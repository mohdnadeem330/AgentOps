/*
* Name               : CustomerUpdateProfileWebService
* Description        : This class is used to upadte Customer's Profile details
*/
@RestResource (urlMapping = '/customer/updateprofile')
global without sharing class CustomerUpdateProfileWebService {

    public enum UPDATETYPE {UpdateFlag, UpdateProfile,UpdateBuyerProfile}

    @HTTPPost
    global static void doPost(Account account, String origin, String unitId, String orderId, String type, String referenceId,Boolean userVerified){
        system.debug('insideDoPost:::');
        RestContextHandler handler = new RestContextHandler(true);
        Savepoint sp = Database.setSavepoint();
        try {
            Boolean userVerifiedval = userVerified;
            RestRequest req = RestContext.request;
            handler.response.data = updateProfile(account, origin, unitId, orderId, type,userVerifiedval);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            System.debug(e.getMessage() +' '+e.getLineNumber()+e.getStackTraceString() );
            Database.rollback(sp);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = e.getMessage() +' '+e.getLineNumber()+e.getStackTraceString();
            handler.finalize(e);
        }
    }

    public static Object updateProfile(Account account, String origin, String unitId, String orderId, String type, Boolean userVerified) {
        
        if (type == String.valueOf(UPDATETYPE.UpdateFlag)) {
            Account updateAccount = new Account();
            updateAccount.Id = account.Id;
            updateAccount.CustomerAppWebUser__c = true;
            update updateAccount;
            return 'Success';
        } else if (type == String.valueOf(UPDATETYPE.UpdateProfile) || type == String.valueOf(UPDATETYPE.UpdateBuyerProfile)) {
            Case newCase = new Case();
            if(type == String.valueOf(UPDATETYPE.UpdateProfile)){
            Group queue = Utilities.getQueueInformation(CustomerAPIConstants.CCA_ONLINE_QUEUE);
            String caseOwnerId = queue.Id != null ? queue.Id : UserInfo.getUserId();

            
            newCase.RecordTypeId = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
            newCase.CustomerType__c = CustomerAPIConstants.CASE_CUSTOMER_TYPE_OWNER;
            newCase.Origin = origin;
            newCase.AccountId = account.Id;
            if (type == String.valueOf(UPDATETYPE.UpdateProfile)){
            	newCase.Unit__c = unitId;
            }
            newCase.isValidationBypass__c= true;
            newCase.SalesOrder__c = orderId;
            newCase.Subject = CustomerAPIConstants.CASE_UPDATE_PROFILE_SUBJECT;
            newCase.SubVertical__c = Constants.CONTACT_CENTRE_SUB_VERTICAL;
            newCase.CaseCategory__c = Constants.CONTACT_DETAILS_UPDATE_CATEGORY;
            newCase.OwnerId = caseOwnerId;
                if(userVerified == true){
                    newCase.RecordTypeId = Utilities.getRecordTypeId('Case', Constants.Requests);
                    newCase.FCR__c = true;
                    newCase.SubVertical__c = Constants.CONTACT_CENTRE_SUB_VERTICAL;
                    newCase.CaseCategory__c = 'Contact Center';
                    newCase.SubCategory__c ='Contact Details Update';
                }
             if (!Test.isRunningTest()) {
                    insert newCase;
                    
              }
            
            if (String.isNotBlank(account.MobileCountryCode__pc)) {
                newCase.MobileCountryCode__c = account.MobileCountryCode__pc;
            } if (String.isNotBlank(account.MobilePhone__pc)) {
                newCase.MobileNumber__c = account.MobilePhone__pc;
            } if (String.isNotBlank(account.MaritalStatus__pc)) {
                newCase.MaritalStatus__c = account.MaritalStatus__pc;
            }

            if (String.isNotBlank(account.BillingStreet)) {
                newCase.PermanentStreet__c = account.BillingStreet;
            } if (String.isNotBlank(account.BillingCity)) {
                newCase.PermanentCity__c = account.BillingCity;
            } if (String.isNotBlank(account.BillingState)) {
                newCase.PermanentState__c = account.BillingState;
            } if (String.isNotBlank(account.BillingPostalCode)) {
                newCase.PermanentPostalCode__c = account.BillingPostalCode;
            } if (String.isNotBlank(account.BillingCountry)) {
                newCase.PermanentCountry__c = account.BillingCountry;
            }
            
            if (String.isNotBlank(account.PassportNumber__pc)) {
                newCase.PassportNumber__c = account.PassportNumber__pc;
            } if (String.isNotBlank(account.Passport_type__pc)) {
                newCase.PassportType__c = account.Passport_type__pc;
            } if (String.isNotBlank(account.PlaceofIssue__pc)) {
                newCase.PlaceofIssue__c = account.PlaceofIssue__pc;
            } if (account.PassportIssueDate__pc != null) {
                newCase.PassportIssueDate__c = account.PassportIssueDate__pc;
            } if (account.PassportExpiryDate__pc != null) {
                newCase.PassportExpiryDate__c = account.PassportExpiryDate__pc;
            }

            if (String.isNotBlank(account.ResidentStatus__pc)) {
                newCase.ResidentStatus__c = account.ResidentStatus__pc;
            } if (String.isNotBlank(account.CountryOfResidence__pc)) {
                newCase.Current_Residential_Country__c = account.CountryOfResidence__pc;
            } if (String.isNotBlank(account.Nationality__pc)) {
                newCase.Nationality__c = account.Nationality__pc;
            } if (String.isNotBlank(account.NationalIdNumber__pc)) {
                newCase.NationalIdNumber__c = account.NationalIdNumber__pc;
            } if (account.NationalIdExpiryDate__pc != null) {
                newCase.NationalIdExpiryDate__c = account.NationalIdExpiryDate__pc;
            }

            if (String.isNotBlank(account.EmploymentStatus__pc)) {
                newCase.EmploymentStatus__c = account.EmploymentStatus__pc;
            } if (String.isNotBlank(account.SourceofFunds__pc)) {
                newCase.SourceofFunds__c = account.SourceofFunds__pc;
            } if (String.isNotBlank(account.Company__pc)) {
                newCase.Company__c = account.Company__pc;
            } if (String.isNotBlank(account.Position__pc)) {
                newCase.Position__c = account.Position__pc;
            } 
            //Pass compound field as a trimmed string.
            String workplaceAddress = account.Workplace_Street__pc + ' ,'+ account.Workplace_Country__pc + ' ,'+ account.Workplace_Postalcode__pc;
            String trimmedWorkplaceAddress = workplaceAddress != null ? workplaceAddress.substring(0, Math.min(255, workplaceAddress.length())) : '';

            if (String.isNotBlank(trimmedWorkplaceAddress)) {
                newCase.CompanyAddress__c = trimmedWorkplaceAddress;
            } if (account.NoofYearswithCompany__pc != null) {
                newCase.NumberOfYearsWithCompany__c = account.NoofYearswithCompany__pc;
            } if (String.isNotBlank(account.Industry)) {
                newCase.Industry__c = account.Industry;
            } if (account.AnnualIncome__pc != null) {
                newCase.AnnualIncome__c = account.AnnualIncome__pc;
            }
            if(userVerified == true){
                newCase.Status = Constants.CLOSED_CASE;
                newCase.StatusReason__c = Constants.WITH_RESOLUTION_CASE;
               
            }
                
            if (!Test.isRunningTest()) {
                update newCase;
            }
            System.debug('After update,newCase.Id ::' + newCase.Id);
			system.debug('updatednewCase:::');
            }
            Account updateAccount = new Account();
            updateAccount.Id = account.Id;
           if (String.isNotBlank(account.Placeofbirth__c)) {
            updateAccount.Placeofbirth__c = account.Placeofbirth__c;
           }
             if (String.isNotBlank(account.ShippingStreet)) {
            updateAccount.ShippingStreet = account.ShippingStreet;
             }
             if (String.isNotBlank(account.ShippingCity)) {
            updateAccount.ShippingCity = account.ShippingCity;
             }
             if (String.isNotBlank(account.ShippingState)) {
            updateAccount.ShippingState = account.ShippingState;
             }
             if (String.isNotBlank(account.ShippingPostalCode)) {
            updateAccount.ShippingPostalCode = account.ShippingPostalCode;
             }
             if (String.isNotBlank(account.ShippingCountry)) {
            updateAccount.ShippingCountry = account.ShippingCountry;
             }
             if (String.isNotBlank(account.VisaUIDNo__pc)) {
            updateAccount.VisaUIDNo__pc = account.VisaUIDNo__pc;
             } 
            if (account.VisaExpiryDate__pc !=null) {
            
            updateAccount.VisaExpiryDate__pc = account.VisaExpiryDate__pc;
            }
             if (String.isNotBlank(account.PassportNumber__pc)) {
            updateAccount.PassportNumber__pc = account.PassportNumber__pc;
             }
                  if (String.isNotBlank(account.BillingPostalCode)) {
            updateAccount.BillingPostalCode = account.BillingPostalCode;
                  }
             if (String.isNotBlank(account.ResidentialAddressSameAsPermanent__c)) {
            updateAccount.ResidentialAddressSameAsPermanent__c = account.ResidentialAddressSameAsPermanent__c;
             }
            if(userVerified == true){
                if (String.isNotBlank(account.BillingStreet)) {
                updateAccount.BillingStreet =account.BillingStreet;
                }
                 if (String.isNotBlank(account.BillingCity)) {
                updateAccount.BillingCity = account.BillingCity;
                 }
                   if (String.isNotBlank(account.BillingCountry)) {
                updateAccount.BillingCountry = account.BillingCountry;
                   }
                 if (String.isNotBlank(account.BillingState)) {
                updateAccount.BillingState = account.BillingState;
                 }
                  if (String.isNotBlank(account.MobileCountryCode__pc)) {
                updateAccount.MobileCountryCode__pc = account.MobileCountryCode__pc;
                  }
                  if (String.isNotBlank(account.MobilePhone__pc)) {
                updateAccount.MobilePhone__pc = account.MobilePhone__pc;
                  }
                  if (String.isNotBlank(account.BillingPostalCode)) {
                updateAccount.BillingPostalCode = account.BillingPostalCode;
                  }
                  if (String.isNotBlank(account.PlaceofIssue__pc)) {
                updateAccount.PlaceofIssue__pc = account.PlaceofIssue__pc;
                  }
                  if (account.PassportIssueDate__pc!=null) {
                updateAccount.PassportIssueDate__pc = account.PassportIssueDate__pc;
                  }
                  if (account.PassportExpiryDate__pc !=null) {
                updateAccount.PassportExpiryDate__pc = account.PassportExpiryDate__pc;
                  }
              if (account.NationalIdNumber__pc !=null) {
                updateAccount.NationalIdNumber__pc = account.NationalIdNumber__pc;
              }
               if (account.NationalIdExpiryDate__pc !=null) {
                updateAccount.NationalIdExpiryDate__pc = account.NationalIdExpiryDate__pc;
               }
                  if (String.isNotBlank(account.ResidentStatus__pc)) {
                updateAccount.ResidentStatus__pc = account.ResidentStatus__pc;
                  }
                  if (String.isNotBlank(account.Nationality__pc)) {
                updateAccount.Nationality__pc = account.Nationality__pc;
                  }
            }
            if( type == String.valueOf(UPDATETYPE.UpdateBuyerProfile)){
                  if (String.isNotBlank(account.Emergency_Full_Name__c)) {
                updateAccount.Emergency_Full_Name__c=account.Emergency_Full_Name__c;
                  }
                  if (String.isNotBlank(account.Emergency_Phone_Number__c)) {
                updateAccount.Emergency_Phone_Number__c=account.Emergency_Phone_Number__c;
                  }
                  if (account.Number_of_Years_in_UAE__c !=null) {
                updateAccount.Number_of_Years_in_UAE__c=account.Number_of_Years_in_UAE__c;
                  }
                  if (String.isNotBlank(account.Landline_Number__c)) {
                updateAccount.Landline_Number__c=account.Landline_Number__c;
                  }
                  if (String.isNotBlank(account.MaritalStatus__pc)) {
				updateAccount.MaritalStatus__pc = account.MaritalStatus__pc;
                  }
            }
			//updateAccount.MaritalStatus__pc = account.MaritalStatus__pc;
            update updateAccount;
			system.debug('updatedAccount:::');
            if(type == String.valueOf(UPDATETYPE.UpdateProfile) && userVerified ==false){
            List<Document__c> docList = new List<Document__c>();
            Document__c cisSheet = new Document__c();
            cisSheet.DocumentType__c = CustomerAPIConstants.DOCUMENT_TYPE_CIS_SHEET;
            cisSheet.Account__c = account.Id;
            cisSheet.Case__c = newCase.Id;
            docList.add(cisSheet);
            Document__c signCISSheet = new Document__c();
            signCISSheet.DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_CIS;
            signCISSheet.Account__c = account.Id;
            signCISSheet.Case__c = newCase.Id;
            docList.add(signCISSheet);
            insert docList;
			system.debug('insertedDocList:::');
            }

            if( type == String.valueOf(UPDATETYPE.UpdateBuyerProfile)){
                 // Start SR Step automation
        map<string, HexaBPM__Status__c> stepStatusMap = new map<string, HexaBPM__Status__c>();
		for (HexaBPM__Status__c srStepStatus : [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name IN ('Completed')]) {
            stepStatusMap.put(srStepStatus.Name, srStepStatus);
        }
        List<HexaBPM__Step__c> srStepsToUpdateList = new List<HexaBPM__Step__c>();
         List<HexaBPM__Service_Request__c> SRList = [SELECT id, HexaBPM__Customer__c, Unit__c FROM HexaBPM__Service_Request__c WHERE BuyerName__c =:account.id AND HexaBPM__External_Status_Name__c ='Submitted' AND SRType__c ='Property Transfer NOC' ];
              if(SRList.size() >0){
                for(HexaBPM__Step__c srStep : [SELECT Id,HexaBPM__Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :SRList[0].Id AND HexaBPM__Summary__c = 'Verification of Buyer Profile' AND HexaBPM__Step_Status__c = 'Pending']){
                    srStep.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;
                    srStepsToUpdateList.add(srStep);
                    system.debug('srStepsToUpdateList ::'+srStepsToUpdateList);
                    
                }
                if(!srStepsToUpdateList.IsEmpty()){
                    update srStepsToUpdateList;
                    system.debug('Updated succesfully ::'+srStepsToUpdateList[0]);
                }

              }
              List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id,HexaBPM__Generate_Document__c,HexaBPM__Status__c,HexaBPM__Document_Name__c ,Name FROM HexaBPM__SR_Doc__c WHERE (HexaBPM__Document_Name__c ='Owner Association Letter' OR HexaBPM__Document_Name__c='Document of Adherence')
                                                    AND HexaBPM__Service_Request__c=:SRList[0].Id ORDER BY CreatedDate DESC LIMIT 2];
                if(srDocList.size() >0){
                    for(HexaBPM__SR_Doc__c srd :srDocList ){
                        srd.HexaBPM__Generate_Document__c = true;
                    }
                    update srDocList;
                    //system.debug('newCase.Id ::'+newCase.Id );
                    //newCase = CustomerServiceUtility.getCaseDetail(' (Id = \'' + newCase.Id + '\') ')[0];
                     
                    UpdateProfileModelNOC updateProfileModelnoc = new UpdateProfileModelNOC(newCase,srDocList);
                    return updateProfileModelnoc;
                }

 
            }

           
            UpdateProfileModel updateProfileModel = new UpdateProfileModel(newCase);

            return updateProfileModel;
        }
        return null;
    }

    public class UpdateProfileModel {
        public String requestId                                     {get;set;}
        public String customerId                                    {get;set;}
        public String customerName                                  {get;set;}
        public String organization                                  {get;set;}
        public String department                                    {get;set;}
        public String vertical                                      {get;set;}
        public String subVertical                                   {get;set;}
        public List<DocumentQueryModel> documents                   {get;set;}

        public UpdateProfileModel(Case cs) {
            this.requestId = cs.Id;
            this.customerId = cs.AccountId;
            this.customerName = cs.Account.Name;
            this.organization = cs.Organization__c;
            this.department = cs.Department__c;
            this.vertical = cs.Vertical__c;
            this.subVertical = cs.SubVertical__c;
            this.documents = new List<DocumentQueryModel>();
            for (Document__c doc: cs.Documents__r) {
                if (doc.DocumentType__c == CustomerAPIConstants.DOCUMENT_TYPE_CIS_SHEET) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED) ? true : false;
                    documentQueryModel.isUploadable = false;
                    documentQueryModel.eligibleForeSign = true;
                    this.documents.add(documentQueryModel);
                }
            }
        }
    }

    public class UpdateProfileModelNOC {
        public String requestId                                     {get;set;}
        public String customerId                                    {get;set;}
        public String customerName                                  {get;set;}
        public String organization                                  {get;set;}
        public String department                                    {get;set;}
        public String vertical                                      {get;set;}
        public String subVertical                                   {get;set;}
        public Boolean isDocGenerated                               {get;set;}
        public List<DocumentQueryModel> documents                   {get;set;}

        public UpdateProfileModelNOC(Case cs, List<HexaBPM__SR_Doc__c> srdoc) {
            this.requestId = cs.Id;
            this.customerId = cs.AccountId;
            this.customerName = cs.Account.Name;
            this.organization = cs.Organization__c;
            this.department = cs.Department__c;
            this.vertical = cs.Vertical__c;
            this.subVertical = cs.SubVertical__c;
            this.isDocGenerated = true;
            this.documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: srdoc) {
                if (doc.HexaBPM__Document_Name__c == 'Owner Association Letter' || doc.HexaBPM__Document_Name__c == 'Document of Adherence') {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED) ? true : false;
                    documentQueryModel.isUploadable = false;
                    documentQueryModel.eligibleForeSign = true;
                    this.documents.add(documentQueryModel);
                }
            }
        }
    }
}