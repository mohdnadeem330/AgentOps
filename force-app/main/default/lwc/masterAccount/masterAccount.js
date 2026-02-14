import { LightningElement, api, wire, track } from 'lwc';
import createMasterAccountRecord from '@salesforce/apex/MergeAccount.createMasterAccountRecord';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UserEmail from "@salesforce/schema/User.Email";
import UserEditDuplicateAccount from "@salesforce/schema/User.Edit_Duplicate_Account__c";
import UserViewDuplicateAccount from "@salesforce/schema/User.View_Duplicate_Account__c";
import getDuplicateRecords from '@salesforce/apex/MergeAccount.getDuplicateRecords';

export default class MasterAccount extends LightningElement {
    @api recordId;
    @track WrapperList = []; // Processed data for the UI
    WrapperListData = [];
    selectedRecordId;
    wireddata;
    disabled1 = true;
    disable = false;
    isLoading = true;
    isavailable = false;
    isPhoneNumberVisible = false;
    @track isPopupOpen = false; // To control popup visibility
    @track duplicateRecords = []; // Stores duplicates excluding the selected record
    @track selectedDuplicateRecord = null; // Selected duplicate record in popup
    @track duplicateRecordId;
    showSpinner = false;
    sandbox = false;
    credentialDetails;
    userId = Id;
    @track selectedOption = 'Email';
    @track isEmailChecked = true;
    isAccessMergeAccount = false; 
    @track options = [
        { label: 'Email', value: 'Email' },
        { label: 'EmiratesId', value: 'EmiratesId' },
        { label: 'Passport', value: 'Passport' },
        { label: 'Phone Number', value: 'PhoneNumber' },
    ];

    @wire(getRecord, { recordId: Id, fields: [UserEditDuplicateAccount, UserEmail, UserViewDuplicateAccount] })
    userDetails({ error, data }) {
        if (data) {
            const UserEditAccess = data.fields.Edit_Duplicate_Account__c.value;
            if (UserEditAccess) {
                this.isPhoneNumberVisible = true;
                this.isAccessMergeAccount = true;
            }
        } else if (error) {
            this.error = error;
        }
    }

    connectedCallback() {
        this.fetchDuplicates();
    }

    get isSingleRecord() {
        return this.WrapperList.length === 1 || !this.isAccessMergeAccount;
    }

    get isRetryDisable() {
        return !this.isAccessMergeAccount;
    }

    handleOptionChange(event) {
        this.selectedOption = event.target.value;
        this.WrapperList = []; // Clear existing data to avoid conflicts
        console.log('Filter Changed:', this.selectedOption); // Debugging
        this.fetchDuplicates(); // Fetch new data based on filter
    }

    fetchDuplicates() {
        this.isLoading = true;
        console.log('Selected Option:', this.selectedOption); // Log selected filter option
        getDuplicateRecords({ recordId: this.recordId, duplicateField: this.selectedOption })
            .then((result) => {
                console.log('Fetched Records:', result); // Log raw fetched data
                if (result) {
                    this.processData(result); // Process the data
                }
                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error fetching duplicates:', error);
                this.WrapperList = []; // Reset the list on error
                this.isLoading = false;
            });
    }

    processData(WrapperListData) {
        console.log(WrapperListData);
        this.WrapperList = WrapperListData.map((record) => {
            const accountMerge = record.account.Merging_Status__c;
            let isNameExists = '';
            if (record.account.MasterAccount__r != null) {
                isNameExists = record.account.MasterAccount__r.Name;
            }
            console.log('isNameExists:', isNameExists);
            return {
                accountId: record.account.Id,
                accountLink: `/${record.account.Id}`,
                accountName: record.account.Name,
                accountNumber: record.account.AccountNumber__c,
                mergingErrorMessage: record.account.Merging_Error_Message__c,
                accountMerge: accountMerge,  // Store the accountMerge here
                buttonLabel: 'Mark as Duplicate',
                SalesOrderCount: record.salesOrderCount,
                isDuplicateMarked: false,
                isButtonDisabled: record.account.EligibleForMerge__c ? true : false,
                buttonClass: 'enabled-button',
                CustomerAppWebUser: record.account.CustomerAppWebUser__c ?? false,
                NationalIdNumber: record.account.NationalIdNumber__pc,
                SkipLiveAldarReason: record.account.SkipLiveAldarReason__c,
                ERPId: record.account.ERPID__c,
                SapAccountID: record.account.SapAccountID__c,
                CustomerVertical: record.account.CustomerVertical__c,
                CustomerSubType: record.account.CustomerSubType__c,
                BlacklistReason: record.account.BlacklistReason__c,
                ScreeningStatus: record.account.ScreeningStatus__c,
                MaskedPhoneNumber: this.maskLastFourDigits(record.account.PersonMobilePhone),
                DOB: record.account.PersonBirthdate,
                Nationality: record.account.Nationality__pc,
                passportnumber: record.account.PassportNumber__pc,
                passportExipry: record.account.PassportExpiryDate__pc,
                NationalIdExpiryDate: record.account.NationalIdExpiryDate__pc,
                SignedKYCFormDate: record.SignedKYCFormDate,
                SignedCISFormDate: record.SignedCISFormDate,
                EligibleforMerge: record.account.EligibleForMerge__c,
                MasterAccount: isNameExists,
                isRetryButtonEnable : (record.account.Merging_Status__c == 'ERP Validation Failure' || record.account.Merging_Status__c == 'Salesforce Merge Failed'),
                MasterAccountId : record.account.MasterAccount__c,
                isCaseAccountId : record.isCaseAccountId
            };
        });
        console.log('Processed WrapperList:', this.WrapperList);
    }

    handleOpenPopup(event) {
        const label = event.target.label;
        if (label === 'Mark as Duplicate') {
            const accountId = event.target.dataset.id;
            this.duplicateRecordId = event.target.dataset.id;
            this.duplicateRecords = this.WrapperList.filter(record => record.accountId !== accountId); //&& !record.isButtonDisabled
            this.isPopupOpen = true;
        } else {
            console.log('cancel merging clicked');
        }
    }

    handleClosePopup() {
        this.isPopupOpen = false;
        this.selectedDuplicateRecord = null;
    }

    handleDuplicateSelection(event) {
        this.selectedDuplicateRecord = event.target.value;
    }

    handleMarkAsDuplicate(event) {
        const accountId = event.target.dataset.id;

        this.WrapperList = this.WrapperList.map((record) => {
            if (record.accountId === accountId) {
                return { ...record, isDuplicateMarked: true };
            }
            return record;
        });

        console.log('Updated WrapperList:', this.WrapperList);
    }


    handleDuplicateSubmit() {
        this.showSpinner = true;
        if (this.selectedDuplicateRecord) {
            //  createMasterAccount({ selectedId: this.selectedDuplicateRecord, recordId: this.recordId })// commented by Amarjeet 
            createMasterAccountRecord({ selectedId: this.selectedDuplicateRecord, duplicateRecordId: this.duplicateRecordId })
                .then((res) => {
                    this.showSpinner = false;
                    this.fetchDuplicates();

                    this.isPopupOpen = false;
                    this.showToast('Success', 'Duplicate record submitted for merge!!', 'success', 'dismissable');
                })
                .catch((error) => {
                    this.showSpinner = false;
                    this.fetchDuplicates();
                    console.error('Error merging duplicate record:', error);
                    this.showToast('Error', error.body?.message || 'An error occurred while merging.', 'error', 'dismissable');
                });
        } else {
            this.showSpinner = false;
            console.error('No duplicate record selected.');
        }
    }

    handleRetryForMerge(event) {
        this.isLoading = true;
        const accountId = event.target.dataset.id;
        let record = this.WrapperList.find(ele=> ele.accountId == accountId);
        console.log(record);
        createMasterAccountRecord({ selectedId: record.MasterAccountId, duplicateRecordId: accountId })
        .then((res) => {
            this.fetchDuplicates();

            if(!res.includes('successfully')) {
                this.showToast('Error', res || 'An error occurred while merging.', 'error', 'dismissable');
            } else {
                this.showToast('Success', 'Duplicate record submitted for merge!!', 'success', 'dismissable');
            }
        }).catch((error) => {
            this.fetchDuplicates();
            console.error('Error merging duplicate record:', error);
            this.showToast('Error', error.body?.message || 'An error occurred while merging.', 'error', 'dismissable');
        }).finally(()=>{
            this.isLoading = false;
        })
    }

    maskLastFourDigits(number) {
        if (number && number.length > 4) {
            const visiblePart = number.slice(0, -4);
            const maskedPart = '*'.repeat(4);
            return visiblePart + maskedPart;
        }
        return 'N/A';
    }

    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}