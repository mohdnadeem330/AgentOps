import { LightningElement, api, wire, track } from 'lwc';
// import getCaseRecord from '@salesforce/apex/CaseService.getCaseRecord';
import getRelatedFilesByCaseId from '@salesforce/apex/ManageCasesController.getRelatedFilesByCaseId';
// import getCaseCommentsHistory from '@salesforce/apex/CaseCommentsService.getCaseCommentsHistory';
// import createnewComments from '@salesforce/apex/CaseCommentsService.createnewComments';
// import getAllContentDocumentLinkRecord from '@salesforce/apex/ContentDocumentLinkService.getAllContentDocumentLinkRecord';
import getFiles from '@salesforce/apex/ManageCasesController.returnFiles';
import createFiles from '@salesforce/apex/ManageCasesController.createFiles';
import getURLPath from '@salesforce/apex/ManageCasesController.getURLPath';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
// import timeZone from '@salesforce/i18n/timeZone'
// import locale from '@salesforce/i18n/locale';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getAttachmentURL from '@salesforce/apex/CaseCommentsService.getAttachmentURL';
import getUserProfileDetails from '@salesforce/apex/UserProfileController.getUserProfileDetails';
import getSRDocId from '@salesforce/apex/UserProfileController.getSRDocId';
import updateProposedExpiryDate from '@salesforce/apex/UserProfileController.updateProposedExpiryDate';
// import updateMobilePhone from '@salesforce/apex/UserProfileController.updateMobilePhone';
import uploadUserPicture from '@salesforce/apex/UserProfileController.uploadUserPicture';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import Contact_OBJECT from '@salesforce/schema/Contact';
import MobileCountryCode_FIELD from '@salesforce/schema/Contact.MobileCountryCode__c';
import blacklistedDomains from '@salesforce/label/c.BlacklistedDomains';
import getValidateEmail from '@salesforce/apex/EmailValidation.getValidateEmailWithAura';
import sendForEmailOTP from '@salesforce/apex/UserProfileController.sendEmailOTP';
import fetchOTPExpiryTime from '@salesforce/apex/CommunityAuthController.getBrokerOTPTimer';
import verifyEmailOTP from '@salesforce/apex/UserProfileController.verifyEmailOTP';
import getValidatePhoneNoWithAura from '@salesforce/apex/PhoneNoValidation.getValidatePhoneNoWithAura';
import hasPendingInvoiceBundle from '@salesforce/apex/UserProfileController.hasPendingInvoiceBundle';
import VATLetterTemplate from '@salesforce/resourceUrl/VATLetterTemplate';
import updateVATDetails from '@salesforce/apex/UserProfileController.updateVATDetails'
const DELAY = 500;

export default class UserProfile extends NavigationMixin(LightningElement) {

   isModalOpen = false;
   isNOCModalOpen = false;
   uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
   deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";
   bigEditIcon = resourcesPath + "/ALDARResources/svg/BigEditIcon.svg";
   testUserPhoto = resourcesPath + "/ALDARResources/png/Avatar.png";
   profilePhoto; 
   isPasswordResetSuccess = false;
   @track profileFlag = false;
   @track expiredTLFlag = false;
   @track accountApprovalStatus = false;
   attachedAMLFiles = [];
   attachedTLFiles = [];


   @track showTLUplode = false;
   @track showAMLUplode = false;
   @track showVATUpload = false;
   @track fileNames = '';
   @track uploadedTLFiles = [];
   @track uploadedAMLFiles = [];
   @track uploadedVATFiles = [];
   @track fileTLNamesList = [];
   @track fileAMLNamesList = [];
   @track fileVATLetterList = [];
   @track commentsData = [];
   @track commentFromField;
   @track isFileUploaded = true;
   @track urlPathPrefix;

   @track disabledSubmit = false;
   @track downloadURL;
   
   @track openPreview = false;
   @track showSpinner=false;
   hideBackNav=false;
   filesList = [];
   filesListTL = [];
   filesListVAT = [];
   filesListSL = [];
   filesListWL = [];
   filesListNOC = [];
   uploadDocSLRecordId;
   uploadDocWLRecordId;
   showSuspensionLetter = false;
   showWarningLetter = false;
   uploadDocTLRecordId;
   uploadDocAMLRecordId;
   uploadDocVATRecordId;
   accountId;

   showNOCLetter = false;
   uploadDocNOCRecordId;
   // Added By Moh Sarfaraj for BPE-130
   @track showBankDetailUpdate = false;
   @track showBankDetailModal = false; 
   @track userRecord;

   // Added by Tharun 
   mobileNumberUpdateModal = false;
   emailUpdateModal        = false;
   showEnterOTPForm        = false;
   showVerifyOTPButton     = false;
   showUpdateButton        = true;
   errorCheckWrongOTP      = false;
   showResendOTPButton     = false;
   showCountDownTimer      = false;
   errorMessageWrongOTP;
   existingEmailAddress;
   existingMobileNumber;
   isProposedEmailAddressExist;
   isProposedMobNumberExist;
   agencyCountry;
   mobileCountryCodePicklist;
   countDownTimerInSeconds;
   counter = 1;
   refreshCounter;
   countryCode;
   mobileNumber;
   showNOCSection = false;
   vatLetterTemplate = VATLetterTemplate;

   hasPendingInvoice = false;
   @wire(hasPendingInvoiceBundle,{'accountId' : '$accountId'})
   getPendingInvoiceBundle({error,data}){
      if(data){
         this.hasPendingInvoice = data;
      }else if(error){
         this.hasPendingInvoice = false;
      }
   }
   
   get vatOptions() {
      return [
          { label: 'VAT Registration Certificate', value: 'VAT Registration Certificate' },
          { label: 'VAT Undertaking Certificate', value: 'VAT Undertaking Certificate' },
      ];
  }
   @wire(getObjectInfo, { objectApiName: Contact_OBJECT })
   contactMetadata;

   @wire(getPicklistValues,{
         recordTypeId: '$contactMetadata.data.defaultRecordTypeId',
         fieldApiName: MobileCountryCode_FIELD
   })
   mobCountryCode({error, data}) {
      if (error) {
      } else if (data) {
          this.mobileCountryCodePicklist = data.values;
      }
  }

  @wire(fetchOTPExpiryTime)
    wiredData({ error, data }) {
        if (data) {
            let countDownTimerInMin          = data.Timer__c;
            this.countDownTimerInSeconds     = countDownTimerInMin * 60;
        } else if (error) {
            console.error('Error:', error);
        }
    }
   
   agencyInformation = [
      {
         id: 1,
         column1Label: "Agency Name:",
         column1Value: "",
         column2Label: "Trade License Number:",
         column2Value: "",
         column3Label: "Trade License Expiry Date:",
         column3Value: "",
      },
      {
         id: 2,
         column1Label: "Email:",
         column1Value: "",
         column2Label: "Phone:",
         column2Value: "",
         column3Label: "Address:",
         column3Value: "",
      },
      {
         id: 3,
         column1Label: "City:",
         column1Value: "",
         column2Label: "Country:",
         column2Value: "",
         column3Label: "P.O. Box:",
         column3Value: "",
      }, 
      {
         id: 4,
         column1Label: "Region:",
         column1Value: "",
      }
   ];

   adminInformation = [
 
   {
      id: 1,
      editableFlag: true,
      column1Label: "Contact First Name:",
      column1Value: "",
      column2Label: "Contact Last Name:",
      column2Value: "",
      column3Label: "Email:",
      column3Value: "",
   },
   {
      id: 2,
      column1Label: "Country Code:",
      column1Value: "",
      column2Label: "Mobile:",
      column2Value: "",
   }
   ];

   paymentDetails = [{
      id: 1,
      column1Label: "Account Name:",
      column1Value: "",
      column2Label: "Account Number:",
      column2Value: "",
      column3Label: "IBAN Number:",
      column3Value: "",
   },
   {
      id: 2,
      column1Label: "Currency:",
      column1Value: "",
      column2Label: "Swift Code:",
      column2Value: "",
      column3Label: "Bank Name:",
      column3Value: "",
   },
   {
      id: 3,
      column1Label: "Branch:",
      column1Value: "",
      column2Label: "Country",
      column2Value: "",
   }
   ];

   todaysDate; vatStartDateValue; vatEndDateValue;
   connectedCallback() {
      var today = new Date();
      this.todaysDate = today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + today.getDate();
      this.resetAll();
   }

   showToast(title, message, varaint, mode) {
      const event = new ShowToastEvent({
         title: title,
         message: message,
         variant: varaint,
         mode: mode
      });
      this.dispatchEvent(event);
   }

   get acceptedFormats() {
      return ['.pdf', '.png', '.jpg', '.jpeg', '.doc'];
   }

   async handleUploadAMLFinished(event) {
      // Get the list of uploaded files
      this.uploadedAMLFiles = event.detail.files;
      let uploadedFileNames = '';
      for (let i = 0; i < this.uploadedAMLFiles.length; i++) {
         uploadedFileNames += this.uploadedAMLFiles[i].name + ', ';
         this.attachedAMLFiles.push(this.uploadedAMLFiles[i].documentId);
      }

      this.dispatchEvent(
         new ShowToastEvent({
            title: 'Success',
            message: this.uploadedAMLFiles.length + ' Files uploaded Successfully: ' + uploadedFileNames,
            variant: 'success',
         }),
      );
   }

   async handleUploadTLFinished(event) {
      // Get the list of uploaded files
      this.uploadedTLFiles = event.detail.files;
      let uploadedFileNames = '';
      for (let i = 0; i < this.uploadedTLFiles.length; i++) {
         uploadedFileNames += this.uploadedTLFiles[i].name + ', ';
         this.attachedTLFiles.push(this.uploadedTLFiles[i].documentId);
      }

      this.dispatchEvent(
         new ShowToastEvent({
            title: 'Success',
            message: this.uploadedTLFiles.length + ' Files uploaded Successfully: ' + uploadedFileNames,
            variant: 'success',
         }),
      );
   }
   UAEVATRegNumber;
   async resetAll() {
      this.showSpinner  = true;
      const newData     = await getUserProfileDetails();
      // Added By Moh Sarfaraj for BPE-130
      this.userRecord = newData;
      if(newData.Account.BillingState =='Abu Dhabi' || newData.Account.BillingState =='Dubai'){
         this.showNOCSection = true;
      }
      if(this.userRecord.Account.ProposedBankDetailStatus__c == 'Pending'){
         this.bankDetailsBtnText = 'Change Request is Pending';
      }else if(this.userRecord.Account.ProposedBankDetailStatus__c == 'Rejected'){
         this.rejectedLastRequest = true;
      }
      if (newData.Account.UAEVATRegisterNumber__c != null) {
         let vatNumber = newData.Account.UAEVATRegisterNumber__c;
         const regex = /^[a-zA-Z0-9]{15}$/;
     
         if (regex.test(vatNumber)) {
             this.UAEVATRegNumber = vatNumber;
         } else {
            console.error('Invalid UAE VAT Registration Number. It must be exactly 15 alphanumeric characters.');
            this.UAEVATRegNumber = '';
         }
      }
      this.vatStartDateValue = newData?.Account?.VATRegistrationStartDate__c;
      this.vatEndDateValue = newData?.Account?.VATRegistrationEndDate__c;


      await getURLPath().then(data => {
            this.urlPathPrefix = data;
            this.downloadURL = 'https://' + location.host + '/' + this.urlPathPrefix + '/';
         }).catch(error => {
         })

      //Trade License
      getSRDocId({accountId: newData.Account.Id, documentType: 'Trade_Commercial_License'}).then(result => {
         this.uploadDocTLRecordId = result.Id;
         this.displayTLlistOfFiles();
      }).catch(error => {
         // console.error('error>>>', error);
      })

      //GO AML
      getSRDocId({accountId: newData.Account.Id, documentType: 'Go_AML_Certificate'}).then(result => {
         this.uploadDocAMLRecordId = result.Id;
         this.displaylistOfFiles();
      }).catch(error => {
      })
      //VAT
      getSRDocId({accountId: newData.Account.Id, documentType: 'VAT_Registration_Certificate'}).then(result => {
         this.uploadDocVATRecordId = result.Id;
         this.displayVATlistOfFiles();
      }).catch(error => {
      })
      //Suspension Letter
      getSRDocId({accountId: newData.Account.Id, documentType: 'Suspension_Letter'}).then(result => {
         this.uploadDocSLRecordId = result.Id;
         this.displaySLFile();
      }).catch(error => {
      })

      //Warning Letter
      getSRDocId({accountId: newData.Account.Id, documentType: 'Warning_Letter'}).then(result => {
         this.uploadDocWLRecordId = result.Id;
         this.displayWLFile();
      }).catch(error => {
      })

      //NOC Broker Letter
      getSRDocId({accountId: newData.Account.Id, documentType: 'Signed_NOC_Broker_Letter'}).then(result => {
         this.uploadDocNOCRecordId = result.Id;
         this.displayNOCFile();
      }).catch(error => {
      })

      this.accountId                   = newData.Account.Id;
      this.contactId                   = newData.Contact.Id;
      this.profilePhoto                = newData.FullPhotoUrl;
      this.existingEmailAddress        = newData.Email;
      this.existingMobileNumber        = newData.Contact.MobileCountryCode__c +' '+newData.Contact.MobilePhone__c;
      this.isProposedEmailAddressExist = newData.Contact.ProposedEmail__c === undefined || newData.Contact.ProposedEmail__c === null || newData.Contact.ProposedEmail__c == '' ? false : true;
      this.isProposedMobNumberExist    = newData.Contact.ProposedMobilePhone__c === undefined || newData.Contact.ProposedMobilePhone__c === null || newData.Contact.ProposedMobilePhone__c == '' ? false : true;
      this.agencyCountry               = newData.Account.BillingCountry;
      this.UAEVATRegNumber             = newData.Account.UAEVATRegisterNumber__c;
      
      if(this.UAEVATRegNumber != null){
         this.vatValue = 'VAT Registration Certificate';
         this.VATTitle = 'VAT Certificate';
         this.showVatCertificate = true;
         this.showVatUndertakingCertificate = false;
         this.showVATSection = true;
      }

      this.accountApprovalStatus = (newData.Account.ApprovalStatus__c == 'Submitted');

      if ((newData.Profile.Name == 'Agency Admin') || (newData.Profile.Name == 'Agency Admin Login')) {
         this.profileFlag = true;
         this.expiredTLFlag = false;
      }else if ((newData.Profile.Name == 'Agency Admin with Limited Access') || (newData.Profile.Name == 'Agency Admin with Limited Access Login')) {
         this.hideBackNav=true;
         this.profileFlag = true;
         this.expiredTLFlag = true;
      } else {
         this.profileFlag = false;
         this.expiredTLFlag = false;
      }
      // Added By Moh Sarfaraj for BPE-130
      this.showBankDetailUpdate = newData.Contact.AgentStatus__c === 'Active' ? newData.Contact.PrimaryAgencyAdmin__c : false;

      this.agencyInformation = [
         {
            id: 1,
            column1Label: "Agency Name:",
            column1Value: newData.Account.Name,
            column2Label: "Trade License Number:",
            column2Value: newData.Account.RegistrationNumber__c,
            column3Label: "Trade License Expiry Date:",
            column3Value: newData.Account.RegistrationExpiryDate__c,
         },
         {
            id: 2,
            column1Label: "Email:",
            column1Value: newData.Account.Email__c,
            column2Label: "Phone:",
            column2Value: newData.Account.Phone,
            column3Label: "Address",
            column3Value: newData.Account.BillingCity + ', ' + newData.Account.BillingCountry,
         },
         {
            id: 3,
            column1Label: "City:",
            column1Value: newData.Account.BillingCity,
            column2Label: "Country:",
            column2Value: newData.Account.BillingCountry,
            column3Label: "P.O. Box:",
            column3Value: newData.Account.BillingPostalCode,
         }, 
         {
            id: 4,
            // column1Label: "Trade License Issue Location:  ",
            // column1Value: newData.Account.PlaceOfRegistration__c,
            column1Label: "Region:",
            column1Value: newData.Account.AgencyRegion__c,
         }
      ];
      
      this.adminInformation = [
      
      {
         id: 1,
         column1Label: "Contact First Name:",
         column1Value: newData.Contact.FirstName,
         column2Label: "Contact Last Name:",
         column2Value: newData.Contact.LastName,
         // This email is taken from User object
         column3Label: "Email:",
         column3Value: newData.Email
      },
      {
         id: 2,
         // This mobile number is taken from Contact
         column1Label: "Country Code:",
         column1Value: newData.Contact.MobileCountryCode__c,
         column2Label: "Mobile:",
         column2Value: newData.Contact.MobilePhone__c,
      }
      ];

      this.paymentDetails = [{
         id: 1,
         column1Label: "Account Name:",
         column1Value: newData.Account.Name,
         column2Label: "Account Number:",
         column2Value: newData.Account.BankAccountNumber__c,
         column3Label: "IBAN Number:",
         column3Value: newData.Account.IBANNumber__c,
      },
      {
         id: 2,
         column1Label: "Currency:",
         column1Value: newData.Account.CurrencyIsoCode,
         column2Label: "Swift Code:",
         column2Value: newData.Account.SwiftCode__c,
         column3Label: "Bank Name:",
         column3Value: newData.Account.BankName__c,
      },
      {
         id: 3,
         column1Label: "Branch:",
         column1Value: newData.Account.BranchAddress__c,
         column2Label: "Country",
         column2Value: newData.Account.BankCountry__c,
      }
      ];
      this.showSpinner=false;

   }

   // to open modal set isModalOpen tarck value as true
   openModal() {
      this.isModalOpen = true;
   }

   //to close modal set isModalOpen tarck value as false
   //this event has been fired from the modal component it self
   closeModal(event) {
      this.isModalOpen = event.detail.isOpen;
   }

   checkSubmitActionStatus(event) {
      this.isPasswordResetSuccess = event.detail.status;
   }

   onFileUploadVAT(event) {
      let files = event.target.files;
      if (files.length > 0) {
         let filesName = '';
         for (let i = 0; i < files.length; i++) {
            let file = files[i];
            filesName = filesName + file.name + ',';
            let freader = new FileReader();
            freader.onload = f => {
               let base64 = 'base64,';
               let content = freader.result.indexOf(base64) + base64.length;
               let fileContents = freader.result.substring(content);
               this.uploadedVATFiles.push({
                  Title: file.name,
                  VersionData: fileContents
               });
            };
            freader.readAsDataURL(file);
         }
         this.fileNames = filesName.slice(0, -1);
         this.fileVATLetterList.push(this.fileNames); 
      }
   }

   onFileUploadAML(event) {
      let files = event.target.files;

      if (files.length > 0) {
         let filesName = '';

         for (let i = 0; i < files.length; i++) {
            let file = files[i];

            filesName = filesName + file.name + ',';

            let freader = new FileReader();
            freader.onload = f => {
               let base64 = 'base64,';
               let content = freader.result.indexOf(base64) + base64.length;
               let fileContents = freader.result.substring(content);
               this.uploadedAMLFiles.push({
                  Title: file.name,
                  VersionData: fileContents
               });
            };
            freader.readAsDataURL(file);
         }

         this.fileNames = filesName.slice(0, -1);

         this.fileAMLNamesList.push(this.fileNames);

         // this.showUplod=false;    
      }
   }

   onFileUploadTL(event) {
      let files = event.target.files;

      if (files.length > 0) {
         let filesName = '';

         for (let i = 0; i < files.length; i++) {
            let file = files[i];

            filesName = filesName + file.name + ',';

            let freader = new FileReader();
            freader.onload = f => {
               let base64 = 'base64,';
               let content = freader.result.indexOf(base64) + base64.length;
               let fileContents = freader.result.substring(content);
               this.uploadedTLFiles.push({
                  Title: file.name,
                  VersionData: fileContents
               });
            };
            freader.readAsDataURL(file);
         }

         this.fileNames = filesName.slice(0, -1);

         this.fileTLNamesList.push(this.fileNames);

         // this.showUplod=false;    
      }
   }

   get acceptedFormats() {
      return ['.pdf', '.png', '.jpg', '.gif', '.csv', '.jpeg', '.docx', '.doc', '.xsl', '.xml', '.ppt'];
   }

   /* Commented By Tharun for BPE-166 START
   updateMobilePhone(){
      let agent = this.template.querySelector('[data-id="Mobile:"]');
      let agentMobileNumber = agent.value;
      updateMobilePhone({
         contactId: this.contactId,
         mobileNumber:agentMobileNumber
      }).then(data => {
            this.showToast('Success', 'Mobile updated Successfully', 'success', 'dismissable');
         })
         .catch(error => {
            // console.log('error' + error);
         });
   } Commented By Tharun for BPE-166 END
   */

   removeTLFile(event) {
      var index = event.currentTarget.dataset.id;
      this.uploadedTLFiles.splice(index, 1);
      this.fileTLNamesList.splice(index, 1);
   }

   removeAMLFile(event) {
      var index = event.currentTarget.dataset.id;
      this.uploadedAMLFiles.splice(index, 1);
      this.fileAMLNamesList.splice(index, 1);
   }

   removeVATFile(event) {
      var index = event.currentTarget.dataset.id;
      this.uploadedVATFiles.splice(index, 1);
      this.fileVATLetterList.splice(index, 1);
   }

   previewHandlerVAT(event) {
      // console.log('previewHandler');
      var contentDocumentId = event.target.dataset.latestid;
      // console.log('contentDocumentId>>>' + contentDocumentId);

      //throw new Error("test");
      getAttachmentURL({
         csId: this.uploadDocVATRecordId,
         cvId: contentDocumentId
      }).then(result => {
         // console.log('result>>>' + JSON.stringify(result));

         this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
               url: result.DistributionPublicUrl
            }
         }, false);
      }).catch(error => {
         // console.error('error>>>', error);
      })
   }

   previewHandlerTL(event) {
      // console.log('previewHandler');
      var contentDocumentId = event.target.dataset.latestid;
      // console.log('contentDocumentId>>>' + contentDocumentId);

      //throw new Error("test");
      getAttachmentURL({
         csId: this.uploadDocTLRecordId,
         cvId: contentDocumentId
      }).then(result => {
         // console.log('result>>>' + JSON.stringify(result));

         this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
               url: result.DistributionPublicUrl
            }
         }, false);
      }).catch(error => {
         // console.error('error>>>', error);
      })
   }

   previewHandler(event) {
      // console.log('previewHandler');
      var contentDocumentId = event.target.dataset.latestid;
      // console.log('contentDocumentId>>>' + contentDocumentId);

      //throw new Error("test");
      getAttachmentURL({
         csId: this.uploadDocAMLRecordId,
         cvId: contentDocumentId
      }).then(result => {
         // console.log('result>>>' + JSON.stringify(result));

         this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
               url: result.DistributionPublicUrl
            }
         }, false);
      }).catch(error => {
         // console.error('error>>>', error);
      })

   }

   // Added by Tharun on July 6
   previewHandlerALL(event) {
      var contentDocumentId = event.target.dataset.latestid;
      var relatedEntityId = event.target.dataset.relatedid;
      getAttachmentURL({
         csId: relatedEntityId,
         cvId: contentDocumentId
      }).then(result => {
         this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
               url: result.DistributionPublicUrl
            }
         }, false);
      }).catch(error => {
      })
   }

   // GO AML File
   async displaylistOfFiles(event) {
      //get list of files
      // console.log('displaylistOfFiles');

      await getRelatedFilesByCaseId({ caseId: this.uploadDocAMLRecordId }).then(result => {
         let resultdata = JSON.parse(JSON.stringify(result));
         this.filesList = [];
         //for (let item of resultdata) {
            let tMap = {
               "label": resultdata[0].Title,
               "value": resultdata[0].ContentDocumentId,
               "type": resultdata[0].ContentDocument.FileType,
               "latestId": resultdata[0].ContentDocument.LatestPublishedVersionId,
               "linkEntityId": this.uploadDocAMLRecordId,
               "url": this.downloadURL + 'sfc/servlet.shepherd/document/download/' + resultdata[0].ContentDocumentId
            };
            this.filesList.push(tMap);
         //}
         // console.log('filesList>>>', JSON.stringify(this.filesList));
      }).catch(error => {
         // console.log(error);
      })

   }

   async displayVATlistOfFiles(event) {
      await getRelatedFilesByCaseId({ caseId: this.uploadDocVATRecordId }).then(result => {
         let resultdata = JSON.parse(JSON.stringify(result));
         this.filesListVAT = [];
            let tMap = {
               "label": resultdata[0].Title,
               "value": resultdata[0].ContentDocumentId,
               "type": resultdata[0].ContentDocument.FileType,
               "latestId": resultdata[0].ContentDocument.LatestPublishedVersionId,
               "linkEntityId": this.uploadDocVATRecordId,
               "url": this.downloadURL + 'sfc/servlet.shepherd/document/download/' + resultdata[0].ContentDocumentId
            };
            this.filesListVAT.push(tMap);
      }).catch(error => {
      })
   }

   // Trade License File
   async displayTLlistOfFiles(event) {
      await getRelatedFilesByCaseId({ caseId: this.uploadDocTLRecordId }).then(result => {
         let resultdata = JSON.parse(JSON.stringify(result));
         this.filesListTL = [];
            let tMap = {
               "label": resultdata[0].Title,
               "value": resultdata[0].ContentDocumentId,
               "type": resultdata[0].ContentDocument.FileType,
               "latestId": resultdata[0].ContentDocument.LatestPublishedVersionId,
               "linkEntityId": this.uploadDocTLRecordId,
               "url": this.downloadURL + 'sfc/servlet.shepherd/document/download/' + resultdata[0].ContentDocumentId
            };
            this.filesListTL.push(tMap);
      }).catch(error => {
      })
   }

   // Added by Tharun on July 6
   // Suspension Letter
   async displaySLFile(event) {
      await getRelatedFilesByCaseId({ caseId: this.uploadDocSLRecordId }).then(result => {
         if(result && result != ''){
         let resultdata = JSON.parse(JSON.stringify(result));
         this.filesListSL = [];
         this.showSuspensionLetter = true;
            let tMap = {
               "label": resultdata[0].Title,
               "value": resultdata[0].ContentDocumentId,
               "type": resultdata[0].ContentDocument.FileType,
               "latestId": resultdata[0].ContentDocument.LatestPublishedVersionId,
               "linkEntityId":this.uploadDocSLRecordId,
               "url": this.downloadURL + 'sfc/servlet.shepherd/document/download/' + resultdata[0].ContentDocumentId
            };
            this.filesListSL.push(tMap);
         }
      })
      .catch(error => {
      })
   }

   // Added by Tharun on July 6
   // Warning Letter
   async displayWLFile(event) {
      await getRelatedFilesByCaseId({ caseId: this.uploadDocWLRecordId })
      .then(result => {
         if(result && result != ''){
         let resultdata = JSON.parse(JSON.stringify(result));
         this.showWarningLetter = true;
         this.filesListWL = [];
            let tMap = {
               "label": resultdata[0].Title,
               "value": resultdata[0].ContentDocumentId,
               "type": resultdata[0].ContentDocument.FileType,
               "latestId": resultdata[0].ContentDocument.LatestPublishedVersionId,
               "linkEntityId":this.uploadDocWLRecordId,
               "url": this.downloadURL + 'sfc/servlet.shepherd/document/download/' + resultdata[0].ContentDocumentId
            };
            this.filesListWL.push(tMap);
         }
      })
      .catch(error => {
      });
   }

   // Added by Tharun on Dec 22
   // Warning Letter
   async displayNOCFile(event) {
      await getRelatedFilesByCaseId({ caseId: this.uploadDocNOCRecordId })
      .then(result => {
         if(result && result != ''){
         let resultdata = JSON.parse(JSON.stringify(result));
         this.showNOCLetter = true;
         this.filesListNOC = [];
            let tMap = {
               "label": resultdata[0].Title,
               "value": resultdata[0].ContentDocumentId,
               "type": resultdata[0].ContentDocument.FileType,
               "latestId": resultdata[0].ContentDocument.LatestPublishedVersionId,
               "linkEntityId":this.uploadDocNOCRecordId,
               "url": this.downloadURL + 'sfc/servlet.shepherd/document/download/' + resultdata[0].ContentDocumentId
            };
            this.filesListNOC.push(tMap);
         }
      })
      .catch(error => {
      });
   }

   //calling create files and save cases
   UploadTLFile() {
      this.showSpinner=true;
      // console.log('inside uplod');

      let proposedExpiryDate = this.template.querySelector('[data-id="proposedExpiryDate"]');
      let proposedExpiryDateValue = proposedExpiryDate.value;

      if (!proposedExpiryDateValue || proposedExpiryDateValue=='' ||  this.uploadedTLFiles.length === 0) {
         this.showToast('Error', 'Please add Trade License and proposed expiry date', 'error', 'dismissable');
         this.showSpinner=false;
      }else {
         this.showTLUplode = true;
         createFiles({ filesToInsert: this.uploadedTLFiles, caseId: this.uploadDocTLRecordId })
            .then(data => {

               this.isFileUploaded = true;
               this.showToast('Success', 'File/s Uploaded Successfully', 'success', 'dismissable');

               this.isFileUploaded = false;

               // this.getFilesData(data);
               this.fileTLNamesList = [];
               this.showSpinner=false;
            })
            .catch(error => {
               // console.log('error' + error);
               this.showSpinner=false;
            });
         
         // this.UploadAMLFile();
         updateProposedExpiryDate({accountId : this.accountId, 
                                  proposedExpiryDate : proposedExpiryDateValue});

         this.accountApprovalStatus = true;
      }
   }

   UploadVATFile(){
      this.showSpinner=true;
      
      let proposedUAEVATRegistrationNumber = '';
      let proposedUAEVATRegistrationNumberValue = '';

      if(this.vatValue == 'VAT Registration Certificate'){

         const isInputsCorrect =  [this.template.querySelector('[data-id="proposedUAEVATRegistrationNumber"]'),
                                   this.template.querySelector('[data-id="vatStartDate"]'),
                                   this.template.querySelector('[data-id="vatEndDate"]')]

         .reduce((validSoFar, inputField) => {

            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
            
         }, true);

         if(!isInputsCorrect){
            this.showSpinner = false;
            this.showToast('Error', 'Please Complete the VAT Required Fields', 'error', 'dismissable');
            return;
         }
         
         proposedUAEVATRegistrationNumber = this.template.querySelector('[data-id="proposedUAEVATRegistrationNumber"]');
         proposedUAEVATRegistrationNumberValue = proposedUAEVATRegistrationNumber.value;
      }
      if (this.uploadedVATFiles.length === 0) {
            if((this.vatValue == 'VAT Registration Certificate' && proposedUAEVATRegistrationNumberValue == '' )){
               this.showToast('Error', 'Please upload UAE VAT Transaction file and UAE VAT Transaction Number', 'error', 'dismissable');
              }else {
               this.showToast('Error', 'Please upload UAE VAT undertaking letter', 'error', 'dismissable');
            }
         this.showSpinner=false;
      }else {
         this.showVATUpload = true;
         createFiles({ filesToInsert: this.uploadedVATFiles, caseId: this.uploadDocVATRecordId })
         .then(data => {
            this.isFileUploaded = true;
            this.showToast('Success', 'File/s Uploaded Successfully', 'success', 'dismissable');
            this.isFileUploaded = false;
            this.fileVATLetterList = [];
            this.showSpinner=false;
         })
         .catch(error => {
            this.showSpinner=false;
         });

         updateVATDetails({ accountId : this.accountId,
                            vatValue : this.vatValue, 
                            proposedVATStartDate : this.vatStartDateValue,
                            proposedVATExpiryDate : this.vatEndDateValue,
                            proposedUAEVATRegistrationNumberValue : proposedUAEVATRegistrationNumberValue});

         this.accountApprovalStatus = true;
      }
   }

   UploadAMLFile() {
      this.showSpinner=true;
      this.showSpinner=false;
      if (!this.uploadedAMLFiles || this.uploadedAMLFiles.length === 0) {
         //this.showToast('Error', 'Please Uplod Files', 'error', 'dismissable');
         this.showSpinner=false;
      }
      else {
         this.showAMLUplode = true;
         createFiles({ filesToInsert: this.uploadedAMLFiles, caseId: this.uploadDocAMLRecordId })
            .then(data => {

               this.isFileUploaded = true;
               this.showToast('Success', 'File/s Uploaded Successfully', 'success', 'dismissable');

               this.isFileUploaded = false;

               //this.getFilesData(data);
               this.fileAMLNamesList = [];
               this.showSpinner=false;
            })
            .catch(error => {
               // console.log('error' + error);
               this.showSpinner=false;
            });

         let proposedExpiryDate = this.template.querySelector('[data-id="proposedExpiryDate"]');
         let proposedExpiryDateValue = proposedExpiryDate.value;
         

         // console.log('proposedExpiryDateValue >>>>> ' + proposedExpiryDateValue);
         // console.log('this.accountId >>>>> ' + this.accountId);
      }
   }

   getFilesData(lstIds) {
      getFiles({ lstFileIds: lstIds })
         .then(data => {
            data.forEach((record) => {
               record.FileName = '/' + record.Id;
            });

            this.data = data;
            this.displaylistOfFiles();

            this.dispatchEvent(new CustomEvent('callgetdata', { detail: ' ' }));
         })
         .catch(error => {
            // window.console.log('error ====> ' + error);
         })
   }



   backToDahboard(){
      // Added By Moh Sarfaraj for BPE-71 starts
      this.showSpinner = true;
      // window.open("../s", "_self");
      window.location.replace("../s")
      setTimeout(() => {
         this.showSpinner = false;
      }, 3000);
      // Added By Moh Sarfaraj for BPE-71 end
   }


   logout(){
    window.location.replace("../secur/logout.jsp");
   }

   profileImagePopup;
   profileData;
   showProfileImagePopup(){
      this.profileImagePopup=true;
   }

   hideProfileImagePopup(){
      this.profileImagePopup=false;
   }
   handlePreview(event){
      const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.profileData = {
                'filename': file.name,
                'base64': base64
            }
            console.log(this.profileData)
            let profilePicture = this.template.querySelector('.profileImagePopUp');
            profilePicture.src= URL.createObjectURL(file)
        }
        reader.readAsDataURL(file)
   }
   /*handleUploadFinished(event){
      console.log(event.detail.files);
      for (let i = 0; i < event.detail.files.length; i++) {
          console.log(JSON.stringify(event.detail.files[i]));
          this.uploadedFiles.push({'name':event.detail.files[i].name , 'documentId':event.detail.files[i].documentId } )
      }
      console.log(this.uploadedFiles);
  }*/
   get acceptedPhotoFormats() {
      return ['.jpg','.jpeg','.png'];
   }
   submitDetails(){
      this.showSpinner=true;
      uploadUserPicture({baseData : this.profileData.base64 })
               .then(data => {
                     console.log(data);
                     if(data.success==='true'){
                        //this.profilePhoto = data.data;
                        const evt = new ShowToastEvent({
                           title: 'Success',
                           message: data.msg,
                           variant: 'success',
                        });
                        this.dispatchEvent(evt);
                        setTimeout(() => {
                           window.location.href =  window.location.href;
                       }, 200);
                     }else{
                        const evt = new ShowToastEvent({
                           title: 'Error',
                           message: data.msg,
                           variant: 'error',
                        });
                        this.dispatchEvent(evt);
                    }
                    this.showSpinner=false;
               })
               .catch(error => {
                  const evt = new ShowToastEvent({
                     title: 'Error',
                     message: error,
                     variant: 'error',
                  });
                  this.dispatchEvent(evt);
                  this.showSpinner=false;
               });
   }

   // Added By Moh Sarfaraj for BPE-130 starts
   get bankDetailsPending(){
      return this.userRecord.Account.ProposedBankDetailStatus__c == 'Pending';
   }

   @track rejectedLastRequest = false;
   @track bankDetailsBtnText = 'Update Bank Details';
   openBankDetailModal(event){
      this.showBankDetailModal = true;
   }

   handleCloseEvent(event){
		let details = event.detail;
		this.showBankDetailModal = details.isOpen;
	}
   // Added By Moh Sarfaraj for BPE-130 end


   //Added by Tharun for BPE-165 START
   onclickUpdateMobilePhone(event)
   {
      this.mobileNumberUpdateModal = true;
   }

   onclickUpdateEmailAddress(event)
   {
      this.emailUpdateModal = true;
   }
   closeUpdateModal()
   {
      this.mobileNumberUpdateModal  = false;
      this.emailUpdateModal         = false;
   }

   //Tharun added below function
   async handleEmailBlur(event)
   {
       let emailAdd = event.target.value;
       let target = this.template.querySelector('[data-id="newEmail"]');
       target.setCustomValidity("");
       if(this.agencyCountry == 'United Arab Emirates'){
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
               target.setCustomValidity("Please Enter Valid Email");
           } else {
               target.setCustomValidity("");
           }
           target.reportValidity();
       }).catch(error =>{
           console.log(error);
       });        
   }

   //Below function is added by Tharun
   async handleSubmitForVerification(event)
   {
      console.log('click event-----'+event.target.name);
      let id = event.target.name;
      this.showSpinner = true;
      const isInputsCorrect = await [...this.template.querySelectorAll('[data-id=' + id + ']')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
      if (!isInputsCorrect) {
         this.showSpinner = false;
         this.showToast('Error', 'Enter Mandatory Fields', 'error');
      }else{
         sendForEmailOTP({
            conId             : this.contactId,
            conEmailAddress   : this.existingEmailAddress
         }).then(result => {
            if(result && result.includes('OTPSent')){
               this.showEnterOTPForm      = true;
               this.showSpinner           = false;
               this.showUpdateButton      = false;
               this.showVerifyOTPButton   = true;
               this.showCountDownTimer    = true;
               var interval=setInterval(function() {
                  if(this.refreshCounter==1){
                     this.counter                    = 1;
                     this.refreshCounter             = 0;
                     this.showCountDownTimer         = false;
                     this.showResendOTPButton        = true;
                     clearInterval(interval);
                  }
                  this.refreshCounter = this.countDownTimerInSeconds - (this.counter++);
               }.bind(this), 1000);
            }
         }).catch(error => {
            // TODO Error handling
            this.showSpinner = false;
         });
      }

   }

   //Below function is added by Tharun
   async handleVerifyEnteredEmailOTP(event){
      //verifyMobileUpdate|verifyEmailUpdate
      console.log('verify event-----'+event.target.name);
      this.showSpinner    = true;
      const isInputsCorrect = await [...this.template.querySelectorAll('[data-id="txtEnteredOTP"]')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
      if (!isInputsCorrect) {
         this.showSpinner = false;
         this.showToast('Error', 'Enter OTP and click on Verify', 'error');
      }else{
         let otpEntered      = this.template.querySelector('[data-id="txtEnteredOTP"]');
         let otpEnteredVal   = otpEntered.value.trim();
         let newEmail = ''; 
         let newCountryCode = ''; 
         let newMobNumber = '';

         if(event.target.name === 'verifyEmailUpdate'){
            newEmail          =  this.template.querySelector('[data-id="newEmail"]').value;
         }else if(event.target.name === 'verifyMobileUpdate'){
            newCountryCode    =  this.template.querySelector('[data-id="countryCode"]').value;
            newMobNumber      =  this.template.querySelector('[data-id="mobNumber"]').value;
         }
         
         verifyEmailOTP({
            conId                : this.contactId,
            otpEntered           : otpEnteredVal,
            emailEntered         : newEmail,
            countryCodeEntered   : newCountryCode,
            mobNumberEntered     : newMobNumber
         }).then(result => {
            console.log('handleVerifyEnteredEmailOTP result' + JSON.stringify(result));
            this.showSpinner    = false;
            if(result.Success != null && result.Success){
               this.showToast('Success', result.Success, 'success', 'dismissable');
               this.closeUpdateModal();
               window.location.reload();
            }else if(result.Failed != null && result.Failed){
               console.log('Result >>>'+ result.Failed);
               this.errorMessageWrongOTP = result.Failed;
               this.errorCheckWrongOTP = true;
            }
         }).catch(error => {
            console.log('error verify OTP---->',JSON.stringify(error));
            this.showSpinner          = false;
            this.errorCheckWrongOTP   = true;
            if(error.body.message!=undefined && error.body.message!='' && error.body.message!=null) {
               this.showToast('Error', JSON.stringify(error.body.message), 'error');
            }else{
               this.showToast('Error', error, 'error');
            }
         });
      }

  }
//Added by Tharun for BPE-165 END

//Added by Tharun for BPE-166 START
async handlePhoneNumberBlur(event)
{
   let enteredMobNumber       = event.target.value;
   if(enteredMobNumber != ''){
      let mob                 = enteredMobNumber.replace(/[^0-9]/g,'');
      let mobNumber           = parseInt(mob);
      this.mobileNumber       = mobNumber.toString();
   }
   this.mobileNumberToCheck = this.countryCode + this.mobileNumber;
   this.delayTimeout = setTimeout(async () => {
      let target = await this.template.querySelector('[data-id="mobNumber"]');
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
   }, DELAY);
}

async handleChange(event)
{
   var value = event.target.value;
   if (event.target.dataset.id === 'countryCode') {
      this.countryCode = value;
      if(this.mobileNumber)
      {
          this.mobileNumberToCheck = this.countryCode + this.mobileNumber;
          this.delayTimeout = setTimeout(async () => {
            let target = await this.template.querySelector('[data-id="mobNumber"]');
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
          }, DELAY);
      }
   }else if(event.target.dataset.id === 'proposedUAEVATRegistrationNumber'){
      this.UAEVATRegNumber = value;

      this.delayTimeout = setTimeout(async () => {
         let target = await this.template.querySelector('[data-id="proposedUAEVATRegistrationNumber"]');
         const regex = /^[0-9]{15}$/;

         if (!regex.test(this.UAEVATRegNumber)) {
            target.setCustomValidity("Enter a valid Tax Registration Number (15 numeric characters).");
         } else {
            target.setCustomValidity("");
         }

         target.reportValidity();
      }, DELAY);

   }else if(event.target.dataset.id === 'vatStartDate'){
      this.vatStartDateValue = value;
   }else if(event.target.dataset.id === 'vatEndDate'){
      this.vatEndDateValue = value;
   }
}

/* Handle Resending OTP Added by Tharun BPE-165, BPE-166 */
handleResendOTP()
{
    this.showSpinner = true;
    this.errorCheckWrongOTP = false;
    this.template.querySelector('[data-id="txtEnteredOTP"]').value = '';

    sendForEmailOTP({
         conId             : this.contactId,
         conEmailAddress   : this.existingEmailAddress
      }).then(result => {
         if(result && result.includes('OTPSent')){
            this.showSpinner           = false;
            this.showCountDownTimer    = true;
            var interval=setInterval(function() {
               if(this.refreshCounter==1){
                  this.counter                    = 1;
                  this.refreshCounter             = 0;
                  this.showCountDownTimer         = false;
                  this.showResendOTPButton        = true;
                  clearInterval(interval);
               }
               this.refreshCounter = this.countDownTimerInSeconds - (this.counter++);
            }.bind(this), 1000);
         }
      }).catch(error => {
         // TODO Error handling
         this.showSpinner = false;
      });
}
/* Handle Resending OTP Added by Tharun BPE-165, BPE-166 */

//Added by Tharun for BPE-166 END

onClickNOC(event){
   this.isNOCModalOpen = true;
}

closeNOCModal(event){
   this.isNOCModalOpen = false;
}
    showVatUndertakingCertificate = false;
    showVatCertificate = false;
    UAEVATRegistrationNumber;
    vatValue;
    showVATSection = false;
    VATTitle;

   handleVATChange(event){
      var value = event.target.value;
      if(event.target.dataset.id === 'vatRegistration'){
            this.vatValue = value;
            this.showVATSection = true;
      } 
      if(this.vatValue == 'VAT Registration Certificate'){
            this.VATTitle = 'VAT Certificate';
            this.showVatCertificate = true;
            this.showVatUndertakingCertificate = false;
            
      }else if(this.vatValue == 'VAT Undertaking Certificate'){
            this.VATTitle = 'VAT Undertaking letter';
            this.showVatCertificate = false;
            this.showVatUndertakingCertificate = true;
            this.UAEVATRegNumber = '';
            this.vatStartDateValue = '';
            this.vatEndDateValue = '';
      }
   }
   
downloadVAT(){
   let a = document.createElement("a");
   a.href = VATLetterTemplate;
   a.download = 'VAT Letter Template.pdf';
   a.click();
}
}