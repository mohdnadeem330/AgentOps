import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import LEAD_OBJECT from '@salesforce/schema/Lead';
import MOBILE_COUNTRY_CODE_FIELD from '@salesforce/schema/Lead.MobileCountryCode__c';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import hasNewSaleCustomPermission from '@salesforce/customPermission/NewSale';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ECSS_RECORD_TYPE from '@salesforce/label/c.AAA_ECSSRecordTypeId';
import ecssLeasingCustomPermission from '@salesforce/customPermission/ECSS_Lead';

import validatePhoneNo from '@salesforce/apex/PhoneNoValidation.getValidatePhoneNoWithAura';
import validateEmail from '@salesforce/apex/EmailValidation.getValidateEmailWithAura';

import hasCustomPermission from '@salesforce/customPermission/CM_Home_Permission';
import LSQCustomPermission from '@salesforce/customPermission/LSQ_Custom_Permission'

//Story number
//import initiateResaleListingProfiles from '@salesforce/label/c.Initiate_Resale_Listing_Profiles';
export default class NavNewLead extends NavigationMixin(LightningElement) {
    @track emailvalue = '';
    @track phonevalue = '';
    @track mobileCountryCode = '971';
    @track checkforemail = false;
    @track checkforphone = false;
    @track isLoading = false;
    @track rtId = '';
    @track errorforemail;
    @track displayNumber;
    error;
    @track prfName;
     
    @track leadType;
    @track leadSource;
    @track enquiryCategory;
    @track enquiryTrigger;
    @track userId;

    //hasPermission = CUSTOM_PERMISSION;
    get hasPermission(){
        return hasCustomPermission;
    }

    //starts : Added by Nikhil Mehra LAS-61
    get hasLSQCustomPermission(){
        return LSQCustomPermission;
    }
    //ends : Added by Nikhil Mehra LAS-61

    //Added by Arvind
    @wire(getRecord, {recordId: USER_ID, fields: [PROFILE_NAME_FIELD]}) 
    wireuser({error,data}){
        if( error ){
           this.error = error ; 
        }else if(data){
            this.prfName =data.fields.Profile.value.fields.Name.value;
            console.log ('***',this.prfName);
           // let initiateResaleProfiles = initiateResaleListingProfiles.split(',');
            if(this.prfName =='Resale Relationship Manager' || this.hasPermission){
                this.leadType = 'Resale';
            }else{
                this.leadType = 'New Sale';
            }
            if( (this.hasPermission && this.leadType == 'Resale') || (hasNewSaleCustomPermission && this.leadType == 'New Sale')){
                this.leadSource ='Direct Call';
                this.enquiryCategory = 'Internal Referral';
                this.enquiryTrigger = 'CM Referral';
                this.userId = USER_ID;
            }else{
                this.userId = '';
            }
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

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadMetadata;
    @wire(getPicklistValues, { recordTypeId: '$leadMetadata.data.defaultRecordTypeId', fieldApiName: MOBILE_COUNTRY_CODE_FIELD })
    mobileCountryCodeOptions;

    connectedCallback() {
        this.rtId = new URL(window.location.href).searchParams.get("recordTypeId");
        console.log('connectedCallback >> Record Type Id>>>' + this.rtId);

        this.setMobileCountryCodeForLSQ();
    }

    renderedCallback() {
        if (this.rtId == null) {
            this.rtId = new URL(window.location.href).searchParams.get("recordTypeId");
            console.log('renderedCallback >> Record Type Id>>>' + this.rtId);
        }
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

    setMobileCountryCodeForLSQ() {
        if(this.hasLSQCustomPermission){ //Added by Nikhil Mehra LAS-61
            this.mobileCountryCode = '44';
        }
    }

    async validateEmailAddress() {
        this.checkforemail = false;
        await validateEmail({ email: this.emailvalue }).then(response => {
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
        });
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
        let pNo = this.mobileCountryCode + this.phonevalue;
        await validatePhoneNo({
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
        });
    }

    async handleValidate(event) {
        this.isLoading = true;
       /* if(this.prfName =='P & I Profile'){
            this.isLoading = false;
            const evt = new ShowToastEvent({
                title: 'Validation Successful',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            this.handleClick();
        }else{*/
        await this.validatePhone();
        await this.validateEmailAddress();

        if (this.checkforphone && this.checkforemail) {
            this.isLoading = false;
            const evt = new ShowToastEvent({
                title: 'Validation Successful',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            this.handleClick();
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
        //}
    }

    handleClick() {
        console.log('Email Address: '+this.emailvalue);
        console.log('mobileCountryCode: '+this.mobileCountryCode);
        console.log('MobileNumber1__c: '+this.phonevalue);

        //starts: Added by Nikhil Mehra LAS-61
        let countryOfResidence = 'United Arab Emirates';
        if(this.hasLSQCustomPermission){
            countryOfResidence = '';
            if (this.mobileCountryCode == '44') {
                countryOfResidence = 'United Kingdom';
            }
        }
        //ends : Added by Nikhil Mehra LAS-61

        if(this.rtId == ECSS_RECORD_TYPE || ecssLeasingCustomPermission)
        {
            const defaultValues = encodeDefaultFieldValues({
            EmailAddress__c: this.emailvalue,
            MobileCountryCode__c: this.mobileCountryCode,
            MobilePhone: this.phonevalue,
            Email: this.emailvalue, 
            MobileNumber1__c: this.phonevalue,
            MobileNumber__c: this.phonevalue,
            Status: 'New Lead',
            //Added by Arvind  
            //Lead_Type__c: this.leadType,
            LeadSource : this.leadSource,
            EnquiryCategory__c : this.enquiryCategory,
            EnquiryTrigger__c : this.enquiryTrigger,
            ReferredBy__c : this.userId,
            CountryOfResidence__c : countryOfResidence // Added by Nikhil Mehra LAS-61
            });
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Lead',
                    actionName: 'new'
                },
                state: {
                    count: '1',
                    nooverride: '1',
                    navigationLocation: 'LIST_VIEW',
                    backgroundContext: '/lightning/o/Lead/list?filterName=Recent',
                    defaultFieldValues: defaultValues,
                    recordTypeId: this.rtId
                }
            });
        }
        else{
            const defaultValues = encodeDefaultFieldValues({
            EmailAddress__c: this.emailvalue,
            MobileCountryCode__c: this.mobileCountryCode,
            MobileNumber1__c: this.phonevalue,
            MobileNumber__c: this.phonevalue,
            Status: 'In Progress Lead',
            //Added by Arvind  
            Lead_Type__c: this.leadType,
            LeadSource : this.leadSource,
            EnquiryCategory__c : this.enquiryCategory,
            EnquiryTrigger__c : this.enquiryTrigger,
            ReferredBy__c : this.userId,
            CountryOfResidence__c : countryOfResidence // Added by Nikhil Mehra LAS-61
            });
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Lead',
                    actionName: 'new'
                },
                state: {
                    count: '1',
                    nooverride: '1',
                    navigationLocation: 'LIST_VIEW',
                    backgroundContext: '/lightning/o/Lead/list?filterName=Recent',
                    defaultFieldValues: defaultValues,
                    recordTypeId: this.rtId
                }
            });
        }
        
    }

    get mobileCountryCodeList() {
        return this.mobileCountryCodeOptions && this.mobileCountryCodeOptions.data && this.mobileCountryCodeOptions.data.values ? this.mobileCountryCodeOptions.data.values : [];
    }
}