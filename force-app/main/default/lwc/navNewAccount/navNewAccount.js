import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import MOBILE_COUNTRY_CODE_FIELD from '@salesforce/schema/Account.MobileCountryCode__c';
import EMAILAPPROVAL_FIELD from '@salesforce/schema/Account.EmailApprovalsReason__c';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import validatePhoneNo from '@salesforce/apex/PhoneNoValidation.getValidatePhoneNoWithAura';
import validateEmail from '@salesforce/apex/EmailValidation.getValidateEmailWithAura';
import checkduplicate from '@salesforce/apex/UtilitiesWithoutSharing.checkduplicateEmail';
//Duplicate account related changes
import checkduplicateresidenttype from '@salesforce/apex/UseExistingAccount.getAccountDuplicate';
import getRecordTypeName from '@salesforce/apex/Utilities.getRecordTypeName';
import addacocuntTeamMember from '@salesforce/apex/UtilitiesWithoutSharing.addacocuntTeamMember';
import sentApproval from '@salesforce/apex/UtilitiesWithoutSharing.sentforApproval';

import hasCorporateLegalCustomPermisssion from '@salesforce/customPermission/CorporateLegal';

import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
// Duplicate account related changes
import NATIONALITY from '@salesforce/schema/Account.BankCountry__c';
import DuplicationEnabled from '@salesforce/label/c.AccountDuplicationEnabled';

export default class NavNewAccount extends NavigationMixin(LightningElement) {
    @track emailvalue = '';
    @track phonevalue = '';
    @track mobileCountryCode = '971';
    @track checkforemail = false;
    @track checkforphone = false;
    @track isLoading = false;
    @track rtId = '';
    @track errorforemail;
    @track displayNumber;
    // Duplicate account related changes
    @track picklistOptionsResidentType;
    @track picklistOptions = [];
    @track isaccountduplicationenabled = false;
    @track residentstatusselected = true;

    residentStatus;
    isResident;
    isNonResident;
    emiratesId;
    recId;
    passportNumber;
    nationality;
    dateOfBirth;
    WrapperList =[];
    isDuplicate = false;
    isModalOpen = false;
    disabled = true;
    isExceptionOpen = false;
    ExceptionAccountId ='';
    ExceptionMessage = false;
    ispersonRecordType= false;
    duplicateFieldsValuesIncorrect = false;
    
    selectedValue='';
    disabledReason = true;

    userId = USER_ID;
    profileName;

    @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.profileName = data.fields.Profile.value.fields.Name.value;
        } else if (error) {
            console.error('Error fetching user data', error);
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            const urlValue = currentPageReference.state.c__phParameter;
            if (urlValue) {
                this.displayNumber = urlValue;
            }
        }
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountMetadata;
    @wire(getPicklistValues, { recordTypeId: '$accountMetadata.data.defaultRecordTypeId', fieldApiName: MOBILE_COUNTRY_CODE_FIELD })
    mobileCountryCodeOptions;
    @wire(getPicklistValues, { recordTypeId: '$accountMetadata.data.defaultRecordTypeId', fieldApiName: EMAILAPPROVAL_FIELD })
    emailApprovalpicklist;
    get options() {
        console.log(this.emailApprovalpicklist);
        return this.emailApprovalpicklist.data?this.emailApprovalpicklist.data.values:[];
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (error) {
            const err = error;
        } else if (data) {
            const rtis = data.recordTypeInfos;
            this.personRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Person Account');
            console.log('Person Record Type Id>>>' + this.personRT);
           
            this.organizationRT = Object.keys(rtis).find(rti => rtis[rti].name === 'Organization Account');
            console.log('Organization Record Type Id>>>' + this.organizationRT);
        }
    };

     // Duplicate account relatec changes
     get optionsResidentType() {
        this.picklistOptionsResidentType = [
            {label: '--None--', value: ''},
            {label: 'Resident', value: 'Resident'},
            {label: 'Non-Resident', value: 'Non-Resident'}
        ];
        return this.picklistOptionsResidentType;
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: NATIONALITY })
    wiredPicklistValues({ error, data }) {
        if (data) {
            console.log('Picklist options:'+JSON.stringify(data.values));
            this.picklistOptions = data.values;
        } else if (error) {
            console.log('error:'+JSON.stringify(error));
            console.error(error);
        }
    }
    handleResidentTypeChange(event){
        var selectedValue = event.target.value;
        this.residentStatus = selectedValue;
        if(selectedValue == 'Resident'){
            this.isResident = true;
            this.isNonResident = false;
            this.residentstatusselected = false;
            console.log('resident');
        } else if(selectedValue == 'Non-Resident'){
            this.isNonResident = true;
            this.isResident = false;
            this.residentstatusselected = false;
            console.log('nonresident');
        } else {
            this.isNonResident = false;
            this.isResident = false;
            this.residentstatusselected = true;
            console.log('none');
        }
    }
    handleEmiratesIdChange(event) {
        this.emiratesId = event.target.value;
    }
    handlePassportChange(event) {
        this.passportNumber = event.target.value;
    }

    handleNationalityChange(event) {
        this.nationality = event.target.value;
    }

    handleDateOfBirthChange(event) {
        this.dateOfBirth = event.target.value;
    }

    connectedCallback() {
        this.rtId = new URL(window.location.href).searchParams.get("recordTypeId");
        console.log('connectedCallback >> Record Type Id>>>' + this.rtId);
        if (this.rtId != null) {
            this.checkForRecordType();
        }
          // Duplicate account related changes
          if(DuplicationEnabled == 'true'){
            this.isaccountduplicationenabled = true;
        }
    }

    renderedCallback() {
        if (this.rtId == null) {
            this.rtId = new URL(window.location.href).searchParams.get("recordTypeId");
            console.log('renderedCallback >> Record Type Id>>>' + this.rtId);
            if (this.rtId != null) {
                this.checkForRecordType();
            }
        }
    }

    async checkForRecordType() {
        await getRecordTypeName({
            objectName: 'Account',
            recordTypeId: this.rtId
        }).then(result => {
            console.log('result>>>' + result);
            if(result =='Person Account'){
                this.ispersonRecordType = true;
            }
            if (result != 'Person Account' && result != 'Organization Account') {
                this.handleClick();
            }
        }).catch(error => {
            console.log('Error: ' + error.body.message);
        });
    }

    handleEmailValidation(event) {
        this.emailvalue = event.target.value;

        this.checkforemail = false;
        var emailFormat = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;
        var emTemp = this.template.querySelector('.email-check');
        if (this.emailvalue.match(emailFormat)) {
            emTemp.setCustomValidity('');
        } else {
            emTemp.setCustomValidity('You have enter incorrect Email');
        }
        emTemp.reportValidity();
        if (this.emailvalue != '') {
            this.validateEmailAddress();
        }
    }

    async validateEmailAddress() {

        this.checkforemail = true;
        var emailFormat = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;
        var emTemp = this.template.querySelector('.email-check');
        if (this.emailvalue.match(emailFormat)) {
            emTemp.setCustomValidity('');
        } else {
            emTemp.setCustomValidity('You have enter incorrect Email');
            this.checkforemail = false;
        }
        emTemp.reportValidity();
        if (this.emailvalue != '') {
           // this.validateEmailAddress();
        }
        /*await validateEmail({ email: this.emailvalue }).then(response => {
            console.log('validate email: ' + response);
            this.checkforemail = response;

            var emTemp = this.template.querySelector('.email-check');
            if (this.checkforemail) {
                emTemp.setCustomValidity('');
            } else {
                emTemp.setCustomValidity('You have enter incorrect Email');
            }
        }).catch(error => {
            console.log('Error: ' + error.body.message);
        });*/
    }

     // Duplicate Account related changes
     async validateEmiratedIdPassportNumber(){
        this.duplicateFieldsValuesIncorrect = false;
        if(this.residentStatus == 'Resident' || this.residentStatus == 'Non-Resident' ){
            this.isLoading = false;
            let msg = '';
            let missingPassportNumberOrEmiratesId = false;
            if (this.residentStatus == 'Resident' && !this.emiratesId ) {
                msg = 'For resident emirates id is required';
                missingPassportNumberOrEmiratesId = true;
                this.duplicateFieldsValuesIncorrect = true;
            }
            if(this.residentStatus == 'Non-Resident' && (!this.passportNumber || !this.nationality || !this.dateOfBirth)){
               
                msg = 'For non-resident passport number, nationality and date of birth is required';
                missingPassportNumberOrEmiratesId = true;
                this.duplicateFieldsValuesIncorrect = true;
            }
            if(missingPassportNumberOrEmiratesId){
                const evt = new ShowToastEvent({
                    title: 'Validation Failed',
                    message: msg,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            } 
            if(this.residentStatus == 'Resident' && (!this.emiratesId || this.emiratesId.length != 15 || !(/^\d*$/.test(this.emiratesId)))){
                this.duplicateFieldsValuesIncorrect = true;
                const evt = new ShowToastEvent({
                    title: 'Validation Failed',
                    message: 'Invalid Emirates Id: Only Numbers are accepted, Should be a 15 Digit Number',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            } else{
                this.isLoading = false;
            }
        }

    }

    handleMobileCountryCode(event) {
        this.mobileCountryCode = event.detail.value;
        this.checkforphone = false;
        if (this.phonevalue && this.phonevalue != '') {
            this.validatePhone();
        }
    }

    handlePhoneValidation(event) {
        this.phonevalue = event.target.value;

        this.checkforphone = false;
        var phoneFormat = /^\d{7,15}$/;
        var phTemp = this.template.querySelector('.phone-check');
        if (this.phonevalue.match(phoneFormat)) {
            phTemp.setCustomValidity('');
        } else {
            phTemp.setCustomValidity('You have enter incorrect Mobile No');
        }
        phTemp.reportValidity();
        if (this.mobileCountryCode && this.mobileCountryCode != '') {
            this.validatePhone();
        }
    }

    async validatePhone() {
        //SSC-631 related change to validate phone number : Bashim
        //let pNo = this.mobileCountryCode + this.phonevalue;
        this.checkforphone = true;
        var phoneFormat = /^\d{7,15}$/;
        var phTemp = this.template.querySelector('.phone-check');
        if (this.phonevalue.match(phoneFormat)) {
            phTemp.setCustomValidity('');
        } else {
            phTemp.setCustomValidity('You have enter incorrect Mobile No');
             this.checkforphone = false;
        }
        if(this.mobileCountryCode && this.phonevalue && this.mobileCountryCode.includes('971') && this.phonevalue.charAt(0) == '0'){
            phTemp.setCustomValidity('UAE number can not start with 0');
             this.checkforphone = false;
        }
        phTemp.reportValidity();
        if (this.mobileCountryCode && this.mobileCountryCode != '') {
           // this.validatePhone();
        }
        /*await validatePhoneNo({
            phoneNo: pNo
        }).then(response => {
            console.log('validate phone: ' + response);
            this.checkforphone = response;

            var phTemp = this.template.querySelector('.phone-check');
            if (this.checkforphone) {
                phTemp.setCustomValidity('');
            } else {
                phTemp.setCustomValidity('You have enter incorrect Mobile No');
            }
            phTemp.reportValidity();
        }).catch(error => {
            console.log('Error: ' + error.body.message);
        });*/
    }
    async checkduplicateEmail(){
        if(this.ispersonRecordType == true){
        // SSC-697, Duplicate Account based on Mobile Number changes: Bashim
        await checkduplicate({ emailId: this.emailvalue, mobileNumber: (this.mobileCountryCode + this.phonevalue) }).then(response => {
            console.log(response);
           if(response){
                var sortedArray = [];
                var isexceptionhappened = false;
                var isExceptionApproved = false;
               // this.WrapperList = response;
                sortedArray = [...response];
                sortedArray.sort((a, b) => b.salesOrderCount - a.salesOrderCount);
                this.WrapperList = sortedArray;
                if(response.length > 0){
                    for(var i=0;i<this.WrapperList.length;i++){
                        if(this.WrapperList[i].account.SkipDuplicateApprovalStatus__c == 'Approved' || this.WrapperList[i].account.SkipDuplicateApprovalStatus__c == 'Sent for Approvals'){
                            
                            if(this.WrapperList[i].account.SkipDuplicateApprovalStatus__c == 'Approved'){
                                isExceptionApproved = true;
                            }else{
                                isexceptionhappened = true;
                            }
                            break;
                        }
                    }
                    if(isExceptionApproved == false){
                        if(isexceptionhappened == false){
                            console.log(this.WrapperList);
                            this.isModalOpen = true;
                            this.ExceptionAccountId = this.WrapperList[0].account.Id;
                            this.isDuplicate = true;
                        }else{
                            console.log(this.WrapperList);
                            this.isModalOpen = true;
                            this.ExceptionAccountId = this.WrapperList[0].account.Id;
                            this.ExceptionMessage = true;
                            this.isDuplicate = true;
                        }
                    }
                    this.isLoading = false;
                }else{
                    this.isDuplicate = false;
                }
           }
        }).catch(error => {
            console.log('Error: ' + error.body.message);
        });
        }
    }

     // Duplicate account related changes
     async checkduplicateEmirateIdPassport(){
        if(this.ispersonRecordType == true){
            console.log('this.ispersonRecordType '+this.ispersonRecordType);
        await checkduplicateresidenttype({ nationalId: this.emiratesId,passPortNumber: this.passportNumber,nationality: this.nationality,dateofBirth: this.dateOfBirth }).then(response => {
            console.log('emirateid response = '+JSON.stringify(response));
           if(response){
                var sortedArray = [];
                var isexceptionhappened = false;
                var isExceptionApproved = false;
               // this.WrapperList = response;
                sortedArray = [...response];
                sortedArray.sort((a, b) => b.salesOrderCount - a.salesOrderCount);
                this.WrapperList = sortedArray;
                if(response.length > 0){
                    for(var i=0;i<this.WrapperList.length;i++){
                        if(this.WrapperList[i].account.SkipDuplicateApprovalStatus__c == 'Approved' || this.WrapperList[i].account.SkipDuplicateApprovalStatus__c == 'Sent for Approvals'){
                            
                            if(this.WrapperList[i].account.SkipDuplicateApprovalStatus__c == 'Approved'){
                                isExceptionApproved = true;
                            }else{
                                isexceptionhappened = true;
                            }
                            break;
                        }
                    }
                    if(isExceptionApproved == false){
                        if(isexceptionhappened == false){
                            console.log(this.WrapperList);
                            this.isModalOpen = true;
                            this.ExceptionAccountId = this.WrapperList[0].account.Id;
                            this.isDuplicate = true;
                        }else{
                            console.log(this.WrapperList);
                            this.isModalOpen = true;
                            this.ExceptionAccountId = this.WrapperList[0].account.Id;
                            this.ExceptionMessage = true;
                            this.isDuplicate = true;
                        }
                    }
                    this.isLoading = false;
                }else{
                    this.isDuplicate = false;
                }
           }
        }).catch(error => {
            console.log('Error: ' + JSON.stringify(error));
        });
        }
    }

    async handleValidate(event) {
        this.isLoading = true;
        if(hasCorporateLegalCustomPermisssion ===true){
            this.handleClick();
        }else{
        await this.validatePhone();
        await this.validateEmailAddress();
        await this.validateEmiratedIdPassportNumber();

        if (this.checkforphone && this.checkforemail) {
            console.log('===duplicateFieldsValuesIncorrect=='+this.duplicateFieldsValuesIncorrect);
            // Duplicate account related changes
            if(((this.isResident && this.emiratesId )|| (this.isNonResident && this.passportNumber && this.nationality && this.dateOfBirth)) && this.checkforphone){
                console.log('===duplicateFieldsValuesIncorrect=='+this.duplicateFieldsValuesIncorrect);
                if(!this.duplicateFieldsValuesIncorrect)
                    await this.checkduplicateEmirateIdPassport();
            } if(!this.WrapperList || this.WrapperList == 0){
                console.log('checkduplicateEmail ');
                await this.checkduplicateEmail();
            }          
           
           if(this.isDuplicate == false && this.duplicateFieldsValuesIncorrect == false ){
               console.log('duplicate');
                this.isLoading = false;
                const evt = new ShowToastEvent({
                    title: 'Validation Successful',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
                this.handleClick();
            }else{
                this.isLoading = false;
            }
        } else {
            this.isLoading = false;
            let msg = '';
            if (!this.checkforphone && !this.checkforemail) {
                msg = 'Mobile Number and Email are not verified';
            } else if (!this.checkforphone) {
                msg = 'Mobile Number is not verified';
            } else if (!this.checkforemail) {
                msg = 'Email is not verified';
            }
            const evt = new ShowToastEvent({
                title: 'Validation Failed',
                message: msg,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
        }
    }

    async handleClick() {
        let dVal = {};
        if (this.rtId == this.personRT) {
            dVal.PersonEmail = this.emailvalue;
            dVal.EmailAddress__pc = this.emailvalue;
            dVal.PersonMobilePhone = this.mobileCountryCode + this.phonevalue;
            dVal.MobileNumberEnc__pc = this.mobileCountryCode + this.phonevalue;
            dVal.MobilePhone__pc = this.phonevalue;
            dVal.MobileCountryCode__pc = this.mobileCountryCode;
            //Duplicate account related changes
            dVal.NationalIdNumber__pc = this.emiratesId;
            dVal.PersonBirthDate  = this.dateOfBirth;
            dVal.PassportNumber__pc = this.passportNumber;
            dVal.Nationality__pc = this.nationality;
            dVal.ResidentStatus__pc = this.residentStatus;
        } else if (this.rtId == this.organizationRT) {
            dVal.Email__c = this.emailvalue;
            dVal.EmailAddress__c = this.emailvalue;
            dVal.MobileNumber__c = this.mobileCountryCode + this.phonevalue;
            dVal.MobileNumberEnc__c = this.mobileCountryCode + this.phonevalue;
            dVal.MobileNumber1__c = this.phonevalue;
            dVal.MobileCountryCode__c = this.mobileCountryCode;
        }
        
        const defaultValues = encodeDefaultFieldValues(dVal);
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
            state: {
                count: '1',
                nooverride: '1',
                navigationLocation: 'LIST_VIEW',
                backgroundContext: '/lightning/o/Account/list?filterName=Recent',
                defaultFieldValues: defaultValues,
                recordTypeId: this.rtId
            }
        });
    }

    get mobileCountryCodeList() {
        return this.mobileCountryCodeOptions && this.mobileCountryCodeOptions.data && this.mobileCountryCodeOptions.data.values ? this.mobileCountryCodeOptions.data.values : [];
    }
    hideModalBox(event){
        this.isModalOpen = false;
    }
    handleRowSelection(event){
        console.log('on select', event.target.value);
        this.disabled = false;
        this.selectedAccountId = event.target.value;
        this.ExceptionAccountId = this.selectedAccountId;
    }
    handleUpdate(event){
        this.isLoading = true;
        addacocuntTeamMember({ recordId: this.selectedAccountId }).then(response => {
            this.isLoading = false;
             window.open('/'+this.selectedAccountId ,'_self');
           
        }).catch(error => {
            this.isLoading = false;
            console.log('Error: ' + error.body.message);
        });
    }
    ClickException(event){
        this.isExceptionOpen = true;
    }
    handleChange(event){
        this.selectedValue = event.target.value;
        if(this.selectedValue =='Other'){
            this.disabledReason = false;
        }
    }
    updateOtherReason(event){
        this.otherReason = event.target.value;
    }
    sentforApprovalProcess(event){
        if(this.otherReason != null && this.selectedValue != null){
        this.isLoading = true;
        sentApproval({ 'AccId': this.ExceptionAccountId, 'OtherReason' :this.otherReason,'ExReason':this.selectedValue}).then(response => {
            this.isLoading = false;
            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Approval Submitted to manager Successfully',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            this.isExceptionOpen = false;
            this.ExceptionMessage = true;
          
       }).catch(error => {
        this.isLoading = false;
        const evt = new ShowToastEvent({
            title: 'Error',
            message: error.body.pageErrors[0].message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
           console.log( error.body.pageErrors[0].message);
       });
    }else{
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'Please complete required fields!',
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
    }
    hideModalBox(event){
        this.isExceptionOpen = false;
    }
}