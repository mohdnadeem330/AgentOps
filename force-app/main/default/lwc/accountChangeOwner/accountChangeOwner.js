import { api, LightningElement, track, wire } from 'lwc';
import getAllAccountsRecords from '@salesforce/apex/AccountChangeOwnerController.getAllAccountsRecords';
import updateSelectedAccounts from '@salesforce/apex/AccountChangeOwnerController.updateSelectedAccounts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent, FlowNavigationBackEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

const data = [
    { id: 1, accountNumber: 'L000123', name: 'Billy Simonns', agencyRegion: 40, owner: 'billy@salesforce.com' },
    { id: 2, accountNumber: 'L000124', name: 'Kelsey Denesik', agencyRegion: 35, owner: 'kelsey@salesforce.com' },
    { id: 3, accountNumber: 'L000125', name: 'Kyle Ruecker', agencyRegion: 50, owner: 'kyle@salesforce.com' },
    { id: 4, accountNumber: 'L000126', name: 'Krystina Kerluke', agencyRegion: 37, owner: 'krystina@salesforce.com' },
];

const columns = [
    { label: 'Account Number', fieldName: 'accountNumber', sortable: true },
    { label: 'Name', fieldName: 'name', sortable: true },
    { label: 'Agency Region', fieldName: 'agencyRegion', sortable: true, cellAttributes: { alignment: 'left' }, },
    { label: 'Registration Number', fieldName: 'registrationNumber', sortable: true },
    { label: 'Broker Manager', fieldName: 'owner', sortable: true },
];

export default class AccountChangeOwner extends NavigationMixin(LightningElement) {

    @api ids;
    @track user;
    @track data = [];
    columns = columns;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    @track newData = false;
    @track selectedRecordsToUpdate;
    @track agencyRegion;
    @track errorDialog = false;
    @track errorDetails;
    @track additionalWhereClauseForUser = 'ProfileName__c = \'Broker Manager\'';
    @track owner;
    @track accountWhereClause = [];
    @track registrationNumber;

    get agencyRegionOptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Domestic', value: 'Domestic' },
            { label: 'International', value: 'International' }
        ];
    }
    // Used to sort columns
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    getSelectedRecord(event) {
        const selectedRows = event.detail.selectedRows;

        console.log('number of selected rows: ' + selectedRows.length);
        console.log(selectedRows);

        this.selectedRecordsToUpdate = selectedRows;

        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++) {
            console.log('You selected: ' + JSON.stringify(selectedRows[i]));
        }
    }

    async connectedCallback() {

        await getAllAccountsRecords()
            .then(result => {
                console.log(result);

                result.forEach(element => {
                    this.data.push({
                        id: element.Id,
                        accountNumber: element.AccountNumber__c,
                        name: element.Name,
                        agencyRegion: element.AgencyRegion__c,
                        registrationNumber: element.RegistrationNumber__c,
                        owner: element.Owner.Name
                    });
                });
            })
            .catch(error => {
                console.log(error);
            })

        this.newData = true;

    }

    handleSelected(event) {
        var objectname = event.detail.ObjectName;
        console.log('objectname: ' + objectname);

        if (objectname === "User") {
            this.user = { Name: event.detail.Name, Id: event.detail.Id }
            console.log('user: ' + this.user);
        }

    }

    async handleChange(event) {
        var value = event.target.value;
        this.accountWhereClause = [];

        if (event.target.dataset.id === 'AgencyRegion') {
            this.agencyRegion = value;

            if (this.agencyRegion == 'All') {
                this.agencyRegion = '';
            }

        } else if (event.target.dataset.id === 'owner') {
            this.owner = value;

        } else if (event.target.dataset.id === 'registrationNumber') {
            this.registrationNumber = value;
        }

        if (this.owner != null && this.owner != '') {
            this.accountWhereClause.push('Owner.Name Like \'%' + this.owner + '%\'');
        }
        if (this.agencyRegion != null && this.agencyRegion != '') {
            this.accountWhereClause.push('AgencyRegion__c = \'' + this.agencyRegion + '\'');
        }
        if (this.registrationNumber != null && this.registrationNumber != '') {
            this.accountWhereClause.push('RegistrationNumber__c Like \'%' + this.registrationNumber + '%\'');
        }

        await getAllAccountsRecords({ searchFor: this.accountWhereClause })
            .then(result => {
                console.log(result);

                this.data = [];

                result.forEach(element => {
                    this.data.push({
                        id: element.Id,
                        accountNumber: element.AccountNumber__c,
                        name: element.Name,
                        agencyRegion: element.AgencyRegion__c,
                        registrationNumber: element.RegistrationNumber__c,
                        owner: element.Owner.Name
                    });
                });
            })
            .catch(error => {
                console.log(error);
            })

        this.newData = true;
    }

    async handleClick(event) {
        console.log(this.selectedRecordsToUpdate);
        console.log('selectedRecordsToUpdate: ' + JSON.stringify(this.selectedRecordsToUpdate));

        this.errorDialog = false;
        this.errorDetails = '';

        if (this.user == null || this.user.Id == null) {
            this.errorDetails += 'New Owner Not Selected';
        }
        else if (this.selectedRecordsToUpdate == null || this.selectedRecordsToUpdate.length == 0) {
            this.errorDetails += 'No Account Selected';
        }

        if (this.errorDetails != null && this.errorDetails != '') {

            const event = new ShowToastEvent({
                title: 'Missing Data',
                variant: 'error',
                message: this.errorDetails,
            });
            this.dispatchEvent(event);

            this.errorDialog = true;

        } else {

            await updateSelectedAccounts({ selectedAccounts: this.selectedRecordsToUpdate, userId: this.user.Id })
                .then(result => {
                    console.log(result);

                    getAllAccountsRecords({ searchFor: this.accountWhereClause })
                        .then(result => {
                            console.log(result);

                            this.data = [];

                            result.forEach(element => {
                                this.data.push({
                                    id: element.Id,
                                    accountNumber: element.AccountNumber__c,
                                    name: element.Name,
                                    agencyRegion: element.AgencyRegion__c,
                                    registrationNumber: element.RegistrationNumber__c,
                                    owner: element.Owner.Name
                                });
                            });
                        })
                        .catch(error => {
                            console.log(error);
                        })

                    const event = new ShowToastEvent({
                        title: 'Success',
                        variant: 'success',
                        message: 'Broker Manager (' + this.user.Name + ') Assigned to the Selected Accounts.',
                    });
                    this.dispatchEvent(event);

                    this.newData = true;
                })
                .catch(error => {
                    console.log(error);
                    const event = new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: JSON.stringify(error.body.pageErrors[0].message),
                    });
                    this.dispatchEvent(event);
                })
        }
    }

    handleBack() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    removeError() {
        this.errorDialog = false;
        this.errorDetails = [];
    }
}