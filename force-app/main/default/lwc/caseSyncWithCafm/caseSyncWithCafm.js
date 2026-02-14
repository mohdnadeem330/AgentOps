import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import callCAFMCaseCreationBatch from '@salesforce/apex/CAFMCalloutToMuleSoft.callCAFMCaseCreationQueue';
import {  getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class caseSyncWithCafm extends LightningElement {
     @api recordId;
    showSpinner = false;
    handleSendtoCAFM() {
         const caseIds = [this.recordId];
        this.showSpinner = true;
        callCAFMCaseCreationBatch({ cafmCaseIdList: caseIds }).then(data => {
            this.showToast('Success', 'Your request has been completed successfully', 'success');
            this.closeScreen();
            getRecordNotifyChange([{ recordId: this.recordId }]);
        }).catch(error => {
            this.showSpinner = false;
            this.showToast('Error', 'Unable to sync with CAFM', 'error');
            console.log(JSON.stringify(error))
        });


    }
    closeScreen() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

}