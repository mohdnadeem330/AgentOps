import { LightningElement, api, track } from 'lwc';
import { FlowNavigationFinishEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import LOGO_IMAGE from '@salesforce/resourceUrl/ECSS_logo';
import UploadBG from '@salesforce/resourceUrl/UploadBG';

export default class ResponseComponent extends LightningElement {
    // Input/Output variables to communicate with the flow
    @api
    get response() {
        return this.responseValue;
    }

    @api
    get reason() {
        return this.rejectionReason;
    }

    // Component's internal state
    @track responseValue = '';
    @track rejectionReason = '';
    @track showReason = false;
    
    // Import static resources for branding
    logoUrl = LOGO_IMAGE;
    bgUrl = UploadBG;

    // Options for the radio button group
    get responseOptions() {
        return [
            { label: 'Accept', value: 'Accept' },
            { label: 'Reject', value: 'Reject' },
        ];
    }

    // Logic to enable/disable the submit button
    get isSubmitDisabled() {
        if (this.responseValue === 'Reject' && !this.rejectionReason) {
            return true; // Disable if rejected but no reason is provided
        }
        if (!this.responseValue) {
            return true; // Disable if no response is selected
        }
        return false;
    }

    // Handles changes to the radio button selection
    handleResponseChange(event) {
        this.responseValue = event.detail.value;
        this.showReason = this.responseValue === 'Reject';
    }

    // Handles changes to the reason text area
    handleReasonChange(event) {
        this.rejectionReason = event.detail.value;
    }

    // Handles the submit button click
    handleSubmit() {
        // Basic validation check before proceeding
        if ((this.responseValue === 'Reject' && this.rejectionReason) || this.responseValue === 'Accept') {
            // This event allows the flow to proceed to the next screen
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }
}