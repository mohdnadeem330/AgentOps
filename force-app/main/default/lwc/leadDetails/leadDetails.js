import { LightningElement, track, api, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import getUserDetails from '@salesforce/apex/BrokerLeadController.getUserDetails';
import getMapDetails from '@salesforce/apex/BrokerLeadController.getMapDetails';
import getsObjectType from '@salesforce/apex/BrokerLeadController.getsObjectType';
import getLeadById from '@salesforce/apex/BrokerLeadController.getLeadById';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class LeadDetails extends LightningElement {

    @track showSpinner = false;
    @track isModalOpen = false;
    @track gridData = [];
    @track array = [];
    @api accountDetils;
    @track contactUserId;
    userId = Id;
    @track newData = false;
    @track leadDetils;
    urlStateParameters = null;
    allDetails;
    sObjectRecord;
    sObjectRecordType;
    @api recordId;
    contactId;
    @api action;
    childRecordId;
    @track showAppointmentBookingModal = false;
    @api new;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {

        console.log(currentPageReference);
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log(currentPageReference);
            //this.setParametersBasedOnUrl();
        }
    }

    async expandCollapseRowsRightSide(event) {

        if (event.detail.action.name === "Appointment") {
            this.action = 'appointment';
            this.childRecordId = event.detail.row.ID;
            this.showAppointmentBookingModal = true;

        } else if (event.detail.action.name === "Edit") {
            this.childRecordId = event.detail.row.ID;
            this.action = 'edit';
            this.isModalOpen = true;
        }

    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }

    async getData() {
        this.showSpinner = true;
        this.newData = false;
        this.gridData = [];
        this.array = [];

        await getMapDetails().then(result => {
            console.log('getMapDetails: ' + JSON.stringify(result));

            for (const i in result) {

                if (result[i].column0 == this.recordId) {
                    this.allDetails = result[i];
                }
            }

            this.allDetails.children.forEach(async element => {

                if (this.new != null && this.new.leadId == element.Id) {

                    this.gridData.push(
                        {
                            ID: this.new.leadId,
                            Property: this.new.property,
                            PropertyUsage: this.new.propertyUsage,
                            Bedrooms: this.new.numberOfBeds,
                            Events: this.new.events,
                            Financing: this.new.financing,
                            Mortgage: this.new.mortgage,
                            UnitType: this.new.unitType,
                            PurposeofUse: this.new.purposeOfUse,
                            BuyorRent: this.new.buyRent,
                            SalesType: this.new.salesType,
                            LeadNumber: element.LeadNumber__c,
                            Actions: ''
                        });

                } else {
                    this.gridData.push(
                        {
                            ID: element.Id,
                            Property: element.Project__c,
                            PropertyUsage: element.PropertyUsage__c,
                            Bedrooms: element.NumberOfBedrooms__c,
                            Events: element.Offer1__c,
                            Financing: element.Financing__c,
                            Mortgage: element.Mortgage__c,
                            UnitType: element.UnitType__c,
                            PurposeofUse: element.PurposeOfUse__c,
                            BuyorRent: element.BuyRent__c,
                            SalesType: element.SalesType__c,
                            LeadNumber: element.LeadNumber__c,
                            Actions: ''
                        });
                }
            });

        })
            .catch(error => {
                this.showToast('Error', JSON.stringify(error), 'error');
                console.log(JSON.stringify(error));
            });

        let result = this.allDetails;
        console.log('this.result: ' + JSON.stringify(result));
        console.log('this.new: ' + JSON.stringify(this.new));
        console.log('this.recordId: ' + JSON.stringify(this.recordId));

        await getsObjectType({ recordID: this.recordId })
            .then(data => {

                console.log('data: ' + JSON.stringify(data));

                for (var key in data) {

                    console.log('sObjectRecordType: ' + this.sObjectRecordType);
                    console.log('sObjectRecord: ' + JSON.stringify(this.sObjectRecord));

                    if (this.sObjectRecordType != null) {
                        if (this.sObjectRecord.createdDate > data[key].createdDate) {
                            this.sObjectRecord = data[key];
                            this.sObjectRecordType = key;
                        } else {
                            this.sObjectRecord = data[key];
                            this.sObjectRecordType = key;
                        }
                    } else {
                        this.sObjectRecord = data[key];
                        this.sObjectRecordType = key;
                    }
                }

            })
            .catch(error => {
                this.showToast('Error', JSON.stringify(error), 'error');
                console.log(JSON.stringify(error));
                this.sObjectRecordType = undefined;
                this.sObjectRecord = undefined;
                this.isLoading = false;
            });



        if (this.sObjectRecordType == 'Contact') {

            this.accountDetils = this.sObjectRecord;
            this.contactId = this.sObjectRecord.Id;
            this.array.push(
                {
                    id: 1,
                    column1Label: "Title",
                    column1Value: this.sObjectRecord.Salutation,
                    column2Label: "Customer First Name:",
                    column2Value: this.sObjectRecord.FirstName,
                    column3Label: "Customer Last Name:",
                    column3Value: this.sObjectRecord.LastName,
                },
                {
                    id: 1,
                    column1Label: "Emirates ID:",
                    column1Value: this.sObjectRecord.Account.NationalIdNumber__pc,
                    column2Label: "Phone Number:",
                    column2Value: '',
                    column3Label: "Region:",
                    column3Value: this.sObjectRecord.Account.AgencyRegion__c,
                },
                {
                    id: 1,
                    column1Label: "City:",
                    column1Value: this.sObjectRecord.MailingCity__c,
                    column2Label: "Country of Residence:",
                    column2Value: this.sObjectRecord.CountryOfResidence__c,
                    column3Label: "Nationality:",
                    column3Value: this.sObjectRecord.Nationality__c,
                },
                {
                    id: 1,
                    column1Label: "Passport Number:",
                    column1Value: this.sObjectRecord.PassportNumber__c,
                    column2Label: "Passport Expiry Date:",
                    column2Value: this.sObjectRecord.PassportExpiryDate__c,
                    column3Label: "WeChatID:",
                    column3Value: "-",
                }/*,
                        {
                            id: 1,
                            column1Label: "Lead Date:",
                            column1Value: this.sObjectRecord.createdDate,
                            column2Label: "",
                            column2Value: "",
                            column3Label: "",
                            column3Value: "",
                        }*/);

        } else if (this.sObjectRecordType == 'Lead') {

            if (this.sObjectRecord != null && this.sObjectRecord != undefined) {
                this.leadDetils = this.sObjectRecord;
                this.recordId = this.sObjectRecord.Id;
            }

            await getLeadById({ recordID: this.recordId }).then((response) => {
                if (response != null) {
                    this.sObjectRecord = response;
                    console.log('--------' + JSON.stringify(this.sObjectRecord));
                }
            }).catch(error => {
                this.showToast('Error', JSON.stringify(error), 'error');
                console.log(JSON.stringify(error));
            });

            this.array.push(
                {
                    id: 1,
                    column1Label: "Title",
                    column1Value: this.sObjectRecord.Salutation,
                    column2Label: "Customer First Name:",
                    column2Value: this.sObjectRecord.FirstName,
                    column3Label: "Customer Last Name:",
                    column3Value: this.sObjectRecord.LastName,
                },
                {
                    id: 1,
                    column1Label: "Emirates ID:",
                    column1Value: this.sObjectRecord.NationalId__c,
                    column2Label: "Phone Number:",
                    column2Value: this.sObjectRecord.MobilePhone,
                    column3Label: "Nationality:",
                    column3Value: this.sObjectRecord.Nationality__c,
                },
                {
                    id: 1,
                    column1Label: "City:",
                    column1Value: this.sObjectRecord.City,
                    column2Label: "Country of Residence:",
                    column2Value: this.sObjectRecord.CountryOfResidence__c,
                    column3Label: "Passport Number:",
                    column3Value: this.sObjectRecord.PassportNumber__c,
                },
                {
                    id: 1,
                    column1Label: "Passport Expiry Date:",
                    column1Value: this.sObjectRecord.PassportExpiryDate__c,
                    column2Label: "WeChatID:",
                    column2Value: "-",
                }
                        /* this field has been commented based on comment in task number 1417,
                        {
                            id: 1,
                            column1Label: "Lead Date:",
                            column1Value: new Date(this.sObjectRecord.CreatedDate).toLocaleString(),
                            column2Label: "",
                            column2Value: "",
                            column3Label: "",
                            column3Value: "",
                        }*/);

        }
        this.showSpinner = false;
        this.newData = true;

    }

    async connectedCallback() {
        this.getData();
    }



    addLead() {
        this.openModal();
        this.action = 'add';
        this.childRecordId = this.recordId;
        //this.recordId = this.contactId;
    }
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal(event) {

        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.showSpinner = true;
        this.gridData = [];
        refreshApex(this.gridData);
        this.getData();
        this.isModalOpen = event.detail.isOpen;
        this.new = event.detail.new;
    }

    closeAppointmentModal(event) {
        this.showAppointmentBookingModal = event.detail.isOpen;
    }
    closeDetailPage() {
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', { detail: { showNavigationTab: true, currentStep: "manage-leads" } }));

        this.dispatchEvent(new CustomEvent('closedetailpage', { detail: { isOpen: false } }));

    }


    gridColumns = [
        {
            type: 'text',
            fieldName: 'Property',
            label: 'Project',
            cellAttributes: { alignment: `center` }
        },
        {
            type: 'text',
            fieldName: 'PropertyUsage',
            label: 'Property Usage',
            cellAttributes: { alignment: `center` }
        },
        {
            type: 'text',
            fieldName: 'Bedrooms',
            label: 'Bedrooms',
            cellAttributes: { alignment: `center` }
        },
        {
            type: 'text',
            fieldName: 'Financing',
            label: 'Financing',
            cellAttributes: { alignment: `center` }
        },
        {
            type: 'text',
            fieldName: 'Mortgage',
            label: 'Mortgage',
            cellAttributes: { alignment: `center` }
        },
        {
            type: 'text',
            fieldName: 'UnitType',
            label: 'Unit Type',
            cellAttributes: { alignment: `center` }
        },
        {
            type: 'text',
            fieldName: 'BuyorRent',
            label: 'Buy or Rent',
            cellAttributes: { alignment: `center` }
        },
        {
            type: 'text',
            fieldName: 'SalesType',
            label: 'Sales Type',
            cellAttributes: { alignment: `center` }
        },
        {

            type: 'text',
            fieldName: 'LeadNumber',
            label: 'Lead Number',
            cellAttributes: { alignment: `center` }
        },
        {

            label: 'Appointment',
            fieldName: 'Actions',
            initialWidth: 100,
            type: 'button',
            typeAttributes: {
                iconName: 'action:log_event',

                name: 'Appointment',
                title: '',
                disabled: false,
                value: 'Appointment'

            },
            cellAttributes: {
                class: 'custom-table-icon with-calendar-icon',
                alignment: `left`
            }
        },
        {

            label: 'Actions',
            fieldName: 'Actions',
            initialWidth: 100,
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
        }

    ];
    get gridDataLength() {
        return this.gridData.length > 0;
    }
}