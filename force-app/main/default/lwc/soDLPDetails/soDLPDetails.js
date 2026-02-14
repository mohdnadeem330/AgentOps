import { LightningElement ,api} from 'lwc';
import getSODetails from '@salesforce/apex/SODLPDetailController.getSODetails';
import getVisitDetails from '@salesforce/apex/SODLPDetailController.getVisitDetails';
import getCaseDetails from '@salesforce/apex/SODLPDetailController.getCaseDetails';
import { NavigationMixin } from 'lightning/navigation';

const actions = [
    { label: 'View Details', name: 'details' },
];

export default class SoDLPDetails extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName='SalesOrder__c';
    soDetail;
    visitDetailList;
    caseDetailList;
    activeSections = ['SO', 'CASE' ,'VISIT'];

    caseColumns = [
        { label: 'Case Number', fieldName: 'CaseNumber', initialWidth: 180 ,hideDefaultActions: true},
        { label: 'Subject', fieldName: 'Subject', hideDefaultActions: true},
        { label: 'Priority', fieldName: 'Priority', hideDefaultActions: true},
        { label: 'Category', fieldName: 'CaseCategory__c', hideDefaultActions: true},
        { label: 'Sub Category', fieldName: 'SubCategory__c', hideDefaultActions: true},
        { label: 'Status', fieldName: 'Status', hideDefaultActions: true},
        { label: 'Created Date', fieldName: 'CreatedDate',  type: 'date', hideDefaultActions: true},
        { label: 'Last Modified Date', fieldName: 'LastModifiedDate',  type: 'date', hideDefaultActions: true},
        {
            type: 'action',
            typeAttributes: { rowActions: actions },
        }
    ];
    
    visitColumns = [
        { label: 'Visit Number', fieldName: 'Name', initialWidth: 180 ,hideDefaultActions: true},
        { label: 'Planned Date', fieldName: 'PlannedDate__c',  type: 'date', hideDefaultActions: true},
        { label: 'Visit Date', fieldName: 'VisitDate__c',  type: 'date', hideDefaultActions: true},
        { label: 'Visit Attended', fieldName: 'VisitAttended__c',  type: 'boolean', hideDefaultActions: true},
        { label: 'Completion Date', fieldName: 'CompletionDate__c',  type: 'date', hideDefaultActions: true},
        { label: 'Completion Status', fieldName: 'Completion_Reason__c',  type: 'text', hideDefaultActions: true},
        { label: 'Vendor Name', fieldName: 'PlannedVendor__c', hideDefaultActions: true},
        { label: 'Visit Status', fieldName: 'Status__c', hideDefaultActions: true},
        {
            type: 'action',
            typeAttributes: { rowActions: actions },
        }
    ];

    connectedCallback(){
        this.loadSODetails();
        this.loadVisitDetails();
        this.loadCaseDetails();
    }


    loadSODetails(){
        getSODetails({recordID :this.recordId })
        .then(data => {
            this.soDetail=data;
            console.log('--- so' + data);
        })
        .catch(error => {
            this.soDetail=undefined;
            console.log('--- so err');
        });
    }

    loadVisitDetails(){
        getVisitDetails({recordID :this.recordId })
        .then(data => {
            this.visitDetailList=data;
            console.log('--- visit' + data);
        })
        .catch(error => {
            this.visitDetailList=undefined;
            console.log('--- visit err');
        });
    }

    loadCaseDetails(){
        getCaseDetails({recordID :this.recordId })
        .then(data => {
            this.caseDetailList=data;
            console.log('--- case' + data);
        })
        .catch(error => {
            this.caseDetailList=undefined;
            console.log('--- case err');
        });
    }

    handleRowAction(event) {
        const row = event.detail.row;
        console.log('row --->' + row)
        this.navigateToDetails(row.Id);
    }

    navigateToDetails(recordId){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        }).then(url => {
            window.open(url, "_blank");
        });
    }
}