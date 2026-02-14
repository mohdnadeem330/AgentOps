import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import generateAllDocuments from '@salesforce/apex/AccountDocumentGenerator.generateAllDocuments';

export default class GenerateDocuments extends LightningElement {
    isExecuting = false;
    @api recordId;

    @api async invoke() {

        console.log('LOgged : ',this.recordId);
        generateAllDocuments({ accountId: this.recordId })
        .then(result => {
            console.log('Result', result);
            if (result) {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Success",
                    message: "Documents generated successfully.",
                    variant: "success"
                }));
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Failed",
                    message: "Failed to generate documents.",
                    variant: "error"
                }));
            } 
        })
        .catch(error => {
            console.error('Error:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: "Failed",
                message: "Failed to generate documents.",
                variant: "error"
            }));
        });
        
        if (this.isExecuting) {
            return;
        }
        this.isExecuting = true;
        // add code here

        await this.sleep(2000);
        this.isExecuting = false;
    }

    sleep(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }
}