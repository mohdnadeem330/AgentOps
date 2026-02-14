import { LightningElement, api, track } from 'lwc';
import closeServiceRequest from '@salesforce/apex/CloseServiceRequestController.closeServiceRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CloseServiceRequest extends LightningElement {
    @api recordId;
    @track isLoading = false;

    async handleCloseClick() {
        this.isLoading = true;

        try {
            const result = await closeServiceRequest({ serviceRequestId: this.recordId });

            // ✅ Success Toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: result,
                    variant: 'success'
                })
            );

            // ✅ Close the Quick Action Modal automatically
            this.dispatchEvent(new CloseActionScreenEvent());

        } catch (error) {
            let message = 'Unexpected error occurred';
            if (error && error.body && error.body.message) {
                message = error.body.message;
            } else if (error && error.message) {
                message = error.message;
            }

            // ❌ Error Toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: message,
                    variant: 'error'
                })
            );

        } finally {
            this.isLoading = false;
        }
    }
}