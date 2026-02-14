import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import {CurrentPageReference} from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import callTransactionAPI from '@salesforce/apex/CryptoTransactionRequest.postTransaction';

export default class CryptoTransaction extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading=true;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.callAPI();
        }
    }

    updateRecordView(recordId) {
        updateRecord({fields: { Id: recordId }});
    }

    callAPI(){
        this.isLoading=true;
        callTransactionAPI({recordId : this.recordId })
        .then(data => {
            console.log('success');            

            if(data==="SUCCESS"){
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Crypto Payment Link generated successfully!',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }else{
                const evt = new ShowToastEvent({
                    title: 'Failure',
                    message: JSON.stringify(data),
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }         
            this.updateRecordView(this.recordId);
            this.isLoading=false;
            this.dispatchEvent(new CloseActionScreenEvent());
        }).catch(error => { 
            this.isLoading=false;
        });
    }
}