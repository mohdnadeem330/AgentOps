import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import QUOTE_OBJECT from '@salesforce/schema/Quote';
import TYPE_OF_STORAGE_FIELD from '@salesforce/schema/Quote.Type_of_storage__c';
import LEASE_PERIOD_FIELD from '@salesforce/schema/Quote.Lease_Period__c';
import FUTURE_EXPANSION_FIELD from '@salesforce/schema/Quote.Future_Expansion__c';
import INSURANCE_REQUIREMENT_FIELD from '@salesforce/schema/Quote.Insurance_Requirement__c';
import PAYMENT_SCHEDULE_FIELD from '@salesforce/schema/Quote.Payment_Schedule__c';
import STATUS_FIELD from '@salesforce/schema/Quote.Status';
import AGREED_LEASE_AMOUNT_FIELD from '@salesforce/schema/Quote.Agreed_Lease_Amount_annually__c';
import MAINTENANCE_FIELD from '@salesforce/schema/Quote.Maintenance__c';
import SECURITY_DEPOSIT_FIELD from '@salesforce/schema/Quote.Security_Deposit__c';
import OPPORTUNITY_ID_FIELD from '@salesforce/schema/Quote.OpportunityId';
import OPPORTUNITY_ACCOUNT_NAME_FIELD from '@salesforce/schema/Opportunity.Account.Name';
import EXPIRATION_DATE_FIELD from '@salesforce/schema/Quote.ExpirationDate';
import BOOKING_AMOUNT from '@salesforce/schema/Quote.Booking_Amount__c';
import TOTAL_LEASE_AMOUNT from '@salesforce/schema/Quote.Total_Lease_Amount__c';

export default class CreateLogisticQuote extends NavigationMixin(LightningElement) {
    @api recordId;
    accountName;
    isLoading = false;

    quoteObject = QUOTE_OBJECT;
    allFields = [
        TYPE_OF_STORAGE_FIELD,
        LEASE_PERIOD_FIELD,
        FUTURE_EXPANSION_FIELD,
        INSURANCE_REQUIREMENT_FIELD,
        PAYMENT_SCHEDULE_FIELD,
        STATUS_FIELD,
        AGREED_LEASE_AMOUNT_FIELD,
        MAINTENANCE_FIELD,
        SECURITY_DEPOSIT_FIELD,
        EXPIRATION_DATE_FIELD,
        BOOKING_AMOUNT,
        TOTAL_LEASE_AMOUNT
    ];

    @wire(getRecord, { recordId: '$recordId', fields: [OPPORTUNITY_ACCOUNT_NAME_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.accountName = data.fields.Account.value.fields.Name.value;
        } else if (error) {
            console.error('Error loading opportunity', error);
        }
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = event.detail.fields;
        fields[OPPORTUNITY_ID_FIELD.fieldApiName] = this.recordId;
        const today = new Date().toISOString().slice(0, 10);
        fields.Name = `${this.accountName} - ${today}`;
        this.template.querySelector('lightning-record-form').submit(fields);
    }

    handleSuccess(event) {
        this.isLoading = false;
        const evt = new ShowToastEvent({
            title: 'Quote created',
            message: 'Quote has been successfully created.',
            variant: 'success',
        });
        this.dispatchEvent(evt);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: 'Quote',
                actionName: 'view'
            }
        });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }
}