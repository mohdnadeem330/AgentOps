import { LightningElement, api, wire } from 'lwc';
import getFilteredChildAccounts from '@salesforce/apex/RETL_ChildAccountsController.getFilteredChildAccounts';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class GetTradelincensesChild extends NavigationMixin(LightningElement) {
    @api recordId;
    tradeAccounts;
    error;

    columns = [
        {
            label: 'Account Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        { label: 'Account Number', fieldName: 'AccountNumber' },
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

    @wire(getFilteredChildAccounts, { parentId: '$recordId', typeValue: 'Trade License' })
    wiredAccounts({ data, error }) {
        if (data) {
            this.tradeAccounts = data.map(acc => ({
                ...acc,
                recordLink: `/lightning/r/Account/${acc.Id}/view`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.tradeAccounts = undefined;
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
                    actionName: 'edit'
                }
            });
        }
    }

    handleNewTrade() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `ParentId=${this.recordId},Type=Trade License`
            }
        });
    }

    refreshData() {
        return refreshApex(this.tradeAccounts);
    }
}