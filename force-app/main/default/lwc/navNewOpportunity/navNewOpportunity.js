import { api, LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";

import CUSTOMER_FIELD from '@salesforce/schema/HexaBPM__Service_Request__c.HexaBPM__Customer__c';
import CUSTOMER_NAME_FIELD from '@salesforce/schema/HexaBPM__Service_Request__c.HexaBPM__Customer__r.Name';
import SALES_ORDER_FIELD from '@salesforce/schema/HexaBPM__Service_Request__c.SalesOrder__c';

import checkOpportunity from '@salesforce/apex/NewRecordController.checkOpportunity';
import getAccount from '@salesforce/apex/NewRecordController.getAccount';

export default class NavNewOpportunity extends NavigationMixin(LightningElement) {
    @api recordId;
    @track custId = '';
    @track custName = '';
    @track soId = '';
    @track isCustomerIdFound = false;
    @track isLoading = true;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [CUSTOMER_FIELD, CUSTOMER_NAME_FIELD, SALES_ORDER_FIELD] })
    wireRecordData({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.custId = data.fields.HexaBPM__Customer__c.value;
            this.custName = data.fields.HexaBPM__Customer__r.value.fields.Name.value;
            this.soId = data.fields.SalesOrder__c.value;
            console.log('custId>>>' + this.custId + '>>>soId>>>' + this.soId);
            
            if (this.custId != undefined && this.custId != null && this.custId != '' && !this.isCustomerIdFound) {
                this.getAccountRecord(this.custId);
                this.isCustomerIdFound = true;
            }
        }
    }

    connectedCallback() {
        let rcId = this.recordId && this.recordId != null ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
        console.log('rcId>>>' + rcId);
    }

    // renderedCallback() {
    //     rcId = this.recordId && this.recordId != null ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
    //     console.log('rcId>>>' + rcId);
    // }

    async getAccountRecord(rcId) {
        this.isLoading = true;
        let isOpportunityCreated = false;
        await checkOpportunity({
            srId: this.recordId
        }).then(result => {
            if (result == true) {
                isOpportunityCreated = true;
                const evt = new ShowToastEvent({
                    title: 'Opportunity is alreday created.',
                    variant: 'info',
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }).catch(error => {
            console.error('error', error);
            this.isLoading = false;
        })
        if (isOpportunityCreated == false) {
            await getAccount({
                rId: rcId
            }).then(result => {
                let acc = JSON.parse(JSON.stringify(result));
                let todayDate = new Date()
                todayDate = todayDate.toISOString().split('T')[0];
                let dVal = {
                    AccountId: acc.Id,
                    StageName: 'Meeting',
                    CloseDate: todayDate,
                    Name: this.custName + ' - ' + todayDate,
                    DealType__c: 'Standard',
                    BookingType__c: 'Aldar Square',
                    AgentType__c: 'Direct',
                    DeliveryMethod__c: 'Courier',
                    SalesOrder__c: this.soId,
                    ServiceRequest__c: this.recordId
                }
                if (acc.IsPersonAccount) {
                    dVal.Contact__c = acc.PersonContactId;
                } else {
                    dVal.Contact__c = acc.Contacts[0].Id;
                }
                this.openRecord(dVal, 'Opportunity');
            }).catch(error => {
                console.error('error', error);
                this.isLoading = false;
            })
        }
    }

    openRecord(dVal, tObjName) {
        this.isLoading = false;
        const defaultValues = encodeDefaultFieldValues(dVal);
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: tObjName,
                actionName: 'new'
            },
            state: {
                count: '1',
                nooverride: '1',
                defaultFieldValues: defaultValues
            }
        });
    }
}