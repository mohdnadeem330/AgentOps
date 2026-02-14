import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createResaleCharges from "@salesforce/apex/ResaleService.createResaleCharges_AuraEnabled";

export default class CancelResaleLwc extends LightningElement {
    loading = true;
    recordId;

    successMessage= 'Case has been successfully cancelled.';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.createCharges(this.recordId);
        }
    }

    createCharges(recordId){
        this.loading = true;
        createResaleCharges({recordId: recordId})
        .then(result => {
            console.log(result);
            this.loading = false;
            this.showToast('Success', result, 'success');
            this.dispatchEvent(new CloseActionScreenEvent());
        }).catch(error => {
            this.loading = false;
            this.processError(error, true);
            this.dispatchEvent(new CloseActionScreenEvent());
        })
    }

    processError(error, showToast){
        console.log(error);
        let processedError = '' + error + '';
        if(typeof error === 'object' && error !== null && JSON.stringify(error) != '{}'){
            if('body' in error && 'message' in error.body){
                processedError = '';
                if('output' in error.body && error.body.output){
                    let errOutput = error.body.output;
                    if('errors' in errOutput && errOutput.errors && Array.isArray(errOutput.errors) && errOutput.errors.length > 0 ){
                        errOutput.errors.forEach(thisErr => {
                            processedError += '\n' + thisErr.message;
                        });
                    }
                    if('fieldErrors' in errOutput && errOutput.fieldErrors ){
                        for (let field in errOutput.fieldErrors) {
                            if(Array.isArray(errOutput.fieldErrors[field]) && errOutput.fieldErrors[field].length > 0){
                                processedError += errOutput.fieldErrors[field][0].fieldLabel + ': ';
                                errOutput.fieldErrors[field].forEach(thisErr => {
                                    processedError += thisErr.message;
                                });
                            }else{
                                processedError += field;
                            }
                        }
                    }
                }else{
                    processedError = error.body.message;
                }
            }else{
                processedError = JSON.stringify(error);
            }
        }
        console.error(processedError);
        if(showToast){
            this.showToast('Error',processedError,'error');
        }
    }
    
    showToast(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}