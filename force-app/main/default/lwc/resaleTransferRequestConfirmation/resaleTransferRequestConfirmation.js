import { LightningElement, api, track } from 'lwc';
import initiateTransfer from '@salesforce/apex/ResaleTransferRequestConfirmController.initiateTransfer';
import LightningConfirm from 'lightning/confirm';
import LightningAlert from 'lightning/alert';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class ResaleTransferRequestConfirmation extends LightningElement {
    @api recordId;
    @track showSpinner = false;

    connectedCallback(){
        this.handleConfirm();
    }

    async handleConfirm() {
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to Initiate Transfer Process?',
            theme: 'warning',
            label: 'Initiate Transfer'
        });
        if(result){
            this.showSpinner = true;
            this.createSR();
        }else{
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    createSR() {
        const recordId = this.recordId;
        initiateTransfer({ recordId: recordId })
            .then(result => {
                if(result && result == 'success'){
                    LightningAlert.open({
                        message: 'Service Request Created',
                        theme: 'success',
                        label: 'Success'
                    });
                }else{
                    LightningAlert.open({
                        message: `An error occurred. Details: ${JSON.stringify(result)}`,
                        theme: 'error',
                        label: 'Service Request Creation Failed'
                    });
                }
            })
            .catch(error => {
                console.log('#### Error creating SR : ',error.body.message);
            })
            .finally(() => {
                this.showSpinner = false;
                this.dispatchEvent(new CloseActionScreenEvent());
                this.refreshRecord();
            });
    }

    refreshRecord(){
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
    }
}