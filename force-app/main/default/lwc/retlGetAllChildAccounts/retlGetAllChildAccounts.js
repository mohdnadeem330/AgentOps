import { LightningElement, api, wire } from 'lwc';
import getFilteredChildAccounts from '@salesforce/apex/RETL_ChildAccountsController.getFilteredChildAccounts';
import { NavigationMixin } from 'lightning/navigation';

export default class GetChildAccounts extends NavigationMixin(LightningElement) {
     @api showNewButton = false;
    @api recordId;
    customerAccounts;
    error;
    columns = [
        {
            label: 'Account Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        { label: 'Account Number', fieldName: 'AccountNumber__c' },
        { label: 'Type', fieldName: 'Type' },
        { label: 'Currency', fieldName: 'CurrencyIsoCode' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Edit', name: 'edit' }
                ]
            }
        }
    ];

    @wire(getFilteredChildAccounts, { parentId: '$recordId', typeValue: 'Customer' })
    wiredAccounts({ data, error }) {
        if (data) {
            this.customerAccounts = data.map(acc => ({
                ...acc,
                recordLink: `/lightning/r/Account/${acc.Id}/view`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.customerAccounts = undefined;
        }
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        } else if (action === 'edit') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: 'Account',
                    //actionName: 'edit'
                }
            });
        }
    }

    /*handleNewCustomer() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `ParentId=${this.recordId},Type=Customer`
            }
        });
    }*/

    refreshData() {
        return refreshApex(this.customerAccounts);
    }
}