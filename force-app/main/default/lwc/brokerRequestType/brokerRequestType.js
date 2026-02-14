import { api, LightningElement, track, wire } from 'lwc';
import createMarketingRequest from '@salesforce/apex/ManageRequestController.createMarketingRequest';
import createEventRequest from '@salesforce/apex/ManageRequestController.createEventRequest';
import getConstant from '@salesforce/apex/Utilities.getConstant';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import BROKER_REQUEST_OBJECT from '@salesforce/schema/BrokerRequest__c';
import MARKETING_CATEGORY_FIELD from '@salesforce/schema/BrokerRequest__c.MarketingCategories__c';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getAgencyName from "@salesforce/apex/ManageRequestController.getAgencyName";
import getAgencyDetailsWithClassification from "@salesforce/apex/ManageRequestController.getAgencyDetailsWithClassification";
import monthlyLimit from "@salesforce/apex/ManageRequestController.monthlyLimit";
import quarterlyLimit from "@salesforce/apex/ManageRequestController.quarterlyLimitNew";
import getBufferDays from "@salesforce/apex/ManageRequestController.getBufferDaysBrokerClassification";
import checkForExistingRequestForQuarter from "@salesforce/apex/ManageRequestController.checkForExistingRequestForQuarter";
// Added By Moh Sarfaraj requested by Sanath 26-11-24
import getQuarters from "@salesforce/apex/ManageRequestController.getQuarters";
import getYears from "@salesforce/apex/ManageRequestController.getYears";
import checkExistingRequests from "@salesforce/apex/ManageRequestController.checkExistingRequests";

import MarketingReimRequestCreatedMessage from '@salesforce/label/c.MarketingReimRequestCreatedMessage';
import MarketingReimNonClassBrokers from '@salesforce/label/c.MarketingReimNonClassBrokers';
import MarketingReimMonthErrorMessage from '@salesforce/label/c.MarketingReimMonthErrorMessage';
import MarketingReimbursementEnabledMonths from '@salesforce/label/c.MarketingReimbursementEnabledMonths';

// Added By Moh Sarfaraj requested by Sanath 26-11-24
const quarterMap = new Map([
    ['1', 'Q1'],
    ['2', 'Q2'],
    ['3', 'Q3'],
    ['4', 'Q4']
  ]);

export default class BrokerRequestType extends LightningElement {
    value = '';
    @api type = '';
    
    @track displayEventFields = false;
    @track taxAmountdisabled = false;
    @track taxAmountRequired = true;
    @track displayMarketingFields = false;

    @track displayMarketingErrorMonth = false;
    @track displayMessageErrorMonth = MarketingReimMonthErrorMessage;

    @track displayMarketingNonClassifiedBrokers = false;
    @track displayMessageMarketingNonClassifiedBrokers = MarketingReimNonClassBrokers;

    @track displayMarketingRequestAlreadyCreated = false;
    @track displayMessageMarketingRequestAlreadyCreated = MarketingReimRequestCreatedMessage;

    @track bufferDaysReceived;
    @track selectedOption = '';
    @track showRadioBttons = true;
    @track showSubmitButton = true;
    @track startDateValue;
    @track objectInfo;
    @track endDateValue;
    @track agencyValue = '';
    @track vatRegisterNumber = '';
    @track brokerPremClassification = false;
    @track requestAlreadyCreated = false;
    @track agencyId;
    @track displaySodicAmount = false;
    @track sodicAmountValue;
    @track invoiceAmountValue;
    @track taxAmountValue;
    @track invoiceValue;
    @track totalAmountValue;
    @track invoiceDateValue;
    @track marketingCategoryValue;
    @track marketingCategoriesValue = [];
    @track recordTypeId;
    @track uploadedFiles = [];
    @track fileNamesList = [];
    @track fileNames = '';
    @track marketingRT;
    @track eventRT;
    @track locationValue;
    @track disabledSubmit = false;
    @track monthlyLimitVal = 0;
    @track quarterlyLimitVal = 0;
    @track sodicQuarterlyLimitVal = 0;
    @track consumeLimitVal = 0;
    @track remainingLimitVal = 0;
    @track showSpinner = false;

    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";

    get options() {
        return [
            { label: 'Marketing Reimbursement', value: 'Marketing Reimbursement' },
            { label: 'Event Request', value: 'Event Request' },
        ];
    }

    @wire(getObjectInfo, { objectApiName: BROKER_REQUEST_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (error) {
            const err = error;
        } else if (data) {
            const rtis = data.recordTypeInfos;
            // console.log('rtis' + JSON.stringify(rtis));
            this.eventRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Event Request');
            this.marketingRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Marketing Reimbursement');
        }
    };

    @wire(getPicklistValues, { recordTypeId: '$marketingRT', fieldApiName: MARKETING_CATEGORY_FIELD })
    marketingCategoryVal({ error, data }) {
        console.log('-----'+data);
        
        if (data) {
            this.marketingCategoryOptions = data.values;
             console.log('marketingCategoryOptions>>>>', this.marketingCategoryOptions);
        } if (error) {
             console.log('error>>>>', error);
        }
    }
    
    // Added By Moh Sarfaraj requested by Sanath 26-11-24
    listquarters = []; requestedQuarter; requestedQuarterLabel;
    @wire(getQuarters)  
        getQuarters({error, data}){
            if(data){
                this.listquarters = data;
            }else if(error){
                this.listquarters = undefined;
            }
        };

    listYears = []; requestedYear; requestedYearLabel;
    @wire(getYears)  
    getYears({error, data}){
        if(data){
            this.listYears = data;
        }else if(error){
            this.listYears = undefined;
        }
    };

    

    handleRadioChange(event) {
        this.selectedOption = event.detail.value;
    }

    @track helpText = '';
    @track acceptFileTypeList = [];

    async connectedCallback() {
        // Added by Moh Sarfaraj for BPE-74
        if(this.type){
            this.showRadioBttons = false;
        }

        console.log("-----------------------------");
        console.log("Broker Request Type");
        console.log("-----------------------------");
        // console.log('displayEventFields' + this.displayEventFields);
        this.showSpinner = true;

        await getAgencyDetailsWithClassification().then(result => {
            var data = [];
            data = result;
            this.agencyId                   = data.Id;
            this.agencyValue                = data.Name;
            this.vatRegisterNumber          = data.UAEVATRegisterNumber__c;
            this.brokerPremClassification   = data.BrokerPremiumClassification__c == 'true' ? true:false;
            this.showSpinner                = false;
        }).catch(error => {
            // console.log('error' + JSON.stringify(error));
            this.showSpinner = false;
        });
        
        if(this.vatRegisterNumber == '' || this.vatRegisterNumber == null){
            this.taxAmountdisabled = true;
            this.taxAmountRequired = false;
        }
        let todaysDate = new Date();
        this.invoiceDateValue   = todaysDate.toISOString();

        getConstant({
            messageName: 'FileAcceptedManageRequest'
        }).then(result => {
            var acceptedFile = result.ConstantValue__c;
            if (acceptedFile != undefined && acceptedFile != null && acceptedFile != '') {
                this.helpText = 'Kindly upload files in the format ' + acceptedFile;

                this.acceptFileTypeList = [];
                if (acceptedFile.includes(',')) {
                    this.acceptFileTypeList = acceptedFile.split(',');
                } else {
                    this.acceptFileTypeList.push(acceptedFile);
                }

                for (let i = 0; i < this.acceptFileTypeList.length; i++) {
                    this.acceptFileTypeList[i] = this.acceptFileTypeList[i].trim();
                }
            }
            console.log('error' + this.acceptFileTypeList);
        }).catch(error => {
            // console.log('error' + JSON.stringify(error));
            this.showSpinner = false;
        })

        this.getRequestForAgencyExists();
    }

    async renderedCallback() {
        if (this.type != undefined && this.type != null && this.type != '' && !this.displayEventFields && !this.displayMarketingFields) {
            if (this.type == this.eventRT) {
                this.selectedOption = 'Event Request';
                this.displayEventFields = true;
            } // Updated by Moh Sarfaraj for BPE-74
            else if (this.type == this.marketingRT && this.brokerPremClassification && 
                !this.displayMarketingErrorMonth && !this.displayMarketingNonClassifiedBrokers && 
                !this.displayMessageMarketingRequestAlreadyCreated) {
                    
                this.selectedOption = 'Marketing Reimbursement';
                this.displayMarketingFields = true;
            }
            if (this.displayEventFields || this.displayMarketingFields) {
                this.showRadioBttons = false;
            }
        }
    }

    async getRequestForAgencyExists()
    {
        await checkForExistingRequestForQuarter({
            accountId: this.agencyId,
            invoiceDate: this.invoiceDateValue
        }).then(result => {
            if (result) {
                // this.requestAlreadyCreated = true; // commented By Moh Sarfaraj requested by Sanath 26-11-24
                //alert(isError);
                //this.showToast('Error', 'Reimbursement request already created for the same agency for the quarter', 'error');
            }
        })
        .catch(error => {
            // TODO Error handling
        });  
        
        // Added by Moh Sarfaraj for BPE-74 starts
        if(this.type){
            if(this.type === this.marketingRT){
                this.selectedOption = 'Marketing Reimbursement';
            }else if(this.type === this.eventRT){
                this.selectedOption = 'Event Request';
            }
            this.nextScreen();
        }
        // Added by Moh Sarfaraj for BPE-74 end
    }

    async getBufferDaysLimit(){
        this.showSpinner = true;
        await getBufferDays({
            accountId: this.agencyId
        }).then(result =>{
            this.bufferDaysReceived = result.bufferDays != null ? result.bufferDays : 0;
            this.showSpinner = false;
        }).catch(error =>{
            this.showSpinner = false;
        });
    }

    nextScreen(event) {
        this.showRadioBttons = false;
        if (this.selectedOption == 'Event Request') {
            this.displayEventFields = true;
        } else if (this.selectedOption == 'Marketing Reimbursement') {
            if(this.brokerPremClassification){
                this.handleMarketingScreenVisibilityBasedOnCurrentDate();
            }else{
                this.displayMarketingNonClassifiedBrokers = true;
                this.showSubmitButton = false;
            }
        }
    }

    handleMarketingScreenVisibilityBasedOnCurrentDate()
    {
        let todaysDate = new Date();
        const month = todaysDate.getMonth();
        let showMRFields = false;
        const monthsValue = MarketingReimbursementEnabledMonths.split(',');

        for(let singleMonth in monthsValue){
            if(monthsValue[singleMonth] == month){
                showMRFields = true;
                break;
            }
        }
        
        if(showMRFields){
            if(this.requestAlreadyCreated){
                this.displayMarketingRequestAlreadyCreated = true;
                this.showSubmitButton = false;
            }else{
                this.displayMarketingFields = true;
            }
        }else{
            this.displayMarketingErrorMonth = true;
            // this.displayMarketingFields = false;
            this.showSubmitButton = false;
        }
        
    }

    // Old implememtation as of Feb 2023
    checkMonthlyLimit() {
        this.showSpinner = true;
        monthlyLimit({
            accountId: this.agencyId,
            recordTypeId: this.marketingRT
        }).then(result => {
            // console.log('result>>>' + JSON.stringify(result));
            this.monthlyLimitVal = result.monthlyLimit != null ? result.monthlyLimit : 0;
            this.consumeLimitVal = result.consumeLimit && result.consumeLimit != null ? result.consumeLimit : 0;

            this.remainingLimitVal = this.monthlyLimitVal - this.consumeLimitVal;
            this.showSpinner = false;
        }).catch(error => {
            // console.error('error>>>' + error);
            this.showSpinner = false;
        })
    }

    handleChangeFields(event) {
        if (event.target.name == 'StartDate') {
            this.startDateValue = event.detail.value;
            // console.log('startDateValue' + this.startDateValue);
        }
        if (event.target.name == 'EndDate') {
            this.endDateValue = event.target.value;
            // console.log('end' + this.endDateValue);
        }
        if (event.target.name == 'Location') {
            this.locationValue = event.target.value;
            // console.log('locationValue' + this.locationValue);
        }
        if (event.target.name == 'Invoice') {
            this.invoiceValue = event.target.value;
            // console.log('invoiceValue' + this.invoiceValue);
        }
        if (event.target.name == 'Comments') {
            this.commentsValue = event.target.value;
            // console.log('commentsValue' + this.commentsValue);
        }
        if (event.target.name == 'InvoiceAmount') {
            this.invoiceAmountValue = event.target.value == '' ? 0 : event.target.value;
            //this.totalAmountValue = (this.invoiceAmountValue ? parseInt(this.invoiceAmountValue) : 0)+ (this.taxAmountValue ? parseInt(this.taxAmountValue) : 0) ;
            // console.log('invoiceAmountValue' + this.invoiceAmountValue);
        }
        if (event.target.name == 'IncludeSodic') {
            var sodicChecked = event.target.checked;
            if(sodicChecked){
                this.displaySodicAmount = true;
            }else{
                this.displaySodicAmount = false;
                this.sodicAmountValue = 0;
                this.handleAmtVal_CalTaxAmt(event);
            }
        }
        if (event.target.name == 'SodicInvoiceAmount') {
            this.sodicAmountValue = event.target.value == '' ? 0 : event.target.value;
        }
        if (event.target.name == 'TaxAmount') {
            this.taxAmountValue = event.target.value;
            //this.totalAmountValue = (this.taxAmountValue ? parseInt(this.taxAmountValue) : 0) + (this.invoiceAmountValue ? parseInt(this.invoiceAmountValue) : 0);
            // console.log('commentaxAmountValuetsValue' + this.taxAmountValue);
        }
        if (event.target.name == 'Invoice') {
            this.invoiceValue = event.target.value;
            // console.log('invoiceValue' + this.invoiceValue);
        }
        if (event.target.name == 'InvoiceDate') {
            this.invoiceDateValue = event.target.value;
            // console.log('invoiceDateValue' + this.invoiceDateValue);
        }
        if (event.target.name == 'Marketing Category') {
            this.marketingCategoryValue = event.target.value;
            // console.log('marketingCategoryValue' + this.marketingCategoryValue);
        }
        if (event.target.name == 'Marketing Categories') {
            this.marketingCategoriesValue = event.target.value;
            console.log('marketingCategoriesValue' + this.marketingCategoriesValue);
        }
        /*
        if (this.taxAmountValue && this.invoiceAmountValue && !this.taxAmountdisabled) {
            // Check if entered taxAmountValue is > 5% of entered invoiceAmountValue
            let taxAmountPercent = (this.invoiceAmountValue/100)*5;
            let finalCalculatedTaxAmtLimit = taxAmountPercent.toFixed(2);
                
            if(parseFloat(this.taxAmountValue) <= parseFloat(finalCalculatedTaxAmtLimit)){
                this.totalAmountValue = parseInt(this.taxAmountValue) + parseInt(this.invoiceAmountValue);
            }else{
                this.showToast('Error', 'Tax amount cannot be more than 5% of Invoice Amount', 'error');
            }
            // console.log('ttll>>l' + this.totalAmountValue);
        }
        if(this.invoiceAmountValue && this.taxAmountdisabled){
            this.totalAmountValue = parseInt(this.invoiceAmountValue);
        }
        */
        // Added By Moh Sarfaraj requested by Sanath 26-11-24 
        if (event.target.name == 'requestQuarter') {
            this.requestedQuarter = parseInt(event.target.value);
            this.requestedQuarterLabel = quarterMap.get(event.target.value);
            this.checkExistingRequestsMain();
        }

        if (event.target.name == 'requestYear') {
            this.requestedYear = parseInt(event.target.value);
            this.requestedYearLabel = event.target.value;
            this.checkExistingRequestsMain();
        }
    }

    // Old implememtation as of Feb 2023
    submitDetails() {
        console.log('***inside submit details');
        let today = new Date().toISOString().slice(0, 10);

        if (this.selectedOption == 'Event Request') 
        {
            if ((Date.parse(today) > Date.parse(this.startDateValue))) {
                this.showToast('Error', 'Start date should be in future', 'error');
            } else if ((Date.parse(this.startDateValue) > Date.parse(this.endDateValue))) {
                this.showToast('Error', 'End date should be in future', 'error');
            } else if (this.startDateValue && this.endDateValue && this.locationValue) {
                this.disabledSubmit = true;
                // console.log(' this.disabledSubmit----event' + this.disabledSubmit);
                var createEventReq = {
                    'sobjectType': 'BrokerRequest__c',
                    'AgencyName__c': this.agencyId,
                    'Remark__c': this.commentsValue,
                    'StartDate__c': this.startDateValue,
                    'EndDate__c': this.endDateValue,
                    'RecordTypeId': this.eventRT,
                    'Location__c': this.locationValue,
                    'ApprovalStatus__c': 'Draft'
                }

                this.showSpinner = true;
                createEventRequest({
                    createEventReq: createEventReq
                }).then(result => {
                    this.showToast('Success', 'Broker Request record  successfully created', 'success');

                    this.showSpinner = false;
                    this.dispatchEvent(new CustomEvent('typechange', { detail: 'Event Request' }));

                    this.dispatchEvent(new CustomEvent('calldisplayevent', { detail: false }));

                    this.closeModal();
                }).catch(error => {
                    // console.log('error' + JSON.stringify(error));
                    this.showSpinner = false;
                })
            } else {
                this.showToast('Error', 'Please fill required fields', 'error');
            }
        } 
        //Else block - If recordType is Marketing Request
        else 
        {
            let isError = false;
            if (this.remainingLimitVal < 0 || this.remainingLimitVal < this.totalAmountValue) {
                isError = true;
                this.showToast('Error', 'You have exceeded your monthly limit', 'error');
            } else if ((Date.parse(today) < Date.parse(this.invoiceDateValue))) {
                isError = true;
                this.showToast('Error', 'Invoice date cannot be in future', 'error');
            } else {
                var invDate = new Date(this.invoiceDateValue);
                var tdate = new Date(today);
                const diffTime = Math.abs(tdate - invDate);
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

                if (diffDays > 30) {
                    isError = true;
                    this.showToast('Error', 'Invoice date should be within 30 days', 'error');
                }
            }
            if (!isError && this.invoiceAmountValue && this.invoiceValue && this.invoiceDateValue && this.marketingCategoriesValue ) {
                this.disabledSubmit = true;
                // console.log(' this.disabledSubmit----Marketing' + this.disabledSubmit);
                var createMarketingReq = {
                    'sobjectType': 'BrokerRequest__c',
                    'AgencyName__c': this.agencyId,
                    'Remark__c': this.commentsValue,
                    'Invoice__c': this.invoiceValue,
                    'InvoiceDate__c': this.invoiceDateValue,
                    //'MarketingCategory__c': this.marketingCategoryValue,
                    'MarketingCategories__c': this.marketingCategoriesValue,
                    'TaxAmount__c': this.taxAmountValue,
                    'InvoiceAmount__c': this.invoiceAmountValue,
                    'RecordTypeId': this.marketingRT,
                    'TotalAmount__c': this.totalAmountValue,
                    'ApprovalStatus__c': 'Draft'
                }

                this.showSpinner = true;
                createMarketingRequest({
                    filesToInsert: this.uploadedFiles,
                    createMarketingReq: createMarketingReq
                }).then(result => {
                    this.showToast('Success', 'Broker Request record  successfully created', 'success');
                    this.showSpinner = false;
                    this.dispatchEvent(new CustomEvent('typechange', { detail: 'Marketing Reimbursement' }));

                    this.dispatchEvent(new CustomEvent('calldisplayevent', { detail: true }));

                    this.closeModal();
                }).catch(error => {
                    // console.log('error' + JSON.stringify(error));
                    this.showSpinner = false;
                })
            } else if (!isError) {
                this.showToast('Error', 'Please fill required fields', 'error', 'dismissable');
            }
        }
    }


    // New Implementation to consider amount for quarterly
    async submitDetailsNew()
    {
        console.log('***inside submit details');
        let today = new Date().toISOString().slice(0, 10);

        if (this.selectedOption == 'Event Request') 
        {
            if ((Date.parse(today) > Date.parse(this.startDateValue))) {
                this.showToast('Error', 'Start date should be in future', 'error');
            } else if ((Date.parse(this.startDateValue) > Date.parse(this.endDateValue))) {
                this.showToast('Error', 'End date should be in future', 'error');
            } else if (this.startDateValue && this.endDateValue && this.locationValue) {
                this.disabledSubmit = true;
                // console.log(' this.disabledSubmit----event' + this.disabledSubmit);
                var createEventReq = {
                    'sobjectType': 'BrokerRequest__c',
                    'AgencyName__c': this.agencyId,
                    'Remark__c': this.commentsValue,
                    'StartDate__c': this.startDateValue,
                    'EndDate__c': this.endDateValue,
                    'RecordTypeId': this.eventRT,
                    'Location__c': this.locationValue,
                    'ApprovalStatus__c': 'Draft'
                }

                this.showSpinner = true;
                createEventRequest({
                    createEventReq: createEventReq
                }).then(result => {
                    this.showToast('Success', 'Broker Request record  successfully created', 'success');

                    this.showSpinner = false;
                    this.dispatchEvent(new CustomEvent('typechange', { detail: 'Event Request' }));

                    this.dispatchEvent(new CustomEvent('calldisplayevent', { detail: false }));

                    this.closeModal();
                }).catch(error => {
                    // console.log('error' + JSON.stringify(error));
                    this.showSpinner = false;
                })
            } else {
                this.showToast('Error', 'Please fill required fields', 'error');
            }
        } 
        //Else block - If recordType is Marketing Request
        else
        {
            // alert('***inside marketing details1');
            let isError = false;
            
            if (this.invoiceAmountValue && this.invoiceValue 
                && this.invoiceDateValue && this.marketingCategoriesValue.length > 0 &&
                this.totalAmountValue && this.requestedQuarter && this.requestedYear)
            {
                // alert('***inside marketing details2');
                /*
                if ((Date.parse(today) < Date.parse(this.invoiceDateValue))) {
                    isError = true;
                    this.showToast('Error', 'Invoice date cannot be in future', 'error');
                } else if(this.invoiceDateValue != null)
                {
                    let invoiceDate = new Date(this.invoiceDateValue);
                    let quarterValue = this.getQuarter(invoiceDate);
                    let startDate = new Date(this.getStartingDay(quarterValue, invoiceDate));
                    const finalStartDate = new Date(startDate);
                    let startDateAddDays = startDate.setMonth(startDate.getMonth() + 3);
                    let finalEndDate = new Date(startDateAddDays);
                    finalEndDate.setDate(finalEndDate.getDate() + this.bufferDaysReceived);
                    let tdate = new Date();
                    if( tdate.getTime() >= finalStartDate.getTime()
                    && tdate.getTime() <= finalEndDate.getTime()){}
                    else{
                        isError = true;
                        this.showToast('Error', 'Date elapsed and Invoice cannot be requested', 'error');
                    }
                }

                
                if (!isError && this.taxAmountValue && this.invoiceAmountValue && !this.taxAmountdisabled) 
                {
                    // Check if entered taxAmountValue is > 5% of entered invoiceAmountValue
                    let taxAmountPercent = (this.invoiceAmountValue/100)*5;
                    let finalCalculatedTaxAmtLimit = taxAmountPercent.toFixed(2);
                        
                    if(parseFloat(this.taxAmountValue) <= parseFloat(finalCalculatedTaxAmtLimit)){
                        this.totalAmountValue = parseInt(this.taxAmountValue) + parseInt(this.invoiceAmountValue);
                    }else{
                        isError = true;
                        this.showToast('Error', 'Tax amount cannot be more than 5% of Invoice Amount', 'error');
                    }
                    // console.log('ttll>>l' + this.totalAmountValue);
                }
                */
                if(!isError && this.fileNamesList.length < 1){
                    isError = true;
                    this.showToast('Error', 'Kindly upload the attachments', 'error', 'dismissable');
                }

                if(!isError && this.fileNamesList.length > 5){
                    isError = true;
                    this.showToast('Error', 'You Cannot upload more than 5 files', 'error', 'dismissable');
                }
                
                if(!isError && this.hasExistingRequest == true){
                    isError = true;
                    this.showToast('Error', 'You have already submitted the request for this Quarter', 'error', 'dismissable');
                }

                if (!isError) 
                {
                    // alert('quarterResult1');
                    this.showSpinner = true;
                    await quarterlyLimit({
                        accountId: this.agencyId,
                        recordTypeId: this.marketingRT,
                        invoiceDate: this.invoiceDateValue,
                        requestedQuarter : this.requestedQuarter,
                        requestedYear : this.requestedYear// Added By Moh Sarfaraj requested by Sanath 26-11-24
                    }).then(result => {
                        this.showSpinner = false;
                        console.log('quarterResult' + JSON.stringify(result));
                        // alert('quarterResult' + JSON.stringify(result));

                        this.sodicQuarterlyLimitVal     = result.sodicQuarterlyLimit != null ? result.sodicQuarterlyLimit : 0;
                        this.quarterlyLimitVal          = result.quarterlyLimit != null ? result.quarterlyLimit : 0;
                        this.consumeLimitVal            = result.consumeLimit && result.consumeLimit != null ? result.consumeLimit : 0;
                        this.remainingLimitVal          = this.quarterlyLimitVal - this.consumeLimitVal;

                        if (this.remainingLimitVal < 0 || this.remainingLimitVal < this.invoiceAmountValue) {
                            isError = true;
                            this.showToast('Error', 'You have exceeded your quarterly limit', 'error');
                        }
                        if(this.sodicQuarterlyLimitVal < this.sodicAmountValue){
                            isError = true;
                            this.showToast('Error', 'You have exceeded your sodic quarterly limit', 'error');
                        }
                        
                    })
                    .catch(error => {
                        // TODO Error handling
                        console.log('error' + JSON.stringify(error));
                    });
                }


                // Logic to Save the record
                if (!isError){
                    this.disabledSubmit = true;
                    this.showSpinner = true;
                    console.log('submit broker request ' + this.requestedQuarterLabel);
                    var createMarketingReq = {
                        'sobjectType': 'BrokerRequest__c',
                        'AgencyName__c': this.agencyId,
                        'Remark__c': this.commentsValue,
                        'Invoice__c': this.invoiceValue,
                        'InvoiceDate__c': this.invoiceDateValue,
                        //'MarketingCategory__c': this.marketingCategoryValue,
                        'MarketingCategories__c': this.marketingCategoriesValue,
                        'TaxAmount__c': this.taxAmountValue == undefined ? 0 : this.taxAmountValue,
                        'InvoiceAmount__c': this.invoiceAmountValue,
                        'SodicInvoiceAmount__c': this.sodicAmountValue,
                        'RecordTypeId': this.marketingRT,
                        'TotalAmount__c': this.totalAmountValue,
                        'ApprovalStatus__c': 'Draft',
                        'RequestQuarter__c' : this.requestedQuarterLabel,
                        'RequestYear__c': this.requestedYearLabel // Added By Moh Sarfaraj requested by Sanath 26-11-24
                    }

                    await createMarketingRequest({
                        filesToInsert: this.uploadedFiles,
                        createMarketingReq: createMarketingReq
                    }).then(result => {
                            this.showToast('Success', 'Broker Request record  successfully created', 'success');
                        this.showSpinner = false;
                        this.dispatchEvent(new CustomEvent('typechange', {
                            detail: 'Marketing Reimbursement'
                        }));

                        this.dispatchEvent(new CustomEvent('calldisplayevent', {
                            detail: true
                        }));

                        this.closeModal();
                    }).catch(error => {
                        //alert(error);
                        this.showSpinner = false;
                        this.showToast('Error', error.body.message, 'error', 'dismissable');
                        this.disabledSubmit = false;
                        // console.log('error' + JSON.stringify(error));
                    })
                }

            }            

            else{
                this.showToast('Error', 'Please fill required fields', 'error', 'dismissable');
            }

        }

    }


    onFileUpload(event) {
        let files = event.target.files;
        // console.log('files' + files);
        if (files.length > 0 && this.fileNamesList.length < 5) {
            var acceptFileList = [];
            for (let i = 0; i < files.length; i++) {
                let filePieces = files[i].name.split('.');
                let fileType = filePieces[filePieces.length - 1].trim();
                
                if (this.acceptFileTypeList.includes(fileType)) {
                    acceptFileList.push(files[i]);
                }
            }
            if (acceptFileList.length > 0) {
                let filesName = '';
                for (let i = 0; i < acceptFileList.length; i++) {
                    let file = acceptFileList[i];

                    filesName = filesName + file.name + ',';

                    let freader = new FileReader();
                    freader.onload = f => {
                        let base64 = 'base64,';
                        let content = freader.result.indexOf(base64) + base64.length;
                        let fileContents = freader.result.substring(content);
                        this.uploadedFiles.push({
                            Title: file.name,
                            VersionData: fileContents
                        });
                    };
                    freader.readAsDataURL(file);
                }
                this.fileNames = filesName.slice(0, -1);
                this.fileNamesList.push(this.fileNames);
            }
        }else{
            this.showToast('Error', 'Cannot upload more than 5 files', 'error', 'dismissable');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
    }

    handleValidation(event) {

        if (this.selectedOption == 'Event Request') {
            if ((Date.parse(this.startDateValue) > Date.parse(this.endDateValue))) {
                this.showToast('Error', 'End date should be in future', 'error');
            }
        } else if (this.selectedOption == 'Marketing Reimbursement') {
            let today = new Date().toISOString().slice(0, 10);
            if ((Date.parse(today) < Date.parse(this.invoiceDateValue))) {
                this.showToast('Error', 'Invoice date cannot be in future', 'error');
            } else {
                var invDate = new Date(this.invoiceDateValue);
                var tdate = new Date(today);
                const diffTime = Math.abs(tdate - invDate);
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

                if (diffDays > 30) {
                    // console.log('240');
                    this.showToast('Error', 'Invoice date should be within 30 days', 'error');
                }
            }
        }
    }

    handleInvoiceDateValidation(event)
    {
        if (this.selectedOption == 'Event Request') {
            if ((Date.parse(this.startDateValue) > Date.parse(this.endDateValue))) {
                this.showToast('Error', 'End date should be in future', 'error');
            }
        }
        else if (this.selectedOption == 'Marketing Reimbursement') {
            //this.handleInvoiceDateMRvalidation();
        }
    }

    handleInvoiceDateMRvalidation()
    {
            let today = new Date().toISOString().slice(0, 10);
            if ((Date.parse(today) < Date.parse(this.invoiceDateValue))) 
            {
                this.showToast('Error', 'Invoice date cannot be in future', 'error');
            }
            else if(this.invoiceDateValue != null)
            {
                // Below logic finds the quarter, start date and end date of the quarter
                // And checks if created date is with in the range
                let invoiceDate = new Date(this.invoiceDateValue);
                let quarterValue = this.getQuarter(invoiceDate);

                let startDate = new Date(this.getStartingDay(quarterValue, invoiceDate));
                const finalStartDate = new Date(startDate);
                // Add 3 months to start date
                let startDateAddDays = startDate.setMonth(startDate.getMonth() + 3);
                let finalEndDate = new Date(startDateAddDays);
                // Add bufferDays additionally
                finalEndDate.setDate(finalEndDate.getDate() + this.bufferDaysReceived);

                //alert('finalStartDate---->>>'+finalStartDate.toLocaleDateString());
                //alert('finalEndDate---->>>'+finalEndDate.toLocaleDateString());
                // Date: '2023-03-15'
                let tdate = new Date();
                //alert('currentDate:'+tdate.toLocaleDateString());
                

                if( tdate.getTime() >= finalStartDate.getTime()
                && tdate.getTime() <= finalEndDate.getTime()){}
                else{
                    this.showToast('Error', 'Date elapsed and Invoice cannot be requested', 'error');
                }
            }
    }

    getQuarter(date) {
        // Get the month of the given date (0 - 11)
        const month = date.getMonth();
        // Determine the quarter based on the month
        if (month <= 2) {
          return 1; // Q1: January - March
        } else if (month <= 5) {
          return 2; // Q2: April - June
        } else if (month <= 8) {
          return 3; // Q3: July - September
        } else {
          return 4; // Q4: October - December
        }
    }
     
    getStartingDay(quarter, invDate) {
        // Determine the month and year based on the quarter
        let month, year;
        if (quarter === 1) {
          month = 0; // January
          year = invDate.getFullYear();
        } else if (quarter === 2) {
          month = 3; // April
          year = invDate.getFullYear();
        } else if (quarter === 3) {
          month = 6; // July
          year = invDate.getFullYear();
        } else if (quarter === 4) {
          month = 9; // October
          year = invDate.getFullYear();
        } else {
          return null; // Invalid quarter number
        }
      
        // Create a new Date object with the determined month and year
        const date = new Date(year, month);
        return date;
    }
    
    handleAmtVal_CalTaxAmt(event)
    {
        //var value = event.target.value;
        //let amountVal;
        //if (event.target.dataset.id === 'InvoiceAmount'){
        //    amountVal = value;
        //}
        
        if(parseInt(event.target.value) < 0){
            event.target.value = 0;
        }
        if(this.taxAmountRequired && !this.displaySodicAmount){
            let taxAmountPercent = (parseInt(this.invoiceAmountValue)/100)*5;
            let finalCalculatedTaxAmtLimit = taxAmountPercent.toFixed(2);
            this.taxAmountValue = finalCalculatedTaxAmtLimit;
            this.totalAmountValue = parseInt(this.invoiceAmountValue) + parseFloat(finalCalculatedTaxAmtLimit);
        }
        else if(this.taxAmountRequired && this.displaySodicAmount){
            let totalAmountWithSodic = parseInt(this.invoiceAmountValue) + parseInt(this.sodicAmountValue);
            let taxAmountPercent = (parseInt(totalAmountWithSodic)/100)*5;
            let finalCalculatedTaxAmtLimit = taxAmountPercent.toFixed(2);
            this.taxAmountValue = finalCalculatedTaxAmtLimit;
            this.totalAmountValue = parseInt(totalAmountWithSodic) + parseFloat(finalCalculatedTaxAmtLimit);
        }else{
            this.taxAmountValue = 0;
            this.totalAmountValue = parseInt(this.invoiceAmountValue) + 0;
        }

    }

    removeFile(event) {
        var index = event.currentTarget.dataset.id;
        this.uploadedFiles.splice(index, 1);
        this.fileNamesList.splice(index, 1);
    }

    get acceptedFormats() {
        var acceptFormatList = [];
        for (let i = 0; i < this.acceptFileTypeList.length; i++) {
            acceptFormatList[i] = '.' + this.acceptFileTypeList[i];
        }

        return acceptFormatList;
    }

    hasExistingRequest = false;
    async checkExistingRequestsMain(){
        await checkExistingRequests({'accountId' : this.agencyId, 'quarter' : this.requestedQuarterLabel, 'year' : this.requestedYearLabel})
        .then(results=>{
            this.hasExistingRequest = (results != null && (results == true || results == 'true')) ? true : false;
        }).catch(error=>{
            this.hasExistingRequest = false;
        })
    }
}