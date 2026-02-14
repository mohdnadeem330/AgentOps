import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord,getRecordNotifyChange } from "lightning/uiRecordApi";
import Status_FIELD from "@salesforce/schema/Case.Status";
import SubStatus_FIELD from "@salesforce/schema/Case.Sub_Status__c";
import ID_FIELD from "@salesforce/schema/Case.Id";

export default class DmPermitCloseBtn extends LightningElement {

    @api recordId;
    showSpinner = false;


   async handleSave() {
        this.showSpinner = true;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[Status_FIELD.fieldApiName] = 'Completed';
        fields[SubStatus_FIELD.fieldApiName] = 'Permit Closed';
        const recordInput = { fields };

        await updateRecord(recordInput)
            .then(() => {
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.closeScreen();
                this.showSpinner = false;
                this.showToast('success', 'Request has been closed successfully.', 'success', 'dismissable');
            })
            .catch(error => {
                this.showSpinner = false;
                console.log(error);
                this.showToast('error', 'Unable to process the request.', 'error', 'dismissable');
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