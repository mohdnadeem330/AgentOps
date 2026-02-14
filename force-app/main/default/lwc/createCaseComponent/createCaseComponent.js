import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import returnToastMessage from '@salesforce/apex/CreateCaseComponentController.returnToastMessage';

export default class CreateCaseComponent extends LightningElement{
    isExecuting = false;
    @api recordId;

    @api async invoke() {
        returnToastMessage({ accountId: this.recordId })
        .then(result => {
            if (result) {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Success",
                    message: result,
                    variant: "success"
                }));
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Failed",
                    message: "Failed to create merge Case.",
                    variant: "error"
                }));
            }
        })
        .catch(error => {
            console.error('Error:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: "Failed",
                message: "Failed to create merge Case.",
                variant: "error"
            }));
        });
        
        if (this.isExecuting) {
            return;
        }
        this.isExecuting = true;

        await this.sleep(2000);
        this.isExecuting = false;
    }

    sleep(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }
}