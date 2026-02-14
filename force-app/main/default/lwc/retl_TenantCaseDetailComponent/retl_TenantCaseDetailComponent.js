import { LightningElement, api, track, wire } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages";
import saveCaseComment from '@salesforce/apex/RETL_TenantRequestController.saveCaseComment';
import createFileRecord from '@salesforce/apex/RETL_ServiceRequestWizardController.uploadDocuments';
import getCaseCommentHistory from '@salesforce/apex/RETL_TenantRequestController.getCaseCommentHistory';
import getCaseDocuments from '@salesforce/apex/RETL_TenantRequestController.getCaseDocuments';
import getCaseDetails from '@salesforce/apex/RETL_TenantRequestController.getCaseDetails';
import getFileSizeLimit from '@salesforce/apex/RETL_ServiceRequestWizardController.getTenantPortalSetting';
import deleteUploadedFile from '@salesforce/apex/RETL_SRDocumentHandler.deleteUploadedFile';
import getCurrentUserDetails from '@salesforce/apex/RETL_ServiceRequestWizardController.getCurrentUserDetails';
import getSessionId from '@salesforce/apex/RETL_SRDocumentHandler.getSessionId';
import getFileUploadEndpoint from '@salesforce/apex/RETL_ServiceRequestWizardController.getFileUploadEndpoint';

export default class Retl_TenantCaseDetailComponent extends LightningElement {
    successimage = Images + '/Request/success.png';
    elementsimage = Images + '/Services/elements.png';
    calimage = Images + '/Services/cal.png';
    icon1image = Images + '/Request/icon1.png';
    icon2image = Images + '/Request/icon2.png';
    icon3image = Images + '/Request/icon3.png';
    icon4image = Images + '/Request/icon4.png';
    icon5image = Images + '/Request/icon5.png';
    icon6image = Images + '/Request/icon6.png';
    icon7image = Images + '/Request/icon7.png';
    icon8image = Images + '/Request/icon8.png';
    icon9image = Images + '/Request/icon9.png';
    icon11image = Images + '/Request/icon11.png';
    icon12image = Images + '/Request/icon12.png';
    icon13image = Images + '/Request/icon13.png';
    icon14image = Images + '/Request/icon14.png';
    icon15image = Images + '/Request/icon15.png';
    icon16image = Images + '/Request/icon16.png';
    icon17image = Images + '/Request/icon17.png';
    icon18image = Images + '/Request/icon18.png';
    icon19image = Images + '/Request/icon19.png';
    icon21image = `${Images}/Request/icon21.png`

    @api caseId; // caseId to fetch case details
    @api accessToken;
    @api requestSubmittingBy;
    @api contactId;
    isLoading = false;
    search = true;
    noComment = true;
    noCommentMessage;
    @track files = [];
    @track attachments = [];
    @track issuedDocument;
    @track uploadProgress = 0;
    @track uploading = false;
    showIssuedDocument = false;
    @api selectedRecord = {};
    @track normalSections = [];
    @track serviceInfoSections = [];
    @track contractorSections = [];
    @track accordionItems = [];
    isAllowComment = true

    @track caseDetails = {};
    showCaseSubject = false;
    showCaseDescription = false;
    showAdditionalInfo = false;
    fileSizeLimit;
    @api showDocuments;
    @api showCommunicationHistory;
    @api showOtherInformation;
    userData;
    showRejectionReason = false;
    connectedCallback() {
        if (!this.caseId && this.selectedRecord && this.selectedRecord.caseId) {
            this.caseId = this.selectedRecord.caseId;
        }
        this.showDocuments = (this.showDocuments === "false") ? false : true;
        this.showCommunicationHistory = (this.showCommunicationHistory === "false") ? false : true;
        this.showOtherInformation = (this.showOtherInformation === "false") ? false : true;
        if (this.caseId) {
            // this.fetchCaseDetails();
            this.fetchCaseDetails(this.showDocuments, this.showCommunicationHistory, this.showOtherInformation);
        }
        // this.getCommunicationHistoryData();
        // this.getCaseAttachments();

        this.loadUserDetails();


    }

    async loadUserDetails() {
        try {
            const data = await getCurrentUserDetails({ contactId: this.contactId });
            this.userData = data;
            if (this.userData.Profile.Name === 'Retail Tenant Partner Login') {
                this.networkName = 'Tenant Portal';
            }
            else if (this.userData.Profile.UserLicense.Name === 'Partner Community Login') {
                this.networkName = 'Contractor Business Portal';
            }

        }
        catch (error) {
            console.error('Error loading user details:', error);

        }
    }

    @wire(getFileSizeLimit)
    wiredLimit({ error, data }) {
        if (data) {
            this.fileSizeLimit = data;
            console.log('File size limit:', this.fileSizeLimit);
        } else if (error) {
            console.error('Error fetching file size limit:', error);
        }
    }

    fetchCaseDetails(includeDocuments, includeComments, includeAccordions) {
        this.isLoading = true;
        getCaseDetails({
            caseId: this.caseId,
            includeDocuments: includeDocuments,
            includeComments: includeComments,
            includeAccordions: includeAccordions
        })
            .then(result => {
                if (result['case']) {
                    this.caseDetails = result['case'];
                    // if (this.caseDetails.Status === 'Resolved_Closed' || this.caseDetails.Status === 'Pending with Customer' || this.caseDetails.Status === 'Cancelled' || this.caseDetails.Status === 'Rejected') {
                    //     this.isAllowComment = false;
                    // }
                    if (this.caseDetails.Status === 'Pending with Customer') {
                        this.isAllowComment = true;
                    }
                    else {
                        this.isAllowComment = false;
                    }
                    if( this.caseDetails.Status === 'Cancelled' && this.caseDetails.RETL_SR_Cancellation_Rejection_Reason__c){
                        this.showRejectionReason = true;
                        this.rejectionReason = this.caseDetails.RETL_SR_Cancellation_Rejection_Reason__c;
                    }
                    else{
                        this.showRejectionReason = false;
                    }
                    try {
                        const c = this.caseDetails;
                        if (c.RETL_SR_Category__c === 'Lease Amendment') {
                            this.showCommunicationHistory = false;
                        }
                        const utcDate = new Date(c.CreatedDate);
                        const typeOfRequest = c.RETL_SR_Type_Of_Request__c;
                        this.selectedRecord = {
                            id: c.Id,
                            caseNumber: c.CaseNumber,
                            status: c.Status === 'Assigned' ? 'In Progress' : c.Status === 'New' ? 'Submitted' : c.Status === 'Resolved_Closed' ? 'Resolved' : c.Status === 'Cancelled'? 'Rejected' : c.Status,
                            category: c.RETL_SR_Category__c ? c.RETL_SR_Category__c : '',
                            subCategory: c.RETL_SR_Sub_Category__c ? c.RETL_SR_Sub_Category__c : '',
                            serviceType: c.RETL_SR_Service_Type__c ? c.RETL_SR_Service_Type__c : '',
                            typeOfRequest: typeOfRequest,
                            caseComments: c.CaseComments__c ? c.CaseComments__c : '',
                            //unitNo: (c.RETL_SR_Additional_Info__r) ? c.RETL_SR_Additional_Info__r.RETL_Unit_No__c : '',
                            unitNo: c.RETL_Store_Name__c ? c.RETL_Store_Name__c : '',
                            subject: c.Subject ? c.Subject : '',
                            description: c.Description ? c.Description : '',
                            createdDate: (utcDate ? utcDate.toLocaleString() : ''),
                            iconsrc: `${c.Status === 'New' ? this.icon9image : c.Status === 'In Progress' ? this.icon19image : c.Status === 'Resolved_Closed' ? this.icon16image : c.Status === 'Rejected' ? icon17image : this.icon9image}`,
                            statusClass: `submitted-pill ${c.Status === 'In Progress' ? 'status-in-progress' : c.Status === 'new' ? 'status-submitted' : c.Status === 'Rejected' ? 'status-rejected' : c.Status === 'Resolved_Closed' ? 'status-resolved' : c.Status === 'Pending with Customer' ? 'status-pending-with-customer' : c.Status === 'Cancelled' ? 'status-cancelled' : ''}`
                        };

                        this.showCaseSubject = this.selectedRecord.category == 'General Request' && this.selectedRecord.subject || this.selectedRecord.category == 'Lease Amendment' && this.selectedRecord.subject ? true : false;
                        this.showCaseDescription = this.selectedRecord.category == 'General Request' && this.selectedRecord.description || this.selectedRecord.category == 'Lease Amendment' && this.selectedRecord.description ? true : false;
                        this.showAdditionalInfo = this.selectedRecord.category != 'General Request' && this.selectedRecord.caseComments ? true : false;

                    } catch (error) {
                        console.error('Error mapping case details:', error.message);
                    }
                }

                if (result['comments']) {
                    this.communicationHistory = result['comments'];
                    this.prepareCommunicationHistory();
                }

                if (result['documents']) {
                    const documents = result['documents'];
                    this.prepareDocumentAttachments(documents);
                }

                if (result['accordions']) {
                    const accordions = result['accordions'];
                    this.prepareOtherInformation(accordions);
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching case details:', error.message);
                this.isLoading = false;
            });
    }

    prepareCommunicationHistory() {
        if (this.communicationHistory && this.communicationHistory.length > 0) {
            this.noComment = false;
            // Add icon dynamically and other properties
            this.communicationHistory = this.communicationHistory.map(f => {
                f.createdByPos = f.createdByDirection === 'right' ? 'right-aligner' : ''; // Default icon
                f.commentColor = f.createdByDirection === 'right' ? 'comments-background-user' : 'comments-background-Aldar';
                return f;
            });
        } else {
            this.noCommentMessage = 'Nothing to display. We will notify you once there are updates in your request';
        }
        // Force UI refresh
        // this.communicationHistory = JSON.parse(JSON.stringify(this.communicationHistory));
    }

    getCommunicationHistoryData() {
        this.isLoading = true;
        getCaseCommentHistory({ caseId: this.caseId })
            .then(result => {
                this.communicationHistory = result;
                this.prepareCommunicationHistory();

                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching communication history:', JSON.stringify(error));
                this.isLoading = false;
            });
    }

    prepareDocumentAttachments(documents) {
        this.attachments = [];
        this.issuedDocument = null;
        this.showIssuedDocument = false;
        if (documents['Issued Document'] && documents['Issued Document'].length > 0 && this.caseDetails.Status === 'Resolved_Closed') {
            this.issuedDocument = documents['Issued Document'][0];
            this.showIssuedDocument = true;
        }
        try {
            let attachmentList = [];
            Object.keys(documents).forEach(function (docType, index) {
                if (docType != 'Issued Document') {
                    const files = documents[docType];
                    attachmentList = (files && files.length > 0) ? [...attachmentList, ...files] : [...attachmentList];
                }
            });
            this.attachments = attachmentList;
        } catch (error) {
            console.error('Error mapping case documents:', error.message);
        }
    }

    getCaseAttachments() {
        this.isLoading = true;
        getCaseDocuments({ caseId: this.caseId, category: this.selectedRecord.category })
            .then(result => {
                if (result['Attachments'] && result['Attachments'].length > 0) {
                    this.attachments = result['Attachments'];
                }
                if (result['Issued Document'] && result['Issued Document'].length > 0 && this.selectedRecord.status === 'Resolved_Closed') {
                    this.issuedDocument = result['Issued Document'][0];
                    this.showIssuedDocument = true;
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching case documents:', JSON.stringify(error));
                this.isLoading = false;
            });
    }


    prepareOtherInformation(accordionsList) {
        if (accordionsList && accordionsList.length > 0) {
            console.log('Has accordions');
            try {
                accordionsList.forEach(accordObj => {
                    let accordName = accordObj.title;
                    if (accordName === 'Service Information') {
                        this.serviceInfoSections = accordObj.sections;
                    }
                    else if (accordName === 'Contractor Details') {
                        this.contractorSections = accordObj.sections;
                    }
                });
                this.accordionItems = accordionsList.map(item => ({
                    id: item.title.replace(/\s+/g, ''),
                    title: item.title,
                    headerText: item.title,
                    iconSrc: item.title === 'Contractor Details' || item.title === 'Organizer Details' ? this.icon21image : this.icon12image,
                    sections: item.sections,
                    isActive: false,
                    headerClass: 'accordion-header',
                    chevronClass: 'chevron-icon',
                    contentClass: 'accordion-content'
                }));
            } catch (error) {
                console.error('Error mapping accordions:', error.message);
            }


        }
    }





    decorateField(f) {
        // Add file decoration
        const hasFiles = Array.isArray(f.files) && f.files.length > 0;
        const showLine = f.index !== 0 ? true : false;
        const files = hasFiles ? f.files.map(file => ({
            fileName: file.fileName,
            fileLink: file.fileLink,
            documentType: file.documentType
        })) : [];

        return {
            ...f,
            hasFiles,
            files,
            showLine
        };
    }


    @api sections = [{ name: 'Service Information', label: 'Service Information' }, { name: 'Contractor Details', label: 'Contractor Details' }]; // Expects an array of {name: '...', label: '...'}

    isWorkPermit = false;

    handleHeaderClick(event) {
        const clickedItemId = event.currentTarget.dataset.id;

        this.accordionItems = this.accordionItems.map(item => {
            const isActive = item.id === clickedItemId ? !item.isActive : false;
            return {
                ...item,
                isActive,
                headerClass: `accordion-header ${isActive ? 'active' : ''}`,
                chevronClass: `chevron-icon ${isActive ? 'active' : ''}`,
                contentClass: `accordion-content ${isActive ? 'active' : ''}`
            };
        });
        this.contractorSections = this.contractorSections.map(sec => {
            const isActive = sec.id === clickedItemId ? !sec.isActive : false;
            return {
                ...sec,
                isActive,
                headerClass: `accordion-header ${isActive ? 'active' : ''}`,
                chevronClass: `chevron-icon ${isActive ? 'active' : ''}`,
                contentClass: `accordion-content ${isActive ? 'active' : ''}`
            };
        });
    }

    recordId; // Case Id passed from parent or page
    @track commentText = '';
    @track files = [];
    @track fileContents = [];

    handleCommentChange(event) {
        this.commentText = event.target.value;
    }
    errorMsg = '';
    handleFileSelect(event) {
        const file = event.target.files[0];
        const fileSizeLimit = 4 * 1024 * 1024; // 4 MB in bytes

        const allowedTypes = ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'];
        Array.from(event.target.files).forEach(file => {
            const fileName = file.name.toLowerCase();
            const fileExt = fileName.split('.').pop();
            if (!allowedTypes.includes(fileExt)) {
                this.errorMsg = `Invalid file type: ${fileExt}. Allowed types are ${allowedTypes.join(', ')}`;
                return;
            }
            if (file.size > 4 * 1024 * 1024) {
                console.warn(`File too large: 1 ${file.name}`);
                this.errorMsg = `${file.name} exceeds 4 MB size limit`;
                return;
            }
        })
        if (file) {
            if (file.size > fileSizeLimit) {
                //this.showToast('Error', 'File size exceeds 4 MB.', 'error');
                return;
            }
            this.errorMsg = '';
            this.files = [...this.files, file];

            const reader = new FileReader();
            reader.onload = () => {
                let base64 = reader.result.split(',')[1];
                // push only contentVersion here, not full wrapper
                this.fileContents.push({
                    fileName: file.name,
                    base64: base64
                });
            };
            reader.readAsDataURL(file);
        }
    }
    @track contentVersionIds = [];


    async handleFileUpload(event) {

        const file = event.target.files[0];
        console.log('files', event.target.files);

        if (!file) return;
        const allowedTypes = ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'];
        const ext = file.name.split('.').pop().toLowerCase();
        let errorMsg = '';
        if (!allowedTypes.includes(ext)) {
            errorMsg = `Invalid file type: ${fileExt}. Allowed types are ${allowedTypes.join(', ')}`;
            //const updatedField = { ...this.field, errorMessage: errorMsg };
            //this.field = updatedField;
            return;
        }
        if (file.size > this.fileSizeLimit * 1024 * 1024) {
            console.warn(`File too large: 1 ${file.name}`);
            errorMsg = `${file.name} exceeds ${this.fileSizeLimit} MB size limit`;

            return;
        }
        this.uploading = true;
        this.uploadProgress = 0;

        try {
            const sessionId = await getSessionId();
            let token = this.accessToken ? this.accessToken : sessionId
            const baseUrl = window.location.origin; // e.g., https://yourdomain.my.salesforce.com
            let endpoint;
            if (this.requestSubmittingBy === 'InternalUser' || this.networkName !== 'Tenant Portal') {
                endpoint = baseUrl + '/services/apexrest/FileUpload';
            }
            else {
                 endpoint = await this.fetchEndpoint();
            }
            // Prepare multipart form data (metadata + file)
            const formData = new FormData();
            // Read file as binary (not base64)
            const fileReader = new FileReader();
            fileReader.onloadend = async () => {

                const fileContent = fileReader.result; // ArrayBuffer
                let progressInterval = setInterval(() => {
                    if (this.uploadProgress < 90) {
                        this.uploadProgress += Math.floor(Math.random() * 5) + 1; // +1–5% randomly
                    }

                }, 400);
                // Send file to Apex REST

                const response = await fetch(endpoint, {
                    method: 'POST',
                    headers: {
                        'Authorization': 'Bearer ' + token,//this.accessToken? this.accessToken:sessionId, //+ sessionStorage.getItem('SalesforceToken'), // or Lightning session if already authenticated
                        'Content-Type': file.type,
                        'file-name': file.name,
                        'document-type': 'Case Comment',
                        'submitting-by': this.requestSubmittingBy,
                        'network-name': this.networkName,
                        'contact-id': this.contactId
                    },
                    body: fileContent
                });


                if (!response.ok) {
                    throw new Error('Upload failed: ' + response.statusText);
                }

                const contentVersionId = await response.json();
                this.contentVersionIds.push(contentVersionId);
                this.files = [...this.files, file];
                this.uploading = false;
                this.uploadProgress = 100;

            };

            // Important: read as ArrayBuffer for binary upload
            fileReader.readAsArrayBuffer(file);

        } catch (err) {
            console.error('Upload error:', err);
            this.errorMessage = err.message;
            this.uploading = false;
        }
    }
    async fetchEndpoint() {
        const url = await getFileUploadEndpoint();
        return url;
    }
    get progressStyle() {
        return `width: ${this.uploadProgress}%;`;
    }

    // handleDelete(event) {
    //     const index = event.target.dataset.index;
    //     this.files.splice(index, 1);
    //     this.fileContents.splice(index, 1);
    //     this.files = [...this.files];
    //     this.fileContents = [...this.fileContents];
    // }
    async handleDelete(event) {
        const index = event.target.dataset.index;

        // Get the corresponding ContentVersionId
        const contentVersionId = this.contentVersionIds[index].id;
        try {
            // Call Apex to delete ContentVersion
            await deleteUploadedFile({ contentVersionId });
            // Remove from local arrays
            this.files.splice(index, 1);
            this.contentVersionIds.splice(index, 1);
            this.files = [...this.files];
            this.contentVersionIds = [...this.contentVersionIds];
            this.template.querySelector('input[type="file"]').value = '';
        } catch (error) {
            console.error('Error deleting file:', error);
            this.errorMsg = 'Failed to delete file from server.';
        }
    }

    async handleSubmit() {
        // if (!this.commentText && this.fileContents.length === 0) {
        if (!this.commentText) {
            // this.noComment = true;
            // this.noCommentMessage = 'Please enter a comment or attach a file before submitting.';
            const inputs = this.template.querySelectorAll('lightning-textarea.comment-text-area');
            inputs.forEach(input => {
                input.setCustomValidity('Complete this field.');
                input.reportValidity();
            });
            return;
        }

        this.isLoading = true;
        try {
            //Build the wrapper expected by Apex
            let filesWrapper;
            let filesArray = [];
            if (this.contentVersionIds.length > 0) {
                // for (let i = 0; i < this.contentVersionIds.length; i++) {
                //     filesWrapper = {
                //         documentType: 'Case Comment',
                //         contentVersions: this.contentVersionIds   // all contentVersions here
                //     };
                //     filesArray.push(filesWrapper);
                // }
                const contentVersionWrappers = this.contentVersionIds.map(item => ({
                    contentVersionId: item.id
                }));

                filesWrapper = {
                    documentType: 'Case Comment',
                    contentVersions: contentVersionWrappers
                };

                filesArray.push(filesWrapper);
            }




            //filesArray.push(filesWrapper);
            const filesWrapperJson = JSON.stringify(filesArray);
            const newComment = await saveCaseComment({
                caseId: this.caseId,
                comment: this.commentText   // matches Apex signature
            });
            let fileLinks = [];
            if (this.contentVersionIds.length > 0) {
                const response = await createFileRecord({
                    filesData: filesWrapperJson,
                    parentId: this.caseId,
                    caseCommentId: newComment.Id
                })
                if (response && response.DocLinks) {
                    this.contentVersionIds = [];
            }

            }


            // this.getCommunicationHistoryData();
            this.fetchCaseDetails(true, true, false); // Refresh comments and documents

            this.commentText = '';
            this.files = [];
            this.fileContents = [];
            this.noComment = '';
            this.template.querySelector('lightning-textarea.comment-text-area').value = '';
            this.isLoading = false;
        } catch (error) {
            console.error('Error in handleSubmit', error.message, error.stack);
            this.isLoading = false;
        }

        //console.log('this.normalSections', JSON.stringify(this.normalSections));
    }

}