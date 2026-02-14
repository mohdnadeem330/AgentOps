import { LightningElement, wire, api, track } from 'lwc';
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
import PortalLoginURL from '@salesforce/label/c.PortalLoginURL';

const DELAY = 3000;


export default class BrokerRegistration extends NavigationMixin(LightningElement) {

    @track verifiedBool = true;
    @track captchaResponse;
    phoneNumberCountryCode;
    @track phoneNumberCountryCodeChosed = '971';
    @track contactPersonCountryCode = '971';




    multipleSelection = true;
    informationTooltipIcon = resourcesPath + "/ALDARResources/svg/InformationTooltip.svg";
    infoIcon = resourcesPath + "/ALDARResources/svg/InfoIcon.svg";

    title = "Agency Registration";
    titleDetails = "";
    @track country;
    @track agencyName;
    @track establishmentDate;
    @track licenseNumber;
    @track expiryDate;
    @track phoneNumber;
    @track companyEmail;
    @track addressLine1;
    @track addressLine2;
    @track state;
    @track city;
    @track poBox;
    @track taxRegistrationCertificate;
    @track website;
    text = "test text";
    @track srName;
    @track srExternalStatus;
    @track id;
    @track nameOfPOA;
    @track attorneyTitle;
    @track ownerTitle;
    @track ownerName;
    @track ownerCountry;
    @track partnerOwnerDetails;
    @track shareHoldingPercentage;
    @track sumOfShareHoldingPercentage;
    @track ownerRecordId;
    @track bankName;
    @track IBANNumber;
    @track swiftCode;
    @track branchAddress;
    @track agencyTitle;
    @track contactPersonName;
    @track contactMiddleName;
    @track contactLastName;
    @track contactPersonMobileNumber;
    @track contactPersonEmailID;
    @track dateofBirth;

    @track referredByTitle;
    @track referredBy;

    @track authorizedSignatoryTitle;
    @track authorizedSignatoryName;
    @track designation;
    @track authorizedSignatoryEmail;


    //
    activeSections = [];
    @track serviceRequestId;
    @track fileData;
    @track errorDialog;
    @track errorDetails = [];

    @track srMap;
    @track phoneNumberResponse = false;
    @track contactMobileNumberResponse = false;
    @track emailResponse = false;
    @track contactEmailIdResponse = false;
    @track existingAgencys;
    @track existingAgencyAdmin;
    @track existingServicesRequests;
    @track ibanNumberResponse = false;
    @track authorizedSignatoryEmailResponse = false;

    @track otpSection;
    @api isLoaded = false;
    @track userOTP;
    @track success;
    @track agencyAdminType;
    @track stepStatus;
    @track serviceRequestStepObj;

    @track goAMLCertificate = [];
    @track companyProfileBrochureCatalogue = [];
    @track attachTradeLicence = [];
    @track emiratesIDPassportcopyofPOA = [];
    @track memorandumofAssociationPowerofAttorney = [];
    @track emiratesIDPassportcopyofPartnerOwner = [];
    @track signedBankCopy = [];
    @track vatRegistrationCertificate = [];

    @track multiPartnerOwner = false;

    @track partnersOwners = [];
    @track firstPartnersOwnerFiles = [];
    @track partnersOwnersCount = 0;
    @track readOnly = false;
    @track agencyAdminReadOnly = false;
    @track readOnlyFields = false;
    @track updateAction = false;
    userId = Id;
    @track makerequired = true;

    completed = resourcesPath + "/ALDARResources/svg/Completed.svg";
    currentStage = resourcesPath + "/ALDARResources/svg/CurrentStage.svg";
    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";

    @track isAgencyInformationCompleted = false;
    @track isAgencyInformationCurrentStage = true;

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
    @track progressBarValue = 0;
    @track progressBarCompleted = false;
    @track numberOfFiles = 0;
    @api mobileNumberToCheck = '';
    @track phoneNumberToCheck = '';

    @track notes = '';
    @track hasNotes = false;

    @wire(getValidateEmail, { email: '$companyEmail' })
    emailResponse;

    @wire(getValidatePhoneNoWithAura, { phoneNo: '$mobileNumberToCheck' })
    mobileResponse;

    @wire(getValidatePhoneNoWithAura, { phoneNo: '$phoneNumberToCheck' })
    phoneNumberResponse;

    @wire(getValidateEmail, { email: '$contactPersonEmailID' })
    contactEmailIdResponse;

    @wire(getValidateEmail, { email: '$authorizedSignatoryEmail' })
    authorizedSignatoryEmailResponse;

    @wire(getValidateIBAN, { ibanNumber: '$IBANNumber' })
    ibanNumberResponse;

    async connectedCallback() {


        await getAllConstants().then(data => {
            console.log('getAllConstants: ' + data);
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

        this.getCountryCodeValues();
        //this will help to close tootip after the user press outside it
        // document.addEventListener('click', ()=>{

        // });



        var today = new Date();
        this.todaysDate = today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + today.getDate();
        this.yesterdayDate = (today.getFullYear() - 18) + '-' + (today.getMonth() + 1) + '-' + (today.getDate());

        this.tomorrowDate = today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + (today.getDate() + 1);

        this.isLoaded = !this.isLoaded;


        console.log('this.userId: ' + this.userId);
        if (this.userId) {

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


                        this.phoneNumber = result.PhoneNumber__c.split(' ')[1];
                        this.phoneNumberCountryCodeChosed = result.PhoneNumber__c.split(' ')[0];

                        this.companyEmail = result.CompanyEmail__c;
                        this.taxRegistrationCertificate = result.TaxRegistrationNumber__c;
                        this.nameOfPOA = result.NameOfPOA__c;
                        this.bankName = result.BankName__c;
                        this.swiftCode = result.SwiftCode__c;
                        this.IBANNumber = result.IBANNumber__c;
                        this.branchAddress = result.BankAddress__c;
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
                    }
                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
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
                                this.contactPersonMobileNumber = result[i].MobileNumber__c.split(' ')[1];
                                this.contactPersonCountryCode = result[i].MobileNumber__c.split(' ')[0];
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
                                } else {
                                    this.partnersOwners.push({
                                        Id: this.partnersOwnersCount, ownerName: result[i].Name, ownerCountry: result[i].Country__c,
                                        partnerOwnerDetails: result[i].PartnerOwnerDetails__c, shareHoldingPercentage: result[i].ShareHoldingPercentage__c, RecordId: result[i].Id, title: result[i].Title__c,
                                    });
                                    this.partnersOwnersCount = this.partnersOwnersCount + 1;
                                }
                            }

                        }

                    }

                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                });

            await getServiceRequestStep({ serviceRequestId: this.serviceRequestId })
                .then(result => {

                    this.serviceRequestStepObj = result;
                    console.log('this.serviceRequestStepObj: ' + JSON.stringify(this.serviceRequestStepObj));
                    console.log('this.srExternalStatus: ' + this.srExternalStatus);
                    if (result != null && (result.HexaBPM__Step_Status__c === this.stepStatus)) {
                        this.readOnly = false;
                        this.readOnlyFields = true;
                        this.verifiedBool = !this.verifiedBool

                        if (result.HexaBPM__Step_Notes__c != '' && result.HexaBPM__Step_Notes__c != null) {
                            this.notes = result.HexaBPM__Step_Notes__c;
                            this.hasNotes = true;
                        }
                    } else {
                        this.readOnly = true;
                    }
                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
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
                            this.emiratesIDPassportcopyofPartnerOwner.push({
                                'filename': result[i].fileName,
                                'base64': result[i].base64,
                                'old': 'true',
                            });
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
                });
        }



        setTimeout(() => {
            this.isLoaded = !this.isLoaded;

            //this.hideCompletedandCurrentStages();
            // this.template.querySelectorAll(".current-stage.agency-information-img")[0].style.display = 'inline-block';
            this.openSection("");

        }, 2000);

    }



    getCountryCodeValues() {

        getCountryCodeValues().then((response) => {
            this.phoneNumberCountryCode = response;
        }).catch(error => {
        });

    }


    addPartnerOwner(event) {

        this.partnersOwners.push({ Id: this.partnersOwnersCount, ownerName: '', ownerCountry: '', partnerOwnerDetails: '', shareHoldingPercentage: '', RecordId: '', title: '', filename: '' });

        this.partnersOwnersCount = this.partnersOwnersCount + 1;

        if (this.partnersOwners.length === 0) {
            this.multiPartnerOwner = false;
        } else {
            this.multiPartnerOwner = true;
        }

    }

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
        return ['.pdf', '.png', '.jpg', '.jpeg'];
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


    }


    handleChange(event) {

        var value = event.target.value;

        if (event.target.dataset.id === 'AgencyName') {
            this.agencyName = value;
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
            this.phoneNumber = value;

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

        } else if (event.target.dataset.id === 'CompanyEmail') {
            this.companyEmail = value;

            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="CompanyEmail"]');

                if (!this.emailResponse.data) {
                    target.setCustomValidity("Enter Valid Email.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
        } else if (event.target.dataset.id === 'AddressLine1') {
            this.addressLine1 = value;
        } else if (event.target.dataset.id === 'AddressLine2') {
            this.addressLine2 = value;
        } else if (event.target.dataset.id === 'Country') {
            this.country = value;
        } else if (event.target.dataset.id === 'State') {
            this.state = value;
        } else if (event.target.dataset.id === 'City') {
            this.city = value;
        } else if (event.target.dataset.id === 'POBox') {
            this.poBox = value;
        } else if (event.target.dataset.id === 'TaxRegistrationCertificate') {
            this.taxRegistrationCertificate = value;
        } else if (event.target.dataset.id === 'Website') {
            this.website = value;
        } else if (event.target.dataset.id === 'NameOfPOA') {
            this.nameOfPOA = value;
        } else if (event.target.dataset.id === 'AttorneyTitle') {
            this.attorneyTitle = value;
        }
        else if (event.target.dataset.id === 'OwnerTitle') {
            this.ownerTitle = value;
        } else if (event.target.dataset.id === 'OwnerName') {
            this.ownerName = value;
        } else if (event.target.dataset.id === 'OwnerCountry') {
            this.ownerCountry = value;
        } else if (event.target.dataset.id === 'PartnerOwnerDetails') {
            this.partnerOwnerDetails = value;
        } else if (event.target.dataset.id === 'ShareHoldingPercentage') {
            this.shareHoldingPercentage = value;
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
            var result = this.swiftCode != null ? this.swiftCode.match(myReg) : null;

            this.delayTimeout = setTimeout(async () => {

                let target = await this.template.querySelector('[data-id="SwiftCode"]');

                if (result == null) {
                    target.scrollIntoView();
                    target.setCustomValidity('Enter Valid Swift Code.');
                    this.errorDetails.push('Enter Valid Swift Code.');
                } else {
                    target.setCustomValidity('');
                }
                target.reportValidity();
            }, DELAY);

        } else if (event.target.dataset.id === 'BranchAddress') {
            this.branchAddress = value;
        }

        else if (event.target.dataset.id === 'AgencyTitle') {
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

            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="ContactPersonMobileNumber"]');

                if (!this.mobileResponse.data) {
                    target.setCustomValidity("Enter Valid Mobile Number.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);

        } else if (event.target.dataset.id === 'ContactPersonEmailID') {
            this.contactPersonEmailID = value;

            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="ContactPersonEmailID"]');

                if (!this.contactEmailIdResponse.data) {
                    target.setCustomValidity("Enter Valid Email.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
        } else if (event.target.dataset.id === 'DateofBirth') {
            this.dateofBirth = value;
            this.validateDate('DateofBirth', this.dateofBirth);
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
            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="AuthorizedSignatoryEmail"]');

                if (!this.authorizedSignatoryEmailResponse.data) {
                    target.setCustomValidity("Enter Valid Email.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
        }

        this.checkCompletedSections();

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
            console.log('isAgencyAdminInformationCompleted: ' + this.isAgencyAdminInformationCompleted);
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
            console.log('isPowerOfAttorneyCompleted: ' + this.isPowerOfAttorneyCompleted);
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
            console.log('isPartnerOwnerDetailsCompleted: ' + this.isPartnerOwnerDetailsCompleted);
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
            console.log('isBankDetailsCompleted: ' + this.isBankDetailsCompleted);
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
            console.log('isAgencyAdminInformationCompleted: ' + this.isAgencyAdminInformationCompleted);
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
            console.log('isAuthorizedSignatoryCompleted: ' + this.isAuthorizedSignatoryCompleted);
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

    /*String nameOfPOA, String bankName, String swiftCode, String ibanNumber, String bankAddress, String title, String firstName,
     String lastName, String middleName, String email, date dob, String mobile */

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

        var isSwiftCorrect;

        if (!isInputsCorrect) {
            this.errorDetails.push('Complete Mandatory Fields.');
        } else {
            isSwiftCorrect = await [...this.template.querySelectorAll('[data-id="SwiftCode"]')]
                .reduce((validSoFar, inputField) => {

                    var myReg = '^[a-zA-Z]{6}[a-zA-Z0-9]{2}([a-zA-Z0-9]{3})?$';
                    var result = this.swiftCode != null ? this.swiftCode.match(myReg) : null;

                    if (result == null) {
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
                });


            await getAgencyTeamByEmail({ email: this.contactPersonEmailID })
                .then(result => {
                    if (this.updateAction) {
                        this.existingAgencyAdmin = null;
                    } else {
                        this.existingAgencyAdmin = result;
                    }
                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
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
                    });
            }
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
                });

            await getServicesRequestsByLicenseNumberAndEmail({
                licenseNumber: this.licenseNumber, email: this.companyEmail
            })
                .then(result => {
                    this.existingServicesRequests = result;

                })
                .catch(error => {
                    this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
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
                    });
            }

            if ((this.existingAgencys.length === 0 || this.updateAction) && this.errorDetails.length == 0) {


                this.partnersOwners.push({ Id: this.partnersOwnersCount, ownerName: this.ownerName, ownerCountry: this.ownerCountry, partnerOwnerDetails: this.partnerOwnerDetails, shareHoldingPercentage: this.shareHoldingPercentage, RecordId: this.ownerRecordId, title: this.ownerTitle });

                const authorizedSignatoryObject = { authorizedSignatoryTitle: this.authorizedSignatoryTitle, authorizedSignatoryName: this.authorizedSignatoryName, designation: this.designation, authorizedSignatoryEmail: this.authorizedSignatoryEmail };

                await createServiceRequestRecord({
                    serviceRequestId: this.serviceRequestId, accountName: this.agencyName, tradeCommercialLicenseNumber: this.licenseNumber, address1: this.addressLine1,
                    address2: this.addressLine2, city: this.city, state: this.state, poBox: this.poBox, country: this.country, establishmentDate: this.establishmentDate,
                    expiryDate: this.expiryDate, phoneNumber: this.phoneNumberCountryCodeChosed + ' ' + this.phoneNumber, companyEmail: this.companyEmail, website: this.website, taxRegistrationNumber: this.taxRegistrationCertificate,
                    nameOfPOA: this.nameOfPOA, bankName: this.bankName, swiftCode: this.swiftCode, ibanNumber: this.IBANNumber, bankAddress: this.branchAddress,
                    title: this.agencyTitle, firstName: this.contactPersonName, lastName: this.contactLastName, middleName: this.contactMiddleName, email: this.contactPersonEmailID,
                    dob: this.dateofBirth, mobile: this.contactPersonCountryCode + ' ' + this.contactPersonMobileNumber, referredBy: this.referredBy, referredByTitle: this.referredByTitle, authorizedSignatoryObject: authorizedSignatoryObject, attorneyTitle: this.attorneyTitle
                })
                    .then(result => {
                        this.serviceRequestId = result.Id;
                    })
                    .catch(error => {
                        this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                    });


                if (this.errorDetails.length == 0) {

                    createAgencyTeamRecord({
                        name: this.ownerName, serviceRequestId: this.serviceRequestId, country: this.ownerCountry,
                        partnerOwnerDetails: this.partnerOwnerDetails, shareHoldingPercentage: this.shareHoldingPercentage
                        , title: this.agencyTitle, email: this.contactPersonEmailID, dob: this.dateofBirth, firstName: this.contactPersonName,
                        middleName: this.contactMiddleName, lastName: this.contactLastName, mobileNumber: this.contactPersonCountryCode + ' ' + this.contactPersonMobileNumber, partnersOwners: this.partnersOwners, ownerTitle: this.ownerTitle
                    })
                        .then(result => {
                            var s = this.partnersOwners.pop();
                        })
                        .catch(error => {
                            this.errorDetails.push('createAgencyTeamRecord Error: ' + JSON.stringify(error));
                        });
                }

                if (this.errorDetails.length == 0) {
                    await attachDocuments({
                        serviceRequestId: this.serviceRequestId
                    })
                        .then(result => {
                            this.srMap = result;

                            console.log('this.srMap: ' + this.srMap);


                            for (let i = 0; i < this.srMap.length; i++) {

                                if (this.srMap[i].Name === 'Memorandum of Association/Power of Attorney' && this.memorandumofAssociationPowerofAttorney != null) {
                                    this.upload(this.memorandumofAssociationPowerofAttorney, this.srMap[i].Id);
                                    this.numberOfFiles++;

                                } else if (this.srMap[i].Name === 'Go AML Certificate' && this.goAMLCertificate != null) {
                                    this.upload(this.goAMLCertificate, this.srMap[i].Id);
                                    this.numberOfFiles++;

                                } else if (this.srMap[i].Name === 'Company Profile/Brochure/Catalogue' && this.companyProfileBrochureCatalogue != null) {
                                    this.upload(this.companyProfileBrochureCatalogue, this.srMap[i].Id);
                                    this.numberOfFiles++;

                                } else if (this.srMap[i].Name === 'VAT Registration Certificate' && this.vatRegistrationCertificate != null) {
                                    this.upload(this.vatRegistrationCertificate, this.srMap[i].Id);
                                    this.numberOfFiles++;

                                } else if (this.srMap[i].Name === 'Bank Copy' && this.signedBankCopy != null) {
                                    this.upload(this.signedBankCopy, this.srMap[i].Id);
                                    this.numberOfFiles++;

                                } else if (this.srMap[i].Name === 'Emirates ID / Passport copy' && this.emiratesIDPassportcopyofPartnerOwner != null) {
                                    this.upload(this.emiratesIDPassportcopyofPartnerOwner, this.srMap[i].Id);
                                    this.numberOfFiles++;

                                } else if (this.srMap[i].Name === 'Trade/Commercial License' && this.attachTradeLicence != null) {
                                    this.upload(this.attachTradeLicence, this.srMap[i].Id);
                                    this.numberOfFiles++;
                                }
                            }
                        })
                        .catch(error => {
                            this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                        });

                    if (!this.updateAction) {
                        this.otpSection = 'show';
                    } else {
                        console.log('serviceRequestStepObj: ' + JSON.stringify(this.serviceRequestStepObj));
                        await updateServiceRequestStep({ step: this.serviceRequestStepObj })
                            .then(result => {
                                this.readOnly = true;
                                console.log('updateServiceRequestStep: ' + JSON.stringify(result));
                            })
                            .catch(error => {
                                this.errorDetails.push('createAgencyTeamRecord Error: ' + JSON.stringify(error));
                            });
                    }
                }
            } else {

                this.errorDialog = true;
                this.errorDetails.push('Kindly note that your company is already registered with Aldar');


            }
        }
        else {
        }

        this.isLoaded = !this.isLoaded;

        if (this.errorDetails.length > 0) {
            this.errorDialog = true;
        }

    }

    async upload(fileData, recordId) {

        await Array.from(fileData).forEach(file => {
            if (file.old == null) {
                const { base64, filename } = file;
                if (base64 != null) {
                    uploadFile({ base64, filename, recordId }).then(result => {
                        file = null;
                        let title = filename + ' uploaded successfully!!';
                        this.numberOfFiles--;
                        this.progressBarValue = 100 / (this.numberOfFiles + 1);

                        if (this.numberOfFiles == 0) {
                            this.progressBarCompleted = true;
                        }
                    }).catch(error => {
                        this.errorDetails.push('upload Error: ' + JSON.stringify(error));
                        console.log(JSON.stringify(error));
                    });
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



    async openfileUpload(event) {


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

            console.log(file.size);

            var id = event.target.dataset.id;

            if (file.size > 2000000) {
                const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id=' + id + ']')]
                    .reduce((validSoFar, inputField) => {

                        inputField.setCustomValidity('File Size Is more than 2MB');

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

                        this.goAMLCertificate.push({
                            'filename': result?.length > 0 ? file.name + `(${this.goAMLCertificate.length})` : file.name,
                            'base64': base64,
                        });
                    }
                    reader.readAsDataURL(file);

                } else if (event.target.dataset.id === 'CompanyProfileBrochureCatalogue') {
                    let result = this.companyProfileBrochureCatalogue.filter(obj => {

                        return obj.filename === file.name;
                    });
                    reader.onload = () => {
                        this.companyProfileBrochureCatalogue.push({
                            'filename': result?.length > 0 ? file.name + `(${this.companyProfileBrochureCatalogue.length})` : file.name,
                            'base64': base64,
                        });
                    }
                    reader.readAsDataURL(file);
                } else if (event.target.dataset.id === 'AttachTradeLicence') {
                    let result = this.attachTradeLicence.filter(obj => {

                        return obj.filename === file.name;
                    });
                    reader.onload = () => {
                        this.attachTradeLicence.push({
                            'filename': result?.length > 0 ? file.name + `(${this.attachTradeLicence.length})` : file.name,
                            'base64': base64,
                        });
                    }
                    reader.readAsDataURL(file);

                } else if (event.target.dataset.id === 'EmiratesIDPassportcopyofPOA') {
                    let result = this.emiratesIDPassportcopyofPOA.filter(obj => {

                        return obj.filename === file.name;
                    });

                    reader.onload = () => {
                        this.emiratesIDPassportcopyofPOA.push({
                            'filename': result?.length > 0 ? file.name + `(${this.emiratesIDPassportcopyofPOA.length})` : file.name,
                            'base64': base64,
                        });
                    }
                    reader.readAsDataURL(file);

                } else if (event.target.dataset.id === 'MemorandumofAssociationPowerofAttorney') {
                    let result = this.memorandumofAssociationPowerofAttorney.filter(obj => {
                        return obj.filename === file.name;
                    });
                    reader.onload = () => {
                        this.memorandumofAssociationPowerofAttorney.push({
                            'filename': result?.length > 0 ? file.name + `(${this.memorandumofAssociationPowerofAttorney.length})` : file.name,
                            'base64': base64,
                        });
                    }
                    reader.readAsDataURL(file);

                } else if (event.target.dataset.id === 'EmiratesIDPassportcopyofPartnerOwner') {

                    let result = this.emiratesIDPassportcopyofPartnerOwner.filter(obj => {
                        return obj.filename === file.name;
                    });


                    let id = event.target.name == null ? '' : event.target.name;
                    console.log(JSON.stringify(id));

                    reader.onload = () => {
                        this.emiratesIDPassportcopyofPartnerOwner.push({
                            'filename': result?.length > 0 ? id + file.name + `(${this.emiratesIDPassportcopyofPartnerOwner.length})` : id + file.name,
                            'base64': base64,
                            'Id': id,
                        });


                    }
                    reader.readAsDataURL(file);

                    var value = event.target.value;
                    let index = this.partnersOwners.findIndex(a => a.Id === id);

                    if (index != null && this.partnersOwners[index] != null && this.partnersOwners[index].filename != null) {
                        this.partnersOwners[index].filename = file.name;
                    } else {
                        this.firstPartnersOwnerFiles.push(file.name);
                    }
                    console.log(JSON.stringify(this.partnersOwners));



                } else if (event.target.dataset.id === 'SignedBankCopy') {

                    let result = this.signedBankCopy.filter(obj => {
                        return obj.filename === file.name;
                    });

                    reader.onload = () => {
                        this.signedBankCopy.push({
                            'filename': result?.length > 0 ? file.name + `(${this.signedBankCopy.length})` : file.name,
                            'base64': base64,
                        });
                    }
                    reader.readAsDataURL(file);

                } else if (event.target.dataset.id === 'VATRegistrationCertificate') {
                    let result = this.vatRegistrationCertificate.filter(obj => {
                        return obj.filename === file.name;
                    });
                    reader.onload = () => {
                        this.vatRegistrationCertificate.push({
                            'filename': result?.length > 0 ? file.name + `(${this.vatRegistrationCertificate.length})` : file.name,
                            'base64': base64,
                        });
                    }
                    reader.readAsDataURL(file);
                } else {
                }
            }
        });

        this.checkCompletedSections();
    }

    resendOTP(event) {

        this.isLoaded = !this.isLoaded;

        updateAgencyTeam({ serviceRequestId: this.serviceRequestId })
            .then(result => {
            })
            .catch(error => {
            });

        this.isLoaded = !this.isLoaded;
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
                this.template.querySelectorAll(`[data-notactiveindex="${index}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-currentstageindex="${index}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-completedstageindex="${index}"]`)[0].style.display = 'inline-block';
            }

            if (selectedIndex < index) {
                this.template.querySelectorAll(`[data-leftsideindex="${index}"]`)[0].classList.remove("slds-is-completed");
                this.template.querySelectorAll(`[data-leftsideindex="${index}"]`)[0].classList.remove("slds-is-active");
                this.template.querySelectorAll(`[data-notactiveindex="${index}"]`)[0].style.display = 'inline-block';
                this.template.querySelectorAll(`[data-currentstageindex="${index}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-completedstageindex="${index}"]`)[0].style.display = 'none';

            }

            if (index == selectedIndex) {
                this.template.querySelectorAll(`[data-currentstageindex="${selectedIndex}"]`)[0].style.display = 'inline-block';
                this.template.querySelectorAll(`[data-notactiveindex="${selectedIndex}"]`)[0].style.display = 'none';
                this.template.querySelectorAll(`[data-completedstageindex="${selectedIndex}"]`)[0].style.display = 'none';
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
                console.log(JSON.stringify(this.firstPartnersOwnerFiles));
                console.log(JSON.stringify(this.partnersOwners));

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
}