import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import getSASUrl from '@salesforce/apex/CalloutToBlobstorage.getSASUrl';
import External_URL from "@salesforce/schema/External_Files__c.External_URL__c";
//Added by Harsh@Aldar 14/10/2024 - Separate DLP and LFU
import EF_RT from "@salesforce/schema/External_Files__c.RelatedRecordTypeName__c";

export default class DmExternalFilePreview extends LightningElement {
    @api recordId;
    showSpinner = false;
    //Added by Harsh@Aldar 14/10/2024 - Separate DLP and LFU
    type = 'LFU';

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [External_URL, EF_RT]
    })
    externalInfo({ error, data }) {
        if (data) {
            this.previewExtFile(data);
        } else if (error) {
            this.showToast('Error', 'Error loading external file data', 'error');
        }
    }

    previewExtFile(data) {
        this.showSpinner = true;
        const url = getFieldValue(data, External_URL);
        const externalFileRelatedRT = getFieldValue(data, EF_RT);

        if (!url) {
            this.showSpinner = false;
            this.showToast('Error', 'External URL is missing', 'error');
            this.dispatchEvent(new CloseActionScreenEvent());
        }
        if (externalFileRelatedRT?.includes('District_Management')){
            this.type = 'LFU';
        } else {
            this.type = 'Non-LFU';
        }
        getSASUrl({ url: url, type : this.type })
            .then(res => {
                console.log('res', res);
                this.showSpinner = false;
                window.open(res, '_blank');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(err => {
                console.error('Error:', err);
                this.showSpinner = false;
                this.showToast('Error', 'Unable to preview this file', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}