import { LightningElement, api } from 'lwc';
import caseCloseRequest from '@salesforce/apex/DMCaseSendDocToCustomer.caseCloseRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class dmdraftTLA extends LightningElement {
    @api recordId;
    showSpinner = false;
    handleSave() {
        this.showSpinner = true;
        caseCloseRequest({ caseId: this.recordId })
            .then(data => {
                this.showSpinner = false;
                this.showToast('Success', 'Case status updated successfully', 'success');
                this.closeScreen();
                getRecordNotifyChange([{recordId: this.recordId}]);
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error creating document: ', error);
                this.showToast('Error', error.body.message, 'error');
                this.closeScreen();
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