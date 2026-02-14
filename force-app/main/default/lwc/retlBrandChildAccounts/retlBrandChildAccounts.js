import { LightningElement, api, wire } from 'lwc';
import getBrandsViaJunction from '@salesforce/apex/RETL_ChildAccountsController.getBrandsViaJunction';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class BrandChildAccounts extends NavigationMixin(LightningElement) {
    @api recordId;
    brandAccounts = [];
    error;
    wiredResult;

    columns = [
        {
            label: 'Account Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        { label: 'Account Number', fieldName: 'AccountNumber' },
        { label: 'Status', fieldName: 'RETL_Status__c' },
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

    @wire(getBrandsViaJunction, { groupId: '$recordId' })
    wiredBrandData(result) {
        this.wiredResult = result;
        const { data, error } = result;

        if (data) {
            this.brandAccounts = data.brandRecords.map(acc => ({
                ...acc,
                recordLink: `/lightning/r/Account/${acc.Id}/view`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.brandAccounts = [];
        }
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                objectApiName: 'Account',
                actionName: action
            }
        });
    }

   /* handleNewBrand() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `ParentId=${this.recordId},Type=Brand`
            }
        });
    }*/

    refreshData() {
        return refreshApex(this.wiredResult);
    }
}