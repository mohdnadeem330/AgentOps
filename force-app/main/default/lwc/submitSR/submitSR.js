import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';

import submitServiceRequest from '@salesforce/apex/SubmitSRController.submitServiceRequest';

export default class SubmitSR extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    @track isLoading = false;
    @track isSuccess = false;
    @track isError = false;
    @track errorMessage = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    async connectedCallback() {
        console.log('recordId>>>' + this.recordId);
        this.isLoading = true;
        this.isSuccess = false;
        this.isError = false;
        this.errorMessage = '';
        await submitServiceRequest({
            srId: this.recordId
        }).then(result => {
            console.log('result>>>' + JSON.stringify(result));
            let tempResult = JSON.parse(JSON.stringify(result));
            debugger;
            if (tempResult.status == 'Draft') {
                if (tempResult.error && tempResult.objMap.HexaBPM__Required_Docs_not_Uploaded__c) {
                    this.isError = true;
                    this.errorMessage = 'Please upload the required documents before Submit';
                    // const evt = new ShowToastEvent({
                    //     title: 'Error',
                    //     message: 'Please upload the required documents before Submit',
                    //     variant: 'error',
                    // });
                    // this.dispatchEvent(evt);
                } else if (tempResult.error && tempResult.actualMessage != undefined && tempResult.actualMessage != null && tempResult.actualMessage != '') {
                    this.isError = true;
                    this.errorMessage = tempResult.actualMessage;
                    // const evt = new ShowToastEvent({
                    //     title: 'Error',
                    //     message: tempResult.actualMessage,
                    //     variant: 'error',
                    // });
                    // this.dispatchEvent(evt);
                } else if (tempResult.error && tempResult.message != undefined && tempResult.message != null && tempResult.message != '') {
                    this.isError = true;
                    this.errorMessage = tempResult.message;
                    // const evt = new ShowToastEvent({
                    //     title: 'Error',
                    //     message: tempResult.message,
                    //     variant: 'error',
                    // });
                    // this.dispatchEvent(evt);
                } else {
                    this.isError = true;
                    this.errorMessage = 'Please Contact System Admin';
                    // const evt = new ShowToastEvent({
                    //     title: 'Error',
                    //     message: 'Please Contact System Admin',
                    //     variant: 'error',
                    // });
                    // this.dispatchEvent(evt);
                }
            } else if (tempResult.status == 'Submitted') {
                if (tempResult.isStatusChange) {
                    this.isSuccess = true;
                    // const evt = new ShowToastEvent({
                    //     title: 'Success',
                    //     message: 'This Service request is successfully Submitted',
                    //     variant: 'success',
                    // });
                    // this.dispatchEvent(evt);
                } else {
                    this.isError = true;
                    this.errorMessage = 'This Service Request is already Submitted';

                    setTimeout(() => {
                        this.updateRecordView(this.recordId);
                    }, 1000);

                    // const evt = new ShowToastEvent({
                    //     title: 'Error',
                    //     message: 'This Service Request is already Submitted',
                    //     variant: 'error',
                    // });
                    // this.dispatchEvent(evt);
                }
            } else {
                this.isError = true;
                this.errorMessage = 'This Service Request is already Submitted';

                // const evt = new ShowToastEvent({
                //     title: 'Error',
                //     message: '',
                //     variant: 'error',
                // });
                // this.dispatchEvent(evt);
            }

            this.isLoading = false;
        }).catch(error => {
            this.isError = true;
            this.errorMessage = error;
            console.error('error>>>' + error);
            // const evt = new ShowToastEvent({
            //     title: 'Error',
            //     message: error,
            //     variant: 'error',
            // });
            // this.dispatchEvent(evt);
            this.isLoading = false;
        })
    }

    closeAction() {
        this.updateRecordView(this.recordId);
        window.open('/' + this.recordId, '_self');
    }

    updateRecordView(recordId) {
        updateRecord({ fields: { Id: recordId } }).then(result => {
        })
    }
}