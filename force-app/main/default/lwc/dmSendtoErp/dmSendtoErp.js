import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import createPayments from '@salesforce/apex/Dm_ERPIntegrationCtrl.createPayments';

export default class DmSendtoErp extends LightningElement {
    @api recordId;
    showSpinner = false;


    handleSave() {
        this.showSpinner = true;

        createPayments({ caseId: this.recordId }).then(res => {
            try {
                console.log(res);
                //console.log(JSON.parse(res));
                this.showSpinner = false;
                if (res && res === 'no payment records') {
                    this.showToast('error', 'No payments available for processing.', 'error', 'dismissable');
                } else if (res) {
                    const parsedData = JSON.parse(res);
                    if (parsedData.statusCode == '500') {
                        this.showToast('error', 'Unable to process the request.', 'error', 'dismissable');
                    } else {
                        const errorRecords = parsedData?.results?.filter(result => result.status === "E");
                        if (errorRecords.length > 0) {
                            const errors = errorRecords.length > 0
                                ? errorRecords.map(result => `Payment ID: ${result.paymentid}, Error: ${result.errorMsg}`).join(" | ")
                                : "";
                            console.log(errors);
                            this.showToast('error', errors, 'error', 'dismissable');
                        }else{
                            this.showToast('success', 'Your request has been successfully processed.', 'success', 'dismissable');
                            this.closeScreen();
                        }

                    }
                } else {
                    this.showToast('error', 'Unable to process the request.', 'error', 'dismissable');                   

                }
            } catch (e) {
                console.log(e.message);
            }
        }).catch(error => {
            this.showSpinner = false;
            console.log(JSON.stringify(error));
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