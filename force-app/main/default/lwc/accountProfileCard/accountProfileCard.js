import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Account.Name','Account.CurrentValueRating__c','Account.CustomerClass__c', 'Account.ProfilePicUrl__c', 'Account.BillingStreet', 'Account.BillingCity', 'Account.BillingState', 'Account.BillingPostalCode'];

export default class AccountProfileCard extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get accountRecord() {
        return this.account.data;
    }

    get error() {
        return this.account.error;
    }
	
}