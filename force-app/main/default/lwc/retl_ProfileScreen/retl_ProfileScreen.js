import { LightningElement, track, api, wire } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages16";
import getCurrentUser from '@salesforce/apex/RETL_SuperAppPageController.getCurrentUser';
import validateMobileNumber from '@salesforce/apex/RETL_ContractorPortalRegistration.validateMobileNumber';
import sendMobileOTP from '@salesforce/apex/DM_UtilityController.sendMobileOTP';
import updateContact from '@salesforce/apex/RETL_ContractorProfileController.updateContact';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedContacts from '@salesforce/apex/RETL_ContractorProfileController.getRelatedContacts';
import getCurrentUserContactRole from '@salesforce/apex/RETL_SuperAppPageController.getCurrentUserContactRole';
import getPicklistValues from '@salesforce/apex/DM_UtilityController.getPicklistValues';
export default class Retl_ProfileScreen extends NavigationMixin(LightningElement) {
    icon11image = Images + '/Request/icon11.png';
    icon22image = Images + '/Request/icon22.png';
    icon23image = Images + '/Request/icon23.png';

    @track userData = {};
    @track profileUpdateInfo = {};
    @track contactRoleobj = {};
    @track contacts = [];
    //@track retailRoleOptions = [];
    //@api userInitials = 'GK';
    accountId;
    userId;
    isLoading = false;
    showRegistration = false
    showProfileSetting = true;
    showUserCreateScreen = false;
    showAdditionalWorkspaceAccess = true;
    isEditMode = false;
    showSwitchWorkspace = false;
    showAddContact = false;
    contactId;
    connectedCallback() {
        //this.getContactRolevlaues();
    }

    @wire(getCurrentUser)
    wiredUser({ data, error }) {
        if (data) {
            this.userData = data;
            this.userId = data.Id;
            this.contactId = data?.ContactId;
            this.accountId = data?.Contact?.AccountId;

            // Call Apex to get Contact Role
            if (this.contactId && this.accountId) {
                this.fetchContactRole(this.contactId, this.accountId);
            }
            //Populate profile screen fields here
            this.profileUpdateInfo = {
                firstName: data?.Contact?.FirstName,
                lastName: data?.Contact?.LastName,
                email: data?.Contact?.Email,
                countrycode: data?.Contact?.MobileCountryCode__c,
                mobile: data?.Contact?.MobilePhone,
                contactid: data?.ContactId
            };

            //Set accountId for next wire
            this.accountId = data?.Contact?.AccountId;

            // Additional values
            this.vertical = data?.Contact?.Account?.CustomerVertical__c;
            if (this.vertical?.includes(';')) {
                this.showSwitchWorkspace = true;
                this.showAdditionalWorkspaceAccess = false;
            }
            else {
                this.showSwitchWorkspace = false;
                this.showAdditionalWorkspaceAccess = true;
            }
            this.fetchContacts();
        } else if (error) {
            console.error('Error fetching user:', error);
            // this.userData = {};
        }
    }

    fetchContactRole(contactId, accountId) {
        getCurrentUserContactRole({ contactId: contactId, accountId: accountId })
            .then(result => {
                const safeResult = result ? { ...result } : {};
                this.contactRoleobj = safeResult;
                if (this.contactRoleobj.RETL_Contact_role__c === 'Admin') {
                    this.showAddContact = true
                }
                else {
                    this.showAddContact = false;
                }
            })
            .catch(error => {
                console.error('Error fetching contact role:', error);
            });
    }

    fetchContacts() {
        if (!this.accountId) {
            console.log('AccountId not ready, skipping contacts fetch');
            return;
        }

        getRelatedContacts({ accountId: this.accountId, contactId: this.contactId })
            .then(result => {
                this.contacts = result.map(contact => {
                    // Extract contact roles as labels
                    const roles = (contact.Contact_roles__r || []).map(
                        r => r.RETL_Contact_role__c
                    );

                    return {
                        id: contact.Id,
                        name: contact.Name,
                        phone: contact.MobilePhone,
                        email: contact.Email,
                        customer: contact.Account ? contact.Account.Name : '',
                        designation: roles.join(', '),     // <---- IMPORTANT
                        expanded: false,
                        iconName: 'utility:chevrondown'
                    };
                });

            })
            .catch(error => {
                console.error('Error fetching contacts', error);
            });
    }


    //User initials
    get userInitials() {
        if (this.profileUpdateInfo?.firstName || this.profileUpdateInfo?.lastName) {
            return (
                (this.profileUpdateInfo.firstName ? this.profileUpdateInfo.firstName.charAt(0) : '') +
                (this.profileUpdateInfo.lastName ? this.profileUpdateInfo.lastName.charAt(0) : '')
            ).toUpperCase();
        }
        return '';
    }

    @track retailRoleOptions = [
        { label: 'Admin', value: 'Admin' },
        { label: 'Operations', value: 'Operations' }

    ];
    handleEditAccount() {
        this.isEditMode = true;
    }

    handlePrfChange(event) {
        let data = this.profileUpdateInfo;
        const value = event.target.value;
        data[event.target.name] = event.target.value;
        if (event.target.name === 'mobile') {
            this.profileUpdateInfo.countrycode = '971';
            let cleaned = value.replace(/[-\s]/g, '');
            if (cleaned.startsWith('971')) {
                cleaned = cleaned.substring(3);
            }
            this.profileUpdateInfo.mobilePhoneCustom = cleaned;

        }

    }

    handleContactRoleChange(event) {
        let data = this.contactRoleobj;
        data[event.target.name] = event.target.value;
    }
    handlePhoneOnBlur(event) {
        let phoneNumber;
        const input = event.currentTarget;
        if (event.target.name == 'mobile') {
            let data = this.profileUpdateInfo;
            phoneNumber = data.countrycode + data.mobile;
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

            });

        }

    }

    handleCancel() {
        this.isEditMode = false;
        // Optionally, reset fields to original values if needed
    }

    handleProfileSave(event) {

        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isInputsCorrect) {
            if (this.userData.Contact.MobilePhone != this.profileUpdateInfo.mobile) {
                this.sendOtp();
            } else {
                this.updateUserInfo();

            }
        }
    }

    sendOtp(event) {
        try {
            this.OTP = null;
            this.hasError = false;
            const profile = this.profileUpdateInfo;
            let conObj = new Object();
            conObj.sobjectType = 'Contact';
            conObj.Id = profile.contactid;
            conObj.MobilePhone = profile.countrycode + profile.mobile;
            this.isLoading = true;
            sendMobileOTP({ con: conObj })
                .then(res => {
                    this.isLoading = false;
                    let data = this.profileUpdateInfo;
                    this.otpSentMsg = 'OTP sent to ' + data.countrycode + data.mobile;
                    this.otpScreen = true;
                    this.showCounter = true;
                    const input = this.template.querySelector('[autocomplete=one-time-code');
                    if (input)
                        input.value = '';

                    this.mobileInterval = setInterval(function () {
                        if (this.refreshCounter == 1) {
                            this.counter = 1;
                            this.refreshCounter = 0;
                            this.showCounter = false;
                            clearInterval(this.mobileInterval);
                        }
                        this.refreshCounter = 60 - (this.counter++);
                    }.bind(this), 1000);

                })
                .catch(error => {
                    this.template.querySelector('c-common-toast-msg-for-communities').
                        showToast('error', 'Unable to send OTP.', '', 3000);
                });

        } catch (e) {
            //console.log('sendOtp', e.message);
        }
    }
    verifyOtp(event) {
        this.hasError = false;
        this.isLoading = true;
        const input = this.template.querySelector('[autocomplete=one-time-code');
        if (input.value.length == 6) {
            verifyOtp({ otp: input.value }).then(res => {
                if (res == 'Success') {
                    this.hideAllForms();
                    this.showProfileUpdate = true;
                    this.profileReadMode = true;
                    this.updateUserInfo();

                } else {
                    this.isLoading = false;
                    this.hasError = true;
                    this.errorMessage = 'OTP does not match.';
                }

            }).catch(error => {
                this.isLoading = false;
                //console.log('error->', error);
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('error', 'Unable to verify OTP.', '', 3000);
            })
        } else {
            this.isLoading = false;
            this.hasError = true;
            this.errorMessage = 'Please Enter OTP';
        }

    }
    updateUserInfo() {

        const profile = this.profileUpdateInfo;
        let conObj = new Object();
        conObj.sobjectType = 'Contact';
        conObj.Id = profile.contactid;
        conObj.LastName = profile.lastName;
        conObj.FirstName = profile.firstName;
        conObj.MobileCountryCode__c = profile.countrycode;
        conObj.MobilePhone__c = profile.mobilePhoneCustom;
        conObj.MobilePhone = profile.mobile;
        const contactRole = this.contactRoleobj;
        let conRoleObj = new Object();
        conRoleObj.sobjectType = 'RETL_Contact_role__c';
        conRoleObj.Id = contactRole.Id;
        conRoleObj.RETL_Contact_role__c = contactRole.RETL_Contact_role__c;
        this.isLoading = true;
        updateContact({ con: conObj, conRole: conRoleObj })
            .then(data => {
                this.isLoading = false;
                this.isEditMode = false;
                this.showAddContact = conRoleObj.RETL_Contact_role__c === 'Admin' ?true:false;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('success', 'Your infomration has been updated successfully', '', 3000);
            })
            .catch(err => {
                this.isLoading = false;
                this.template.querySelector('c-common-toast-msg-for-communities').
                    showToast('error', 'Unable to update your information.', '', 3000);
                //console.log('error-->', err);
            });
    }


    handleSave() {
        this.isEditMode = false;
        // Add logic to save updated data to server or state
        alert('Details Saved');
    }

    handleFullNameChange(event) {
        this.fullName = event.target.value;
    }

    handlePhoneChange(event) {
        this.phoneNumber = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handleAddContact() {
        this.showProfileSetting = false;
        this.showUserCreateScreen = true;
    }


    index;
    toggleDetails(event) {
        const idx = event.currentTarget.dataset.index;
        this.index = idx;
        // this.contacts = this.contacts.map((c, i) =>
        //     i == idx ? { ...c, expanded: !c.expanded } : { ...c, expanded: false }
        // );
        this.contacts = this.contacts.map((c, i) => {
            const expanded = i == idx ? !c.expanded : false;
            return {
                ...c,
                expanded: expanded,
                iconName: expanded ? 'utility:chevronup' : 'utility:chevrondown'
            };
        });
    }

    get getArrowSymbol() {
        return this.contacts[this.index]?.expanded ? 'utility:chevronup' : 'utility:chevrondown';//'▲' : '▼';
    }

    handleBackClick() {
        this.dispatchEvent(
            new CustomEvent('backtomain', {
                detail: true
            })
        );

    }

    handleUserCreationClose(event) {
        this.showUserCreateScreen = false;
        this.showProfileSetting = true;
        this.fetchContacts();
    }


    navigateToSuperApp() {
        console.log('navigateToSuperApp')
        window.open('/business/', "_self");
    }

    navigateToRegistrationPage() {
        //sessionStorage.setItem('currentUserId', this.userId);
        window.open('/business/SelfRegister', "_self");
        //this.showProfileSetting = false;
        //this.showRegistration = true;
    }

    get logoutUrl() {
        return "/business/secur/logout.jsp";
    }


    handleLogout() {
        window.open(this.logoutUrl, "_self");
    }

}