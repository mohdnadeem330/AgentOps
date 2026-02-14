import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import PARENT_OPPORTUNITY_FIELD from "@salesforce/schema/Resale_Offers__c.Opportunity__c";
import updateRecordStatus from '@salesforce/apex/ResaleOfferApproveButtonController.init';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ResaleOfferApproveButton extends NavigationMixin(LightningElement) {
    @api recordId;

    @track showSuccessMessage = false;
    @track showErrorMessage = false;
    @track showSpinner = false;
    @track showButtonOptions = true;
    @track errorMessage;

    @wire(getRecord, { recordId: "$recordId", fields: [PARENT_OPPORTUNITY_FIELD] })
    offer;

    get oppId() {
        return getFieldValue(this.offer.data, PARENT_OPPORTUNITY_FIELD);
    }

    handleAccept() {
        this.updateStatus('Accepted');
    }

    handleReject() {
        this.updateStatus('Rejected');
    }

    updateStatus(status) {
        this.showSpinner = true;
        this.showButtonOptions = false;
        updateRecordStatus({ recordId: this.recordId, status: status })
        .then(result => {console.log(result);
            this.showSuccessMessage = true;
            this.showErrorMessage = false;
            this.refreshRecord(status);  
        })
        .catch(error => {console.log(error);
            this.errorMessage = error.body.message;
            this.showSuccessMessage = false;
            this.showErrorMessage = true;
            this.showSpinner = false;
        });
    }

    refreshRecord(status){
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        this.showSpinner = false;
        if(status === 'Accepted'){
            this.showNotification('Success', 'Offer Accepted Successfully', 'success');
            notifyRecordUpdateAvailable([{recordId: this.oppId}]);
            this.goToRecordPage(this.oppId, 'view');
        }else{
            this.showNotification('Success', 'Offer Rejected Successfully', 'success');
            setTimeout(() => { console.log('closing'); this.handleClose(); }, 300);
        }
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
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