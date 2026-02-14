import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getRecordDetails from "@salesforce/apex/InitiateResaleController.getRecordDetails";

export default class InitiateResaleLwc extends NavigationMixin(LightningElement)  {
    recordId;
    result;
    sobjectType;
    recordDetials;
    accountDetials;
    email;
    
    initLoad = false;
    loading = true;
    confirming = true;
    error;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {console.log(currentPageReference);
            this.recordId = currentPageReference.state.recordId;
            this.getRecord();
        }
    }

    getRecord(){
        getRecordDetails({ recordId: this.recordId })
        .then(result =>{
            console.log(result);
            this.result = result;
            let closePanel = false;
            if('type' in result){
                this.sobjectType = result.type;
                switch (this.sobjectType) {
                    case  'SalesOrder__c':
                        this.recordDetials = result.salesOrder;
                        this.confirming = true;
                        break;
                    default:
                        closePanel = true;
                        break;
                }
                if(!closePanel && this.recordDetials){console.log(this.recordDetials);
                    if('Account__r' in this.recordDetials){
                        this.accountDetials = this.recordDetials.Account__r;
                    }else{
                        this.showToast('Error','Account is Inaccessible','error');
                        closePanel = true;
                    }
                }
                if(closePanel){
                    this.close();
                }
                this.initLoad = true;
                this.loading = false;
            }else{
                this.showToast('Unexpected Exception', JSON.stringify(result), 'error');
                this.close();
            }
        })
        .catch(error => {
            this.processError(error, true);
            this.close();
        })
    }

    handleConfirmation(event) {
        let button = event.currentTarget.dataset.button;
        this.confirming = false;
        this.loading = true;
        if (button == 'confirm') {
            this.goToNewCaseRecordForm();
        } else if (button == 'cancel') {
            this.close();
        }
    }

    goToNewCaseRecordForm(){
        const defaultValues = encodeDefaultFieldValues({
            Unit__c: this.recordDetials.Unit__c,
            SalesOrder__c: this.recordId,
            AccountId: this.recordDetials.Account__c,
            Status: this.result.status,
            Origin: this.result.origin,
            Current_Residential_Status__c: this.accountDetials.ResidentStatus__pc,
            Current_Residential_Country__c: this.accountDetials.CountryOfResidence__pc,
            Sales_Manager__c: this.result.salesManagerId,
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                recordTypeId: this.result.recordTypeId,
            }
        }, true);
    }

    processError(error, showToast){
        let processedError = '' + error + '';
        if(typeof error === 'object' && error !== null && JSON.stringify(error) != '{}'){
            if('body' in error && 'message' in error.body){
                processedError = '';
                if('output' in error.body && error.body.output && 'errors' in error.body.output && error.body.output.errors ){
                    let nestedErrors = error.body.output.errors;
                    if(Array.isArray(nestedErrors)){
                        nestedErrors.forEach(thisErr => {
                            processedError += '\n' + thisErr.message;
                        });
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

    close(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}