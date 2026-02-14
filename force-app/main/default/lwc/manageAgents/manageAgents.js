import { api, LightningElement, track, wire } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getContacts from '@salesforce/apex/BrokerAgentsController.getContacts';
//import updateContactAgentStatus from '@salesforce/apex/BrokerAgentsController.updateContactAgentStatus';
//import updateUserAgentStatus from '@salesforce/apex/BrokerAgentsController.updateUserAgentStatus';
import updateContactAgentStatus from '@salesforce/apex/BrokerAgentsWithoutSharingController.updateContactAgentStatus';
import updateUserAgentStatus from '@salesforce/apex/BrokerAgentsWithoutSharingController.updateUserAgentStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import BrokerType_FIELD from '@salesforce/schema/Contact.BrokerType__c';
import CustomerLocation_FIELD from '@salesforce/schema/Lead.CustomerLocation__c';
import Contact_OBJECT from '@salesforce/schema/Contact';
import Lead_OBJECT from '@salesforce/schema/Lead';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import resetPassword from '@salesforce/apex/BrokerAgentsController.resetPassword';
// import checkUserOnboarded from '@salesforce/apex/ALD_trailheadappOnboardTM_Restriction.checkUserOnboarded';
// Added by Moh Sarfaraj for BPE-71
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class ManageAgents extends LightningElement {

    currentPage = 1;
    pageSize = 10;

    // Added by Moh Sarfaraj for BPE-71
    get isDesktop() {
        return FORM_FACTOR === 'Large';
    }

      //Filter js Start Here// 
	fillter = resourcesPath + '/ALDARResources/svg/fillter.svg';
    buttonClicked;
    @track cssClass = 'filters-items';
    @track iconClass = 'filters-title';
    @track iconName = ''; 
    handleToggleClick() {
        this.buttonClicked = !this.buttonClicked;
        this.iconClass = this.buttonClicked ? 'filters-title addbg' : 'filters-title';
        this.cssClass = this.buttonClicked ? 'filters-items showfillter' : 'filters-items';
        this.iconName = this.buttonClicked ? 'utility:check' : '';
    } 
    //Filter js End Here// 
    showAgentsCannotbeAdded = false;
    @track isModalOpen = false;
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    listIcon = resourcesPath + "/ALDARResources/svg/ListIcon.svg";
    @track isGeneratePasswordModalOpen;

    @track agentsList;
    @track ids;
    @api gridData = [];
    @api filteredData = [];
    @api newData = false;
    @api action;
    @api rowData;
    @api realMobile;
    @api realEmail;
    @track active;
    @track userEmail;
    @track roleSearch = '';
    @track regionSearch = '';
    @track searchAgent = '';
    @track rolesOptions = [{ label: '', value: '' }];
    @track regionOptions = [{ label: '', value: '' }];
    @api newData1 = false;
    @api newData2 = false;
    @track showSpinner = false;
    @wire(getObjectInfo, { objectApiName: Contact_OBJECT })
    contactMetadata;

    @wire(getObjectInfo, { objectApiName: Lead_OBJECT })
    leadMetadata;

    @wire(getPicklistValues,
        {
            recordTypeId: '$contactMetadata.data.defaultRecordTypeId',
            fieldApiName: BrokerType_FIELD
        }
    )
    brokerTypePicklist(data, error) {
        if (data && data.data && data.data.values) {
            data.data.values.forEach(objPicklist => {
                this.rolesOptions.push({
                    label: objPicklist.label,
                    value: objPicklist.value
                });
            });
            this.newData1 = true;

        } else if (error) {
        }
    };

    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: CustomerLocation_FIELD
        }
    )
    regionPicklist(data, error) {
        if (data && data.data && data.data.values) {
            data.data.values.forEach(objPicklist => {
                this.regionOptions.push({
                    label: objPicklist.label,
                    value: objPicklist.value
                });
            });
            this.newData2 = true;

        } else if (error) {
        }
    };

    async connectedCallback() {

        this.getContactsData();
    }

    resetAll() {
        this.filteredData = [...this.gridData];;
        this.roleSearch = '';
        this.regionSearch = '';
        this.searchAgent = '';
    }

    updateSearch() {

        this.filteredData = [...this.gridData];;
        let allSearchFields = this.template.querySelectorAll('.agentFilters');
        for (let j = 0; j < allSearchFields.length; j++) {
            console.log(allSearchFields[j].value);
            console.log(allSearchFields[j].dataset.id);
            if (allSearchFields[j].value != undefined && allSearchFields[j].value != '') {
                if (allSearchFields[j].dataset.id === 'roleSearch') {
                    this.roleSearch = allSearchFields[j].value;
                }
                if (allSearchFields[j].dataset.id === 'regionSearch') {
                    this.regionSearch = allSearchFields[j].value;
                }
                if (allSearchFields[j].dataset.id === 'searchAgent') {
                    this.searchAgent = allSearchFields[j].value;
                }
            }



        }
        /*
                if (event.target.dataset.id === 'roleSearch') {
                    this.roleSearch = event.target.value;
                }
                if (event.target.dataset.id === 'regionSearch') {
                    this.regionSearch = event.target.value;
                }
                if (event.target.dataset.id === 'searchAgent') {
                    this.searchAgent = event.target.value;
                }
        */
        regex = new RegExp(this.roleSearch, 'i');
        this.filteredData = this.filteredData.filter(
            row => regex.test(row.role)
        );

        regex = new RegExp(this.regionSearch, 'i');
        this.filteredData = this.filteredData.filter(
            row => regex.test(row.region)
        );

        var regex = new RegExp(this.searchAgent, 'i');
        this.filteredData = this.filteredData.filter(
            row => (regex.test(row.firstName) || regex.test(row.lastName) || regex.test(row.emailId) || regex.test(row.country)
                || regex.test(row.phoneNumber) || regex.test(row.agencyName))
        );

        this.newData = true;

    }

    async getContactsData(event) {
        this.showSpinner = true;
        await getContacts()
            .then(result => {
                this.agentsList = result;

                this.gridData = [];
                this.agentsList.forEach(element => {

                    var status = element.contactRecord.AgentStatus__c;
                    if (element.userRecord !=null && element.userRecord.IsActive == true) {
                        if(element.userRecord.BlockedFromBackend__c == false){
                            status = 'Active';
                        }
                    }
                    this.gridData.push({
                        title: element.contactRecord.Salutation,
                        agencyName: element.contactRecord.Account.Name,
                        agencyId: element.contactRecord.AccountId,
                        firstName: element.contactRecord.FirstName,
                        lastName: element.contactRecord.LastName,
                        emailId: element.realEmail,
                        role: element.contactRecord.BrokerType__c,
                        birthdate: element.contactRecord.Birthdate,
                        region: element.contactRecord.Account.BillingState,
                        country: element.contactRecord.Account.BillingCountry,
                        phoneNumber: element.realMobile,
                        phoneNumberWithoutCountryCode: element.contactRecord.MobilePhone__c,
                        countryCode: element.contactRecord.MobileCountryCode__c,
                        active: status,
                        edit: '',
                        generatePassword: '',
                        agentStatus: '',
                        contactId: element.contactRecord.Id,
                        userId: element.userRecord !=null ? element.userRecord.Id : '',
                        realEmail: element.realEmail,
                        realMobile: element.realMobile,
                        username: element.userRecord !=null ? element.userRecord.Username : '',
                        agentId: element.contactRecord.AgentID__c,
                        emiratesID: element.contactRecord.NationalIdNumber__c,
                        expiryDate: element.contactRecord.NationalIdExpiryDate__c,
                        //linemanagerName: element.contactRecord.Line_Manager_Name__c,
                        //linemanagerEmail: element.contactRecord.Line_Manager_Email__c
                        // Added By Moh Sarfaraj for BPE-110
                        primaryOwner : element.contactRecord.PrimaryOwner__c,
                        primaryAgencyAdmin : element.contactRecord.PrimaryAgencyAdmin__c,
                        // Added By Moh Sarfaraj for BPM-355
                        blockedFromBackend : element.contactRecord.BlockedFromBackend__c,
                        nationality : element.contactRecord.Nationality__c,

                        // Added By Moh Sarfaraj for BPM-526
                        passportNumber : element.contactRecord.PassportNumber__c,
                        passportExpiryDate : element.contactRecord.PassportExpiryDate__c,
                    });
                });

                this.filteredData = [...this.gridData];
                this.newData = true;
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
            });
    }

    async generatePasswordRowAction(event) {
        // if(event.detail.row.active == 'Blocked' && event.detail.row.blockedFromBackend == true){
        //     this.showToast('Error', 'Cannot perform the action, because User is Blocked from Backend', 'error');
        // }
        // else 
        if (event.detail.row.active == 'Pending Verification') {
            this.showToast('Error', 'Cannot perform the action, because User Status is Pending Verification', 'error');
        } 
        else if(event.detail.row.active == 'Rejected' && event.detail.action.name !== "Edit")
        {
            this.showToast('Error', 'Cannot perform the action, because User Status is Rejected', 'error');
        }
        else {
            if (event.detail.action.name === "generatePassword") {
                var tempData = event.detail.row;
                this.ids = tempData.userId;
                this.userEmail = tempData.realEmail;
                this.isGeneratePasswordModalOpen = true;
            }
            if (event.detail.action.name === "Edit") {
                this.action = 'edit';
                this.isModalOpen = true;
                this.rowData = event.detail.row;
            } else {
                this.action = '';
            }
            if (event.detail.action.name === "agentStatus") {
                var rowInfo = event.detail.row;
                this.ids = rowInfo.contactId;
                this.userEmail = rowInfo.userEmail;
                this.active = rowInfo.active;

                this.showSpinner = true;

                await updateUserAgentStatus({ userId: rowInfo.userId, checkboxVal: this.active }).then(result => {

                    updateContactAgentStatus({ userId: this.ids, checkboxVal: this.active }).then(result => {

                        this.showToast('Success', 'Change Status request submitted successfully. if the status is not changed immediately it might take several minutes.', 'Success');

                        setTimeout(() => {
                            this.getContactsData();
                            this.showSpinner = false;
                        }, 3000);

                    }).catch(error => {
                        console.log('updateContactAgentStatus: ' + JSON.stringify(error));

                        if (error.body.pageErrors[0] != null) {
                            this.showToast('Error', error.body.pageErrors[0].message, 'error');
                        }

                        console.log(error);
                        this.showSpinner = false;

                    })

                }).catch(error => {
                    console.log(JSON.stringify(error));

                    if (error.body.pageErrors[0] != null) {
                        this.showToast('Error', error.body.pageErrors[0].message, 'error');
                    }
                    if (error.body.fieldErrors != null && error.body.fieldErrors.IsActive[0] != null) {
                        this.showToast('Error', error.body.fieldErrors.IsActive[0].message, 'error');
                    }
                    this.showSpinner = false;

                })
            }

            if (event.detail.action.name === "reset") {
                var rowInfo = event.detail.row;
                rowInfo.userId;

                resetPassword({ userId: rowInfo.userId }).then(result => {
                    this.showToast('Success', 'Reset Password Email sent to the user.', 'success');

                }).catch(error => {
                    this.showToast('Error', JSON.stringify(error.body.pageErrors[0].message), 'error');
                });
            }
        }
    }

    gridColumns = [
        {
            type: 'text',
            fieldName: 'agencyName',
            label: 'Agency Name',
            initialWidth: 130,
            cellAttributes: { class: 'agency-name-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'firstName',
            label: 'First Name',
            initialWidth: 100,
            cellAttributes: { class: 'first-name-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'lastName',
            label: 'Last Name',
            initialWidth: 100,
            cellAttributes: { class: 'last-name-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'username',
            label: 'Username',
            initialWidth: 250,
            cellAttributes: { class: 'email-id-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'emailId',
            label: 'Email ID',
            initialWidth: 250,
            cellAttributes: { class: 'email-id-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'agentId',
            label: 'Agent ID',
            initialWidth: 100,
            cellAttributes: { class: 'agent-id-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'role',
            label: 'Role',
           initialWidth: 120,
            cellAttributes: { class: 'role-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'region',
            label: 'Region',
            initialWidth: 130,
            cellAttributes: { class: 'region-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'country',
            label: 'Country',
            initialWidth: 130,
            cellAttributes: { class: 'country-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'phoneNumber',
            label: 'Phone Number',
            initialWidth: 140,
            cellAttributes: { class: 'phone-number-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'active',
            label: 'Status',
            initialWidth: 130,
            cellAttributes: { class: 'active-cell' /*important for reponsive */ }

        },
        {

            label:  this.isDesktop ? 'Actions' : 'Edit', // updated by Moh Sarfaraj for BPE-71
            fieldName: 'edit',
            initialWidth: 40,
            type: 'button',
            typeAttributes: {
                iconName: 'action:edit',

                name: 'Edit',
                title: 'Edit',
                disabled: false,
                value: 'Edit'

            },
            cellAttributes: {
                class: 'custom-table-icon edit-icon',
                alignment: `left`
            }
        },
        {
            label: this.isDesktop ? '' : 'Generate Password', // updated by Moh Sarfaraj for BPE-71
            fieldName: 'generatePassword',
            initialWidth: 40,
            type: 'button',
            typeAttributes: {
                iconName: 'action:password_unlock',

                name: 'generatePassword',
                title: 'Generate Password',
                disabled: false,
                value: 'Edit'

            },
            cellAttributes: {
                class: 'custom-table-icon generate-password',
                alignment: `left`
            }
        },
        {

            label: this.isDesktop ? '' : 'Enable/Disable Agent', // updated by Moh Sarfaraj for BPE-71
            fieldName: 'agentStatus',
            initialWidth: 40,
            type: 'button',
            typeAttributes: {
                iconName: 'action:user',

                name: 'agentStatus',
                title: 'Enable/Disable Agent',
                disabled: false,
                value: 'Edit'

            },
            cellAttributes: {
                class: 'custom-table-icon logout',
                alignment: `left`
            }
        },
        {

            label: this.isDesktop ? '' : 'Reset Password', // updated by Moh Sarfaraj for BPE-71
            fieldName: 'reset',
            initialWidth: 40,
            type: 'button',
            typeAttributes: {
                iconName: 'action:reset_password',

                name: 'reset',
                title: 'Reset Password',
                disabled: false,
                value: 'Edit'

            },
            cellAttributes: {
                class: 'custom-table-icon reset-password-icon',
                alignment: `left`
            }
        }

    ];



    async addAgent() {
        
        // this.showSpinner = true;
        this.trailhead_feature = 'Add Agent';
        this.trailhead_Project = '';


        // Commented by Moh Sarfaraj for BRP-5539

        //trailhead_Project is sent to apex to consolidate all the assigned trailmixes
        // await checkUserOnboarded({
        //     featureSelected: this.trailhead_feature,
        //     projectName: this.trailhead_Project
        // })
        // .then(result => {
        //         this.showSpinner = false;
        //         let userOnboarded = result.userOnboarded;
        //         if(userOnboarded){
        //             this.openModal();
        //         }else{
        //             this.userTrailMixes = result.onBoardtrailMixRecords;
        //             this.showAgentsCannotbeAdded = true;
        //         }
        //     })
        //     .catch(error => {
        //     console.log('error: ' + JSON.stringify(error));
        // });

        this.openModal();

    }
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.action = 'add';
        this.isModalOpen = true;
    }
    closeModal(event) {

        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.isModalOpen = event.detail.isOpen;

        setTimeout(() => {
            this.getContactsData();
        }, 3000);


    }
    generatePasswordModalOpen(event) {

        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        //  this.isModalOpen = event.detail.isOpen;
        this.isGeneratePasswordModalOpen = event.detail;


    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }

    closeAgentsCannotBookModal(event)
    {
        this.showAgentsCannotbeAdded = event.detail.isOpen;
    }

    // Add a method to calculate the total number of pages:
    get totalPages() {
        if (this.filteredData) {
            return Math.ceil(this.filteredData.length / this.pageSize);
        }
        return 0;
    }

    // Add methods to handle Previous and Next button clicks:
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

    // Modify your tableData to display only the items for the current page:
    get paginatedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        if (!this.filteredData) {
            return [];
        } else {
            return this.filteredData.slice(start, end);
        }
    }
}