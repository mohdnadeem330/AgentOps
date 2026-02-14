import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { CurrentPageReference } from 'lightning/navigation';
import getVFDomainURL from "@salesforce/apex/Utilities.getVFDomainURL";
import getServiceRequest from "@salesforce/apex/SOAFromSRController.getServiceRequest";

export default class SOAFromSR extends NavigationMixin(LightningElement) {

    @api recordId;
    @track errorMessageToDisplay = '';
    @track errorHeader = 'Error Message';
    @track error = { message: '' };
    @track isLoaded = false;
    @track srRecord;
    @track soaUrl = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    async connectedCallback() {

        this.isLoaded = true;
        getServiceRequest({ srId: this.recordId }).then(result => {

            this.srRecord = result;
            this.handleSOA();


            console.log(result);
            this.isLoaded = false;

        }).catch(error => {
            this.error = error;
            this.reduceErrors(error);
            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
            this.isLoaded = false;
        })
    }

    handleSOA() {

        if (this.srRecord.SalesOrder__c == null) {
            this.errorMessageToDisplay = 'Kindly populate Sales Order to see Statment of Account';
            this.errorHeader = 'Statment of Account';
            this.isLoaded = false;

        } else {

            var mainUrl = getVFDomainURL();
            var fullUrl = mainUrl + '/apex/StatementOfAccountDocument?id=' + this.srRecord.SalesOrder__c;
            this.soaUrl = '/apex/StatementOfAccountDocument?id=' + this.srRecord.SalesOrder__c;
            console.log('Page URL soaUrl- ' + this.soaUrl);
            /*this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/StatementOfAccountDocument?id=' + this.caseRecord.SalesOrder__c
                }
            }).then(url => { window.open(url) });*/
        }
    }

    handleSOANewTab() {

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: this.soaUrl
            }
        }).then(url => { window.open(url) });

    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
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