import { LightningElement, api, track } from 'lwc';
import saveFinanceComment from '@salesforce/apex/FinanceComment.saveFinanceComment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class FinanceCommentUpdate extends NavigationMixin(LightningElement) {
    @api recordId; // The record ID from the Lightning page
    @track remarks = '';
    @track isSaving = false; // Track the saving state

    get spinnerClass() {
        return this.isSaving ? 'slds-show' : 'slds-hide';
    }

    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    async handleSave() {
        if (!this.recordId || !this.remarks) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Remarks cannot be empty.',
                variant: 'error',
            }));
            return;
        }

        this.isSaving = true; // Set loading state to true
        try {
            await saveFinanceComment({ recordID: this.recordId, remarks: this.remarks });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Finance Comments updated successfully!',
                variant: 'success',
            }));
            this.remarks = ''; // Clear the textarea after success
            this.navigateToRecordViewPage(); // Redirect and refresh the page
        } catch (error) {
            const errorMessage = error.body?.message || 'An unknown error occurred.';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: errorMessage,
                variant: 'error',
            }));
            console.error('Error:', error); // Log error details for debugging
        } finally {
            this.isSaving = false; // Reset loading state
        }
    }

    navigateToRecordViewPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });

        // Set a timeout to refresh the page after navigation
        setTimeout(() => {
            window.location.reload();
        }, 1000); // Delay of 1 second to allow navigation to complete
    }
}