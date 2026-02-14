import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import generateInvoiceDocument from '@salesforce/apex/InvoiceBundleController.generateInvoiceDocument';

export default class RegenerateBrokerInvoiceBundle extends LightningElement {
    @api recordId;
    isLoading=true;
    recordLoaded=false;
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.initRegenerateBrokerInvoice();
        }
    }

    initRegenerateBrokerInvoice(){
        generateInvoiceDocument({recordId : this.recordId })
            .then(data => {
                if(data && data != undefined && data !='' &&  data =='Success' ){
                    this.isLoading=false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Request submitted successfully!',
                            variant: 'success'
                        })
                    );
                    
                }else if(data && data != undefined && data !='' ){
                    this.dispatchEvent(
                        new ShowToastEvent({
                        title: 'Error',
                        message: data,
                        variant: 'error'
                        })
                    );
                }
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable regenerate documents!',
                        variant: 'error'
                    })
                );
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
            });
        
    }
}