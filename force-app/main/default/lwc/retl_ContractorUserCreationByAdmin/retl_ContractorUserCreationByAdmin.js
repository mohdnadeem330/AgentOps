import { LightningElement, track, api } from 'lwc';
import getPicklistValues from '@salesforce/apex/DM_UtilityController.getPicklistValues';
import validateMobileNumber from '@salesforce/apex/RETL_ContractorPortalRegistration.validateMobileNumber';
import EmailValidation from '@salesforce/apex/RETL_ContractorPortalRegistration.validateEmailId';
import createContact from '@salesforce/apex/RETL_ContractorProfileController.createContact';
export default class Retl_ContractorUserCreationByAdmin extends LightningElement {
    conObj = new Object();
    contactRoleObj = new Object();
    @track countryCodeOptions = [];
    //@track retailRoleOptions = [];
    @track titlevlaues = [];
    @api accountId
    isLoading = false;
    isButtonDisabled = false;
    connectedCallback() {
        this.gettitlevlaues();
        //this.getContactRolevlaues();
        this.getCountryCodeValues();

    }
    
    @track retailRoleOptions = [
            { label: 'Admin', value: 'Admin' },
            { label: 'Operations', value: 'Operations' }

        ];

    getCountryCodeValues() {
        getPicklistValues({ objName: 'Account', fldName: 'MobileCountryCode__c' })
            .then(data => {
                this.countryCodeOptions = Object.entries(data).map(([label, value]) => ({ value, label }));
            })
            .catch(error => {
                //console.log('error->' + error.message)
            });
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
    handlePhoneOnBlur(event) {
        this.isLoading = true;
        let phoneNumber;
        const input = event.currentTarget;
        if (event.target.name == 'mobile') {
            let data = this.profileUpdateInfo;
            phoneNumber = data.countrycode + data.mobile;
        } else if (event.target.name == 'MobilePhone__c') {
            phoneNumber = this.conObj.MobileCountryCode__c + this.conObj.MobilePhone__c;
        }

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

    handleConChange(event) {
        this.conObj[event.target.name] = event.target.value;

        if (event.target.name === 'MobileCountryCode__c') {
            this.conObj.MobilePhone__c = '';

            const phoneInput = this.template.querySelector('[data-id="conPhone"]');
            if (phoneInput) {
                phoneInput.classList.remove('checkinput');
            }
        }
    }
    handleConRoleChange(event){
       this.contactRoleObj[event.target.name] = event.target.value;


    }

    handleClose() {
        this.backToMain();
    }
    backToMain() {
        this.dispatchEvent(
            new CustomEvent('backtomain', {
                detail: true
            })
        );
    }

    handleUserSaveClick(event) {
        this.isButtonDisabled = true;
        this.conObj.sobjectType = 'Contact';
        this.conObj.AccountId = this.accountId;
        this.conObj.MobilePhone = this.conObj.MobileCountryCode__c + this.conObj.MobilePhone__c;
        this.contactRoleObj.sobjectType = 'RETL_Contact_role__c';
        this.contactRoleObj.RETL_Account_Name__c = this.accountId;
        this.contactRoleObj.Name = this.contactRoleObj.RETL_Contact_role__c;
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isInputsCorrect) {
            this.isLoading = true;
            createContact({ con: this.conObj, conRole: this.contactRoleObj })
                .then(res => {
                    this.isLoading = false;
                    this.showUserPopup = false;
                     this.backToMain();
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('success', 'Your request has been created.', '', 3000);
                })
                .catch(error => {
                    this.isLoading = false;
                    this.isButtonDisabled = false;
                    //console.log('error', error)
                    let err = error.body.message;
                    this.conObj.MobilePhone__c = '';
                    if (err) {
                        this.template.querySelector('c-common-toast-msg-for-communities').
                            showToast('error', err, '', 3000);
                    } else {
                        this.template.querySelector('c-common-toast-msg-for-communities').
                            showToast('error', 'Unable to create request.', '', 3000);
                    }

                })
        }
    }
}