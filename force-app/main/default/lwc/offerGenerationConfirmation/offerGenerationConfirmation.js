import { api, LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import generateSalesOffer from '@salesforce/apex/OpportunityUnitSearchController.generateSalesOffer';
import sendSalesOfferPDF from '@salesforce/apex/OpportunityUnitSearchController.sendSalesOfferPDF';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 

import getVFDomainURL from "@salesforce/apex/Utilities.getVFDomainURL";


export default class OfferGenerationConfirmation extends LightningElement {


    @api selectedUnitSearchList;

    @track selectedUnits={};
    @track fullUrl='https://prdev-aldarprdev.cs81.force.com/pr2/apex/OfferDetailsPDFController';

    selectOfferId;
    currentUnit;
    customerName='Customer';
    doneTypingInterval = 0;
    checkboxGroupvalue = {};

    downloadIcon=resourcesPath+ "/ALDARResources/svg/Download.svg";
    value = ['option1'];

    @api selectedRow;
    connectedCallback(){
        console.log("~!@#~!!!!!!!!!!!!!!!!!!~~@#!@!#!@#@#!##~~#@#@#~!#");
        setTimeout(() => {
            console.log("//////////////////////////////////////");
            console.log(JSON.stringify(this.selectedRow));
            console.log("///////////////////////////////////////");
        }, 2000);


    }
    
    get options() {
        return [
            //{ label: 'Affection Plan', value: 'AffectionPlan' },
            { label: 'Marketing Plan', value: 'MarketingPlan' },
        ];
    }

    handleCustomerNameChange(event) {
        clearTimeout(this.typingTimer);
        let value = event.target.value;
        let name = event.target.name;

        this.typingTimer = setTimeout(() => {
            this[name] = value;
            this.customerName = value;
        }, this.doneTypingInterval);
    }

    get selectedValues() {
        return this.value.join(',');
    }

    handleChange(e) {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.affectionMarketingPlan= JSON.parse(JSON.stringify(e.detail.value));
        this.selectedUnits[this.currentUnit] = pd;
        console.log(pd);
    }

    connectedCallback(){
        this.handleSelectedUnits();
    }   

    async handleSelectedUnits() {
        this.selectedUnits={};
        for (let index = 0; index < this.selectedUnitSearchList.length; index++) {
            this.selectedUnits[this.selectedUnitSearchList[index].Id]= {'selectionStatus':true,
                                                 'unitId': this.selectedUnitSearchList[index].Id, 
                                                 'unitName':this.selectedUnitSearchList[index].endUnitCode,
                                                 'community':this.selectedUnitSearchList[index].community,
                                                 'salesOfferDetails':{},
                                                 'isResale':this.selectedUnitSearchList[index].isResale,
                                                 'propertyCode': this.selectedUnitSearchList[index].propertyCode};
        }
        // console.log(JSON.stringify(this.selectedUnits));
        this.generateOffer();
    }

    handleOfferChange(event){
        this.isLoading=true;

        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.offerId=(event.detail.value == '') ? undefined : event.detail.value;
        this.selectedUnits[this.currentUnit] = pd;
        
        this.generateOffer();
    }

    generateOffer(){
        generateSalesOffer({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.getLeadId /* this.recordId Lead ID */ })
        .then(data => {
            // console.log(data);

            try{
                //this.selectedUnits[this.currentUnit].salesOfferDetails=data[this.currentUnit]; 
                //Iterator to set data for all units
                for(var key in this.selectedUnits){

                    if(this.selectedUnits[key].selectionStatus){
                        // console.log(data[key]);

                        this.selectedUnits[key].salesOfferDetails=data[key];
                    }
                }
                console.log(data);
                console.log(JSON.stringify( data ));

                //this.currentOffer=data[this.currentUnit];
                this.isLoading=false;
            }catch(e){
                console.log(e);
            }
            
        })
        .catch(error => {
            console.log('Unable to Payment Plan for given Building/Unit==>'+ JSON.stringify(error));
            this.isLoading=false;
        });
    }

    handlePaymentUnitSelect(event){

        //GET THE OFFERS
        this.isLoading=true;
        this.currentUnit = event.target.value;

        //TODO: PDB gpopulate the UI
        if(!this.selectedUnits[this.currentUnit].salesOfferDetails ){
            this.generateOffer();
        }else{
            //this.currentSalesOfferDetails=undefined;
            this.selectedUnits[this.currentUnit].salesOfferDetails;
        }
        this.handlePDFActive();
        this.populateSelectedValsFlag=true;
    }

    get selectedUnitList(){
        let unitsToReturn = [];
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                this.selectedUnits[key].calculatedPayment=undefined;
                if('isResale' in this.selectedUnits[key]){
                    if(this.selectedUnits[key].isResale){
                        this.selectedUnits[key]['isNewSale'] = false;
                        this.selectedUnits[key]['tabLabel'] = this.selectedUnits[key]['propertyCode']; //!this.selectedUnits[key][''];
                    }else{
                        this.selectedUnits[key]['isNewSale'] = true;
                        this.selectedUnits[key]['tabLabel'] = this.selectedUnits[key]['unitName'];
                    }
                }else{
                    this.selectedUnits[key]['tabLabel'] = this.selectedUnits[key]['unitName'];
                }
                unitsToReturn.push(this.selectedUnits[key]);
                
            }
        }
        // console.log(JSON.stringify( unitsToReturn ));

        return unitsToReturn;
    }

    get saleOfferInputParam(){
        var param1_unitToOfferMap = [];
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
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
                                            //'multiPurposeAmountApplicable': (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable )?this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable:false ,
                                            //'unitFinishes':this.selectedUnits[key].unitFinishes
                                            };
                param1_unitToOfferMap.push(tempUnitSelectionObj);
            }
        }
        // console.log('saleOfferInputParam ' + JSON.stringify(param1_unitToOfferMap));

        return param1_unitToOfferMap;
    }

    unselectPaymentPlan(event){
        
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
            if(pd.salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id == event.target.name){
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected= false;
                break;
            }
        }
        // console.log(event.target.name);
        this.selectedUnits[this.currentUnit] = pd;
    }
    //selectedPaymentPlan;
    selectPaymentPlan(event){ 
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        // if (this.hidePill) {
        //     for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
        //         pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected = false;
        //     }
        // }

        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){

            if(pd.salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id == event.target.value){
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected= true;
                /*pd.paymentPlanId=(event.target.value == '') ? undefined : event.target.value;
                pd.netSalesPrice=(event.target.value == '') ? undefined : pd.salesOfferDetails.applicablePaymentPlansCalculated[i].netSalesPrice;
                pd.partnerDiscountAmount=(event.target.value == '') ? undefined : pd.salesOfferDetails.applicablePaymentPlansCalculated[i].partnerDiscountAmount;
                pd.rebateAmount=(event.target.value == '') ? undefined : pd.salesOfferDetails.applicablePaymentPlansCalculated[i].rebateAmount;
                pd.totalDiscount =(event.target.value == '') ? undefined : pd.salesOfferDetails.unitRecord.SellingPrice__c - pd.salesOfferDetails.applicablePaymentPlansCalculated[i].discountedUnitSalesPrice;
                */
                
                break;
            }
        }
        //this.selectedPaymentPlan=undefined;
        this.selectedUnits[this.currentUnit] = pd;

        this.isLoading=false;
    }

    get getReceiverName(){
        console.log("//////////////////////////////////////");
            console.log(JSON.stringify(this.selectedRow));
            console.log("///////////////////////////////////////");
        return `${this.selectedRow.selectedRow[0].column1} ${this.selectedRow.selectedRow[0].column2} ${this.selectedRow.selectedRow[0].column3}`;
    }

    get getLeadId(){
        console.log("//////////////////////////////////////");
            console.log(JSON.stringify(this.selectedRow));
            console.log("///////////////////////////////////////");
        var leadid = `${this.selectedRow.selectedRow[0].column7}`;
        // var leadChildid = `${this.selectedRow.selectedChildRow[0].column7}`;
        // var leadidValue = leadChildid.substring(0, leadid.indexOf("-"))
        return leadid;

    }

    async handlePDFActive(event){
        var currentUnit='';
        var currentOffer='';
        var otherUnits='';
        var selectedPayments='';
        var multiPurposeAmountApplicable='';
        var AffectionPlan=false;
        var MarketingPlan=false;
        var isResale = false;


        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                 if(key == this.currentUnit){
                    currentUnit=key;
                    if('isResale' in this.selectedUnits[key]) {
                        isResale = this.selectedUnits[key].isResale;
                    }
                    if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                        for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                            if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                                selectedPayments= selectedPayments+ (selectedPayments==''?'':'|')+ (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                            }
                        }
                    }
                    multiPurposeAmountApplicable = (this.selectedUnits[key].salesOfferDetails)?this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable:false;
                    currentOffer= (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.offerId)?this.selectedUnits[key].salesOfferDetails.offerId:'' ;
                 }else{
                    otherUnits= otherUnits + (otherUnits==''?'':'|')+ key;
                 }
                
               

                if (this.selectedUnits[key].affectionMarketingPlan) {
                    this.selectedUnits[key].affectionMarketingPlan.forEach(element => {
                    if (element == 'AffectionPlan') {
                        AffectionPlan = true;
                    }else if(element == 'MarketingPlan'){
                        MarketingPlan = true;
                    }
                    });
                }
                
            }
        }

        if(isResale){
            this.fullUrl = '../apex/ResaleOfferPDF?currentUnit='+currentUnit+'&customerName='+this.getReceiverName+'&opportunityId='+this.getLeadId;
        }else{
            this.fullUrl = '../apex/OfferDetailsPDF?id='+this.getLeadId+'&currentUnit='+ currentUnit+'&currentOffer='+currentOffer+'&otherUnits='+otherUnits+'&selectedPayments='+selectedPayments+'&customerName='+this.customerName+'&multiPurposeAmount='+multiPurposeAmountApplicable+'&affectionPlan='+ AffectionPlan +'&marketingPlan='+MarketingPlan;
        }

        console.log('this.fullUrl ' + this.fullUrl );
    }

    async handleMenuAction(event){
        this.isLoading=true;
        
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus && this.currentUnit == key){
                var selectedPaymentPlanCounter = 0;
                if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                    for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                        if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                            selectedPaymentPlanCounter++;
                        }
                    }
                }
                if(selectedPaymentPlanCounter ==0  ){
                    const evt = new ShowToastEvent({
                        title: 'Invalid Payment Plans Selection',
                        message: 'Please select atleast 1 payment plan for the offer generation process',
                        variant: 'warning',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return;
                }else{
                    this.handlePDFActive();
                }

            }
        }
    
    }

    sendSalesOfferEmail(event){
        this.isLoading=true;
        /*var param1_unitToOfferMap ={};
        param1_unitToOfferMap = [];
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                let selectedPayments = []; 
                if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                    for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                        if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                            selectedPayments.push(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                        }
                    }
                }
                let tempUnitSelectionObj = {'unitId':key,
                                            'offerId':(this.currentUnit == key ? this.currentOffer : undefined),
                                            'selectedPayments':selectedPayments}
                param1_unitToOfferMap.push(tempUnitSelectionObj);
            }
        } */
        //var singleUnitIdToSend = event.target.dataset.unitId;
        sendSalesOfferPDF({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.getLeadId ,customerName : this.customerName , singleUnitId : this.currentUnit})
        .then(data => {

            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Email have been sent successfully.',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            // //redirect to opportunity, once user clicks on send All button
            // //Else do not redirect
            // if(singleUnitIdToSend == undefined || singleUnitIdToSend ==null || singleUnitIdToSend==''){
            //     this[NavigationMixin.Navigate]({
            //     type: 'standard__recordPage',
            //     attributes: {
            //         recordId: this.recordId,
            //         objectApiName: 'Opportunity',
            //         actionName: 'view'
                    
            //     }
            // });
            // }
        })
        .catch(error => {
            console.log('sending email failed'+ JSON.stringify(error));
            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Sending email failed.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            
        });
    }
}