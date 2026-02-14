import { api, LightningElement,track } from 'lwc';
import getsObjectType from '@salesforce/apex/OpportunityUnitSearchController.getsObjectType';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import performBudgetCheck from "@salesforce/apex/OpportunityUnitSearchController.performBudgetCheck";
import reserveUnit from '@salesforce/apex/OpportunityUnitSearchController.reserveUnit';
export default class ReserveUnitConfirmation extends LightningElement {

    @api selectedUnits;
    recordId='0062600000KLCQGAA5';
    opportunityDetailsArray=[];
    sobjectData;
    /*selectedList=[
        {id:1,name:"Unit Name 1"},
        {id:2,name:"Unit Name 2"},
        {id:3,name:"Unit Name 3"}
    ];*/

   
@track primaryUnitDetails=[];
@track amountDetails=[];
@track secondaryUnitDetails=[];
@track paymentAmountOptions=[];
//downPaymentValue;
//defaultValue;
currentUnit;
selectedPaymentAmount;

get selectedUnitList(){
    let unitsToReturn = [];
    for(var key in this.selectedUnits){
        unitsToReturn.push(this.selectedUnits[key]);
    }
    return unitsToReturn;
}
get paymentOptionsForReservation() {
    return [
        { label: 'Online', value: 'Online' },
    ];
}
initInnerTables(){
this.primaryUnitDetails=[];
this.amountDetails=[];
this.secondaryUnitDetails=[];
this.paymentAmountOptions=[];

    for(var key in this.selectedUnits){
        if(key === this.currentUnit && this.selectedUnits[key].salesOfferDetails){
            let paymentPlanName='';
            if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                    if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected ){
                        paymentPlanName=this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Name;
                        //this.downPaymentValue = this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[0].totalValue.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode})
                        this.paymentAmountOptions.push({label: 'Down Payment - ' + this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[0].totalValue.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode}), value: this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[0].totalValue.toString()});
                        this.amountDetails = [
                            
                            {id:1,label:"Payable Amount",value: this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].netSalesPrice.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode})},
                            {id:2,label:"Selling Price",value:  this.selectedUnits[key].salesOfferDetails.unitRecord.SellingPrice__c.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode})},
                            {id:3,label:"Total Discount",value: this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].discountAmount.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode})}];
                    }
                }
            }
            this.primaryUnitDetails = [
                {id:1,label:"Property Name",value: this.selectedUnits[key].unitName},
                {id:2,label:"Payment Plan",value: paymentPlanName},
                {id:3,label:"Promotion Name",value: this.selectedUnits[key].salesOfferDetails.offerRecord ? this.selectedUnits[key].salesOfferDetails.offerRecord.Name : '' }];
        
            this.secondaryUnitDetails=[
                {id:1,
                    column1Label:"Unit Type",
                    column1Value: this.selectedUnits[key].salesOfferDetails.unitRecord.UnitType__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.UnitType__c : '',
                    column2Label:"Terrace",
                    column2Value:this.selectedUnits[key].salesOfferDetails.unitRecord.TerraceArea__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.TerraceArea__c : '',
                    column3Label:"Subsidy Years",
                    column3Value:this.sobjectData.SubsidyYears__c ? this.sobjectData.SubsidyYears__c : '',
                },
                {id:2,
                    column1Label:"Unit Name",
                    column1Value:this.selectedUnits[key].salesOfferDetails.unitRecord.Name ? this.selectedUnits[key].salesOfferDetails.unitRecord.Name : '',
                    column2Label:"Price",
                    column2Value:this.selectedUnits[key].salesOfferDetails.unitRecord.SellingPrice__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.SellingPrice__c.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode}) : '',
                    column3Label:"Unit Finish",
                    column3Value:this.selectedUnits[key].unitFinishes ? this.selectedUnits[key].unitFinishes : '',
                },
                {id:3,
                    column1Label:"Rooms",
                    column1Value:this.selectedUnits[key].salesOfferDetails.unitRecord.TotalRooms__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.TotalRooms__c : '',
                    column2Label:"Delivery Method",
                    column2Value: this.sobjectData.DeliveryMethod__c ? this.sobjectData.DeliveryMethod__c : '', 
                    column3Label:"Multi-purpose Room",
                    column3Value:this.selectedUnits[key].multiPurposeAmountApplicable ? this.selectedUnits[key].multiPurposeAmountApplicable : '',
                },
                {id:4,
                    column1Label:"Saleable Area",
                    column1Value:this.selectedUnits[key].salesOfferDetails.unitRecord.SaleableArea__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.SaleableArea__c : '',
                    column2Label:"",
                    column2Value:"",
                    column3Label:"",
                    column3Value:"",
                }];

            //this.downPaymentValue='00';
            //this.defaultValue= this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode}) : this.selectedUnits[key].salesOfferDetails.unitRecord.Project__r.ReservationAmount__c.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode});
            let defaultAmount = this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c : this.selectedUnits[key].salesOfferDetails.unitRecord.Project__r.ReservationAmount__c
            this.paymentAmountOptions.push({label: 'Default Payment - ' + defaultAmount.toLocaleString("en-US", {style:"currency", currency:this.selectedUnits[key].salesOfferDetails.unitRecord.CurrencyIsoCode}) , value:  defaultAmount.toString() });
            this.selectedPaymentAmount = this.selectedUnits[key].reservationAmount;
        }
    }       
}
handlePaymentUnitSelect(event){
    this.currentUnit = event.target.value;
    this.initInnerTables();
}
gesObjectData(){
    getsObjectType({recordID :this.recordId })
    .then(data => {
        for(var key in data){
            this.sobjectData = data[key];
        }
        this.opportunityDetailsArray=[
            {id:1,
                column1Label:"Sales Type",
                column1Value: this.sobjectData.SaleType__c?this.sobjectData.SaleType__c:'',
                column2Label:"Broker Agency Name",
                column2Value:this.sobjectData.BrokerAgencyAccount__r?this.sobjectData.BrokerAgencyAccount__r.Name:'',
                column3Label:"Referral Employee Name",
                column3Value:this.sobjectData.EmployeeName__c?this.sobjectData.EmployeeName__c:'',
            },
            {id:2,
                column1Label:"Deal Type",
                column1Value:this.sobjectData.DealType__c?this.sobjectData.DealType__c:'',
                column2Label:"Bank Name",
                column2Value:this.sobjectData.BankName__c?this.sobjectData.BankName__c:'',
                column3Label:"Broker Agent Name",
                column3Value:this.sobjectData.BrokerAgentName__c?this.sobjectData.BrokerAgentName__c:'',
            },
            {id:3,
                column1Label:"Booking Type",
                column1Value:this.sobjectData.BookingType__c?this.sobjectData.BookingType__c:'',
                column2Label:"Referral Type",
                column2Value:this.sobjectData.ReferralType__c?this.sobjectData.ReferralType__c:'',
                column3Label:"Corporate Partner",
                column3Value:this.sobjectData.CorporateWealthName__c?this.sobjectData.CorporateWealthName__c:'',
            },
            {id:4,
                column1Label:"Agent Type",
                column1Value:this.sobjectData.AgentType__c?this.sobjectData.AgentType__c:'',
                column2Label:"",
                column2Value:"",
                column3Label:"",
                column3Value:"",
            }
       ];
        this.initInnerTables();
    })
    .catch(error => {
        console.log('Unable to sObject data ==>'+ JSON.stringify(error));
    });
}


    
   

connectedCallback(){
    this.dispatchEvent(new CustomEvent('canproceed', {detail: {canproceed:true}}));
    this.gesObjectData();
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
                                    'amount':parseFloat(this.selectedUnits[key].reservationAmount),
                                    'amountType':this.selectedUnits[key].reservationAmountType,
                                    'paymentMethod':'Online',
                                    'multiPurposeAmountApplicable': (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable )?this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable:false ,
                                    'unitFinishes':this.selectedUnits[key].unitFinishes
                                    };
        param1_unitToOfferMap.push(tempUnitSelectionObj);
    
    }
    return param1_unitToOfferMap;
}

@api async handleReserve(){
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
        //Payment Selection
        if(this.selectedUnits[key].reservationAmount == undefined || this.selectedUnits[key].reservationAmount == 0 ){
            const evt = new ShowToastEvent({
                title: 'Payment Option/Amount not selected',
                message: 'Please select Payment Method and Amont for '+this.selectedUnits[key].unitName+' before submitting ',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
            return;
        }

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
            return;
        }    
    }
    //TODO perform reservation
    this.reserveSelectedUnit();
}


reserveSelectedUnit(){
    reserveUnit({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId ,action: 'RESERVE' , winReason : '' ,selectedEOI: '' })
    .then(data => {
        if(data && data['result'] && data['result']=='success'){
            const evt = new ShowToastEvent({
                title: 'Reservation Successful',
                message: 'Reservation Successful',
                variant: 'success',
            });
            this.dispatchEvent(evt);
        }else if(data && data['result'] ){
            const evt = new ShowToastEvent({
                title: 'Reservation Failed',
                message: 'Reservation failed '+ data['result'],
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }else{
            const evt = new ShowToastEvent({
                title: 'Reservation Failed',
                message: 'Reservation failed '+ data,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
        this.isLoading=false;
    })
    .catch(error => {
        console.log('Unable to reserve selected unit ==>'+ JSON.stringify(error));
        const evt = new ShowToastEvent({
            title: 'Reservation Failed',
            message: 'Reservation failed '+ error.message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
        this.isLoading=false;
    });
}

handlePaymentChange(event){
    this.selectedPaymentAmount= event.detail.value;
    let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
    pd.reservationAmount= event.detail.value;
    for(let i=0; i < this.paymentAmountOptions.length; i++ ){
        if(this.paymentAmountOptions[i].value === event.detail.value){
            pd.reservationAmountType = this.paymentAmountOptions[i].label.includes('Down Payment') ? 'Down Payment' : 'Default Amount';
        }
    }
    this.selectedUnits = {...this.selectedUnits};
    this.selectedUnits[this.currentUnit] = pd;
    this.initInnerTables();
}

}