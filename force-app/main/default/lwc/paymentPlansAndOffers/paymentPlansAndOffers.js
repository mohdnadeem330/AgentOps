import { api, LightningElement,track,wire } from 'lwc';
import generateSalesOffer from '@salesforce/apex/OpportunityUnitSearchController.generateSalesOffer';
import unitFinishingValues from "@salesforce/apex/OpportunityUnitSearchController.unitFinishingValues";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import performBudgetCheck from "@salesforce/apex/OpportunityUnitSearchController.performBudgetCheck";
export default class PaymentPlansAndOffers extends LightningElement {
    currentUnit;
    recordId='0062600000KLCQGAA5';
    @track tableData=[];
    
    @track selectedUnits;
    isLoading=false;
    @track cardsData=[];
    unitFinishingVals;
    selectedUnitFinishingVal;
    /*
        {label:"Selling Price",value:"1,544,000 AED"},
        {label:"Total Discount",value:"15,999.50 AED"},
        {label:"Payable Price",value:"1,375,000.50 AED"},
        {label:"Rebate(Upon Handover)",value:"12,000.05"}
    */
   @track overViewArray=[];
   /*
    {id:1,
        column1Label:"Adm Waive Percent:",
        column1Value:"1%",
        column2Label:"PM Fees:",
        column2Value:"2%",
        column3Label:"Yas Park Voucher:",
        column3Value:"Yes",
    },
    {id:2,
        column1Label:"Service Charge Waive Years:",
        column1Value:"2",
        column2Label:"HM Waive Years Fees:",
        column2Value:"1",
        column3Label:"",
        column3Value:"",
    }
];*/
    get selectedUnitList(){
        let unitsToReturn = [];
        for(var key in this.selectedUnits){
            unitsToReturn.push(this.selectedUnits[key]);
        }
        return unitsToReturn;
    }



    get saleOfferInputParam(){
        var param1_unitToOfferMap = [];
        for(var key in this.selectedUnits){
            let selectedPayments = []; 
            if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                    if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                        selectedPayments.push(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                    }
                }
            }
            let tempUnitSelectionObj = {'unitId':key,
                                        'offerId':this.selectedUnits[key].offerId,// (this.currentUnit == key ? this.currentOffer : undefined),
                                        'selectedPayments':selectedPayments,
                                        'amount':this.selectedUnits[key].reservationAmount,
                                        'amountType':this.selectedUnits[key].reservationAmountType,
                                        'paymentMethod':this.selectedUnits[key].paymentMethod,
                                        'multiPurposeAmountApplicable': (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable )?this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable:false ,
                                        'unitFinishes':this.selectedUnits[key].unitFinishes
                                        };
            param1_unitToOfferMap.push(tempUnitSelectionObj);
        
        }
        return param1_unitToOfferMap;
    }

    initInnerTables(){
        this.tableData=[];
        this.cardsData=[];
        this.overViewArray=[];
        this.selectedUnitFinishingVal='';
        for(var key in this.selectedUnits){
            if(key === this.currentUnit && this.selectedUnits[key].salesOfferDetails){
                this.selectedUnitFinishingVal =  this.selectedUnits[key].salesOfferDetails.unitFinishes?this.selectedUnits[key].salesOfferDetails.unitFinishes:'';
                if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                    for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                        if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected ){
                            for(let j = 0; j < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails.length ; j++ ){
                                /* Prepare table data Payment Table*/
                                this.tableData.push({id:1,
                                    index: this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentNumber__c,
                                    milestone: this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.Description__c,
                                    installment:this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentPercentage__c,
                                    date:this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentDate__c,
                                    total:this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].totalValue.toLocaleString()
                                });
                            }
                            
                            this.cardsData.push({label:"Selling Price",value:  this.selectedUnits[key].salesOfferDetails.unitRecord.SellingPrice__c.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode})});
                            this.cardsData.push({label:"Total Discount",value:  this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].discountAmount.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode}) });
                            this.cardsData.push({label:"Payable Price",value: this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].netSalesPrice.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode}) });
                            this.cardsData.push({label:"Rebate(Upon Handover)",value: this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].rebateAmount.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode})});
                        }
                    }
                }
                
                if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated && key === this.currentUnit && this.selectedUnits[key].salesOfferDetails.offerId){
                    for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated.length ; i=i+3){
                        
                        let obj={column1Label:this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i].OfferType__c +' '+ this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i].OfferOn__c +' '+(this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i].DiscountType__c?this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i].DiscountType__c:'') ,
                            column1Value: ': '+ this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i].OfferValue__c.toLocaleString() +' '+ this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i].OfferValueType__c,
                            column2Label:"",
                            column2Value:"",
                            column3Label:"",
                            column3Value:""};
                        if(i+1 < this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated.length){
                            obj.column2Label = this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+1].OfferType__c +' '+ this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+1].OfferOn__c +' '+ (this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+1].DiscountType__c?this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+1].DiscountType__c:'') ;
                            obj.column2Value = ': '+this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+1].OfferValue__c.toLocaleString() +' '+ this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+1].OfferValueType__c;
                        }
                        if(i+2 < this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated.length){
                            obj.column3Label = this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+2].OfferType__c +' '+ this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+2].OfferOn__c +' '+ (this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+2].DiscountType__c?this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+2].DiscountType__c :'') ;
                            obj.column3Value =': '+ this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+2].OfferValue__c.toLocaleString() +' '+ this.selectedUnits[key].salesOfferDetails.applicableOfferLinesCalculated[i+2].OfferValueType__c;
                        }
                        this.overViewArray.push(obj);                
                    }
                }
            }
                
        }
    }

    handlePaymentUnitSelect(event){
        //GET THE OFFERS
        this.currentUnit = event.target.value;
        if(!this.selectedUnits[this.currentUnit].salesOfferDetails ){
            this.generateOffer();
        }
        this.populateSelectedValsFlag=true;
    }
    //populateSelectedValsFlag=false;
    renderedCallback(){
       /*if(this.populateSelectedValsFlag){
            this.populateSelectedVals();
        }*/
    }/*
    populateSelectedVals(){
        let selectedOffer = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].selectedOffer");
        let selectedPaymentPlan = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].selectedPaymentPlan");
        //let selectedPaymentPlanName = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].selectedPaymentPlanName");
        if(selectedOffer) {selectedOffer.value=this.selectedUnits[this.currentUnit].offerId ;}
        if( selectedPaymentPlan){
            //for reservation wizard if multiple payment are selected then clear selection if one selected then set default
            let selectedPayments = []; 
            if(this.selectedUnits[this.currentUnit].salesOfferDetails && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated ){
                for(let i = 0 ; i < this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                    if(this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                        selectedPayments.push(this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                    }
                }
            }
            
            if(selectedPayments.length == 1){
                selectedPaymentPlan.value=selectedPayments[0];
            }
        }
        //if ui is refreshed then exit
        if(selectedOffer){
            this.populateSelectedValsFlag=false;
            this.isLoading=false;
        }
        
    }*/

    generateOffer(){
    
        generateSalesOffer({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId  })
        .then(data => {
            //Iterator to set data for all units
            //this.availableEOIs=undefined;
            for(var key in this.selectedUnits){
                this.selectedUnits[key].salesOfferDetails=data[key];
            }
            this.tableData=[];
            this.cardsData=[];
            this.overViewArray=[];
            //this.currentOffer=data[this.currentUnit];
            this.initInnerTables();
            this.isLoading=false;
        })
        .catch(error => {
            console.error('Unable to Payment Plan for given Building/Unit==>'+ JSON.stringify(error));
            this.isLoading=false;
        });
    }
    /*
    @track tableData=[
       {id:1,
        index:1,
        milestone:"Handover",
        installment:"90",
        date:"14.03.2022",
        total:"7056"
       },
       {id:2,
        index:2,
        milestone:"Upon Signing of SPA",
        installment:"10",
        date:"14.09.2022",
        total:"7.84"
       }
   
    ];
    */
    
    selectPaymentPlan(event){ 
        this.isLoading=true;
        this.tableData=[];
        this.cardsData=[];
        this.overViewArray=[];
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        //Default all to false
        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
            if(pd.salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id == event.target.value){
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected= true;
                pd.paymentPlanId=(event.target.value == '') ? undefined : event.target.value;
                
            }else{
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected= false;
            }
        }
        //this.selectedPaymentPlan=undefined;
        this.selectedUnits[this.currentUnit] = pd;
        this.initInnerTables();
        this.isLoading=false;
    }

    handleUnitFinishesChange(event){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitFinishes= event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
        this.initInnerTables();
    }
    handleMultiPurposeRoomChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.salesOfferDetails.multiPurposeAmountApplicable= event.target.checked;
        this.selectedUnits[this.currentUnit] = pd;
        //this.currentOffer= (event.detail.value == '') ? undefined : event.detail.value;
        this.generateOffer();
    }

    handleOfferChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.offerId=(event.detail.value == '') ? undefined : event.detail.value;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
    }


   
    tableColumns = [
        {
            type: 'text',
            fieldName: 'index',
            label: '#',
            initialWidth: 100,
        },
        {
            type: 'text',
            fieldName: 'milestone',
            label: 'Milestone',
            initialWidth: 200,
        },
        {
            type: 'text',
            fieldName: 'installment',
            label: 'Installment %',
            initialWidth: 200,
        },
        {
            type: 'text',
            fieldName: 'date',
            label: 'Date',
            initialWidth: 200,
        },
        {
            type: 'text',
            fieldName: 'total',
            label: 'Total',
            initialWidth: 200,
        }

    ];


connectedCallback(){
    if(!this.selectedUnits){
        this.selectedUnits={'a012600000Np8vPAAR': {unitId:'a012600000Np8vPAAR' , unitName : 'P212'}/*,
    'a012600000Np8vTAAR': {unitId:'a012600000Np8vTAAR' , unitName : 'P112' }*/};
    }else{
    }
    this.initInnerTables();
}

@wire(unitFinishingValues)
getunitFinishingValues({ error, data }) {
    if (data) {
        this.unitFinishingVals = data;
        
    } else if (error) {
        this.unitFinishingVals = undefined;
    }
}


@api async goToTheConfirmationStep(){
    //TODO Remove payment plan skip 
    //Check the budget
    if(!(await performBudgetCheck({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId  }))){
        const evt = new ShowToastEvent({
            title: 'Budget Check Failed',
            message: 'Budget Check Failed',
            variant: 'error',
        });
        this.dispatchEvent(evt);
        this.isLoading=false;
        return;
    }
    //Check atleast 1 payment Plan is selected
    for(var key in this.selectedUnits){
        var selectedPaymentPlanCounter = 0;
        if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
            for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                    selectedPaymentPlanCounter++;
                }
            }
        }
        if(selectedPaymentPlanCounter !=1  ){
            const evt = new ShowToastEvent({
                title: 'Invalid Payment Plans Selection',
                message: 'Please select atleast 1 payment plan for the selected unit(s)',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
            //return;
        }

        
    }
    this.dispatchEvent(new CustomEvent('canproceed', {detail: {canproceed:true}}));
    this.dispatchEvent(new CustomEvent('selectedunits', {detail: {selectedList:this.selectedUnits}}));

   
}



}