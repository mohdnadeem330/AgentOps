import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getparentRecordDetails from "@salesforce/apex/ReceiptAcknowledgementController.initialiseReceiptAcknowlegment";
import updateReceiptAcknowledgementRecord from "@salesforce/apex/ReceiptAcknowledgementController.updatedReceiptAcknowledgementRecord";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import PaidbyUser from '@salesforce/schema/ReceiptAcknowledgement__c.RecievedFromAccount__c';

export default class UpdatePaidBy extends NavigationMixin(LightningElement) {
    @api recordId;
    @track payFromAccountId = '';
    @track accountList = [];
    @track receiptAckRecordId = '';
    @track parentRecord = {};
    @track exisitPaidByUser = '';
    @track isLoading = false;
    @track disableSave = false;

    @wire(getRecord, { recordId: '$recordId', fields: [PaidbyUser] })
    getRecords({ data }) { 
        if (data) {
            this.exisitPaidByUser = data.fields.RecievedFromAccount__c.value;
        }
    }

    @wire(getparentRecordDetails, { recordId: '$recordId' })
    parentRecords(result) { 
        const { data, error } = result;
        if (data) {
            this.parentRecord = data;
            if (this.parentRecord.relatedAccounts) {
                const uniqueAccounts = new Map();
                this.parentRecord.relatedAccounts.forEach(account => {
                    uniqueAccounts.set(account.Id, account);
                });
                this.accountList = [...uniqueAccounts.values()]
                    //.filter(account => account.Id !== this.exisitPaidByUser)
                    .map(account => {
                        return { 
                            label: account.Name, 
                            value: account.Id 
                        };
                    });

                this.payFromAccountId = this.parentRecord.salesOrderRecord.Account__c;
            }
        } else if (error) {
            this.showToast('Error', 'Failed to fetch parent record details.', 'error');
        }
    }

    handleChange(event) {
        this.payFromAccountId = event.detail.value;
    }

    handleSave() {
        this.isLoading = true;
        if (this.exisitPaidByUser !== this.payFromAccountId) {
            const receiptAcknowledgementRec = {
                sobjectType: 'ReceiptAcknowledgement__c',
                Id: this.recordId,
                RecievedFromAccount__c: this.payFromAccountId,
            };

            updateReceiptAcknowledgementRecord({ recieptRecord: receiptAcknowledgementRec })
                .then(() => {
                    this.showToast('Success', 'Receipt Acknowledgement Paid By is updated.', 'success');
                })
                .then(() => {
                    this.navigateToRecord();
                    this.isLoading = false;
                })
                .catch(error => {
                    const errorMessage = error.body && error.body.message ? error.body.message : 'An error occurred while updating the record.';
                    this.showToast('Error', errorMessage, 'error');
                    this.isLoading = false;
                });
        } else {
            this.showToast('Error', 'Current user and the selected user are the same. Please choose another user.', 'error');
            this.isLoading = false;
        }
    }

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'ReceiptAcknowledgement__c',
                actionName: 'view'
            }
        });
        setTimeout(() => {
            window.location.reload();
        }, 1000);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}