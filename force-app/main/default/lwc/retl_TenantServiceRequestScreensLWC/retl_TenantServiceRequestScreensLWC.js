import { LightningElement, track, api } from 'lwc';
import getContactsByAccount from '@salesforce/apex/RETL_ServiceRequestWizardController.getContactsByAccount';

export default class Retl_TenantServiceRequestScreensLWC extends LightningElement {
    @track isStepOneModalOpen = true;
    @track showStepTwo = false;

    @api idFromVf;
    @track selectedAccountId;
    @track selectedContactId;
    @track contactOptions = [];

    connectedCallback() {
        console.log('idFromVf: ' + this.idFromVf);
        const urlId = this.idFromVf;
        console.log('urlId: ' + urlId);
        // Check if id exists and starts with '001'
        if (urlId && urlId.startsWith('001')) {
            this.selectedAccountId = urlId;
            // Load contacts for the selected account
            this.loadContacts();
        }
    }

    get isContactDisabled() {
        return !this.selectedAccountId;
    }

    get isNextDisabled() {
        return !(this.selectedAccountId && this.selectedContactId);
    }

    /** Account selection handler **/
    handleAccountSelect(event) {
        this.selectedAccountId = event.detail.recordId;
        if (this.selectedAccountId) {
            this.loadContacts();
        } else {
            this.contactOptions = [];
        }
    }

    /** Load contacts based on Account **/
    loadContacts() {
        getContactsByAccount({ accountId: this.selectedAccountId })
            .then(data => {
                this.contactOptions = data.map(c => ({ label: c.Name, value: c.Id }));
            })
            .catch(() => {
                this.contactOptions = [];
            });
    }

    handleContactChange(event) {
        this.selectedContactId = event.detail.value;
    }

    handleNextFromModal() {
        this.isStepOneModalOpen = false;
        this.showStepTwo = true;
    }

    closeStepOneModal() {
        this.isStepOneModalOpen = false;
    }

    handleBack() {
        this.showStepTwo = false;
        this.isStepOneModalOpen = true;
    }
}