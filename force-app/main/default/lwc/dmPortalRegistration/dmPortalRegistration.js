import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createAccount from '@salesforce/apex/DM_PortalRegistrationCtrl.createAccount';
import getPicklistValues from '@salesforce/apex/DM_UtilityController.getPicklistValues';
import { NavigationMixin } from 'lightning/navigation';
import pageUrl from '@salesforce/resourceUrl/reCAPTCHAv2';
import isReCAPTCHAValid from '@salesforce/apex/DM_PortalRegistrationCtrl.isReCAPTCHAValid';
import HomeImages from "@salesforce/resourceUrl/HomeImages";
import { loadStyle } from 'lightning/platformResourceLoader';
import ExternalStyle from "@salesforce/resourceUrl/ExternalStyle";
import validateMobileNumber from '@salesforce/apex/DM_PortalRegistrationCtrl.validateMobileNumber';
import EmailValidation from '@salesforce/apex/DM_PortalRegistrationCtrl.validateEmailId';
import DM_AccountRole from '@salesforce/label/c.DM_AccountRole';

export default class DmPortalRegistration extends NavigationMixin(LightningElement) {
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
    showPopup = false;
    btnDisable = false;  
    countryCode;

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
        this.getDevelopementValues();
        this.accountobj.sobjectType = 'Account';
        this.Contactobj.sobjectType = 'Contact';
        this.gettitlevlaues();
        //this.getRolevlaues();
        //this.HandelingTrue();
        //this.showPages();    
        this.getCurrentDate();
        this.getEmiratesValues();
        this.getCountryCodeValues();
        this.accountobj.MobileCountryCode__c = '971';
        this.Contactobj.MobileCountryCode__c = '971';
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

        if (name === 'MobileCountryCode__c') {
            this.accountobj.MobileNumber1__c = '';

            const phoneInput = this.template.querySelector('[data-id="accountPhone"]');
            if (phoneInput) {
                phoneInput.classList.remove('checkinput');
            }
        }
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

    handleInputContactChange(event) {
        const { name, value } = event.target;
        this.Contactobj[name] = value;

        if (name === 'MobileCountryCode__c') {
            this.Contactobj.MobilePhone__c = '';

            const phoneInput = this.template.querySelector('[data-id="contactPhone"]');
            if (phoneInput) {
                phoneInput.classList.remove('checkinput');
            }
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
                    'Base64': base64,
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

    handelNext() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

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
        } else if (!this.captchaValid) {
            this.isLoading = false;
            this.template.querySelector('c-common-toast-msg-for-communities').showToast('error', 'Please Verify Captcha', '', 6000);
        }
        else {
            this.accountobj.BillingCountry = 'United Arab Emirates';
            this.template.querySelector('.step3').classList.remove('slds-is-active');
            this.btnDisable = true;
            createAccount({
                accountobj: this.accountobj, Contactobj: this.Contactobj, accountFile: JSON.stringify(this.AccountFileData),
                contactFile: JSON.stringify(this.ContactFileData)
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
    }
    handleClickHere() {
        this.showPopup = true;
    }
    closePopup() {
        this.showPopup = false;
    }
    openEmail() {
        window.location.href = 'mailto:dcportalsupport@aldar.com';
    }
    handleEmailOnBlur(event) {    
        this.isLoading=true;    
        const val = event.currentTarget.value;
        const input = event.currentTarget;
        if (val) {
            EmailValidation({ email: val }).then(res => {
                if (res == true) {
                    try {                       
                        input.setCustomValidity('');
                        input.classList.add('checkinput');
                        this.isLoading=false;
                    } catch (e) {
                        //console.log(e.message)
                    }
                } else {
                    input.classList.remove('checkinput');
                    input.setCustomValidity('Email is not valid');
                    this.isLoading=false;
                }
                input.reportValidity();
            }).catch(err => {
                //console.log('error-->', err);
                this.isLoading=false;
            });
        
        }else{
            this.isLoading=false; 
        }
       
    }
     handlePhoneOnBlur(event) {      
        this.isLoading=true; 
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
                         this.isLoading=false; 
                    } else {
                        input.classList.remove('checkinput');
                        input.setCustomValidity('Phone number is not valid');
                         this.isLoading=false; 
                    }
                    input.reportValidity();
                } catch (e) {
                    //console.log(e.message)
                    
                }
            }).catch(err => {
                //console.log('error-->', err);
                this.isLoading=false; 
            });    
        }else{
            this.isLoading=false; 
        }      
    } 
}