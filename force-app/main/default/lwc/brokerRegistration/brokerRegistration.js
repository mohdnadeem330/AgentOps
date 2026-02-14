import { LightningElement, wire, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
// import portalThemeCss from '@salesforce/resourceUrl/portalThemeCss';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Service_Request_OBJECT from '@salesforce/schema/HexaBPM__Service_Request__c';
import Agency_Team_OBJECT from '@salesforce/schema/AgencyTeam__c';
import Agent_Title_FIELD from '@salesforce/schema/AgencyTeam__c.Title__c';
import Country_FIELD from '@salesforce/schema/HexaBPM__Service_Request__c.Country__c';
import getValidateEmail from '@salesforce/apex/EmailValidation.getValidateEmailWithAura';
import getValidatePhoneNoWithAura from '@salesforce/apex/PhoneNoValidation.getValidatePhoneNoWithAura';
import createServiceRequestRecord from '@salesforce/apex/BrokerAgencyRegistrationController.createServiceRequestRecord';
import attachDocuments from '@salesforce/apex/BrokerAgencyRegistrationController.attachDocuments';
import createAgencyTeamRecord from '@salesforce/apex/BrokerAgencyRegistrationController.createAgencyTeamRecord';
import getAgenciesByLicenseNumberAndEmail from '@salesforce/apex/BrokerAgencyRegistrationController.getAgenciesByLicenseNumberAndEmail';
import getServicesRequestsByLicenseNumberAndEmail from '@salesforce/apex/BrokerAgencyRegistrationController.getServicesRequestsByLicenseNumberAndEmail';
import getServiceRequestByEmailAndLicenseNumber from '@salesforce/apex/BrokerAgencyRegistrationController.getServiceRequestByEmailAndLicenseNumber';
import uploadFile from '@salesforce/apex/BrokerAgencyRegistrationController.uploadFile';
import uploadFiles from '@salesforce/apex/BrokerAgencyRegistrationController.uploadFiles';
import getOtpDetails from '@salesforce/apex/BrokerAgencyRegistrationController.getOtpDetails';
import getAllConstants from '@salesforce/apex/BrokerAgencyRegistrationController.getAllConstants';
import updateServiceRequestRecordStatus from '@salesforce/apex/BrokerAgencyRegistrationController.updateServiceRequestRecordStatus';
import getValidateIBAN from '@salesforce/apex/IBANValidation.getValidateIbanWithAura';
import updateAgencyTeam from '@salesforce/apex/BrokerAgencyRegistrationController.updateAgencyTeam';
import getServiceRequest from '@salesforce/apex/BrokerAgencyRegistrationController.getServiceRequest';
import getAgencyTeam from '@salesforce/apex/BrokerAgencyRegistrationController.getAgencyTeam';
import getServiceRequestStep from '@salesforce/apex/BrokerAgencyRegistrationController.getServiceRequestStep';
import updateServiceRequestStep from '@salesforce/apex/BrokerAgencyRegistrationController.updateServiceRequestStep';
import getUploadedFiles from '@salesforce/apex/BrokerAgencyRegistrationController.getUploadedFiles';
import getAgencyTeamByEmail from '@salesforce/apex/BrokerAgencyRegistrationController.getAgencyTeamByEmail';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getCountryCodeValues from '@salesforce/apex/BrokerAgencyRegistrationController.getCountryCodeValues';
import getConstant from '@salesforce/apex/BrokerAgencyRegistrationController.getConstant';
import PortalLoginURL from '@salesforce/label/c.PortalLoginURL';
import getBrokerAndSalesManagers from '@salesforce/apex/BrokerAgencyRegistrationController.getBrokerAndSalesManagers';
import VATLetterTemplate from '@salesforce/resourceUrl/VATLetterTemplate';
import getUsersQuery from '@salesforce/apex/BrokerAgencyRegistrationController.getUsersQuery';
import validateTradeLicenseNumber from '@salesforce/apex/BrokerAgencyRegistrationController.validateTradeLicenseNumber';
import resendOTPForTradeLicenseNumber  from '@salesforce/apex/BrokerAgencyRegistrationController.resendOTPForTradeLicenseNumber';
import BrokerAgencyLoginURL from '@salesforce/label/c.BrokerAgencyRegistrationURL';
import GoAMLLinkURL from '@salesforce/label/c.GoAML_Link';
// Added By Moh Sarfaraj for BPE-120
import blacklistedDomains from '@salesforce/label/c.BlacklistedDomains';
import getIntPropLocation from '@salesforce/apex/BrokerAgencyRegistrationController.getPicklistValuesGeneric';
import {
    COUNTRIES,
    STATES, 
} from './countriesStates';
import * as VALIDATIONS from "./validations";
import PartnerOwnersDuplicateEnable from '@salesforce/label/c.BPM_PartnerOwnersDuplicateEnable';
import LegalEntityConsent from '@salesforce/label/c.BPM_LegalEntity_Consent';
const DELAY = 3000;


export default class BrokerRegistration extends NavigationMixin(LightningElement) {

    verifiedBool = true;
    captchaResponse;
    phoneNumberCountryCode;
    phoneNumberCountryCodeChosed = '971';
    contactPersonCountryCode = '971';

    // Added by Tharun on 30 March
     queryBrokerAssociates = 'SELECT Title, FirstName, LastName, Email, MobilePhone, IsActive, Team__c FROM User WHERE IsActive = True AND ShowOnBrokerPortal__c = true AND MobilePhone != null AND Team__c IN (\'DXB\',\'AUH\') ORDER BY FirstName ASC';
     brokerAUHTeamArray = [];
     brokerDXBTeamArray = [];

    loginURL = BrokerAgencyLoginURL.split("/").slice(0,3).join("/");
    GoAMLLink = GoAMLLinkURL;
    multipleSelection = true;
    informationTooltipIcon = resourcesPath + "/ALDARResources/svg/InformationTooltip.svg";
    infoIcon = resourcesPath + "/ALDARResources/svg/InfoIcon.svg";
    vatLetterTemplate = VATLetterTemplate;
    title = "Agency Registration";
    titleDetails = "";
     country;
     agencyName;
     establishmentDate;
     licenseNumber;
     existinglicenseNumber;
     expiryDate;
     phoneNumber;
     companyEmail;
     addressLine1;
     addressLine2;
     state;
     city;
     poBox;
     taxRegistrationCertificate;
     website;
    text = "test text";
     srName;
     srExternalStatus;
     id;
     nameOfPOA;
     attorneyTitle;
     ownerTitle;
     ownerName;
     ownerCountry;
     partnerOwnerDetails;
     shareHoldingPercentage;
     ownerMobCountryCode;
     ownerMobileNumber;
     ownerEmail;
     sumOfShareHoldingPercentage;
     ownerRecordId;
     bankName;
     IBANNumber;
     swiftCode;
     branchAddress;
     bankAccountNumber;
     bankCountry;
     agencyTitle;
     contactPersonName;
     contactMiddleName;
     contactLastName;
     contactPersonMobileNumber;
     contactPersonEmailID;
     dateofBirth;
     referredByTitle;
     referredBy;
     authorizedSignatoryTitle;
     authorizedSignatoryName;
     designation;
     authorizedSignatoryEmail;
     hasActiveSRWithLicenseNumber = false;
    activeSections = [];
     serviceRequestId;
     fileData;
     errorDialog;
     errorDetails = [];

     srMap;
     phoneNumberResponse = false;
     contactMobileNumberResponse = false;
     emailResponse = false;
     contactEmailIdResponse = false;
     existingAgencys;
     existingAgencyAdmin;
     existingServicesRequests;
     ibanNumberResponse = false;
     authorizedSignatoryEmailResponse = false;

     otpSection;
    @api isLoaded = false;
     userOTP;
     success;
     agencyAdminType;
     stepStatus;
     serviceRequestStepObj;

     goAMLCertificate = [];
     companyProfileBrochureCatalogue = [];
     attachTradeLicence = [];
     emiratesIDPassportcopyofPOA = [];
     memorandumofAssociationPowerofAttorney = [];
     emiratesIDPassportcopyofPartnerOwner = [];
     signedBankCopy = [];
     vatRegistrationCertificate = [];
     ADMRERACertificate = [];
     @track multiPartnerOwner = false;
     @track partnersOwners = [];
     firstPartnersOwnerFiles = [];
     @track partnersOwnersCount = 0;
     readOnly = false;
     agencyAdminReadOnly = false;
     readOnlyFields = false;
     updateAction = false;
    userId = Id;
     makerequired = true;
    makeRequiredForUAE = false;
    completed = resourcesPath + "/ALDARResources/svg/Completed.svg";
    currentStage = resourcesPath + "/ALDARResources/svg/CurrentStage.svg";
    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";
    isAgencyInformationCompleted = false;
    isAgencyInformationCurrentStage = true;
    isPowerOfAttorneyCompleted = false;
    isPowerOfAttorneyCurrentStage = true;
    isPartnerOwnerDetailsCompleted = false;
    isPartnerOwnerDetailsCurrentStage = true;
    isBankDetailsCompleted = false;
    isBankDetailsCurrentStage = true;
    isAuthorizedSignatorySectionCompleted = false;
    isAgencyAdminInformationCurrentStage = true;
    isAuthorizedSignatoryCompleted = false;
    isAuthorizedSignatoryCurrentStage = true;
    showMessageBox = false;
    _handler;
    todaysDate;
    yesterdayDate;
    tomorrowDate;
    aldarLogo = resourcesPath + "/ALDARResources/png/AldarLogo.png";
     progressBarValue = 0;
     progressBarCompleted = false;
     numberOfFiles = 0;
    @api mobileNumberToCheck = '';
     phoneNumberToCheck = '';
     successSubmit = false;

     notes = '';
     hasNotes = false;
     requiredForInternational = false;
     referredByoptions = [];
     getOTP = false;
     OTPMessage;
    isADM_RERARequired = false;
    // Added by Moh Sarfaraj for BPE-110 & BPM-322
    primaryOwner = true;
    selectedIntPropLocation; gotSelectedIntPropLocation = [];
    wiredIntPropLocations;
    isLegalChecked;
    vatValue;
    showVatUndertakingCertificate = false;
    showVatCertificate = false;
    vatStartDateValue; vatEndDateValue;
    //UAEVATRegistrationNumber;
    label = {LegalEntityConsent};

    get vatOptions() {
        return [
            { label: 'VAT Registration Certificate', value: 'VAT Registration Certificate' },
            { label: 'VAT Undertaking Certificate', value: 'VAT Undertaking Certificate' },
        ];
    }
    @wire(getValidateEmail, { email: '$companyEmail' })
    emailResponseMethod({ error, data }) {
        if (this.companyEmail) {
            let target = this.template.querySelector('[data-id="CompanyEmail"]');
            if (!data) {
                target.setCustomValidity("Enter Valid Email.")
            } else {
                target.setCustomValidity("");
            }
            target.reportValidity();
        }else {}
    };

    @wire(getIntPropLocation,{sObjectName : 'HexaBPM__Service_Request__c',  fieldName : 'InterestedPropertyLocation__c'})
    getIntPropLocationsMethod({data, error}){
        if(data){
            this.wiredIntPropLocations = data;
        }else if(error){
            console.log(JSON.stringify(error));
        }
    };

    fiabciRegistredOptions; fiabciRegistredValue; disabledFiabciStatus = false; requiredFiabciStatus = false;
    @wire(getIntPropLocation,{sObjectName : 'HexaBPM__Service_Request__c',  fieldName : 'FIABCIRegistered__c'})
    getFiabciRegistredOptions({data, error}){
        if(data){
            this.fiabciRegistredOptions = data;
        }else if(error){
            console.log(JSON.stringify(error));
        }
    };

    fiabciStatusOptions;  fiabciStatusValue;
    @wire(getIntPropLocation,{sObjectName : 'HexaBPM__Service_Request__c',  fieldName : 'FIABCIStatus__c'})
    getFiabciStatusOptions({data, error}){
        if(data){
            this.fiabciStatusOptions = data;
        }else if(error){
            console.log(JSON.stringify(error));
        }
    };

    agencyCategoryOptions;  agencyCategoryValue;
    @wire(getIntPropLocation,{sObjectName : 'HexaBPM__Service_Request__c',  fieldName : 'AgencyCategory__c'})
    getAgencyCategory({data, error}){
        if(data){
            this.agencyCategoryOptions = data;
        }else if(error){
            console.log( 'Error ' + JSON.stringify( error ) );
        }
    };

    @wire(getValidatePhoneNoWithAura, { phoneNo: '$mobileNumberToCheck' })
    mobileResponse;

    @wire(getValidatePhoneNoWithAura, { phoneNo: '$phoneNumberToCheck' })
    phoneNumberResponse;

    @wire(getValidateEmail, { email: '$contactPersonEmailID' })
    contactEmailIdResponseMethod({ error, data }) {
        if (this.contactPersonEmailID) {
            let target = this.template.querySelector('[data-id="ContactPersonEmailID"]');
            if (!data) {
                target.setCustomValidity("Enter Valid Email.")
            } else {
                target.setCustomValidity("");
            }
            target.reportValidity();
        } else {
            console.log(error);
        }
    };

    @wire(getValidateEmail, { email: '$authorizedSignatoryEmail' })
    authorizedSignatoryEmailResponseMethod({ error, data }) {

        if (this.authorizedSignatoryEmail) {
            let target = this.template.querySelector('[data-id="AuthorizedSignatoryEmail"]');

            if (!data) {
                target.setCustomValidity("Enter Valid Email.")
            } else {
                target.setCustomValidity("");
            }
            target.reportValidity();
        } else {
            console.log(error);
        }
    };

    // Added by Tharun as per BPE-110
    @wire(getValidateEmail, { email: '$ownerEmail' })
    ownerEmailAddressEmailResponseMethod({ error, data }) {
        if (this.ownerEmail) {
            let target = this.template.querySelector('[data-id="ownerEmailAddress"]');
            if (!data) {
                target.setCustomValidity("Enter Valid Email.")
            } else {
                target.setCustomValidity("");
            }
            target.reportValidity();
        } else {
            console.log(error);
        }
    };
    // Added by Tharun as per BPE-110

    @wire(getValidateIBAN, { ibanNumber: '$IBANNumber' })
    ibanNumberResponse;
     validStates = [];

    helpText = '';
    acceptFileTypeList = [];

    async connectedCallback() {

        this.template.addEventListener('contextmenu', function (e) {
            e.preventDefault();
        });

        this.template.onkeydown = function (e) {
            if (e.keyCode == 123) {
                e.preventDefault();
            }
        }
        
        let fullPath = window.location.href.split('/');
        let pageName = fullPath[fullPath.length - 1];

        getBrokerAndSalesManagers({  })
            .then(result => {
                this.recordsList = result;

                this.referredByoptions = [];

                result.forEach(element => {
                    this.referredByoptions.push({ label: element, value: element });
                });

            })
            .catch(error => {
                this.error = error;
                this.showToast('Error', JSON.stringify(error), 'error');
            })



        await getAllConstants().then(data => {
            if (data) {
                this.srStatus = data.SUBMITTED;
                this.agencyAdminType = data.AGENCY_ADMIN_AURA;
                this.stepStatus = data.REQUIRE_ADDITIONAL_INFORMATION;
            } else {

            }
        })
            .catch(error => {
                this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                console.log('error getAllConstants: ' + JSON.stringify(error));

            });

        getConstant({
            messageName: 'FileAcceptedAgencyRegistration'
        }).then(result => {
            var acceptedFile = result.ConstantValue__c;
            if (acceptedFile != undefined && acceptedFile != null && acceptedFile != '') {
                this.helpText = 'Accepted format are ' + acceptedFile;

                this.acceptFileTypeList = [];
                if (acceptedFile.includes(',')) {
                    this.acceptFileTypeList = acceptedFile.split(',');
                } else {
                    this.acceptFileTypeList.push(acceptedFile);
                }

                for (let i = 0; i < this.acceptFileTypeList.length; i++) {
                    this.acceptFileTypeList[i] = this.acceptFileTypeList[i].trim();
                }
            }
        }).catch(error => {
            console.log(JSON.stringify(error));
            this.showSpinner = false;
        })

        this.getCountryCodeValues();
        var today = new Date();
        this.todaysDate = today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + today.getDate();
        this.yesterdayDate = (today.getFullYear() - 18) + '-' + (today.getMonth() + 1) + '-' + (today.getDate());
        this.tomorrowDate = today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + (today.getDate() + 1);
        this.isLoaded = !this.isLoaded;

        if (this.userId && 'BrokerAgencyRegistration' != pageName) {

            this.makerequired = false;

            this.updateAction = true;

            await getServiceRequest({ userId: this.userId })
                .then(result => {

                    if (result !== null) {
                        this.serviceRequestId = result.Id;
                        this.agencyName = result.AccountName__c;
                        this.licenseNumber = result.TradeCommercialLicenseNumber__c;
                        this.addressLine1 = result.Address1__c;
                        this.addressLine2 = result.Address2__c;
                        this.city = result.City__c;
                        this.state = result.State__c;
                        this.poBox = result.POBox__c;
                        this.country = result.Country__c;
                        this.establishmentDate = result.EstablishmentDate__c;

                        if (this.country == 'United Arab Emirates') {
                            this.requiredForInternational = true;
                        } else {
                            this.requiredForInternational = false;
                        }

                        this.phoneNumber = result.PhoneNumber__c.split(' ')[1];
                        this.phoneNumberCountryCodeChosed = result.PhoneNumber__c.split(' ')[0];

                        this.companyEmail = result.CompanyEmail__c;
                        this.taxRegistrationCertificate = result.TaxRegistrationNumber__c;
                        const regex = /^[a-zA-Z0-9]{15}$/;
                        
                        if (regex.test(this.taxRegistrationCertificate)) {
                            this.taxRegistrationCertificate = result.TaxRegistrationNumber__c;
                        } else {
                            this.taxRegistrationCertificate = '';
                            throw new Error('Invalid Tax Registration Number. It must be exactly 15 alphanumeric characters.');
                        }

                        this.nameOfPOA = result.NameOfPOA__c;

                        this.bankName = result.BankName__c;
                        this.swiftCode = result.SwiftCode__c;
                        this.IBANNumber = result.IBANNumber__c;
                        this.branchAddress = result.BankAddress__c;
                        this.bankAccountNumber = result.BankAccountNumber__c;
                        this.bankCountry = result.BankCountry__c

                        this.expiryDate = result.ExpiryDate__c;
                        this.website = result.Website__c;
                        this.srName = result.Name;
                        this.srExternalStatus = result.HexaBPM__Internal_Status_Name__c;

                        this.attorneyTitle = result.POATitle__c;
                        this.referredByTitle = result.ReferredByTitle__c;
                        this.referredBy = result.ReferredBy__c;
                        this.authorizedSignatoryTitle = result.Title__c;
                        this.authorizedSignatoryName = result.SignatoryName__c;
                        this.designation = result.Designation__c;
                        this.authorizedSignatoryEmail = result.SignatoryEmail__c;
                        this.gotSelectedIntPropLocation = result.InterestedPropertyLocation__c != null ? result.InterestedPropertyLocation__c.split(';') : [];
                        this.agencyCategoryValue = result.AgencyCategory__c;
                        this.isLegalChecked = result.AMLConsent__c

                        let countryIndex = COUNTRIES.indexOf(this.country);
                        let validStates1 = STATES[countryIndex + 1].split('|');
                        validStates1.forEach(element => {
                            this.validStates.push({ label: element, value: element });
                        });
                    } else {
                        this.userId = null;
                    }
                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));
                });

            await getAgencyTeam({ serviceRequestId: this.serviceRequestId })
                .then(result => {
                    if (result != null) {
                        for (let i = 0; i < result.length; i++) {
                            if (result[i].Type__c === this.agencyAdminType) {
                                this.agencyTitle = result[i].Title__c;
                                if (result[i].Name.split(' ').length == 2) {
                                    this.contactPersonName = result[i].Name.split(' ')[0];
                                    this.contactLastName = result[i].Name.split(' ')[1];
                                    this.contactMiddleName = '';
                                } else {
                                    this.contactPersonName = result[i].Name.split(' ')[0];
                                    this.contactMiddleName = result[i].Name.split(' ')[1];
                                    this.contactLastName = result[i].Name.split(' ')[2];
                                }
                                // Updated By Moh Sarfaraj
                                this.contactPersonMobileNumber = result[i].MobileNumber__c; // result[i].MobileNumber__c.split(' ')[1];
                                this.contactPersonCountryCode = result[i].MobileCountryCode__c; // result[i].MobileNumber__c.split(' ')[0];
                                this.contactPersonEmailID = result[i].EmailAddress__c;
                                this.dateofBirth = result[i].DateOfBirth__c;
                            } else {
                                if (this.partnersOwnersCount === 0) {
                                    this.ownerName = result[i].Name;
                                    this.ownerCountry = result[i].Country__c;
                                    this.partnerOwnerDetails = result[i].PartnerOwnerDetails__c;
                                    this.shareHoldingPercentage = String(result[i].ShareHoldingPercentage__c);
                                    this.ownerRecordId = result[i].Id;
                                    this.partnersOwnersCount = this.partnersOwnersCount + 1;
                                    this.ownerTitle = result[i].Title__c;
                                    this.ownerMobCountryCode = result[i].MobileCountryCode__c;
                                    this.ownerMobileNumber = result[i].MobileNumber__c;
                                    this.ownerEmail = result[i].EmailAddress__c;
                                    // Added By Moh Sarfaraj for BPE-110
                                    this.primaryOwner = result[i].PrimaryOwner__c;
                                } else {
                                    // Updated By Moh Sarfaraj for BPE-110
                                    this.partnersOwners.push({
                                        Id: this.partnersOwnersCount, ownerName: result[i].Name, ownerCountry: result[i].Country__c,
                                        partnerOwnerDetails: result[i].PartnerOwnerDetails__c, shareHoldingPercentage: result[i].ShareHoldingPercentage__c, 
                                        RecordId: result[i].Id, title: result[i].Title__c, ownerMobileCountryCode: result[i].MobileCountryCode__c,
                                        ownerMobile: result[i].MobileNumber__c, ownerEmail: result[i].EmailAddress__c, primaryOwner : result[i].PrimaryOwner__c
                                    });
                                    this.partnersOwnersCount = this.partnersOwnersCount + 1;
                                }
                            }
                        }
                    }
                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));
                });

            await getServiceRequestStep({ serviceRequestId: this.serviceRequestId })
                .then(result => {

                    this.serviceRequestStepObj = result;
                    if (result != null && (result.HexaBPM__Step_Status__c === this.stepStatus)) {
                        this.readOnly = false;
                        this.readOnlyFields = true;
                        this.verifiedBool = !this.verifiedBool;

                        if (result.HexaBPM__Step_Notes__c != '' && result.HexaBPM__Step_Notes__c != null) {
                            this.notes = result.HexaBPM__Step_Notes__c;
                            this.hasNotes = true;
                        }
                    } else {
                        this.readOnly = true;
                        this.agencyAdminReadOnly = true;
                        this.readOnlyFields = true;
                    }
                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));
                });


            await getUploadedFiles({ serviceRequestId: this.serviceRequestId })
                .then(result => {
                    for (let i = 0; i < result.length; i++) {

                        if (result[i].srDocumentName === 'Memorandum of Association/Power of Attorney') {
                            this.memorandumofAssociationPowerofAttorney.push({
                                'filename': result[i].fileName,
                                'base64': result[i].base64,
                                'old': 'true',
                            });
                        } else if (result[i].srDocumentName === 'Go AML Certificate') {
                            this.goAMLCertificate.push({
                                'filename': result[i].fileName,
                                'base64': result[i].base64,
                                'old': 'true',
                            });
                            //ADM/RERA start
                        } else if (result[i].srDocumentName === 'ADM / RERA Certificate') {
                            this.ADMRERACertificate.push({
                                'filename': result[i].fileName,
                                'base64': result[i].base64,
                                'old': 'true',
                            });
                            //ADM/RERA end
                        } else if (result[i].srDocumentName === 'Company Profile/Brochure/Catalogue') {
                            this.companyProfileBrochureCatalogue.push({
                                'filename': result[i].fileName,
                                'base64': result[i].base64,
                                'old': 'true',
                            });
                        } else if (result[i].srDocumentName === 'VAT Registration Certificate') {
                            this.vatRegistrationCertificate.push({
                                'filename': result[i].fileName,
                                'base64': result[i].base64,
                                'old': 'true',
                            });
                        } else if (result[i].srDocumentName === 'Bank Copy') {
                            this.signedBankCopy.push({
                                'filename': result[i].fileName,
                                'base64': result[i].base64,
                                'old': 'true',
                            });
                        } else if (result[i].srDocumentName === 'Emirates ID / Passport copy') {
                            if (result[i].fileName.startsWith('PO')) {

                                for (let index = 0; index < this.partnersOwners.length; index++) {

                                    if (result[i].fileName.startsWith('PO' + (index + 1))) {
                                        this.partnersOwners[index].filename = result[i].fileName;
                                    }
                                }

                                this.emiratesIDPassportcopyofPartnerOwner.push({
                                    'filename': result[i].fileName.substring(3),
                                    'base64': result[i].base64,
                                    'old': 'true',
                                });

                                if (result[i].fileName.startsWith('POF')) {
                                    this.firstPartnersOwnerFiles.push(result[i].fileName.substring(3));
                                }

                            } else {
                                this.emiratesIDPassportcopyofPOA.push({
                                    'filename': result[i].fileName,
                                    'base64': result[i].base64,
                                    'old': 'true',
                                });
                            }

                        } else if (result[i].srDocumentName === 'Trade/Commercial License') {
                            this.attachTradeLicence.push({
                                'filename': result[i].fileName,
                                'base64': result[i].base64,
                                'old': 'true',
                            });
                        }
                    }
                })
                .catch(error => {
                    this.errorDetails.push('getUploadedFiles Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));

                });
        } else if (this.userId && 'BrokerAgencyRegistration' == pageName) {
            this.userId = null;
            window.location.replace(window.location.href.replace('BrokerAgencyRegistration', "secur/logout.jsp"));
        }



        setTimeout(() => {
            this.isLoaded = !this.isLoaded;

            //this.hideCompletedandCurrentStages();
            // this.template.querySelectorAll(".current-stage.agency-information-img")[0].style.display = 'inline-block';
            this.openSection("");

        }, 2000);

        // Added by Tharun on 30 March
        this.getBrokerAssociates();

    }

    // Added by Tharun on 30 March
    async getBrokerAssociates()
    {
        await getUsersQuery({ 
            query: this.queryBrokerAssociates
        })
        .then(result => {
            result.forEach(currentItem => {
                if (currentItem.Team__c == 'AUH') {
                    this.brokerAUHTeamArray.push({
                        id : currentItem.Id,
                        fullName : (currentItem.FirstName != null ? (currentItem.FirstName + ' ') : '') + currentItem.LastName,
                        mobile : currentItem.MobilePhone,
                    })
                }else if (currentItem.Team__c == 'DXB') {
                    this.brokerDXBTeamArray.push({
                        id : currentItem.Id,
                        fullName : (currentItem.FirstName != null ? (currentItem.FirstName + ' ') : '') + currentItem.LastName,
                        mobile : currentItem.MobilePhone,
                    })
                }
            });
        })
        .catch(error => {
            console.log(JSON.stringify(error));
            // TODO Error handling
        });
    }

    getCountryCodeValues() {

        getCountryCodeValues().then((response) => {
            this.phoneNumberCountryCode = response;
        }).catch(error => {
            console.log(JSON.stringify(error));

        });

    }


    addPartnerOwner(event) {
        // Updated By Moh Sarfaraj for BPE-110
        this.partnersOwners.push({ Id: this.partnersOwnersCount, ownerName: '', ownerCountry: '', partnerOwnerDetails: '', shareHoldingPercentage: '', RecordId: '', title: '', filename: '',ownerMobileCountryCode: '',ownerMobile: '',ownerEmail: '', primaryOwner : false });

        this.partnersOwnersCount = this.partnersOwnersCount + 1;

        if (this.partnersOwners.length === 0) {
            this.multiPartnerOwner = false;
        } else {
            this.multiPartnerOwner = true;
        }
    }

    // Added By Moh Sarfaraj for BPE-110 starts
    handlePrimaryOwner(event){
        let isPrimaryOwner = event.target.checked;   
        let name = event.target.dataset.item;
        let id = event.target.dataset.id;
    
        if(name === 'PrimaryOwner'){
            this.primaryOwner = isPrimaryOwner;
            if(isPrimaryOwner){
                for(let i=0;i<this.partnersOwners.length;i++){
                    this.partnersOwners[i]["primaryOwner"] = false;
                }
            }
        }else if(name === 'PrimaryOwnerMulti' && isPrimaryOwner){
            this.primaryOwner = isPrimaryOwner ? false : true;
            for(let i=0;i<this.partnersOwners.length;i++){
                if(id == this.partnersOwners[i].Id){
                    this.partnersOwners[i]["primaryOwner"] = true;
                }else{
                    this.partnersOwners[i]["primaryOwner"] = false;
                }
            }
            this.partnersOwners = [...this.partnersOwners];
        }
    }
    // Added By Moh Sarfaraj for BPE-110 end

    removePartnerOwner(event) {
        let value = parseInt(event.target.dataset.item);

        this.partnersOwners.splice(this.partnersOwners.findIndex(a => a.Id === value), 1);
        this.partnersOwnersCount = this.partnersOwnersCount - 1;
    }

    removeByAttr(arr, attr, value) {
        var i = arr.length;
        while (i--) {
            if (arr[i] && arr[i].hasOwnProperty(attr) && (arr[i][attr] === value)) {
                if (parseInt(arr[i].shareHoldingPercentage) != NaN) {
                    arr.splice(i, 1);
                }
            }
        }
        return arr;
    }


    get acceptedFormats() {
        var acceptFormatList = [];
        for (let i = 0; i < this.acceptFileTypeList.length; i++) {
            acceptFormatList[i] = '.' + this.acceptFileTypeList[i];
        }

        return acceptFormatList;
    }

    /*@wire(getAllConstants,)
    srStatus({ error, data }) {
        if (data) {


            this.srStatus = data.SUBMITTED;
            this.agencyAdminType = data.AGENCY_ADMIN_AURA;
            this.stepStatus = data.REQUIRE_ADDITIONAL_INFORMATION;
        } else {
        }
    }*/

    @wire(getObjectInfo, { objectApiName: Service_Request_OBJECT })
    serviceRequestMetadata;

    @wire(getObjectInfo, { objectApiName: Agency_Team_OBJECT })
    agencyTeamMetadata;

    @wire(getPicklistValues,
        {
            recordTypeId: '$serviceRequestMetadata.data.defaultRecordTypeId',
            fieldApiName: Country_FIELD
        }
    )
    CountryPicklist;

    @wire(getPicklistValues,
        {
            recordTypeId: '$agencyTeamMetadata.data.defaultRecordTypeId',
            fieldApiName: Agent_Title_FIELD
        }
    )
    titlePicklist;

    handleCaptcha(event) {

        this.verifiedBool = event.detail.value;

        if (event.detail.response) {
            this.captchaResponse = event.detail.response;

        }
    }

    partnerOwnerChange(event) {
        var id = parseInt(event.target.dataset.id);
        var item = event.target.dataset.item;
        var value = event.target.value;
        let index = this.partnersOwners.findIndex(a => a.Id === id);
        if (item === 'OwnerName') {
            this.partnersOwners[index].ownerName = value;
        } else if (item === 'OwnerCountry') {
            this.partnersOwners[index].ownerCountry = value;
        } else if (item === 'PartnerOwnerDetails') {
            this.partnersOwners[index].partnerOwnerDetails = value;
        } else if (item === 'ShareHoldingPercentage') {
            this.partnersOwners[index].shareHoldingPercentage = value;
        } else if (item === 'OwnerTitle') {
            this.partnersOwners[index].title = value;
        }
        // Tharun Added as per BPE-109
        // TODO: Tharun to add mobile number validation here...
        else if (item === 'OwnerCountryCode') {
            this.partnersOwners[index].ownerMobileCountryCode = value;
        }else if (item === 'OwnerMobileNumber') {
            this.partnersOwners[index].ownerMobile = value;
        }else if (item === 'OwnerEmailAddress') {
            //Added below by Tharun to iterate all owner email address and show error
            this.partnersOwners[index].ownerEmail = value;
            const ownerEmailFields = this.template.querySelectorAll('[data-item="OwnerEmailAddress"]'); 
            
            for (let i = 0; i < ownerEmailFields.length; i++) {
                let emailField = ownerEmailFields.item(i);
                let emailValue = emailField.value;
                emailField.setCustomValidity("");
                
                getValidateEmail({ email: emailValue })
                .then(data => {
                    if (!data) {
                        emailField.setCustomValidity("Enter Valid Owner Email.")
                    } else {
                        emailField.setCustomValidity("");
                    }
                    //emailField.reportValidity();
                }).catch(error => {
                    console.log(JSON.stringify(error));
                    // TODO Error handling
                });

                if(this.country && this.country === 'United Arab Emirates'){
                    let domains = blacklistedDomains.split(',');
                    if(domains.includes('@'+(emailValue.split('@')[1]).toLowerCase())){
                        emailField.setCustomValidity("Please Enter Owner Professional Email Address");
                    }else{
                        emailField.setCustomValidity("");
                    }
                    //emailField.reportValidity();
                }
                emailField.reportValidity();
            }
        }
        // Tharun Added as per BPE-109
        //Added below by Tharun to iterate all owner email address and show error
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

        if (event.target.dataset.id === 'AgencyName') {
            this.agencyName = value;
        } else if (event.target.dataset.id === 'InterestedPropoertyLocations') {
            this.selectedIntPropLocation = value;
        } else if (event.target.dataset.id === 'EstablishmentDate') {
            this.establishmentDate = value;
            this.validateDate('EstablishmentDate', this.establishmentDate);
        } else if (event.target.dataset.id === 'LicenseNumber') {
            this.licenseNumber = value;
        } else if (event.target.dataset.id === 'ExpiryDate') {
            this.expiryDate = value;
            this.validateDate('ExpiryDate', this.expiryDate);
        } else if (event.target.dataset.id === 'phoneNumberCountryCode') {
            this.phoneNumberCountryCodeChosed = value;

            this.phoneNumberToCheck = this.phoneNumberCountryCodeChosed + this.phoneNumber;

            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="PhoneNumber"]');

                if (!this.phoneNumberResponse.data) {
                    target.setCustomValidity("Enter Valid Mobile Number.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);

        } else if (event.target.dataset.id === 'PhoneNumber') {
            this.phoneNumberToCheck = this.phoneNumberCountryCodeChosed + this.phoneNumber;
            let target = this.template.querySelector('[data-id="PhoneNumber"]');
            if (/^[0-9]*$/.test(value)){
                this.phoneNumber = value;
                target.setCustomValidity("");
            }else{
                target.setCustomValidity("Enter Numbers only.");
            }
            target.reportValidity();
        } else if (event.target.dataset.id === 'CompanyEmail') {
            this.companyEmail = value;
        } else if (event.target.dataset.id === 'AddressLine1') {
            this.addressLine1 = value;
        } else if (event.target.dataset.id === 'AddressLine2') {
            this.addressLine2 = value;
        } else if (event.target.dataset.id === 'Country') {
            // Added By Moh Sarfaraj for BPE-120 starts
            this.country = value;
            let companyEmail = this.template.querySelector('[data-id="CompanyEmail"]');
            let contactEmail = this.template.querySelector('[data-id="ContactPersonEmailID"]');
            let emailField = this.template.querySelector('[data-id="AuthorizedSignatoryEmail"]');
            // Added By Moh Sarfaraj for BPE-110
            let ownerEmail = this.template.querySelector('[data-id="ownerEmailAddress"]');
            this.handleEmailBlurMulti();

            if(value === 'United Arab Emirates'){
                this.makeRequiredForUAE = true;
                let domains = blacklistedDomains.split(',');

                if(!companyEmail.value || companyEmail.value == '' || companyEmail.value === ''  || companyEmail.value === null || companyEmail.value ===  undefined){
                    companyEmail.setCustomValidity("Please Enter Email Address");
                }else if(domains.includes('@'+(companyEmail.value.split('@')[1]).toLowerCase())){
                    companyEmail.setCustomValidity("Please Enter Professional Email Address");
                }else{
                    companyEmail.setCustomValidity("");
                }

                if(!contactEmail.value || contactEmail.value == '' || contactEmail.value === ''  || contactEmail.value === null || contactEmail.value ===  undefined){
                    contactEmail.setCustomValidity("Please Enter Email Address");
                }else if(domains.includes('@'+(contactEmail.value.split('@')[1]).toLowerCase())){
                    contactEmail.setCustomValidity("Please Enter Professional Email Address");
                }else{
                    contactEmail.setCustomValidity("");
                }

                if(!emailField.value || emailField.value == '' || emailField.value === ''  || emailField.value === null || emailField.value ===  undefined){
                    emailField.setCustomValidity("Please Enter Email Address");
                }else if(domains.includes('@'+(emailField.value.split('@')[1]).toLowerCase())){
                    emailField.setCustomValidity("Please Enter Professional Email Address");
                }else{
                    emailField.setCustomValidity("");
                }
                // Added By Moh Sarfaraj for BPE-110
                if(!ownerEmail.value || ownerEmail.value == '' || ownerEmail.value === ''  || ownerEmail.value === null || ownerEmail.value ===  undefined){
                    ownerEmail.setCustomValidity("Please Enter Email Address");
                }else if(domains.includes('@'+(ownerEmail.value.split('@')[1]).toLowerCase())){
                    ownerEmail.setCustomValidity("Please Enter Professional Email Address");
                }else{
                    ownerEmail.setCustomValidity("");
                }
            }else {
                this.makeRequiredForUAE = false;
                companyEmail.setCustomValidity("");
                contactEmail.setCustomValidity("");
                emailField.setCustomValidity("");
                ownerEmail.setCustomValidity("");
            }
            companyEmail.reportValidity();
            contactEmail.reportValidity();
            emailField.reportValidity();
            ownerEmail.reportValidity();
            
            this.country = value;
            this.validStates = [];

            let countryIndex = COUNTRIES.indexOf(this.country);
            let validStates1 = STATES[countryIndex + 1].split('|');
            validStates1.forEach(element => {
                this.validStates.push({ label: element, value: element });
            });
            this.state = '';
            this.checkIsRequiredForInternational();

        } else if (event.target.dataset.id === 'State') {
            this.state = value;
            this.checkIsRequiredForInternational();
        } else if (event.target.dataset.id === 'City') {
            this.city = value;
        } else if (event.target.dataset.id === 'POBox') {
            this.poBox = value;
        } else if (event.target.dataset.id === 'TaxRegistrationCertificate') {
            this.taxRegistrationCertificate = value;
            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="TaxRegistrationCertificate"]');
                const regex = /^[0-9]{15}$/;
          
                if (!regex.test(this.taxRegistrationCertificate)) {
                    target.setCustomValidity("Enter a valid Tax Registration Number (15 numeric characters).");
                } else {
                    target.setCustomValidity("");
                }
          
                target.reportValidity();
            }, DELAY);
         } else if (event.target.dataset.id === 'Website') {
            this.website = value;
        } else if (event.target.dataset.id === 'NameOfPOA') {
            this.nameOfPOA = value;
        } else if (event.target.dataset.id === 'AttorneyTitle') {
            this.attorneyTitle = value;
        } else if (event.target.dataset.id === 'OwnerTitle') {
            this.ownerTitle = value;
        } else if (event.target.dataset.id === 'OwnerName') {
            this.ownerName = value;
        } else if (event.target.dataset.id === 'OwnerCountry') {
            this.ownerCountry = value;
        } else if (event.target.dataset.id === 'PartnerOwnerDetails') {
            this.partnerOwnerDetails = value;
        } else if (event.target.dataset.id === 'ShareHoldingPercentage') {
            this.shareHoldingPercentage = value;
        } else if (event.target.dataset.id === 'ownerMobCountryCode') {
            this.ownerMobCountryCode = value;
        } else if (event.target.dataset.id === 'ownerMobileNumber') {
            this.ownerMobileNumber = value;
        } else if (event.target.dataset.id === 'ownerEmailAddress') {
            this.ownerEmail = value;
        } else if (event.target.dataset.id === 'BankName') {
            this.bankName = value;
        } else if (event.target.dataset.id === 'IBANNumber') {
            this.IBANNumber = value;
            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="IBANNumber"]');
                if (!this.ibanNumberResponse.data) {
                    target.setCustomValidity("Enter Valid IBAN Number.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
        } else if (event.target.dataset.id === 'SwiftCode') {
            this.swiftCode = value;
            var myReg = '^[a-zA-Z]{6}[a-zA-Z0-9]{2}([a-zA-Z0-9]{3})?$';
            var result = this.swiftCode != null ? this.swiftCode.match(myReg) : '';
            if(this.swiftCode == null){
                let target = this.template.querySelector('[data-id="SwiftCode"]');	
                target.setCustomValidity('');	
                target.reportValidity();	
                } else {
                    this.delayTimeout = setTimeout(async () => {
                        let target = await this.template.querySelector('[data-id="SwiftCode"]');
                        if (result == null && this.swiftCode != null && this.swiftCode != '') {
                            target.scrollIntoView();
                            target.setCustomValidity('Enter Valid Swift Code.');
                        } else {
                            target.setCustomValidity('');
                        }
                        target.reportValidity();
                    }, DELAY);
                }
        } else if (event.target.dataset.id === 'BranchAddress') {
            this.branchAddress = value;
        } else if (event.target.dataset.id === 'BankAccNumber') {
            this.bankAccountNumber = value;
            if(this.IBANNumber){
                let target = this.template.querySelector('[data-id="BankAccNumber"]');
                if(this.IBANNumber.includes(this.IBANNumber)){
                    target.setCustomValidity("");
                }else{
                    target.scrollIntoView();
                    target.setCustomValidity("Enter Valid Account Number");
                }
                target.reportValidity();
            }
        } else if (event.target.dataset.id === 'bankCountry') {
            this.bankCountry = value;
        } else if (event.target.dataset.id === 'AgencyTitle') {
            this.agencyTitle = value;
        } else if (event.target.dataset.id === 'ContactPersonName') {
            this.contactPersonName = value;
        } else if (event.target.dataset.id === 'ContactMiddleName') {
            this.contactMiddleName = value;
        } else if (event.target.dataset.id === 'ContactLastName') {
            this.contactLastName = value;
        } else if (event.target.dataset.id === 'ContactPersonCountryCode') {
            this.contactPersonCountryCode = value;
            this.mobileNumberToCheck = this.contactPersonCountryCode + this.contactPersonMobileNumber;

            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="ContactPersonMobileNumber"]');

                if (!this.mobileResponse.data) {
                    target.setCustomValidity("Enter Valid Mobile Number.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
        } else if (event.target.dataset.id === 'ContactPersonMobileNumber') {
            this.contactPersonMobileNumber = value;
            this.mobileNumberToCheck = this.contactPersonCountryCode + this.contactPersonMobileNumber;
            
            let target = this.template.querySelector('[data-id="ContactPersonMobileNumber"]');
            if (/^[0-9]*$/.test(value)) 
            {
                this.contactPersonMobileNumber = value;
                target.setCustomValidity("");
            }else{
                target.setCustomValidity("Enter Numbers only.");
            }
            target.reportValidity();

        } else if (event.target.dataset.id === 'ContactPersonEmailID') {
            this.contactPersonEmailID = value;
        } else if (event.target.dataset.id === 'DateofBirth') {
            this.dateofBirth = value;
            this.validateDate('DateofBirth', this.dateofBirth);

            let age = this.getAge(value);
            let target = this.template.querySelector('[data-id="DateofBirth"]');

            if (age < 18) {
                target.setCustomValidity("Age should be at least 18 years");
            } else {
                target.setCustomValidity("");
            }
            target.reportValidity();

        } else if (event.target.dataset.id === 'OTP') {
            this.userOTP = value;
        } else if (event.target.dataset.id === 'ReferredByTitle') {
            this.referredByTitle = value;
        } else if (event.target.dataset.id === 'ReferredBy') {
            this.referredBy = value;
        }
        else if (event.target.dataset.id === 'AuthorizedSignatoryTitle') {
            this.authorizedSignatoryTitle = value;
        } else if (event.target.dataset.id === 'AuthorizedSignatoryName') {
            this.authorizedSignatoryName = value;
        } else if (event.target.dataset.id === 'Designation') {
            this.designation = value;
        } else if (event.target.dataset.id === 'AuthorizedSignatoryEmail') {
            this.authorizedSignatoryEmail = value;
        } 
        else if(event.target.dataset.id === 'fiabciRegistred'){
            this.requiredFiabciStatus = false;
            this.disabledFiabciStatus = false;
            this.fiabciRegistredValue =  value;

            if(value === 'Yes'){
                this.requiredFiabciStatus = true;
            }else if(value === 'No'){
                this.fiabciStatusValue = '';
                this.disabledFiabciStatus = true;
            }
        }else if(event.target.dataset.id === 'fiabciStatus'){
            this.fiabciStatusValue =  value;
        }else if(event.target.dataset.id === 'agencyCategory'){
            this.agencyCategoryValue = value;
        }else if(event.target.dataset.id === 'vatRegistration'){
            this.vatValue = value;
        }/*else if(event.target.dataset.id === 'UAEVATRegistrationNumber'){
            this.UAEVATRegistrationNumber = value;
        } */
        else if(event.target.dataset.id === 'vatStartDate'){
            this.vatStartDateValue = value;
        }else if(event.target.dataset.id === 'vatEndDate'){
            this.vatEndDateValue = value;
        }

        if(this.vatValue == 'VAT Registration Certificate'){
            this.showVatCertificate = true;
            this.showVatUndertakingCertificate = false;
        }else if(this.vatValue == 'VAT Undertaking Certificate'){
            this.showVatCertificate = false;
            this.showVatUndertakingCertificate = true;
        }
        
        this.checkCompletedSections();

    }

    // Added by Tharunn
    async handlePhoneNumberBlur(event)
    {
        if (event.target.dataset.id === 'PhoneNumber')
        {
            let enteredMobNumber    = event.target.value;
            if(enteredMobNumber != ''){
                let mob                 = enteredMobNumber.replace(/[^0-9]/g,'');
                let mobNumber           = parseInt(mob);
                this.phoneNumber        = mobNumber.toString();
            }

            this.phoneNumberToCheck = this.phoneNumberCountryCodeChosed + this.phoneNumber;
            let target = await this.template.querySelector('[data-id="PhoneNumber"]');
            await getValidatePhoneNoWithAura({
                phoneNo : this.phoneNumberToCheck
            }).then(result => {
                if (!result) {
                    target.setCustomValidity("Enter Valid Mobile Number.");
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }).catch(error =>{
                console.log(error);
            });
        }
        else if (event.target.dataset.id === 'ContactPersonMobileNumber')
        {
            let enteredMobNumber    = event.target.value;
            if(enteredMobNumber != ''){
                let mob                                 = enteredMobNumber.replace(/[^0-9]/g,'');
                let mobNumber                           = parseInt(mob);
                this.contactPersonMobileNumber          = mobNumber.toString();
            }

            this.mobileNumberToCheck = this.contactPersonCountryCode + this.contactPersonMobileNumber;
            let target = await this.template.querySelector('[data-id="ContactPersonMobileNumber"]');
            await getValidatePhoneNoWithAura({
                phoneNo : this.mobileNumberToCheck
            }).then(result => {
                if (!result) {
                    target.setCustomValidity("Enter Valid Mobile Number.");
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }).catch(error =>{
                console.log(error);
            });
        }
        // Added by Tharun
        else if (event.target.dataset.id === 'ownerMobileNumber')
        {
            let enteredMobNumber    = event.target.value;
            let ownerMN;
            if(enteredMobNumber != ''){
                let mob                                 = enteredMobNumber.replace(/[^0-9]/g,'');
                let mobNumber                           = parseInt(mob);
                ownerMN                                 = mobNumber.toString();
            }
            this.ownerMobileNumber = ownerMN;
            let ownerMobNumCC = this.template.querySelector('[data-id="ownerMobCountryCode"]').value;
            this.mobileNumberToCheck = ownerMobNumCC + ownerMN;
            let target = await this.template.querySelector('[data-id="ownerMobileNumber"]');
            await getValidatePhoneNoWithAura({
                phoneNo : this.mobileNumberToCheck
            }).then(result => {
                if (!result) {
                    target.setCustomValidity("Enter Valid Mobile Number.");
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }).catch(error =>{
                console.log(error);
            });
        }

        else if (event.target.dataset.item === 'OwnerMobileNumber')
        {
            var id = parseInt(event.target.dataset.id);
            let index = this.partnersOwners.findIndex(a => a.Id === id);
            let enteredMobNumber    = event.target.value;
            let ownerMN;
           
            if(enteredMobNumber != ''){
                let mob                                 = enteredMobNumber.replace(/[^0-9]/g,'');
                let mobNumber                           = parseInt(mob);
                ownerMN                                 = mobNumber.toString();
                this.partnersOwners[index].ownerMobile = mobNumber.toString();
            }
            let ownerMobNumCC = this.template.querySelector('[data-item="OwnerCountryCode"]').value;
            this.mobileNumberToCheck = ownerMobNumCC + ownerMN;
            let target = await this.template.querySelector('[data-item="OwnerMobileNumber"]');
            
            await getValidatePhoneNoWithAura({
                phoneNo : this.mobileNumberToCheck
            }).then(result => {
                if (!result) {
                    target.setCustomValidity("Enter Valid Mobile Number.");
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }).catch(error =>{
                console.log(error);
            });
        }
        // Added by Tharun
    }

    // Added By Moh Sarfaraj for BPE-120
    // Below dataset.item is added to handle multiple owners
    handleEmailBlur(event){
        let emailValue  = event.target.value;
        let emailField;
        if(event.target.dataset.id === 'CompanyEmail'){
            emailField = this.template.querySelector('[data-id="CompanyEmail"]');  
        }else if(event.target.dataset.id === 'ContactPersonEmailID'){
            emailField = this.template.querySelector('[data-id="ContactPersonEmailID"]');  
        }else if(event.target.dataset.id === 'AuthorizedSignatoryEmail'){
            emailField = this.template.querySelector('[data-id="AuthorizedSignatoryEmail"]');
        }else if(event.target.dataset.id === 'ownerEmailAddress'){
            emailField = this.template.querySelector('[data-id="ownerEmailAddress"]');
        }

        emailField.setCustomValidity("");
        getValidateEmail({ email: emailValue })
        .then(data => {
            if (!data) {
                emailField.setCustomValidity("Enter Valid Owner Email.")
            } else {
                emailField.setCustomValidity("");
            }
        }).catch(error => {
            console.log(JSON.stringify(error));
            // TODO Error handling
        });

        if(this.country && this.country === 'United Arab Emirates'){
            emailField.setCustomValidity("");
            let domains = blacklistedDomains.split(',');
            if(domains.includes('@'+(emailValue.split('@')[1]).toLowerCase())){
                emailField.setCustomValidity("Please Enter Professional Email Address");
            }else{
                emailField.setCustomValidity("");
            }
        }
        emailField.reportValidity();
    }

    handleEmailBlurMulti(event){
        const ownerEmailFields = this.template.querySelectorAll('[data-item="OwnerEmailAddress"]'); 
        for (let i = 0; i < ownerEmailFields.length; i++) {
            let emailField = ownerEmailFields.item(i);
            let emailValue = emailField.value;
            emailField.setCustomValidity("");
            
            getValidateEmail({ email: emailValue })
            .then(data => {
                if (!data) {
                    emailField.setCustomValidity("Enter Valid Owner Email.")
                } else {
                    emailField.setCustomValidity("");
                }
            }).catch(error => {
                console.log(JSON.stringify(error));
            });

            if(this.country && this.country === 'United Arab Emirates'){
                let domains = blacklistedDomains.split(',');
                if(domains.includes('@'+(emailValue.split('@')[1]).toLowerCase())){
                    emailField.setCustomValidity("Please Enter Owner Professional Email Address");
                }else{
                    emailField.setCustomValidity("");
                }
            }
            emailField.reportValidity();
        }
    }

    checkIsRequiredForInternational() {
        //ADM/RERA Start
        this.isADM_RERARequired = false; //ADM/RERA File is optional
        if (this.country == 'United Arab Emirates'){
            if(this.state == 'Abu Dhabi' || this.state == 'Dubai') {
                this.isADM_RERARequired = true; //ADM/RERA File is required
            }
            this.requiredForInternational = true;
        } else {
            this.requiredForInternational = false;
        }
        //ADM/RERA End
    }
    async checkCompletedSections() {

        let flag = 0;
        this.isAgencyAdminInformationCompleted = false;
        const AgencyInformationSection = await [...this.template.querySelectorAll('.AgencyInformationSection')];
        AgencyInformationSection.forEach(element => {
            if (element.value == null || element.value == '') {
                flag++;
            }
        });

        if (flag == 0) {
            this.isAgencyAdminInformationCompleted = true;
        }
        ////////////////////////////////////////////////
        flag = 0;
        this.isPowerOfAttorneyCompleted = false;
        const PowerOfAttorneySection = await [...this.template.querySelectorAll('.PowerOfAttorneySection')];
        PowerOfAttorneySection.forEach(element => {
            if (element.value == null || element.value == '') {
                flag++;
            }
        });

        if (flag == 0) {
            this.isPowerOfAttorneyCompleted = true;
        }
        ///////////////////////////////////////////////////
        flag = 0;
        this.isPartnerOwnerDetailsCompleted = false;
        const PartnerOwnerDetailsSection = await [...this.template.querySelectorAll('.PartnerOwnerDetailsSection')];
        PartnerOwnerDetailsSection.forEach(element => {
            if (element.value == null || element.value == '') {
                flag++;
            }
        });

        if (flag == 0) {
            this.isPartnerOwnerDetailsCompleted = true;
        }

        ///////////////////////////////////////////////////
        flag = 0;
        this.isBankDetailsCompleted = false;
        const BankDetailsSection = await [...this.template.querySelectorAll('.BankDetailsSection')];
        BankDetailsSection.forEach(element => {
            if (element.value == null || element.value == '') {
                flag++;
            }
        });

        if (flag == 0) {
            this.isBankDetailsCompleted = true;
        }

        ///////////////////////////////////////////////////
        flag = 0;
        this.isAgencyAdminInformationCompleted = false;
        const AgencyAdminInformationSection = await [...this.template.querySelectorAll('.AgencyAdminInformationSection')];
        AgencyAdminInformationSection.forEach(element => {
            if (element.value == null || element.value == '') {
                flag++;
            }
        });

        if (flag == 0) {
            this.isAgencyAdminInformationCompleted = true;
        }

        ///////////////////////////////////////////////////
        flag = 0;
        this.isAuthorizedSignatoryCompleted = false
        const AuthorizedSignatorySection = await [...this.template.querySelectorAll('.AuthorizedSignatorySection')];
        AuthorizedSignatorySection.forEach(element => {
            if (element.value == null || element.value == '') {
                flag++;
            }
        });

        if (flag == 0) {
            this.isAuthorizedSignatoryCompleted = true;
        }
    }

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

    async handleSubmit() {

        this.isLoaded = true;
        this.errorDetails = [];
        const isShareHoldingPercentageCorrect = await [...this.template.querySelectorAll('[data-id="ShareHoldingPercentage"]')]
            .reduce((validSoFar, inputField) => {

                this.sumOfShareHoldingPercentage = parseInt(this.shareHoldingPercentage);

                for (let index = 0; index < this.partnersOwners.length; index++) {
                    if (parseInt(this.partnersOwners[index].shareHoldingPercentage) != NaN) {
                        this.sumOfShareHoldingPercentage = this.sumOfShareHoldingPercentage + parseInt(this.partnersOwners[index].shareHoldingPercentage);
                    }
                }

                if (this.sumOfShareHoldingPercentage > 100) {
                    inputField.setCustomValidity('Share Holding Percentage Cannot be More Than 100 For All Partner/Owner.');
                    this.errorDetails.push('Share Holding Percentage Cannot be More Than 100 For All Partner/Owner.');

                } else if (this.sumOfShareHoldingPercentage < 100) {
                    inputField.setCustomValidity('Share Holding Percentage Must Equal 100 For All Partner/Owner.');
                    this.errorDetails.push('Share Holding Percentage Must Equal 100 For All Partner/Owner.');

                } else {
                    inputField.setCustomValidity('');
                }
                inputField.reportValidity();

                return validSoFar && inputField.checkValidity();
            }, true);

        const isInputsCorrect = await [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {

                    inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

            var LicenseNumber = this.template.querySelector('[data-id="LicenseNumber"]')
            if(LicenseNumber && LicenseNumber.value.length > 0)
            {
                validateTradeLicenseNumber({LicenseNumber:LicenseNumber.value})
                .then(result =>{
                    this.hasActiveSRWithLicenseNumber = result;
                    if(this.hasActiveSRWithLicenseNumber && !this.updateAction)
                    {
                        LicenseNumber.setCustomValidity('There is Already Agency Admin with This Trade License number.');
                        this.errorDetails.push('There is Already Agency Admin with This Trade License number.');  
                    }else
                    {
                        this.hasActiveSRWithLicenseNumber = false;
                        LicenseNumber.setCustomValidity('');
                    }
                LicenseNumber.reportValidity();
                })
                .catch(error => {
                    console.log(JSON.stringify(error));
                })
            }

            // Added By Moh Sarfaraj for BPE-110 starts
            let hasPrimaryOwner = false;
            if(this.primaryOwner){
                hasPrimaryOwner = true;
            }else if(this.partnersOwners.length > 0){
                for(let i=0;i<this.partnersOwners.length;i++){
                    if(this.partnersOwners[i].primaryOwner == true){
                        hasPrimaryOwner = true;
                    }
                }
            }
            if(!hasPrimaryOwner){
                this.errorDetails.push('Please select at least one Owner as Primary.');
            }
            // Added By Moh Sarfaraj for BPE-110 end
            

           var isSwiftCorrect;

        //BPM-473 - Partner Owner Email/Mobile duplicate check   
        if(PartnerOwnersDuplicateEnable === "TRUE" || PartnerOwnersDuplicateEnable === "true"){
            VALIDATIONS.validateOwnersEmailAndMobile(this);
        }           

        if (!isInputsCorrect) {
            this.errorDetails.push('Kindly Complete the Mandatory Fields.');
        } else {
            isSwiftCorrect = await [...this.template.querySelectorAll('[data-id="SwiftCode"]')]
                .reduce((validSoFar, inputField) => {

                    var myReg = '^[a-zA-Z]{6}[a-zA-Z0-9]{2}([a-zA-Z0-9]{3})?$';
                    var result = this.swiftCode != null ? this.swiftCode.match(myReg) : '';

                    if (result == null && this.swiftCode != null && this.swiftCode != '') {
                        let target = this.template.querySelector('[data-id="SwiftCode"]');
                        target.scrollIntoView();
                        inputField.setCustomValidity('Enter Valid Swift Code.');
                        this.errorDetails.push('Enter Valid Swift Code.');
                    } else {
                        inputField.setCustomValidity('');
                    }
                    inputField.reportValidity();

                    return validSoFar && inputField.checkValidity() && result !== null;
                }, true);

            if(this.swiftCode == null || this.swiftCode == undefined  || this.swiftCode == '') 
            {	
                isSwiftCorrect = true;
            }

            await getValidateEmail({ email: this.companyEmail })
                .then(result => {
                    this.emailResponse = result;

                    if (!this.emailResponse) {
                        let target = this.template.querySelector('[data-id="CompanyEmail"]');
                        target.scrollIntoView();
                    }

                    const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="CompanyEmail"]')]
                        .reduce((validSoFar, inputField) => {

                            if (!this.emailResponse) {
                                this.errorDetails.push('Enter Valid Company Email.');
                                inputField.setCustomValidity('Enter Valid Email.');
                            } else {
                                inputField.setCustomValidity('');
                            }
                            inputField.reportValidity();

                            return validSoFar && inputField.checkValidity() && this.emailResponse;
                        }, true);

                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));

                });

            await getAgencyTeamByEmail({ email: this.contactPersonEmailID })
                .then(result => {
                    this.existingAgencyAdmin = result;
                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));

                });

            await getValidateEmail({ email: this.contactPersonEmailID })
                .then(result => {
                    this.contactEmailIdResponse = result;


                    if (!this.contactEmailIdResponse) {
                        let target = this.template.querySelector('[data-id="ContactPersonEmailID"]');
                        target.scrollIntoView();
                    }

                    const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="ContactPersonEmailID"]')]
                        .reduce((validSoFar, inputField) => {

                            if (!this.contactEmailIdResponse) {
                                inputField.setCustomValidity('Enter Valid Email.');
                                this.errorDetails.push('Enter Valid Contact Person Email.');

                            } else if (this.existingAgencyAdmin != null && !this.updateAction) {
                                inputField.setCustomValidity('There is Already Agency Admin with This Email');
                                this.errorDetails.push('There is Already Agency Admin with This Email.');

                            } else {
                                inputField.setCustomValidity('');
                            }
                            inputField.reportValidity();

                            return validSoFar && inputField.checkValidity() && this.contactEmailIdResponse;
                        }, true);

                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));

                });

            await getValidateEmail({ email: this.authorizedSignatoryEmail })
                .then(result => {
                    this.authorizedSignatoryEmailResponse = result;


                    if (!this.authorizedSignatoryEmailResponse) {
                        let target = this.template.querySelector('[data-id="AuthorizedSignatoryEmail"]');
                        target.scrollIntoView();
                    }

                    const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="AuthorizedSignatoryEmail"]')]
                        .reduce((validSoFar, inputField) => {

                            if (!this.authorizedSignatoryEmailResponse) {
                                inputField.setCustomValidity('Enter Valid Email.');
                                this.errorDetails.push('Enter Valid Authorized Signatory Email.');
                            } else {
                                inputField.setCustomValidity('');
                            }
                            inputField.reportValidity();

                            return validSoFar && inputField.checkValidity() && this.authorizedSignatoryEmailResponse;
                        }, true);

                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));

                });

            await getValidatePhoneNoWithAura({ phoneNo: this.contactPersonCountryCode + this.contactPersonMobileNumber })
                .then(result => {
                    this.contactMobileNumberResponse = result;


                    if (!this.contactMobileNumberResponse) {
                        let target = this.template.querySelector('[data-id="ContactPersonMobileNumber"]');
                        target.scrollIntoView();
                    }

                    const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="ContactPersonMobileNumber"]')]
                        .reduce((validSoFar, inputField) => {

                            if (!this.contactMobileNumberResponse) {
                                inputField.setCustomValidity('Enter Valid Mobile Number.');
                                this.errorDetails.push('Enter Valid Mobile Number.');

                            } else {
                                inputField.setCustomValidity('');
                            }
                            inputField.reportValidity();
                            return validSoFar && inputField.checkValidity() && this.contactMobileNumberResponse;
                        }, true);

                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));

                });

            if (this.IBANNumber) {
                await getValidateIBAN({ ibanNumber: this.IBANNumber })
                    .then(result => {
                        this.ibanNumberResponse = result;

                        if (!this.ibanNumberResponse) {
                            let target = this.template.querySelector('[data-id="IBANNumber"]');
                            target.scrollIntoView();
                        }

                        const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="IBANNumber"]')]
                            .reduce((validSoFar, inputField) => {

                                if (!this.ibanNumberResponse) {
                                    inputField.setCustomValidity('Enter Valid IBAN Number.');
                                    this.errorDetails.push('Enter Valid IBAN Number.');

                                } else {
                                    inputField.setCustomValidity('');
                                }
                                inputField.reportValidity();
                                return validSoFar && inputField.checkValidity() && this.ibanNumberResponse;
                            }, true);

                    })
                    .catch(error => {
                        this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                        console.log(JSON.stringify(error));

                    });
            }
        }

        // Added By Moh Sarfaraj for BPE-197 starts
        if(!this.isAcceptedTAndC){
            this.errorDetails.push('Please accept terms and conditions.');
        }
        // Added By Moh Sarfaraj for BPE-197 end

        if(!this.isLegalChecked){
            this.errorDetails.push('Legal consent is required.');
        }

        if (this.verifiedBool) {
            this.errorDialog = true;
            this.errorDetails.push('Kindly Check the Captcha.');
        }

        if (isInputsCorrect && this.emailResponse && this.contactEmailIdResponse && this.contactMobileNumberResponse && isSwiftCorrect && !this.verifiedBool && isShareHoldingPercentageCorrect) {

            await getAgenciesByLicenseNumberAndEmail({
                licenseNumber: this.licenseNumber, email: this.companyEmail
            })
                .then(result => {
                    this.existingAgencys = result;

                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));

                });

            await getServicesRequestsByLicenseNumberAndEmail({
                licenseNumber: this.licenseNumber, email: this.companyEmail
            })
                .then(result => {
                    this.existingServicesRequests = result;

                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    console.log(JSON.stringify(error));

                });

            if (this.existingAgencys == null && this.existingServicesRequests == null && this.errorDetails.length == 0) {

                await getServiceRequestByEmailAndLicenseNumber({
                    email: this.companyEmail, licenseNumber: this.licenseNumber
                })
                    .then(result => {
                        this.existingAgencys = result;

                    })
                    .catch(error => {
                        this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                        console.log(JSON.stringify(error));

                    });
            }

            if ((this.existingAgencys.length === 0 || this.updateAction) && this.errorDetails.length == 0) {

                // Updated By Moh Sarfaraj for BPE-110
                this.partnersOwners.push({ Id: this.partnersOwnersCount, ownerName: this.ownerName, 
                    ownerCountry: this.ownerCountry, partnerOwnerDetails: this.partnerOwnerDetails, 
                    shareHoldingPercentage: this.shareHoldingPercentage, RecordId: this.ownerRecordId, 
                    title: this.ownerTitle, ownerMobileCountryCode: this.ownerMobCountryCode,
                    ownerMobile: this.ownerMobileNumber, ownerEmail: this.ownerEmail, primaryOwner : this.primaryOwner
                 });   
                const authorizedSignatoryObject = { authorizedSignatoryTitle: this.authorizedSignatoryTitle, authorizedSignatoryName: this.authorizedSignatoryName, designation: this.designation, authorizedSignatoryEmail: this.authorizedSignatoryEmail };

                let serviceRequestRecord = { 'sobjectType': 'HexaBPM__Service_Request__c' };

                serviceRequestRecord.Id = this.serviceRequestId == null || this.serviceRequestId == '' ? null : this.serviceRequestId;

                serviceRequestRecord.AccountName__c = this.agencyName;
                serviceRequestRecord.TradeCommercialLicenseNumber__c = this.licenseNumber;
                serviceRequestRecord.Address1__c = this.addressLine1;
                serviceRequestRecord.Address2__c = this.addressLine2;
                serviceRequestRecord.City__c = this.city;
                serviceRequestRecord.State__c = this.state;
                serviceRequestRecord.POBox__c = this.poBox;
                serviceRequestRecord.Country__c = this.country;
                serviceRequestRecord.EstablishmentDate__c = this.establishmentDate;
                serviceRequestRecord.ExpiryDate__c = this.expiryDate;
                serviceRequestRecord.PhoneNumber__c = this.phoneNumberCountryCodeChosed + ' ' + this.phoneNumber;
                serviceRequestRecord.CompanyEmail__c = this.companyEmail;
                serviceRequestRecord.Website__c = this.website;
                serviceRequestRecord.TaxRegistrationNumber__c = this.taxRegistrationCertificate;

                serviceRequestRecord.POATitle__c = this.attorneyTitle;
                serviceRequestRecord.NameOfPOA__c = this.nameOfPOA;

                serviceRequestRecord.BankName__c = this.bankName;
                serviceRequestRecord.SwiftCode__c = this.swiftCode;
                serviceRequestRecord.IBANNumber__c = this.IBANNumber;
                serviceRequestRecord.BankAddress__c = this.branchAddress;
                serviceRequestRecord.BankAccountNumber__c = this.bankAccountNumber;
                serviceRequestRecord.BankCountry__c = this.bankCountry;

                serviceRequestRecord.ReferredBy__c = this.referredBy == null ? '' : this.referredBy;
                serviceRequestRecord.ReferredByTitle__c = this.referredByTitle == null ? '' : this.referredByTitle;
                serviceRequestRecord.Title__c = this.authorizedSignatoryTitle == null ? '' : this.authorizedSignatoryTitle;
                serviceRequestRecord.Designation__c = this.designation == null ? '' : this.designation;
                serviceRequestRecord.SignatoryName__c = this.authorizedSignatoryName == null ? '' : this.authorizedSignatoryName;
                serviceRequestRecord.SignatoryEmail__c = this.authorizedSignatoryEmail == null ? '' : this.authorizedSignatoryEmail;
                serviceRequestRecord.InterestedPropertyLocation__c = this.selectedIntPropLocation;
                serviceRequestRecord.FIABCIRegistered__c = this.fiabciRegistredValue;
                serviceRequestRecord.FIABCIStatus__c = this.fiabciStatusValue;
                serviceRequestRecord.AgencyCategory__c = this.agencyCategoryValue;
                serviceRequestRecord.AMLConsent__c = this.isLegalChecked;
                serviceRequestRecord.VATRegistrationStartDate__c = this.vatStartDateValue; 
                serviceRequestRecord.VATRegistrationEndDate__c = this.vatEndDateValue;
                serviceRequestRecord.VATRegistrationtype__c = this.vatValue;

                await createServiceRequestRecord({ serviceRequestRecord: serviceRequestRecord })
                    .then(result => {
                        this.serviceRequestId = result.Id;

                        let agencyAdmin = { 'sobjectType': 'AgencyTeam__c' };

                        agencyAdmin.Title__c = this.agencyTitle;
                        agencyAdmin.EmailAddress__c = this.contactPersonEmailID;
                        agencyAdmin.DateOfBirth__c = this.dateofBirth;
                        agencyAdmin.Name = this.contactPersonName + ' ' + (this.contactMiddleName != null ? this.contactMiddleName + ' ' : '') + this.contactLastName;
                        agencyAdmin.MobileCountryCode__c = this.contactPersonCountryCode;
                        agencyAdmin.MobileNumber__c =  this.contactPersonMobileNumber;
                        agencyAdmin.ServiceRequest__c = this.serviceRequestId;
                        createAgencyTeamRecord({ agencyAdmin: agencyAdmin, partnersOwners: this.partnersOwners })
                            .then(result => {
                                var s = this.partnersOwners.pop();

                                attachDocuments({
                                    serviceRequestId: this.serviceRequestId
                                })
                                    .then(result => {
                                        this.srMap = result;
                                        this.srDocWithFiles();
                                    }).catch(error => {
                                        console.log(JSON.stringify(error));
                                        this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                                    });

                                if (!this.updateAction) {
                                    this.otpSection = 'show';
                                } else {
                                    updateServiceRequestStep({ step: this.serviceRequestStepObj })
                                        .then(result => {
                                            this.readOnly = true;
                                            this.successSubmit = true;
                                        })
                                        .catch(error => {
                                            console.log(JSON.stringify(error));

                                            this.errorDetails.push('createAgencyTeamRecord Error: ' + JSON.stringify(error));
                                        });
                                }
                            })
                            .catch(error => {
                                console.log(JSON.stringify(error));

                                this.errorDetails.push('createAgencyTeamRecord Error: ' + JSON.stringify(error));
                                var s = this.partnersOwners.pop();

                            });

                    })
                    .catch(error => {
                        this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                        console.log(JSON.stringify(error));
                        var s = this.partnersOwners.pop();
                    });
            } else {
                this.errorDialog = true;
                this.errorDetails.push('Kindly note that your company is already registered with Aldar');
            }
        }
        else {
        }

        setTimeout(() => {
            this.isLoaded = !this.isLoaded;
        }, 5000);

        if (this.errorDetails.length > 0) {
            this.errorDialog = true;
        } else {
            this.errorDialog = false;
        }
    }

    async populateToUpload(i) {

        if (this.srMap[i].Name === 'Memorandum of Association/Power of Attorney' && this.memorandumofAssociationPowerofAttorney != null && this.memorandumofAssociationPowerofAttorney.length > 0) {
            await this.upload(this.memorandumofAssociationPowerofAttorney, this.srMap[i].Id);
            this.numberOfFiles++;

        } else if (this.srMap[i].Name === 'Go AML Certificate' && this.goAMLCertificate != null && this.goAMLCertificate.length > 0) {
            await this.upload(this.goAMLCertificate, this.srMap[i].Id);
            this.numberOfFiles++;
            //ADM/RERA start
        } else if (this.srMap[i].Name === 'ADM / RERA Certificate' && this.ADMRERACertificate != null && this.ADMRERACertificate.length > 0) {
            await this.upload(this.ADMRERACertificate, this.srMap[i].Id);
            this.numberOfFiles++;
            //ADM/RERA end
        } else if (this.srMap[i].Name === 'Company Profile/Brochure/Catalogue' && this.companyProfileBrochureCatalogue != null && this.companyProfileBrochureCatalogue.length > 0) {
            await this.upload(this.companyProfileBrochureCatalogue, this.srMap[i].Id);
            this.numberOfFiles++;

        } else if (this.srMap[i].Name === 'VAT Registration Certificate' && this.vatRegistrationCertificate != null && this.vatRegistrationCertificate.length > 0) {
            await this.upload(this.vatRegistrationCertificate, this.srMap[i].Id);
            this.numberOfFiles++;

        } else if (this.srMap[i].Name === 'Bank Copy' && this.signedBankCopy != null && this.signedBankCopy.length > 0) {
            await this.upload(this.signedBankCopy, this.srMap[i].Id);
            this.numberOfFiles++;

        } else if (this.srMap[i].Name === 'Emirates ID / Passport copy' && ((this.emiratesIDPassportcopyofPartnerOwner != null && this.emiratesIDPassportcopyofPartnerOwner.length > 0) || (this.emiratesIDPassportcopyofPOA != null && this.emiratesIDPassportcopyofPOA.length > 0))) {
            
            await this.upload(this.emiratesIDPassportcopyofPartnerOwner, this.srMap[i].Id);
            await this.upload(this.emiratesIDPassportcopyofPOA, this.srMap[i].Id);
            this.numberOfFiles++;

        } else if (this.srMap[i].Name === 'Trade/Commercial License' && this.attachTradeLicence != null && this.attachTradeLicence.length > 0) {
            await this.upload(this.attachTradeLicence, this.srMap[i].Id);
            this.numberOfFiles++;
        }
    }

    async srDocWithFiles() {
        for (let i = 0; i < this.srMap.length; i++) {
            await this.populateToUpload(i);
        }

        await uploadFiles({
            filesToUpload: this.filesToUpload
        }).then(result => {

            this.progressBarValue = 20;            
            uploadFiles({
                filesToUpload: this.filesToUpload2,
            }).then(result => {
                this.progressBarValue = 30;

                uploadFiles({
                    filesToUpload: this.filesToUpload3,
                }).then(result => {
                    this.progressBarValue = 45;

                    uploadFiles({
                        filesToUpload: this.filesToUpload4,
                    }).then(result => {
                        this.progressBarValue = 65;

                        uploadFiles({
                            filesToUpload: this.filesToUpload5,
                        }).then(result => {
                            this.progressBarValue = 75;

                            uploadFiles({
                                filesToUpload: this.filesToUpload6,
                            }).then(result => {

                                this.progressBarValue = 85;

                                uploadFiles({
                                    filesToUpload: this.filesToUpload7,
                                }).then(result => {
                                    this.progressBarValue = 95;

                                    uploadFiles({
                                        filesToUpload: this.filesToUpload8,
                                    }).then(result => {
                                        this.progressBarValue = 100;
                                        this.progressBarCompleted = true;

                                    }).catch(error => {
                                        this.errorDetails.push('uploadFiles Error: ' + JSON.stringify(error));
                                        console.log('uploadFiles Error: ' + JSON.stringify(error));
                                    });
                                }).catch(error => {
                                    this.errorDetails.push('uploadFiles Error: ' + JSON.stringify(error));
                                    console.log('uploadFiles Error: ' + JSON.stringify(error));
                                    console.log(error);

                                });

                            }).catch(error => {
                                this.errorDetails.push('uploadFiles Error: ' + JSON.stringify(error));
                                console.log('uploadFiles Error: ' + JSON.stringify(error));
                                console.log(error);

                            });
                        }).catch(error => {
                            this.errorDetails.push('uploadFiles Error: ' + JSON.stringify(error));
                            console.log('uploadFiles Error: ' + JSON.stringify(error));
                            console.log(error);

                        });
                    }).catch(error => {
                        this.errorDetails.push('uploadFiles Error: ' + JSON.stringify(error));
                        console.log('uploadFiles Error: ' + JSON.stringify(error));
                        console.log(error);

                    });

                }).catch(error => {
                    this.errorDetails.push('uploadFiles Error: ' + JSON.stringify(error));
                    console.log('uploadFiles Error: ' + JSON.stringify(error));
                    console.log(error);

                });

            }).catch(error => {
                this.errorDetails.push('uploadFiles Error: ' + JSON.stringify(error));
                console.log('uploadFiles Error: ' + JSON.stringify(error));
                console.log(error);

            });

        }).catch(error => {
            this.errorDetails.push('uploadFiles Error: ' + JSON.stringify(error));
            console.log('uploadFiles Error: ' + JSON.stringify(error));
            console.log(error);

        });
    }
    filesToUpload = [];
    filesToUpload2 = [];
    filesToUpload3 = [];
    filesToUpload4 = [];
    filesToUpload5 = [];
    filesToUpload6 = [];
    filesToUpload7 = [];
    filesToUpload8 = [];

    async upload(fileData, recordId) {

        await Array.from(fileData).forEach(file => {
            if (file.old == null) {
                const { base64, filename } = file;
                if (base64 != null) {

                    if ((new Blob([JSON.stringify(file)]).size + new Blob([JSON.stringify(this.filesToUpload)]).size) < 4000000) {
                        this.filesToUpload.push({ base64: base64, fileName: filename, Id: recordId });
                    } else if ((new Blob([JSON.stringify(file)]).size + new Blob([JSON.stringify(this.filesToUpload2)]).size) < 4000000) {
                        this.filesToUpload2.push({ base64: base64, fileName: filename, Id: recordId });
                    } else if ((new Blob([JSON.stringify(file)]).size + new Blob([JSON.stringify(this.filesToUpload3)]).size) < 4000000) {
                        this.filesToUpload3.push({ base64: base64, fileName: filename, Id: recordId });
                    } else if ((new Blob([JSON.stringify(file)]).size + new Blob([JSON.stringify(this.filesToUpload4)]).size) < 4000000) {
                        this.filesToUpload4.push({ base64: base64, fileName: filename, Id: recordId });
                    } else if ((new Blob([JSON.stringify(file)]).size + new Blob([JSON.stringify(this.filesToUpload5)]).size) < 4000000) {
                        this.filesToUpload5.push({ base64: base64, fileName: filename, Id: recordId });
                    } else if ((new Blob([JSON.stringify(file)]).size + new Blob([JSON.stringify(this.filesToUpload6)]).size) < 4000000) {
                        this.filesToUpload6.push({ base64: base64, fileName: filename, Id: recordId });
                    } else if ((new Blob([JSON.stringify(file)]).size + new Blob([JSON.stringify(this.filesToUpload7)]).size) < 4000000) {
                        this.filesToUpload7.push({ base64: base64, fileName: filename, Id: recordId });
                    } else if ((new Blob([JSON.stringify(file)]).size + new Blob([JSON.stringify(this.filesToUpload8)]).size) < 4000000) {
                        this.filesToUpload8.push({ base64: base64, fileName: filename, Id: recordId });
                    }
                } else {
                    console.log('base64 = null');
                }
            }
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

    async downloadVAT() {

        let a = document.createElement("a");
        a.href = VATLetterTemplate;
        a.download = 'VAT Letter Template.pdf';
        a.click();
    }


    async openfileUpload(event) {
        function getBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = error => reject(error);
            });
        }

        let files = event.target.files;
        var id = event.target.dataset.id;

        if (files.length > 0) {
            var acceptFileList = [];
            for (let i = 0; i < files.length; i++) {
                let filePieces = files[i].name.split('.');
                let fileType = filePieces[filePieces.length - 1].trim();

                if (this.acceptFileTypeList.includes(fileType)) {
                    acceptFileList.push(files[i]);
                }
            }
            if (acceptFileList.length > 0) {


                await Array.from(acceptFileList).forEach(file => {

                    var base64;
                    getBase64(file).then(
                        data => {
                            base64 = data.split(',')[1];
                        }
                    );

                    let fileSize = file.size;

                    const acceptedFormats = this.acceptFileTypeList;
                    if (file.size > 2000000) {
                        const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id=' + id + ']')]
                            .reduce((validSoFar, inputField) => {

                                inputField.setCustomValidity('File Size Is more than 2MB');

                                inputField.reportValidity();
                                return validSoFar && inputField.checkValidity();
                            }, true);

                    } else if (!acceptedFormats.includes(file.type.split('/')[0]) && !acceptedFormats.includes(file.type.split('/')[1])) {

                        const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id=' + id + ']')]
                            .reduce((validSoFar, inputField) => {

                                inputField.setCustomValidity('File Type Should be one of the following: ' + acceptedFormats);

                                inputField.reportValidity();
                                return validSoFar && inputField.checkValidity();
                            }, true);

                    } else {

                        const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id=' + id + ']')]
                            .reduce((validSoFar, inputField) => {

                                inputField.setCustomValidity('');

                                inputField.reportValidity();
                                return validSoFar && inputField.checkValidity();
                            }, true);

                        var reader = new FileReader();

                        if (event.target.dataset.id === 'GoAMLCertificate') {
                            reader.onload = () => {
                                let result = this.goAMLCertificate.filter(obj => {

                                    return obj.filename === file.name;
                                });

                                if ((file.size + new Blob([JSON.stringify(this.goAMLCertificate)]).size) > 2500000) {
                                    alert('Files Size is More Than 2 MB.');
                                } else {

                                    this.goAMLCertificate.push({
                                        'filename': result?.length > 0 ? file.name + `(${this.goAMLCertificate.length})` : file.name,
                                        'base64': reader.result.split(',')[1],
                                        'fileSize': fileSize,
                                    });
                                }
                            }
                            reader.readAsDataURL(file);

                            //console.log('after');
                            //ADM/RERA start
                        } else if (event.target.dataset.id === 'ADMRERACertificate') {
                            reader.onload = () => {

                                //console.log('reader.result');

                                let result = this.ADMRERACertificate.filter(obj => {

                                    return obj.filename === file.name;
                                });

                                if ((file.size + new Blob([JSON.stringify(this.ADMRERACertificate)]).size) > 2500000) {
                                    alert('Files Size is More Than 2 MB.');
                                } else {

                                    this.ADMRERACertificate.push({
                                        'filename': result?.length > 0 ? file.name + `(${this.ADMRERACertificate.length})` : file.name,
                                        'base64': reader.result.split(',')[1],
                                        'fileSize': fileSize,
                                    });
                                }
                            }
                            reader.readAsDataURL(file);
                            //ADM/RERA end
                        } else if (event.target.dataset.id === 'CompanyProfileBrochureCatalogue') {
                            let result = this.companyProfileBrochureCatalogue.filter(obj => {

                                return obj.filename === file.name;
                            });


                            reader.onload = () => {

                                if ((file.size + new Blob([JSON.stringify(this.companyProfileBrochureCatalogue)]).size) > 2500000) {
                                    alert('Files Size is More Than 2 MB.');
                                } else {
                                    this.companyProfileBrochureCatalogue.push({
                                        'filename': result?.length > 0 ? file.name + `(${this.companyProfileBrochureCatalogue.length})` : file.name,
                                        'base64': reader.result.split(',')[1],
                                        'fileSize': fileSize,
                                    });
                                }
                            }
                            reader.readAsDataURL(file);
                        } else if (event.target.dataset.id === 'AttachTradeLicence') {
                            let result = this.attachTradeLicence.filter(obj => {

                                return obj.filename === file.name;
                            });

                            reader.onload = () => {

                                if ((file.size + new Blob([JSON.stringify(this.attachTradeLicence)]).size) > 2500000) {
                                    alert('Files Size is More Than 2 MB.');
                                } else {
                                    this.attachTradeLicence.push({
                                        'filename': result?.length > 0 ? file.name + `(${this.attachTradeLicence.length})` : file.name,
                                        'base64': reader.result.split(',')[1],
                                        'fileSize': fileSize,

                                    });
                                }
                            }
                            reader.readAsDataURL(file);

                        } else if (event.target.dataset.id === 'EmiratesIDPassportcopyofPOA') {
                            let result = this.emiratesIDPassportcopyofPOA.filter(obj => {

                                return obj.filename === file.name;
                            });


                            reader.onload = () => {

                                if ((file.size + new Blob([JSON.stringify(this.emiratesIDPassportcopyofPOA)]).size) > 2500000) {
                                    alert('Files Size is More Than 2 MB.');
                                } else {
                                    this.emiratesIDPassportcopyofPOA.push({
                                        'filename': result?.length > 0 ? file.name + `(${this.emiratesIDPassportcopyofPOA.length})` : file.name,
                                        'base64': reader.result.split(',')[1],
                                        'fileSize': fileSize,

                                    });
                                }
                            }
                            reader.readAsDataURL(file);

                        } else if (event.target.dataset.id === 'MemorandumofAssociationPowerofAttorney') {
                            let result = this.memorandumofAssociationPowerofAttorney.filter(obj => {
                                return obj.filename === file.name;
                            });

                            reader.onload = () => {

                                if ((file.size + new Blob([JSON.stringify(this.memorandumofAssociationPowerofAttorney)]).size) > 2500000) {
                                    alert('Files Size is More Than 2 MB.');
                                } else {
                                    this.memorandumofAssociationPowerofAttorney.push({
                                        'filename': result?.length > 0 ? file.name + `(${this.memorandumofAssociationPowerofAttorney.length})` : file.name,
                                        'base64': reader.result.split(',')[1],
                                        'fileSize': fileSize,

                                    });
                                }
                            }
                            reader.readAsDataURL(file);

                        } else if (event.target.dataset.id === 'EmiratesIDPassportcopyofPartnerOwner') {

                            let result = this.emiratesIDPassportcopyofPartnerOwner.filter(obj => {
                                return obj.filename === file.name;
                            });

                            let id = event.target.name == null ? '' : event.target.name;

                            let flag = true;
                            reader.onload = () => {

                                if ((file.size + new Blob([JSON.stringify(this.emiratesIDPassportcopyofPartnerOwner)]).size) > 2500000) {
                                    flag = false;
                                    alert('Files Size is More Than 2 MB.');
                                } else {

                                    this.emiratesIDPassportcopyofPartnerOwner.push({
                                        'filename': result?.length > 0 ? (id == '' ? 'POF' : 'PO') + id + file.name + `(${this.emiratesIDPassportcopyofPartnerOwner.length})` : (id == '' ? 'POF' : 'PO') + id + file.name,
                                        'base64': reader.result.split(',')[1],
                                        'Id': id,
                                        'fileSize': fileSize,

                                    });

                                    var value = event.target.value;
                                    let index = this.partnersOwners.findIndex(a => a.Id === id);

                                    if (index != null && this.partnersOwners[index] != null && this.partnersOwners[index].filename != null) {
                                        this.partnersOwners[index].filename = 'PO' + index + file.name;
                                    } else {
                                        this.firstPartnersOwnerFiles.push(file.name);
                                    }
                                }
                            }
                            reader.readAsDataURL(file);

                            if (flag) {

                            }


                        } else if (event.target.dataset.id === 'SignedBankCopy') {

                            let result = this.signedBankCopy.filter(obj => {
                                return obj.filename === file.name;
                            });

                            reader.onload = () => {
                                if ((file.size + new Blob([JSON.stringify(this.signedBankCopy)]).size) > 2500000) {
                                    alert('Files Size is More Than 2 MB.');
                                } else {
                                    this.signedBankCopy.push({
                                        'filename': result?.length > 0 ? file.name + `(${this.signedBankCopy.length})` : file.name,
                                        'base64': reader.result.split(',')[1],
                                        'fileSize': fileSize,

                                    });
                                }
                            }
                            reader.readAsDataURL(file);

                        } else if (event.target.dataset.id === 'VATRegistrationCertificate') {
                            let result = this.vatRegistrationCertificate.filter(obj => {
                                return obj.filename === file.name;
                            });


                            reader.onload = () => {

                                if ((file.size + new Blob([JSON.stringify(this.vatRegistrationCertificate)]).size) > 2500000) {
                                    alert('Files Size is More Than 2 MB.');
                                } else {

                                    this.vatRegistrationCertificate.push({
                                        'filename': result?.length > 0 ? file.name + `(${this.vatRegistrationCertificate.length})` : file.name,
                                        'base64': reader.result.split(',')[1],
                                        'fileSize': fileSize,

                                    });
                                }
                            }
                            reader.readAsDataURL(file);
                        } else {
                        }
                    }
                });
            } else {
                const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id=' + id + ']')]
                    .reduce((validSoFar, inputField) => {

                        inputField.setCustomValidity('Accepted format are ' + this.acceptFileTypeList);

                        inputField.reportValidity();
                        return validSoFar && inputField.checkValidity();
                    }, true);
            }
        }
        this.checkCompletedSections();
    }

    resendOTP(event) {
        this.isLoaded = true;
        updateAgencyTeam({ serviceRequestId: this.serviceRequestId })
            .then(result => {
                this.isLoaded = false;
            })
            .catch(error => {
                console.log(JSON.stringify(error));

                this.isLoaded = false;
            });
    }

    handleOTP(event) {
        this.isLoaded = true;

        if (event.target.dataset.id === 'CancelOTP') {
            this.otpSection = '';
        } else {
            getOtpDetails({ serviceRequestId: this.serviceRequestId })
                .then(result => {
                    if (result != null) {
                        const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="OTP"]')]
                            .reduce((validSoFar, inputField) => {

                                if (this.userOTP !== result.OTPNumber__c) {
                                    inputField.setCustomValidity('Invalid Pin Code.');
                                } else {
                                    inputField.setCustomValidity('');

                                    updateServiceRequestRecordStatus({ serviceRequestId: this.serviceRequestId, status: this.srStatus })
                                        .then(result => {
                                            this.otpSection = '';
                                            this.success = 'show';
                                            this.isLoaded = false;
                                        })
                                        .catch(error => {
                                            console.log(JSON.stringify(error));

                                            this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                                            this.isLoaded = false;
                                        });
                                }
                                inputField.reportValidity();

                                return validSoFar && inputField.checkValidity() && (this.userOTP === result.OTPNumber__c);
                            }, true);
                    } else {
                        const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="OTP"]')]
                            .reduce((validSoFar, inputField) => {

                                inputField.setCustomValidity('Session Timeout, Please Generate another PIN.');
                                inputField.reportValidity();

                                return false;
                            }, true);
                    }
                })
                .catch(error => {
                    console.log(JSON.stringify(error));

                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                });
        }
    }
    removeError() {
        this.errorDialog = false;
        this.errorDetails = [];
    }

    counter = 0;
    openSection(event) {
        let selected = event?.target?.dataset["id"] || event?.currentTarget?.dataset?.id || "AgencyInformation";
        this.counter += 1;

        let selectedIndex = (event?.target?.dataset["leftsideindex"] || event?.currentTarget?.dataset?.leftsideindex) ||
            (event?.target?.dataset["index"] || event?.currentTarget?.dataset?.index) || 1;


        for (let index = 1; index <= 7; index++) {
            if (index < selectedIndex) {
                this.template.querySelectorAll(`[data-leftsideindex="${index}"]`)[0].classList.add("slds-is-completed");
            }

            if (selectedIndex < index) {
                this.template.querySelectorAll(`[data-leftsideindex="${index}"]`)[0].classList.remove("slds-is-completed");
                this.template.querySelectorAll(`[data-leftsideindex="${index}"]`)[0].classList.remove("slds-is-active");
            }

            if (index == selectedIndex) {
                this.template.querySelectorAll(`[data-leftsideindex="${selectedIndex}"]`)[0].classList.add("slds-is-active");
                let scrollToDiv = selected + "ST"
                this.template.querySelectorAll(`[data-scrollto="${scrollToDiv}"]`)[0]?.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
            }
        }

        // and you have to add  allow-multiple-sections-open to the lightning-accordion html tag
        if (this.multipleSelection) {
            if ((this.counter == 1) || (event?.target?.dataset != undefined && Object.keys(event?.target?.dataset).length != 0)) {
                //for multiple selection
                if (this.activeSections.indexOf(selected) == -1) {

                    this.activeSections = [...this.activeSections, selected];
                } else if (this.activeSections.indexOf(selected) != -1 && (event?.target?.dataset["scrollto"] != undefined && Object.keys(event?.target?.dataset).length != 0)) {

                    this.activeSections.splice(this.activeSections.indexOf(selected), 1);
                    this.activeSections = [...this.activeSections];
                }
            }
        } else {
            this.activeSections = selected; // for one selection
        }
    }

    removeFile(event) {
        let listName = event.currentTarget.dataset.listname;
        let fileName = event.currentTarget.dataset.id;

        switch (listName) {
            case "goAMLCertificate":
                this.goAMLCertificate = this.goAMLCertificate.filter(function (obj) {
                    return obj.filename != fileName;
                });

                this.goAMLCertificate = [...this.goAMLCertificate];
                break;
            //ADM/RERA start
            case "ADMRERACertificate":
                this.ADMRERACertificate = this.ADMRERACertificate.filter(function (obj) {
                    return obj.filename != fileName;
                });

                this.ADMRERACertificate = [...this.ADMRERACertificate];
                break;
            //ADM/RERA end
            case "emiratesIDPassportcopyofPOA":
                this.emiratesIDPassportcopyofPOA = this.emiratesIDPassportcopyofPOA.filter(function (obj) {
                    return obj.filename != fileName;
                });

                this.emiratesIDPassportcopyofPOA = [...this.emiratesIDPassportcopyofPOA];
                break;
            case "companyProfileBrochureCatalogue":
                this.companyProfileBrochureCatalogue = this.companyProfileBrochureCatalogue.filter(function (obj) {
                    return obj.filename != fileName;
                });
                this.companyProfileBrochureCatalogue = [...this.companyProfileBrochureCatalogue];
                break;
            case "attachTradeLicence":
                this.attachTradeLicence = this.attachTradeLicence.filter(function (obj) {
                    return obj.filename != fileName;
                });
                this.attachTradeLicence = [...this.attachTradeLicence];
                break;
            case "vatRegistrationCertificate":
                this.vatRegistrationCertificate = this.vatRegistrationCertificate.filter(function (obj) {
                    return obj.filename != fileName;
                });
                this.vatRegistrationCertificate = [...this.vatRegistrationCertificate];
                break;
            case "memorandumofAssociationPowerofAttorney":
                this.memorandumofAssociationPowerofAttorney = this.memorandumofAssociationPowerofAttorney.filter(function (obj) {
                    return obj.filename != fileName;
                });
                this.memorandumofAssociationPowerofAttorney = [...this.memorandumofAssociationPowerofAttorney];
                break;
            case "emiratesIDPassportcopyofPartnerOwner":
                this.emiratesIDPassportcopyofPartnerOwner = this.emiratesIDPassportcopyofPartnerOwner.filter(function (obj) {
                    return obj.filename != fileName;
                });
                this.emiratesIDPassportcopyofPartnerOwner = [...this.emiratesIDPassportcopyofPartnerOwner];

                let id = event.currentTarget.dataset.index == null ? '' : event.currentTarget.dataset.index;
                let index = this.partnersOwners.findIndex(a => a.Id === parseInt(id));

                if (id != '' && (this.partnersOwners[index] != null || this.partnersOwners[index] != undefined) && this.partnersOwners[index].filename != null) {
                    this.partnersOwners[index].filename = '';
                } else {
                    this.firstPartnersOwnerFiles.splice(index, 1);
                }
                break;
            case "signedBankCopy":
                this.signedBankCopy = this.signedBankCopy.filter(function (obj) {
                    return obj.filename != fileName;
                });
                this.signedBankCopy = [...this.signedBankCopy];
                break;
        }

    }


    toggleMessageBox() {
        this.showMessageBox = !this.showMessageBox;
    }


    closeModal(event) {
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.success = event.detail.isOpen;
        // Move to a new location
        window.location.href = PortalLoginURL;
    }

    closeSubmitModal() {
        location.reload();
    }

    closeOTP() {
        location.reload();
    }
    onchangeOfTradeLicenseNumber(event){
        this.existinglicenseNumber = event.target.value;
    }
    resendOTPForTradeLicenseNumer(){

        this.isLoaded = true;
        console.log('resendOTPForTradeLicenseNumer');
        console.log('this.existinglicenseNumber::'+this.existinglicenseNumber);
      var existinglicenseNumber = this.template.querySelector('[data-id="existinglicenseNumber"]');
      if(this.existinglicenseNumber == '' || this.existinglicenseNumber == null || this.existinglicenseNumber == undefined){
        this.isLoaded = false;
        this.OTPMessage = 'Please Enter Valid Trade License Number';
      //  existinglicenseNumber.setCustomValidity('Please Enter Valid Trade License Number');
      }else{
        resendOTPForTradeLicenseNumber({LicenseNumber:this.existinglicenseNumber})
        .then(result => {
         
      if(result == 'Draft'){
          this.OTPMessage = 'OTP Sent Successfully';
          existinglicenseNumber.setCustomValidity('');
          this.getOTP = false;
          this.isLoaded = false;
         }else if(result == 'Submitted'){
          this.isLoaded = false;
          this.OTPMessage = '';
          existinglicenseNumber.setCustomValidity('This Trade License number is already registered, Kindly get in touch with your broker manager');
         // this.errorDetails.push('There is Already Agency Admin with This Trade License number.');  
       }else if(result == 'Not Registered'){
          this.isLoaded = false;
          this.OTPMessage = '';
          existinglicenseNumber.setCustomValidity('This Trade License number is Not registered, Kindly Register!');
        }
      existinglicenseNumber.reportValidity();
      
      })
      .catch(error => {   
          this.isLoaded = false;
      })
      }

    }

    // Added By Moh Sarfaraj for BPE-197 starts
    showTermsAndConditions = false;
    isAcceptedTAndC = false;
    handleTermsConditions(event){
        this.showTermsAndConditions = true;
    }

    handleConsentCheck(event){
        this.isLegalChecked = event.target.checked;
    }

    handleTAndCEvent(event){
        this.showTermsAndConditions = false;
        this.isAcceptedTAndC = event.detail.type === 'accept'  ? true :false;
    }

    navigateToGetOTP(event){
        this.getOTP = true;
        this.OTPMessage = '';
        this.existinglicenseNumber = '';
    }
    closeOTP(){
        this.getOTP = false;
        this.OTPMessage = '';
        this.existinglicenseNumber = '';
    }
}