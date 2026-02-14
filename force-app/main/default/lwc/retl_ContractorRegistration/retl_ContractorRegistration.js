import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createAccount from '@salesforce/apex/RETL_ContractorPortalRegistration.createAccount';
import getPicklistValues from '@salesforce/apex/DM_UtilityController.getPicklistValues';
import { NavigationMixin } from 'lightning/navigation';
import pageUrl from '@salesforce/resourceUrl/reCAPTCHAv2';
import isReCAPTCHAValid from '@salesforce/apex/RETL_ContractorPortalRegistration.isReCAPTCHAValid';
import HomeImages from "@salesforce/resourceUrl/HomeImages";
import { loadStyle } from 'lightning/platformResourceLoader';
import ExternalStyle from "@salesforce/resourceUrl/ExternalStyle";
import validateMobileNumber from '@salesforce/apex/RETL_ContractorPortalRegistration.validateMobileNumber';
import EmailValidation from '@salesforce/apex/RETL_ContractorPortalRegistration.validateEmailId';
import DM_AccountRole from '@salesforce/label/c.DM_AccountRole';
import emiratesDocumentLabel from '@salesforce/label/c.Dm_DocumentTypeEmirates';
import getCurrentUser from '@salesforce/apex/RETL_SuperAppPageController.getCurrentUser';
import getCurrentUserContactRole from '@salesforce/apex/RETL_SuperAppPageController.getCurrentUserContactRole';
import getDocument from '@salesforce/apex/RETL_SuperAppPageController.getDocument';

import updateAccount from '@salesforce/apex/RETL_ContractorPortalRegistration.updateAccount';
export default class Retl_ContractorRegistration extends NavigationMixin(LightningElement) {
    handleStepBlur(event) {
        const stepIndex = event.detail.index;
    }
    renderedCallback() {
        Promise.all([
            loadStyle(this, ExternalStyle)
        ])
    }
    Logo = HomeImages + '/Home-Images/DM_logo_login.png';
    Sidebar = HomeImages + '/Home-Images/DM_sidebar.png';
    Done = HomeImages + '/Home-Images/DM_approval.svg';
    Tick = HomeImages + '/Home-Images/DM_thick.svg';
    @track accountobj = new Object();
    @track Contactobj = new Object();
    @track contactRoleObj = new Object();
    @track developementValues = [];
    @track titlevlaues = [];
    @track isLoading = false;
    @track detailspage = true;
    @track uploadpage = false;
    @track termspage = false;
    @track sucesspage = false;
    @track nextNo = 0;
    readOnly = false;
    termsCheckboxvalue = false;
    //@track RoleValues = [];
    @track Emirates = [];
    @track Emiratescontact = [];
    @track accDocumentsadded = '';
    @track isaccountuploaddisable = false;
    @track iscontactuploaddisable = false;
    @track showaccountpill = false;
    allowSubmit;
    @track showcontactpill = false;
    timer;
    @track conDocumentsadded = '';
    @track countryCodeOptions = [];
    AccountFileData;
    ContactFileData;
    //CaptchaInfo
    @track navigateTo;
    captchaToken;
    captchaValid;
    prevBtn = false;
    nextBtn = true;
    submitBtn = false;
    cancelBtn = true;
    isStep1Done = false;
    isStep2Done = false;
    isStep3Done = false;
    minDate;
    maxDateValue
    showPopup = false;
    btnDisable = false;
    isAccountDataChanged = false;
    isVATUpdated = false;
    isTradeLicenseUpdated = false;
    communitiesAdded;
    countryCode;
    @api userExistingDetails;
    emiratesDocumentLabel;
    originalVertical;
    @track originalAccountobj = new Object();
    @track originalContactobj = new Object();
    @track originalContactRoleobj = new Object();
    showRetailRole = false;
    showDMRole = false;
    showDMORRetail = false;
    showDMANDRetailRole = false;
    //retailRoleValues
    constructor() {
        super();
        this.navigateTo = pageUrl;
    }
    captchaLoaded(event) {
        var e = event;
        if (e.target.getAttribute('src') == pageUrl) {
            window.addEventListener("message", (e) => {
                if (e.data.action == "getCAPCAH") {
                    let token = e.data.callCAPTCHAResponse;
                    this.captchaToken = token;
                }
                if (e.data.action == "expiredCaptcha") {
                    this.captchaValid = false;
                    this.captchaToken = null;
                }
            }, false);
        }
    }
    disconnectedCallback() {
        window.removeEventListener('message', function (e) { }, false);
    }
    connectedCallback() {
        //this.getRolevlaues();
        this.getDevelopementValues();
        this.getNationalityValues();
        this.accountobj.sobjectType = 'Account';
        this.Contactobj.sobjectType = 'Contact';
        this.contactRoleObj.sobjectType = 'RETL_Contact_role__c'
        this.gettitlevlaues();
        //this.HandelingTrue();
        //this.showPages();
        this.getCurrentDate();
        this.getEmiratesValues();
        this.getCountryCodeValues();
        this.accountobj.MobileCountryCode__c = '971';
        this.Contactobj.MobileCountryCode__c = '971';


        this.emiratesDocumentLabel = emiratesDocumentLabel;
    }
    get isVerticalDisabled() {
        return this.readOnly ;
    }

    // accessibility: remove from tab order when disabled
    get displayTabIndex() {
        return this.isVerticalDisabled ? '-1' : '0';
    }

    // css class for display element
    get displayClass() {
        return `multi-select-display ${this.isVerticalDisabled ? 'disabled' : ''}`;
    }
    @wire(getCurrentUser)
    wiredUser({ data, error }) {
        if (data) {
            if (data.Name !== 'Contractor Business Portal Site Guest User') {
                this.userExistingDetails = data;
                const contactId = data.ContactId;
                const accountId = data.Contact?.AccountId;

                // Call Apex to get Contact Role
                if (contactId && accountId) {
                    this.fetchContactRole(contactId, accountId);
                    this.loadExistingDocuments(contactId, accountId);
                }
            }

            if (this.userExistingDetails) {
                this.accountobj = { ...this.userExistingDetails.Contact.Account };
                this.originalAccountobj = { ...this.userExistingDetails.Contact.Account };
                this.Contactobj = { ...this.userExistingDetails.Contact };
                this.originalContactobj = { ...this.userExistingDetails.Contact };

                // Prepopulate picklist
                const preselected = this.accountobj.CustomerVertical__c?.split(';') || [];

                this.options = this.options.map(opt => {
                    if (preselected.includes(opt.value)) {
                        opt.selected = true;
                        opt.disabled = opt.value === 'Retail'; // disable Retail when coming from Retail page
                        opt.className = opt.disabled ? 'option selected disabled' : 'option selected';
                    }
                    return opt;
                });

                this.selectedValues = preselected;
                if (this.selectedValues.includes('Retail')) {
                    this.retailRuleApplicable = true;
                    this.showRetailRole = true;
                    this.showDMRole = false;
                    this.showDMANDRetailRole = false;
                    this.showDMORRetail = true;
                }
                else if (this.selectedValues.includes('District Management')) {
                    this.retailRuleApplicable = false;
                    this.showRetailRole = false;
                    this.showDMRole = true;
                    this.showDMANDRetailRole = false;
                    this.showDMORRetail = false;
                }
                else {
                    this.retailRuleApplicable = false;
                }
                this.selectedLabels = preselected.join(', ');
                this.originalVertical = this.accountobj.CustomerVertical__c || '';
                const required = ["District Management", "Retail"];
                if (required.every(v => this.selectedValues.includes(v))) {
                    console.log('Both selected');
                    this.communitiesAdded = this.joinWithAnd(this.selectedValues);
                    this.showRetailRole = false;
                    this.showDMRole = false;
                    this.showDMANDRetailRole = true;
                    this.showDMORRetail = false;
                } else {
                    console.log('Missing one or both');
                }
            }
        } else if (error) {
            console.error('Error fetching user:', error);
            // this.userData = {};
        }
    }
    loadExistingDocuments(contactId, accountId) {
        getDocument({ contactId: contactId, accountId: accountId })
            .then(result => {
                result.forEach(doc => {
                    if (doc.documentType === 'Trade License') {
                        this.showaccountpill = true;
                        this.accDocumentsadded = doc.fileName;
                        this.isaccountuploaddisable = true;
                    }
                    if (doc.documentType === 'Emirates ID Copy') {
                        this.showcontactpill = true;
                        this.conDocumentsadded = doc.fileName;
                        this.iscontactuploaddisable = true;
                    }
                    if (doc.documentType === 'Passport file') {
                        this.showContactPassportPill = true;
                        this.conPassportDocumentsAdded = doc.fileName;
                        this.isPassportUploadDisable = true;
                    }
                    if (doc.documentType === 'Visa file') {
                        this.showContactVisaPill = true;
                        this.conVisaDocumentsAdded = doc.fileName;
                        this.isVisaUploadDisable = true;
                    }
                });
            })
            .catch(error => {
                console.error('ERROR loading documents', error);
            });
    }
    fetchContactRole(contactId, accountId) {
        getCurrentUserContactRole({ contactId: contactId, accountId: accountId })
            .then(result => {
                const safeResult = result ? { ...result } : {};
                this.contactRoleObj = safeResult;
                this.originalContactRoleobj = result || {};
            })
            .catch(error => {
                console.error('Error fetching contact role:', error);
            });
    }

    handleCancelClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/districtMngmt/login'
            }
        });
    }
    get RoleValues() {
        return [
            { label: 'Contractor', value: 'Contractor' },
            { label: 'Consultant', value: 'Consultant' },
            { label: 'Individual', value: 'Individual' },
        ];
    }
    get RoleValues() {
        return DM_AccountRole.split(',').map(role => ({
            label: role.trim(),
            value: role.trim()
        }));
    }

    /*getRolevlaues() {
        getPicklistValues({ objName: 'Account', fldName: 'Role__c' })
            .then(data => {
                this.RoleValues = Object.entries(data).map(([value, label]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    } */



    selectedValues = [];
    selectedLabels = 'Select verticals';
    isOpen = false;
    retailRuleApplicable = false;
    verticalError;
    @track options = [
        { label: 'District Management', value: 'District Management', selected: false, disabled: false, className: 'option' },
        { label: 'Retail', value: 'Retail', selected: false, disabled: false, className: 'option' }

    ];

    @track retailRoleValues = [
        { label: 'Admin', value: 'Admin' },
        { label: 'Operations', value: 'Operations' }

    ];

    toggleDropdown() {
        this.isOpen = !this.isOpen;
    }
    get verticalLabelColor() {
        if (this.selectedLabels === 'Select verticals') {
            return 'verticalLabelColor';
        }
    }


    handleSelect(event) {
        const value = event.currentTarget.dataset.value;
        const option = this.options.find(o => o.value === value);
        if (option.disabled) {
            return;  // prevent unselecting Retail
        }

        this.options = this.options.map(opt => {
            if (opt.value === value && !opt.disabled) {
                opt.selected = !opt.selected;
                opt.className = opt.selected ? 'option selected' : 'option';
            }
            return opt;
        });

        // Collect selected values
        this.selectedValues = this.options.filter(o => o.selected).map(o => o.label);
        this.accountobj = {
            ...this.accountobj,
            CustomerVertical__c: this.selectedValues.join(';')
        };

        // Reset all role sections
        this.showRetailRole = false;
        this.showDMRole = false;
        this.showDMANDRetailRole = false;
        this.showDMORRetail = false;

        // ---- CHECK FINAL SELECTED VALUES ---- //
        const hasRetail = this.selectedValues.includes("Retail");
        const hasDM = this.selectedValues.includes("District Management");

        // Apply rules cleanly
        if (hasRetail && hasDM) {
            // BOTH SELECTED
            this.communitiesAdded = this.joinWithAnd(this.selectedValues);
            this.showDMANDRetailRole = true;
            this.accountobj.Type = "Contractor";
        }
        else if (hasRetail) {
            // ONLY RETAIL
            this.communitiesAdded = "Retail community";
            this.accountobj.Type = "Contractor";
            this.showRetailRole = true;
            this.showDMORRetail = true;
        }
        else if (hasDM) {
            // ONLY DISTRICT MANAGEMENT
            this.communitiesAdded = "District Management community";
            this.showDMRole = true;
            this.showDMORRetail = true;
        }

        if (this.selectedValues.includes('Retail')) {
            this.retailRuleApplicable = true;
        }
        else {
            this.retailRuleApplicable = false;
        }
        this.selectedLabels = this.selectedValues.length
            ? this.selectedValues.join(', ')
            : 'Select vertical';
        this.validateVerticalChange();
    }

    validateVerticalChange() {
        const current = this.accountobj.CustomerVertical__c || '';
        const original = this.originalVertical || '';

        // No change?
        if (current === original) {
            this.verticalError = 'Please update vertical.';
            this.showRetailRole = false;
            this.showDMRole = false;
            this.showDMANDRetailRole = false;
            this.showDMORRetail = false;
            return false;
        }
        this.verticalError = '';
        this.isAccountDataChanged = true;
        return true;
    }
    gettitlevlaues() {
        getPicklistValues({ objName: 'Contact', fldName: 'Salutation' })
            .then(data => {
                this.titlevlaues = Object.entries(data).map(([value, label]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }

    getDevelopementValues() {
        getPicklistValues({ objName: 'Contact', fldName: 'CountryOfResidence__c' })
            .then(data => {
                this.developementValues = Object.entries(data).map(([value, label]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }

    nationalityOptions;
    getNationalityValues() {
        getPicklistValues({ objName: 'Contact', fldName: 'Nationality__c' })
            .then(data => {
                this.nationalityOptions = Object.entries(data).map(([value, label]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }

    getEmiratesValues() {
        getPicklistValues({ objName: 'Contact', fldName: 'CustomerLocation__c' })
            .then(data => {
                this.EmiratesOptions = Object.entries(data).map(([value, label]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }
    getCountryCodeValues() {
        getPicklistValues({ objName: 'Account', fldName: 'MobileCountryCode__c' })
            .then(data => {
                this.countryCodeOptions = Object.entries(data).map(([label, value]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
    }
    handleCaptchaReceived(event) {
        if (event.detail.data === true) {
            this.allowSubmit = true;
        }
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this.accountobj[name] = value;
        if (name === 'RegistrationNumber__c') {
                    this.isTradeLicenseUpdated = true;
                    this.accountobj['ECSS_Trade_License_Number__c'] = value;
        }
        if (this.userExistingDetails) {
            this.accountobj[name] = value;
            this.accountobj['Id'] = this.userExistingDetails.Contact.AccountId;
            const currentAcc = this.accountobj;
            const originalAcc = this.originalAccountobj;
            // No change?
            if (currentAcc === originalAcc) {
                this.isAccountDataChanged = false;
                this.isVATUpdated = false;
                this.isTradeLicenseUpdated = false;
            }
            else {
                this.isAccountDataChanged = true;
                if (name === 'UAEVATRegisterNumber__c') {
                    this.isVATUpdated = true;
                }
                if (name === 'RegistrationNumber__c') {
                    this.isTradeLicenseUpdated = true;
                    this.accountobj['ECSS_Trade_License_Number__c'] = value;
                }
            }
        }
        // if (name === 'CustomerVertical__c') {
        //     if (value === 'Retail') {
        //         this.accountobj['Type'] = 'Contractor';
        //         this.communitiesAdded = 'Retail community'
        //     }
        //     if (value === 'District Management') {
        //         this.communitiesAdded = 'District Management community'
        //     }
        //     if (value.includes(';')) {
        //         let values = value.split(";");
        //         this.communitiesAdded = joinWithAnd(values);
        //     }
        //     console.log('communitiesAdded', communitiesAdded);
        // }



        if (name === 'MobileCountryCode__c') {
            this.accountobj.MobileNumber1__c = '';

            const phoneInput = this.template.querySelector('[data-id="accountPhone"]');
            if (phoneInput) {
                phoneInput.classList.remove('checkinput');
            }
        }
        if (name === 'MobileNumber1__c') {
            this.accountobj.MobileNumber__c = '971-' + value;
        }
        if (name === 'PlaceOfRegistration__c') {
            this.accountobj.RETL_LicenseIssuedCity__c = value;
        }
    }

    joinWithAnd(values) {
        if (!values || values.length === 0) return "";
        if (values.length === 1) return values[0];
        if (values.length === 2) return values.join(" and ");

        // More than 2 values
        return values.slice(0, -1).join(", ") + " and " + values[values.length - 1];
    }
    handelaccountfile(event) {
        const accountFiles = event.target.files[0];
        const allowedTypes = ['application/pdf', 'image/png', 'image/jpeg'];

        if (accountFiles && allowedTypes.includes(accountFiles.type)) {
            var Accountreader = new FileReader()
            Accountreader.onload = () => {
                var base64 = Accountreader.result.split(',')[1]
                this.AccountFileData = {
                    'fileName': accountFiles.name,
                    'Base64': base64,
                }
                if (this.AccountFileData && Object.keys(this.AccountFileData).length > 0) {
                    this.accDocumentsadded = accountFiles.name;
                    this.isaccountuploaddisable = true;
                    this.showaccountpill = true;
                }
            }
            Accountreader.readAsDataURL(accountFiles);
        } else {
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('warning', 'Only .pdf, .png and .jpg file types are allowed.', '', 3000);
            return;
        }
    }
    isContactDataChanged = false;
    isContactEmailUpdated = false;
    handleInputContactChange(event) {
        const { name, value } = event.target;
        this.Contactobj[name] = value;
        if (this.userExistingDetails) {
            this.Contactobj['Id'] = this.userExistingDetails.ContactId;
            const currentCon = this.Contactobj;
            const originalCon = this.originalContactobj;
            // No change?
            if (currentCon === originalCon) {
                this.isContactDataChanged = false;
                this.isContactEmailUpdated = true;
            }
            else {
                this.isContactDataChanged = true;
                let type = event.currentTarget.dataset.key;
                if (name === 'Email') {
                    this.isContactEmailUpdated = true;
                }
                if (type === 'passport') {
                    this.showContactPassportPill = false;
                    this.conPassportDocumentsAdded = '';
                    this.isPassportUploadDisable = false;
                }
                if (type === 'visa') {
                    this.showContactVisaPill = false;
                    this.conVisaDocumentsAdded = '';
                    this.isVisaUploadDisable = false;
                }
                if (type === 'emirates') {
                    this.showcontactpill = false;
                    this.conDocumentsadded = '';
                    this.iscontactuploaddisable = false;
                }
                if (type === 'tradelicence') {
                    this.showaccountpill = false;
                    this.accDocumentsadded = '';
                    this.isaccountuploaddisable = false;
                }

            }
        }
        if (name === 'MobileCountryCode__c') {
            this.Contactobj.MobilePhone__c = '';

            const phoneInput = this.template.querySelector('[data-id="contactPhone"]');
            if (phoneInput) {
                phoneInput.classList.remove('checkinput');
            }
        }
        if (name === 'MobilePhone__c') {
            this.Contactobj.MobilePhone = '971-' + value;
        }
    }
    handelContactFiles(event) {
        const contactFiles = event.target.files[0];
        const allowedTypes = ['application/pdf', 'image/png', 'image/jpeg'];
        if (contactFiles && allowedTypes.includes(contactFiles.type)) {
            var Contactreader = new FileReader()
            Contactreader.onload = () => {
                var base64 = Contactreader.result.split(',')[1]
                this.ContactFileData = {
                    'fileName': contactFiles.name,
                    'Base64': base64
                }
                if (this.ContactFileData && Object.keys(this.ContactFileData).length > 0) {
                    this.conDocumentsadded = contactFiles.name;
                    this.iscontactuploaddisable = true;
                    this.showcontactpill = true;
                }
            }
            Contactreader.readAsDataURL(contactFiles);
        } else {
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('warning', 'Only .pdf, .png and .jpg file types are allowed.', '', 3000);
            return;
        }
    }
    handleInputContactRoleChange(event) {
        const { name, value } = event.target;
        this.contactRoleObj[name] = value;
        if (this.userExistingDetails && this.originalContactRoleobj) {
            this.contactRoleObj['Id'] = this.originalContactRoleobj.Id;
            const currentCon = this.contactRoleObj;
            const originalCon = this.originalContactRoleobj;
            // No change?
            if (currentCon === originalCon) {
               // this.isContactRoleDataChanged = false;
                contactRoleObj = null;
            }

        }

    }
    isVisaUploadDisable = false;
    isPassportUploadDisable = false;
    showContactPassportPill = false;
    showContactVisaPill = false;
    conPassportDocumentsAdded
    conVisaDocumentsAdded;
    @track contactRetailPassportFileData;
    @track contactRetailVisaFileData;
    handelContactRetailPassportFiles(event) {
        const contactFiles = event.target.files[0];
        const allowedTypes = ['application/pdf', 'image/png', 'image/jpeg'];
        let documentType = event.currentTarget.dataset.documenttype;
        if (contactFiles && allowedTypes.includes(contactFiles.type)) {
            var Contactreader = new FileReader()
            Contactreader.onload = () => {
                var base64 = Contactreader.result.split(',')[1]
                this.contactRetailPassportFileData = {
                    'fileName': contactFiles.name,
                    'Base64': base64,
                    'documentType': documentType
                }
                if (this.contactRetailPassportFileData && Object.keys(this.contactRetailPassportFileData).length > 0) {
                    this.conPassportDocumentsAdded = contactFiles.name;
                    this.isPassportUploadDisable = true;
                    this.showContactPassportPill = true;
                }
            }
            Contactreader.readAsDataURL(contactFiles);
        } else {
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('warning', 'Only .pdf, .png and .jpg file types are allowed.', '', 3000);
            return;
        }
    }

    handelContactRetailVisaFiles(event) {
        const contactFiles = event.target.files[0];
        const allowedTypes = ['application/pdf', 'image/png', 'image/jpeg'];
        let documentType = event.currentTarget.dataset.documenttype;
        if (contactFiles && allowedTypes.includes(contactFiles.type)) {
            var Contactreader = new FileReader()
            Contactreader.onload = () => {
                var base64 = Contactreader.result.split(',')[1]
                this.contactRetailVisaFileData = {
                    'fileName': contactFiles.name,
                    'Base64': base64,
                    'documentType': documentType
                }
                if (this.contactRetailVisaFileData && Object.keys(this.contactRetailVisaFileData).length > 0) {
                    this.conVisaDocumentsAdded = contactFiles.name;
                    this.isVisaUploadDisable = true;
                    this.showContactVisaPill = true;
                }
            }
            Contactreader.readAsDataURL(contactFiles);
        } else {
            this.template.querySelector('c-common-toast-msg-for-communities').
                showToast('warning', 'Only .pdf, .png and .jpg file types are allowed.', '', 3000);
            return;
        }
    }
    handelVisaPillRomeval() {
        this.isVisaUploadDisable = false;
        this.contactRetailVisaFileData = null;
        this.conVisaDocumentsAdded = '';
        this.showContactVisaPill = false;
    }
    handelPassportPillRomeval() {
        this.isPassportUploadDisable = false;
        this.contactRetailPassportFileData = null;
        this.conPassportDocumentsAdded = '';
        this.showContactPassportPill = false;
    }

    handelNext() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if (!this.validateVerticalChange()) {
            return;
        }
        if (isInputsCorrect) {
            this.nextNo = this.nextNo + 1;

            if (this.nextNo == 1) {
                this.prevBtn = true;
                this.nextBtn = true;
                this.submitBtn = false;
                this.uploadpage = true;
                this.detailspage = false;
                this.template.querySelector('.step2').classList.add('slds-is-active');
                this.template.querySelector('.step1').classList.remove('slds-is-active');
                this.isStep1Done = true;
            }
            if (this.nextNo == 2) {
                this.submitBtn = true;
                this.nextBtn = false;
                this.readOnly = true;
                this.detailspage = true;
                this.uploadpage = true;
                this.termspage = true;
                this.isStep2Done = true;
                this.template.querySelector('.step2').classList.remove('slds-is-active');
                this.template.querySelector('.step3').classList.add('slds-is-active');
            }
            if (this.nextNo == 3) {
                this.termspage = false;
                this.sucesspage = true;
                this.template.querySelector('.step3').classList.remove('slds-is-active');
            }
        }
    }

    handelPervious() {
        if (this.nextNo > 0) {
            this.nextNo = this.nextNo - 1;
        }
        if (this.nextNo == 0) {
            this.uploadpage = false;
            this.detailspage = true;
            this.readOnly = false;
            this.prevBtn = false;
            this.submitBtn = false;
            this.nextBtn = true;
            this.isStep1Done = false;
            this.template.querySelector('.step1').classList.add('slds-is-active');
            this.template.querySelector('.step2').classList.remove('slds-is-active');
        }
        if (this.nextNo == 1) {
            this.uploadpage = true;
            this.detailspage = false;
            this.termspage = false;
            this.readOnly = false;
            this.submitBtn = false;
            this.nextBtn = true;
            this.isStep2Done = false;
            this.template.querySelector('.step2').classList.add('slds-is-active');
            this.template.querySelector('.step3').classList.remove('slds-is-active');
        }
        if (this.nextNo == 2) {
            this.termspage = true;
            this.sucesspage = false;
        }
        if (this.nextNo == 3) {
            this.termspage = false;
            this.sucesspage = true;
        }
    }
    termsCheckbox(event) {
        this.termsCheckboxvalue = event.target.checked;
    }
    handelaccountpillromeval() {
        this.isaccountuploaddisable = false;
        this.AccountFileData = null;
        this.accDocumentsadded = '';
        this.showaccountpill = false;
    }
    handelcontactpillromeval() {
        this.iscontactuploaddisable = false;
        this.AccountFileData = null;
        this.conDocumentsadded = '';
        this.showcontactpill = false;
    }
    async handleSave() {
        this.isLoading = true;
        await isReCAPTCHAValid({ tokenFromClient: this.captchaToken }).then(data => {
            this.captchaValid = data;
        });
        if (!this.termsCheckboxvalue) {
            this.isLoading = false;
            this.template.querySelector('c-common-toast-msg-for-communities').showToast('error', 'Please check the terms and conditions to proceed', '', 6000);
        }
        else if (!this.captchaValid) {
            this.isLoading = false;
            this.template.querySelector('c-common-toast-msg-for-communities').showToast('error', 'Please Verify Captcha', '', 6000);
        }
        else {
            this.accountobj.BillingCountry = 'United Arab Emirates';
            this.template.querySelector('.step3').classList.remove('slds-is-active');
            this.btnDisable = true;
            if (this.userExistingDetails && (this.isAccountDataChanged || this.isContactDataChanged)) {
                updateAccount({
                    accountobj: this.accountobj, Contactobj: this.Contactobj, contactRoleObj: this.contactRoleObj, accountFile: JSON.stringify(this.AccountFileData),
                    contactFile: JSON.stringify(this.ContactFileData), contactRetailPassportFile: JSON.stringify(this.contactRetailPassportFileData), contactRetailVisaFile: JSON.stringify(this.contactRetailVisaFileData),
                    isTradeLicenseUpdated: this.isTradeLicenseUpdated,
                    isVATUpdated: this.isVATUpdated,
                    isContactEmailUpdated: this.isContactEmailUpdated
                })
                    .then(data => {
                        this.readOnly = false;
                        this.detailspage = false;
                        this.uploadpage = false;
                        this.termspage = false;
                        this.sucesspage = true;
                        this.isStep3Done = true;
                        this.submitBtn = false;
                        this.nextBtn = false;
                        this.prevBtn = false;
                        this.cancelBtn = false;
                        this.isLoading = false;
                        this.template.querySelector('.step3').classList.remove('slds-is-active');
                    })
                    .catch(error => {
                        this.btnDisable = false;
                        this.isLoading = false;
                        //console.log('error while saving-->' + error.message);
                        this.template.querySelector('c-common-toast-msg-for-communities').showToast('error', error.body.message, '', 6000);
                    });
            }
            else {
                createAccount({
                    accountobj: this.accountobj, Contactobj: this.Contactobj, contactRoleObj: this.contactRoleObj, accountFile: JSON.stringify(this.AccountFileData),
                    contactFile: JSON.stringify(this.ContactFileData), contactRetailPassportFile: JSON.stringify(this.contactRetailPassportFileData), contactRetailVisaFile: JSON.stringify(this.contactRetailVisaFileData)
                })
                    .then(data => {
                        this.readOnly = false;
                        this.detailspage = false;
                        this.uploadpage = false;
                        this.termspage = false;
                        this.sucesspage = true;
                        this.isStep3Done = true;
                        this.submitBtn = false;
                        this.nextBtn = false;
                        this.prevBtn = false;
                        this.cancelBtn = false;
                        this.isLoading = false;
                        this.template.querySelector('.step3').classList.remove('slds-is-active');
                    })
                    .catch(error => {
                        this.btnDisable = false;
                        this.isLoading = false;
                        //console.log('error while saving-->' + error.message);
                        this.template.querySelector('c-common-toast-msg-for-communities').showToast('error', error.body.message, '', 6000);
                    });
            }

        }
    }
    navaigateToLoginPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/districtMngmt/login'
            }
        });
    }

    getCurrentDate() {
        const today = new Date();
        let month = today.getMonth() + 1;
        let day = today.getDate();
        const year = today.getFullYear();

        if (month < 10) {
            month = '0' + month;
        }
        if (day < 10) {
            day = '0' + day;
        }

        this.minDate = `${year}-${month}-${day}`;
        this.maxDateValue = `${year}-${month}-${day}`;
    }
    handleClickHere() {
        this.showPopup = true;
    }
    closePopup() {
        this.showPopup = false;
    }
    handlebackToHome() {
        window.open('/business/secur/logout.jsp', "_self");
    }
    openEmail() {
        window.location.href = 'mailto:dcportalsupport@aldar.com';
    }
    handleEmailOnBlur(event) {
        this.isLoading = true;
        const val = event.currentTarget.value;
        const input = event.currentTarget;
        if (val) {
            EmailValidation({ email: val }).then(res => {
                if (res == true) {
                    try {
                        input.setCustomValidity('');
                        input.classList.add('checkinput');
                        this.isLoading = false;
                    } catch (e) {
                        //console.log(e.message)
                    }
                } else {
                    input.classList.remove('checkinput');
                    input.setCustomValidity('Email is not valid');
                    this.isLoading = false;
                }
                input.reportValidity();
            }).catch(err => {
                //console.log('error-->', err);
                this.isLoading = false;
            });

        } else {
            this.isLoading = false;
        }

    }
    handlePhoneOnBlur(event) {
        this.isLoading = true;
        const val = event.currentTarget.value;
        const input = event.currentTarget;

        if (input.dataset.id === 'accountPhone') {
            this.countryCode = this.template.querySelector('[data-id="accountCountryCode"]').value;
        } else if (input.dataset.id === 'contactPhone') {
            this.countryCode = this.template.querySelector('[data-id="contactCountryCode"]').value;
        }

        const phoneNumber = this.countryCode + val;

        if (phoneNumber.length >= 9) {
            validateMobileNumber({ mobNo: phoneNumber }).then(res => {
                try {
                    if (res.IsValid == 'Yes') {
                        input.setCustomValidity('');
                        input.classList.add('checkinput');
                        this.isLoading = false;
                    } else {
                        input.classList.remove('checkinput');
                        input.setCustomValidity('Phone number is not valid');
                        this.isLoading = false;
                    }
                    input.reportValidity();
                } catch (e) {
                    //console.log(e.message)

                }
            }).catch(err => {
                //console.log('error-->', err);
                this.isLoading = false;
            });
        } else {
            this.isLoading = false;
        }
    }
}