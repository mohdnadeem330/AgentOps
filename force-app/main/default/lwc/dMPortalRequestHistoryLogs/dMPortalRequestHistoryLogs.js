import { LightningElement, api, wire } from 'lwc';
import getCaseHistoryRecords from '@salesforce/apex/AuditLogsController.getCaseHistoryRecords';

export default class DMPortalRequestHistoryLogs extends LightningElement {
    @api recordId; 
    caseHistory = [];
    columns = [
        { label: 'When', fieldName: 'createdDateFormatted' },
        { label: 'Who', fieldName: 'createdByName' },
        { label: 'What', fieldName: 'fieldChanged' },
        { label: 'Description', fieldName: 'description', wrapText:true }
    ];
    connectedCallback() {
        this.loadCaseHistory();
    }
    loadCaseHistory() {
        getCaseHistoryRecords({ caseId: this.recordId })
            .then(result => {
                this.caseHistory = result;
            })
            .catch(error => {
                console.error('Error retrieving case history:', error);
            });
    }
}