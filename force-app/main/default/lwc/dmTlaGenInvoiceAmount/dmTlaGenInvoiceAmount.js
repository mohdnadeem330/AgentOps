import { LightningElement, api, wire } from 'lwc';
import SendOverstayDetails from '@salesforce/apex/DMCaseSendDocToCustomer.SendOverstayDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class DmTlaGenInvoiceAmount extends LightningElement {
    @api recordId;
    showSpinner = false;
    handleSend() {
        this.showSpinner = true;
        SendOverstayDetails({ caseId: this.recordId }).then(data => {
            this.showToast('Success', 'Email has been sent to customer successfully.', 'success', 'dismissable');
            this.closeScreen();
            getRecordNotifyChange([{ recordId: this.recordId }]);
        }).catch(error => {
            this.showSpinner = false;
            this.showToast('Error', 'Unable to send an email, please check with Admin', 'error', 'dismissable');
            //console.log(JSON.stringify(error))
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