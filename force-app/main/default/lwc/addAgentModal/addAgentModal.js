import { LightningElement, track, api, wire } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Contact_OBJECT from '@salesforce/schema/Contact';
import Title_FIELD from '@salesforce/schema/Contact.Salutation';
import BrokerType_FIELD from '@salesforce/schema/Contact.BrokerType__c';
import MobileCountryCode_FIELD from '@salesforce/schema/Contact.MobileCountryCode__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import createAgent from '@salesforce/apex/UtilitiesWithoutSharing.createAgent';
import getValidateEmail from '@salesforce/apex/EmailValidation.getValidateEmailWithAura';
import getValidatePhoneNoWithAura from '@salesforce/apex/PhoneNoValidation.getValidatePhoneNoWithAura';
import getRecordsRegionByName from '@salesforce/apex/AccountChangeOwnerController.getRecordsRegionByName';
import getRecordsByName from '@salesforce/apex/AccountChangeOwnerController.getRecordsByName'
import createUserFromContact from '@salesforce/apex/UtilitiesWithoutSharing.createUserFromContact';
import uploadFile from '@salesforce/apex/BrokerAgentsController.uploadFile';
import getUploadedFiles from '@salesforce/apex/BrokerAgentsController.getUploadedFiles';
import getCountryCodeValues from '@salesforce/apex/BrokerAgentsController.getCountryCodeValues';
import getCurrentBrokerDetails from '@salesforce/apex/BrokerAgentsController.getCurrentBrokerDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Added By Moh Sarfaraj for BPE-120
import blacklistedDomains from '@salesforce/label/c.BlacklistedDomains';
import blockedAgentMessagetoDisplay from '@salesforce/label/c.BPM_BlockedAgentMessagetoDisplay';
// Added By Moh Sarfaraj for BPM-331
import getExistingBrokerWithEmailOrMobile from '@salesforce/apex/BrokerAgentsController.getExistingBrokerWithEmailOrMobile';

import sentOTP from '@salesforce/apex/UtilitiesWithoutSharing.sentOTP';
import getOtpDetails from '@salesforce/apex/UtilitiesWithoutSharing.validateOTP';
import enableDisableOtp from '@salesforce/label/c.EnableDisableAgentOTP';
import fetchOTPExpiryTime from '@salesforce/apex/CommunityAuthController.getBrokerOTPTimer';

import getNationlityPicklistValues from '@salesforce/apex/UserProfileController.getPicklistValuesGeneric';

const DELAY = 3000;

export default class AddAgentModal extends LightningElement {
    disableEmailAndMobile = true; blockedAgentMessagetoDisplay = blockedAgentMessagetoDisplay; 
    nationalityOptions = []; nationality;

    // @wire(getValidateEmail, { email: '$email' })
    // emailResponse;

    //adding check for line manager email
   // @wire(getValidateEmail, { email: '$linemanagerEmail' })
   // lmemailResponse;

    @wire(getValidatePhoneNoWithAura, { phoneNo: '$mobileNumberToCheck' })
    mobileResponse;

    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";

    @track files = [];
    @api action;
    @api rowData;
    @track rowData2 = [];

    @track agencyName;
    @track firstName;
    @track lastName;
    @api email;
  //  @api linemanagerEmail;
  //  @track linemanagerName;
    @api phone;
    @track role;
    @track emiratesID;
    @track expiryDate;
    @api componentTitle = 'Add Agent';
    @track newData = false;
    @track title;
    @track errorDetails;
    @track errorDialog;
    @track additionalWhereClauseForUser = 'RecordType.Name = \'Broker Agency\'';
    @track user;
    @track accountsOption = [];
    //@track accountRegions = [];
    @track showEmirates = false;
    @track birthdate;
    @track countryCode = '';
    @api mobileNumberToCheck = '';
    @track showSpinner = false;
    @track readOnlyEmail = false;
    @track mobileCountryCodePicklist2;
    @track disableButton = false;
    @track isDubaiBroker = false;
    @track brokerRegion;

    makerequired = true;    //MAKE FILE MANDATORY
    // Added By Moh Sarfaraj for BPE-110
    @track isPrimaryOwner = false;
    @track isPrimaryAgencyAdmin = false;
    @track disabledRole = false;
    @track showPrimaryOwner = false;
    @track showPrimaryAdmin = false;
    @track disablePrimaryOwner = false;
    @track disablePrimaryAdmin = false;
    @track isAbuDhabiBroker = false;

    // Added By Moh Sarfaraj for BPM-331
    isRERA_ADM_toShow = false; isBlockedFromBackend = false;

    // Added By Moh Sarfaraj for BPM-526
    passportNumber; passportExpiryDate; currentDate;

    @wire(getNationlityPicklistValues,{sObjectName : 'Contact',  fieldName : 'Nationality__c'})
    wiredNationlityPicklist({data, error}){
        if(data){
            this.nationalityOptions = data;
        }else if(error){
            this.nationalityOptions = [];
        }
    }

    @wire(getObjectInfo, { objectApiName: Contact_OBJECT })
    contactMetadata; loggedInBrokerUser;

    // Added By Moh Sarfaraj for BPE-10
    @wire(getCurrentBrokerDetails)
        brokerDetails({data, error}){
        if(data){
            // Updated By Moh Sarfaraj for BPM-331
            this.disableEmailAndMobile = data.Contact.BrokerType__c == 'Agency Admin' ? false : true;
            this.brokerRegion = data?.Account?.BillingState?.toLowerCase();
            this.isDubaiBroker = this?.brokerRegion?.includes('dubai');
            this.isAbuDhabiBroker = this?.brokerRegion?.includes('abu dhabi');
            this.loggedInBrokerUser = data;
        }
        else if(error){
            this.brokerRegion = undefined;
            console.log(JSON.stringify(error));
        }
    };

    @wire(getPicklistValues,
        {
            recordTypeId: '$contactMetadata.data.defaultRecordTypeId',
            fieldApiName: Title_FIELD
        }
    )
    titlePicklist;

    @wire(getPicklistValues,
        {
            recordTypeId: '$contactMetadata.data.defaultRecordTypeId',
            fieldApiName: MobileCountryCode_FIELD
        }
    )
    MobileCountryCodePicklist;

    @wire(getPicklistValues,
        {
            recordTypeId: '$contactMetadata.data.defaultRecordTypeId',
            fieldApiName: BrokerType_FIELD
        }
    )
    brokerTypePicklist;

    async connectedCallback() {
        // Added by Moh Sarfaraj for BPM-526
        const date = new Date().toString().split(' ');
        this.currentDate = (date[0]+' '+date[1]+' '+date[2]+' '+date[3]).toString();

        this.showSpinner = true;
        getCountryCodeValues().then((response) => {
            this.mobileCountryCodePicklist2 = response;
            this.showSpinner = false;
        }).catch(error => {
            this.showToast('Error', JSON.stringify(error), 'error');
            this.showSpinner = false;
        });
        
        if (this.action == 'edit') {
            this.isEmailVerified = true;
            this.isSMSVerified = true;
            this.agencyName = this.rowData.agencyId;
            this.firstName = this.rowData.firstName;
            this.lastName = this.rowData.lastName;
            this.email = this.rowData.emailId;
           // this.linemanagerName = this.rowData.linemanagerName;
           // this.linemanagerEmail = this.rowData.linemanagerEmail;
            this.emiratesID = this.rowData.emiratesID;
            this.expiryDate = this.rowData.expiryDate;
            this.phone = this.rowData.phoneNumberWithoutCountryCode;
            this.countryCode = this.rowData.countryCode;
            //this.dateOfBirth = rowData;
            this.role = this.rowData.role;
            this.componentTitle = 'Edit Agent';
            this.title = this.rowData.title;
            this.birthdate = this.rowData.birthdate;
            this.readOnlyEmail = (this.rowData.active == 'Active' || this.rowData.active == 'In-Active') ? true : false;
            // Added By Moh Sarfaraj for BPE-110 starts
            this.isPrimaryOwner = this.rowData.primaryOwner;
            this.isPrimaryAgencyAdmin = this.rowData.primaryAgencyAdmin;
            this.disabledRole = this.role ? true : false;
            this.disablePrimaryOwner = this.isPrimaryOwner;
            this.disablePrimaryAdmin = this.isPrimaryAgencyAdmin;
            this.showPrimaryOwner =  this.role === 'Partner/Owner' ? true : false;
            this.showPrimaryAdmin = this.role === 'Agency Admin' ? true : false;
            // Added By Moh Sarfaraj for BPE-110 end

            this.nationality = this.rowData.nationality;

            // Added By Moh Sarfaraj for BPE-526
            this.passportNumber = this.rowData.passportNumber;
            this.passportExpiryDate = this.rowData.passportExpiryDate;

            // Added By Moh Sarfaraj for BPM-331
            this.isRERA_ADM_toShow = (this.role === 'Partner/Owner' || this.role === 'Agency Admin') ? false : true; 
            
            // Added By Moh Sarfaraj for BPM-355
            // this.isBlockedFromBackend = (this.rowData.active == 'Blocked' && this.rowData.blockedFromBackend) ? true : false;



            this.showSpinner = true;
            // Updated By Moh Sarfaraj for BPM-331
            await getUploadedFiles({ contactId: this.rowData.contactId, role: this.role })
                .then(result => {
                    for (let i = 0; i < result.length; i++) {
                        this.files.push({
                            'filename': result[i].fileName,
                            'base64': result[i].base64,
                            'type': result[i].type,
                            'old': 'true',
                        });
                    }
                    this.showSpinner = false;
                })
                .catch(error => {
                    this.errorDetails.push('getUploadedFiles Error: ' + JSON.stringify(error));
                    this.showToast('Error', JSON.stringify(error), 'error');
                    this.showSpinner = false;
                });
        }

        this.showSpinner = true;
        getRecordsRegionByName({ objectName: 'Account', searchFor: '', additionalWhereClause: this.additionalWhereClauseForUser })
            .then(result => {
                console.log('result -> '+result);
                this.recordsList = result;

                this.accountsOption = [];
                this.showEmirates = false;

                result.forEach(element => {
                    this.accountsOption.push({ label: element.Name, value: element.Id });
                    //console.log('Agency:' +element.AgencyRegion__c);
                    if(element.AgencyRegion__c === 'Domestic'){
                        this.showEmirates = true;
                    } else {
                       // this.accountRegions=false;
                    }
                    //console.log('Account Region1:' +this.showEmirates);
                });

                
                this.showSpinner = false;
                

            })
            .catch(error => {
                //exception handling
                this.error = error;
                this.showToast('Error', JSON.stringify(error), 'error');
                this.showSpinner = false;
            })
    }

    async submitDetails() {
        this.showSpinner = true;
        this.errorDialog = false;
        this.errorDetails = [];
        this.rowData2 = [];
        // this.disableButton = true;

        // Added By Moh Sarfaraj for BPM-355
        // if(this.isBlockedFromBackend){
        //     this.errorDetails.push('You are not allowed to update the details.');
        //     this.showToast('Error', 'You are not allowed to update the details.', 'error');
        //     this.showSpinner = false;
        //     return;
        // }

        const isInputsCorrect = await [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {

                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!isInputsCorrect) {
            this.errorDetails.push('Complete Mandatory Fields.');
            this.showToast('Error', 'Complete Mandatory Fields.', 'error');
        }else if(this.files.length == 0){
            this.errorDetails.push('Upload the Mandatory Attachment.');
            this.showToast('Error', 'Upload the Mandatory Attachment.', 'error');
        }
        else {
            // Added By Moh Sarfaraj for BPM-440
            if(this.isEmailVerified == false && this.isEmailOTPTrue == true){
                this.errorDetails.push('Please verify your Email Address.');
                this.showToast('Error', 'Please verify your Email Address.', 'error');
                this.showSpinner = false;
                return;
            }
    
            if(this.countryCode == '971' && this.isSMSVerified == false && this.isSMSOTPTrue == true){
                this.errorDetails.push('Please verify your Mobile Number.');
                this.showToast('Error', 'Please verify your Mobile Number.', 'error');
                this.showSpinner = false;
                return;
            }
            // Added By Moh Sarfaraj for BPM-440

            // Added by Moh Sarfaraj for BPE-10 starts
            let showError = false;
            this.disableButton = false;
            if(this.showEmirates === true){
                let hasRERABrokerCard = false;
                let hasResidentVisa = false;
                let hasEmiratesId = false;
                let hasPassort = false;
                // Added By Moh Sarfaraj for BPE-143
                let hasADMCard = false;

                this.files.forEach(element=>{
                    if(hasEmiratesId === false && element.type === 'Emirates ID Copy'){
                        hasEmiratesId = true;
                        //element.type = 'Emirates ID Copy';
                    }
                    if(hasResidentVisa === false && element.type === 'Residence Visa'){
                        //hasResidentVisa = true;
                        //element.type = 'Residence Visa';
                    }
                    if(hasPassort === false && element.type === 'Passport Copy'){
                        hasPassort = true;
                    }
                    if(hasRERABrokerCard === false && element.type === 'RERA Broker Card'){
                        hasRERABrokerCard = true;
                        //element.type = 'RERA Broker Card';
                    }
                    // Added By Moh Sarfaraj for BPE-143
                    if(hasADMCard === false && element.type === 'ADM Card'){
                        hasADMCard = true;
                    }
                })
                if(hasEmiratesId ===  false){
                    this.showSpinner = false;
                    this.errorDetails.push('Upload the Emirates ID / Residence Visa.');
                    this.showToast('Error', 'Upload the Emirates ID / Residence Visa.', 'error');
                    showError = true;
                    this.disableButton = false;
                } else if(hasPassort === false){
                    this.showSpinner = false;
                    this.errorDetails.push('Upload the Passport Page.');
                    this.showToast('Error', 'Upload the Passport Page.', 'error');
                    showError = true;
                    this.disableButton = false;
                }
                else if(hasRERABrokerCard === false && this.isDubaiBroker){
                    // Updated By Moh Sarfaraj for BPM-331
                    if(this.isRERA_ADM_toShow){
                        this.showSpinner = false;
                        this.errorDetails.push('Upload the RERA Broker Card.');
                        this.showToast('Error', 'Upload the RERA Broker Card.', 'error');
                        showError = true;
                        this.disableButton = false;
                    }
                }
                else if(hasADMCard === false && this.isAbuDhabiBroker){
                    // Updated By Moh Sarfaraj for BPM-331
                    if(this.isRERA_ADM_toShow){
                        this.showSpinner = false;
                        this.errorDetails.push('Upload the ADM Card.');
                        this.showToast('Error', 'Upload the ADM Card.', 'error');
                        showError = true;
                        this.disableButton = false;
                    }
                }
            }else{
                let hasPassportId = false;
                this.files.forEach(element=>{
                    if(hasPassportId === false && element.type === 'Passport Copy'){
                        hasPassportId = true;
                        //element.type = 'Passport Copy';
                    }
                })
                if(hasPassportId === false){
                    this.showSpinner = false;
                    this.errorDetails.push('Upload the Passport Page.');
                    this.showToast('Error', 'Upload the Passport Page.', 'error');
                    showError = true;
                    this.disableButton = false;
                }
            }
            if(showError === true){
                this.showSpinner = false;
                return;
            }else{// Added by Moh Sarfaraj for BPE-10 end
                this.rowData2.push({
                    agencyName: this.agencyName,
                    title: this.title,
                    firstName: this.firstName,
                    lastName: this.lastName,
                    emailId: this.email,
                    role: this.role,
                    country: this.rowData != null && this.action == 'edit' ? this.rowData.country : '',
                    phoneNumber: this.phone,
                    countryCode: this.countryCode,
                    contactId: this.rowData != null && this.action == 'edit' ? this.rowData.contactId : '',
                    userId: this.rowData != null && this.action == 'edit' ? this.rowData.userId : '',
                    realEmail: this.rowData != null && this.action == 'edit' ? this.rowData.realEmail : '',
                    realMobile: this.rowData != null && this.action == 'edit' ? this.rowData.realMobile : '',
                    birthdate: this.birthdate,
                    emiratesID: this.emiratesID != null ? this.emiratesID : '',
                    expiryDate: this.expiryDate != null ? this.expiryDate : '',                
                    //linemanagerEmail: this.linemanagerEmail,
                    //linemanagerName: this.linemanagerName
                    // Added By Moh Sarfaraj for BPE-110
                    primaryOwner : this.isPrimaryOwner,
                    primaryAgencyAdmin : this.isPrimaryAgencyAdmin,
                    nationality : this.nationality,
                    passportNumber :this.passportNumber,
                    passportExpiryDate : this.passportExpiryDate
                });
    
                this.showSpinner = true;
                await createAgent({ agentInfoObject: this.rowData2[0] })
                    .then(result => {
    
                        var profileName = 'Agency User Login';
                        if (this.role == 'Agency Admin') {
                            profileName = 'Agency Admin Login';
                        }
                        if (result != 'Duplicate') {
                            var contactId = result;
    
                            if (this.action != 'edit') {
                                createUserFromContact({ contactId: result, isActive: false, profile: profileName })
                                    .then(result1 => {
                                        this.showSpinner = false;
                                    })
                                    .catch(error => {
    
                                        console.log(JSON.stringify(error));
    
                                        if (error.body.message && error.body.message != null) {
                                            if (JSON.stringify(error.body.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")) {
                                                this.showToast('Error', 'FIELD_CUSTOM_VALIDATION_EXCEPTION: Please check the User/Contact Record', 'error');
                                                this.errorDetails.push(JSON.stringify(error));
                                            } else {
                                                this.showToast('Error', JSON.stringify(error.body.message), 'error');
                                                this.errorDetails.push(JSON.stringify(error));
                                            }
                                            this.errorDetails.push(JSON.stringify(error.body.message));
    
                                        } else if (error.body.fieldErrors.Username && error.body.fieldErrors.Username[0].message != null) {
                                            this.errorDetails.push(JSON.stringify(error.body.fieldErrors.Username[0].message));
                                            this.showToast('Error', JSON.stringify(error.body.fieldErrors.Username[0].message, 'error'));
    
                                        } else {
                                            this.showToast('Error', JSON.stringify(error), 'error');
                                            this.errorDetails.push(JSON.stringify(error));
                                        }
                                        this.showSpinner = false;
                                    });
                            }
    
                            if (this.files != null) {
                                this.upload(this.files, contactId);
                            }
    
                        } else if(result == 'Duplicate') {
                            this.errorDetails.push('There is already a User with this Email in the System.');
                            this.showToast('Error', 'There is already a User with this Email in the System.', 'error');
                        }
                        else {
                            this.errorDetails.push('Some error occured. Please contact Admin.');
                            this.showToast('Error','Some error occured. Please contact Admin.', 'error');
                        }
                    })
                    .catch(error => {
    
                        console.log(JSON.stringify(error));
    
                        if (error.body.message && error.body.message != null) {
                            this.errorDetails.push(JSON.stringify(error.body.message));
    
                            if (error.body.message.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")) {
                                this.showToast('Error', 'FIELD_CUSTOM_VALIDATION_EXCEPTION: Please check the User/Contact Record', 'error');
                                this.errorDetails.push(JSON.stringify(error));
    
                            } else {
                                this.showToast('Error', JSON.stringify(error.body.message), 'error');
                                this.errorDetails.push(JSON.stringify(error));
                            }
                        } else if (error.body.pageErrors && error.body.pageErrors[0] && error.body.pageErrors[0].message != null) {
                            this.showToast('Error', JSON.stringify(error.body.pageErrors[0].message), 'error');
                            this.errorDetails.push(JSON.stringify(error));
    
                        } else {
                            this.errorDetails.push(JSON.stringify(error));
                            let errorStr = JSON.stringify(error);
                            console.log(errorStr.substring(errorStr.indexOf('"message":"'), errorStr.indexOf("}]}")));
                            this.showToast('Error', errorStr.substring(errorStr.indexOf('"message":"'), errorStr.indexOf("}]}")), 'error');
                        }
    
                        this.showSpinner = false;
    
                    });
            }
        }

        setTimeout(() => {
            if (this.errorDetails.length > 0) {
                this.errorDialog = true;
                this.showSpinner = false;
            } else {
                this.showSpinner = false;
                this.closeModal();
            }
            this.disableButton = false;
        }, 3000);

        console.log(this.errorDetails);
    }

    removeError() {
        this.errorDialog = false;
        this.errorDetails = [];
    }

    removeFile(event) {
        let listName = event.currentTarget.dataset.listname;
        let fileName = event.currentTarget.dataset.id;

        this.files = this.files.filter(function (obj) {
            return obj.filename != fileName;
        });

        this.files = [...this.files];
    }

    getAge(dateString) {

        var today = new Date();
        var birthDate = new Date(dateString);
        var age = today.getFullYear() - birthDate.getFullYear();
        var m = today.getMonth() - birthDate.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
            age--;
        }
        return age;
    }

    handleChange(event) {
        var value = event.target.value;

        if (event.target.dataset.id === 'title') {
            this.title = value;
        } else if (event.target.dataset.id === 'agencyName') {
            this.agencyName = value;
            
        } else if (event.target.dataset.id === 'firstName') {
            this.firstName = value;
        } else if (event.target.dataset.id === 'lastName') {
            this.lastName = value;
        } else if (event.target.dataset.id === 'email') {
            this.email = value.toLowerCase();
            // Added By Moh Sarfaraj for BPM-440
            this.type = 'EMAIL';
            this.value = value.toLowerCase();
            this.isEmailVerified = false;

            /*this.delayTimeout = setTimeout(async () => {
                let target = this.template.querySelector('[data-id="email"]');

                if (!this.emailResponse.data) {
                    target.setCustomValidity("Enter Valid Email.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
            */
         //adding check for line manager email validity 
        } /*else if (event.target.dataset.id === 'linemanagerEmail') {
            this.linemanagerEmail = value.toLowerCase();

            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="linemanagerEmail"]');

                if (!this.lmemailResponse.data) {
                    target.setCustomValidity("Enter Valid Email.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);

        } */else if (event.target.dataset.id === 'dateOfBirth') {
            this.birthdate = value;

            let age = this.getAge(value);
            let target = this.template.querySelector('[data-id="dateOfBirth"]');

            if (age < 18) {
                target.setCustomValidity("Age should be at least 18 years");
            } else {
                target.setCustomValidity("");
            }
            target.reportValidity();

        } else if (event.target.dataset.id === 'role') {
            this.role = value;
            // Added By Moh Sarfaraj for BPM-331
            this.isRERA_ADM_toShow = (this.role === 'Partner/Owner' || this.role === 'Agency Admin') ? false : true; 

        } else if (event.target.dataset.id === 'emiratesID'){
            this.emiratesID = value;
        } else if (event.target.dataset.id === 'expiryDate'){
            this.expiryDate = value;
        } /*else if (event.target.dataset.id === 'linemanagerName'){
            this.linemanagerName = value;
        } */
        else if (event.target.dataset.id === 'phone') {
            this.phone = value;
            this.isSMSVerified = false;
            let target = this.template.querySelector('[data-id="phone"]');
            if (/^[0-9]*$/.test(value)){
                this.phone = value;
                target.setCustomValidity("");

                this.type = 'SMS';

            }else{
                target.setCustomValidity("Enter Numbers only.");
            }
            target.reportValidity();
            /* Commented by Tharun
            this.mobileNumberToCheck = this.countryCode + this.phone;
            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="phone"]');

                if (!this.mobileResponse.data) {
                    target.setCustomValidity("Enter Valid Mobile Number.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
            */
        } else if (event.target.dataset.id === 'countryCode') {
            this.countryCode = value;
            this.isSMSVerified = false;
            if(this.phone)
            {
                this.mobileNumberToCheck = this.countryCode + this.phone;
                this.delayTimeout = setTimeout(async () => {
                    let target = await this.template.querySelector('[data-id="phone"]');

                    if (!this.mobileResponse.data) {
                        target.setCustomValidity("Enter Valid Mobile Number.")
                    } else {
                        target.setCustomValidity("");
                    }
                    target.reportValidity();
                }, DELAY);
            }
        } //else if (event.target.dataset.id === 'uploadedFiles') {
           // this.files = value;
        //}
        // Added By Moh Sarfaraj for BPE-110 starts
        else if(event.target.dataset.id === 'primaryOwner' ){
            if(event.target.checked){
                this.isPrimaryAgencyAdmin = false;
                this.isPrimaryOwner = true;
                this.role = 'Partner/Owner';
            }else{
                this.isPrimaryOwner = false;
            }
        }else if(event.target.dataset.id === 'primaryAgencyAdmin'){
            if(event.target.checked){
                this.isPrimaryAgencyAdmin = true;
                this.isPrimaryOwner = false;
                this.role = 'Agency Admin';
            }else{
                this.isPrimaryAgencyAdmin = false;
            }
        } 
        // Added By Moh Sarfaraj for BPE-110 end
        else if(event.target.dataset.id === 'nationality'){
            this.nationality = value;
        }

        // Added By Moh Sarfaraj for BPE-526
        else if(event.target.dataset.id === 'passportNumber'){
            this.passportNumber = value;
        }else if(event.target.dataset.id === 'passportExpiryDate'){
            this.passportExpiryDate = value;
        }
    }

    async upload(fileData, recordId) {
        await Array.from(fileData).forEach(file => {
            if (file.old == null) {
                const { base64, filename, type } = file;
                if (base64 != null) {
                    this.showSpinner = true;

                    setTimeout(async() =>{
                        await uploadFile({ base64, filename, type, recordId }).then(result => {
                            file = null;
                            let title = filename + ' uploaded successfully!!';
                            this.showSpinner = false;
                        }).catch(error => {
                            this.errorDetails.push(JSON.stringify(error.body.message));
                            this.errorDetails.push(JSON.stringify(error));
                            this.showSpinner = false;
                        });
                    }, DELAY);
                }
            }
        });
    }

    async openfileUpload(event) {
        // Added By Moh Sarfaraj for BPM-331
        const date = new Date().toLocaleString();
        // Added By Moh Sarfaraj for BPE-10
        let fileEventeName = event.target.name;
        let type = ''; //fileEventeName === 'emirate' ? 'Emirates ID Copy' : fileEventeName === 'residence' ? 'Residence Visa' : fileEventeName === 'rera' ? 'RERA Broker Card' : fileEventeName === 'passport' ? 'Passport Copy' : '';
        if(fileEventeName === 'emirate'){
            type = 'Emirates ID Copy';
        }else if (fileEventeName === 'residence'){
            type = 'Residence Visa';
        }else if (fileEventeName === 'rera'){
            type = 'RERA Broker Card';
        }else if(fileEventeName === 'passport'){
            type = 'Passport Copy';
        }// Added By Moh Sarfaraj for BPE-143
        else if(fileEventeName === 'adm'){
            type = 'ADM Card';
        }

        function getBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = error => reject(error);
            });
        }

        await Array.from(event.target.files).forEach(file => {
            var base64;
            getBase64(file).then(
                data => {
                    base64 = data.split(',')[1];
                }
            );
            let fileSize = file.size;

            //[KP - BPM-454]: adding file extension to Contact document.
            var extension = file.name.split('.').pop();

            var reader = new FileReader();

            reader.onload = () => {
                if(file.size > 2500000){
                    this.showToast('Error','File size is More Than 2 MB.', 'error');
                    this.errorDetails.push('File size is More Than 2 MB.');
                    this.files = [];
                    return;
                }else if ((file.size + new Blob([JSON.stringify(this.files)]).size) > 2500000)
                { 
                    this.showToast('Error','Total File size is More Than 2 MB.', 'error');
                    this.errorDetails.push('Total File size is More Than 2 MB.');
                    return;
                }
                let result = this.files.filter(obj => {
                    //return obj.filename === file.name;
                    if(obj.filename === file.name){
                        this.showToast('Error','File already exists', 'error');
                        this.errorDetails.push('File already exists');
                        return;
                    }
                });
                // updated By Moh Sarfaraj for BPE-10
                this.files.push({ // Updated By Moh Sarfaraj for BPM-331
                    'filename': type + ' - '+date+'.'+extension, // result?.length > 0 ? file.name + `(${this.files.length})` : file.name,
                    'base64': base64,
                    'fileSize': fileSize,
                    'type' : type
                });
            }
            reader.readAsDataURL(file);
        });
    }

    async getBase64(file) {
        return await new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.readAsDataURL(file);
            reader.onload = () => {
                resolve(reader.result);
                return reader.result.split(',')[1];
            }
            reader.onerror = error => {
                reject(error)
                return '';
            };
        });
    }


    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
    }

    handleSelected(event) {
        var objectname = event.detail.ObjectName;

        if (objectname === "User") {
            this.user = { Name: event.detail.Name, Id: event.detail.Id }
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

    //Tharun added below function
    async handleEmailBlur(event)
    {
        let emailAdd = event.target.value.toLowerCase();
        let target = this.template.querySelector('[data-id="email"]');
        target.setCustomValidity("");
         // Added By Moh Sarfaraj for BPE-120
        if(this.countryCode && this.countryCode === '971'){
            let domains = blacklistedDomains.split(',');
            if(domains.includes('@'+(emailAdd.split('@')[1]).toLowerCase())){
                target.setCustomValidity("Please enter professional Email Address");
                target.reportValidity();
                return;
            }else{
                target.setCustomValidity("");
                target.reportValidity();
            }
        }

        await getValidateEmail({
            email : emailAdd
        }).then(result => {
            // TODO On success
            if (!result) {
                target.setCustomValidity("Enter Valid Email");
            } else {
                // Added By Moh Sarfaraj for BPM-331
                getExistingBrokerWithEmailOrMobile({ 
                    value : emailAdd, 
                    type : 'Email', 
                    editedUserContact : this.componentTitle == 'Edit Agent' ? this.rowData.contactId : '',
                    actionType : this.componentTitle
                })
                .then(resonse=>{
                    if(resonse == true){
                        target.setCustomValidity("Email is associated with another broker");
                    }else{
                        target.setCustomValidity("");
                    }
                    target.reportValidity();
                }).catch(error=>{
                    console.log(JSON.stringify(error));
                })
            }
            target.reportValidity();
        }).catch(error =>{
            console.log(error);
        });        
    }

    // Added By Moh Sarfaraj for BPE-120
    handleCountryCodeBlur(event){
        let countryCode = event.target.value;
        let target = this.template.querySelector('[data-id="email"]');

        if(countryCode && countryCode === '971'){
            let domains = blacklistedDomains.split(',');
            if(domains.includes('@'+(target.value.split('@')[1]).toLowerCase())){
                target.setCustomValidity("Please enter professional Email Address");
            }
        }else{
            target.setCustomValidity("");
        }
        target.reportValidity();
        this.utlityFunctionForMobileValidation();   
    }

    //Tharun added below function
    async handlePhoneNumberBlur(event)
    {
        // this.showSpinner = true;
        this.isSMSVerified = false;
        let enteredMobNumber    = event.target.value;
        if(enteredMobNumber != ''){
            let mob                 = enteredMobNumber.replace(/[^0-9]/g,'');
            let mobNumber           = parseInt(mob);
            this.phone              = mobNumber.toString();
        }
        this.utlityFunctionForMobileValidation();
        // this.mobileNumberToCheck = this.countryCode + this.phone;
        // let target = await this.template.querySelector('[data-id="phone"]');
        // await getValidatePhoneNoWithAura({
        //     phoneNo : this.mobileNumberToCheck
        // }).then(result => {
        //     if (!result) {
        //         target.setCustomValidity("Enter Valid Mobile Number.");
        //     } else {
        //         target.setCustomValidity("");
        //         // Added By Moh Sarfaraj for BPM-331
        //         getExistingBrokerWithEmailOrMobile({ 
        //             value : enteredMobNumber, 
        //             type : 'Mobile',
        //             editedUserContact : this.componentTitle == 'Edit Agent' ? this.rowData.contactId : '',
        //             actionType : this.componentTitle
        //         })
        //         .then(resonse=>{
        //             if(resonse == true){
        //                 target.setCustomValidity("Number is associated with another broker");
        //             }else{
        //                 target.setCustomValidity("");
        //                 if(this.countryCode !== '971'){
        //                     this.isSMSVerified = true;
        //                 }
        //             }
        //             target.reportValidity();
        //         }).catch(error=>{
        //             console.log(JSON.stringify(error));
        //         })
        //     }
        //     target.reportValidity();
        //     this.showSpinner = false;
        // }).catch(error =>{
        //     console.log(error);
        //     this.showSpinner = false;
        // });
    }

    // Added BY Moh Sarfaraj for BPM-440 starts
    otpSection = false; isSMSVerified = false; isEmailVerified = false; showTimer = false; timerTextValue; type; value; enteredOtpValue;
    isOtpValidatedWithInCount = true; isNeedToClearSetInterval = false; countDown; otpText;

    get isEmailOTPTrue(){
        return (enableDisableOtp.split(',')[0]).toLowerCase() == 'enableemail';
    }

    get isSMSOTPTrue(){
        return (enableDisableOtp.split(',')[1]).toLowerCase() == 'enablesms';
    }

    get verifyEmailButtonText(){
        return this.isEmailVerified == false ? 'Verify Email' : 'Email Verified';
    }

    get verifyMobileButtonText(){
        return this.isSMSVerified == false ? 'Verify Mobile' : 'Mobile Verified';
    }

    get showMobileVerifiedButton(){
        return  this.countryCode == null || this.countryCode == '' || this.countryCode == undefined || this.countryCode == '971';
    }

    @wire(fetchOTPExpiryTime)
    wiredData({ error, data }) { 
        if (data) {
            this.countDown = data.Timer__c * 60;
            
        } else if (error) {
            console.error('Error:', error);
        }
    }

    closeOTPModal(){
        this.otpSection = false;
        this.isNeedToClearSetInterval = true;
        this.enteredOtpValue = null;
    }

    sentOTP(){
        this.sentOTPForValidation();
    }

    resendOTP(){
        this.sentOTPForValidation();
        this.enteredOtpValue = null;
    }

    handleOTP(event){
        this.enteredOtpValue = event.target.value;
    }

    validateOTP(event){
        this.validateOTPViaApex(event);
    }

    verifyEmail(event){
        this.type = 'EMAIL';

        this.errorDetails = [];
        const isInputsCorrect = [this.template.querySelector('.otpEmail')]
            .reduce((validSoFar, inputField) => {

                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!isInputsCorrect) {
            this.errorDetails.push('Please complete the email field');
            this.showToast('Error', 'Please complete the email field', 'error');
            return;
        }

        if(this.isEmailVerified == true){
            this.showToast('Success', 'Your Email Address is already verified.', 'success')
            return;
        }
        if(this.email == undefined || this.email == '' || this.email == null){
            this.showToast('Error', 'Please enter email address', 'error');
            return ;
        }
        this.value = this.email;
        this.otpSection = true;
        this.sentOTP();
    }

    verifyMobile(event){
        this.type = 'SMS';

        this.errorDetails = [];
        const isInputsCorrect = [this.template.querySelector('.otpMobile')]
            .reduce((validSoFar, inputField) => {

                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!isInputsCorrect) {
            this.errorDetails.push('Please complete the mobile field');
            this.showToast('Error', 'Please complete the mobile field', 'error');
            return;
        }

        if(this.isSMSVerified == true){
            this.showToast('Success', 'Your Mobile Number is already verified.', 'success');
            return;
        }
        if(this.countryCode == undefined || this.countryCode == '' || this.countryCode == null){
            this.showToast('Error', 'Please select Country Code', 'error');
            return;
        }
        if(this.phone == undefined || this.phone == '' || this.phone == null){
            this.showToast('Error', 'Please enter Mobile Number', 'error');
            return;
        }

        this.value = this.countryCode + this.phone;
        if(this.countryCode == '971'){
            this.otpSection = true;
            this.sentOTP();
        }else{
            this.isSMSVerified = true;
        }
    }

    async sentOTPForValidation(){
        this.showSpinner = true;
        this.otpText = 'We are sending '+ (this.type == 'SMS' ? 'a mobile OTP' : 'an email OTP')+ ' to '+ this.value; 
        await sentOTP({
            contactId : this.loggedInBrokerUser.ContactId, 
            type : this.type,  
            value : this.value,
        })
        .then(result=>{
            if(this.isEmailOTPTrue ||  this.isSMSOTPTrue){
                if(result == 'success'){
                    this.showSpinner = false;
                    this.isNeedToClearSetInterval = false;
                    this.countDownUtlityFunction();
                    this.otpText = 'We have sent '+ (this.type == 'SMS' ? 'a mobile OTP' : 'an email OTP')+ ' to '+ this.value; 
                    this.showToast('Success', 'Your OTP has been Sent Successfully', 'success');
                }else{
                    this.otpText = '';
                    this.showSpinner = false;
                    this.showToast('Error', 'An Unexpected Error occured while Sending the OTP', 'error');
                }
            }
        }).catch(error=>{
            this.showSpinner = false;
            this.showToast('Error', error.body.message, 'error');
        })
    }

    countDownUtlityFunction(){
        this.showTimer = true;
        let remainingSeconds = this.countDown;
        this.isOtpValidatedWithInCount = true;

        var intrvalCount = setInterval(() => {
            remainingSeconds-- ;
            this.timerTextValue = `To generate next OTP wait for ${remainingSeconds} seconds.`;
            if(remainingSeconds <= 0){
                clearInterval(intrvalCount);
                this.showTimer = false;
                this.isOtpValidatedWithInCount = false; 
            }else if(this.isNeedToClearSetInterval){
                clearInterval(intrvalCount);
                this.showTimer = false;
            }
        }, 1000);
    }

    async validateOTPViaApex(){
        this.showSpinner = true;
        if(this.isOtpValidatedWithInCount){
            await getOtpDetails({ contactId : this.loggedInBrokerUser.ContactId })
            .then(getOTPResults=>{
                if(getOTPResults.length > 0){
                    if(getOTPResults[0].BrokerLoginOTPNumber__c == this.enteredOtpValue){
                        this.enteredOtpValue = null;
                        if(this.type == 'EMAIL'){
                            this.isEmailVerified = true;                              
                        }else if(this.type == 'SMS'){
                            this.isSMSVerified = true;
                        }
                        this.isNeedToClearSetInterval = true;
                        this.showSpinner = false;
                        this.showToast('Success', 'Your OTP has been validated Successfully', 'success');
                        this.closeOTPModal();
                    }else{
                        this.showSpinner = false;
                        this.showToast('Validation Failed', 'Entered OTP is not Matched', 'error');
                    }
                }else{
                    this.showSpinner = false;
                    this.showToast('Time out', 'Please Resend the OTP', 'error');
                }
            }).catch(error=>{
                this.showSpinner = false;
                this.showToast('Validation Failed', error.body.message , 'error');
            })
        }else{
            this.showSpinner = false;
            this.showToast('Time out', 'Please Resend the OTP', 'error');
        }
    }

    async utlityFunctionForMobileValidation(){
        
        if((this.phone != undefined || this.phone != '') &&  (this.countryCode != undefined || this.countryCode != '')){
            this.showSpinner = true;
            this.mobileNumberToCheck = this.countryCode + this.phone;
            let target = await this.template.querySelector('[data-id="phone"]');
            await getValidatePhoneNoWithAura({
                phoneNo : this.mobileNumberToCheck
            }).then(result => {
                if (!result) {
                    target.setCustomValidity("Enter Valid Mobile Number.");
                    this.showSpinner = false;
                } else {
                    target.setCustomValidity("");
                    // Added By Moh Sarfaraj for BPM-331
                    getExistingBrokerWithEmailOrMobile({ 
                        value : this.phone, 
                        type : 'Mobile',
                        editedUserContact : this.componentTitle == 'Edit Agent' ? this.rowData.contactId : '',
                        actionType : this.componentTitle
                    })
                    .then(resonse=>{
                        if(resonse == true){
                            target.setCustomValidity("Number is associated with another broker");
                            this.showSpinner = false;
                        }else{
                            target.setCustomValidity("");
                            if(this.countryCode !== '971'){
                                this.isSMSVerified = true;
                            }
                            this.showSpinner = false;
                        }
                        target.reportValidity();
                    }).catch(error=>{
                        console.log(JSON.stringify(error));
                    })
                }
                target.reportValidity();
                this.showSpinner = false;
            }).catch(error =>{
                console.log(error);
                this.showSpinner = false;
            });
        }
    }

    // Added BY Moh Sarfaraj for BPM-440 end
}