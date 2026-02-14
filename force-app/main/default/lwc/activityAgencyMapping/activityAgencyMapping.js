import { LightningElement, api, track } from 'lwc';
import getAllAgency from '@salesforce/apex/ActivityController.getAllAgency';
import saveActivityMapping from '@salesforce/apex/ActivityController.saveActivityMapping';
import getSelectedAgency from '@salesforce/apex/ActivityController.getSelectedAgency';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

const columns = [
    { label: 'Account Name', fieldName: 'Name' },
    {
        label: '',
        fieldName: 'Id',
        initialWidth: 5,
        cellAttributes: {
            class: 'column-id'
        }
    }
];

export default class ActivityAgencyMapping extends NavigationMixin(LightningElement) {
    @api recordId;

    columns = columns;
    @track data = [];
    @track openModal = false;
    @track selectedDatatableRows = [];
    @track emailCheckBox = false;
    @track isLoading = false;
    @track accountField = '';

    // Load agency data when component is connected
    async connectedCallback() {
        await this.getAccountData();
    }

    // Load all agencies from Apex
    async getAccountData() {
        this.isLoading = true;
        try {
            const result = await getAllAgency();
            this.data = result;
        } catch (error) {
            this.showToast('Error', 'Failed to load agencies', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Search agencies by account name
    async handleSearch() {
        const accountInput = this.template.querySelector('[data-id="accountField"]');
        const searchValue = accountInput ? accountInput.value : '';

        this.isLoading = true;
        try {
            const result = await getAllAgency({ accountName: searchValue });
            this.data = result;
            await this.getSelectedAccounts();
        } catch (error) {
            this.showToast('Error', 'Search failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Load selected agencies for the current record
    async getSelectedAccounts() {
        try {
            const selected = await getSelectedAgency({ recordId: this.recordId });
            this.selectedDatatableRows = selected.map(item => item.Agency__c);
        } catch (error) {
            this.showToast('Error', 'Failed to load selected agencies', 'error');
        }
    }

    // Called when rows are selected in the datatable
    handleRowAction(event) {
        this.selectedDatatableRows = event.detail.selectedRows.map(row => row.Id);
    }

    // Handle the email toggle
    handleCheckBox(event) {
        this.emailCheckBox = event.target.checked;
    }

    // Save the selected agencies
    async handleSaveButton() {
        this.isLoading = true;

        try {
            const result = await saveActivityMapping({
                activityID: this.recordId,
                accountIDs: this.selectedDatatableRows,
                emailFlag: this.emailCheckBox
            });

            if (result === 'success') {
                this.showToast('Success', 'Agency was added successfully', 'success');
            } else {
                this.showToast('Failure', 'Unable to add agency: ' + result, 'error');
            }

            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.navigateToRecordPage();
        } catch (error) {
            this.showToast('Error', 'Unexpected error occurred', 'error');
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    // Show toast message
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Navigate back to the record view
    navigateToRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'BrokerActivities__c',
                actionName: 'view'
            }
        });
    }

    // Open modal and preload selected agencies
    OpenModal() {
        this.openModal = true;
        this.getSelectedAccounts();
    }

    // Invoked from external button/actions
    @api invoke() {
        this.OpenModal();
    }

    // Close the modal
    closeModal() {
        this.openModal = false;
    }
}