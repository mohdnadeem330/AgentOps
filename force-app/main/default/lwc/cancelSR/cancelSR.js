import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { CurrentPageReference } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import checkToAllowCancelSR from '@salesforce/apex/CancelSRController.checkToAllowCancelSR';
import cancelSR from '@salesforce/apex/CancelSRController.cancelSR';

export default class CancelSR extends NavigationMixin(LightningElement) {

    @api recordId;
    @track errorMessageToDisplay = '';
    @track errorHeader = 'Error Message';
    @track error = { message: '' };
    @track isLoaded = true;
    @track isAllowToCancelSR = false;
    cancellationDisplayText = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.isLoaded = false;
        } else {
            this.navigateToSR();
        }
    }

    async connectedCallback() {
        this.isLoaded = true;
        await checkToAllowCancelSR({
            recordId: this.recordId
        }).then(result => {
            this.isAllowToCancelSR = result;
            if(result){
                this.cancellationDisplayText = 'Are you sure to cancel the SR?';
            } else {
                this.cancellationDisplayText = 'Cancellation is not allowed at this Stage.';
            }
            this.isLoaded = false;
        }).catch(error => {
            this.error = error;
            this.reduceErrors(error);
            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
            this.isLoaded = false;
        })
    }

    handleCancelation() {

        this.isLoaded = true;

        if (this.isAllowToCancelSR) {
            cancelSR({
                recordId: this.recordId
            }).then(result => {

                this.showToast('Success', 'Service Request Canceled Successfully', 'success');
                this.updateRecordView(this.recordId);

            }).catch(error => {
                this.error = error;
                this.reduceErrors(error);
                this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                this.isLoaded = false;
            })
        } else {
            this.showToast('Error', 'Cancelltion is not at this stage.', 'error');
        }
    }

    updateRecordView(recordId) {
        updateRecord({ fields: { Id: recordId } }).then(result => {
            this.closeAction();
        })
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    navigateToSR() {

        this.readOnlyScreen = true;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'HexaBPM__Service_Request__c',
                actionName: 'view'
            }
        }).then((url) => {
            window.location.replace(url);
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }

    reduceErrors(errors) {
        if (this.error.body) {
            if (Array.isArray(this.error.body)) {
                this.errorMessageToDisplay += this.error.body.map(e => e.message).join(', ');
            }
            else if (typeof this.error.body === 'object') {
                let fieldErrors = this.error.body.fieldErrors;
                let pageErrors = this.error.body.pageErrors;
                let duplicateResults = this.error.body.duplicateResults;
                let exceptionError = this.error.body.message;

                if (exceptionError && typeof exceptionError === 'string') {
                    this.errorMessageToDisplay += exceptionError;
                }

                if (fieldErrors) {
                    for (var fieldName in fieldErrors) {
                        let errorList = fieldErrors[fieldName];
                        for (var i = 0; i < errorList.length; i++) {
                            this.errorMessageToDisplay += fieldName + ' ' + errorList[i].message + ' ';
                            this.errorHeader = pageErrors[i] != null ? pageErrors[i].statusCode : this.errorHeader;
                        }
                    }
                }

                if (pageErrors && pageErrors.length > 0) {
                    for (let i = 0; i < pageErrors.length; i++) {
                        this.errorMessageToDisplay += pageErrors[i].message;
                        this.errorHeader = pageErrors[i] != null ? pageErrors[i].statusCode : this.errorHeader;
                    }
                }

                if (duplicateResults && duplicateResults.length > 0) {
                    this.errorMessageToDisplay += 'duplicate result error';
                }
            }
        }
        // handles errors from the lightning record edit form
        if (this.error.message) {
            this.errorMessageToDisplay += this.error.message;
        }
        if (this.error.detail) {
            this.errorMessageToDisplay += this.error.detail;
        }

    }
}