import { LightningElement, api, wire, track } from 'lwc';
import getAllLeasesUnderGroup from '@salesforce/apex/RETL_AccountMetricsController.getAllLeasesUnderGroup';

export default class retlGetAllLeases extends LightningElement {
    @api recordId;
    @track leaseData = [];

    columns = [
    {
        label: 'Lease Number',
        fieldName: 'linkName',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'OrderNumber' },
            target: '_blank'
        }
    },
    {
        label: 'Account Name',
        fieldName: 'accountLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'accountName' },
            target: '_blank'
        }
    },
    { label: 'Start Date', fieldName: 'EffectiveDate', type: 'date' },
    { label: 'End Date', fieldName: 'EndDate', type: 'date' },
    { label: 'Rent Per Month', fieldName: 'RETL_Rent_Per_Month__c', type: 'currency' },
    { label: 'Status', fieldName: 'RETL_Status__c' }
];


@wire(getAllLeasesUnderGroup, { groupId: '$recordId' })
wiredLeases({ error, data }) {
    if (data) {
        this.leaseData = data.map(row => ({
            ...row,
           linkName: `/lightning/r/Order/${row.Id}/view`,
           OrderNumber: row.OrderNumber,
            accountLink: row.AccountId ? `/lightning/r/Account/${row.AccountId}/view` : null,
        accountName: row.Account?.Name || '—'
        }));
    } else if (error) {
        console.error('Error fetching leases:', error);
    }
}


}