import { LightningElement, track, api ,wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import getsObjectType from '@salesforce/apex/OpportunityUnitSearchController.getsObjectType';
import getAllProjects from '@salesforce/apex/OpportunityUnitSearchController.getAllProjects';
import getAllBuildings from '@salesforce/apex/OpportunityUnitSearchController.getAllBuildings';
import getUnitDetails from '@salesforce/apex/OpportunityUnitSearchController.getUnitDetails';
import generateSalesOffer from '@salesforce/apex/OpportunityUnitSearchController.generateSalesOffer';
import unitFinishingValues from "@salesforce/apex/OpportunityUnitSearchController.unitFinishingValues";
import unitFurnishingValues from "@salesforce/apex/OpportunityUnitSearchController.unitFurnishingValues";
import sendSalesOfferPDF from '@salesforce/apex/OpportunityUnitSearchController.sendSalesOfferPDF';
import generateOfferPDF from '@salesforce/apex/OpportunityUnitSearchController.generateOfferPDF';

const actions = [
    { label: 'Show details', name: 'show_details' }
];

const columns = [
    { label: 'Unit Name', fieldName: 'Name'},
     /*{{ label: 'Number Of Bedrooms', fieldName: 'NumberOfBedrooms__c' },
    { label: 'Unit Type', fieldName: 'UnitType__c'},
    { label: 'Property Usage', fieldName: 'PropertyUsage__c'},*/
    { label: 'Unit Model', fieldName: 'UnitModel__c' },
    /*{ label: 'Floor Number', fieldName: 'FloorNumber__c'},
    { label: 'Unit View', fieldName: 'UnitView__c'},
    { label: 'Unit Category', fieldName: 'UnitCategory__c'},
    { label: 'Terrace Area', fieldName: 'TerraceArea__c' , type : 'number', typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2',
    }},
    { label: 'Total Area', fieldName: 'TotalArea__c' , type : 'number', typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2',
    }},
    { label: 'Unit Plot Area', fieldName: 'UnitPlotArea__c', type : 'number', typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2',
    }},*/
    { label: 'Selling Price', fieldName: 'SellingPrice__c', type: 'currency', typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2',
        currencyCode: 'AED'
    }},
     /*{{ label: 'Online Reservation Fee', fieldName: 'OnlineReservationFee__c', type: 'currency' , typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2',
        currencyCode: 'AED'
    }}*/
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    } ];

    const offerColumnsDef = [
        { label: 'Offer Type', fieldName: 'offerType'},
        { label: 'Offer On', fieldName: 'offerOn'},
        /*{ label: 'Value', fieldName: 'offerValue', type: 'number', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }},*/
        { label: 'Value', fieldName: 'offerValueType'}
        
    ];

    const installmentColumnsDef = [
        { label: 'Installment #', fieldName: 'installmentNumber'},
        { label: 'Installment Percentage', fieldName: 'installmenPercentage',type: 'percent',typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
        }},
        { label: 'Total', fieldName: 'total', type: 'currency', typeAttributes: {
            step: '0.1',
            minimumFractionDigits: '2',
            maximumFractionDigits: '2',
            currencyCode: 'AED'
        }}
    ];

export default class OpportunityUnitSearchLite extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading=true;
    currentPage=1;
    columnsDefination =  columns;
    installmentColumns = installmentColumnsDef;
    offerColumns = offerColumnsDef;
    unitData;
    sObjectRecordType;
    sObjectRecord;
    projectList;
    selectedProject;
    buildingList;
    selectedBuilding;
    currentUnit;
    selectedUnits ={};
    customerName='Customer';
    /*get disableOffer(){
        return (this.selectedUnitList < 1);
    }*/
    get page1(){
        return (this.currentPage == 1);
    }
    get page2(){
        return (this.currentPage == 2);
    }
    get page3(){
        return (this.currentPage == 3);
    }
    get currentPageStep(){
        return 'Step'+this.currentPage;
    }
    get hasUnitData(){
        return (this.unitData && this.unitData.length >0);
    }
    get multiPurposeOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }
    get selectedUnitList(){
        let unitsToReturn = [];
        for(var key in this.selectedUnits){
                unitsToReturn.push(this.selectedUnits[key]);
        }
        return unitsToReturn;
    }
    get disableForwardNavigation(){
        return (!this.selectedUnitList || this.selectedUnitList.length <1 ) ;
    }
    get saleOfferInputParam(){
        var param = [];
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
                                        'offerId':this.selectedUnits[key].offerId,
                                        'selectedPayments':selectedPayments,
                                        'multiPurposeAmountApplicable': (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable )?this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable:false ,
                                        };
                                        param.push(tempUnitSelectionObj);
        }
        
        console.log(param);
        return param;
    }
    get installmentData(){
        var installmentDataToReturn=[];
        
        if(this.selectedUnits[this.currentUnit].salesOfferDetails && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated ){
            for(let i = 0 ; i < this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                if(this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                    for(let j = 0 ; j < this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails.length ; j ++){
                        installmentDataToReturn.push({'Id':this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.Id,
                                            'installmentNumber':this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentNumber__c,
                                            'installmenPercentage':this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentPercentage__c/100,
                                            'total':this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].totalValue});
                    }
                }
            }
        }
        return installmentDataToReturn;
    }

    get offerData(){
        var offerDataToReturn=[];
        
        if(this.selectedUnits[this.currentUnit].salesOfferDetails && this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated ){
            for(let i = 0 ; i < this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated.length ; i ++){
                offerDataToReturn.push({'Id':this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated[i].Id,
                'offerType':this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated[i].OfferType__c,
                'offerOn':this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated[i].OfferOn__c +' '+ (this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated[i].DiscountType__c ? '('+  this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated[i].DiscountType__c +')':''),
                //'offerValue':this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated[i].OfferValue__c,
                'offerValueType':this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated[i].OfferValue__c + ' ' +this.selectedUnits[this.currentUnit].salesOfferDetails.applicableOfferLinesCalculated[i].OfferValueType__c});
            }
        }
        
        return offerDataToReturn;
    }
    connectedCallback(){
        this.getObjectData();
    }

    renderedCallback(){
        if(this.resetFlag){
            this.resetUIValues();
        }
    }

    @wire(unitFinishingValues)
    getunitFinishingValues({ error, data }) {
        if (data) {
            this.unitFinishingVals = data;
            
        } else if (error) {
            this.unitFinishingVals = undefined;
        }
    }

    @wire(unitFurnishingValues)
    getUnitFurnishingValues({ error, data }) {
        if (data) {
            this.unitFurnishingVals = data;
            
        } else if (error) {
            this.unitFurnishingVals = undefined;
        }
    }

    getObjectData(){
        getsObjectType({recordID :this.recordId })
        .then(data => {
            for(var key in data){
                this.sObjectRecordType = key;
                this.sObjectRecord = data[key];
            }
            if(this.sObjectRecordType == 'Opportunity'){
                this.populateProjects(); 
            }
            
        })
        .catch(error => {
            // console.log('Unable to sObject data ==>'+ JSON.stringify(error));
            this.sObjectRecordType = undefined;
            this.sObjectRecord = undefined;
            this.isLoading=false;
        });
    }

    populateProjects(){
        getAllProjects()
        .then(data => {
            this.projectList = data;
            for(let i=0;i<data.length; i++){
                if(this.sObjectRecord && this.sObjectRecord.Project__c && data[i].label == this.sObjectRecord.Project__c){
                    this.selectedProject = data[i].value;
                    break;
                }
            }
            if(this.selectedProject){
                this.populateBuildings();
            }else{
                this.isLoading=false;
            }
            
        })
        .catch(error => {
            // console.log('Unable to fetch Project data ==>'+ JSON.stringify(error));
            this.projectList = undefined;
            this.isLoading=false;
        });
    }

    handleProjectChange(event){
        this.unitData=undefined;
        this.isLoading=true;
        this.selectedProject=event.detail.value;
        this.populateBuildings();
    }

    populateBuildings(){
        getAllBuildings({projectId :this.selectedProject })
        .then(data => {
            this.buildingList = data;
            this.selectedBuilding = (data && data[0] && data[0].value)?data[0].value:'';

            this.populateUnitData();
            this.isLoading=false;
        })
        .catch(error => {
            // console.log('Unable to fetch Building data ==>'+ JSON.stringify(error));
            this.buildingList = undefined;
            this.isLoading=false;
        });
    }

    handleBuildingChange(event){
        this.unitData=undefined;
        this.isLoading=true;
        this.selectedBuilding=event.detail.value;
        this.populateUnitData();
    }

    populateUnitData(){
        
        getUnitDetails({buildingsId : this.selectedBuilding  })
        .then(data => {
            this.unitData=[];
            if(data.unitDetailList){
                for(let i = 0 ; i < data.unitDetailList.length ; i ++){
                    this.unitData.push( data.unitDetailList[i].unitDetails);
                }
            }
            //console.log([...this.unitData]);
            this.isLoading=false;
            
        })
        .catch(error => {
            this.isLoading=false;
        });
    }

    handleMenuAction(event){
        //Validation
        if(this.currentPage == 2 && event.target.name=='forward' ){
            for(var key in this.selectedUnits){
                if(this.selectedUnits[key].selectionStatus){
                    var selectedPaymentPlanCounter = 0;
                    if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                        for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                            if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                                selectedPaymentPlanCounter++;
                            }
                        }
                        if(selectedPaymentPlanCounter ==0 ){
                            const evt = new ShowToastEvent({
                                title: 'Invalid Payment Plans Selection',
                                message: 'Please select payment plan for the '+ this.selectedUnits[key].unitName ,
                                variant: 'error',
                            });
                            this.dispatchEvent(evt);
                            this.isLoading=false;
                            return;
                        }
    
                    }
                }
            }
        }
        if(event.target.name=='forward'){
            this.currentPage++;
        }else if(event.target.name=='back'){
            this.currentPage--;
        }
        if(this.currentPage == 2){
            this.resetFlag=true;
        }else{
            this.resetFlag=false;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'show_details':
                this.navigateToDetails(row);
                break;
            default:
        }
    }
    navigateToDetails(row){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                actionName: 'view',
            },
        });
    }
    selectRow(event){
        const selectedRows = event.detail.selectedRows;
        //Remove other records
        /*for(var key in this.selectedUnits){
            var decoupledVals = [...this.selectedUnits[key]];
            decoupledVals.selectionStatus=false;
            this.selectedUnits[key]=decoupledVals;
        }*/
        this.selectedUnits={};
        // Set selected records
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedUnits[selectedRows[i].Id] = { 'selectionStatus':true,
                                                            'unitId': selectedRows[i].Id, 
                                                            'unitName':selectedRows[i].Name,
                                                            'salesOfferDetails':undefined};
        }
        
    }
    handlePaymentUnitSelect(event){
        //GET THE OFFERS
        this.isLoading=true;
        this.currentUnit = event.target.value;
        if(!this.selectedUnits[event.target.value].salesOfferDetails ){
            this.generateOffer();
        }else{
            this.isLoading=false;
            //this.populateSelectedValsFlag=true;
        }
        this.resetFlag=true;
    }
    handleOfferUnitSelect(event){
        //GET THE OFFERS
        this.currentUnit = event.target.value;
    }
    handleCustomerNameChnage(event){
        this.customerName = event.target.value;
    }
    generateOffer(){
        generateSalesOffer({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId  })
        .then(data => {
            //Iterator to set data for all units
            this.availableEOIs=undefined;
            for(var key in this.selectedUnits){
                this.selectedUnits[key].salesOfferDetails=data[key];
                
            }
            console.log(data);
            this.isLoading=false;
        })
        .catch(error => {
            this.isLoading=false;
        });
    }

   
    sendSalesOfferEmail(event){
        this.isLoading=true;
        var singleUnitIdToSend = event.target.dataset.unitId;
        sendSalesOfferPDF({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId ,customerName : this.customerName , singleUnitId : singleUnitIdToSend})
        .then(data => {

            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Email have been sent successfully.',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
        })
        .catch(error => {
            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Sending email failed.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            
        });
    }
    generateOfferPDF(event){
        this.isLoading=true;
        var singleUnitIdToSend = event.target.dataset.unitId;
        generateOfferPDF({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId ,customerName : this.customerName , singleUnitId : singleUnitIdToSend})
        .then(data => {

             //New method to delete + Create attachments
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: data,
                actionName: 'view',
            },
        });
        this.isLoading=false;
        })
        .catch(error => {
            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Sending email failed.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            
        });
    }

    selectPaymentPlan(event){ 
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        //set all as false
        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
            pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected = false;
        }
        
        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){

            if(pd.salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id == event.target.value){
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected= true;
                pd.paymentPlanId=(event.target.value == '') ? undefined : event.target.value;
                break;
            }
        }
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
    }

    handleOfferChange(event){
        this.isLoading=true;

        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.offerId=(event.detail.value == '') ? undefined : event.detail.value;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
        
    }
    handleDesignChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitDesignRecordId=(event.detail.value == '') ? undefined : event.detail.value;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
       
    }

    handleMultiPurposeRoomChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.salesOfferDetails.multiPurposeAmountApplicable=(event.detail.value == 'Yes') ? true : false;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
    }
    handleUnitFinishesChange(event){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitFinishes= event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
    }
    handleUnitFurnishingChange(event){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitFurnishing= event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
    }
    
    resetUIValues(){
        //get Fields
        let selectedPaymentPlan = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].selectedPaymentPlan");
        let selectedOffer = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].selectedOffer");
        let multiPurposeRoomField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].multiPurposeRoomField");
        let unitDesiagnField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].unitDesiagnField");
        let unitFinishingField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].unitFinishingField");
        let unitFurnishingField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].unitFurnishingField");
        //Populate Value
        if(selectedOffer) {selectedOffer.value=this.selectedUnits[this.currentUnit].offerId ;}
        if(multiPurposeRoomField){ multiPurposeRoomField.value=this.selectedUnits[this.currentUnit].salesOfferDetails.multiPurposeAmountApplicable?'Yes':'No';}
        if(unitDesiagnField){unitDesiagnField.value=this.selectedUnits[this.currentUnit].unitDesignRecordId;}
        if(unitFinishingField){unitFinishingField.value=this.selectedUnits[this.currentUnit].unitFinishes ;}
        if(unitFurnishingField){unitFurnishingField.value=this.selectedUnits[this.currentUnit].unitFurnishing ;}
        if( selectedPaymentPlan){
            //for reservation wizard if multiple payment are selected then clear selection if one selected then set default
            if(this.selectedUnits[this.currentUnit].salesOfferDetails && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated ){
                for(let i = 0 ; i < this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                    if(this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                        selectedPaymentPlan.value=this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id;
                        break;
                    }
                }
            }
        }

        //if ui is refreshed then exit
        if(selectedOffer){
            this.resetFlag=false;
        }
    }
}