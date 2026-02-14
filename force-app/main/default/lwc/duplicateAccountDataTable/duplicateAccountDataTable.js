import { LightningElement, api, track } from 'lwc';
import { FlowNavigationFinishEvent, FlowAttributeChangeEvent, FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationPauseEvent } from 'lightning/flowSupport';

export default class DuplicateAccountDataTable extends LightningElement {
    @api accountData = []; // Incoming from Flow

    // These are exposed back to Flow
    @api selectedAccount; // Selected record
    @api actionName;      // Action string

    @track selectedRecord = null;

    columns = [
        { label: 'Name', fieldName: 'Name', initialWidth: 200},
        { label: 'Account Number', fieldName: 'AccountNumber__c', initialWidth: 170 },
        { label: 'Fasttrack Account', fieldName: 'FastTrackedAccount__c', initialWidth: 170 },
        { label: 'Date of Birth', fieldName: 'PersonBirthdate' , initialWidth: 170, type: "date-local", typeAttributes: {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    }},
        { label: 'Passport Number', fieldName: 'PassportNumber__pc' , initialWidth: 170},
        { label: 'Nationality', fieldName: 'Nationality__pc' , initialWidth: 170},
        { label: 'National Id', fieldName: 'NationalIdNumber__pc' , initialWidth: 170},
        { label: 'KYC Validity', fieldName: 'KYC_Validity_Status__c', initialWidth: 170 },
        { label: 'Resident Status', fieldName: 'ResidentStatus__pc' , initialWidth: 170},
        { label: 'Customer Type', fieldName: 'CustomerType__c' , initialWidth: 170},
        { label: 'Customer Sub Type', fieldName: 'CustomerSubType__c', initialWidth: 170 }
    ];

    get isActionDisabled() {
        return this.selectedRecord === null;
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRecord = selectedRows.length > 0 ? selectedRows[0] : null;

        // Set selected record to flow output
        this.selectedAccount = this.selectedRecord;
    }

    handleBack() {
        // Fire Flow Navigation Event for "Back"
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    handleSubmitMerge() {
        this.setActionAndDispatch('SubmitMergeRequest');
    }

    handleRequestSameEmail() {
        this.setActionAndDispatch('RequestForSameEmail');
    }

    setActionAndDispatch(action) {
        //if (!this.selectedRecord) return;

        this.actionName = action;

        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
    }
}