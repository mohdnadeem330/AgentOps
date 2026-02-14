import { LightningElement, api, wire, track } from 'lwc';

import { createRecord } from 'lightning/uiRecordApi';
import getAllProjects from '@salesforce/apex/OpportunityRTOUnitSearchController.getAllProjects';
import getAllBuildings from '@salesforce/apex/OpportunityRTOUnitSearchController.getAllBuildings';
import getRTOUnitDetails from '@salesforce/apex/OpportunityRTOUnitSearchController.getRTOUnitDetails';
import getYearValues from '@salesforce/apex/OpportunityRTOUnitSearchController.fechYearValues';
import saveConfigurations from '@salesforce/apex/OpportunityRTOUnitSearchController.saveConfigurations';
import getsObjectType from '@salesforce/apex/OpportunityRTOUnitSearchController.getsObjectType';
import bookRTO from "@salesforce/apex/OpportunityRTOUnitSearchController.bookRTO";
import getWinReasonPickList from '@salesforce/apex/OpportunityRTOUnitSearchController.getWinReasonPickList';
import getUserStatus from "@salesforce/apex/OpportunityUnitSearchController.getUserStatus";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
import getRegistrationValidation from '@salesforce/apex/OpportunityUnitSearchController.validateRegistrationAllowed';
import getCurrentUserProfile from '@salesforce/apex/OpportunityRTOUnitSearchController.getCurrentUserProfile';

//import getProjectToProjectBudget from "@salesforce/apex/OpportunityUnitSearchController.getProjectToProjectBudget";

const columns = [
    { label: 'Unit Price', fieldName: 'UnitPrice__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rebate Percentage', fieldName: 'RebatePercentage__c', type: 'number' , editable: true, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rebate Amount', fieldName: 'RebateAmount__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rent', fieldName: 'Rent__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rent Escalation', fieldName: 'RentEscalation__c', type: 'number' , editable: true, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rent Credit Rate', fieldName: 'RentCreditRate__c', type: 'number' , editable: true, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rent Credit', fieldName: 'RentCredit__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}, 
    { label: 'Cummulative Equity', fieldName: 'CummulativeEquity__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}, 
    { label: 'Total Equity', fieldName: 'TotalEquity__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}, 
    { label: 'Total Equity Percentage', fieldName: 'TotalEquityPercentage__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}, 
    { label: 'Buyout Price', fieldName: 'RemainingPayment__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}
];

const columnsReadOnly = [
    { label: 'Unit Price', fieldName: 'UnitPrice__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rebate Percentage', fieldName: 'RebatePercentage__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rebate Amount', fieldName: 'RebateAmount__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rent', fieldName: 'Rent__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rent Escalation', fieldName: 'RentEscalation__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rent Credit Rate', fieldName: 'RentCreditRate__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }},
    { label: 'Rent Credit', fieldName: 'RentCredit__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}, 
    { label: 'Cummulative Equity', fieldName: 'CummulativeEquity__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}, 
    { label: 'Total Equity', fieldName: 'TotalEquity__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}, 
    { label: 'Total Equity Percentage', fieldName: 'TotalEquityPercentage__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}, 
    { label: 'Buyout Price', fieldName: 'RemainingPayment__c', type: 'number' , editable: false, typeAttributes: {
        step: '0.1',
        minimumFractionDigits: '2',
        maximumFractionDigits: '2'/*,
        currencyCode: 'AED'*/
    }}
];

export default class OpportunityUnitSearch extends NavigationMixin(LightningElement) {
    //Get Opportunity or Lead Ids
   
    redirecPageUrl;
    multiUnitWarning='Configuration will be applicable for all the selected unit(s)';
    @api recordId;
    securityDeposit;
    discountPercetnage;
    scApplicable;
    hmApplicable
    sObjectRecord;
    sObjectRecordType;
    steps = [];
    unitsSelectedList = [];
    pageNumber = 1;
    @track selectedUnits = {};
    @track selectedUnit;
    rtoYearId = {};
    showBudgetModal=false;
    isExport = false
    isLoading = true;
    projectList;
    yearList;
    yearOptionList = [];
    projectRecord;
    @track selectedYearList = [];
    selectedProject;
    buildingList;
    selectedBuilding;
    buildingToPaymentMap = {};
    selectedYearForBooking=[];
    currentUnit;
    currentYear;
    @track 
    configTableDataMap={};
    configTableData=[];
    @track unitDataTable;
    @track selectedYear;
    @track yearWiseTable = [];
    @track yearWiseTableMap = {};
    unitInventoryDetails;
    registrationValidationMessage = 'Not Allowed';
    selectedAction;
    selectedFrequency;
    selectedPaymentMethod='Cheque';
    rtpConfigurationDetails;
    startDate;

    rowOffset=0;
    columns = columns;
    columnsReadOnly=columnsReadOnly;
    pageNumber = 1;
    @track isButtonVisible = false;
    isBlocked = false;
    /* Default methods */
    connectedCallback() {
        console.log('connectedCallback');
        this.getUrStatus();
        if(!this.isBlocked){
        this.gesObjectData();
    }
    }
    getUrStatus(){
        getUserStatus()
        .then(data=>{
           this.isBlocked = data;
        }).catch(error => { 
           
        });
    }
    renderedCallback() {
        if (this.refreshUIFlag) {
            this.refreshUI();
        }
        if(!this.redirecPageUrl && this.recordId ){
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view',
                },
            }).then(url => {
                this.redirecPageUrl = url;
            });
        }
    }
    disconnectedCallback() {

    }

    
    /* getters */
    get disablPath() {
        return (this.pageNumber == 1 || this.steps == []);
    }
    get disableProceed() {
        return (this.ConfigureRTO && this.pageNumber == 2);
    }
    get disableBack() {
        return (this.OfferWizard && this.pageNumber == 2 && this.sObjectRecordType == 'Unit__c');
    }
    get disableConfigRTO() {
        return (this.totalSelectedUnits < 1);
    }
    get disableBookRTO() {
        return (this.totalSelectedUnits != 1 || (this.registrationValidationMessage!=undefined && this.registrationValidationMessage!=null && this.registrationValidationMessage!=''));
    }
    get showWarning() {
        return (this.totalSelectedUnits > 1);
    }
   
    get showPage1() {
        return this.pageNumber == 1;
    }
    get showPage2() {
        return this.pageNumber == 2
    }
    get showPage3() {
        return this.pageNumber == 3
    }

    get ConfigureRTO() {
        return (this.selectedAction == 'CONFIGURERTO');
    }

    get totalSelectedUnits() {
        var selectedCountToReturn = 0;
        if (this.selectedUnits) {
            for (var key in this.selectedUnits) {
                if (this.selectedUnits[key].selectionStatus) {
                    selectedCountToReturn++;
                }
            }
        }
        return selectedCountToReturn;
    }

    get selectedUnitList() {
        let unitsToReturn = [];
        for (var key in this.selectedUnits) {
            if (this.selectedUnits[key].selectionStatus) {
                unitsToReturn.push(this.selectedUnits[key]);
            }
        }
        return unitsToReturn;
    }
    get budgetCheckProfileAllowed() {
        return (this.prfName == 'System Administrator' || this.prfName == 'Sales Manager')
    }

    get totalSelectedUnitProject() {
        var selectedCountToReturn = 0;
        const filteredUnitsProjects = this.selectedUnitList.reduce((acc, current) => {
            const x = acc.find(item => item.ProjectName === current.ProjectName);
            if (!x) {
                return acc.concat([current]);
            } else {
                return acc;
            }
        }, []);
        selectedCountToReturn = filteredUnitsProjects.length;
        return selectedCountToReturn;
    }

    get selectedUnitPaymentList() {
        let unitsToReturn = [];
        for (var key in this.selectedUnits) {
            if (this.selectedUnits[key].selectionStatus) {
                unitsToReturn.push(this.selectedUnits[key]);
            }
        }
        return unitsToReturn;
    }

    /* Apex Call Methods */

    navigateToBookingMemoRecord() {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.lastCreatedBookingMemoId,
                objectApiName: 'BookingMemo__c',
                actionName: 'view'

            }
        });
    }
    @wire(getRecord, { recordId: '$recordId', fields: ['account.OwnerId'] })
    mom;

    @wire(getRecord, {
        recordId: strUserId,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.prfName = data.fields.Profile.value.fields.Name.value;
        }
    }

    @wire(getCurrentUserProfile, {}) 
    userData({ error, data }) {
        if(data) {
            if(data.Profile.Name == "System Administrator") {    
                this.isButtonVisible = true;
            }
        } else if(error) {
            // error handling
            console.error(error.body.message);
        }
    }


    validateRegistrationEliginility(){
        getRegistrationValidation({opportunityId :this.recordId })
        .then(data => {
            this.registrationValidationMessage=data;
        }).catch(error => {
            // console.log('Unable to Registration elligibility ==>'+ JSON.stringify(error));
            this.registrationValidationMessage = 'Not Allowed';
            this.isLoading=false;
        });
    }

    get frequencyOptions(){
        //Frequecy options for RTO Booking
        return [
            { label: 'Yearly', value: '1' },
            { label: 'Half Yearly', value: '2' },
            { label: 'Quarterly', value: '4' },
            { label: 'Monthly', value: '12' }
        ];
    }
    get paymentOptionsForRTO(){
        //Frequecy options for RTO Booking
        return [
            { label: 'Cheque', value: 'Cheque' }
        ]
    }
    

  
    
    async handleMenuAction(event) {
        if (event.target.name == 'CONFIGURERTO') {
            this.selectedAction = event.target.name;
            this.steps = []
            this.steps.push({ label: 'Unit Selection', value: 1 });
            this.steps.push({ label: 'Select Years', value: 2 });
            this.steps.push({ label: 'Configure RTO', value: 3 });
            this.pageNumber = this.pageNumber + 1;
            this.isConfigureRTO = true;
            this.isBookingRTO = false;
        } else if (event.target.name == 'BOOKRTO') {
            this.isLoading=true;
            this.selectedAction = event.target.name;
            this.steps = []
            this.steps.push({ label: 'Unit Selection', value: 1 });
            this.steps.push({ label: 'Book RTO', value: 2 });
            //this.pageNumber = this.pageNumber + 1;
            this.isBookingRTO = true;
            this.isConfigureRTO = false;
            this.populateBookingData();
        } else if (event.target.name == 'BACK') {
            this.pageNumber = this.pageNumber - 1;
            if(this.pageNumber == 1){
                this.reselectUnits();
            }
        }else if(event.target.name == 'FORWARD'){

            this.securityDeposit =this.template.querySelector(".securityDeposit").value;
            this.discountPercetnage =this.template.querySelector(".discountPercetnage").value;
            this.scApplicable =this.template.querySelector(".scApplicable").checked;
            this.hmApplicable =this.template.querySelector(".hmApplicable").checked;
            if(this.isConfigureRTO && this.selectedYearForBooking.length  < 1 ){
                const evt = new ShowToastEvent({
                    title: 'Selection required',
                    message: 'Please select the years before proceeding',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                return;
            }else if(this.securityDeposit== 0 || this.securityDeposit==undefined || this.securityDeposit >100 ){
                const evt = new ShowToastEvent({
                    title: 'Security Deposit',
                    message: 'Please enter valid Security Deposit % before proceeding',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                return;
            }
            else if(this.discountPercetnage== 0 || this.discountPercetnage==undefined || this.discountPercetnage >100 ){
                const evt = new ShowToastEvent({
                    title: 'Security Deposit',
                    message: 'Please enter valid Discount % before proceeding',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                return;
            }
            this.populateTableMapping();
            //this.pageNumber = this.pageNumber + 1;
        }else if(event.target.name == 'SAVECONFIG'){
            this.saveRTOConfigs();
        }
        if(this.pageNumber==2){
            this.refreshUIFlag=true;
        }
    }
    refreshUI(){
        let yearSelection = this.template.querySelector(".yearSelection");
        let securityDeposit = this.template.querySelector(".securityDeposit");

        if(yearSelection){
            yearSelection.value=this.selectedYearForBooking;
            securityDeposit.value = this.securityDeposit;
            this.template.querySelector(".discountPercetnage").value =  this.discountPercetnage;
            this.template.querySelector(".scApplicable").checked = this.scApplicable;
            this.template.querySelector(".hmApplicable").checked = this.hmApplicable;
            this.refreshUIFlag=false;
        }
    }

    reselectUnits(){
        let tempTable = JSON.parse(JSON.stringify(this.unitDataTable));
        this.unitDataTable=[];
        for (let i = 0; i < tempTable.length; i++) {
            tempTable[i].isSelected = this.selectedUnits[tempTable[i].unitDetails.Id] ? this.selectedUnits[tempTable[i].unitDetails.Id].selectionStatus :false;
        }
        this.unitDataTable=tempTable;
    }


    gesObjectData() {
        getsObjectType({ recordID: this.recordId })
            .then(data => {
                for (var key in data) {
                    this.validateRegistrationEliginility();
                    this.sObjectRecordType = key;
                    this.sObjectRecord = data[key];
                }
                
                if (this.sObjectRecordType == 'Opportunity') {
                    this.populateProjects();
                }
            })
            .catch(error => {                
                this.sObjectRecordType = undefined;
                this.sObjectRecord = undefined;
                this.isLoading = false;
            });
    }   


    @wire(getYearValues)
    getYearValueData({ error, data }) {
        if (data) {
            this.yearList = data;
            
        } else if (error) {
            this.yearList = undefined;
        }
    }
    winReasonOptions;
    @wire(getWinReasonPickList)
    getWinReasonValues({ error, data }) {
        if (data) {
            this.winReasonOptions = data;
            
        } else if (error) {
            this.winReasonOptions = undefined;
        }
    }

    populateProjects() {
        getAllProjects()
            .then(data => {
                this.projectList = data;
                for (let i = 0; i < data.length; i++) {
                    if (this.sObjectRecord && this.sObjectRecord.Project__c && data[i].label == this.sObjectRecord.Project__c) {
                        this.selectedProject = data[i].value;
                        break;
                    }
                }
                if (this.selectedProject) {
                    this.populateBuildings();
                } else {
                    this.isLoading = false;
                }

            })
            .catch(error => {
                // console.log('Unable to fetch Project data ==>'+ JSON.stringify(error));
                this.projectList = undefined;
                this.isLoading = false;
            });
    }

    /*projectToProjectBudget() {
        getProjectToProjectBudget({ projectId: this.selectedProject })
            .then(data => {
                this.projectRecord = data;
            })
            .catch(error => {
                this.projectRecord = false;
            });
    }*/
    populateBuildings() {
        //this.projectToProjectBudget();
        getAllBuildings({ projectId: this.selectedProject })
            .then(data => {
                this.buildingList = data;
                this.selectedBuilding = (data && data[0] && data[0].value) ? data[0].value : '';

                this.populateUnitData();
                this.isLoading = false;
            })
            .catch(error => {
                // console.log('Unable to fetch Building data ==>'+ JSON.stringify(error));
                this.buildingList = undefined;
                this.isLoading = false;
            });
    }


    populateUnitData() {
        this.isLoading = true;
        this.unitDataTable=[];
        getRTOUnitDetails({ buildingsId: this.selectedBuilding })
            .then(data => {
                this.unitDataTable = data;
                
                //this.checkEligiblity();
                if (this.unitDataTable.length <= 0) {
                    const evt = new ShowToastEvent({
                        title: 'Units',
                        message: 'No unit available for selected filter criteria ',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }else{
                    this.reselectUnits();
                }
                this.isLoading = false;

            })
            .catch(error => {
                console.log('Unable to fetch Unit data ==>'+ JSON.stringify(error));
                this.isLoading = false;

            });
    }

    /* Handler Methods */
    handleProjectChange(event) {
        this.unitDataTable = undefined;
        this.isLoading = true;
        this.selectedProject = event.detail.value;
        //this.selectedUnits={};
        this.populateBuildings();
    }

    handleBuildingChange(event) {
        this.unitDataTable = undefined;
        this.isLoading = true;
        this.selectedBuilding = event.detail.value;

        this.populateUnitData();
    }

    handleRowSelect(event) {
        this.isLoading = true;
        if (event.target.checked) {
            for (let i = 0; i < this.unitDataTable.length; i++) {
                if(this.unitDataTable[i].unitDetails.Id == event.target.dataset.id){
                    this.selectedUnits[event.target.dataset.id] = {
                        'selectionStatus': event.target.checked,
                        'unitId': event.target.dataset.id,
                        'unitName': event.target.dataset.unitName,
                        'configurations': this.unitDataTable[i].configurations,
                        'unitDetails':this.unitDataTable[i].unitDetails
                    };
                    console.log(JSON.stringify(this.unitDataTable[i].configurations));
                    break;
                }
            }
            console.log(JSON.stringify(this.selectedUnits[event.target.dataset.id]));
            
        } else {
            this.selectedUnits[event.target.dataset.id].selectionStatus = false;
        }
        this.isLoading = false;
    }

    

    yearSelectionDone=true;
    handleActiveConfig(event){
        console.log('Unit Logged'+ event.target.value);
        try{
            this.isLoading=true;
            this.yearSelectionDone=false;
            this.currentUnit = event.target.value;
            setTimeout(()=>{
                if(!this.yearSelectionDone){
                    this.populateTableDate();
                }
            },2000)
        }catch(e){
            console.log(e);
             this.isLoading=true;
        }
    }
    handleYearConfig(event){
        this.isLoading=true;
        this.currentYear = event.target.value;
        this.yearSelectionDone=true;
        this.populateTableDate();
    }
    populateTableDate(){
        this.configTableData=[];
        let uKey = this.currentUnit+'_'+this.currentYear;
        if(this.configTableDataMap[uKey]){
            this.configTableData=this.configTableDataMap[uKey].details.RTOLines__r;
        }
        this.isLoading=false;
    }

    saveConfigurationValues(){
        this.isLoading=true;
        var selectedUnitConfig = [];
        for (var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                selectedUnitConfig.push(key);
            }
        }
        var rtoConfig = [];
        var rtoConfigLines = [];
        for (var key in this.configTableDataMap){
            rtoConfig.push(this.configTableDataMap[key].details);
            for(let i = 0; i< this.configTableDataMap[key].details.RTOLines__r.length ; i++ ){
                rtoConfigLines.push(this.configTableDataMap[key].details.RTOLines__r[i]);
            }
        }
        //TODO Validation If needed
        saveConfigurations({unitIds : selectedUnitConfig  , years : this.selectedYearForBooking, rtoConfig: rtoConfig, rtoConfigLines: rtoConfigLines, securityDeposit : this.securityDeposit ,discountPercetnage :  this.discountPercetnage ,scApplicable: this.scApplicable , hmApplicable: this.hmApplicable})
        .then(data => {

            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Configuration Saved',
                message: 'Configuration Saved successfully.',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            //Hard Refresh
            setTimeout(() => {
                window.location.href=this.redirecPageUrl;
            }, 500);
        })
        .catch(error => {
            console.log('config error '+JSON.stringify(error));
            const evt = new ShowToastEvent({
                title: 'Unable to save configuration',
                message: 'Error while storing the configuration records '+ error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
        });
    }


    draftValues = [];

    handleSave(event) {
        const updatedFields = event.detail.draftValues;
        //We get updated field and the key field
        this.isLoading=true;        
        for (var key in this.configTableDataMap){
            let tempObj= JSON.parse(JSON.stringify(this.configTableDataMap[key])); 
            if(tempObj.details.Years__c == this.currentYear){
                for(let i = 0; i< tempObj.details.RTOLines__r.length ; i++ ){
                    //Compare with Draft Vals and Update
                    for(let j=0;j<updatedFields.length ; j++){
                        if(updatedFields[j].YearNumber__c == tempObj.details.RTOLines__r[i].YearNumber__c ){
                            if(updatedFields[j].RentEscalation__c){
                                tempObj.details.RTOLines__r[i].RentEscalation__c = updatedFields[j].RentEscalation__c
                            }
                            if(updatedFields[j].RebatePercentage__c){
                                tempObj.details.RTOLines__r[i].RebatePercentage__c = updatedFields[j].RebatePercentage__c
                            }
                            if(updatedFields[j].RentCreditRate__c){
                                tempObj.details.RTOLines__r[i].RentCreditRate__c = updatedFields[j].RentCreditRate__c
                            }
                            break;
                        }
                    }
                }
            }
            this.calculatedRTOLine(tempObj.details.RTOLines__r);
            this.configTableDataMap[key]=tempObj;
        }
        this.populateTableDate();
        this.draftValues=[];
    }

    availableYearsForBooking=[];
    availableYearsToConfigDataBooking={};
    selectedConfig={}
    populateBookingData(){
        this.isLoading=true;
        this.availableYearsForBooking=[];
        this.availableYearsToConfigDataBooking={};
        this.selectedConfig={}
        this.availableSecurityDeposit=0;
        //Iterate over all records and set the
        for (var key in this.selectedUnits){
            var yearConfigFound=false;
            if(this.selectedUnits[key].selectionStatus){
                for (var kc in this.selectedUnits[key].configurations){
                    this.availableYearsForBooking.push( { label: kc, value: kc });
                    this.availableYearsToConfigDataBooking[kc] =  this.selectedUnits[key].configurations[kc];
                    yearConfigFound=true;
                }
                    
                if(!yearConfigFound){
                    const evt = new ShowToastEvent({
                        title: 'Unable to fetch configuration',
                        message: 'Please makesure the configuration is defined for the selected unit',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return;
                }
                
            }
        }
        this.pageNumber = this.pageNumber + 1;
        this.isLoading=false;
    }
    calculatedDeposit;
    handleBookingYearSelect(event){
        this.selectedConfig = this.availableYearsToConfigDataBooking[event.target.value];
        this.calculatedDeposit = (this.availableYearsToConfigDataBooking[event.target.value].details.SecurityDepositPercent__c * this.availableYearsToConfigDataBooking[event.target.value].details.RTOLines__r[0].Rent__c) / 100;
    }
    bookRTO(){

        var isError =false;
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value ){
                isError =true;
            }
        });
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value ){
                isError =true;
            }
        });

        if(isError){
            const evt = new ShowToastEvent({
                title: 'Reqired Fields Missing',
                message: 'Please populate all the fields before submitting',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }else{
            this.isLoading=true;
            let startDate = new Date(this.template.querySelector(".startDate").value);
            let paymentMode = this.template.querySelector(".paymentMode").value;
            let frequency = this.template.querySelector(".frequency").value;
            let winReason = this.template.querySelector(".winReason").value;
            let securityDeposit = this.template.querySelector(".securityDeposit").value;
            console.log(startDate);
            console.log(paymentMode);
            console.log(frequency);
            console.log(winReason);
            console.log(securityDeposit);
            bookRTO({opportunityId : this.recordId , configID : this.selectedConfig.details.Id ,startDate : startDate, frequency: frequency , paymentMode : paymentMode,winReason:winReason , securityDepositAmount : securityDeposit })
            .then(data => {
                console.log(data);
                if(data && data['result'] && data['result']=='success'){
                    const evt = new ShowToastEvent({
                        title: 'RTO Booked',
                        message: 'RTO booking completed successfully.',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    //Hard Refresh
                    setTimeout(() => {
                        window.location.href=this.redirecPageUrl;
                    }, 500);
                }else if(data && data['result'] ){
                    const evt = new ShowToastEvent({
                        title: 'RTO Booking Failed',
                        message: 'RTO Booking failed '+ data['result'],
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }else{
                    const evt = new ShowToastEvent({
                        title: 'RTO Booking Failed',
                        message: 'RTO Booking failed '+ data,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
                
                this.isLoading=false;
            })
            .catch(error => {
                console.log(error);
                const evt = new ShowToastEvent({
                    title: 'Unable to create booking',
                    message: 'Error while creating booking '+ error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading=false;
            });
        }
    }
    populateTableMapping(){
        this.isLoading=true;
        this.configTableDataMap={};
        //Iterate over all records and set the
        for (var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                console.log('Selected' +key );
                for(let i=0; i<  this.selectedYearForBooking.length ; i++){
                    console.log('Selected Year' +this.selectedYearForBooking[i] );
                    var yearConfigFound=false;
                    if(!this.currentYear){
                        this.currentYear=this.selectedYearForBooking[i];
                    }
                    let uKey = key+'_'+this.selectedYearForBooking[i];
                    console.log('Selected uKey' +uKey);
                    for (var kc in this.selectedUnits[key].configurations){
                        if(this.selectedUnits[key].configurations[kc].uKey == uKey){
                            this.configTableDataMap[uKey] = this.selectedUnits[key].configurations[kc];
                            yearConfigFound=true;
                            break;
                        }
                    }
                    console.log('flag yearConfigFound' +yearConfigFound);
                    if(!yearConfigFound){
                        let yearConfig=[];
                        for(let yearVal = 1; yearVal<= Number(this.selectedYearForBooking[i].split(' ')[0]) ; yearVal++){
                            yearConfig.push({
                                'Name':yearVal + '-' +this.selectedUnits[key].unitDetails.Name +'-'+ this.selectedYearForBooking[i],
                                'YearNumber__c':yearVal,
                                'RTOConfiguration__c': 0,
                                'UnitPrice__c':this.selectedUnits[key].unitDetails.SellingPrice__c,
                                'RebatePercentage__c': 0,
                                'RebateAmount__c': 0,
                                'Rent__c': yearVal==1 ? this.selectedUnits[key].unitDetails.MarketLeaseRent__c : 0,
                                'RentEscalation__c': 0,
                                'RentCreditRate__c': 0,
                                'RentCredit__c': 0,
                                'CummulativeEquity__c': 0,
                                'TotalEquity__c': 0,
                                'TotalEquityPercentage__c': 0,
                                'RemainingPayment__c':0,
                                'Unit__c':key,
                                'Years__c':this.selectedYearForBooking[i]
                            });
                        }
                        let tempObj = {
                            'yearConfig': this.selectedYearForBooking[i],
                            'details':{
                                'Name':this.selectedUnits[key].unitDetails.Name +'-'+ this.selectedYearForBooking[i],
                                'BuildingSectionName__c': this.selectedUnits[key].unitDetails.BuildingSectionName__c,
                                'Project__c': this.selectedUnits[key].unitDetails.Project__c,
                                //'EndDate__c':this.selectedUnits[key].unitDetails.BuildingSectionName__c,
                                //'StartDate__c':this.selectedUnits[key].unitDetails.BuildingSectionName__c,
                                'Unit__c': key,
                                'Years__c': this.selectedYearForBooking[i],
                                'RTOLines__r':yearConfig
                            },
                            'uKey':uKey
                        }
                        this.configTableDataMap[uKey] = tempObj;
                    }
                }
            }
        }
        this.pageNumber = this.pageNumber + 1;
        this.isLoading=false;
    }
    

    handleChangeYear(event) {
        console.log( event.target.value);
        this.selectedYearForBooking = event.target.value;
    }




    handleYearSelect(event) {
        console.log(event.target.value);
        this.selectedYear = event.target.value;
        let noOfYear = parseInt(this.selectedYear.replace('Years', '').replace('Year', '').trim());
        console.log('noOfYear>>>' + noOfYear);
        let tempYearWiseTable = [];
        if (this.yearWiseTableMap.hasOwnProperty(this.selectedYear)) {
            this.yearWiseTable = this.yearWiseTableMap[this.selectedYear];
        } else {
            let sellingPrice = this.selectedUnit.unitPrice;
            let unitRent = this.selectedUnit.unitRent;
            for (let i = 0; i < noOfYear; i++) {
                tempYearWiseTable.push({
                    'Years__c': (i + 1) + ' Year',
                    'UnitPrice__c': sellingPrice,
                    'RebatePercentage__c': 0,
                    'RebateAmount__c': 0,
                    'Rent__c': unitRent,
                    'RentEscalation__c': 0,
                    'RentCredit__c': 0,
                    'RentCreditRate__c': 0,
                    'CummulativeEquity__c': 0,
                    'TotalEquity__c': 0,
                    'RemainingPayment__c': 0,
                    'TotalEquityPercentage__c': 0,
                    'TotalEquityPercentageReadOnly': 0
                });
            }
            this.yearWiseTableMap[this.selectedYear] = tempYearWiseTable;
            this.yearWiseTable = tempYearWiseTable;
        }
    }

    

    calculatedRTOLine(rtoYearTable) {
        
        for (let i = 0; i < rtoYearTable.length; i++) {
            
            rtoYearTable[i].UnitPrice__c = parseFloat(rtoYearTable[i].UnitPrice__c);

            
            if (i == 0) {                
                rtoYearTable[i].Rent__c = parseFloat(rtoYearTable[i].Rent__c);
                rtoYearTable[i].RentCredit__c = rtoYearTable[i].RentCreditRate__c == 0 ? 0 : ((rtoYearTable[i].Rent__c * rtoYearTable[i].RentCreditRate__c) / 100);
                rtoYearTable[i].CummulativeEquity__c = rtoYearTable[i].RentCredit__c;// rtoYearTable[i].Rent__c;
            } else {
                rtoYearTable[i].Rent__c = rtoYearTable[i].RentEscalation__c == 0 ? rtoYearTable[i - 1].Rent__c : (rtoYearTable[i - 1].Rent__c + ((rtoYearTable[i - 1].Rent__c * rtoYearTable[i].RentEscalation__c) / 100));
                rtoYearTable[i].RentCredit__c = rtoYearTable[i].RentCreditRate__c == 0 ? 0 : ((rtoYearTable[i].Rent__c * rtoYearTable[i].RentCreditRate__c) / 100);
                rtoYearTable[i].CummulativeEquity__c = rtoYearTable[i - 1].CummulativeEquity__c + rtoYearTable[i].RentCredit__c;
            }
            rtoYearTable[i].RebateAmount__c = rtoYearTable[i].RebatePercentage__c == 0 ? 0 : ((rtoYearTable[i].UnitPrice__c * rtoYearTable[i].RebatePercentage__c) / 100);
            

            rtoYearTable[i].TotalEquity__c = rtoYearTable[i].CummulativeEquity__c + rtoYearTable[i].RebateAmount__c;
            rtoYearTable[i].RemainingPayment__c = rtoYearTable[i].UnitPrice__c - rtoYearTable[i].TotalEquity__c;
            rtoYearTable[i].TotalEquityPercentage__c = rtoYearTable[i].TotalEquity__c == 0 ? 0 : ((rtoYearTable[i].TotalEquity__c / rtoYearTable[i].UnitPrice__c) * 100);
            rtoYearTable[i].TotalEquityPercentageReadOnly = rtoYearTable[i].TotalEquity__c == 0 ? 0 : (rtoYearTable[i].TotalEquity__c / rtoYearTable[i].UnitPrice__c);
        }
        //let tempReturn = JSON.parse(JSON.stringify(rtoYearTable));
        //return tempReturn;
    }

    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.showBudgetModal = true;
    }
    closeModal(event) {
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.showBudgetModal = event.detail.isOpen;
    }

}