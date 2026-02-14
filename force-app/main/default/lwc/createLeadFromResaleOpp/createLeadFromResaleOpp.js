import { LightningElement, api, track } from 'lwc';
import createNewLead from '@salesforce/apex/CreateLeadFromResaleOppController.createNewLead';
import LightningConfirm from 'lightning/confirm';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateLeadFromResaleOpp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showSpinner = false;

    connectedCallback(){
        this.handleConfirm();
    }

    async handleConfirm() {
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to Create New Lead?',
            theme: 'warning',
            label: 'Create Lead'
        });
        if(result){
            this.createLead();
        }else{
            this.nextStep( false, undefined, undefined, true );
        }
    }

    createLead() {
        this.showSpinner = true;
        const recordId = this.recordId;
        createNewLead({ recordId: recordId })
        .then(result => {
            let resultArr = result.split(':'); console.log(resultArr);
            if(resultArr && Array.isArray(resultArr) && resultArr[0] == 'success'){
                this.nextStep( false, resultArr[1], undefined, false, );
            }else{
                this.nextStep( false, undefined, {   
                        label: 'Lead Creation Failed',
                        message: `An error occurred. Details: ${JSON.stringify(result)}`,
                        theme: 'error',
                    }, true
                );
            }
        })
        .catch(error => {
            console.log('#### Error creating Lead : ',error.body.message);
            this.nextStep( false, undefined, undefined, true );
        });
    }

    async nextStep(spinner, leadId, alert, close){
        this.spinner = spinner;
        if(leadId){
            this.showNotification('Success', 'Lead Created', 'success');
            this.goToRecordPage(leadId, 'view');
        }
        if(alert){
            await LightningAlert.open(alert);
        }
        if(close){
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    goToRecordPage(recordId, type) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: type
            }
        }, true);
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}