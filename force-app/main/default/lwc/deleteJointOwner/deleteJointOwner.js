import { LightningElement, api, track } from 'lwc';
import submitForApproval from '@salesforce/apex/DeleteJointOwner.SubmitForDelete';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import modal from "@salesforce/resourceUrl/custommodalcss";
import { loadStyle } from "lightning/platformResourceLoader";

export default class DeleteJointOwner extends LightningElement {
    @api recordId;  
    @track isLoading = false;
    @track errorMessage = '';

    connectedCallback() {
        loadStyle(this, modal);
      }
    
    handleApproval() {
        this.isLoading = true;
        submitForApproval({ recordId: this.recordId })
            .then((result) => {
                this.isLoading = false;
                if (result) {
                    this.showToast('Success', 'Record submitted for approval', 'success');
                    this.dispatchEvent(new CloseActionScreenEvent());
                    
                } else {
                    this.errorMessage = 'Failed to submit the record for approval.';
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.errorMessage = error.body.message || 'Unknown error';
                this.showToast('Error', this.errorMessage, 'error');
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
    cancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}