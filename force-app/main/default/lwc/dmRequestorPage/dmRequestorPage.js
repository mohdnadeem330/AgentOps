import { LightningElement, track, wire, api } from 'lwc';
import getProducts from '@salesforce/apex/DM_RequestorPageCtrl.getProducts';
import createCase from '@salesforce/apex/DM_RequestorPageCtrl.createCase';
import updateCase from '@salesforce/apex/DM_RequestorPageCtrl.updateCase';
import getAllCases from '@salesforce/apex/DM_RequestorPageCtrl.getAllCases';
import getPaymentInfo from '@salesforce/apex/DM_RequestorPageCtrl.getPaymentRequests';
import getFeedInfo from '@salesforce/apex/DMCustomCommentFeederController.getFeedItemList';
import getSRRelatedDocuments from '@salesforce/apex/DM_RequestorPageCtrl.getSRRelatedDocuments';
import getCustomerDocuments from '@salesforce/apex/DM_RequestorPageCtrl.getCustomerDocuments';
import updateOtherDocument from '@salesforce/apex/DM_RequestorPageCtrl.updateOtherDocument';
import getActionRequiredCases from '@salesforce/apex/DM_RequestorPageCtrl.getActionRequiredCases';
import deleteRequestRecord from '@salesforce/apex/DM_RequestorPageCtrl.deleteRequestRecord';
import submitWireTransferPayment from '@salesforce/apex/DM_RequestorPageCtrl.submitWireTransferPayment';
import getCaseInfo from '@salesforce/apex/DM_RequestorPageCtrl.getCaseInfo';
import customerDocuments from '@salesforce/apex/DM_RequestorPageCtrl.showCustomerDocuments';
import getDocuments from '@salesforce/apex/DM_RequestorPageCtrl.getDocuments';
import fetchDMCounts from '@salesforce/apex/DM_RequestorPageCtrl.fetchDMCounts';
import updateDocumentUpload from '@salesforce/apex/DM_RequestorPageCtrl.updateDocumentUpload';
import getPicklistValues from '@salesforce/apex/DM_UtilityController.getPicklistValues';
import getUserInfo from '@salesforce/apex/DM_UtilityController.getUserInfo';
import updateExternalFileAsDeleted from '@salesforce/apex/DM_RequestorPageCtrl.updateExternalFileAsDeleted';
import getSASUrl from '@salesforce/apex/CalloutToBlobstorage.getSASUrl';
import getBankTransferDetails from '@salesforce/apex/DM_UtilityController.getBankTransferDetails';
import validateMobileNumber from '@salesforce/apex/DM_PortalRegistrationCtrl.validateMobileNumber';
import EmailValidation from '@salesforce/apex/DM_PortalRegistrationCtrl.validateEmailId';
import updateContact from '@salesforce/apex/DM_UtilityController.updateContact';
import sendMobileOTP from '@salesforce/apex/DM_UtilityController.sendMobileOTP';
import verifyOtp from '@salesforce/apex/DM_UtilityController.verifyOtp';
import createContact from '@salesforce/apex/DM_RequestorPageCtrl.createContact';
import getAllDlpCases from '@salesforce/apex/North_baniyasRequest.getAllDlpCases'; //Added by Rajat
import getDLpCaseInfo from '@salesforce/apex/North_baniyasRequest.getDLpCaseInfo'; //Added By Rajat
import updateDlpCase from '@salesforce/apex/North_baniyasRequest.updatedlpCase'; //Added By Rajat
import updateAssignTo from '@salesforce/apex/North_baniyasRequest.updateAssignTo'; // Added By Rajat
import getQueueMembersByOwner from '@salesforce/apex/North_baniyasRequest.getQueueMembersByOwner'; //Added By Daksh
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; //Added By Rajat
import { getObjectInfo,getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi'; //Added By Rajat
import getUserName from  '@salesforce/apex/North_baniyasRequest.getUserName';
import USER_ID from '@salesforce/user/Id';
import createPermitClosureReq from '@salesforce/apex/DM_RequestorPageCtrl.createPermitClosureReq';
import deleteRecord from '@salesforce/apex/DM_UtilityController.deleteRecord';
import checkFeatureFlagEnabled from '@salesforce/apex/DM_RequestorPageCtrl.checkFeatureFlagEnabled';

import { CloseActionScreenEvent } from 'lightning/actions';
import CASE_OBJECT from '@salesforce/schema/Case';
/*import  basePath from "@salesforce/community/basePath";
uncomment once live*/
import CASE_NUMBER from "@salesforce/schema/Case.CaseNumber";
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import { loadScript } from 'lightning/platformResourceLoader';
import apexchartJs from '@salesforce/resourceUrl/ApexCharts';
import FILE_SAVER from '@salesforce/resourceUrl/FileSaver';
import Dm_RequestorPaymentURL from '@salesforce/label/c.Dm_RequestorPaymentURL';
import blobFileUploadScript from '@salesforce/resourceUrl/blobFileUploadScript';
import DM_TLA_DocumentValues from '@salesforce/label/c.DM_TLA_DocumentValues';
import HomeImages from "@salesforce/resourceUrl/HomeImages";
import { loadStyle } from 'lightning/platformResourceLoader';
import ExternalStyle from "@salesforce/resourceUrl/ExternalStyle";
import { NavigationMixin } from 'lightning/navigation';

export default class DmRequestorPage extends NavigationMixin(LightningElement) {
    showNOCForm = false;
    showPTWForm = false;
    showOtherForm = false;
    showTLAForm = false;
    @track developementValues = [];
    @track tlaDevelopementValues = [];
    @track devStages = [];
    @track productValues = [];
    activeBtn = '';
    @track caseObj;
    @track utilityValues = [];
    @track excavationValues = [];
    showOtherUtilityName = false;
    showOtherExcavationName = false;
    allMyCases;
    @track filteredCases = [];
    @track DlpfilteredCases =[];
    paymentInfoFilterList = [];
    showMyCases = false;
    @track isLoading = false;
    isModalLoading = false;
    noRecords = false;
    noDlpCases = false;
    @track currentRequestInfo;
    userInfo;
    profileInfo;
    @track profileUpdateInfo;
    isDisabled = false;
    @track utlilityPicklistValues = [];
    @track excavationPicklistValues = [];
    @track countryCodeOptions = [];
    currentRequestId;
    showSubmitBtn = false;
    openCancelModal = false;
    openDeleteModal = false;
    cancelBtnShowList = ['Work In Progress'];
    feedInfo;
    showInspectedDate = false;
    showSplitPayment = false;
    showHazardImpact = false;
    showSafetyPrec = false;
    nofilterRecords = false;
    nofilterpaymentRecords = false;
    paymentInfoList;
    showMyFinance = false;
    showHomepage = true;
    noPaymentRecords = false;
    @track allCaseCount;
    @track inprogressCaseCount;
    @track pendingCaseCount;
    @track rejectedCaseCount;
    @track closedCaseCount;
    @track draftCaseCount;
    actionReqCases;
    statusMap = { "Open": ['New'], "In Progres": ['Work In Progress'], "Approved": ['Closed', 'Completed'], "Pending": ['Pending with Customer'], "Rejected": ['Rejected'], "Saved": ['Draft'] };
    chartHasData = false;
    showFormslist = false;
    showUserPopup = false;
    chartSeries = [];
    chartLabels = [];
    hideSideBar = false;
    sucessPage = false;
    showDocuments = false;
    product;
    @track extFileList;
    fileName;
    isStep1Done = false;
    isStep2Done = false;
    currentRequestName = 'NOC Details';
    showNextbtn = true;
    externalFilesList = [];
    isFeedAvailable = false;
    aldarDocumentList = [];
    @track tlaDocumentList = [];
    aldarDocId;
    isDraft = false;
    otherDocKey = 'otherDoc';
    @track files = [];
    @track showModal = false;
    @track modalUrl = '';
    @track previewUrl = '';
    isSubmitted = false;
    addOtherDocument = false;
    otherDocumentName;
    documentType;
    showMessage = false;
    noFileMsg;
    isSaved = false;
    disServiceType = false;
    noExtFiles = false;
    cancelReq = false;
    caseNumber;
    @track fileIds = '';
    isSaveDoc = false;
    updateCustomerDoc = false;
    isUpload = false;
    @track customerDoc = [];
    showOtherDoc = false;
    addTLADocument = false;
    @track fileData = [];
    docName;
  //  @track selectedProductPrice = 0;
    isServicePrice = false;
    @track contentVersionIds = [];

    @track pageSize = 10;
    @track dlpPageSize = 100;
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track recordEnd = 0;
    @track recordStart = 0;
    @track isPrev = true;
    @track isNext = true;
    @track startDate;
    @track endDate;
    filterCondition;
    selectedStatus;
    chartRendered = false;
    @track showBankTransferPopup = false;
    @track paymentReqId = '';
    paymentDate;
    remittanceName;
    paymentReference;
    attName;
    maxDate;
    isLoadPopup = false;
    caseNum;
    showReceiptBtn = false;
    showYasIslandDetails = false;
    blobFolderName = 'aldar/DistrictManagement';
    blobSubFolderName = '';
    blobSource = 'salesforce';
    blobUserId = '';
    isLoadingFile = false;
    addDocSpinner = false;
    disablebtn = false;
    deleteBtn = false;
    bankTransferDetails;
    csNumber;
    accNumber;
    showProfileUpdate = false;
    profileEditMode = false;
    documentsWithExternalFiles;
    documentsWithoutExternalFiles;
    noDocsWithoutExtFiles;
    profileReadMode = true;
    otpScreen = false;
    showCounter = false;
    refreshCounter;
    mobileInterval;
    counter = 1;
    showCounter = false;
    OTP;
    otpSentMsg;
    hasError = false;
    errorMessage;
    @track titlevlaues = [];
    conObj = new Object();
    showOtherDocName = false;
    showRenewDetails = false;
    showDemaraction = false;
    @track caseRecordTypeId;
    @track caseTLARecordTypeId;

    showPermitClosure = false;
    showPermitClsBtn = false;
    @track permitClosureDoc = [];
    showPermitDocSpin = false;
    fileUploadSet;
    documentName;
    @track dlpSortByValue = '';
    dlpshowModel = false;
    @track dlpCaseCategoryOptions = [];
    @track dlpSubCategoryOptions = [];
    controllerValues = {};
    allDlpSubCategoryMap = [];

    Logo = HomeImages + '/Home-Images/DM_logo_login.png';
    Sidebar = HomeImages + '/Home-Images/DM_sidebar.png';
    Open = HomeImages + '/Home-Images/DM_open.svg';
    Pending = HomeImages + '/Home-Images/DM_pending.svg';
    Inprogress = HomeImages + '/Home-Images/DM_pending.svg';
    Approved = HomeImages + '/Home-Images/DM_approved.svg';
    Rejected = HomeImages + '/Home-Images/DM_reject.svg';
    Draft = HomeImages + '/Home-Images/DM_draft.svg';
    Done = HomeImages + '/Home-Images/DM_approval.svg';
    Tick = HomeImages + '/Home-Images/DM_thick.svg';
    Question = HomeImages + '/Home-Images/DM_question.svg';
    Bell = HomeImages + '/Home-Images/DM_bell.svg';
    Edit = HomeImages + '/Home-Images/DM_edit.svg';
    Document = HomeImages + '/Home-Images/DM_doc.svg';
    History = HomeImages + '/Home-Images/DM_history.svg';
    Contact = HomeImages + '/Home-Images/DM_contact.svg';
    Finacial = HomeImages + '/Home-Images/DM_finacial.svg';
    Request = HomeImages + '/Home-Images/DM_request.svg';
    Home = HomeImages + '/Home-Images/DM_home.svg';
    Rightarrow = HomeImages + '/Home-Images/DM_rightarrow.svg';
    Upload = HomeImages + '/Home-Images/DM_upload.svg';
    Banner = HomeImages + '/Home-Images/banner.png';
    Document = HomeImages + '/Home-Images/document.png';

    dlpRecordTypeId='';
    showSwitchButton = false;
    showAdditionalWorkspaceAccess = true;
    @wire(getPicklistValuesByRecordType, {
        recordTypeId : '$dlpRecordTypeId',
        objectApiName : CASE_OBJECT
    })
    wiredRecordTypeInfo({data, error}) {
        if(data) {
            if(data)
            {
                this.pickDlpStatus = data.picklistFieldValues.Status.values;
                this.pickDlpAppointmentstatus = data.picklistFieldValues.Appointment_Status__c.values;          
                const allCategories = data.picklistFieldValues.CaseCategory__c.values;
                const subCategoryField = data.picklistFieldValues.SubCategory__c;

                this.allDlpSubCategoryMap = subCategoryField.values;
                this.controllerValues = subCategoryField.controllerValues;

                this.dlpCaseCategoryOptions = [
                    { label: '--None--', value: null },
                    ...allCategories
                        .filter(item => item.label.startsWith('North'))
                        .map(item => ({ label: item.label, value: item.value }))
                ];

                if (this.dlpCaseCategoryValue) {
                    this.filterDlpSubCategories(this.dlpCaseCategoryValue);
                }

                console.log('✅ Categories:', this.dlpCaseCategoryOptions);
                console.log('✅ Subcategories Map:', this.allDlpSubCategoryMap);
            }
            else
            {
                
            }


        }}
    



    connectedCallback() {
        this.conObj.MobileCountryCode__c = '971';
        //this.getDevelopementValues();
        this.getdevStageValues();
        this.getAllCasesInfo();
        this.getUserDetails();
        this.getUtilityValues();
        this.getExcavationValues();
        this.initializeRequestInfo();
        this.getPaymentDetails();
        this.getActionRequiredCases();
        this.fetchCaseCounts();
        this.fetchDraftCaseCounts();
        this.fetchTypeCounts();
        this.getCurrentDate();
        this.getBankTransferDetails();

        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        try {
            if (urlParams.get('pg') == 'fin') {
                this.hideAllForms();
                this.showMyFinance = true;
                this.getPaymentDetails();
            }
        } catch (e) {
            
        }
        setTimeout(() => {
            const toastComponent = this.template.querySelector('c-common-toast-msg-for-communities');
            if (toastComponent) {
                toastComponent.showToast('warning', 'Dear Customer, This portal is dedicated to processing permits, NOCs, and leasing agreements. For Facility Management (FM) related issues, please submit a request through the CAFM System or the @yourservices app.', '', 3000);
            } else {
                //console.error("Toast component not found");
            }
        }, 0);
    }

    @wire(getRecord, { recordId: "$currentRequestId", fields: [CASE_NUMBER] })
    caseRecord({ error, data }) {
        if (error) {
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
           
        } else if (data) {
            this.caseNum = data.fields.CaseNumber.value;
        }
    }
    getBankTransferDetails() {
        getBankTransferDetails()
            .then(data => {
                if (data) {
                    this.bankTransferDetails = data;
                }
            })
            .catch(error => {
               
            });
    }

    getCurrentDate() {
        const today = new Date();
        let month = today.getMonth() + 1;
        let day = today.getDate();
        const year = today.getFullYear();

        if (month < 10) {
            month = '0' + month;
        }
        if (day < 10) {
            day = '0' + day;
        }

        this.maxDate = `${year}-${month}-${day}`;
    }
    async renderedCallback() {
        Promise.all([
            loadStyle(this, ExternalStyle)
        ])
        loadScript(this, blobFileUploadScript)
            .then(() => {
               
            })
            .catch(error => {
                //console.log('Blob script Error is', JSON.stringify(error));
            });

        loadScript(this, apexchartJs + '/dist/apexcharts.js')
            .then(() => {
                if (!this.chartRendered) {
                    this.prepareDataForChart();
                    this.chartRendered = true;
                }
            })
            .catch((error) => {
                //console.error('Failed JS: ' + error);
            });

        if (this.showNOCForm && this.isDisabled && this.template.querySelector('[data-id="nocprgbar"]')) {
            this.template.querySelector('[data-id="nocprgbar"]').classList.add('removesidebar');
        }
        if (this.showPTWForm && this.isDisabled && this.template.querySelector('[data-id="ptwprgbar"]')) {
            this.template.querySelector('[data-id="ptwprgbar"]').classList.add('removesidebar');
        }
        if (this.showOtherForm && this.isDisabled && this.template.querySelector('[data-id="otherprgbar"]')) {
            this.template.querySelector('[data-id="otherprgbar"]').classList.add('removesidebar');
        }
        if (this.showTLAForm && this.isDisabled && this.template.querySelector('[data-id="tlaprgbar"]')) {
            this.template.querySelector('[data-id="tlaprgbar"]').classList.add('removesidebar');
        }
        if (this.isStep1Done && this.template.querySelector('.step2')) {
            this.template.querySelector('.step2').classList.add('slds-is-active');
        }
        if (this.selectedStatus == 'Open' && this.template.querySelector('[data-status="Open"]'))
            this.template.querySelector('[data-status="Open"]').classList.add('active-pill');

        if (this.showMyFinance && this.template.querySelector('[data-name="Financials"]')) {
            this.template.querySelector('[data-name="Financials"]').classList.add('active');
            this.template.querySelector('[data-name="Home"]').classList.remove('active');
            this.template.querySelector('[data-name="Requests"]').classList.remove('active');
        }
    }

    async prepareDataForChart() {
        /* var options = {
            series: [100,50],
            chart: {
                type: 'donut',
                width: 400,
            },

            labels: ['NOC','PTW'],
            responsive: [{
                breakpoint: 480,
                options: {
                    chart: {
                        width: 320
                    },
                    legend: {
                        position: 'bottom'
                    }
                }
            }]
        }; */

        var options = {
            series: this.chartSeries,
            chart: {
                type: 'donut',
                width: 400,
            },

            labels: this.chartLabels,
            responsive: [{
                breakpoint: 480,
                options: {
                    chart: {
                        width: 320
                    },
                    legend: {
                        position: 'bottom'
                    }
                }
            }]
        };
        if (this.chartHasData)
            this.template.querySelector('[data-id="showChart"]').classList.remove('hideChart');
        else
            this.template.querySelector('[data-id="showChart"]').classList.add('hideChart');

        var chart = new ApexCharts(this.template.querySelector('.chart'), options);
        chart.render();


    }

    handlePopClose(event) {
        this.showFormslist = false;
    }
    handleUserPopClose(event) {
        this.showUserPopup = false;
    }
    get testOptions() {
        return [
            { label: 'Official Request Letter', value: 'Official Request Letter' }

        ];
    }
    get logoutUrl() {
        //Uncomment once live
        /*  const sitePrefix = basePath.replace(
             /\/s$/i, ""
         );
         return sitePrefix + "/secur/logout.jsp"; */
        // return "/districtMngmt/secur/logout.jsp";
         return "/business/secur/logout.jsp";
    }
    getUserDetails() {
        getUserInfo()
            .then(data => {
                this.userInfo = data;
                this.profileInfo = data[0];
                this.blobUserId = data[0].Id;
                let prf = new Object();
                prf.firstname = data[0].FirstName;
                prf.lastname = data[0].LastName;
                prf.email = data[0].Email;
                prf.countrycode = data[0].Contact.MobileCountryCode__c;
                prf.mobile = data[0].Contact.MobilePhone__c;
                prf.contactid = data[0].ContactId;
                this.profileUpdateInfo = prf;
                this.checkFeatureFlag();
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });
    }
    checkFeatureFlag() {
        checkFeatureFlagEnabled()
            .then(data => {
                if (data === 'false') {
                    this.showSwitchButton = false;
                    this.showAdditionalWorkspaceAccess = false;
                } else if (data === 'true') {
                    this.checkVertical();
                }
            })
            .catch(error => {
                console.error('Error checking feature flag:', error);
            });
    }
    
     checkVertical() {
        console.log('this.userInfo',JSON.stringify(this.userInfo));
        if (this.userInfo[0]?.Contact?.Account?.CustomerVertical__c) {
            let list = this.userInfo[0]?.Contact?.Account?.CustomerVertical__c.split(/[,;]+/)
                .map(v => v.trim())
                .filter(v => v);

            if (list.length > 1) {
               this.showSwitchButton = true;
               this.showAdditionalWorkspaceAccess = false
            }
            else{
                this.showSwitchButton = false;
                this.showAdditionalWorkspaceAccess = true
            }


        }
        console.log('this.showSwitchButton',this.showSwitchButton);

    }

    initializeRequestInfo() {
        this.currentRequestInfo = { "Development_Name__c": "", "Project_Name__c": "", "Plot_Developer__c": "", "Sector_and_Plot_No__c": "", "Project_Consultant__c": "", "Appointed_Contractor__c": "", "Description": "", "NOC_to_be_Addressed_to__c": "", "Dev_Stage__c": "", "ProductId": "", "Other_Utility_Name__c": "" };
        this.utlilityPicklistValues.forEach(item => {
            this.currentRequestInfo[item.label] = '';
        });
        this.excavationPicklistValues.forEach(item => {
            this.currentRequestInfo[item.label] = '';
        });

    }
    fetchTypeCounts() {
        fetchDMCounts({ groupByFilter: 'Type' })
            .then(data => {
                if (data) {

                    if (Object.keys(data).length > 0)
                        this.chartHasData = true;
                    Object.entries(data).forEach(([label, count]) => {
                        if (label === "Temporary License Agreement") {
                            label = "TLA";
                        }
                        this.chartLabels.push(label);
                        this.chartSeries.push(count);
                    });

                    this.prepareDataForChart();
                }
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });
    }

    fetchCaseCounts() {
        fetchDMCounts({ groupByFilter: 'Status' })
            .then(data => {
                if (data) {
                    this.inprogressCaseCount = data['Work In Progress'] || 0;
                    this.pendingCaseCount = data['Pending with Customer'] || 0;
                    this.rejectedCaseCount = (data['Rejected'] || 0) + (data['Cancelled'] || 0);
                    this.closedCaseCount = data['Completed'] || 0;
                    this.allCaseCount = Object.values(data).reduce((a, b) => a + b, 0);
                }
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });
    }
    fetchDraftCaseCounts() {
        fetchDMCounts({ groupByFilter: 'Sub_Status__c' })
            .then(data => {
                if (data) {
                    this.draftCaseCount = data['Draft'] || 0;
                }
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });
    }
    getPaymentDetails() {
        this.filterCondition = '';
        if (this.startDate && this.endDate) {
            const startDateObj = new Date(this.startDate);
            const endDateObj = new Date(this.endDate);

            if (!isNaN(startDateObj.getTime()) && !isNaN(endDateObj.getTime())) {
                endDateObj.setHours(23, 59, 59, 999);
                const startDateFormatted = startDateObj.toISOString();
                const endDateFormatted = endDateObj.toISOString();

                //this.filterCondition += ` AND CreatedDate > ${startDateFormatted} AND CreatedDate < ${endDateFormatted}`;
                this.filterCondition += ` AND CreatedDate >= ${startDateFormatted} AND CreatedDate <= ${endDateFormatted}`;

            }
        }

        getPaymentInfo({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            filterCondition: this.filterCondition
        })
            .then(result => {
                if (result) {
                    var data = JSON.parse(result);
                    this.filteredCases = data.paymentReq;
                    this.pageNumber = data.pageNumber;
                    this.totalRecords = data.totalRecords;
                    this.recordStart = data.recordStart;
                    this.recordEnd = data.recordEnd;
                    this.totalPages = Math.ceil(data.totalRecords / this.pageSize);
                    this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
                    this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);

                    /*  this.filteredCases.forEach(item => {
                         if (item.Status__c == 'Pending' && (item.Payment_Type__c === 'Online') )
                             item.showPayBtn = true;
                         else
                             item.showPayBtn = false;
                     }); */

                    this.filteredCases.forEach(item => {
                        if (item.Status__c === 'Pending') {
                            if (item.Payment_Type__c === 'Online') {
                                item.showPayBtn = true;
                            } else if (item.Payment_Type__c === 'Wire Transfer') {
                                item.showBankTransfer = true;
                            } else {
                                item.showPayBtn = false;
                                item.showBankTransfer = false;
                                item.showBlankBtn = true;
                            }
                        } else if (item.Status__c === 'Received') {
                            item.showReceiptBtn = true;
                        } else {
                            item.showBlankBtn = true;
                        }
                    });
                    this.paymentInfoList = this.filteredCases;
                    this.paymentInfoFilterList = this.paymentInfoList
                    if (this.filteredCases.length > 0)
                        this.noPaymentRecords = false;
                    else
                        this.noPaymentRecords = true;
                }
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }
    getActionRequiredCases() {
        getActionRequiredCases()
            .then(data => {
                this.actionReqCases = data;
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }
    initilizeCaseObject() {
        this.caseObj = null;
        this.caseObj = new Object();
        this.caseObj.sobjectType = 'Case';
    }

    async handleBtnClick(event) {
        this.currentRequestId = '';
        let btn = event.currentTarget.dataset.name;
        this.files = [];
        this.activeBtn = btn;
        this.hideAllForms();
        this.isDisabled = false;
        this.currentRequestInfo = null;
        this.showSubmitBtn = false;
        this.hideSideBar = false;
        this.showNextbtn = true;
        this.isFeedAvailable = false;
        this.initializeRequestInfo();
        this.startDate = '';
        this.endDate = '';
        this.isSubmitted = false;
        this.disServiceType = true;
        this.initilizeCaseObject();
        this.clearPaginationData();
        this.showBackbtn = false;
        this.isSaveDoc = false;
     //   this.selectedProductPrice = 0;
        this.showRenewDetails = false;

        if (btn == 'NOC') {
            //this.initilizeCaseObject();
            this.getproductValues();
            this.showNOCForm = true;
            this.clearCheckedUtilityStatusForAll();
            this.currentRequestName = 'NOC Details';
            this.disServiceType = false;
            this.caseObj.Request_split_payment__c = 'No';
            this.caseObj.IPS_Received_from_ADM__c = 'No';
            this.currentRequestInfo.IPS_Received_from_ADM__c = 'No';
            this.caseObj.Asset_Evaluation__c = 'Not Required';
            this.currentRequestInfo.Asset_Evaluation__c = 'Not Required';
        }
        if (btn == 'Permit to Work') {
            //this.initilizeCaseObject();
            this.getproductValues();
            this.showPTWForm = true;
            this.showHazardImpact = false;
            this.showSafetyPrec = false;
            this.clearCheckedUtilityStatusForAll();
            this.clearCheckedExcavationForAll();
            this.currentRequestInfo.Request_Type__c = 'New';
            this.caseObj.Request_Type__c = 'New';
            this.caseObj.Hazards_Identified_Environmental_Impact__c = 'No';
            this.currentRequestInfo.Hazards_Identified_Environmental_Impact__c = 'No';
            this.caseObj.Safety_Precautions_and_Controls_in_Place__c = 'No';
            this.currentRequestInfo.Safety_Precautions_and_Controls_in_Place__c = 'No';
            this.currentRequestInfo.Demarcation__c = 'Setting out land demarcation Points';
            this.caseObj.Demarcation__c = 'Setting out land demarcation Points';
            this.currentRequestInfo.Duration_of_Work_Days__c = '0';
            this.caseObj.Duration_of_Work_Days__c = '0';
            this.currentRequestInfo.Duration_of_Work_Months__c = '0';
            this.caseObj.Duration_of_Work_Months__c = '0';
            this.currentRequestInfo.Duration_of_Work_Years__c = '0';
            this.caseObj.Duration_of_Work_Years__c = '0';
            this.currentRequestName = 'PTW Details';
            this.disServiceType = false;
            this.caseObj.Request_split_payment__c = 'No';
            this.caseObj.IPS_Received_from_ADM__c = 'No';
            this.currentRequestInfo.IPS_Received_from_ADM__c = 'No';
            this.caseObj.Asset_Evaluation__c = 'Not Required';
            this.currentRequestInfo.Asset_Evaluation__c = 'Not Required';
        }
        if (btn == 'Others') {
            //this.initilizeCaseObject();
            this.getproductValues();
            this.showOtherForm = true;
            this.currentRequestName = 'Other Details';
            this.disServiceType = false;
        }
        if (btn == 'Temporary License Agreement') {
            // this.initilizeCaseObject();
            this.getproductValues();
            this.showTLAForm = true;
            this.showInspectedDate = false;
            this.showSplitPayment = false;
            this.currentRequestInfo.Request_Type__c = 'New';
            this.caseObj.Request_Type__c = 'New';
            this.currentRequestInfo.Is_the_site_Inspected__c = 'No';
            this.currentRequestInfo.Is_the_area_pre_approved_by_aldar__c = 'No';
            this.currentRequestInfo.Request_split_payment__c = 'No';
            this.caseObj.Is_the_site_Inspected__c = 'No';
            this.caseObj.Is_the_area_pre_approved_by_aldar__c = 'No';
            this.currentRequestName = 'TLA Details';
        }
        if (btn == 'Home') {
            this.hideAllForms();
            this.chartRendered = false;
            this.showHomepage = true;
            this.isStep1Done = false;
            this.filteredCases = this.allMyCases;
            this.template.querySelector('[data-name="Home"]').classList.add('active');
            this.template.querySelector('[data-name="Requests"]').classList.remove('active');
            this.template.querySelector('[data-name="Financials"]').classList.remove('active');
            this.template.querySelector('[data-name="Cases"]').classList.remove('active');
        }
        if (btn == 'Financials') {
            this.hideAllForms();
            this.showMyFinance = true;
            this.getPaymentDetails();
            this.template.querySelector('[data-name="Financials"]').classList.add('active');
            this.template.querySelector('[data-name="Home"]').classList.remove('active');
            this.template.querySelector('[data-name="Requests"]').classList.remove('active');
            this.template.querySelector('[data-name="Cases"]').classList.remove('active');
        }
        if (btn == 'Requests') {
            this.hideAllForms();
            this.showMyCases = true;
            this.selectedStatus = 'all';
            await this.getAllCasesInfo();
            this.template.querySelector('[data-name="Requests"]').classList.add('active');
            this.template.querySelector('[data-name="Home"]').classList.remove('active');
            this.template.querySelector('[data-name="Financials"]').classList.remove('active');
            this.template.querySelector('[data-name="Cases"]').classList.remove('active');
        }
        if (btn == 'New Request') {
            this.hideAllForms();
            this.showHomepage = true;
            this.showFormslist = true;

        }
        if (btn == 'Add New User') {
            this.hideAllForms();
            this.showProfileUpdate = true;
            this.profileReadMode = true;
            this.gettitlevlaues();
            this.showUserPopup = true;

        }
// Added by Rajat Jain
        if (btn == 'Cases') {           
            this.hideAllForms();
            this.showDLPCases = true;
            this.caseRetriveTypeValue = 'NewCase';
            this.selectedStatus = 'all';           
            this.getDlpCasesInfo();
            this.activeBtn = 'dlpCase';
            this.template.querySelector('[data-name="Requests"]').classList.remove('active');
            this.template.querySelector('[data-name="Home"]').classList.remove('active');
            this.template.querySelector('[data-name="Financials"]').classList.remove('active');
            this.template.querySelector('[data-name="Cases"]').classList.add('active');

        }
    // End
    }
    clearPaginationData() {
        this.pageNumber = 1;
        this.totalRecords = 0;
        this.totalPages = 0;
        this.recordEnd = 0;
        this.recordStart = 0;
    }
    handlePayBtn(event) {
        let url = Dm_RequestorPaymentURL + '?id=' + event.target.dataset.id;
        window.open(url, "_self");
    }

    hideAllForms() {
        this.showMyCases = false;
        this.showHomepage = false;
        this.showNOCForm = false;
        this.showPTWForm = false;
        this.showOtherForm = false;
        this.openCancelModal = false;
        this.showTLAForm = false;
        this.showMyFinance = false;
        this.showFormslist = false;
        this.showUserPopup = false;
        this.sucessPage = false;
        this.showDocuments = false;
        this.openDeleteModal = false;
        this.showProfileUpdate = false;
        this.profileEditMode = false;
        this.otpScreen = false;
        this.showCounter = false;
        this.showDLPCases = false;
        this.ShowDlpDetails =false;
    }
    handleLogout() {
        window.open(this.logoutUrl, "_self");
    }

    // getDevelopementValues() {
    //     getPicklistValues({ objName: 'Case', fldName: 'Development_Name__c' })
    //         .then(data => {
    //             this.developementValues = Object.entries(data).map(([value, label]) => ({ value, label }));
    //         })
    //         .catch(error => {
    //             //console.log('error->' + error.message)
    //         });
    // }
     @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            const recordTypes = data.recordTypeInfos;
            for (let key in recordTypes) {
                if (recordTypes[key].name === 'District Management') {
                    this.caseRecordTypeId = key;
                } else if (recordTypes[key].name === 'District Management TLA') {
                    this.caseTLARecordTypeId = key;
                }
            }
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: "$caseRecordTypeId" })
    picklistResDm({ error, data }) {
        if (data) {
            this.developementValues = [...data.picklistFieldValues?.Development_Name__c.values];
        } else if (error) {
            //console.log(error)
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: "$caseTLARecordTypeId" })
    picklistResTla({ error, data }) {
        if (data) {
            this.tlaDevelopementValues = [...data.picklistFieldValues?.Development_Name__c.values];
        } else if (error) {
            //console.log(error)
        }
    }

    getUtilityValues() {
        getPicklistValues({ objName: 'Case', fldName: 'Utility__c' })
            .then(data => {
                this.utlilityPicklistValues = Object.entries(data).map(([value, label]) => ({ value, label }));
                this.utlilityPicklistValues.forEach(item => {
                    item.isChecked = null;
                });
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }
    getExcavationValues() {
        getPicklistValues({ objName: 'Case', fldName: 'Method_of_Excavation__c' })
            .then(data => {
                this.excavationPicklistValues = Object.entries(data).map(([value, label]) => ({ value, label }));
                this.excavationPicklistValues.forEach(item => {
                    item.isChecked = null;
                });

            })
            .catch(error => {
                //console.log('error->' + error.message)
            });

    }
    clearCheckedUtilityStatusForAll() {
        this.utlilityPicklistValues.forEach(item => {
            item.isChecked = null;
        });
    }
    clearCheckedExcavationForAll() {
        this.excavationPicklistValues.forEach(item => {
            item.isChecked = null;
        });
    }
    get yesNoValues() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }

        ];
    }
    get tlaDocumentValues() {
        const stringArray = DM_TLA_DocumentValues.split(',');
        const objectArray = stringArray.map(item => ({
            label: item,
            value: item
        }));
        return objectArray;
       /*  return [
            { label: 'Customer TLA', value: 'Customer TLA' },
            { label: 'Payment Cheque', value: 'Payment Cheque' },
            { label: 'Security Cheque', value: 'Security Cheque' },
            { label: 'Others', value: 'Others' }
        ]; */
    }
    get assestEvaluationValues() {
        return [
            { label: 'Required', value: 'Required' },
            { label: 'Not Required', value: 'Not Required' }

        ];
    }
    get requestTypeValues() {
        return [
            { label: 'New', value: 'New' },
            { label: 'Renewal', value: 'Renewal' }

        ];
    }
    get daysValues() {
        let days = [];
        for (let i = 0; i <= 30; i++) {
            days.push({ label: `${i}`, value: `${i}` });
        }
        return days;

    }
    get monthsValues() {
        let months = [];
        for (let i = 0; i <= 11; i++) {
            months.push({ label: `${i}`, value: `${i}` });
        }
        return months;
    }
    get yearsValues() {
        let years = [];
        for (let i = 0; i <= 4; i++) {
            years.push({ label: `${i}`, value: `${i}` });
        }
        return years;
    }
    get demarcationValues() {
        return [
            { label: 'Setting out land demarcation Points', value: 'Setting out land demarcation Points' },
            { label: 'Re-demarcation', value: 'Re-demarcation' }

        ];
    }

    getdevStageValues() {
        getPicklistValues({ objName: 'Case', fldName: 'Dev_Stage__c' })
            .then(data => {
                this.devStages = Object.entries(data).map(([value, label]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }

    getproductValues() {
        getProducts({ type: this.activeBtn })
            /* .then(data => {
                this.productValues = data?.map(
                    ({ Id, Name }) => ({ value: Id, label: Name })
                );
            })
            .catch(error => {
                console.log('error->' + error.message)
            }); */
            .then(data => {
                this.productValues = data.map(product => {
                    let unitPrice = 0;
                    if (product.PricebookEntries && product.PricebookEntries.length > 0) {
                        unitPrice = product.PricebookEntries[0].List_Price_Incl_VAT__c;
                    }
                    return {
                        value: product.Id,
                        label: product.Name,
                        unitPrice: unitPrice
                    };
                });
                const othersOption = this.productValues.find(option => option.label === 'Others');
                if (othersOption) {
                    this.productValues = this.productValues.filter(option => option.label !== 'Others');
                    this.productValues.push(othersOption);
                }
            })
            .catch(error => {
                //console.log('error->' + error.message);
            });
    }
    handleRadioBtn(event) {
        this.caseObj[event.target.dataset.apiname] = event.detail.value;
        this.currentRequestInfo[event.target.dataset.apiname] = event.detail.value;
        if (event.target.dataset.apiname == 'Is_the_site_Inspected__c') {
            if (event.detail.value == 'Yes')
                this.showInspectedDate = true;
            else
                this.showInspectedDate = false;
        }
        if (event.target.dataset.apiname == 'Is_the_area_pre_approved_by_aldar__c') {
            if (event.detail.value == 'Yes')
                this.showSplitPayment = true;
            else
                this.showSplitPayment = false;
        }
        if (event.target.dataset.apiname == 'Hazards_Identified_Environmental_Impact__c') {
            if (event.detail.value == 'Yes')
                this.showHazardImpact = true;
            else
                this.showHazardImpact = false;
        }
        if (event.target.dataset.apiname == 'Safety_Precautions_and_Controls_in_Place__c') {
            if (event.detail.value == 'Yes')
                this.showSafetyPrec = true;
            else
                this.showSafetyPrec = false;
        }
    }

    dlpStatus;
    dlpHandleChange(event) {
        try {
           this.dlpStatus = event.currentTarget.value; // console.log('Dlp Status'+this.dlpStatus);
        } catch (e) {
           // console.log('Error dlpHandleChange'+e.message);
        }
    }

    dlpAppointmentDate;
    handleAppointmentDate(event) {
        try {
            console.log('@@@handleAppointmentDate'+event);
           this.dlpAppointmentDate = event.currentTarget.value; // console.log('Dlp Status'+this.dlpStatus);
        } catch (e) {
           // console.log('Error dlpHandleChange'+e.message);
        }
    }
    //Govt portal Chnages
    dlpPostComment;
    handlePostComment(event) {
        try {
           this.dlpPostComment = event.currentTarget.value; // console.log('Dlp Status'+this.dlpStatus);
        } catch (e) {
           // console.log('Error dlpHandleChange'+e.message);
        }
    }

    //Start by Daksh Sharma for Appointment Status Changes
    dlpAppointmentStatus;
    dlpHandleAppointmentStatusChange(event) {
        try {
           this.dlpAppointmentStatus = event.currentTarget.value;  console.log('Dlp Appoinment Status'+this.dlpAppointmentStatus);
        } catch (e) {
           // console.log('Error dlpHandleChange'+e.message);
        }
    }//End

    handleChange(event) {
        try {
            this.caseObj[event.currentTarget.name] = event.currentTarget.value;
            this.currentRequestInfo[event.currentTarget.name] = event.currentTarget.value;

            if (event.currentTarget.name === 'ProductId') {
                const selectedProductId = event.currentTarget.value;
                const selectedProduct = this.productValues.find(product => product.value === selectedProductId);
              //  this.selectedProductPrice = selectedProduct ? selectedProduct.unitPrice : 0;
                this.isServicePrice = true;

                if (selectedProduct?.label == 'Land Demarcation') {
                    this.showDemaraction = true;
                } else {
                    this.showDemaraction = false;
            }
            }

            if ((this.activeBtn === 'NOC' || this.activeBtn === 'Permit to Work') && event.currentTarget.name === 'Development_Name__c') {
                if (event.detail.value == 'Yas Island')
                    this.showYasIslandDetails = true;
                else
                    this.showYasIslandDetails = false;
            }

            if (event.currentTarget.name === 'Request_Type__c') { // added by Aswathi 17/01/2025
                if (event.currentTarget.value === 'Renewal') {
                    this.showRenewDetails = true;
                } else if (event.currentTarget.value === 'New') {
                    this.showRenewDetails = false;
                    this.caseObj.Previous_Request_Number__c = '';
                    this.caseObj.Validity_Date__c = '';
                    this.currentRequestInfo.Previous_Request_Number__c = '';
                    this.currentRequestInfo.Validity_Date__c = '';
                }
            }

        } catch (e) {
            //console.log(e.message)
        }
    }
    handleCheckbox(event) {
        if (event.target.label == 'Others' && event.target.checked && event.target.name == 'utilChkbx')
            this.showOtherUtilityName = true;
        else if (event.target.label == 'Others' && event.target.name == 'utilChkbx')
            this.showOtherUtilityName = false;

        if (event.target.label == 'Others' && event.target.checked && event.target.name == 'excavationChkbx')
            this.showOtherExcavationName = true;
        else if (event.target.label == 'Others' && event.target.name == 'excavationChkbx')
            this.showOtherExcavationName = false;

        if (!event.target.checked && event.target.name == 'utilChkbx') {
            this.utlilityPicklistValues.forEach(item => {
                if (item.label == event.target.label) {
                    item.isChecked = false;
                }
            });
        }
        if (!event.target.checked && event.target.name == 'excavationChkbx') {
            this.excavationPicklistValues.forEach(item => {
                if (item.label == event.target.label) {
                    item.isChecked = false;
                }
            });
        }

        if (!this.utilityValues.includes(event.target.label) && event.target.checked && event.target.name == 'utilChkbx') {
            this.utilityValues.push(event.target.label);
        } else if (this.utilityValues.includes(event.target.label)) {
            const index = this.utilityValues.indexOf(event.target.label);
            if (index > -1) {
                this.utilityValues.splice(index, 1);
            }
        }
        this.caseObj['Utility__c'] = this.utilityValues.join(';');

        if (!this.excavationValues.includes(event.target.label) && event.target.checked && event.target.name == 'excavationChkbx') {
            this.excavationValues.push(event.target.label);
        } else if (this.excavationValues.includes(event.target.label)) {
            const index = this.excavationValues.indexOf(event.target.label);
            if (index > -1) {
                this.excavationValues.splice(index, 1);
            }
        }
        this.caseObj['Method_of_Excavation__c'] = this.excavationValues.join(';');
    }
    handleCheckboxPTW(event) {
        this.caseObj[event.target.name] = event.target.checked;
        /*   if (event.target.name == 'Hazards_Identified_Environmental_Impact__c') {
              this.currentRequestInfo[event.target.name] = event.target.checked;
          } */
        if (event.target.name == 'Safety_Precautions_and_Controls_in_Place__c') {
            this.currentRequestInfo[event.target.name] = event.target.checked;
        }
        if (event.target.name == 'Re_demarcation__c' && event.target.checked) {
            this.currentRequestInfo.Setting_out_land_demarcation_at_site__c = false;
        }
        if (event.target.name == 'Setting_out_land_demarcation_at_site__c' && event.target.checked) {
            this.currentRequestInfo.Re_demarcation__c = false;
        }
    }
    get hasActionReq() {
        if (this.actionReqCases && this.actionReqCases.length > 0)
            return true;
        else
            return false;
    }


    async getDlpCasesInfo() {
        //this.template.querySelector('[data-id="DlpAll"]').classList.add('active-pill');
        //console.log('Inside getDlpCasesInfo');
        this.isLoading = true;
        this.filterCondition = '';

        if (this.selectedStatus) {
            let status = '';
            if (this.selectedStatus === 'New' || this.selectedStatus === 'Work In Progress' || this.selectedStatus === 'Pending with Customer') {
                status = this.selectedStatus;
            }
            this.filterCondition += ` AND Status LIKE '%${status}%'`;

            if (this.selectedStatus === 'Draft') {
                status = this.selectedStatus;
                this.filterCondition += ` AND Sub_Status__c LIKE '%${status}%'`;
            }
            if (this.selectedStatus === 'Rejected') {
                this.filterCondition += ` AND (Status LIKE '%Cancelled%' OR Status LIKE '%Rejected%')`;
            }
            if (this.selectedStatus === 'Approved') {
                this.filterCondition += ` AND Status LIKE '%Completed%'`;
            }
        }

        //console.log('Test');
        if (this.startDate && this.endDate) {
            const startDateObj = new Date(this.startDate);
            const endDateObj = new Date(this.endDate);

            if (!isNaN(startDateObj.getTime()) && !isNaN(endDateObj.getTime())) {
                endDateObj.setHours(23, 59, 59, 999);
                const startDateFormatted = startDateObj.toISOString();
                const endDateFormatted = endDateObj.toISOString();

                this.filterCondition += ` AND CreatedDate >= ${startDateFormatted} AND CreatedDate <= ${endDateFormatted}`;
            }
        }
        console.log('pageSize'+this.dlpPageSize+'--pageNumber--'+this.pageNumber+'--');
       console.log('--@@@this.SearchValueDLPCase_--'+ this.SearchValueDLPCase);
        await getAllDlpCases({
            pageSize: this.dlpPageSize,
            pageNumber: this.pageNumber,
            filterCondition: this.filterCondition,
            caseRetriveType : this.caseRetriveTypeValue,
            searchValue : this.SearchValueDLPCase,
            sortBy: this.dlpSortByValue
        })

            .then(result => {
              
                if (result) {
                    var data = JSON.parse(result);
                    this.isLoading = false;
                    
                    this.DlpfilteredCases = data.cs;
                    this.pageNumber = data.pageNumber;
                    this.totalRecords = data.totalRecords;
                    this.recordStart = data.recordStart;
                    this.recordEnd = data.recordEnd;
                    this.totalPages = Math.ceil(data.totalRecords / this.dlpPageSize);
                    this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
                    this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);
                    

                   // this.filteredCases = this.allMyCases;
                     if (this.DlpfilteredCases.length > 0)
                     {
                        console.log('@@@Value'+JSON.stringify(this.DlpfilteredCases));
                        this.noDlpCases = false;
                        this.DlpfilteredCases.forEach(caseItem => {
                            // Ensure that 'Assigned_To__r' and 'Assigned_To__r.Name' are defined
                            if (!caseItem.Assigned_To__r || !caseItem.Assigned_To__r.Name) {
                                caseItem.Assigned_To__r = caseItem.Assigned_To__r || {};  // Initialize the object if it doesn't exist
                                caseItem.Assigned_To__r.Name = '';  // Set default value if Name is missing
                            }
                        });
                        console.log('@@@this.DlpfilteredCases.'+JSON.stringify(this.DlpfilteredCases));
                     }                        
                     else
                     {
                        this.noDlpCases = true;
                     }
    

                 }
                 else
                 {
                    this.isLoading = false;
                 }
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = JSON.stringify(error);
                console.log('errorMessage-1'+errorMessage);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('getAllCasesInfo: ' + errorMessage);
            });

    }




    async getAllCasesInfo() {
        this.isLoading = true;
        this.filterCondition = '';

        if (this.selectedStatus) {
            let status = '';
            if (this.selectedStatus === 'New' || this.selectedStatus === 'Work In Progress' || this.selectedStatus === 'Pending with Customer') {
                status = this.selectedStatus;
            }
            this.filterCondition += ` AND Status LIKE '%${status}%'`;

            if (this.selectedStatus === 'Draft') {
                status = this.selectedStatus;
                this.filterCondition += ` AND Sub_Status__c LIKE '%${status}%'`;
            }
            if (this.selectedStatus === 'Rejected') {
                this.filterCondition += ` AND (Status LIKE '%Cancelled%' OR Status LIKE '%Rejected%')`;
            }
            if (this.selectedStatus === 'Approved') {
                this.filterCondition += ` AND Status LIKE '%Completed%'`;
            }
        }

        if (this.startDate && this.endDate) {
            const startDateObj = new Date(this.startDate);
            const endDateObj = new Date(this.endDate);

            if (!isNaN(startDateObj.getTime()) && !isNaN(endDateObj.getTime())) {
                endDateObj.setHours(23, 59, 59, 999);
                const startDateFormatted = startDateObj.toISOString();
                const endDateFormatted = endDateObj.toISOString();

                this.filterCondition += ` AND CreatedDate >= ${startDateFormatted} AND CreatedDate <= ${endDateFormatted}`;
            }
        }

        await getAllCases({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            filterCondition: this.filterCondition
        })
            .then(result => {
                if (result) {
                    var data = JSON.parse(result);
                    this.filteredCases = data.cs;
                    this.pageNumber = data.pageNumber;
                    this.totalRecords = data.totalRecords;
                    this.recordStart = data.recordStart;
                    this.recordEnd = data.recordEnd;
                    this.totalPages = Math.ceil(data.totalRecords / this.pageSize);
                    this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
                    this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);

                    this.allMyCases = data.cs;
                    //this.noRecords = false;
                    this.allMyCases.forEach(item => {
                        if (this.cancelBtnShowList.includes(item.Sub_Status__c))
                            item.showCancelIcon = true;
                        else
                            item.showCancelIcon = false;

                        if (item.Sub_Status__c == 'Waiting for Payment')
                            item.showPaymentIcon = true;
                        else
                            item.showPaymentIcon = false;
                    });
                    this.allMyCases.forEach(item => {
                        if (item.Sub_Status__c == 'Assigned')
                            item.Sub_Status__c = 'Submitted';
                    });
                    this.allMyCases.forEach(item => {
                        if (item.Sub_Status__c == 'Draft') {
                            item.showDeleteBtn = true;
                        } else {
                            item.showDeleteBtn = false;
                        }
                    });
                    this.isLoading = false;
                    this.filteredCases = this.allMyCases;
                    if (this.filteredCases.length > 0)
                        this.noRecords = false;
                    else
                        this.noRecords = true;

                }
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('getAllCasesInfo: ' + errorMessage);
            });

    }

    handleNext() {
        this.pageNumber = this.pageNumber + 1;
        if (this.activeBtn == 'Requests')
            this.getAllCasesInfo();
        if (this.activeBtn == 'Financials')
            this.getPaymentDetails();
        if (this.activeBtn =='dlpCase')
            this.getDlpCasesInfo();

    }
    handlePrev() {
        this.pageNumber = this.pageNumber - 1;
        if (this.activeBtn == 'Requests')
            this.getAllCasesInfo();
        if (this.activeBtn == 'Financials')
            this.getPaymentDetails();
        if (this.activeBtn =='dlpCase')
            this.getDlpCasesInfo();
    }
    handleStartDate(event) {
        if (this.activeBtn == 'Requests') {
            this.startDate = event.target.value;
            this.getAllCasesInfo();
        }
        if (this.activeBtn == 'Financials') {
            this.startDate = event.target.value;
            this.getPaymentDetails();
        }
    }

    handleEndDate(event) {
        if (this.activeBtn == 'Requests') {
            this.endDate = event.target.value;
            this.getAllCasesInfo();
        }
        if (this.activeBtn == 'Financials') {
            this.endDate = event.target.value;
            this.getPaymentDetails();
        }
    }

    inactiveAllPills() {
        this.template.querySelector('[data-id="All"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="In Progres"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="Pending"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="Approved"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="Rejected"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="Saved"]').classList.remove('active-pill');
    }
    filterReq(event) {
        this.template.querySelector('[data-id="Requests"]').classList.add('active');
        this.template.querySelector('[data-id="Home"]').classList.remove('active');
        this.hideAllForms();
        this.activeBtn = 'Requests';
        this.clearPaginationData();
        this.showMyCases = true;
        this.selectedStatus = event.currentTarget.dataset.status;

        this.getAllCasesInfo().then(() => {
            this.inactiveAllPills();
            if (this.selectedStatus == 'all')
                this.template.querySelector('[data-id="All"]').classList.add('active-pill');
            if (this.selectedStatus == 'Work In Progress')
                this.template.querySelector('[data-id="In Progres"]').classList.add('active-pill');
            if (this.selectedStatus == 'Pending with Customer')
                this.template.querySelector('[data-id="Pending"]').classList.add('active-pill');
            if (this.selectedStatus == 'Approved')
                this.template.querySelector('[data-id="Approved"]').classList.add('active-pill');
            if (this.selectedStatus == 'Rejected')
                this.template.querySelector('[data-id="Rejected"]').classList.add('active-pill');
            if (this.selectedStatus == 'Draft')
                this.template.querySelector('[data-id="Saved"]').classList.add('active-pill');
        });
    }

    handleSaveAsDraft() {
        try {
            this.hideAllForms();
            this.showMyCases = true;
            this.getAllCasesInfo();
            if (this.template.querySelector('[data-name="Requests"]'))
                this.template.querySelector('[data-name="Requests"]').classList.add('active');
            if (this.template.querySelector('[data-name="Home"]'))
                this.template.querySelector('[data-name="Home"]').classList.remove('active');
            if (this.template.querySelector('[data-name="Financials"]'))
                this.template.querySelector('[data-name="Financials"]').classList.remove('active');
        } catch (e) {
            //console.log(e.message);
        }
    }
    handleUpdate() {
        this.isLoading = true;
        this.caseObj.Id = this.currentRequestId;
        this.caseObj.Sub_Status__c = 'Submitted with Ammendments';
        this.caseObj.Status = 'Work In Progress';

        updateCase({ caseObj: this.caseObj })
            .then(data => {
                this.customerDocuments();
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('success', 'Documents are updated successfully', '', 3000);
                this.showOtherDoc = false;
                this.updateCustomerDoc = false;
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('error while saving on updation-->' + errorMessage);
            });
    }

    async handleSave(event) {
        try {
            let btn = event.target.dataset.name;
            this.cancelReq = false;
            const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox,lightning-textarea')]
                .reduce((validSoFar, inputField) => {
                    inputField.reportValidity();
                    return validSoFar && inputField.checkValidity();
                }, true);

            if (isInputsCorrect) {
                this.isLoading = true;
                this.isSaved = true;
                this.disServiceType = true;
                if (btn == 'draft') {
                    this.caseObj.Sub_Status__c = 'Draft';
                }
                else if (btn == 'submit') {
                    this.caseObj.Sub_Status__c = 'Submitted';
                    this.isSubmitted = true;
                }

                //get Exisiting checkbox values in case of update
                this.utlilityPicklistValues.forEach(item => {
                    if (item.isChecked == true) {
                        if (!this.utilityValues.includes(item.label))
                            this.utilityValues.push(item.label);
                    }
                });
                this.caseObj['Utility__c'] = this.utilityValues.join(';');

                this.excavationPicklistValues.forEach(item => {
                    if (item.isChecked == true) {
                        if (!this.excavationValues.includes(item.label))
                            this.excavationValues.push(item.label);
                    }
                });
                this.caseObj['Method_of_Excavation__c'] = this.excavationValues.join(';');

                if (this.currentRequestId) {
                    this.caseObj.Id = this.currentRequestId;
                    await this.updateCasehandler();

                } else {
                    this.caseObj.Type = this.activeBtn;
                    let tempProduct = '';
                    if (this.activeBtn != 'Temporary License Agreement')
                        tempProduct = this.productValues.filter((item) => item.value == this.caseObj.ProductId)[0].label;
                    this.caseObj.Subject = 'DM-' + this.activeBtn + '-' + tempProduct;
                    this.caseObj.Origin = 'Portal';
                    await this.createCaseHandler();
                }
            }

        } catch (e) {
            //console.log(e.message);
        }

    }
    createCaseHandler() {
        createCase({ caseObj: this.caseObj })
            .then(data => {
                this.caseObj = data;
                this.getAllCasesInfo();
                this.currentRequestId = data.Id;
                this.hideAllForms();
                this.showDocuments = true;
                this.showSubmitBtn = true;
                this.isStep1Done = true;
                this.showCustomerDocuments();
                this.isSaved = false;
                this.isLoading = false;
                refreshApex(this.caseRecord);
            })
            .catch(error => {
                this.isLoading = false;
                this.isSaved = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                } else {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', error.body.message, '', 3000);
                }
                //console.log('error while saving on creation-->' + errorMessage);
            });
    }
    handleBackHome() {
        this.chartRendered = false;
        this.hideAllForms();
        this.showHomepage = true;
        this.isSubmitted = false;
        this.getAllCasesInfo();
        this.fetchCaseCounts();
        this.fetchTypeCounts();
        if (this.template.querySelector('[data-name="Home"]'))
            this.template.querySelector('[data-name="Home"]').classList.add('active');
        if (this.template.querySelector('[data-name="Requests"]'))
            this.template.querySelector('[data-name="Requests"]').classList.remove('active');

        if (this.template.querySelector('[data-name="Financials"]'))
            this.template.querySelector('[data-name="Financials"]').classList.remove('active');
    }
    updateCasehandler() {
        this.isLoading = true;
        updateCase({ caseObj: this.caseObj })
            .then(data => {
                this.caseNumber = this.caseNum;
                this.showCustomerDocuments();
                this.hideAllForms();
                this.isSaved = false;
                this.isLoading = false;
                if (this.isSubmitted) {
                    this.sucessPage = true;
                } else {
                    this.showDocuments = true;
                    this.showSubmitBtn = true;
                }
                if (this.cancelReq) {
                    this.hideAllForms();
                    this.getAllCasesInfo();
                    this.showMyCases = true;
                }

            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('error while saving on creation-->' + errorMessage);
            });
    }
    showCustomerDocuments() {
        getCustomerDocuments({ caseId: this.currentRequestId })
            .then(data => {
                this.csNumber = data[0].Case__r.CaseNumber;
                this.accNumber = data[0].Case__r.Account.AccountNumber__c;
                this.csOwner = data[0].Case__r.OwnerId;

                this.extFileList = data.map(doc => {
                    const hasExternalFiles = doc.External_Files__r && doc.External_Files__r.length > 0;
                    const singleFile = hasExternalFiles ? doc.External_Files__r[0] : null;

                    return {
                        ...doc,
                        hasExternalFiles: hasExternalFiles,
                        externalFiles: hasExternalFiles ? doc.External_Files__r : [],
                        singleFile: singleFile,
                        docValue: null,
                        isDisabled: hasExternalFiles
                    };
                });

                this.noDocuments = this.extFileList.length === 0;
            })
            .catch(error => {
                //console.error('error->' + error.message);
            });
    }
    handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();
        if (searchKey) {
            if (this.allMyCases) {
                let searchRecords = [];
                for (let record of this.allMyCases) {
                    let valuesArray = Object.values(record);
                    for (let val of valuesArray) {
                        let strVal = String(val);
                        if (strVal) {
                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
                this.filteredCases = searchRecords;
                if (this.filteredCases.length > 0)
                    this.nofilterRecords = false;
                else
                    this.nofilterRecords = true;
            }
        } else {
            this.filteredCases = this.allMyCases;
        }
    }
    handleFinancialSearch(event) {
        const searchKey = event.target.value.toLowerCase();
        if (searchKey) {
            if (this.paymentInfoList) {
                let searchRecords = [];
                for (let record of this.paymentInfoList) {
                    let valuesArray = Object.values(record);
                    for (let val of valuesArray) {
                        let strVal = String(val);
                        if (strVal) {
                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
                this.paymentInfoFilterList = searchRecords;
                if (this.paymentInfoFilterList.length > 0)
                    this.nofilterpaymentRecords = false;
                else
                    this.nofilterpaymentRecords = true;
            }
        } else {
            this.paymentInfoFilterList = this.paymentInfoList;
        }
    }
    dlpcurrentRequestId
    dlpCaseNumber
    dlpCurrentInfo
    ShowDlpDetails=false;
    pickDlpStatus;
    pickDlpAppointmentstatus;
    dlpAccountValue ='';
    dlpContactValue ='';
    @track dlpCaseCategoryValue ='';
    @track dlpCaseSubCategoryValue ='';
    dlpCaseComment='';
    dlpCaseRecordType='';
    dlpCasePriority='';
    dlpCaseOrigin='';
    dlpCaseOwner='';
    dlpCaseAssignedTo='';
    dlpCaseUnit='';
    dlpAppointmentDate ='';
    dlpWebEmailValue ='';
    dlpWebNameValue ='';
    dlpWebPhoneValue ='';
    dlpPostComment = '';
    dlpAppointmentStatus = '';
    dlpLastActivePill = null;
   // dlpCaseNumber ='';
    handleDLPViewClick(event) {
        this.dlpLastActivePill = this.template.querySelector(".active-pill")?.dataset.id;
        this.dlpcurrentRequestId = event.target.dataset.id;
        console.log('dlpcurrentRequestId --'+this.dlpcurrentRequestId);
        this.dlpCaseNumber = event.target.dataset.caseno;
        //console.log('dlpCaseNumber'+this.dlpCaseNumber);
        getDLpCaseInfo({ caseId: event.target.dataset.id })
        .then(data => {
            this.ShowDlpDetails =true;
            this.showDLPCases = false;
            this.dlpRecordTypeId =data.RecordTypeId;
            //pickDlpStatus
            //console.log('Data value>>>2>>'+data);
            console.log('data Value final>>>'+JSON.stringify(data));
            this.dlpRecordTypeId =data.RecordTypeId;
         
             this.dlpAccountValue = data.hasOwnProperty('AccountId') ? data.Account.Name :null;
             this.dlpContactValue = data.hasOwnProperty('ContactId') ? data.Contact.Name :null;
             this.dlpCaseOrigin = data.hasOwnProperty('Origin') ? data.Origin :null;
             this.dlpCaseCategoryValue = data.hasOwnProperty('CaseCategory__c') ? data.CaseCategory__c :null;
             this.dlpCaseSubCategoryValue = data.hasOwnProperty('SubCategory__c') ? data.SubCategory__c :null;
             this.dlpCaseComment= data.hasOwnProperty('CaseComments__c') ? data.CaseComments__c :null;
             this.dlpCaseRecordType= data.hasOwnProperty('Recordtype_Name__c') ? data.Recordtype_Name__c :null;
             this.dlpCasePriority= data.hasOwnProperty('Priority') ? data.Priority :null;
             this.dlpCaseOwner= data.hasOwnProperty('OwnerId') ? data.Owner.Name :null;
             this.dlpCaseAssignedTo= data.hasOwnProperty('Assigned_To__c') ? data.Assigned_To__r.Name :null;
             this.dlpCaseUnit= data.hasOwnProperty('Unit_Name__c') ? data.Unit_Name__c :null;
             this.dlpAppointmentDate = data.hasOwnProperty('Appointment_Date__c') ? data.Appointment_Date__c :null;
             this.dlpWebEmailValue = data.hasOwnProperty('SuppliedEmail') ? data.SuppliedEmail :null;
             this.dlpWebNameValue = data.hasOwnProperty('SuppliedName') ? data.SuppliedName :null;
             this.dlpWebPhoneValue = data.hasOwnProperty('SuppliedPhone') ? data.SuppliedPhone :null;
             this.dlpPostComment = '';
             this.dlpStatus = data.hasOwnProperty('Status') ? data.Status :null;
             this.dlpAppointmentStatus = data.hasOwnProperty('Appointment_Status__c') ? data.Appointment_Status__c :null;

             //console.log('this.dlpCaseAssignedTo'+this.dlpCaseAssignedTo);
             if(this.dlpCaseAssignedTo ==null)
             {
                this.showAcceptButton=true;
             }
             else
             {
                this.showAcceptButton=false;
             }
            //console.log('dlpRecordTypeId'+this.dlpRecordTypeId);
            this.dlpCurrentInfo = data;
            //console.log('Data >>> ' + JSON.stringify(this.dlpCurrentInfo));
        }).catch(error => {
            const errorMessage = JSON.stringify(error);
            if (errorMessage.includes("You do not have access to the Apex class")) {
                this.template.querySelector('c-common-toast-msg-for-communities')
                    .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
            }
        })

    }

    handleViewClick(event) {
        this.showHomepage = false;
        this.hideSideBar = true;
        this.clearCheckedUtilityStatusForAll();
        this.initilizeCaseObject();
        this.showOtherUtilityName = false;
        this.showOtherExcavationName = false;
        this.showSubmitBtn = false;
        this.showNextbtn = false;
        this.currentRequestId = event.target.dataset.id;
        this.caseNum = event.target.dataset.caseno;
        this.showBackbtn = true;
        this.customerDoc = [];
        this.showOtherDoc = false;
        this.getTLADocumentData();
        this.deleteBtn = false;
        this.customerDocuments();

        getFeedInfo({ parentId: this.currentRequestId })
            .then(data => {
                let tempFeed = [];
                data.forEach(item => {
                    if (item.Body?.includes('@' + this.userInfo[0].Name) || item.CreatedBy?.Id === this.userInfo[0].Id) { // updated by Aswathi 16/01/25
                        tempFeed.push(item);
                    }
                });
                this.feedInfo = tempFeed;
                if (this.feedInfo.length > 0) {
                    this.isFeedAvailable = true;
                } else {
                    this.isFeedAvailable = false;
                }

            })
            .catch(error => {
                //console.log('Error getFeedInfo-' + error);
            });

        /* customerDocuments({ caseId: this.currentRequestId })
            .then(data => {
                this.externalFilesList = [];
                data.forEach(item => {
                    let temp = new Object();
                    temp.FileName = item.File_Name__c;
                    temp.DocType = item.Document__r.DocumentType__c;
                    temp.FileFormat = item.File_Format__c;
                    temp.OtherDocName = item.Document__r.Other_Document_Name__c;
                    temp.ExternalUrl = item.External_URL__c;
                    this.externalFilesList.push(temp);
                });
            })
            .catch(error => {
                console.log('error->' + error.message)
            }); */

        // get Aldar documents
        getDocuments({ sObjectName: 'Case__c', recordId: this.currentRequestId, recordType: 'CustomerDocument', isAvailable: true })
            .then(data => {
                if (data && data.length > 0) {
                    this.noFileMsg = false;
                    this.aldarDocumentList = data;
                    this.files = data;
                    this.contentVersionIds = data.map(doc => doc.contentVersion.Id);
                } else {
                    this.noFileMsg = true;
                    this.files = [];
                    this.contentVersionIds = [];
                }
            })
            .catch(error => {
                //console.log('Error fetching documents:', error);
            });

        getCaseInfo({ caseId: event.target.dataset.id })
            .then(data => {
                this.currentRequestInfo = null;
                this.currentRequestInfo = data;
                this.isDisabled = true;
               // this.selectedProductPrice = this.currentRequestInfo.Service_Price__c;
                if (data.Sub_Status__c == 'Completed') {
                    this.showPermitClsBtn = true;
                } else {
                    this.showPermitClsBtn = false;
                }
                if (data?.Product?.Name == 'Land Demarcation') {
                    this.showDemaraction = true;
                } else {
                    this.showDemaraction = false;
                }

                if (data.Sub_Status__c == 'Additional Information Required from Customer') {
                    this.updateCustomerDoc = true;
                } else {
                    this.updateCustomerDoc = false;
                }
                if (data.Sub_Status__c == 'Draft' || data.Sub_Status__c == 'Additional Information Required from Customer') {
                    this.showCustomerDocuments();
                    this.isDisabled = false;
                    //this.disServiceType = false;
                    this.showSubmitBtn = true;
                    this.showBackbtn = false;
                    if (data.Sub_Status__c == 'Draft') {
                        this.isDraft = true;
                        this.showNextbtn = true;
                        this.showSubmitBtn = false;
                        //this.showCustomerDocuments();
                    } else {
                        this.isDraft = false;
                        this.showNextbtn = false;
                        this.showSubmitBtn = true;
                    }
                }
                if (data.Utility__c) {
                    let utilitylist = data.Utility__c.split(';');
                    utilitylist.forEach(utl => {
                        this.utlilityPicklistValues.forEach(item => {
                            if (item.label == utl) {
                                item.isChecked = true;
                            }
                        });
                        if (utl == 'Others')
                            this.showOtherUtilityName = true;
                    });
                }
                if (data.Method_of_Excavation__c) {
                    let excavationlist = data.Method_of_Excavation__c.split(';');
                    excavationlist.forEach(utl => {
                        this.excavationPicklistValues.forEach(item => {
                            if (item.label == utl) {
                                item.isChecked = true;
                            }
                        });
                        if (utl == 'Others')
                            this.showOtherExcavationName = true;
                    });
                }
                getProducts({ type: data.Type })
                    .then(data => {
                        this.productValues = data?.map(
                            ({ Id, Name }) => ({ value: Id, label: Name })
                        );
                    })
                    .catch(error => {
                        //console.log('error->' + error.message)
                    });

                if (data.Type == 'NOC') {
                    this.activeBtn = 'NOC';
                    this.showNOCForm = true;
                    if (data.Development_Name__c == 'Yas Island')
                        this.showYasIslandDetails = true;
                }

                if (data.Type == 'Permit to Work') {
                    this.activeBtn = 'Permit to Work';
                    this.currentRequestInfo.Duration_of_Work_Days__c = data.Duration_of_Work_Days__c.toString();
                    this.currentRequestInfo.Duration_of_Work_Months__c = data.Duration_of_Work_Months__c.toString();
                    this.currentRequestInfo.Duration_of_Work_Years__c = data.Duration_of_Work_Years__c.toString();
                    this.showPTWForm = true;
                    if (data.Hazards_Identified_Environmental_Impact__c == 'Yes')
                        this.showHazardImpact = true;
                    if (data.Safety_Precautions_and_Controls_in_Place__c == 'Yes')
                        this.showSafetyPrec = true;
                    if (data.Development_Name__c == 'Yas Island')
                        this.showYasIslandDetails = true;
                }
                if (data.Type == 'Others') {
                    this.activeBtn = 'Others';
                    this.showOtherForm = true;
                }
                if (data.Type == 'Temporary License Agreement') {
                    this.activeBtn = 'Temporary License Agreement';
                    this.showTLAForm = true;
                    if (data.Is_the_site_Inspected__c == 'Yes')
                        this.showInspectedDate = true;
                    if (data.Is_the_site_Inspected__c == 'Is_the_area_pre_approved_by_aldar__c')
                        this.showSplitPayment = true;
                    this.showTLAForm = true;
                }
                this.showMyCases = false;
            })
            .catch(error => {
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('error -->' + errorMessage);
            });
    }
    customerDocuments() {
        customerDocuments({ caseId: this.currentRequestId })
            .then(data => {
                this.externalFilesList = [];
                data.forEach(item => {
                    let temp = new Object();
                    temp.FileName = item.File_Name__c;
                    //temp.DocType = item.Document__r.DocumentType__c;
                    if (item.Document__r.DocumentType__c.toLowerCase() === 'others') {
                        temp.DocType = item.Document__r.Other_Document_Name__c;
                    } else {
                        temp.DocType = item.Document__r.DocumentType__c;
                    }
                    temp.FileFormat = item.File_Format__c;
                    temp.OtherDocName = item.Document__r.Other_Document_Name__c;
                    temp.ExternalUrl = item.External_URL__c;
                    this.externalFilesList.push(temp);
                });
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }
    handleBackBtn() {
        try {
            this.hideAllForms();
            this.clearPaginationData();
            this.showMyCases = true;
            this.selectedStatus = 'all';
            this.getAllCasesInfo();
            if (this.template.querySelector('[data-name="Requests"]'))
                this.template.querySelector('[data-name="Requests"]').classList.add('active');
            if (this.template.querySelector('[data-name="Home"]'))
                this.template.querySelector('[data-name="Home"]').classList.remove('active');
            if (this.template.querySelector('[data-name="Financials"]'))
                this.template.querySelector('[data-name="Financials"]').classList.remove('active');
        } catch (e) {
            //console.log(e.message);
        }
    }
    handleCancel(event) {
        this.openCancelModal = true;
        this.currentRequestId = event.target.dataset.id;
    }
    closeCancelModal() {
        this.openCancelModal = false;
    }
    requestCancelHandler(event) {
        this.caseObj.Sub_Status__c = 'Cancelled';
        this.caseObj.Status = 'Cancelled';
        this.caseObj.Id = this.currentRequestId;
        this.cancelReq = true;
        this.updateCasehandler();
    }
    handleDeleteReq(event) {
        this.openDeleteModal = true;
        this.currentRequestId = event.target.dataset.id;
    }
    closeDeleteModal() {
        this.openDeleteModal = false;
    }
    async deleteRequestRecord() {
        this.disablebtn = true;
        this.isLoadPopup = true;
        deleteRequestRecord({ caseId: this.currentRequestId })
            .then(() => {
                this.hideAllForms();
                this.getAllCasesInfo();
                this.showMyCases = true;
                this.isLoadPopup = false;
                this.disablebtn = false;
            })
            .catch(error => {
                this.isLoadPopup = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('Error deleting Case record:' + errorMessage);
            });
        /*  try {
             await deleteRecord(this.currentRequestId);
             this.template.querySelector('c-common-toast-msg-for-communities').
                 showToast('success', 'Request deleted successfully', '', 3000);
             this.hideAllForms();
             this.getAllCasesInfo();
             this.showMyCases = true;
             this.isLoadPopup = false;
         } catch (error) {
             console.error('Error deleting Case record:', error);
             this.isLoadPopup = false;
         } */
    }

    getSRRelatedDocuments() {
        getSRRelatedDocuments({ serviceId: this.product })
            .then(data => {
                let extFileArray = [];
                if (data && data.length > 0 && data[0].Mandatory_Documents__c) {
                    let documents = data[0].Mandatory_Documents__c.split(',');
                    documents.forEach(item => {
                        let extFileObj = new Object();
                        extFileObj.DocType = item;
                        extFileObj.FileName = '';
                        extFileObj.FileFormat = '';
                        extFileObj.ExternalUrl = '';
                        extFileObj.OtherDocName = '';
                        extFileArray.push(extFileObj);
                    });
                }
                this.extFileList = extFileArray;
            })
            .catch(error => {
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('error-->' + errorMessage);
            });
    }
    handlePrevious() {
        if (!this.currentRequestInfo.Sub_Status__c == 'Draft') {
            this.currentRequestInfo = this.caseObj;
        }
        this.showDocuments = false;
        this.showSubmitBtn = false;
        if (this.activeBtn == 'NOC') {
            this.showNOCForm = true;
            if (this.caseObj.Utility__c) {
                let utilitylist = this.caseObj.Utility__c.split(';');
                utilitylist.forEach(utl => {
                    this.utlilityPicklistValues.forEach(item => {
                        if (item.label == utl) {
                            item.isChecked = true;
                        }
                    });
                    if (utl == 'Others')
                        this.showOtherUtilityName = true;
                });
            }
        }
        if (this.activeBtn == 'Permit to Work') {
            this.showPTWForm = true;
            this.currentRequestInfo.Duration_of_Work_Days__c = this.caseObj.Duration_of_Work_Days__c.toString();
            this.currentRequestInfo.Duration_of_Work_Months__c = this.caseObj.Duration_of_Work_Months__c.toString();
            this.currentRequestInfo.Duration_of_Work_Years__c = this.caseObj.Duration_of_Work_Years__c.toString();
            if (this.caseObj.Utility__c) {
                let utilitylist = this.caseObj.Utility__c.split(';');
                utilitylist.forEach(utl => {
                    this.utlilityPicklistValues.forEach(item => {
                        if (item.label == utl) {
                            item.isChecked = true;
                        }
                    });
                    if (utl == 'Others')
                        this.showOtherUtilityName = true;
                });
            }
            if (this.caseObj.Method_of_Excavation__c) {
                let excavationlist = this.caseObj.Method_of_Excavation__c.split(';');
                excavationlist.forEach(utl => {
                    this.excavationPicklistValues.forEach(item => {
                        if (item.label == utl) {
                            item.isChecked = true;
                        }
                    });
                    if (utl == 'Others')
                        this.showOtherExcavationName = true;
                });
            }
        }

        if (this.activeBtn == 'Others') {
            this.showOtherForm = true;
        }
        if (this.activeBtn == 'Temporary License Agreement') {
            this.showTLAForm = true;
        }
        this.template.querySelector('.step2').classList.remove('slds-is-active');
    }

    async handleFileUpload(event) {
        //console.log('this.csNumber',this.csNumber);
        //console.log('this.accNumber',this.accNumber);
       // this.isLoadingFile = true; -- removed by nelesgh to test 
                this.isLoadingFile = false;

        try {
            // console.log('this.accNumber handleFileUpload'+this.accNumber);
            // console.log('this.csNumber'+this.csNumber);
            // console.log('file -> ',event.currentTarget.files[0]);
            // const fileInput = event.currentTarget.files;
            // const index = event.currentTarget.dataset.index;
            // if (fileInput.length > 0) {
            //     const fileName = fileInput[0].name;
            //     this.extFileList[index].FileName = fileName;
            //     this.extFileList[index].isDisabled = true;
            // }
            // const inputParams = {
            //     dataId: event.currentTarget.dataset.id,
            //     userId: event.currentTarget.dataset.userId,
            //     groupId: event.currentTarget.dataset.groupId,
            //     folderName: event.currentTarget.dataset.folderName,
            //     subFolderName: this.accNumber + '/' + this.csNumber,
            //     source: event.currentTarget.dataset.source,
            //     file: event.currentTarget.files[0],
            // };
            // console.log('file data ',JSON.stringify(inputParams));
            const index = event.currentTarget.dataset.index;
            const fileObj = event.currentTarget.files[0];
            console.log('length ', event.currentTarget.files.length);
             console.log('fileObj1 --> ',fileObj);
            /*if (event.currentTarget.files.length > 0) {
                const fileName = fileObj.name;
                this.customerDoc[index].fileName = fileName;
            }*/

            if (fileObj.length > 0) {
                 const fileName = fileObj.name;
                 this.extFileList[index].FileName = fileName;
                 this.extFileList[index].isDisabled = true;
             }

            // --- MIME TYPE FIX FOR CAD FILES ---
            let mimeType = fileObj.type;  // may be empty for CAD files
            const fileName = fileObj.name;
            console.log('fileObj2 --> ',fileObj);

            const ext = fileName.split('.').pop().toLowerCase();
            console.log('mimeType type --> ',mimeType);
            if (!mimeType || mimeType === "") {
                const cadMimeMap = {
                    dwg: "image/vnd.dwg",
                    dxf: "image/vnd.dxf",
                    stp: "application/step",
                    step: "application/step",
                    igs: "model/iges",
                    iges: "model/iges",
                    sldprt: "application/sldworks",
                    sldasm: "application/sldasm"
                };

                mimeType = cadMimeMap[ext] || "application/octet-stream"; // fallback
            }
            // Overwrite File type 
            const correctedFile = new File([fileObj], fileObj.name, { type: mimeType });
            const inputParams = {
                dataId: event.currentTarget.dataset.id,
                userId: event.currentTarget.dataset.userId,
                groupId: event.currentTarget.dataset.groupId,
                folderName: event.currentTarget.dataset.folderName,
                subFolderName: this.accNumber + '/' + this.csNumber,
                source: event.currentTarget.dataset.source,
                file: correctedFile,     // send updated object with detected MIME
            };
            console.log('correctedFile : ', correctedFile);
            console.log('inputparams ->',JSON.stringify(inputParams));
            let res = await window.callBlob(inputParams);
            if (res == 'Success') {
                this.isLoadingFile = false;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('success', 'Document has been uploaded successfully', '', 3000);
            }
            else {
                this.isLoadingFile = false;
                this.extFileList[index].FileName = null;
                this.extFileList[index].isDisabled = false;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('warning', 'Unable to upload the document, please try again', '', 3000);
            }
        } catch (e) {
            console.log('-error--' + e.message);
            this.isLoadingFile = false;
            this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('error', e.message, '', 3000);
        }
    }
    handleFileDelete(event) {
        const index = event.target.dataset.index;
        const id = event.target.dataset.id;
        try {
            updateExternalFileAsDeleted({ documentId: id })
                .then(data => {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('success', 'Document has been deleted successfully', '', 3000);
                    this.extFileList[index].FileName = null;
                    this.extFileList[index].isDisabled = false;
                    this.showCustomerDocuments();
                })
                .catch(error => {
                    //console.log('error--' + error.message);
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('warning', 'Unable to delete document, please try again', '', 3000);
                })
        } catch (error) {
            console.error('Error downloading file:', error);
        }
    }
    handleOtherDocument(event) {
        this.otherDocumentName = event.target.value;
        this.documentType = 'Others';
    }
    async handleOtherDocFileUpload(event) {
        this.isLoadingFile = true;
        try {
            // const index = event.currentTarget.dataset.index;
            // const fileInput = event.currentTarget.files;
            // if (fileInput.length > 0) {
            //     const fileName = fileInput[0].name;
            //     this.customerDoc[index].fileName = fileName;
            // }
            // const inputParams = {
            //     dataId: event.currentTarget.dataset.id,
            //     userId: event.currentTarget.dataset.userId,
            //     groupId: event.currentTarget.dataset.groupId,
            //     folderName: event.currentTarget.dataset.folderName,
            //     subFolderName: this.accNumber + '/' + this.csNumber,
            //     source: event.currentTarget.dataset.source,
            //     file: event.currentTarget.files[0],
            // };
            const index = event.currentTarget.dataset.index;
            const fileObj = event.currentTarget.files[0];
            if (event.currentTarget.files.length > 0) {
                const fileName = fileObj.name;
                this.customerDoc[index].fileName = fileName;
            }

            // --- MIME TYPE FIX FOR CAD FILES ---
            let mimeType = fileObj.type;  // may be empty for CAD files
            const fileName = fileObj.name;
            const ext = fileName.split('.').pop().toLowerCase();
            console.log('mimeType type --> ',mimeType);
            if (!mimeType || mimeType === "") {
                const cadMimeMap = {
                    dwg: "image/vnd.dwg",
                    dxf: "image/vnd.dxf",
                    stp: "application/step",
                    step: "application/step",
                    igs: "model/iges",
                    iges: "model/iges",
                    sldprt: "application/sldworks",
                    sldasm: "application/sldasm"
                };

                mimeType = cadMimeMap[ext] || "application/octet-stream"; // fallback
            }
            // Overwrite File type 
            const correctedFile = new File([fileObj], fileObj.name, { type: mimeType });
            const inputParams = {
                dataId: event.currentTarget.dataset.id,
                userId: event.currentTarget.dataset.userId,
                groupId: event.currentTarget.dataset.groupId,
                folderName: event.currentTarget.dataset.folderName,
                subFolderName: this.accNumber + '/' + this.csNumber,
                source: event.currentTarget.dataset.source,
                file: correctedFile,     // send updated object with detected MIME
            };
            console.log('correctedFile : ', correctedFile);
            console.log('inputparams ->',JSON.stringify(inputParams));
            let res = await window.callBlob(inputParams);
            if (res == 'Success') {
                this.deleteBtn = true;
                this.isLoadingFile = false;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('success', 'Document has been uploaded successfully', '', 3000);
            }
            else {
                this.isLoadingFile = false;
                //this.customerDoc[index].fileName = null;
                this.deleteBtn = false;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('warning', 'Unable to upload the document, please try again', '', 3000);
            }
        } catch (e) {
            console.log('-error--' + e.message);
            this.isLoadingFile = false;
            this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('error',e.message , '', 3000);
        }
    }
    handleOtherDocFileDelete(event) {
        const index = event.target.dataset.index;
        const id = event.target.dataset.id;
        try {
            updateExternalFileAsDeleted({ documentId: id })
                .then(data => {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('success', 'Document has been deleted successfully', '', 3000);
                    this.customerDoc = this.customerDoc.map((doc, idx) => {
                        if (idx == index) {
                            return { ...doc, fileName: null };
                        }
                        return doc;
                    });

                    this.customerDoc = [...this.customerDoc];
                })
                .catch(error => {
                    //console.log('error--' + error.message);
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('warning', 'Unable to delete document, please try again', '', 3000);
                })
        } catch (error) {
            console.error('Error downloading file:', error);
        }
    }
    handleSaveOtherDoc() {
        this.isSaveDoc = true;
        this.addDocSpinner = true;
        try {
            updateOtherDocument({ caseId: this.currentRequestId, otherDoc: this.otherDocumentName, docType: this.documentType })
                .then(data => {
                    this.docValue = null;
                    this.customerDoc = [...this.customerDoc, data];
                    this.closeModal();
                    this.showOtherDocName = false;
                    this.showOtherDoc = true;
                    this.addDocSpinner = false;
                    //this.showCustomerDocuments();
                    const tempdoc = { Id: data.Id, Case__c: this.extFileList[0].Case__c, RecordTypeId: this.extFileList[0].RecordTypeId, DocumentType__c: data.DocumentType__c, Case__r: null, Other_Document_Name__c: data.Other_Document_Name__c, singleFile: null, docValue: null, externalFiles: [] };
                    this.extFileList.push(tempdoc)
                })
                .catch(error => {
                    this.isLoadPopup = false;
                    const errorMessage = JSON.stringify(error);
                    if (errorMessage.includes("You do not have access to the Apex class")) {
                        this.template.querySelector('c-common-toast-msg-for-communities')
                            .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                    }
                    //console.log('error-->' + errorMessage);
                })
        } catch (e) {
            //console.log(e.message);
        }

    }
    handleFileDelete(event) {
        const index = event.target.dataset.index;
        const id = event.target.dataset.id;
        try {
            updateExternalFileAsDeleted({ documentId: id })
                .then(data => {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('success', 'Document has been deleted successfully', '', 3000);
                    this.extFileList[index].FileName = null;
                    this.extFileList[index].isDisabled = false;
                    this.showCustomerDocuments();
                })
                .catch(error => {
                    //console.log('error--' + error.message);
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('warning', 'Unable to delete document, please try again', '', 3000);
                })
        } catch (error) {
            //console.error('Error downloading file:', error);
        }
    }
    handleAddDocument() {
        this.addOtherDocument = true;
        this.isSaveDoc = false;
    }
    handleTLADocument() {
        this.addTLADocument = true;
        this.isSaveDoc = false;
    }

    filePreview(event) {
        const docId = event.target.dataset.id;
        const fileType = event.target.dataset.filetype.toLowerCase();
        const renditionMap = {
            'pdf': 'svgz',
            'jpg': 'ORIGINAL_Jpg',
            'jpeg': 'ORIGINAL_Jpg',
            'png': 'ORIGINAL_Jpg',
            // Add other file types if needed
        };
        const renditionType = renditionMap[fileType] || 'svgz';
        this.previewUrl = window.location.href + `sfsites/c/sfc/servlet.shepherd/version/renditionDownload?rendition=${renditionType}&versionId=` + docId;
        this.showModal = true;
    }
    previewExtFiles(event) {
        const exturl = event.target.dataset.url;
        this.previewUrl = exturl;
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.addOtherDocument = false;
        this.addCustomerDocument = false;
        this.addTLADocument = false;
        this.showBankTransferPopup = false;
    }

    downloadAldarDocument(event) {
        const docId = event.target.dataset.id;
        const loc = window.location.href;
        const url = loc + "sfc/servlet.shepherd/document/download/" + docId;

        /*const downloadLink = document.createElement('a');
        downloadLink.href = url;
        downloadLink.setAttribute('download', '');
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink); */
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        }, false
        );
    }
    async downloadAllDocuments() {
        const fileList = this.contentVersionIds;
        try {
            await loadScript(this, FILE_SAVER);

            if (fileList.length === 1) {
                // If there is only one file, download it directly
                const singleFileId = fileList[0];
                const response = await fetch(window.location.href + '/sfc/servlet.shepherd/version/download/' + singleFileId);
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                const blob = await response.blob();

                // Extract filename from Content-Disposition header
                const contentDisposition = response.headers.get('Content-Disposition');
                let fileName = 'AldarDocument';
                if (contentDisposition && contentDisposition.indexOf('attachment') !== -1) {
                    const match = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
                    if (match != null && match[1]) {
                        fileName = match[1].replace(/['"]/g, '');
                    }
                }

                saveAs(blob, fileName);
            } else {
                // If there are multiple files, download them as a zip
                const fileIds = fileList.join('/');
                const response = await fetch(window.location.href + '/sfc/servlet.shepherd/version/download/' + fileIds);
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                const blob = await response.blob();
                saveAs(blob, 'AldarDocuments.zip');
            }
        } catch (error) {
            //console.error('Error downloading file:', error);
        }
    }
    downloadExtFile(event) {
        this.showSpinner = true;
        const url = event.target.dataset.url;
        const fileName = event.target.dataset.filename;
       // console.log('FileName '+fileName);
        getSASUrl({ url: url, type: 'LFU' }).then(res => {
            this.showSpinner = false;
            fetch(res)
                .then(response => response.blob())
                .then(blob => {
                    const blobUrl = window.URL.createObjectURL(blob);
                    const downloadLink = document.createElement('a');
                    downloadLink.href = blobUrl;
                    downloadLink.setAttribute('download', fileName);
                    document.body.appendChild(downloadLink);
                    downloadLink.click();
                    document.body.removeChild(downloadLink);
                    window.URL.revokeObjectURL(blobUrl); // Clean up the URL object
                })
                .catch(error => console.error('Error downloading file:', error));

        }).catch(err => {
            //console.log('err', err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'error',
                    message: 'Unalbe to download this file',
                    variant: 'error'
                })
            );
        });
    }
    downloadAllCustomerDoc() {
        let fileList = this.externalFilesList;

        if (fileList && fileList.length > 0) {
            fileList.forEach(file => {
                this.downloadFile(file.ExternalUrl, file.FileName);
            });
        }
    }
    downloadFile(url, fileName) {
        fetch(url)
            .then(response => response.blob())
            .then(blob => {
                const blobUrl = window.URL.createObjectURL(blob);
                const downloadLink = document.createElement('a');
                downloadLink.href = blobUrl;
                downloadLink.setAttribute('download', fileName);
                document.body.appendChild(downloadLink);
                downloadLink.click();
                document.body.removeChild(downloadLink);
                window.URL.revokeObjectURL(blobUrl); // Clean up the URL object
            })
            .catch(error => console.error('Error downloading file:', error));
    }

    // TLA Document
    handleUpdateTLADoc() {
        this.isLoading = true;
        this.caseObj.Id = this.currentRequestId;
        this.caseObj.CaseNumber = this.csNumber;
        this.caseObj.OwnerId = this.csOwner;
        if (this.fileData.length > 0) {
            updateDocumentUpload({ tlaAttachments: this.fileData.flat(), caseObj: this.caseObj, identifier: 'requestor' })
            .then(result => {
                this.getTLADocumentData();
                this.fileData = [];
                this.showOtherDoc = false;
                this.docName = '';
                this.customerDoc = [];
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('success', 'Documents are updated successfully', '', 3000);
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('error while saving on updation-->' + errorMessage);
            });
        } else {
            this.isLoading = false;
            this.template.querySelector('c-common-toast-msg-for-communities')
                .showToast('warning', 'Please upload a file', '', 2000);
        }
    }
    handleDeleteTLADoc(event) {
        const index = event.target.dataset.index;
        this.fileData[index] = [];
        this.customerDoc[index].fileName = '';
        this.template.querySelector('c-common-toast-msg-for-communities')
            .showToast('success', 'Document has been deleted successfully', '', 3000);
    }

    get noTLADocument() {
        return this.tlaDocumentList.length === 0 && this.externalFilesList.length === 0;
    }
    getTLADocumentData() {
        getDocuments({ sObjectName: 'Case__c', recordId: this.currentRequestId, recordType: 'Case_Document' })
            .then(data => {
                if (data && data.length > 0) {
                    this.tlaDocumentList = data;
                    this.contentVersionIds = data.map(doc => doc.contentVersion.Id);
                } else {
                    this.tlaDocumentList = [];
                    this.contentVersionIds = [];
                }
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('error fetching TLA Documents-->' + errorMessage);
            });
    }
    handleTLADocumentChange(event) {
        this.documentType = event.target.value;
        if (this.documentType == 'Others')
            this.showOtherDocName = true;
        else {
            this.showOtherDocName = false;
            this.otherDocumentName = '';
        }
    }
    handleTLADocumentUpload(event) {
        const documentId = event.target.dataset.id;
        const index = event.target.dataset.index;
        const filetype = event.target.dataset.filetype;
        const fileInput = event.currentTarget.files;

        if (fileInput.length > 0) {
            const file = fileInput[0];
            const fileName = fileInput[0].name;
            this.customerDoc[index].fileName = fileName;

            // File type and size validation
            const allowedTypes = ['image/png', 'application/pdf', 'image/jpeg'];
            const maxSize = 3 * 1024 * 1024; // 3 MB

           if (!allowedTypes.includes(file.type)) {
                this.template.querySelector('c-common-toast-msg-for-communities')
                    .showToast('warning', 'Only .pdf, .png, and .jpg file types are allowed.', '', 3000);
                return;
            }

            if (file.size > maxSize) {
                this.template.querySelector('c-common-toast-msg-for-communities')
                    .showToast('warning', 'The file size must be less than 3 MB.', '', 3000);
                return;
            }

            var reader = new FileReader();
            reader.onload = () => {
                var base64 = reader.result.split(',')[1];
                if (!this.fileData[index]) {
                    this.fileData[index] = [];
                }

                this.fileData[index].push({
                    'filename': fileName,
                    'base64': base64,
                    'recordId': documentId,
                    'fileType': filetype
                });
            };
            reader.readAsDataURL(file);
        }
    }

    //Wire Transfer
    handleBankTransferBtn(event) {
        this.paymentReqId = '';
        this.attName = '';
        this.showBankTransferPopup = true;
        this.paymentReqId = event.target.dataset.id;
    }
    handlePaymentChange(event) {
        const fieldName = event.target.name;
        if (fieldName === 'Payment_Date__c') {
            this.paymentDate = event.target.value;
        } else if (fieldName === 'Remittance_Name__c') {
            this.remittanceName = event.target.value;
        } else if (fieldName === 'Payment_Reference_No__c') {
            this.paymentReference = event.target.value;
        }
    }
    handleSubmitPayment() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isInputsCorrect) {
            this.disablebtn = true;
            this.isLoading = true;
            const { base64, filename } = this.fileData;
            submitWireTransferPayment({
                reqId: this.paymentReqId,
                paymentdate: this.paymentDate,
                name: this.remittanceName,
                ref: this.paymentReference,
                base64,
                filename
            })
                .then(() => {
                    this.showBankTransferPopup = false;
                    this.fileData = '';
                    this.attName = '';
                    this.paymentReqId = '';
                    this.getPaymentDetails();
                    this.isLoading = false;
                    this.disablebtn = false;
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('success', 'Details submitted successfully', '', 3000);
                })
                .catch(error => {
                    this.isLoading = false;
                    this.disablebtn = false;
                    const errorMessage = JSON.stringify(error);
                    if (errorMessage.includes("You do not have access to the Apex class")) {
                        this.template.querySelector('c-common-toast-msg-for-communities')
                            .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                    }
                    //console.log('error-->' + errorMessage);
                })
        }
    }
    handlePaymentUpload(event) {
        this.fileData = '';
        const file = event.target.files[0];

        const allowedTypes = ['image/png', 'application/pdf', 'image/jpeg'];
        const maxSize = 3 * 1024 * 1024;

        if (!allowedTypes.includes(file.type)) {
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('warning', 'Only .pdf, .png and .jpg file types are allowed.', '', 3000);
            return;
        }
        if (file.size > maxSize) {
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('warning', 'The file size must be less than 3 MB.', '', 3000);
            return;
        }

        this.attName = file.name;
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64
            }
        }
        reader.readAsDataURL(file);
    }

    // Download Receipt in My Financial
    handleRecieptDownload(event) {
        this.paymentReqId = event.target.dataset.id;

        getDocuments({ sObjectName: 'Payment_Request__c', recordId: this.paymentReqId, recordType: 'CustomerDocument', docType: 'Receipt' })
            .then((data) => {
                if (data && data.length > 0 && data[0].contentVersion && data[0].contentVersion.Id) {
                    this.downloadReceipt(data[0].contentVersion.Id);
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('success', 'Reciept downloaded successfully', '', 3000);
                } else {
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('warning', 'No receipt available for download', '', 3000);
                }
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('error-->' + errorMessage);
            })
    }
    downloadReceipt(contentVersionId) {
        const downloadUrl = window.location.href + '/sfc/servlet.shepherd/version/download/' + contentVersionId;
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.setAttribute('download', 'Receipt.pdf');
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }
    gettitlevlaues() {
        getPicklistValues({ objName: 'Contact', fldName: 'Salutation' })
            .then(data => {
                this.titlevlaues = Object.entries(data).map(([value, label]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }
    handleProfileClick(event) {
        this.hideAllForms();
        this.getCountryCodeValues();
        this.showProfileUpdate = true;
        this.profileReadMode = true;
        this.template.querySelector('[data-name="Home"]').classList.remove('active');
        this.template.querySelector('[data-name="Requests"]').classList.remove('active');
        this.template.querySelector('[data-name="Financials"]').classList.remove('active');
    }
    handleProfileEdit(event) {
        this.profileEditMode = true;
        this.profileReadMode = false;

    }
    handleProfileCancel(event) {
        this.profileEditMode = false;
        this.profileReadMode = true;
    }
    getCountryCodeValues() {
        getPicklistValues({ objName: 'Account', fldName: 'MobileCountryCode__c' })
            .then(data => {
                this.countryCodeOptions = Object.entries(data).map(([label, value]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }
    get ringCounters() {
        return (100 / 90) * this.refreshCounter;
    }
    get ringVariant() {
        if (this.refreshCounter < 3) {
            return 'expired'
        }
        if (this.refreshCounter < 10) {
            return 'warning'
        }
        return 'base';
    }
    handleProfileSave(event) {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isInputsCorrect) {
            if (this.profileInfo.Contact.MobilePhone__c != this.profileUpdateInfo.mobile) {
                this.sendOtp();
            } else {
                this.updateUserInfo();

            }
        }
    }

    sendOtp(event) {
        try {
            this.OTP = null;
            this.hasError = false;
            const profile = this.profileUpdateInfo;
            let conObj = new Object();
            conObj.sobjectType = 'Contact';
            conObj.Id = profile.contactid;
            conObj.MobilePhone = profile.countrycode + profile.mobile;
            this.isLoading = true;
            sendMobileOTP({ con: conObj })
                .then(res => {
                    this.isLoading = false;
                    let data = this.profileUpdateInfo;
                    this.otpSentMsg = 'OTP sent to ' + data.countrycode + data.mobile;
                    this.hideAllForms();
                    this.showProfileUpdate = true;
                    this.profileEditMode = false;
                    this.otpScreen = true;
                    this.showCounter = true;
                    const input = this.template.querySelector('[autocomplete=one-time-code');
                    if (input)
                        input.value = '';

                    this.mobileInterval = setInterval(function () {
                        if (this.refreshCounter == 1) {
                            this.counter = 1;
                            this.refreshCounter = 0;
                            this.showCounter = false;
                            clearInterval(this.mobileInterval);
                        }
                        this.refreshCounter = 60 - (this.counter++);
                    }.bind(this), 1000);

                })
                .catch(error => {
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('error', 'Unable to send OTP.', '', 3000);
                });

        } catch (e) {
            //console.log('sendOtp', e.message);
        }
    }
    verifyOtp(event) {
        this.hasError = false;
        this.isLoading = true;
        const input = this.template.querySelector('[autocomplete=one-time-code');
        if (input.value.length == 6) {
            verifyOtp({ otp: input.value }).then(res => {
                if (res == 'Success') {
                    this.hideAllForms();
                    this.showProfileUpdate = true;
                    this.profileReadMode = true;
                    this.updateUserInfo();

                } else {
                    this.isLoading = false;
                    this.hasError = true;
                    this.errorMessage = 'OTP does not match.';
                }

            }).catch(error => {
                this.isLoading = false;
                //console.log('error->', error);
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('error', 'Unable to verify OTP.', '', 3000);
            })
        } else {
            this.isLoading = false;
            this.hasError = true;
            this.errorMessage = 'Please Enter OTP';
        }

    }
    updateUserInfo() {
        this.isLoading = true;
        const profile = this.profileUpdateInfo;
        let conObj = new Object();
        conObj.sobjectType = 'Contact';
        conObj.Id = profile.contactid;
        conObj.LastName = profile.lastname;
        conObj.FirstName = profile.firstname;
        conObj.MobileCountryCode__c = profile.countrycode;
        conObj.MobilePhone__c = profile.mobile;
        conObj.MobilePhone = profile.countrycode + profile.mobile;

        updateContact({ con: conObj })
            .then(data => {
                this.getUserDetails();
                this.isLoading = false;
                this.profileEditMode = false;
                this.profileReadMode = true;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('success', 'Your infomration has been updated successfully', '', 3000);
            })
            .catch(err => {
                this.isLoading = false;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('error', 'Unable to update your information.', '', 3000);
                //console.log('error-->', err);
            });
    }

    handlePhoneOnBlur(event) {
        this.isLoading = true;
        let phoneNumber;
        const input = event.currentTarget;
        if (event.target.name == 'mobile') {
            let data = this.profileUpdateInfo;
            phoneNumber = data.countrycode + data.mobile;
        } else if (event.target.name == 'MobilePhone__c') {
            phoneNumber = this.conObj.MobileCountryCode__c + this.conObj.MobilePhone__c;
        }

        if (phoneNumber.length >= 9) {
            validateMobileNumber({ mobNo: phoneNumber }).then(res => {
                try {
                    if (res.IsValid == 'Yes') {
                        input.setCustomValidity('');
                        input.classList.add('checkinput');
                        this.isLoading = false;
                    } else {
                        input.classList.remove('checkinput');
                        input.setCustomValidity('Phone number is not valid');
                        this.isLoading = false;
                    }
                    input.reportValidity();
                } catch (e) {
                    //console.log(e.message)

                }
            }).catch(err => {
                //console.log('error-->', err);
                this.isLoading = false;
            });

        } else {
            this.isLoading = false;
        }

    }
    handleEmailOnBlur(event) {
        this.isLoading = true;
        const val = event.currentTarget.value;
        const input = event.currentTarget;
        if (val) {
            EmailValidation({ email: val }).then(res => {
                if (res == true) {
                    try {
                        input.setCustomValidity('');
                        input.classList.add('checkinput');
                        this.isLoading = false;
                    } catch (e) {
                        //console.log(e.message)
                    }
                } else {
                    input.classList.remove('checkinput');
                    input.setCustomValidity('Email is not valid');
                    this.isLoading = false;
                }
                input.reportValidity();
            }).catch(err => {
                //console.log('error-->', err);
                this.isLoading = false;
            });

        } else {
            this.isLoading = false;
        }

    }
    handlePrfChange(event) {
        let data = this.profileUpdateInfo;
        data[event.target.name] = event.target.value;
        if (event.target.name === 'countrycode') {
            data.mobile = '';
            const phoneInput = this.template.querySelector('[data-id="profPhone"]');
            if (phoneInput) {
                phoneInput.classList.remove('checkinput');
            }
        }
    }
    handleConChange(event) {
        this.conObj[event.target.name] = event.target.value;

        if (event.target.name === 'MobileCountryCode__c') {
            this.conObj.MobilePhone__c = '';

            const phoneInput = this.template.querySelector('[data-id="conPhone"]');
            if (phoneInput) {
                phoneInput.classList.remove('checkinput');
            }
        }
    }

    handleUserSaveClick(event) {
        this.conObj.sobjectType = 'Contact';
        this.conObj.AccountId = this.profileInfo.AccountId;
        this.conObj.MobilePhone = this.conObj.MobileCountryCode__c + this.conObj.MobilePhone__c;

        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isInputsCorrect) {
            this.isLoading = true;
            createContact({ con: this.conObj })
                .then(res => {
                    this.isLoading = false;
                    this.showUserPopup = false;
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('success', 'Your request has been created.', '', 3000);
                })
                .catch(error => {
                    this.isLoading = false;
                    //console.log('error', error)
                    let err = error.body.message;
                    this.conObj.MobilePhone__c = '';
                    if (err) {
                        this.template.querySelector('c-common-toast-msg-for-communities').
                            showToast('error', err, '', 3000);
                    } else {
                        this.template.querySelector('c-common-toast-msg-for-communities').
                            showToast('error', 'Unable to create request.', '', 3000);
                    }

                })
        }
    }
    /* Permit closure changes - start */
    
    permitClosureReq(event) {
        this.permitClosureDoc = [];
        this.fileUploadSet = new Set();
        this.showPermitClosure = true;
    }
    handlePermitClose(event) {
        this.showPermitClosure = false;

    }
    async handleDeletePermitDoc(event) {
        const recordIdVal = event.target.dataset.id;
        const index = event.target.dataset.index;
        this.showPermitDocSpin = true;
        await deleteRecord({ recordId: recordIdVal })
            .then(res => {
                this.showPermitDocSpin = false;
                this.permitClosureDoc.splice(index, 1);
                this.fileUploadSet.delete(recordIdVal);
            }).catch(error => {
                this.showPermitDocSpin = false;
                console.log(error);
            });

    }
    handlePermitDocChange(event) {
        this.documentName = event.target.value;
    }
    handlePermitDocAdd(event) {
        if (this.documentName) {
            this.showPermitDocSpin = true;

            updateOtherDocument({ caseId: this.currentRequestId, otherDoc: this.documentName, docType: 'Others' })
                .then(res => {
                    let data = JSON.parse(JSON.stringify(res));
                    this.permitClosureDoc.push(data);
                    this.showPermitDocSpin = false;
                    this.documentName = null;
                }).catch(error => {
                    this.showPermitDocSpin = false;
                    console.log(error);
                });
        } else {
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('warning', 'Please enter document type', '', 3000);
        }
    }
    async handlePermitClosUpload(event) {
        this.showPermitDocSpin = true;
        try {
            // const fileInput = event.currentTarget.files;
            // const index = event.currentTarget.dataset.index;
            //this.fileUploadSet.add(event.currentTarget.dataset.id);
            // const inputParams = {
            //     dataId: event.currentTarget.dataset.id,
            //     userId: this.blobUserId,
            //     groupId: event.currentTarget.dataset.id,
            //     folderName: this.blobFolderName,
            //     subFolderName: this.accNumber + '/' + this.csNumber,
            //     source: this.blobSource,
            //     file: event.currentTarget.files[0]
            // };
            // console.log('inputparams ->',JSON.stringify(inputParams));
            const index = event.currentTarget.dataset.index;
            const fileObj = event.currentTarget.files[0];
            this.fileUploadSet.add(event.currentTarget.dataset.id);

            // --- MIME TYPE FIX FOR CAD FILES ---
            let mimeType = fileObj.type;  // may be empty for CAD files
            const fileName = fileObj.name;
            const ext = fileName.split('.').pop().toLowerCase();
            console.log('mimeType type --> ',mimeType);
            if (!mimeType || mimeType === "") {
                const cadMimeMap = {
                    dwg: "image/vnd.dwg",
                    dxf: "image/vnd.dxf",
                    stp: "application/step",
                    step: "application/step",
                    igs: "model/iges",
                    iges: "model/iges",
                    sldprt: "application/sldworks",
                    sldasm: "application/sldasm"
                };

                mimeType = cadMimeMap[ext] || "application/octet-stream"; // fallback
            }
            // Overwrite File type 
            const correctedFile = new File([fileObj], fileObj.name, { type: mimeType });
            const inputParams = {
                dataId: event.currentTarget.dataset.id,
                userId: event.currentTarget.dataset.userId,
                groupId: event.currentTarget.dataset.groupId,
                folderName: event.currentTarget.dataset.folderName,
                subFolderName: this.accNumber + '/' + this.csNumber,
                source: event.currentTarget.dataset.source,
                file: correctedFile,     // send updated object with detected MIME
            };
            console.log('correctedFile : ', correctedFile);
            console.log('inputparams ->',JSON.stringify(inputParams));
            let res = await window.callBlob(inputParams);
            if (res == 'Success') {
                this.showPermitDocSpin = false;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('success', 'Document has been uploaded successfully', '', 3000);
            }
            else {
                this.showPermitDocSpin = false;

                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('warning', 'Unable to upload the document, please try again', '', 3000);
            }
        } catch (e) {
            console.log('-error--' + e.message);
            this.isLoadingFile = false;
            this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('error', e.message, '', 3000);
        }

    }
    handlePermitClsSubmit(event) {
        if (this.permitClosureDoc.length === this.fileUploadSet.size && this.permitClosureDoc.length > 0) {
            this.showPermitDocSpin = true;
            createPermitClosureReq({ caseId: this.currentRequestId })
                .then(res => {
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('success', 'Your request has been submitted successfully.', '', 3000);
                    this.showPermitClosure = false;
                    this.showPermitDocSpin = false;
                    this.showPermitClsBtn = false;
                }).catch(error => {
                    console.log('error-->', error);
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('error', 'Unable to process your request.', '', 3000);
                });
        } else {
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('warning', 'Please upload required documents.', '', 3000);
        }

    }

    showHelpLinks = false;
    userManualLinks = [
        { label: "Portal User Registration", url: "https://asset.aldar.com/salesforce/videos/1.%20Aldar%20User%20Registration.mp4" },
        { label: "NOC Request Creation", url: "https://asset.aldar.com/salesforce/videos/3.3%20Customer-NOC%20Request%20Creation.mp4" },
        { label: "PTW Request Creation", url: "https://asset.aldar.com/salesforce/videos/3.1%20Customer%20-%20PTW%20Request%20Creation.mp4" },
        { label: "NOC/PTW - Additional Information Submission", url: "https://asset.aldar.com/salesforce/videos/5.2%20Customer%20Re-submission.mp4" },
        { label: "Temporary License Agreement - Request Creation", url: "https://asset.aldar.com/salesforce/videos/1.%20TLA%20-%20Customer%20Request%20Creation.mp4" },
        { label: "Temporary License Agreement - Additional Information Submission", url: "https://asset.aldar.com/salesforce/videos/2.%20TLA%20-%20Customer%20Request%20Re-submission.mp4" },
        { label: "Payment by Online", url: "https://asset.aldar.com/salesforce/videos/9.1%20Customer%20Payment%20by%20Online.mp4" },
        { label: "Payment by Wire Transfer", url: "https://asset.aldar.com/salesforce/videos/9.2%20Customer%20Payment%20by%20Wire%20Transfer.mp4" }
    ];

    handleHelpPopup(event) {
        this.showHelpLinks = true;
    }
    handleHelpPopupClose(event) {
        this.showHelpLinks = false;
    }



    //isLoading =false;
    handleDlpUpdateBtnClick(){
        console.log('dlpStatus',this.dlpStatus);
        if(this.dlpStatus =='Work In Progress' || this.dlpStatus =='Resolved')
        {
            //Start by Daksh Sharma for Appointment Status Changes
            if (this.dlpStatus === 'Resolved' && (!this.dlpAppointmentStatus || this.dlpAppointmentStatus.trim() === '')) {
                this.template.querySelector('c-common-toast-msg-for-communities')
                    .showToast('error', 'Appointment Status cannot be empty when status is Resolved', '', 3000);
                return; 
            }
            //End
        this.isLoading =true;
        const inputBox = this.template.querySelector(`[data-label="Case Comment"]`);
        console.log('Comment'+inputBox.value);
        console.log('dlpStatus'+this.dlpStatus);
        console.log('dlpcurrentRequestId'+this.dlpcurrentRequestId);
        console.log('AppointmentDate'+this.dlpAppointmentDate);
        console.log('PostComment->'+this.dlpPostComment);
            updateDlpCase({CaseId:this.dlpcurrentRequestId,Status :this.dlpStatus, Comment : inputBox.value ,AppointmentDate : this.dlpAppointmentDate ,PostComment : this.dlpPostComment,
                            AppointmentStatus: this.dlpAppointmentStatus, CaseCategory: this.dlpCaseCategoryValue, SubCategory: this.dlpCaseSubCategoryValue}).then(() => {
            console.log('then');
            this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('Success', 'Case updated successfully', '', 3000);
            //Govt portal Chnages
            const childComp = this.template.querySelector('c-case-comments-display');
            if(childComp) {
                childComp.refreshComments();
            }
            this.dlpPostComment = '';
            console.log('dlpPostComment-->',this.dlpPostComment);
                        this.isLoading =false;
            if(this.dlpStatus =='Resolved'){
                this.handleBtnClick({ currentTarget: { dataset: { name: 'Cases' } } });
            } 
        })
        .catch(error => {
            console.log('Catch');
            this.template.querySelector('c-common-toast-msg-for-communities')
            .showToast('error', error.body.message,'', 3000);
            this.isLoading =false;
           // this.showToast('Error', error.body.message, 'error');
        });
    }
    else
    {
        console.log('Else');
        this.template.querySelector('c-common-toast-msg-for-communities')
            .showToast('error', 'You can only update "Work In Progress" or "Resolved" Status','', 3000);
    }

    }






     // Replace with your Flow API name
   IsCaseAssigned ='Assigned';
   currentUser;
   showAcceptButton=true;
    handleCaseAccepted() {
        // Pass parameters to the Flow
        
        this.isLoading =true;
        updateAssignTo({CaseId:this.dlpcurrentRequestId, assignedUserId: ''}).then(() => {
            console.log('then');
            this.isLoading =false;            
            this.showAcceptButton=false;
            this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('Success', 'Case Accepted successfully', '', 3000);
                        this.isLoading =false;
                        this.IsCaseAssigned ='Assigned';
                        console.log('this.IsCaseAssigned'+this.IsCaseAssigned);
        })
        .catch(error => {
            console.log('Catch-1'+error.body.message);
            this.IsCaseAssigned ='Assigned1';
            this.template.querySelector('c-common-toast-msg-for-communities')
            .showToast('error', error.body.message,'', 3000);
            this.isLoading =false;
           // this.showToast('Error', error.body.message, 'error');
        });

       
        if(this.IsCaseAssigned =='Assigned')
        {
        console.log('IsCaseAssigned'+this.IsCaseAssigned);
        this.currentUser=USER_ID;
        console.log('this.currentUser'+this.currentUser);
        getUserName({UserId:this.currentUser})
        .then(data => {
            console.log('Data'+data);
            this.dlpCaseAssignedTo = data.hasOwnProperty('Name') ? data.Name :null;
             console.log('this.dlpCaseAssignedTo'+this.dlpCaseAssignedTo);
        }).catch(error => {
           console.log('Error'+error); 
        })
     }
      
    }

    caseRetriveTypeValue;
    dlpfilterReq(event) {
        
        this.selectedStatus = event.currentTarget.dataset.status;       
        this.dlpSortByValue = '';
        console.log('this.selectedStatus'+this.selectedStatus);
        this.clearPaginationData();
        if(this.selectedStatus == 'New Case')
        {
            this.template.querySelector('[data-id="DlpNewCase"]').classList.add('active-pill');
            this.template.querySelector('[data-id="AllAcceptedCases"]').classList.remove('active-pill');
            this.template.querySelector('[data-id="MyAcceptedCases"]').classList.remove('active-pill');
            this.template.querySelector('[data-id="dlpAllCases"]').classList.remove('active-pill');
            this.template.querySelector('[data-id="dlpEmergencyCase"]').classList.remove('active-pill');
            this.caseRetriveTypeValue = 'NewCase';
        }
        else if(this.selectedStatus == 'All Accepted Cases')
        {
            this.template.querySelector('[data-id="DlpNewCase"]').classList.remove('active-pill');
            this.template.querySelector('[data-id="AllAcceptedCases"]').classList.add('active-pill');
            this.template.querySelector('[data-id="MyAcceptedCases"]').classList.remove('active-pill');
            this.template.querySelector('[data-id="dlpAllCases"]').classList.remove('active-pill');
            this.template.querySelector('[data-id="dlpEmergencyCase"]').classList.remove('active-pill');
            this.caseRetriveTypeValue = 'AllAcceptedCase';
        }
        else if(this.selectedStatus == 'My Accepted Cases')
            {
                this.template.querySelector('[data-id="DlpNewCase"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="AllAcceptedCases"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="MyAcceptedCases"]').classList.add('active-pill');
                this.template.querySelector('[data-id="dlpAllCases"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="dlpEmergencyCase"]').classList.remove('active-pill');
                this.caseRetriveTypeValue = 'Mycases';
            }
        else if(this.selectedStatus == 'dlp All Cases')
            {
                this.template.querySelector('[data-id="DlpNewCase"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="AllAcceptedCases"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="MyAcceptedCases"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="dlpAllCases"]').classList.add('active-pill');
                this.template.querySelector('[data-id="dlpEmergencyCase"]').classList.remove('active-pill');
                this.caseRetriveTypeValue = 'dlpAllCase';
            }              
        else if(this.selectedStatus == 'dlp Emergency Case')
            {
                this.template.querySelector('[data-id="DlpNewCase"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="AllAcceptedCases"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="MyAcceptedCases"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="dlpAllCases"]').classList.remove('active-pill');
                this.template.querySelector('[data-id="dlpEmergencyCase"]').classList.add('active-pill');
                this.caseRetriveTypeValue = 'dlpEmergencyCase';
            }    
        
        this.getDlpCasesInfo();  

      
    }
 
    //Added by rajat jain for Seach feature
    handleKeyDown(event) {
        if (event.key === 'Enter') {
            const inputValue = event.target.value;
            this.handleDlpSearchBtnClick(inputValue);
        }
    }
   
    SearchValueDLPCase ='NaN'
     handleDlpSearchBtnClick(searchValue)
    {
        this.clearPaginationData();
        const inputElement = this.template.querySelector('[data-id="dlpSearchValue"]');
        //this.SearchValueDLPCase = inputElement.value;
        this.SearchValueDLPCase = searchValue;
        this.caseRetriveTypeValue = 'FilterCase';
        //console.log('Input Value:', inputValue);
        this.selectedStatus = 'filterCase';       
        
        //this.SearchValueDLPCase = this.inputValue;
        console.log('SearchValueDLPCase'+ this.SearchValueDLPCase);
        this.template.querySelector('[data-id="DlpNewCase"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="AllAcceptedCases"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="MyAcceptedCases"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="dlpAllCases"]').classList.remove('active-pill');
        this.template.querySelector('[data-id="dlpEmergencyCase"]').classList.remove('active-pill');
        
        this.getDlpCasesInfo(); 
        
    }
    //End by rajat jain for Seach feature
   
   
    //Start by Daksh Sharma for Sort By feature
    get dlpSortOptions() {
        return [
            { label: '--None--', value: '' },
            { label: 'Case Ascending', value: 'CaseNumber/ASC' },
            { label: 'Case Descending', value: 'CaseNumber/DESC' },
            { label: 'Status Ascending', value: 'Status/ASC' },
            { label: 'Status Descending', value: 'Status/DESC' },
            { label: 'Category Ascending', value: 'CaseCategory__c/ASC' },
            { label: 'Category Descending', value: 'CaseCategory__c/DESC' },
            { label: 'Sub-Category Ascending', value: 'SubCategory__c/ASC' },
            { label: 'Sub-Category Descending', value: 'SubCategory__c/DESC' },
            { label: 'Unit Ascending', value: 'Unit_Name__c/ASC' },
            { label: 'Unit Descending', value: 'Unit_Name__c/DESC' },
            { label: 'CreatedDate Ascending', value: 'CreatedDate/ASC' },
            { label: 'CreatedDate Descending', value: 'CreatedDate/DESC' },
            { label: 'LastModifiedDate Ascending', value: 'LastModifiedDate/ASC' },
            { label: 'LastModifiedDate Descending', value: 'LastModifiedDate/DESC' }
        ];
    }

    handleDlpSortChange(event) {
        this.dlpSortByValue = event.detail.value;
        this.getDlpCasesInfo();
    }

    dlpHandleOpenModel() {
        this.dlpshowModel = true;
    }

    dlpHandleCloseModel() {
        this.dlpshowModel = false;
    }
    //End by Daksh Sharma for Sort By feature
    //Added by Protivity for Retail Contractor added
    navigateToSuperApp(event) {
        console.log('navigateToSuperApp')
        window.open('/business/', "_self");
    }

    navigateToRegistrationPage(event) {
       window.open('/business/SelfRegister', "_self");

    }
    //end
   
    @track dlpShowTransferModal = false;      
    @track dlpTransferOptions = [];           
    dlpSelectedTransferUserId = null;         

    handleOpenTransferModal(event) {
        this.dlpShowTransferModal = true;
        this.dlpSelectedTransferUserId = null;
        this.dlpTransferOptions = [];
        this.dlpIsTransferLoading = true;
        console.log('CaseId-->',this.dlpcurrentRequestId);
        getQueueMembersByOwner({caseId: this.dlpcurrentRequestId})
            .then(data => {
                this.dlpTransferOptions = data.map(user => {
                    return {
                        label: user.Name,
                        value: user.Id
                    };
                });

            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    closeTransferModal() {
        this.dlpShowTransferModal = false;
        this.dlpSelectedTransferUserId = null;
        this.dlpTransferOptions = [];
    }

    handleTransferSelect(event) {
        this.dlpSelectedTransferUserId = event.detail.value;
    }

    confirmTransfer() {
        if (!this.dlpSelectedTransferUserId) {
            this.template.querySelector('c-common-toast-msg-for-communities')
                .showToast('error', 'Please select a user to transfer.', '', 3000);
            return;
        }

        this.isLoading = true;
        updateAssignTo({ CaseId: this.dlpcurrentRequestId, assignedUserId: this.dlpSelectedTransferUserId })
        .then(() => {
            this.template.querySelector('c-common-toast-msg-for-communities')
                .showToast('Success', 'Case transferred successfully', '', 3000);
            this.dlpShowTransferModal = false;
            this.isLoading = false;

            getDLpCaseInfo({ caseId: this.dlpcurrentRequestId })
            .then(data => {
                this.dlpCaseAssignedTo = data.hasOwnProperty('Assigned_To__c') ? data.Assigned_To__r.Name : null;
                this.showAcceptButton = (this.dlpCaseAssignedTo == null);
            });
        })
        .catch(error => {
            console.log('transfer error', error);
            const msg = error?.body?.message || error?.message || JSON.stringify(error);
            this.template.querySelector('c-common-toast-msg-for-communities')
                .showToast('error', 'Transfer failed: ' + msg, '', 5000);
            this.dlpIsTransferLoading = false;
        });
    }
    handleBackClick() {
        this.ShowDlpDetails = false;
        this.showDLPCases = true;

        let pillId = this.dlpLastActivePill ? this.dlpLastActivePill : "DlpNewCase";

        this.dlpfilterReq({
            currentTarget: { dataset: { id: pillId } }
        });

        setTimeout(() => {
            this.template.querySelectorAll(".pills a").forEach(el => {
                el.classList.remove("active-pill");
            });
            const activeEl = this.template.querySelector(`[data-id="${pillId}"]`);
            if (activeEl) {
                activeEl.classList.add("active-pill");
            }
        }, 0);
    }

    handleDlpCategoryChange(event) {
        this.dlpCaseCategoryValue = event.detail.value;
        console.log('dlpCaseCategoryValue--1--',this.dlpCaseCategoryValue);
        this.dlpCaseSubCategoryValue = null;
        this.filterDlpSubCategories(this.dlpCaseCategoryValue);
    }

    handleDlpSubCategoryChange(event) {
        this.dlpCaseSubCategoryValue = event.detail.value;
        console.log('dlpCaseSubCategoryValue--1--',this.dlpCaseSubCategoryValue);
    }

    filterDlpSubCategories(selectedCategory) {
        const controllerKey = this.controllerValues[selectedCategory];
        console.log('ߔ�ontroller Key for selected category:', controllerKey);

        if (controllerKey === undefined) {
            this.dlpSubCategoryOptions = [{ label: '--None--', value: null }];
            return;
        }

        const filtered = this.allDlpSubCategoryMap
            .filter(item => item.validFor.includes(controllerKey))
            .map(item => ({
                label: item.label,
                value: item.value
            }));

        this.dlpSubCategoryOptions = [
            { label: '--None--', value: null },
            ...filtered
        ];

        console.log('✅ Filtered Subcategories:', this.dlpSubCategoryOptions);
    }
     //End by Daksh Sharma for Sort By feature
}