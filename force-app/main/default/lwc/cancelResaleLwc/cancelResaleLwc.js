import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import RECORDTYPEID_FIELD from '@salesforce/schema/Case.RecordTypeId';
import CANCELLATION_REASON_FIELD from '@salesforce/schema/Case.CancellationReason__c';

export default class CancelResaleLwc extends LightningElement {
    loading = true;
    recordId;
    caseRecord;

    currentStatus;
    
    get cancellationMessage() {
        return this.currentStatus == 'Property Listed' 
                ? 'Customer will have to pay listing fee and service charge if he/she initiates the transfer before expiry date.\nAre you sure you want to cancel this listing?' 
                : undefined;
    }

    successMessage= 'Case has been successfully cancelled.';

    _newCancellationReason;
    get newCancellationReason(){
        if(this._newCancellationReason){
            return this._newCancellationReason;
        }else{
            this._newCancellationReason = this.currentStatus == 'Property Listed' ? 'Customer Backed-Out' : 'Other';
            return this._newCancellationReason;
        }
    }
    cancellationReasonOptions = [
        { label: 'Customer Backed-Out', value: 'Customer Backed-Out' },
        { label: 'Other', value: 'Other' },
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    @wire(getRecord, { recordId:  '$recordId', fields: [STATUS_FIELD, RECORDTYPEID_FIELD, CANCELLATION_REASON_FIELD] })
    setCase({ error, data }){
        if(data){
            var result = JSON.parse(JSON.stringify(data));
            console.log('case data: ', result);
            this.caseRecord = result;
            this.recordTypeId = getFieldValue(result, RECORDTYPEID_FIELD); // result.fields.RecordTypeId.value;
            this.currentStatus = getFieldValue(result, STATUS_FIELD); // result.fields.Status.value;
            this._newCancellationReason = getFieldValue(result, CANCELLATION_REASON_FIELD); // result.fields.CancellationReason__c.value;
            this.loading = false;
        }else if(error) {
            this.processError(error, true);
        }
    };
    
    @wire(getPicklistValues, { recordTypeId:  '$recordTypeId', fieldApiName: CANCELLATION_REASON_FIELD })
    setCancellationReasonOptions({error, data}){console.log(this.recordTypeId);
        if(data){
            var result = JSON.parse(JSON.stringify(data));
            console.log('picklist data: ', result);
            if('values' in result){
                this.cancellationReasonOptions = result.values;
            }else{
                this.processError('Unable to get cancellation reason options', true);
            }
            this.loading = false;       
        }else if(error) {
            this.loading = false;
            this.processError(error, false);
        }
    };

    handleChange(event) {
        this._newCancellationReason = event.detail.value;
    }

    async submitForCancellation(){
        this.loading = true;
        try {
            let fields = {
                Id: this.recordId,
                Status: 'Cancelled',
                CancellationReason__c: this._newCancellationReason,
            }
            await updateRecord({ fields: fields });
            this.showToast('Success', this.successMessage, 'success');
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.loading = false;
            this.processError(error, true);
        }
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