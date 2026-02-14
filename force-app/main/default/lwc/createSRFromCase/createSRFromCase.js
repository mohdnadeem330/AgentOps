import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import createSR from '@salesforce/apex/CreateSRFromCaseController.createSR';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';

export default class CreateSRFromCase extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @track srId = '';
    @track isLoading = false;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    async connectedCallback() {
        console.log('this.recordId>>>' + this.recordId);


    }

    @track errorMessageToDisplay = '';
    @track error = { message: '' };
    @track errorHeader = 'Error Message';
    @track successMessageToDisplay = '';

    async createSR() {
        this.errorMessageToDisplay = '';
        this.isLoading = true;
        await createSR({
            caseId: this.recordId
        }).then(result => {
            console.log('result>>>' + JSON.stringify(result));
            this.srId = result.Id;
            this.successMessageToDisplay = 'Service Request Created Successfully';
            this.showToast('Success', this.successMessageToDisplay, 'success');
            this.isLoading = false;
        }).catch(error => {
            this.error = error;
            this.reduceErrors(error);
            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
            console.error(this.errorMessageToDisplay);
            console.error('error>>>' + JSON.stringify(error));
            this.isLoading = false;
        })
    }

    navigateToSR() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.srId,
                objectApiName: 'HexaBPM__Service_Request__c',
                actionName: 'view'
            }
        });
    }

    updateRecordViewAndClose() {
        this.isLoading = true;
        eval("$A.get('e.force:refreshView').fire();");
        setTimeout(() => {
            this.closeAction();
        }, 1000);
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
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