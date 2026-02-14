import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getRecordDetails from '@salesforce/apex/SendSRDocsController.getRecordDetails';
import sendForESign from '@salesforce/apex/SendSRDocsController.sendForESign';

export default class SendSRDocForESign extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading = true;
    @track isSuccess = false;
    @track isSending = false;
    @track isError = false;
    @track errorMessage = '';
    @track options = [];
    @track isOptions = false;
    // @track userGroup = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    async connectedCallback() {
        this.isSuccess = false;
        this.isSending = false;
        this.isError = false;
        this.errorMessage = '';
        this.isOptions = false;
        this.options = [];
        await getRecordDetails({
            recordId: this.recordId
        }).then(result => {
            let tempResult = JSON.parse(JSON.stringify(result));
            if (tempResult.hasOwnProperty('Error')) {
                this.isError = true;
                this.errorMessage = tempResult.Error;
                this.isLoading = false;
            }
            if (tempResult.hasOwnProperty('Success')) {
                if (Array.isArray(tempResult.Success)) {
                    for (let res of tempResult.Success) {
                        this.options.push({ 'label': res.FullName__c, 'value': res.EmailAddress__c, 'isSelected': false });
                    }
                    this.isOptions = true;
                    this.isLoading = false;
                } else {
                    this.sendDocForESign();
                }
            }
        }).catch(error => {
            console.error('error>>>' + error);
            this.isLoading = false;
        })
    }

    handleChange(event) {
        this.options[parseInt(event.target.dataset.idx)].isSelected = event.detail.checked;
    }

    handleSubmit() {
        let success = false;
        for (let opt of this.options) {
            if (opt.isSelected) {
                success = true; 
            }
        }
        if (success) {
            this.sendDocForESign();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a value, to whom you need to send the document for eSign',
                    variant: 'error'
                })
            );
        }
    }

    async sendDocForESign() {
        this.isLoading = true;
        this.isSuccess = false;
        this.isSending = true;
        this.isError = false;
        this.errorMessage = '';

        let optList = [];
        for (let opt of this.options) {
            if (opt.isSelected) {
                optList.push(opt.value);
            }
        }
        let authorisedSignatory = optList.join(',');
        await sendForESign({
            recordId: this.recordId,
            authorisedSignatory: authorisedSignatory
        }).then(data => {
            this.isSending = false;
            if (data && data != undefined && data != '' && data == 'Success') {
                this.isSuccess = true;
                this.handleCancel();
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Success',
                //         message: 'Document is successfully sent for eSignature',
                //         variant: 'success'
                //     })
                // );
            } else if (data && data != undefined && data != '') {
                this.isError = true;
                this.errorMessage = data;
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Error',
                //         message: data,
                //         variant: 'error'
                //     })
                // );
            } else {
                this.isError = true;
                this.errorMessage = 'Unable to perform this action, please try again after some time';
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Error',
                //         message: 'Unable to perform this action, please try again after some time',
                //         variant: 'error'
                //     })
                // );
            }
            this.isLoading = false;
        }).catch(error => {
            this.isError = true;
            this.errorMessage = 'Unable to perform this action';
            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Error',
            //         message: 'Unable to perform this action.',
            //         variant: 'error'
            //     })
            // );
            this.isLoading = false;
        });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'HexaBPM__Service_Request__c',
                actionName: 'view'
            }
        });
    }
}