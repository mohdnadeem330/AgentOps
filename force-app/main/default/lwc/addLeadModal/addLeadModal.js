import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import Title_FIELD from '@salesforce/schema/Lead.Salutation';
import MobileCountryCode_FIELD from '@salesforce/schema/Lead.MobileCountryCode__c';
import ResidentStatus_FIELD from '@salesforce/schema/Lead.ResidentStatus__c';
import Nationality_FIELD from '@salesforce/schema/Lead.Nationality__c';
import SalesType_FIELD from '@salesforce/schema/Lead.SalesType__c';
import PropertyUsage_FIELD from '@salesforce/schema/Lead.PropertyUsage__c';
import BuyRent_FIELD from '@salesforce/schema/Lead.BuyRent__c';
import Project_FIELD from '@salesforce/schema/Lead.Project__c';
import UnitType_FIELD from '@salesforce/schema/Lead.UnitType__c';
import NumberOfBedrooms_FIELD from '@salesforce/schema/Lead.NumberOfBedrooms__c';
import Offer1_FIELD from '@salesforce/schema/Lead.Offer1__c';
import PurposeOfUse_FIELD from '@salesforce/schema/Lead.PurposeOfUse__c';
import Bulk_FIELD from '@salesforce/schema/Lead.Bulk__c';
import PropertyReadiness_FIELD from '@salesforce/schema/Lead.PropertyReadiness__c';
import Financing_FIELD from '@salesforce/schema/Lead.Financing__c';
import Mortgage_FIELD from '@salesforce/schema/Lead.Mortgage__c';
import CustomerBudget_FIELD from '@salesforce/schema/Lead.CustomerBudget__c';
import SalesOrigin_FIELD from '@salesforce/schema/Lead.SalesOrigin__c';
import LeadSource_FIELD from '@salesforce/schema/Lead.LeadSource';
import EnquiryCategory_FIELD from '@salesforce/schema/Lead.EnquiryCategory__c';
import EnquiryTrigger_FIELD from '@salesforce/schema/Lead.EnquiryTrigger__c';
import LeadOrigin_FIELD from '@salesforce/schema/Lead.LeadOrigin__c';
import getDependentPickListValues from '@salesforce/apex/Utilities.getDependentPickListValues';
import getValidateEmail from '@salesforce/apex/EmailValidation.getValidateEmailWithAura';
import getValidatePhoneNoWithAura from '@salesforce/apex/PhoneNoValidation.getValidatePhoneNoWithAura';
import createLead from '@salesforce/apex/BrokerLeadController.createLead';
import getsObjectType from '@salesforce/apex/BrokerLeadController.getsObjectType';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCountryCodeValues from '@salesforce/apex/BrokerLeadController.getCountryCodeValues';
import getEmiratesValues from '@salesforce/apex/BrokerLeadController.getEmiratesValues';
import EnableDisableButtons from '@salesforce/apex/LEX_UploadDocumentsController.EnableDisableButtons';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
//import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import getProfileInfo from '@salesforce/apex/PortalAPIs.getProfileInfo';
// Added By Moh Sarfaraj for BPE-279
import validateBrokersEmailMobileForLeadCreation from '@salesforce/apex/BrokerLeadController.validateBrokersEmailMobileForLeadCreation';
import addLeadconfirmationText from '@salesforce/label/c.BPM_AddLeadConfirmationText';
const DELAY = 3000;

export default class AddLeadModal extends LightningElement {

    @wire(getValidateEmail, { email: '$emailAddress' })
    emailResponse;

    @wire(getValidatePhoneNoWithAura, { phoneNo: '$mobileNumberToCheck' })
    mobileResponse;

   // @api recordId;
    @track prfName;
    blockSales;
    @api mobileNumberToCheck;
    @track mobileNumber;
    @track oldMobile;
    @track oldMobileReal;
    @track countryCode;
    @api title;
    @api firstName;
    @api lastName;
    @api emailAddress;
    @track oldEmail;
    @track oldEmailReal;
    @api residanceCountry;
    @track nationality;
    @api residentStatus;
    @track emiratesID;
    @track passportNumber;
    @track passportExpiryDate;
    @track city;
    @api salesType;
    @track propertyUsage;
    @track buyRent;
    @track property;
    @track unitType;
    @track numberOfBeds;
    @track events;
    @track purposeOfUse;
    @track bulk;
    @track propertyReadiness;
    @track financing;
    @track mortgage;
    @track mortgagePicklist;
    @track customerBudget;
    @track propertyUsagePicklist;
    @track buyRentPicklist;
    @track projectPicklist;
    @track unitTypePicklist;
    @track residentCountryPicklist;
    @track showPassportFields = false;
    @track showEmiratesIdField = false;
    @track errorDetails;
    @track errorDialog;
    @track sObjectRecord;
    @track sObjectRecordType;
    @api recordId;
    @api action;
    @track showSpinner = false;
    @track disableButton = false;
    @track disableAddLead = false;
    leadId;
    todaysDate;
    @track EmiratesValues;
    @api isLoaded = false;
    @track mobileCountryCodePicklist2;
    @api new;
    @track salesTypePicklist;
    @track pageTitle = 'Add a Lead';
    @track salesOrigin;
    @track leadOrigin;
    @track leadOriginPicklist;
    @track enquiryCategory;
    @track enquiryCategoryList;
    @track enquiryTrigger;
    @track enquiryTriggerList;
    //Below is added by Tharun as per BPM-360 - consent
    isConsentChecked;
    // Added By Moh Sarfaraj for BPE-196
    @track disabledContactInfo = false;
    
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadMetadata;
    
    @api isResaleUnit;
    @api resaleUnitId;
    @api resaleUnitSalesOrderId;
    // @api resaleUnitListedCase;
    showConfirmLeadModal =  false; confirmationTextToShow = addLeadconfirmationText;

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }
    get leadTypes() {
        return [
            { label: 'Person', value: 'Person' },
            { label: 'Organization', value: 'Organization' }
        ];
    }
    async test() {

        //this.accountDetils = this.template.querySelector('c-lead-details').accountDetils;

        await getsObjectType({ recordID: this.recordId })
            .then(data => {

                for (var key in data) {
                    this.sObjectRecordType = key;
                    this.sObjectRecord = data[key];
                }

                if (this.sObjectRecordType == 'Contact') {

                    this.title = this.sObjectRecord.Salutation;
                    this.firstName = this.sObjectRecord.FirstName;
                    this.lastName = this.sObjectRecord.LastName;
                    this.countryCode = this.sObjectRecord.Account.MobileCountryCode__c;
                    this.mobileNumber = this.sObjectRecord.MobilePhone__c;
                    this.emailAddress = this.sObjectRecord.Email;
                    this.residentStatus = this.sObjectRecord.ResidentStatus__c;
                    this.nationality = this.sObjectRecord.Nationality__c;
                    this.residanceCountry = this.sObjectRecord.CountryOfResidence__c;
                    this.city = this.sObjectRecord.MailingCity__c;
                    this.passportNumber = this.sObjectRecord.PassportNumber__c;
                    this.passportExpiryDate = this.sObjectRecord.PassportExpiryDate__c;
                    this.emiratesID = this.sObjectRecord.Account.NationalIdNumber__pc;

                    this.residentCountryPicklist = [];

                    if (this.residentStatus === 'Resident') {
                        this.showEmiratesIdField = true;
                        this.showPassportFields = false;
                        this.residentCountryPicklist.push({
                            label: 'United Arab Emirates',
                            value: 'United Arab Emirates'
                        });
                    } else {
                        this.showEmiratesIdField = false;
                        this.showPassportFields = true;
                        for (let i = 0; i < this.nationalityPicklist.data.values.length; i++) {

                            this.residentCountryPicklist.push({
                                label: this.nationalityPicklist.data.values[i].label,
                                value: this.nationalityPicklist.data.values[i].value
                            });
                        }
                    }

                } else if (this.sObjectRecordType == 'Lead') {

                    this.leadId = this.sObjectRecord.Id;
                    this.title = this.sObjectRecord.Salutation;
                    this.firstName = this.sObjectRecord.FirstName;
                    this.lastName = this.sObjectRecord.LastName;
                    this.countryCode = this.sObjectRecord.MobileCountryCode__c;
                    this.mobileNumber = this.sObjectRecord.MobileNumber1__c;
                    this.oldMobile = this.sObjectRecord.MobileCountryCode__c + this.sObjectRecord.MobileNumber1__c;
                    this.oldMobileReal = this.sObjectRecord.MobileNumber__c;
                    this.emailAddress = this.sObjectRecord.Email;
                    this.oldEmail = this.sObjectRecord.Email;
                    this.oldEmailReal = this.sObjectRecord.EmailAddress__c
                    this.residentStatus = this.sObjectRecord.ResidentStatus__c;
                    this.nationality = this.sObjectRecord.Nationality__c;
                    this.residanceCountry = this.sObjectRecord.CountryOfResidence__c;
                    this.city = this.sObjectRecord.City;
                    this.passportNumber = this.sObjectRecord.PassportNumber__c;
                    this.passportExpiryDate = this.sObjectRecord.PassportExpiryDate__c;
                    this.emiratesID = this.sObjectRecord.NationalId__c;
                    this.salesOrigin = this.sObjectRecord.SalesOrigin__c;
                    this.leadOrigin = this.sObjectRecord.LeadOrigin__c;
                    this.enquiryCategory = this.sObjectRecord.EnquiryCategory__c;
                    this.enquiryTrigger = this.sObjectRecord.EnquiryTrigger__c;
                    
                   
                    if (this.action != 'add') {
                        this.pageTitle = 'Edit a Lead';
                        this.salesType = this.sObjectRecord.SalesType__c;
                        this.propertyUsage = this.sObjectRecord.PropertyUsage__c == 'Residential Sale' ? 'Residential' : this.sObjectRecord.PropertyUsage__c;
                        this.buyRent = this.sObjectRecord.BuyRent__c;
                        this.property = this.sObjectRecord.Project__c;
                        this.unitType = this.sObjectRecord.UnitType__c;
                        this.numberOfBeds = this.sObjectRecord.NumberOfBedrooms__c;
                        this.events = this.sObjectRecord.Offer1__c;
                        this.purposeOfUse = this.sObjectRecord.PurposeOfUse__c;
                        this.bulk = this.sObjectRecord.Bulk__c;
                        this.propertyReadiness = this.sObjectRecord.PropertyReadiness__c;
                        this.financing = this.sObjectRecord.Financing__c;
                        this.mortgage = this.sObjectRecord.Mortgage__c;
                        this.customerBudget = this.sObjectRecord.CustomerBudget__c;
                        this.showEmiratesDropDown = (this.sObjectRecord.CountryOfResidence__c == 'United Arab Emirates')
                        this.company = this.sObjectRecord.Company;
                        this.isOrganization = (this.sObjectRecord.Company!=null);
                        this.leadType = this.isOrganization ? 'Organization':'Person';
                        // Added By Moh Sarfaraj for BPE-196
                        this.disabledContactInfo = true;

                    } else {
                        this.leadId = '';
                        // Added By Moh Sarfaraj for BPE-196
                        this.disabledContactInfo = false;
                    }
                    this.residentCountryPicklist = [];

                    if (this.residentStatus === 'Resident') {
                        this.showEmiratesIdField = true;
                        this.showPassportFields = false;
                        this.residentCountryPicklist.push({
                            label: 'United Arab Emirates',
                            value: 'United Arab Emirates'
                        });
                    } else {
                        this.showEmiratesIdField = false;
                        this.showPassportFields = true;
                        for (let i = 0; i < this.nationalityPicklist.data.values.length; i++) {

                            this.residentCountryPicklist.push({
                                label: this.nationalityPicklist.data.values[i].label,
                                value: this.nationalityPicklist.data.values[i].value
                            });
                        }
                    }

                    /*this.propertyUsagePicklist = this.getPicklistOptions(SalesType_FIELD.fieldApiName, PropertyUsage_FIELD.fieldApiName, this.salesType);
                    this.buyRentPicklist = this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, BuyRent_FIELD.fieldApiName, this.propertyUsage);
                    this.projectPicklist = this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, Project_FIELD.fieldApiName, this.propertyUsage);
                    this.unitTypePicklist = this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, UnitType_FIELD.fieldApiName, this.propertyUsage);
                    this.customerBudgetPicklist = this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, CustomerBudget_FIELD.fieldApiName, this.propertyUsage);*/

                }

            })
            .catch(error => {
                this.showToast('Error', JSON.stringify(error), 'error');
                this.sObjectRecordType = undefined;
                this.sObjectRecord = undefined;
                this.isLoading = false;
            });

        if (this.sObjectRecordType == 'Lead' && this.action != 'add') {

            this.propertyUsagePicklist = await this.getPicklistOptions(SalesType_FIELD.fieldApiName, PropertyUsage_FIELD.fieldApiName, this.salesType);
            this.buyRentPicklist = await this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, BuyRent_FIELD.fieldApiName, this.propertyUsage);
            this.projectPicklist = await this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, Project_FIELD.fieldApiName, this.propertyUsage);
            this.unitTypePicklist = await this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, UnitType_FIELD.fieldApiName, this.propertyUsage);
            this.customerBudgetPicklist = await this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, CustomerBudget_FIELD.fieldApiName, this.propertyUsage);

            if (this.financing != 'No') {
                this.mortgagePicklist = await this.getPicklistOptions(Financing_FIELD.fieldApiName, Mortgage_FIELD.fieldApiName, this.financing);
            }
        }
        if(this.salesOrigin != null){
            this.leadOriginPicklist = await this.getPicklistOptions(SalesOrigin_FIELD.fieldApiName, LeadOrigin_FIELD.fieldApiName, this.salesOrigin);
        }
        if (this.enquiryCategory != null) {
            this.enquiryTriggerList = await this.getPicklistOptions(EnquiryCategory_FIELD.fieldApiName, EnquiryTrigger_FIELD.fieldApiName, this.enquiryCategory);
        }
    }

    getCountryCodeValues() {

        getCountryCodeValues().then((response) => {
            this.mobileCountryCodePicklist2 = response;
        }).catch(error => {
            this.showToast('Error', JSON.stringify(error), 'error');
        });

    }

    getEmiratesValues() {

        getEmiratesValues().then((response) => {

            this.EmiratesValues = response;
        }).catch(error => {
            this.showToast('Error', JSON.stringify(error), 'error');
        });

    }

    getProfileInfo() {
        getProfileInfo().then((response) => {
            this.prfName = response.Profile.Name;
            this.blockSales = response.Contact.BlockSales__c;
            if(this.prfName=='Agency Admin' || this.prfName=='Agency Admin with Limited Access' || this.prfName=='Agency Admin Login' || this.prfName=='Agency Admin with Limited Access Login') 
            {
                this.disableAddLead=true;
            }else if(this.blockSales)
            {
                this.disableAddLead=true;
            }
        }).catch(error => {
            this.showToast('Error', JSON.stringify(error), 'error');
        });
    }
    

    

    async connectedCallback() {

        
        this.getProfileInfo();
        console.log('RRR2 Profile ' + this.prfName);
        this.getCountryCodeValues();
        this.getEmiratesValues();
        this.showSpinner = true;

        var today = new Date();
        this.todaysDate = today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + today.getDate();

        this.enquiryCategoryList = await this.getPicklistOptions(LeadSource_FIELD.fieldApiName, EnquiryCategory_FIELD.fieldApiName, 'Broker Portal');
        if (this.recordId != null) {
            setTimeout(() => {
                this.test();
            }, 2000);
        }


        setTimeout(() => {
            this.showSpinner = false;
        }, 2000);
    }
    showEmiratesDropDown=true;
    async validateDate(dataId, value) {

        const isInputsCorrect = await [...this.template.querySelectorAll('[data-id="' + dataId + '"]')]
            .reduce((validSoFar, inputField) => {

                if (value == null) {
                    inputField.setCustomValidity('Your entry does not match the allowed format dd/MM/yyyy.');
                } else {
                    inputField.setCustomValidity('');
                }

                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
    }

    async handlePhoneNumberBlur(event)
    {
        let enteredMobNumber    = event.target.value;
        if(enteredMobNumber != ''){
            let mob                 = enteredMobNumber.replace(/[^0-9]/g,'');
            let mobNumber           = parseInt(mob);
            this.mobileNumber       = mobNumber.toString();
        }
        this.mobileNumberToCheck = this.countryCode + this.mobileNumber;
        let target = await this.template.querySelector('[data-id="mobileNumber"]');
        await getValidatePhoneNoWithAura({
            phoneNo : this.mobileNumberToCheck
        }).then(result => {
            if (!result) {
                target.setCustomValidity("Enter Valid Mobile Number.");
            } else {
                target.setCustomValidity("");
                // Added By Moh Sarfaraj for BPE-279 commneted for performance testing
                this.brokerEmailMobileValidation(this.mobileNumber, 'mobile');
            }
            target.reportValidity();
        }).catch(error =>{
            console.log(error);
        });
    }

    async handleChange(event) {
        var value = event.target.value;

        if (event.target.dataset.id === 'mobileNumber') {
            this.mobileNumber = value;
            let target = this.template.querySelector('[data-id="mobileNumber"]');
            if (/^[0-9]*$/.test(value))
            {
                this.mobileNumber = value;
                target.setCustomValidity("");
            }else{
                target.setCustomValidity("Enter Numbers only.");
            }
            target.reportValidity();
            /*
            this.mobileNumberToCheck = this.countryCode + this.mobileNumber;
            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="mobileNumber"]');

                if (!this.mobileResponse.data && this.oldMobile != this.mobileNumberToCheck) {
                    target.setCustomValidity("Enter Valid Mobile Number.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
            */
        } else if (event.target.dataset.id === 'countryCode') {
            this.countryCode = value;
            if(this.mobileNumber)
            {
                this.mobileNumberToCheck = this.countryCode + this.mobileNumber;
                this.delayTimeout = setTimeout(async () => {
                    let target = await this.template.querySelector('[data-id="mobileNumber"]');

                    if (!this.mobileResponse.data && this.oldMobile != this.mobileNumberToCheck) {
                        target.setCustomValidity("Enter Valid Mobile Number.")
                    } else {
                        target.setCustomValidity("");
                    }
                    target.reportValidity();
                }, DELAY);
            }
        } else if (event.target.dataset.id === 'title') {
            this.title = value;
        } else if (event.target.dataset.id === 'firstName') {
            this.firstName = value;
        } else if (event.target.dataset.id === 'lastName') {
            this.lastName = value;
        } else if (event.target.dataset.id === 'emailAddress') {
            this.emailAddress = value;
            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="emailAddress"]');
                if (!this.emailResponse.data && this.oldEmail != this.emailAddress) {
                    target.setCustomValidity("Enter Valid Email.")
                } else {
                    target.setCustomValidity("");
                    // Added By Moh Sarfaraj for BPE-279 commented for performance testing
                    this.brokerEmailMobileValidation(this.emailAddress, 'email');
                }
                target.reportValidity();
            }, DELAY);
        } else if (event.target.dataset.id === 'residanceCountry') {
            this.showEmiratesDropDown = (value == 'United Arab Emirates');
            this.residanceCountry = value;
        } else if (event.target.dataset.id === 'nationality') {
            this.nationality = value;
        } else if (event.target.dataset.id === 'acceptConsent') {
            this.isConsentChecked = event.target.checked;
        } else if (event.target.dataset.id === 'residentStatus') {

            this.residentCountryPicklist = [];
            // Added By Moh Sarfaraj for BPE-269
            this.residanceCountry = null;

            if (value === 'Resident') {
                this.showEmiratesIdField = true;
                this.showPassportFields = false;
                this.residentCountryPicklist.push({
                    label: 'United Arab Emirates',
                    value: 'United Arab Emirates'
                });
                // Added By Moh Sarfaraj for BPE-269
                this.residanceCountry = 'United Arab Emirates';
                this.showEmiratesDropDown = true;
            } else {
                // Added By Moh Sarfaraj for BPE-269
                this.city = '';
                this.emiratesID = '';
                this.showEmiratesDropDown = false;

                this.showEmiratesIdField = false;
                this.showPassportFields = true;
                for (let i = 0; i < this.nationalityPicklist.data.values.length; i++) {

                    this.residentCountryPicklist.push({
                        label: this.nationalityPicklist.data.values[i].label,
                        value: this.nationalityPicklist.data.values[i].value
                    });
                }
            }
            this.residentStatus = value;
        } else if (event.target.dataset.id === 'emiratesID') {
            this.emiratesID = value;
        } else if (event.target.dataset.id === 'passportNumber') {
            this.passportNumber = value;
        } else if (event.target.dataset.id === 'passportExpiryDate') {
            this.passportExpiryDate = value;
            this.validateDate('passportExpiryDate', this.passportExpiryDate);
        } else if (event.target.dataset.id === 'city') {
            this.city = value;
        } else if (event.target.dataset.id === 'salesType') {

            this.showSpinner = true;

            this.propertyUsagePicklist = await this.getPicklistOptions(SalesType_FIELD.fieldApiName, PropertyUsage_FIELD.fieldApiName, value);

            this.salesType = value;
            this.propertyUsage = null;
            this.buyRent = null;
            this.property = null;
            this.unitType = null;
            this.customerBudget = null;
            this.customerBudgetPicklist = [];
            this.unitTypePicklist = [];
            this.projectPicklist = [];
            this.buyRentPicklist = [];

            this.showSpinner = false;

        } else if (event.target.dataset.id === 'propertyUsage') {

            this.showSpinner = true;

            this.buyRentPicklist = await this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, BuyRent_FIELD.fieldApiName, value);
            this.projectPicklist = await this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, Project_FIELD.fieldApiName, value);
            this.unitTypePicklist = await this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, UnitType_FIELD.fieldApiName, value);
            this.customerBudgetPicklist = await this.getPicklistOptions(PropertyUsage_FIELD.fieldApiName, CustomerBudget_FIELD.fieldApiName, value);

            this.propertyUsage = value;
            this.buyRent = null;
            this.property = null;
            this.unitType = null;
            this.customerBudget = null;

            this.showSpinner = false;

        } else if (event.target.dataset.id === 'buyRent') {
            this.buyRent = value;
        } else if (event.target.dataset.id === 'property') {
            this.property = value;
        } else if (event.target.dataset.id === 'unitType') {
            this.unitType = value;
        } else if (event.target.dataset.id === 'numberOfBeds') {
            this.numberOfBeds = value;
        } else if (event.target.dataset.id === 'events') {
            this.events = value;
        } else if (event.target.dataset.id === 'purposeOfUse') {
            this.purposeOfUse = value;
        } else if (event.target.dataset.id === 'bulk') {
            this.bulk = value;
        } else if (event.target.dataset.id === 'propertyReadiness') {
            this.propertyReadiness = value;
        } else if (event.target.dataset.id === 'financing') {
            this.mortgagePicklist = null;
            this.showSpinner = true;
            this.mortgage = null;

            if (value != 'No') {
                this.mortgagePicklist = await this.getPicklistOptions(Financing_FIELD.fieldApiName, Mortgage_FIELD.fieldApiName, value);
            }
            this.financing = value;

            this.showSpinner = false;

        } else if (event.target.dataset.id === 'mortgage') {
            this.mortgage = value;
        } else if (event.target.dataset.id === 'customerBudget') {
            this.customerBudget = value;
        } else if (event.target.dataset.id === 'salesOrigin') {
            this.salesOrigin = value;
            this.leadOrigin = null;
            this.showSpinner = true;
            this.leadOriginPicklist = await this.getPicklistOptions(SalesOrigin_FIELD.fieldApiName, LeadOrigin_FIELD.fieldApiName, value);
            this.showSpinner = false;
        } else if (event.target.dataset.id === 'leadOrigin') {
            this.leadOrigin = value;
        } else if (event.target.dataset.id === 'enquiryCategory') {
            this.enquiryCategory = value;
            this.enquiryTrigger = null;
            this.showSpinner = true;
            this.enquiryTriggerList = await this.getPicklistOptions(EnquiryCategory_FIELD.fieldApiName, EnquiryTrigger_FIELD.fieldApiName, value);
            this.showSpinner = false;
        } else if (event.target.dataset.id === 'enquiryTrigger') {
            this.enquiryTrigger = value;
        } else if (event.target.dataset.id === 'leadType') {
            
            if(value=='Person'){
                this.isOrganization=false;
            }else if(value=='Organization'){
                this.isOrganization=true;
            }
        } else if (event.target.dataset.id === 'Company') {
            this.company = value;
        } 
    }

    handleEmailBlur(event){
        this.delayTimeout = setTimeout(async () => {
            let target = this.template.querySelector('[data-id="emailAddress"]');

            if (!this.emailResponse.data && this.oldEmail != this.emailAddress) {
                target.setCustomValidity("Enter Valid Email.")
            } else {
                target.setCustomValidity("");
                // Added By Moh Sarfaraj for BPE-279 commented for performance testing
                this.brokerEmailMobileValidation(this.emailAddress, 'email');
            }
            target.reportValidity();
        }, DELAY);
    }

    // Added By Moh Sarfaraj for BPE-279
    async brokerEmailMobileValidation(value, type){
        await validateBrokersEmailMobileForLeadCreation({
            value : value, type : type
        }).then(results=>{ 
            if(type == 'email'){
                this.delayTimeout = setTimeout(async () => {
                    let target = this.template.querySelector('[data-id="emailAddress"]');
                    if (results != 'Yes') {
                        target.setCustomValidity("This Email is already associated with Broker")
                    } else {
                        target.setCustomValidity("");
                    }
                    target.reportValidity();
                }, DELAY);
            }else if(type == 'mobile'){
                this.delayTimeout = setTimeout(async () => {
                    let target =  this.template.querySelector('[data-id="mobileNumber"]');

                    if (results != 'Yes') {
                        target.setCustomValidity("This Mobile is already associated with Broker");
                    } else {
                        target.setCustomValidity("");
                    }
                    target.reportValidity();
                }, DELAY);
            }
        }).catch(error=>{
        })
    }

    isOrganization=false;
    company='';

    isEmpty(obj) {
        for (var key in obj) {
            if (obj.hasOwnProperty(key))
                return false;
        }
        return true;
    }

    async handleSubmit() {
        this.showSpinner = true;
        this.disableButton = true;
        this.errorDialog = false;
        this.errorDetails = [];

        if (this.isInputsCorrect) {
            const leadInfoObject = {
                title: this.title,
                countryCode: this.countryCode,
                mobileNumber: this.mobileNumber,
                realMobileNumber: this.oldMobileReal,
                firstName: this.firstName,
                lastName: this.lastName,
                emailAddress: this.emailAddress,
                realEmail: this.oldEmailReal,
                residentStatus: this.residentStatus,
                nationality: this.nationality,
                city: this.city,
                emiratesID: this.emiratesID,
                passportNumber: this.passportNumber,
                passportExpiryDate: this.passportExpiryDate,
                salesType: this.salesType,
                propertyUsage: this.propertyUsage == 'Residential' ? 'Residential Sale' : this.propertyUsage,
                buyRent: this.buyRent,
                property: this.property,
                unitType: this.unitType,
                numberOfBeds: this.numberOfBeds,
                events: this.events,
                purposeOfUse: this.purposeOfUse,
                bulk: this.bulk,
                propertyReadiness: this.propertyReadiness,
                financing: this.financing,
                mortgage: this.mortgage,
                customerBudget: this.customerBudget,
                leadId: this.leadId,
                residanceCountry: this.residanceCountry,
                salesOrigin: this.salesOrigin,
                leadOrigin: this.leadOrigin,
                enquiryCategory: this.enquiryCategory,
                enquiryTrigger: this.enquiryTrigger,
                company: this.isOrganization? this.company:'',
                consent: this.isConsentChecked
            };

            var isResaleUnit = this.isResaleUnit;
            if(isResaleUnit){
                leadInfoObject.isResaleUnit = isResaleUnit;
                leadInfoObject.resaleUnitId = this.resaleUnitId;
                leadInfoObject.resaleUnitSalesOrderId = this.resaleUnitSalesOrderId;
                // leadInfoObject.resaleUnitListedCase = this.resaleUnitListedCase;
            }

            console.log(leadInfoObject);
            this.new = leadInfoObject;
            await createLead({ leadInfoObject: leadInfoObject })
                .then(result => {

                    if (result == 'Duplicate') {
                        this.showToast('Error', 'Kindly note that there already exists a lead with the below details', 'error');
                        this.errorDetails.push('Kindly note that there already exists a lead with the below details');
                    } else if (result == 'Success') {
                    }
                })
                .catch(error => {

                    if (error.body && error.body.pageErrors && error.body.pageErrors[0] && error.body.pageErrors[0].message != null) {
                        this.errorDetails.push(error.body.pageErrors[0].message);
                        this.showToast('Error', error.body.pageErrors[0].message, 'error');
                    } else {
                        this.showToast('Error', 'Kindly note that there already exists a lead with the below details', 'error');
                        console.log('createLead Error: ' + JSON.stringify(error));
                        this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    }
                });

            if (this.errorDetails.length > 0) {
                this.errorDialog = true;
            } else if (!this.isInputsCorrect) {
            } else {
                this.test();
                this.closeModal();
            }
        }
        this.showSpinner = false;
        this.disableButton = false;
    }

    removeError() {
        this.errorDialog = false;
        this.errorDetails = [];
    }

    async getPicklistOptions(controllingField, dependentField, pickedValue) {

        const picklistOptions = [];
        await getDependentPickListValues({ objectName: BuyRent_FIELD.objectApiName, controllingField: controllingField, dependentField: dependentField })
            .then(result => {

                for (let i = 0; i < result[pickedValue].length; i++) {

                    picklistOptions.push({
                        label: result[pickedValue][i],
                        value: result[pickedValue][i]
                    });
                }
            })
            .catch(error => {
                this.showToast('Error', JSON.stringify(error), 'error');
            });

        return picklistOptions;
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false, new: this.new } }));
    }

    closeConfirmLeadModal(){
        this.showConfirmLeadModal = false;
    }

    backConfirmation(){
        this.showConfirmLeadModal = false;
    }

    isInputsCorrect;

    // Added by Moh Sarfaraj for BPM-314
    submitBeforeConfirmation(){
        this.isInputsCorrect = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if(this.isInputsCorrect){
            this.showConfirmLeadModal = true;
        }
    }

    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: Title_FIELD
        }
    )
    titlePicklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: CustomerBudget_FIELD
        }
    )
    customerBudgetPicklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: ResidentStatus_FIELD
        }
    )
    residentStatusPicklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: Nationality_FIELD
        }
    )
    nationalityPicklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: SalesType_FIELD
        }
    )
    async salesTypePicklistFromSF({ error, data }) {
        if (data) {
            console.log('salesTypePicklistFromSF: ' + JSON.stringify(data));

            this.salesTypePicklist = [];
            for (let i = 0; i < data.values.length; i++) {

                if (data.values[i].label != 'Institutional' && data.values[i].label != 'Asset Management') {
                    if (data.values[i].label == 'Residential Sale') {
                        this.salesTypePicklist.push({
                            label: 'Residential',
                            value: data.values[i].value
                        });
                    } else {
                        this.salesTypePicklist.push({
                            label: data.values[i].label,
                            value: data.values[i].value
                        });
                    }
                }
            }
            console.log('salesTypePicklist: ' + JSON.stringify(this.salesTypePicklist));
        }
    };

    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: NumberOfBedrooms_FIELD
        }
    )
    numberOfBedroomsPicklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: Offer1_FIELD
        }
    )
    offer1Picklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: PurposeOfUse_FIELD
        }
    )
    purposeOfUsePicklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: Bulk_FIELD
        }
    )
    bulkPicklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: PropertyReadiness_FIELD
        }
    )
    propertyReadinessPicklist;
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: Financing_FIELD
        }
    )
    financingPicklist;

    @wire(getPicklistValues,
        {
            recordTypeId: '$leadMetadata.data.defaultRecordTypeId',
            fieldApiName: SalesOrigin_FIELD
        }
    )
    salesOriginPicklist;
}