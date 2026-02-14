import { LightningElement, wire, track } from 'lwc';
import searchCases from '@salesforce/apex/AccountSearchController.searchCases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountSearch extends LightningElement {
    @track accountName = '';
    @track cases = [];
    @track columns = [
        {
            label: 'Case Number',
            fieldName: 'CaseLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'CaseNumber' },
                target: '_blank'
            }
        },
        { label: 'Record Type', fieldName: 'RecordTypeName', type: 'text' },
        { label: 'Account Name', fieldName: 'AccountLink', type: 'url', typeAttributes: { label: { fieldName: 'AccountName' }, target: '_blank' } },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Project', fieldName: 'Project', type: 'text' },
        { label: 'Legal Case Category', fieldName: 'LegalCaseCategory', type: 'text' },
        { label: 'Owner Name', fieldName: 'OwnerName', type: 'text' },
        { label: 'Batch', fieldName: 'Batch', type: 'text' },
        { label: 'Unit', fieldName: 'UnitLink',type: 'url', typeAttributes: { label: { fieldName: 'Unit' }, target: '_blank' }},
        { label: 'Unit Text', fieldName: 'UnitText', type: 'text' }
    ];

    handleAccountNameChange(event) {
        this.accountName = event.target.value;
        if (!this.accountName) {
            this.cases = [];
            return;
        }
    }

    handleSearch(event) {
        this.accountName = event.target.value;
        searchCases({ accountName: this.accountName })
            .then(result => {
                this.cases = result.map(caseRecord => ({
                    ...caseRecord,
                    RecordTypeName: caseRecord.RecordType.Name,
                    AccountName: caseRecord.Account.Name,
                    AccountLink: '/' + caseRecord.AccountId,
                    CaseLink: '/' + caseRecord.Id, // Add the link to the case record
                    OwnerName: caseRecord.Owner.Name,
                    Project: caseRecord.Project__c, // Include Project__c
                    LegalCaseCategory: caseRecord.Legal_Case_Category__c, // Include Legal_Case_Category__c
                    Batch: caseRecord.Batch__c,
                    UnitLink: caseRecord.Unit__r ? '/' + caseRecord.Unit__r.Id : null,
                    Unit: caseRecord.Unit__r ? caseRecord.Unit__r.Name : null,
                    UnitText: caseRecord.Unit_text__c
                }));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                console.error('Error searching cases:', error);
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}