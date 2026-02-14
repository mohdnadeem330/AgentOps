import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSOandUnitDetails from '@salesforce/apex/CustomRulesHelper.getSOandUnitDetails';
import createSelectedUnits from '@salesforce/apex/CustomRulesHelper.createSelectedUnits';
import RemoveSelectedUnits from '@salesforce/apex/CustomRulesHelper.RemoveSelectedUnits';
import createSOA from '@salesforce/apex/CustomRulesHelper.createSOA';
const COLUMN = [
    // { label: 'Project Name', fieldName: 'projectName' },
    { label: 'Unit No', fieldName: 'Name' },
    //{ label: 'Sales Order No', fieldName: 'Name' },
   /*
    {
         
        label: 'Net Amount', fieldName: 'NetAmount__c', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
        
    },
    */
    {
        label: 'Outstanding Amount', fieldName: 'OutstandingAmount__c', type: 'currency', typeAttributes: {
            step: '0.01',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    },
    
    {
        label: 'Unit Selling Price', fieldName: 'Unit_Selling_Price__c', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    },
    
    {
        label: 'Previous Rebate offered', fieldName: 'Previous_Rebate_Offered__c', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }
    },
    {
        label: 'Maximum Additional Rebate', fieldName: 'Maximum_Rebate', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2'
        }
    },
    {
        label: 'Unit Split Percentage', fieldName: 'Rebate_Percentage__c', type: 'percentage', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2'
        }, editable: true
    },
    
];
export default class RebateUnitSelection extends LightningElement {
    @track columns = COLUMN;
    @track availableUnitList = [];
    @api recordId;
    @track selectedRows = [];
    @track selectedUnitList = [];
    @track unitList = [];
    @track selectedUnit = '';
    @track isLoading = true;
    @track onLoadunitresult = [];
    @track previousAmtoffered=0.0;
    @track previousreboffered=0.0;
    @track totalOutstanding=0.0;
    @track additionalRebateAmmount=0.0;
    @track additionalRebatePercentage=0.0;
    @track totalUnitPrice = 0.0;
    readOnlyMode = false;
    SRStatus = '';
    @track firstFieldValue = '';
    @track secondFieldValue = '';
    @track readOnlyFirstField = false;
    @track readOnlySecondField = false;
    Maximum_Rebate = 0.0;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        this.readOnlyMode = false;
        this.callConnected(true);

    }

    async callConnected(isConnected) {
        try {
            await getSOandUnitDetails({ srId: this.recordId })
                .then(result => {
                    console.log('result' + JSON.stringify(result));
                    this.SRStatus = result.Status;
                    console.log('result.Status' +result.Status +JSON.stringify(result.Status))
                    this.unitList = [{ label: '--None--', value: '' }];  
                    this.onLoadunitresult=  result.unitselectedList;   
                    this.onLoadunitresult = this.onLoadunitresult.map(item => { 
                        return {...item, Maximum_Rebate: parseFloat(((.15 * item.Unit_Selling_Price__c)- item.Previous_Rebate_Offered__c).toFixed(2))}
                    }) 

                    for (let res of  result.unitselectedList) {
                        this.unitList.push({ label: res.Name, value: res.Name });
                        if(res.Rebate_Percentage__c>=0){
                            this.availableUnitList.push(res);
                        }   
                    }

                    if(this.availableUnitList.length>0){
                        for(let avilableUnit of this.availableUnitList){
                            this.previousAmtoffered+=avilableUnit.Previous_Rebate_Offered__c;
                            this.totalOutstanding+=parseFloat(avilableUnit.OutstandingAmount__c);
                            this.totalUnitPrice+=parseFloat(avilableUnit.Unit_Selling_Price__c);
                        }
                        this.previousAmtoffered = parseFloat(this.previousAmtoffered.toFixed(2));
                        this.previousreboffered=(this.previousAmtoffered/this.totalOutstanding)*100;
                        // this.previousreboffered=(this.previousAmtoffered/this.totalUnitPrice)*100;
                        this.previousreboffered=parseFloat(this.previousreboffered.toFixed(2));
                        
                    }
                  //  console.log('totalUnitPrice' + this.totalUnitPrice);
                    console.log('previousreboffered' + this.previousreboffered);

                    this.additionalRebateAmmount=result.AdditionalRebateAmt.toFixed(2);
                    this.additionalRebatePercentage=result.AdditionalRebatePer.toFixed(2);
                    
                })
                .catch(error => {
                    console.log(error);
                })
        }
        catch (error) {
            console.log(error);
        }

    }

    onhandleChangeCombobox(event) {
    
    this.selectedUnit = event.detail.value;
    let duplicateItem= this.availableUnitList.filter(avilableUnit=>{
      
        if(avilableUnit.Name==this.selectedUnit){
           return true;
        }
        return false;
      })
      

      if(duplicateItem.length > 0 ){
        this.showToast('Error', 'Duplicate Selection', 'error');
        return;
      }

    let matchedItemList= this.onLoadunitresult.filter(onLoadunit=>{
         if(onLoadunit.Name==this.selectedUnit){
            return true;
         }
         return false;
       })
       this.previousreboffered=0.0;
       this.previousAmtoffered=0.0;
       this.totalOutstanding=0.0;
       this.totalUnitPrice = 0.0;
       var result = [matchedItemList[0], ...this.availableUnitList];
       this.availableUnitList=result;
       if(this.availableUnitList.length>0){
        for(let avilableUnit of this.availableUnitList){
            this.previousAmtoffered+=parseFloat(avilableUnit.Previous_Rebate_Offered__c.toFixed(2));
            this.totalOutstanding+=parseFloat((avilableUnit.OutstandingAmount__c).toFixed(2));
            this.totalUnitPrice+=parseFloat((avilableUnit.Unit_Selling_Price__c).toFixed(2));
        }
        this.previousreboffered=(this.previousAmtoffered/this.totalOutstanding)*100;
        // this.previousreboffered=(this.previousAmtoffered/this.totalUnitPrice)*100;
        this.previousreboffered=parseFloat(this.previousreboffered.toFixed(2));
      
        if(this.additionalRebatePercentage > 0 && this.totalOutstanding > 0 )
        {
        this.additionalRebateAmmount = parseFloat(((this.additionalRebatePercentage / 100) * this.totalOutstanding).toFixed(2));
        }
      

    }

    }

    async handleSaveAction() {
        try {
            this.isLoading = false;  
           let total=0;
            for(let sruint of this.availableUnitList){
                total+=parseFloat(sruint.Rebate_Percentage__c);
            }
            if(total!=100){
                this.showToast('Error', 'Total Unit split Rebate% should be 100', 'error');
                this.isLoading = true; 
                return;
            }
            createSelectedUnits({ srUnitList: this.availableUnitList, srId: this.recordId,percentage:this.additionalRebatePercentage,ammount:this.additionalRebateAmmount })
                        .then(result => {
                            this.isLoading = true;
                            this.showToast('Success', 'Rebate Unit Addition/Updates are completed', 'success');
                            this.availableUnitList=[];
                            this.onLoadunitresult= [];
                            this.previousAmtoffered=0;
                            this.previousreboffered=0;
                            this.additionalRebateAmmount=0.0;
                            this.additionalRebatePercentage=0.0;
                            this.totalOutstanding=0.0;
                            this.callConnected(true);
                            // window.open('/' + this.recordId, '_self');
                        })
                        .catch(error => {
                            this.isLoading = true;
                            console.log(error)
                            this.showToast('Error', error, 'Error');
                            window.open('/' + this.recordId, '_self');
                        })
                }                  
        catch (error) {
           console.log(error);
        }
    }

    selectRow(event) {
        let selectedRows = event.target.selectedRows;
        this.selectedUnitList = selectedRows.filter(row => selectedRows.includes(row));
    }

    async handleDeleteAction() {
        this.isLoading = false;
        if (this.selectedUnitList.length === 0) {
            this.isLoading = true;
            this.showToast('Error', 'No row Selected', 'error');
            return;
        } else {  
            console.log('Selected Units' + JSON.stringify(this.selectedUnitList))
            RemoveSelectedUnits({ deleteIds: JSON.stringify(this.selectedUnitList), srId: this.recordId })
                .then(result => {
                    this.isLoading = true;
                    this.showToast('Success', 'Success! Rebate Unit Selection is completed', 'success');
                  this.availableUnitList=[];
                  this.onLoadunitresult= [];
                  this.previousAmtoffered=0;
                  this.previousreboffered=0;
                  this.totalOutstanding=0.0;
                  this.callConnected(true);
                })
                .catch(error => {
                    console.log(error)
                    this.isLoading = true;
                    this.showToast('Error', 'Failed! ' + error, 'Error');
                    window.open('/' + this.recordId, '_self');
                })
                
        }

    }
    async handleSOAAction(){

        this.isLoading = false;

        let total=0;
            for(let sruint of this.availableUnitList){
                total+=parseFloat(sruint.Rebate_Percentage__c);
            }
            if(total!=100){
                this.showToast('Error', 'Total Unit split Rebate% should be 100', 'error');
                this.isLoading = true; 
                return;
            }
            if(total == 0){
                this.showToast('Error', 'Unit not Selected for Rebate', 'error');
                this.isLoading = true; 
                return;
            }
         
        createSOA({srId: this.recordId})
        .then(result => {
                this.isLoading = true;
                this.showToast('Success', 'Started: SOA and ERP SOA generation', 'success');
                this.availableUnitList=[];
                this.onLoadunitresult= [];
                this.callConnected(true);
                })
        .catch(error => {
                console.log(error)
                this.isLoading = true;
                this.showToast('Error', 'Failed! ' + error, 'Error');
                window.open('/' + this.recordId, '_self');
                })
                
        
    }

    
    handleOnCellChange(event) {
        let index=0;
        for (let avilableUnit of  this.availableUnitList) {
            for (let draftValue of event.detail.draftValues) {
                if(avilableUnit.Id==draftValue.Id){
                    // if((draftValue.Rebate_Percentage__c/100)* this.additionalRebateAmmount > avilableUnit.OutstandingAmount__c)
                    //     {
                    //         this.showToast('Error', 'Maximum rebate offered for allocated units should not be more than outstanding', 'error');
                    //         return;
                    //     }

                    // else{ 
                        this.availableUnitList[index]={...this.availableUnitList[index], Rebate_Percentage__c: draftValue.Rebate_Percentage__c};
                    // }
                }
            }
            index++;
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    get isListEmpty() {
        return !this.availableUnitList || this.availableUnitList.length === 0;
    }

     handlepercentchange(event){ 
        

    //     if((parseFloat(event.target.value)+parseFloat(this.previousreboffered) >15) && (parseFloat(event.target.value)> 0)){
    //     this.additionalRebateAmmount =0;
    //    // this.additionalRebatePercentage= 0; 
    //     this.showToast('Error', 'Maximum rebate offered for allocated units should not be more than 15%', 'error');
    //     return;
    //   }             
    //   if((parseFloat(event.target.value)+parseFloat(this.previousreboffered) >15) && (parseFloat(event.target.value)> 0)){
    //     this.additionalRebateAmmount =0;
    //    // this.additionalRebatePercentage= 0; 
    //     this.showToast('Error', 'Maximum rebate offered for allocated units should not be more than 15%', 'error');
    //     return;
    //   }
    //     else if(((parseFloat(event.target.value)+parseFloat(this.previousreboffered))/100) * parseFloat(this.totalUnitPrice).toFixed(2) > parseFloat(this.totalOutstanding).toFixed(2) && parseFloat(event.target.value) > 0){
    //         this.additionalRebateAmmount =0;
    //        // this.additionalRebatePercentage= 0; 
    //         this.showToast('Error', 'Maximum rebate offered for allocated units should not be more than outstanding', 'error');
    //         return;

    console.log('val' + parseFloat(event.target.value))
    if(parseFloat(event.target.value) >= 100){
            this.showToast('Error', 'Maximum rebate offered for allocated units should be less than 100%', 'error');
            return;
      }else{

            this.additionalRebateAmmount =0;
            this.additionalRebatePercentage= 0; 
            this.additionalRebatePercentage= event.target.value;

            for (let avilableUnit of this.availableUnitList) {
                console.log('avilableUnit' +JSON.stringify(avilableUnit) + avilableUnit.Previous_Rebate_Offered__c)
                console.log('Test' + (parseFloat((this.additionalRebatePercentage/100) * avilableUnit.OutstandingAmount__c) + parseFloat(avilableUnit.Previous_Rebate_Offered__c)))
                 if((parseFloat((this.additionalRebatePercentage/100) * avilableUnit.OutstandingAmount__c) + parseFloat(avilableUnit.Previous_Rebate_Offered__c)) > .15 * avilableUnit.Unit_Selling_Price__c){
                    this.showToast('Error', 'Maximum rebate offered for allocated unit: '+ avilableUnit.Name + 'should not be more than 15% of Selling Price', 'error');
                 return;
                }   
                           
            }
            if(this.additionalRebatePercentage > 0 && this.totalOutstanding > 0 )
            {
            this.additionalRebateAmmount = parseFloat(((this.additionalRebatePercentage / 100) * this.totalOutstanding).toFixed(2));
            }
            if(this.additionalRebatePercentage == null || this.additionalRebatePercentage == 0 )
            {
            this.additionalRebateAmmount = 0.0;
            }
            this.readOnlySecondField = this.additionalRebatePercentage> 0 ? true: false;
         
       }
      
    }
    get readOnlyClass() {
        this.readOnlyMode = (this.SRStatus == 'Draft' || this.SRStatus == 'Submitted' || this.SRStatus == null || this.SRStatus == undefined)? false: true ;
        
        if(this.readOnlyMode == true)
            {
               this.columns.find(column => column.fieldName == 'Rebate_Percentage__c').editable = false;
            }
            else
            {
            this.columns.find(column => column.fieldName == 'Rebate_Percentage__c').editable = true;
            }
            

        // console.log('this.readOnlyMode' + this.readOnlyMode)
        return this.readOnlyMode;
    }


    handleSecondFieldChange(event) {
            
            // if((parseFloat(event.target.value)+parseFloat(this.previousAmtoffered)) > parseFloat(0.15 * this.totalUnitPrice).toFixed(2)){
            //     this.additionalRebatePercentage= 0; 
            //     console.log('this.additionalRebateAmmount: ' + (parseFloat(event.target.value)+parseFloat(this.previousAmtoffered))  + 'Outstanding: ' +parseFloat(0.15 * this.totalOutstanding).toFixed(2))
            //     this.showToast('Error', 'Maximum rebate offered for allocated units should not be more than 15% of total selling price', 'error');
            //     return;
            //   }
            //   else if((parseFloat(event.target.value)+parseFloat(this.previousAmtoffered)) > parseFloat(this.totalOutstanding).toFixed(2)){
            //     this.additionalRebatePercentage= 0; 
            //     this.showToast('Error', 'Maximum rebate offered for allocated units should not be more than outstanding', 'error');
            //     return;
            //   }

            if(parseFloat(event.target.value) >= parseFloat((this.totalOutstanding).toFixed(2))){
                this.showToast('Error', 'Maximum rebate offered for allocated units should be less than total Outstanding', 'error');
                return;
          }
              else{
                    this.additionalRebateAmmount =0;
                    this.additionalRebatePercentage= 0; 
                    this.additionalRebateAmmount= event.target.value;
                    
                    if(this.additionalRebateAmmount > 0 && this.totalOutstanding > 0 )
                        {
                        this.additionalRebatePercentage = ((((parseFloat(this.additionalRebateAmmount).toFixed(2))/ (parseFloat(this.totalOutstanding).toFixed(2)))* 100));
                        this.additionalRebatePercentage  = (parseFloat((this.additionalRebatePercentage).toFixed(2)));
                        for (let avilableUnit of this.availableUnitList) {

                             if((parseFloat((this.additionalRebatePercentage/100) * avilableUnit.OutstandingAmount__c) + parseFloat(avilableUnit.Previous_Rebate_Offered__c)) > .15 * avilableUnit.Unit_Selling_Price__c){
                                this.showToast('Error', 'Maximum rebate offered for allocated unit: '+ avilableUnit.Name + 'should not be more than 15% of Selling Price', 'error');
                             return;
                            }   
                                       
                        }
                        }
                    if(this.additionalRebateAmmount == null || this.additionalRebateAmmount == 0 )
                    {
                    this.additionalRebatePercentage = 0.0;
                    }
                    this.readOnlyFirstField = this.additionalRebateAmmount> 0? true: false;
                 
               }
        
        
      //  this.updateReadOnlyState();
    }

    updateReadOnlyState() {
        this.readOnlyFirstField = this.additionalRebateAmmount> 0? true: false;
        this.readOnlySecondField = this.additionalRebatePercentage> 0? true: false;
    }

    handleClose() {
        window.location.reload();
        alert('closed')
    }

   
    
}