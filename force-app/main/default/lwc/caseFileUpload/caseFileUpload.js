import { LightningElement, track } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import validateEncryptedToken from '@salesforce/apex/UploadDocumentLinkController.validateEncryptedToken';
import uploadFilesToCase from '@salesforce/apex/UploadDocumentLinkController.uploadFilesToCase';
import getCaseDetails from '@salesforce/apex/UploadDocumentLinkController.getCaseDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import COMPANY_LOGO from '@salesforce/resourceUrl/AldarLogo';

export default class GuestCaseFileUpload extends LightningElement {

    @track caseId;
    @track isLoading = true;
    @track caseRecord;
    @track isLinkExpired = false; // new: expired link flag

    acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg', '.doc', '.docx'];
    recordId = USER_ID;
    companyLogo = COMPANY_LOGO;


    connectedCallback() {
        const params = new URLSearchParams(window.location.search);
        const token = params.get('key');

        if (!token) {
            // this.showToast('Error', 'Missing token', 'error');
            this.isLoading = false;
            this.isLinkExpired = true;
            return;
        }

        // Validate token
        validateEncryptedToken({ token })
            .then(caseId => {
                this.caseId = caseId;
                return getCaseDetails({ caseId });
            })
            .then(caseRec => {
                this.caseRecord = caseRec;
            })
            .catch(error => {
                this.isLinkExpired = true;
            })
            .finally(() => {
                this.isLoading = false;
            });

    }

    handleUploadFinished(event) {
        if (!this.caseId) return;

        const uploadedFiles = event.detail.files;
        const contentDocumentIds = uploadedFiles.map(f => f.documentId);
        this.isLoading = true;
        uploadFilesToCase({ caseId: this.caseId, contentDocumentIds })
            .then(() => {
                // Hide upload section & show success
                this.uploadSuccess = true;

                // this.showToast(
                //     'Success',
                //     `${uploadedFiles.length} file(s) uploaded successfully`,
                //     'success'
                // );
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Upload failed', 'error');
            }).finally(() => {
                // Stop spinner
                this.isLoading = false;
            });
    }

    get showUploadSection() {
        return this.caseId && !this.uploadSuccess;
    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}