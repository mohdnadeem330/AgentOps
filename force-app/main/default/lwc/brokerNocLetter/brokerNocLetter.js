import { LightningElement, track } from 'lwc';
import loggedInUserId from '@salesforce/user/Id';
import getProjectPicklistValues from '@salesforce/apex/BP_Configurations.getProjectPicklistValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BrokerNocLetter extends LightningElement {
    @track projectOptions = [];
    @track selectedProjects = [];
    @track showIframe = false;
    @track showSpinner = false;
    @track broker_NOC_URL;

    urlPrefix = '/BrokerNOCLetterPDF?';

    connectedCallback() {
        this.loadPicklistValues();
    }

    async loadPicklistValues() {
        try {
            const data = await getProjectPicklistValues();
            this.projectOptions = data.map(item => ({ label: item, value: item }));
        } catch (error) {
            console.error('Error loading picklist values:', error);
        }
    }

    handleProjectChange(event) {
    this.selectedProjects = event.detail.value;
}


    get isNextDisabled() {
        return !(this.selectedProjects && this.selectedProjects.length > 0);
    }

    handleNext() {

        const encodedProjects = encodeURIComponent(this.selectedProjects);
        this.showSpinner = true;
        this.showIframe = true;

        this.broker_NOC_URL =
            '..' + this.urlPrefix +
            'userId=' + loggedInUserId +
            '&projects=' + encodedProjects;

        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    closeModal() {
        this.selectedProjects = [];
        this.showIframe = false;
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}