import { LightningElement, track, wire } from 'lwc';
import getAllCases from '@salesforce/apex/DM_PmcPortalHandler.getAllCases';
import getAllRequests from '@salesforce/apex/DM_PmcPortalHandler.getAllRequests';
import fetchDMCaseCount from '@salesforce/apex/DM_PmcPortalHandler.fetchDMCaseCount';
import getDataToExport from '@salesforce/apex/DM_PmcPortalHandler.getDataToExport';
import updateCase from '@salesforce/apex/DM_PmcPortalCtrl.updateCase';
import getPMCPortalUsers from '@salesforce/apex/DM_PmcPortalCtrl.getPMCPortalUsers';
import getPaymentInfo from '@salesforce/apex/DM_PmcPortalCtrl.getPaymentRequests';
import getDmApprovalUsers from '@salesforce/apex/DM_PmcPortalCtrl.getDMApproverUsers';
import getCaseMilestones from '@salesforce/apex/DM_PmcPortalCtrl.getCaseMilestones';
import updateAldarDocument from '@salesforce/apex/DM_PmcPortalCtrl.updateAldarDocument';
import customerDocuments from '@salesforce/apex/DM_RequestorPageCtrl.showCustomerDocuments';
import getCaseInfo from '@salesforce/apex/DM_RequestorPageCtrl.getCaseInfo';
import getDocuments from '@salesforce/apex/DM_RequestorPageCtrl.getDocuments';
import updateDocumentUpload from '@salesforce/apex/DM_RequestorPageCtrl.updateDocumentUpload';
import getUserInfo from '@salesforce/apex/DM_UtilityController.getUserInfo';
import getPicklistValues from '@salesforce/apex/DM_UtilityController.getPicklistValues';
import getSASUrl from '@salesforce/apex/CalloutToBlobstorage.getSASUrl';
import validateMobileNumber from '@salesforce/apex/DM_PortalRegistrationCtrl.validateMobileNumber';
import sendMobileOTP from '@salesforce/apex/DM_UtilityController.sendMobileOTP';
import verifyOtp from '@salesforce/apex/DM_UtilityController.verifyOtp';
import updateContact from '@salesforce/apex/DM_UtilityController.updateContact';
import { deleteRecord } from 'lightning/uiRecordApi';
import recallApproval from '@salesforce/apex/DM_PmcPortalCtrl.recallApproval'; 
import updateDocument from '@salesforce/apex/DM_PmcPortalCtrl.updateDocument';

/* import  basePath from "@salesforce/community/basePath"; 
Uncommnet once live */
import { loadScript } from 'lightning/platformResourceLoader';
import apexchartJs from '@salesforce/resourceUrl/ApexCharts';
//import documentJs from '@salesforce/resourceUrl/documentJs';
import DM_PMCTeamPortalProfile from '@salesforce/label/c.DM_PMCTeamPortalProfile';
import DM_PMCPortalProfile from '@salesforce/label/c.DM_PMCPortalProfile';
import DM_PMC_Status from '@salesforce/label/c.DM_PMC_Status';
import FILE_SAVER from '@salesforce/resourceUrl/FileSaver';

import HomeImages from "@salesforce/resourceUrl/HomeImages";
import { loadStyle } from 'lightning/platformResourceLoader';
import ExternalStyle from "@salesforce/resourceUrl/ExternalStyle";

import { getObjectInfo, getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import CASE_OBJECT from "@salesforce/schema/Case";

export default class DmPmcPortalPage extends LightningElement {
    @track ownerOptions = [];
    @track filterOwnerOptions = [];
    @track devNameOptions = [];
    @track nocValidityOptions = [
    { label: '1 Month',  value: '1 Month' },
    { label: '2 Months', value: '2 Months' },
    { label: '3 Months', value: '3 Months' },
    { label: '4 Months', value: '4 Months' },
    { label: '5 Months', value: '5 Months' },
    { label: '6 Months', value: '6 Months' }
];
    allMyCases;
    @track approverList = [];
    @track filteredCases;
    @track assingedCases;
    showMyCases = true;
    isLoading = false;
    noRecords = false;
    @track userInfo;
    @track user;
    showPTWForm = false;
    showNOCForm = false;
    showOtherForm = false;
    isDisabled = true;
    isAssigned = true;
    showOtherUtilityName = false;
    @track currentRequestInfo;
    @track utlilityPicklistValues = [];
    @track excavationPicklistValues = [];
    showSubmitBtn = false;
    @track caseObj = new Object();
    disableCustomerComments = true;
    disableRejectedComments = true;
    customerComments;
    showHazardImpact = false;
    showSafetyPrec = false;
    showRenewDetails = false;
    nofilterRecords = false;
    showOtherExcavationName = false;
    recordEditableStatuses = ['Work In Progress', 'Additional Information Required from Customer', 'Submitted with Ammendments', 'Additional Information Required from PMC'];
    @track newCaseCount;
    @track inprogressCaseCount;
    @track pendingCaseCount;
    @track rejectedCaseCount;
    @track closedCaseCount;
    @track allCaseCount;
    showRequests = false;
    showMyFinance = false;
    noPaymentRecords = false;
    caseIds;
    chartLoaded = false;
    chartData = [];
    noLatestRecords = true;
    assignedRecords = true;
    currentRequestId;
    @track aldarDocumentList = [];
    externalFilesList = [];
    externalUrls = [];
    @track files = [];
    @track showModal = false;
    @track modalUrl = '';
    showApprover = false;
    noDocuments = true;
    isSaved = false;
    @track milestones = false;
    @track statusMessage = '';
    interval;
    isMilestoneRunning = false;
    isEscalated = false;
    @track refreshChild = false;
    minDate;

    @track pageSize = 10;
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track recordEnd = 0;
    @track recordStart = 0;
    @track isPrev = true;
    @track isNext = true;
    @track startDate;
    @track endDate;
    filterCondition = '';
    selectedStatus;
    chartRendered = false;
    chartHasData = false;
    documentType;
    isSaveDoc = false;
    aldarDocList = [];
    chartSeries = [];
    chartLabels = [];
    docName;
    @track fileData = [];
    @track isPMCUser = false;
    showAldarDoc = false;
    aldarDocName;
    showAldarDocument = false;
    @track contentVersionIds = [];
    showProfileUpdate = false;
    profileReadMode = true;
    profileInfo;
    profileEditMode = false;
    @track profileUpdateInfo;
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
    incidentId = '';
    filterStatus = '';
    filterOwnerId = '';
    filterDevName='';
    accName = '';
    skipOldData = false;
    showMilestone = true;
    approverName = '';
    showRecallBtn = false;
    showOtherDoc = false;
    showDemaraction = false;
    @track dataToExport = [];
    showPtwDates = true;
    ptwDate = false;
    columnHeader = ['Request Number', 'Contact Name', 'Contact Email', 'Contact Number', 'Request Type', 'Status', 'Service Type', 'Sector and Plot','Project Name','Appointed Contractor','Scope of work','Purpose of work','Start Date','End Date','Duration of work','Validity', 'Assigned To', 'Created By', 'Created Date','Approved Date']

    // statusMap = { "New": ['New'], "In Progress": ['Work In Progress'], "Pending": ['Pending with Customer'], "Rejected": ['Rejected'], "Closed": ['Cancelled', 'Closed'] };

    Logo = HomeImages + '/Home-Images/DM_logo_login.png';
    Sidebar = HomeImages + '/Home-Images/DM_sidebar.png';
    Open = HomeImages + '/Home-Images/DM_open.svg';
    Pending = HomeImages + '/Home-Images/DM_pending.svg';
    Inprogress = HomeImages + '/Home-Images/DM_pending.svg';
    Approved = HomeImages + '/Home-Images/DM_approved.svg';
    Rejected = HomeImages + '/Home-Images/DM_reject.svg';
    Draft = HomeImages + '/Home-Images/DM_draft.svg';

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

    @track caseRecordTypeId;
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            const recordTypes = data.recordTypeInfos;
            for (let key in recordTypes) {
                if (recordTypes[key].name === 'District Management') {
                    this.caseRecordTypeId = key; // key is the recordTypeId
                    break;
                }
            }
        }
    }
    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: "$caseRecordTypeId" })
    picklistRes({ error, data }) {
        if (data) {
            this.devNameOptions = [...data.picklistFieldValues?.Development_Name__c.values];

            this.devNameOptions.unshift({ label: 'All', value: '' });
        } else if (error) {
            //console.log(error)
        }
    }

    async connectedCallback() {
        this.caseObj.sobjectType = 'Case';
        this.getAllRequestsInfo();
        this.getUserDetails();
        this.getUtilityValues();
        this.getExcavationValues();
        //this.getPMCPortalUsers();
        this.getDMApproverUsersInfo();
        this.getAllRequests();
        this.fetchCaseCounts();
        this.fetchSubStatusCaseCounts();
        this.fetchTypeCounts();
        this.getCurrentDate();

        const url = new URL(window.location.href);
        const tbValue = url.searchParams.get('tb');
        const idValue = url.searchParams.get('id');
        
        if (tbValue == 'req') {
            
            this.hideAllForms();
            if (idValue) {
                this.currentRequestId = idValue;
                this.loadViewCaseInfo(idValue);
                this.getAldarDocuments();
                this.getCaseMilestones();
            } else {
                this.showRequests = true;
                this.selectedStatus = 'All';
                await this.getAllRequestsInfo();
            }
        } else { //to show home tab
            this.hideAllForms();
            this.chartRendered = false;
            this.showMyCases = true;
            this.getAllRequests();
        }
    }
    get logoutUrl() {
        //Uncomment once live
        /*  const sitePrefix = basePath.replace(
              /\/s$/i, ""
          ); 
        
          return sitePrefix + "/secur/logout.jsp"; */
        return "/districtMngmt/secur/logout.jsp";


    }
    get statusValues() {
        return [
            { label: 'Work In Progress', value: 'Work In Progress' },
            { label: 'Additional Information Required from Customer', value: 'Additional Information Required from Customer' },
            { label: 'Documents Accepted by PMC', value: 'Documents Accepted by PMC' },
            { label: 'Rejected by PMC', value: 'Rejected by PMC' },

        ];
    }
    get statusValues1() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }
    get aldarDocTypeValues() {
        return [
            { label: 'DM Attachments', value: 'DM Attachments' },
            { label: 'DM Attachements for Stamp', value: 'DM Attachements for Stamp' },
            { label: 'DM Letter/Transmittal', value: 'DM Letter/Transmittal' },
            { label: 'DM PMC NOC', value: 'PMC NOC' },
            { label: 'DM PMC Review Comment Sheet', value: 'DM PMC Review Comment Sheet' },
            { label: 'Others', value: 'Others' },
        ];
    }
    async renderedCallback() {
        Promise.all([
            loadStyle(this, ExternalStyle)
        ])

        loadScript(this, apexchartJs + '/dist/apexcharts.js')
            .then(() => {
                //if (this.chartLoaded)
                if (!this.chartRendered) {
                    this.prepareDataForChart();
                    this.chartRendered = true;
                }
            })
            .catch((error) => {
                console.error('Failed JS: ' + error);
            });
        /*  loadScript(this, documentJs)
             .then(() => {
                 console.log('loades successfull')
             })
             .catch((error) => {
                 console.error('Failed JS: ' + error);
          }); */

        const url = new URL(window.location.href);
        const tbValue = url.searchParams.get('tb');
        if (tbValue == 'hm') {
            this.template.querySelector('[data-name="Home"]')?.classList.add('active');
            this.template.querySelector('[data-name="Requests"]')?.classList.remove('active');
        } else if (tbValue == 'req') {
            this.template.querySelector('[data-name="Requests"]')?.classList.add('active');
            this.template.querySelector('[data-name="Home"]')?.classList.remove('active');
        }

    }

    async prepareDataForChart() {
        /* [{
                x: 'NOC',
                y: 10
              }, {
                x: 'PTW',
                y: 18
              }, {
                x: 'Others',
                y: 13
              }]*/

        /* let options = {
             chart: {
                 type: 'bar'
             },
             series: [{
                 name: 'Count',
                 data: this.chartData,
             }],
             colors: ["#4653ab"],
 
         };*/
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

        // const div = this.template.querySelector('.chart');
        // const chart = new ApexCharts(div, options);
        if (this.chartHasData)
            this.template.querySelector('[data-id="showChart"]').classList.remove('hideChart');
        else
            this.template.querySelector('[data-id="showChart"]').classList.add('hideChart');

        var chart = new ApexCharts(this.template.querySelector('.chart'), options);
        chart.render();
        this.chartLoaded = false;

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

        this.minDate = `${year}-${month}-${day}`;
    }

    handleLogout() {
        window.open(this.logoutUrl, "_self");
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
    get demarcationValues() {
        return [
            { label: 'Setting out land demarcation Points', value: 'Setting out land demarcation Points' },
            { label: 'Re-demarcation', value: 'Re-demarcation' }

        ];
    }
    get yesNoValues() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }

        ];
    }

    async getUserDetails() {
        await getUserInfo()
            .then(data => {
                this.userInfo = data;
                if (this.userInfo && this.userInfo?.length > 0) {
                    this.user = this.userInfo[0];
                    this.profileInfo = this.userInfo[0];
                    let prf = new Object();
                    prf.firstname = data[0].FirstName;
                    prf.lastname = data[0].LastName;
                    prf.email = data[0].Email;
                    prf.countrycode = data[0].Contact.MobileCountryCode__c;
                    prf.mobile = data[0].Contact.MobilePhone__c;
                    prf.contactid = data[0].ContactId;
                    this.profileUpdateInfo = prf;
                    if (this.user.Profile && this.user.Profile.Name === DM_PMCTeamPortalProfile) {
                        this.isAssigned = true;

                    } else {
                        this.isAssigned = false;
                    }
                }
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });

        await this.getPMCPortalUsers();
    }
    handleBtnClick(event) {
        let btn = event.currentTarget.dataset.name;
        this.currentRequestId = '';
        this.startDate = '';
        this.endDate = '';
        this.files = [];
        this.clearPaginationData();
        event.preventDefault();
        if (btn == 'Home') {
            /* this.hideAllForms();
            this.chartRendered = false;
            this.showMyCases = true;
            this.getAllRequests();
            this.template.querySelector('[data-name="Home"]').classList.add('active');
            this.template.querySelector('[data-name="Requests"]').classList.remove('active'); */
            //this.template.querySelector('[data-name="Financials"]').classList.remove('active');
            const currentUrl = window.location.href.split('?')[0];
            const newUrl = `${currentUrl}?tb=hm`;
            window.location.href = newUrl;
            //history.pushState(null, '', newUrl);
        }
        if (btn == 'Requests') {
            /*  this.hideAllForms();
             this.showRequests = true;
             this.selectedStatus = 'All';
             this.getAllRequestsInfo();
             this.template.querySelector('[data-name="Requests"]').classList.add('active');
             this.template.querySelector('[data-name="Home"]').classList.remove('active'); */
            //this.template.querySelector('[data-name="Financials"]').classList.remove('active');
            const currentUrl = window.location.href.split('?')[0];
            const newUrl = `${currentUrl}?tb=req`;
            window.location.href = newUrl;
            //history.pushState(null, '', newUrl);

        }
        if (btn == 'Financials') {
            this.hideAllForms();
            this.showMyFinance = true;
            // this.template.querySelector('[data-name="Financials"]').classList.add('active');
            this.template.querySelector('[data-name="Home"]').classList.remove('active');
            this.template.querySelector('[data-name="Requests"]').classList.remove('active');
        }
    }
    clearPaginationData() {
        this.pageNumber = 1;
        this.totalRecords = 0;
        this.totalPages = 0;
        this.recordEnd = 0;
        this.recordStart = 0;
    }
    async getPMCPortalUsers() {
        await getPMCPortalUsers()
            .then(data => {
                if (data) {

                    this.filterOwnerOptions = data.map(user => ({
                        label: user.Name,
                        value: user.Id
                    }));

                    this.ownerOptions = data.map(user => ({
                        label: user.Name,
                        value: user.Id
                    }));

                    // console.log('userinfo--', this.userInfo);
                    if (this.userInfo && this.userInfo[0]) {
                        this.filterOwnerOptions.push({
                            label: this.userInfo[0].Name,
                            value: this.userInfo[0].Id
                        });

                        this.ownerOptions.push({
                            label: this.userInfo[0].Name,
                            value: this.userInfo[0].Id
                        });
                    }
                    this.filterOwnerOptions.unshift({ label: 'All', value: '' });

                    //console.log('filterOwnerOptions--', this.filterOwnerOptions);

                }
            })
            .catch(error => {
                //console.error('Error fetching PMC portal users:', error);
            });
    }

    getDMApproverUsersInfo() {
        getDmApprovalUsers()
            .then(data => {
                if (data) {
                    this.approverList = data.map(user => ({
                        label: user.Name,
                        value: user.Id
                    }));

                }
            })
            .catch(error => {
                //console.error('Error fetching PMC portal users:', error);
            });
    }

    hideAllForms() {
        this.showNOCForm = false;
        this.showPTWForm = false;
        this.showMyCases = false;
        this.showOtherForm = false;
        this.showMyFinance = false;
        this.showRequests = false;
        this.showProfileUpdate = false;
        this.profileReadMode = false;
        this.profileEditMode = false;
        this.otpScreen = false;
        this.showCounter = false;

    }
    async getAllRequestsInfo() {
        this.isLoading = true;
        this.filterCondition = '';

        if (this.skipOldData) {
            this.filterCondition += ` AND Incident_Id__c = null`;
        }
        if (this.incidentId && this.incidentId.trim() !== "") {
            this.filterCondition += ` AND (Stakeholder_Reference_No__c LIKE '%${this.incidentId}%' OR CaseNumber LIKE '%${this.incidentId}%')`;
        } else {
            this.filterCondition = this.filterCondition.replace(/ AND \(Stakeholder_Reference_No__c LIKE '%.*?%' OR CaseNumber LIKE '%.*?%'\)/, '');
        }
        if (this.filterStatus) {
            this.filterCondition += ` AND Sub_Status__c = '${this.filterStatus}'`;
        } else {
            this.filterCondition = this.filterCondition.replace(/ AND Sub_Status__c = '.*?'/, '');
        }

        if (this.filterDevName) {
            this.filterCondition += ` AND Development_Name__c = '${this.filterDevName}'`;
        } else {
            this.filterCondition = this.filterCondition.replace(/ AND Development_Name__c = '.*?'/, '');
        }

        if (this.filterOwnerId) {
            this.filterCondition += ` AND OwnerId = '${this.filterOwnerId}'`;
        } else {
            this.filterCondition = this.filterCondition.replace(/ AND OwnerId = '.*?'/, '');
        }
        if (this.accName && this.accName.trim() !== "") {
            this.filterCondition += ` AND (Account.Name LIKE '%${this.accName}%' OR Contact.Name LIKE '%${this.accName}%')`;
        } else {
            this.filterCondition = this.filterCondition.replace(/ AND \(Account\.Name LIKE '%.*?%' OR Contact\.Name LIKE '%.*?%'\)/, '');
        }
        if (this.selectedStatus) {
            let status = '';
            // if (this.selectedStatus === 'New' || this.selectedStatus === 'Work In Progress' || this.selectedStatus === 'Pending with Customer') {
            //     status = this.selectedStatus;
            //     this.filterCondition += ` AND Status LIKE '%${status}%'`;
            // }

            if (this.selectedStatus === 'New') {
                status = this.selectedStatus;
                this.filterCondition += ` AND Status LIKE '%${status}%'`;
            }
            if (this.selectedStatus === 'Work In Progress') {
                this.filterCondition += ` AND (Sub_Status__c LIKE '%Work In Progress%' OR Sub_Status__c LIKE '%Submitted with Ammendments%' OR Sub_Status__c LIKE '%Additional Information Required from PMC%')`;
            }
            if (this.selectedStatus === 'Pending with Customer') {
                this.filterCondition += ` AND (Sub_Status__c LIKE '%Additional Information Required from Customer%')`;
            }
            

            if (this.selectedStatus === 'Rejected') {
                this.filterCondition += ` AND (Status LIKE '%Cancelled%' OR Status LIKE '%Rejected%')`;
            }
            if (this.selectedStatus === 'Closed') {
                this.filterCondition += ` AND (Status LIKE '%Completed%')`;
            }
        }
        if (this.startDate && this.endDate) {
            const startDateObj = new Date(this.startDate);
            const endDateObj = new Date(this.endDate);

            if (!isNaN(startDateObj.getTime()) && !isNaN(endDateObj.getTime())) {
                endDateObj.setHours(23, 59, 59, 999);
                const startDateFormatted = startDateObj.toISOString();
                const endDateFormatted = endDateObj.toISOString();

                //this.filterCondition += ` AND CreatedDate > ${startDateFormatted} AND CreatedDate < ${endDateFormatted}`;
                this.filterCondition += ` AND CreatedDate >= ${startDateFormatted} AND CreatedDate <= ${endDateFormatted}`;
            } else {
                this.filterCondition = this.filterCondition.replace(/ AND CreatedDate >= .*? AND CreatedDate <= .*?/, '');
            }
        } else {
            this.filterCondition = this.filterCondition.replace(/ AND CreatedDate >= .*? AND CreatedDate <= .*?/, '');
        }
        //console.log('Filter Condition:-->', this.filterCondition);
        getAllCases({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            filterCondition: this.filterCondition
        })
            .then(result => {
                if (result) {
                    var data = JSON.parse(result);
                    data.cs.forEach(cas => {
                        cas.AssignName = cas.Assign_To__r ? cas.Assign_To__r.Name : cas.Owner.Name;
                        cas.recordLink = '/districtMngmt/?tb=req&id=' + cas.Id;
                    });
                    this.filteredCases = data.cs;
                    this.pageNumber = data.pageNumber;
                    this.totalRecords = data.totalRecords;
                    this.recordStart = data.recordStart;
                    this.recordEnd = data.recordEnd;
                    this.totalPages = Math.ceil(data.totalRecords / this.pageSize);
                    this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
                    this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);

                    if (this.filteredCases?.length > 0)
                        this.noRecords = false;
                    else
                        this.noRecords = true;
                    this.allMyCases = data.cs;
                    //this.filteredCases = data;
                    this.isLoading = false;
                }

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
    get statusOptions() {
        const stringArray = DM_PMC_Status.split(',');
        let objectArray = stringArray.map(item => ({
            label: item.trim(),
            value: item.trim()
        }));
        objectArray.unshift({ label: 'All', value: '' });
        return objectArray;
    }
    handleFilterChange(event) {
        if (event.target.name == 'Incident_Id__c') {
            this.incidentId = event.detail.value;
        }
        if (event.target.name == 'Status') {
            this.filterStatus = event.detail.value;
        }
        if (event.target.name == 'Assigned') {
            this.filterOwnerId = event.detail.value;
        }
        if (event.target.name == 'Account') {
            this.accName = event.detail.value;
        }
        if (event.target.name == 'skipOld') {
            this.skipOldData = event.target.checked;
        }
        if (event.target.name == 'Development_Name__c') {
            this.filterDevName = event.detail.value;
        }
    }

    handleAssignedToChange(event) {
        this.assignedTo = event.detail.value;
    }

    applyFilter() {
        this.getAllRequestsInfo();
    }
    resetFilter() {
        this.filterCondition = '';
        this.incidentId = null;
        this.endDate = null;
        this.startDate = null;
        this.filterStatus = '';
        this.filterOwnerId = '';
        this.accName = null;
        this.filterDevName='';
        this.skipOldData = false;
        this.getAllRequestsInfo();
    }


    getAllRequests() {
        getAllRequests()
            .then(data => {
                this.allCases = data;
                this.assingedCases = this.allCases.filter(Case =>
                    Case.Sub_Status__c === "Assigned" ||
                    Case.Sub_Status__c === "Additional Information Required from PMC" ||
                    Case.Sub_Status__c === "Submitted with Ammendments"
                );

                this.assingedCases.forEach(cas => {
                    cas.AssignName = cas.Assign_To__r ? cas.Assign_To__r.Name : cas.Owner.Name;
                    cas.recordLink = '/districtMngmt/?tb=req&id=' + cas.Id;
                });

                if (this.assingedCases?.length > 0)
                    this.assignedRecords = false;

                // Filter cases for the current week
                const currentDate = new Date();
                const firstDayOfWeek = new Date(currentDate);
                firstDayOfWeek.setDate(currentDate.getDate() - currentDate.getDay()); // Sunday
                const lastDayOfWeek = new Date(currentDate);
                lastDayOfWeek.setDate(currentDate.getDate() - currentDate.getDay() + 6); // Saturday

                this.currentWeekCases = this.allCases.filter(Case => {
                    const caseDate = new Date(Case.CreatedDate);
                    return caseDate >= firstDayOfWeek && caseDate <= lastDayOfWeek;
                }).slice(0, 10);

                this.currentWeekCases.forEach(cas => {
                    cas.AssignName = cas.Assign_To__r ? cas.Assign_To__r.Name : cas.Owner.Name;
                    cas.recordLink = '/districtMngmt/?tb=req&id=' + cas.Id;
                });
                if (this.currentWeekCases?.length > 0)
                    this.noLatestRecords = false;

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
    handleNext() {
        this.pageNumber = this.pageNumber + 1;
        this.getAllRequestsInfo();
    }

    handlePrev() {
        this.pageNumber = this.pageNumber - 1;
        this.getAllRequestsInfo();
    }
    /* handleStartDate(event) {
        this.startDate = event.target.value;
        this.getAllRequestsInfo();
    }
    handleEndDate(event) {
        this.endDate = event.target.value;
        this.getAllRequestsInfo();
    } */
    handleDateChange(event) {
        if (event.target.name == 'startDate') {
            this.startDate = event.target.value;
        }
        if (event.target.name == 'endDate') {
            this.endDate = event.target.value;
        }
        /* if (this.startDate && this.endDate) {
            this.getAllRequestsInfo();
        } */
    }
    fetchCaseCounts() {
        fetchDMCaseCount({ groupByFilter: 'Status' })
            .then(data => {
                if (data) {
                    //this.newCaseCount = data['New'] || 0;
                    //this.inprogressCaseCount = data['Work In Progress'] || 0;
                    //this.pendingCaseCount = data['Pending with Customer'] || 0;
                    this.rejectedCaseCount = (data['Rejected'] || 0) + (data['Cancelled'] || 0);
                    this.closedCaseCount = data['Completed'] || 0;
                    this.allCaseCount = Object.values(data).reduce((a, b) => a + b, 0);
                }
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });
    }
    fetchSubStatusCaseCounts() {
        fetchDMCaseCount({ groupByFilter: 'Sub_Status__c' })
            .then(data => {
                if (data) {
                    this.inprogressCaseCount = (data['Work In Progress'] || 0) + (data['Submitted with Ammendments'] || 0) + (data['Additional Information Required from PMC'] || 0);
                    this.pendingCaseCount = data['Additional Information Required from Customer'] || 0;
                }
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });
    }
    fetchTypeCounts() {
        fetchDMCaseCount({ groupByFilter: 'Type' })
            .then(data => {
                if (data) {
                    let counts = data;
                    if (Object.keys(data)?.length > 0)
                        this.chartHasData = true;
                    Object.entries(data).forEach(([label, count]) => {
                        if (label === "Temporary License Agreement") {
                            label = "TLA";
                        }
                        this.chartLabels.push(label);
                        this.chartSeries.push(count);
                    });
                    this.chartLoaded = true;
                    this.prepareDataForChart();
                }
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });
    }
    getAldarDocuments() {
        getDocuments({ sObjectName: 'Case__c', recordId: this.currentRequestId, recordType: 'CustomerDocument' })
            .then(data => {
                if (data && data?.length > 0) {
                    this.noDocuments = false;
                    this.aldarDocumentList = data;
                    this.files = data;
                    console.log('this.files',this.files);
                    this.contentVersionIds = data.map(doc => doc.contentVersion.Id);
                } else {
                    this.noDocuments = true;
                    this.files = [];
                    this.contentVersionIds = [];
                }
            })
            .catch(error => {
                console.log('Error fetching documents:', error);
            });
    }
    handleViewClick(event) {
        event.preventDefault();
        this.clearCheckedUtilityStatusForAll();
        this.clearCheckedExcavationForAll();
        this.showOtherUtilityName = false;
        this.showOtherExcavationName = false;
        this.showSafetyPrec = false;
        this.showHazardImpact = false;
        this.currentRequestId = event.currentTarget.dataset.id;
        this.aldarDocList = [];
        this.showAldarDoc = false;
        this.getAldarDocuments();
        this.showApprover = false;
        const currentUrl = window.location.href.split('?')[0];
        const newUrl = `${currentUrl}?tb=req&id=${this.currentRequestId}`;
        window.location.href = newUrl;

    }
    async loadViewCaseInfo(reqId) {
        await customerDocuments({ caseId: reqId })
            .then(data => {
                this.externalFilesList = [];
                this.externalUrls = [];
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
                    temp.CreatedDate = item.CreatedDate;
                    this.externalFilesList.push(temp);

                    this.externalUrls.push(item.External_URL__c);
                });
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });

        await getCaseInfo({ caseId: reqId })
            .then(data => {
                this.currentRequestInfo = null;
                this.currentRequestInfo = data;
                this.showRecallBtn = false;
                console.log('GetCaseInfo -> '+data);
                console.log('GetCaseInfo 2 -> ',data);
                //  ADD HERE: Show NOC_Validity__c field only for assigned PMC user by Neelesh
                const profileName = this.user?.Profile?.Name || '';
                const userId = this.user?.Id;
               // const ownerId = data.OwnerId;

                if (
                    (profileName === DM_PMCPortalProfile || profileName === DM_PMCTeamPortalProfile) 
                    ) {
                    this.isPMCUser = true;
                } else {
                    this.isPMCUser = false;
                }
                this.getCaseMilestones();
                //console.log('caseInfo-->',this.currentRequestInfo)
                if (data?.Product?.Name == 'Land Demarcation') {
                    this.showDemaraction = true;
                } else {
                    this.showDemaraction = false;
                }
                if (!data.Assigned_To__c) {
                    if (this.approverList?.length > 0) {
                        this.currentRequestInfo.Assigned_To__c = this.approverList[0].value;
                        //this.caseObj.Assigned_To__c = this.approverList[0].value;
                    }
                }
                if (data.Sub_Status__c == 'Approval In Progress') {
                    this.approverName = data.Assigned_To__r?.Name;
                    if (!this.isAssigned)
                        this.showRecallBtn = true;
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
                    excavationlist.forEach(exc => {
                        this.excavationPicklistValues.forEach(item => {
                            if (item.label == exc) {
                                item.isChecked = true;
                            }
                        });
                        if (exc == 'Others')
                            this.showOtherExcavationName = true;
                    });
                }

                if (this.recordEditableStatuses.includes(data.Sub_Status__c)) {
                    this.showSubmitBtn = true;
                    this.isDisabled = false;
                    if (this.user.Profile && this.user.Profile.Name === DM_PMCPortalProfile) {
                        this.isAssigned = false;
                    }else if(this.user.Profile && this.user.Profile.Name === DM_PMCTeamPortalProfile && this.currentRequestInfo.OwnerId === this.user.Id) {
                        this.isAssigned = false;
                    }

                } else {
                    this.showSubmitBtn = false;
                    this.isDisabled = true;
                    if (this.user.Profile && this.user.Profile.Name === DM_PMCPortalProfile) {
                        this.isAssigned = true;
                    }
                }
                if (data.Sub_Status__c == 'Submitted with Ammendments' && data.Additional_Info_Req_By__c == this.userInfo[0].Id) {
                    this.showSubmitBtn = true;
                    this.isDisabled = false;

                }

                if (data.Type == 'NOC') {
                    this.hideAllForms();
                    this.showNOCForm = true;
                    //this.showSubmitBtn = true;
                    //this.caseObj.NOC_Validity__c = data.NOC_Validity__c || '1 Month';
                    this.caseObj.NOC_Validity__c = data.NOC_Validity__c;
                }
                if (data.Type == 'Permit to Work') {
                    this.hideAllForms();
                    this.showPTWForm = true;
                    //this.showSubmitBtn = true;
                    console.log('inside ptw ',data.Sub_Status__c);
                    if (data.Sub_Status__c == 'Work In Progress') 
                        this.showPtwDates = true;
                        this.ptwDate = false;
                    if (data.Hazards_Identified_Environmental_Impact__c == 'Yes')
                        this.showHazardImpact = true;
                    if (data.Safety_Precautions_and_Controls_in_Place__c == 'Yes')
                        this.showSafetyPrec = true;
                    if (data.Request_Type__c == 'Renewal')
                        this.showRenewDetails = true;
                }
                if (data.Type == 'Others') {
                    this.hideAllForms();
                    this.showOtherForm = true;
                    //this.showSubmitBtn = true;
                }

            })
            .catch(error => {
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('handleViewClick:error -->' + errorMessage);
            });
    }
    getCaseMilestones() {
        if (this.currentRequestInfo.Status == 'Pending with Customer') {
            this.showMilestone = false;
        }
        getCaseMilestones({ caseId: this.currentRequestId })
            .then(data => {
                if (data) {
                    const isStopped = this.currentRequestInfo.IsStopped;
                    const filteredMilestones = data;
                    // Calculate time remaining milestone
                    this.milestones = filteredMilestones.map(milestone => ({
                        ...milestone,
                        TimeRemaining: this.calculateTimeRemaining(milestone.TargetDate),

                        ElapsedTime: this.calculateElapsedTime(milestone.TargetDate),
                        completionDate: this.calculateTargetTime(milestone.TargetDate)
                    }));

                    this.statusMessage = this.getStatusMessage(this.milestones);
                    if (!isStopped) {
                        this.startCountdown();
                    }
                } else {
                    console.error('No data returned from getCaseMilestones.');
                }
            })
            .catch(error => {
                console.error('Error fetching milestone data:', error);
            });
    }

    handleChange(event) {
        // if (event.target.name == 'Sub_Status__c' && event.target.value == 'Additional Information Required from Customer') {
        //     this.caseObj.Status = 'Pending with Customer';
        //     this.disableCustomerComments = false;
        //     this.disableRejectedComments = true;
        //     this.showPtwDates = false;
        // } else 
        // Prevent default form submission behavior
            event.preventDefault();
            event.stopPropagation();
    
        // YOU NEED TO UNCOMMENT AND FIX THESE LINES:
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        console.log('event.detail.value -> ',fieldValue);
        console.log('event.detail.Name -> ',fieldName);
        // Initialize caseObj if it doesn't exist
        if (!this.caseObj) {
            this.caseObj = { sobjectType: 'Case' };
        }

        // Always update the field value 
        this.caseObj[fieldName] = fieldValue;
        console.log('this.caseObj.Sub_Status__c -> ',this.caseObj.Sub_Status__c);
        // Perform validation for PMC Reference Number 
        if (fieldName === 'PMC_Reference_No__c' && this.caseObj.Sub_Status__c == 'Documents Accepted by PMC') {
            const inputCmp = event.target; // Use event.target instead of querySelector
            if (!fieldValue || fieldValue.trim() === '') {
                inputCmp.setCustomValidity('PMC Reference Number is required');
            } else {
                inputCmp.setCustomValidity('');
            }
            inputCmp.reportValidity(); // Shows validation error if any
        }
             
        if (event.target.name == 'Sub_Status__c' && event.target.value == 'Rejected by PMC') {
            this.caseObj.Status = 'Rejected';
            this.disableCustomerComments = true;
            this.showPtwDates = false;
        } else if(event.target.name == 'Sub_Status__c'){
            this.caseObj.Status = 'Work In Progress';
            this.disableRejectedComments = true;
            this.showPtwDates = true;
            this.ptwDate = false;
        }
        
        
        if (event.target.name === 'Sub_Status__c') {
            if (event.target.value === 'Documents Accepted by PMC') {
                this.template.querySelector('[data-id="approvedDate"]').value = new Date().toISOString();
                this.currentRequestInfo.PMC_Approved_Date__c = new Date().toISOString();
                this.caseObj.PMC_Approved_Date__c = new Date().toISOString();
                this.showApprover = true;
                this.showPtwDates = true;
                this.ptwDate = true;
            } else {
                this.template.querySelector('[data-id="approvedDate"]').value = '';
                this.currentRequestInfo.PMC_Approved_Date__c = '';
                this.caseObj.PMC_Approved_Date__c = '';
                this.showApprover = false;
            }
        }

        if (event.target.name == 'Assigned_To__c')
            this.showApprover = true;
        if (event.target.name == 'OwnerId') {
            this.caseObj.Assigned_To__c = event.target.value;
        } else if (event.target.name == 'Sub_Status__c' && event.target.value == 'Documents Accepted by PMC') {
            this.caseObj.Assigned_To__c = this.approverList[0].value;
        }

        this.caseObj[event.target.name] = event.target.value;
        
        if(this.caseObj.Sub_Status__c === 'Additional Information Required from Customer'){
            this.disableCustomerComments = false;
            this.caseObj.Status = 'Pending with Customer';
            this.disableRejectedComments = true;
            this.showPtwDates = false;
        }else if (this.caseObj.Sub_Status__c === 'Rejected by PMC'){
            this.disableRejectedComments = false;
            this.showPtwDates = false;
        }else {
             this.disableCustomerComments = true;
             this.disableRejectedComments = true;
        }
    }

    handleCommentChange(event) {
        this.customerComments = event.target.value;
        // if (event.target.name == 'customer_comments') {
        //     this.caseObj.Required_Information__c = event.target.value;
        // } else if (event.target.name == 'Rejected_Reason__c') {
        //     this.caseObj.Rejected_Reason__c = event.target.value;
        // }
        if (event.target.name === 'customer_comments') {
            this.caseObj.Required_Information__c =
                this.customerComments.length > 255
                    ? this.customerComments.slice(0, 252).trim() + '...'
                    : this.customerComments;
        }

        if (event.target.name === 'Rejected_Reason__c') {
            this.caseObj.Rejected_Reason__c =
                this.customerComments.length > 255
                    ? this.customerComments.slice(0, 252).trim() + '...'
                    : this.customerComments;
        }
        
    }
    handleSearch(event) {
        const searchKey = event.currentTarget.value.toLowerCase();
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
                if (this.filteredCases?.length > 0)
                    this.nofilterRecords = false;
                else
                    this.nofilterRecords = true;
            }
        } else {
            this.filteredCases = this.allMyCases;
        }
    }
    handleSave() {
        this.isSaved = true;
        this.caseObj.Id = this.currentRequestInfo.Id;
        this.caseObj.CreatedById = this.currentRequestInfo.CreatedById;
        this.caseObj.CaseNumber = this.currentRequestInfo.CaseNumber;

        // Validate ALL required fields including PMC Reference Number
        const isFormValid = this.validateForm();
        
        if (!isFormValid) {
            this.isLoading = false;
            this.isSaved = false;
            return;
        }
      
        this.isLoading = true;
        this.updateCasehandler();
    }

    // New validation method
    validateForm() {
        let isValid = true;
        
        // 1. Validate PMC Reference Number specifically
        const pmcInput = this.template.querySelector('[name="PMC_Reference_No__c"]');
        console.log('pmcInput -> ',pmcInput);
        if (pmcInput) {
            const pmcValue = pmcInput.value;
            if (!pmcValue || pmcValue.trim() === '') {
                pmcInput.setCustomValidity('PMC Reference Number is required');
                pmcInput.reportValidity();
                isValid = false;
            } else {
                pmcInput.setCustomValidity('');
            }
        }        
        // 2. Check if Sub_Status__c requires PMC Reference Number
        if ((this.caseObj.Sub_Status__c === 'Documents Accepted by PMC')|| (this.caseObj.Sub_Status__c === 'Rejected by PMC')){
            if (!this.caseObj.PMC_Reference_No__c || this.caseObj.PMC_Reference_No__c.trim() === '') {
                if (pmcInput) {
                    pmcInput.setCustomValidity('PMC Reference Number is required for this status');
                    pmcInput.reportValidity();
                }
                // Show toast message
                this.template.querySelector('c-common-toast-msg-for-communities')
                    .showToast('error', 'PMC Reference Number is required', '', 3000);
                isValid = false;
            }
        }
        
        // 3. Validate all other lightning inputs
        const allInputs = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')];
        const inputsValid = allInputs.reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
        
        return isValid && inputsValid;
    }

    updateCasehandler() {
        let isInputsCorrect = true;
        if(this.caseObj.Sub_Status__c === 'Documents Accepted by PMC' || this.caseObj.Required_Information__c != null || this.caseObj.Rejected_Reason__c != null){
         isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        }
        
        if (isInputsCorrect) {
            updateCase({ caseObj: this.caseObj, comment: this.customerComments })
                .then(data => {
                    const currentUrl = window.location.href.split('?')[0];
                    const newUrl = `${currentUrl}?tb=req&id=${this.currentRequestId}`;
                    window.location.href = newUrl;
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('success', 'Your request has been updated successfully', '', 3000);
                    //this.getAllRequestsInfo();
                    //this.getAllRequests();
                    //this.hideAllForms();
                    //this.showMyCases = true;
                    this.getCaseMilestones();
                    this.isSaved = false;
                    this.isLoading = false;
                    this.refreshChild = true;
                })
                .catch(error => {
                    const errorMessage = JSON.stringify(error);
                    if (errorMessage.includes("You do not have access to the Apex class")) {
                        this.template.querySelector('c-common-toast-msg-for-communities')
                            .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                    }
                    //console.log('error while saving on updation-->' + errorMessage);
                });
        } else {
            this.isLoading = false;
            this.isSaved = false
        }

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
    getPaymentDetails() {
        getPaymentInfo({
            caseId: this.caseIds
        })
            .then(data => {
                this.paymentInfoList = data;
                if (data?.length > 0)
                    this.noPaymentRecords = false;
                else
                    this.noPaymentRecords = true;
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }

    inactiveAllPills() {
        this.template.querySelector('[data-status="All"]').classList.remove('active-pill');
        this.template.querySelector('[data-status="Work In Progress"]').classList.remove('active-pill');
        this.template.querySelector('[data-status="Pending with Customer"]').classList.remove('active-pill');
        this.template.querySelector('[data-status="Rejected"]').classList.remove('active-pill');
        this.template.querySelector('[data-status="Closed"]').classList.remove('active-pill');
    }

    filterReq(event) {
        this.template.querySelector('[data-name="Requests"]').classList.add('active');
        this.template.querySelector('[data-name="Home"]').classList.remove('active');

        this.hideAllForms();
        this.clearPaginationData();
        this.showRequests = true;
        this.selectedStatus = event.currentTarget.dataset.status;

        this.getAllRequestsInfo().then(() => {
            this.inactiveAllPills();
            if (this.selectedStatus == 'All')
                this.template.querySelector('[data-status="All"]').classList.add('active-pill');
            if (this.selectedStatus == 'Work In Progress')
                this.template.querySelector('[data-status="Work In Progress"]').classList.add('active-pill');
            if (this.selectedStatus == 'Pending with Customer')
                this.template.querySelector('[data-status="Pending with Customer"]').classList.add('active-pill');
            if (this.selectedStatus == 'Rejected')
                this.template.querySelector('[data-status="Rejected"]').classList.add('active-pill');
            if (this.selectedStatus == 'Closed')
                this.template.querySelector('[data-status="Closed"]').classList.add('active-pill');
        });
    }

    filePreview(event) {
        const docId = event.target.dataset.id;
        const fileType = event.target.dataset.filetype.toLowerCase();
        //this.previewUrl = window.location.href + "sfsites/c/sfc/servlet.shepherd/version/renditionDownload?rendition=svgz&versionId=" + docId;

        const renditionMap = {
            'pdf': 'svgz',
            'jpg': 'ORIGINAL_Jpg',
            'jpeg': 'ORIGINAL_Jpg',
            'png': 'ORIGINAL_Jpg',
            // Add other file types if needed
        };
        const renditionType = renditionMap[fileType] || 'svgz';
        this.previewUrl = window.location.href.split('?')[0] + `sfsites/c/sfc/servlet.shepherd/version/renditionDownload?rendition=${renditionType}&versionId=` + docId;
        this.showModal = true;
    }
    closeModal() {
        this.showModal = false;
        this.showAldarDocument = false;
    }

    async deleteAldarDoc(event) {
        const docId = event.target.dataset.id;
        try {
            await deleteRecord(docId);
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('success', 'Documents has been deleted successfully', '', 3000);
            this.getAldarDocuments();
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }

    downloadAldarDocument(event) {
        const docId = event.target.dataset.id;
        const loc = window.location.href.split('?')[0];
        const url = loc + "sfc/servlet.shepherd/document/download/" + docId;
        const downloadLink = document.createElement('a');
        downloadLink.href = url;
        downloadLink.setAttribute('download', '');
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);
    }

    async downloadAllDocuments() {
        const fileList = this.contentVersionIds;
        try {
            await loadScript(this, FILE_SAVER);

            if (fileList?.length === 1) {
                // If there is only one file, download it directly
                const singleFileId = fileList[0];
                const response = await fetch(window.location.href.split('?')[0] + 'sfc/servlet.shepherd/version/download/' + singleFileId);
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
                const response = await fetch(window.location.href.split('?')[0] + 'sfc/servlet.shepherd/version/download/' + fileIds);
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                const blob = await response.blob();
                saveAs(blob, 'AldarDocuments.zip');
            }
        } catch (error) {
            console.error('Error downloading file:', error);
        }
    }

    get getStatusStyle() {
        return this.statusMessage === 'Escalated' ? 'color: red;' : ''; // If statusMessage is 'Escalated', set color to red
    }
    getStatusMessage(milestones) {
        const isInProgress = milestones.some(milestone =>
            !milestone.IsCompleted &&
            !milestone.IsViolated
        );

        const hasOverdueMilestone = milestones.some(milestone =>
            milestone.IsViolated
        );

        const allCompleted = milestones.every(milestone => milestone.IsCompleted);

        if (isInProgress) {
            this.isMilestoneRunning = true;
            this.isEscalated = false;
            return 'Milestone is running';
        } else if (hasOverdueMilestone) {
            this.isEscalated = true;
            this.isMilestoneRunning = false;
            return 'Escalated';
        } else if (allCompleted) {
            this.isEscalated = false;
            this.isMilestoneRunning = false;
            return 'Completed';

        } else {
            return 'Unknown status';
        }
    }


    startCountdown() {
        this.interval = setInterval(() => {
            this.updateTimeRemaining();
        }, 1000);
    }

    updateTimeRemaining() {
        this.milestones = this.milestones.map(milestone => ({
            ...milestone,
            TimeRemaining: this.calculateTimeRemaining(milestone.TargetDate),
            ElapsedTime: this.calculateElapsedTime(milestone.TargetDate)
        }));
    }

    calculateTargetTime(targetDate) {
        const targetDateTime = new Date(targetDate);

        // Get the completion time in local time with timezone
        const options = { timeZone: 'Asia/Dubai', hour12: true, hour: 'numeric', minute: 'numeric' };
        const timeWithTimezone = targetDateTime.toLocaleString('en-US', options).replace(',', '');
        const dateWithTimezone = targetDateTime.toLocaleDateString('en-US', { day: '2-digit', month: 'long', year: 'numeric' });
        const completionTimeWithTimezone = `${dateWithTimezone}, ${timeWithTimezone}`;

        return completionTimeWithTimezone;
    }


    calculateTimeRemaining(targetDate) {
        const targetTime = new Date(targetDate);
        const currentTime = new Date();
        const timeDiff = targetTime - currentTime;

        // Convert time difference to days, hours, minutes, and seconds
        const remainingDays = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
        const remainingHours = Math.floor((timeDiff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const remainingMinutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
        const remainingSeconds = Math.floor((timeDiff % (1000 * 60)) / 1000);

        let remainingText = '';

        if (timeDiff > 0) {
            remainingText = `${remainingDays} days ${remainingHours} hr ${remainingMinutes} min ${remainingSeconds} sec remaining`;
        }
        return remainingText;
    }

    calculateElapsedTime(targetDate) {
        const targetTime = new Date(targetDate);
        const currentTime = new Date();
        const timeDiff = currentTime - targetTime;

        // Convert time difference to days, hours, minutes, and seconds
        const remainingDays = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
        const remainingHours = Math.floor((timeDiff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const remainingMinutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
        const remainingSeconds = Math.floor((timeDiff % (1000 * 60)) / 1000);

        let remainingText = '';

        if (timeDiff > 0) {
            remainingText = `${remainingDays} days ${remainingHours} hr ${remainingMinutes} min ${remainingSeconds} sec overdue`;
        }
        return remainingText;
    }

    disconnectedCallback() {
        if (this.interval) {
            clearInterval(this.interval);
        }
    }

    previewExtFiles(event) {
        this.showSpinner = true;
        const url = event.target.dataset.url;
        getSASUrl({ url: url, type: 'LFU' }).then(res => {
            this.showSpinner = false;
            /* this.previewUrl = res;
            this.showModal = true; */
            window.open(res, '_blank')
        }).catch(err => {
            //console.log('err', err);
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('error', 'Unable to preview this file', '', 3000);
        });
    }
    downloadExtFile(event) {
        this.showSpinner = true;
        const url = event.target.dataset.url;
        const fileName = event.target.dataset.filename;
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
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('error', 'Unalbe to download this file', '', 3000);

        }); 
    }


    async downloadAllCustomerDoc() {
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
    } catch(error) {
        console.error('Error downloading file:', error);
    }

    handleAldarDocument() {
        this.showAldarDocument = true;
        this.isSaveDoc = false;
    }
    handleAldarDocType(event) {
        this.documentType = event.target.value;
        if(this.documentType === 'Others'){
            this.showOtherDoc = true;
        }
    }
    handleAldarDocName(event) {
        this.aldarDocName = event.target.value;
        //this.documentType = 'Others';
    }
    handleSaveAldarDocument() {
        this.isSaveDoc = true;
        this.isLoading = true;
        updateAldarDocument({ caseId: this.currentRequestId, aldarDocName: this.aldarDocName, docType: this.documentType })
            .then(data => {
                this.aldarDocList = [...this.aldarDocList, data];
                this.showAldarDoc = true;
                this.showOtherDoc = false;
                this.aldarDocName = '';
                this.isLoading = false;
                this.closeModal();
            })
            .catch(error => {
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("You do not have access to the Apex class")) {
                    this.template.querySelector('c-common-toast-msg-for-communities')
                        .showToast('error', 'Unable to proceed further, please refresh and try again', '', 3000);
                }
                //console.log('error-->' + errorMessage);
            })
    }
    handleAldarDocumentUpload(event) {
        const documentId = event.target.dataset.id;
        const index = event.target.dataset.index;
        const filetype = event.target.dataset.filetype;
        const fileInput = event.currentTarget.files;

        if (fileInput.length > 0) {
            const file = fileInput[0];
            //const fileName = file.name;
            const fileName = fileInput[0].name;
            this.aldarDocList[index].fileName = fileName;

            //const allowedTypes = ['image/png', 'application/pdf', 'image/jpeg'];
            const allowedMimeTypes = [
                'image/png',
                'application/pdf',
                'image/jpeg',
                'application/vnd.ms-excel', // .xls
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
                'message/rfc822', // .eml
                'application/vnd.ms-outlook', // .msg (may vary or be missing)
                'application/octet-stream' // Fallback for unknowns like .msg
            ];

            // Allowed file extensions (fallback)
            const allowedExtensions = ['.png', '.pdf', '.jpg', '.jpeg', '.xls', '.xlsx', '.eml', '.msg'];
            const maxSize = 3 * 1024 * 1024; // 3 MB

            // Extract extension
            const fileExtension = fileName.slice(fileName.lastIndexOf('.')).toLowerCase();

            // Validate MIME type AND fallback to extension check
            const isValidType = allowedMimeTypes.includes(file.type) || allowedExtensions.includes(fileExtension);

            if (!isValidType) {
                this.template.querySelector('c-common-toast-msg-for-communities')
                    .showToast('warning', 'Only PDF, PNG, JPG, Excel, EML, and MSG file types are allowed.', '', 3000);
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
                //console.log('File Data:', JSON.stringify(this.fileData));               
            };
            reader.readAsDataURL(file);
        }
    }
    handleUpdateAldarDoc() {
        this.isLoading = true;
        this.caseObj.Id = this.currentRequestId;
        if (this.fileData.length > 0) {
            updateDocumentUpload({ tlaAttachments: this.fileData.flat(), caseObj: this.caseObj, identifier: 'pmc' })
                .then(result => {
                    this.getAldarDocuments();
                    this.fileData = [];
                    this.showAldarDoc = false;
                    this.aldarDocList = [];
                    this.docName = '';
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
                    //console.log('error while saving on Updation-->' + errorMessage);
                });
        } else {
            this.isLoading = false;
            this.template.querySelector('c-common-toast-msg-for-communities')
                .showToast('warning', 'Please upload a file', '', 2000);
        }
    }
    handleDeleteAldarDoc(event) {
        const index = event.target.dataset.index;
        this.fileData[index] = [];
        this.aldarDocList[index].fileName = '';
        this.template.querySelector('c-common-toast-msg-for-communities')
            .showToast('success', 'Document has been deleted successfully', '', 3000);
    }
    handleExportData() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if (isInputsCorrect) {
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
            getDataToExport({ filterCondition: this.filterCondition })
                .then(data => {
                    this.dataToExport = data;

                    // Prepare a html table
                    let doc = '<table>';
                    // Add styles for the table
                    doc += '<style>';
                    doc += 'table, th, td {';
                    doc += '    border: 1px solid black;';
                    doc += '    border-collapse: collapse;';
                    doc += '}';
                    doc += '</style>';
                    // Add all the Table Headers
                    doc += '<tr>';
                    this.columnHeader.forEach(element => {
                        doc += '<th>' + element + '</th>'
                    });
                    doc += '</tr>';
                    // Add the data rows
                    this.dataToExport.forEach(cs => {
                        doc += '<tr>';
                        doc += '<td style="mso-number-format:\\@">' + cs.CaseNumber + '</td>';
                        doc += '<td>' + cs.CreatedBy.Name + '</td>';
                        doc += '<td>' + cs.ContactEmail + '</td>';
                        doc += '<td style="mso-number-format:\\@">' + cs.ContactMobile + '</td>';
                        doc += '<td>' + cs.Type + '</td>';
                        doc += '<td>' + cs.Sub_Status__c + '</td>';
                        doc += '<td>' + cs.Product.Name + '</td>';

                        doc += '<td>' + (cs.Sector_and_Plot_No__c || 'N/A') + '</td>';
                        doc += '<td>' + cs.Project_Name__c + '</td>';
                        doc += '<td>' + (cs.Appointed_Contractor__c || 'N/A') + '</td>';
                        doc += '<td>' + (cs.Description || 'N/A') + '</td>';
                        doc += '<td>' + (cs.Purpose_of_Work__c || 'N/A') + '</td>';
                        doc += '<td>' + (cs.Start_Date__c || 'N/A') + '</td>';
                        doc += '<td>' + (cs.End_Date__c || 'N/A') + '</td>';
                        doc += '<td>' + (cs.TLA_Duration__c || 'N/A') + '</td>';

                        doc += '<td>' + cs.Validity_Status__c + '</td>';
                        doc += '<td>' + cs.Owner.Name + '</td>';
                        doc += '<td>' + cs.CreatedBy.Name + '</td>';
                        let createdDate = new Date(cs.CreatedDate);
                        let formattedDate = createdDate.toLocaleDateString('en-US', { day: '2-digit', month: 'long', year: 'numeric' });
                        doc += '<td>' + formattedDate + '</td>';
                        let ClosedDate = new Date(cs.ClosedDate);
                        let formattedClosedDate = cs.ClosedDate ? new Date(cs.ClosedDate).toLocaleDateString('en-US', { day: '2-digit', month: 'long', year: 'numeric' }) : 'N/A';
                        doc += '<td>' + formattedClosedDate + '</td>';
                        doc += '</tr>';
                    });
                    doc += '</table>';
                    var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
                    let downloadElement = document.createElement('a');
                    downloadElement.href = element;
                    downloadElement.target = '_self';
                    downloadElement.download = 'Request Data.xls';
                    document.body.appendChild(downloadElement);
                    downloadElement.click();
                })
        }
    }
    handleProfileClick(event) {
        this.hideAllForms();
        this.getCountryCodeValues();
        this.showProfileUpdate = true;
        this.profileReadMode = true;
        this.template.querySelector('[data-name="Home"]').classList.remove('active');
        this.template.querySelector('[data-name="Requests"]').classList.remove('active');

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
    handleProfileEdit(event) {
        this.profileEditMode = true;
        this.profileReadMode = false;

    }
    handleProfileCancel(event) {
        this.profileEditMode = false;
        this.profileReadMode = true;
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
    handlePhoneOnBlur(event) {
        this.isLoading = true;
        let phoneNumber;
        const input = event.currentTarget;
        if (event.target.name == 'mobile') {
            let data = this.profileUpdateInfo;
            phoneNumber = data.countrycode + data.mobile;
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
                //console.log('error->', JSON.stringify(error));
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('error', 'Unable to verify OTP.', '', 3000);
            })
        } else {
            this.isLoading = false;
            this.hasError = true;
            this.errorMessage = 'Please Enter OTP';
        }

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
                this.hideAllForms();
                this.getUserDetails();
                this.isLoading = false;
                this.showProfileUpdate = true;
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
    handleRefresh() {
        const currentUrl = window.location.href.split('?')[0];
        const newUrl = `${currentUrl}?tb=req&id=${this.currentRequestId}`;
        window.location.href = newUrl;
    }
    handleRecall() {
        this.isLoading = true;
        recallApproval({ recordId: this.currentRequestId }).then(data => {
            this.isLoading = false;
            const currentUrl = window.location.href.split('?')[0];
            const newUrl = `${currentUrl}?tb=req&id=${this.currentRequestId}`;
            window.location.href = newUrl;
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('success', 'Your request is recalled successfully.', '', 3000);

        }).catch(error => {
            this.isLoading = false;
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('error', 'Unable to recall approval request.', '', 3000);
        });
    }
    updateDocumentHanlder(event) {
        console.log('inside checkbox');
        let docObj = new Object();
        docObj.SObjectType = 'Document__c';
        docObj.Id = event.target.dataset.id;
        docObj.AvailableForExternalUsers__c = event.target.checked;
        console.log('docObj+++'+docObj);
        updateDocument({ doc: docObj })
            .then(data => {
               this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('success', 'Document has been updated successfully.', '', 3000);
            })
            .catch(error => {
                //console.log('Error -', JSON.stringify(error));
            });
    }
}