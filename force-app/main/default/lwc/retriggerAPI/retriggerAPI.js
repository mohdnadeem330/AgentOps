import { api, LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";

import SYNC_STATUS_FIELD from '@salesforce/schema/HexaBPM__Service_Request__c.SyncStatus__c';

import callRespectiveAPI from '@salesforce/apex/RetriggerAPIController.callRespectiveAPI';

export default class RetriggerAPI extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading = true;
    @track syncStatus = '';
    @track isSyncStatusFound = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [SYNC_STATUS_FIELD] })
    wireRecordData({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.syncStatus = data.fields.SyncStatus__c.value;
            console.log('syncStatus>>>' + this.syncStatus);
            
            if (this.syncStatus != undefined && this.syncStatus != null && (this.syncStatus == 'Failed' || this.syncStatus == '') && !this.isSyncStatusFound) {
                this.callAPICallout(this.recordId);
                this.isSyncStatusFound = true;
            } else if (this.syncStatus == 'Synced' || this.syncStatus == 'In Progress') {
                const evt = new ShowToastEvent({
                    title: 'API is alreday ' + this.syncStatus + '.',
                    variant: 'info',
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }
    }

    connectedCallback() {
        let rcId = this.recordId && this.recordId != null ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
        console.log('rcId>>>' + rcId);
    }

    async callAPICallout(rId) {
        this.isLoading = true;
        await callRespectiveAPI({
            srId: rId
        }).then(result => {
            if (result == 'success') {
                const evt = new ShowToastEvent({
                    title: 'API Retriggering!!!',
                    variant: 'info',
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(new CloseActionScreenEvent());
                this.isLoading = false;
            }
        }).catch(error => {
            console.error('error', error);
            this.isLoading = false;
        })
    }
}