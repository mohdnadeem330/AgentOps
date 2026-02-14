/*
* Name               : CustomerProfileWebservice

* Description        : This class is used to get Customer's Profile details
* Version			 : V1.1 Added by Protiviti when retail contact logic added.
*/
@RestResource (urlMapping = '/customer/myprofile')
global without sharing class CustomerProfileWebservice {
    private static String CASE_SUBVERTICAL_CUSTOMERPORTAL_LIVEALDAR  = 'Customer Portal and App - Live Aldar';//NOPMD: [Code Style-FieldNamingConventions]
    private static String CASE_CASECATEGORY_DATA_ACCOUNTMERGE        = 'Data - Account Merge';//NOPMD: [Code Style-FieldNamingConventions]
    private static String CLOSED                                     = 'Closed';//NOPMD: [Code Style-FieldNamingConventions]
    @HTTPPost
    global static void doPost(String email, String emiratesId, Boolean authentication){       
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> responseMap = getProfileData(email, emiratesId, authentication);
            if (responseMap.containsKey('success')) {
                handler.response.data = responseMap.get('success');
                handler.response.success = true;
            }else if(responseMap.containsKey('invalidAccountValidContact')){//V1.1 Protiviti
                handler.response.message = CustomerAPIConstants.MESSAGE_MULTI_ACCOUNT_FOUND;
                handler.response.data = responseMap.get('invalidAccountValidContact');
                handler.response.success = true;
            }
            else if(responseMap.containsKey('multipleAccountContactFound')){//V1.1 Protiviti
                handler.response.success = false;
                handler.response.statusCode = CustomerAPIConstants.STATUS_CODE_SYSTEM_MULTI_CONTACT;
                handler.response.message = CustomerAPIConstants.MESSAGE_MULTI_ACCOUNT_CONTACT_FOUND;
            } else if (responseMap.containsKey('multiAccountFound')) {
                handler.response.success = false;
                handler.response.statusCode = CustomerAPIConstants.STATUS_CODE_SYSTEM_MULTI_ACCOUNT;
                handler.response.message = CustomerAPIConstants.MESSAGE_MULTI_ACCOUNT_FOUND;
            } /*else if (responseMap.containsKey('noAccountFound')) {
handler.response.success = false;
handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
handler.response.message = CustomerAPIConstants.MESSAGE_NO_ACCOUNT_FOUND;
} */
            else if(responseMap.containsKey('multiContactFound')){//1.1 protiviti
                handler.response.success = false;
                handler.response.statusCode = CustomerAPIConstants.STATUS_CODE_SYSTEM_MULTI_CONTACT;
                handler.response.message = CustomerAPIConstants.MESSAGE_MULTI_CONTACT_FOUND;
            }else if (responseMap.containsKey('blankParameters')) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_BLANK_REQUEST_PARAMETERS;
            }//Added by Protiviti Starts here.
            else if(responseMap.containsKey('noDataFound')){//V1.1 Protiviti
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_NO_DATA_FOUND;
            }
            //Added by Protiviti Ends here.
            handler.finalize();
        } catch(Exception ex){
            System.debug(ex.getLineNumber()+' '+ex.getmessage() +ex.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message =CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }

    public static Map<String, Object> getProfileData(String email, String emiratesId, Boolean authentication) {
        Map<String, Object> profileModelMap = new Map<String, Object>();
        AuthenticationDataWrapper authenticationWrapper;//V1.1  Added for creating response for login API.
        if (String.isBlank(emiratesId) && String.isBlank(email)) {
            profileModelMap.put('blankParameters', null);
            return profileModelMap;
        }    
        Boolean isValid = false;
        //V1.1 Added by Protiviti  Starts here
        // Build dynamic SOQL WHERE clauses for Person Account and Contact.
        String whereClause = String.isNotBlank(emiratesId) ? ' (NationalIdNumber__pc = \'' + emiratesId + '\') ' : ' (PersonEmail = \'' + email + '\') ';
        whereClause += ' AND MergedAccount__c = false AND Blacklisted__c = false AND SkipCustomerLogin__c = false AND SkipLiveAldarReason__c = null ';
        List<Account> accountList = new List<Account>();
        List<Contact> contactList =  new List<Contact>();
        
		//V1.1 Added by Protiviti  End here
        if (authentication) {
            // Check Authentication from ForgeRock
            //V1.1 Added by Protiviti  Starts here
            authenticationWrapper = new AuthenticationDataWrapper();//to store personaccount and contact related to bussiness contact basic info.
            String query = 'SELECT Id, Name, FirstName, LastName, PersonEmail, MobileCountryCode__pc, MobilePhone__pc, Nationality__pc, NationalIdNumber__pc, BillingCountry, AllowLiveAldarRegistration__c, ERPID__c, CustomerVertical__c FROM Account';
            //V1.1 Added by  Protiviti End here
                accountList = Database.query(query + ' WHERE ' + whereClause);
           	//V1.1 Modified by Protiviti Ends here.
            if (!accountList.isEmpty() && accountList.size() == 1) {
                //V1.1 Commented By Protiviti
                //profileModelMap.put('success', accountList[0]);
                //V1.1 Added below line by Protiviti
                authenticationWrapper.account = accountList[0];
            }
            
            //Added by Tajinkumar
            else if(accountList.size() > 1){ 
                List<Account> getAccountList = CustomerServiceUtility.getAccountDetail(whereClause);
                isValid = getActiveAccounts(getAccountList,authenticationWrapper,isValid);
            }
            
            //V1.1 Added by Protiviti  Starts here
            contactList = RETL_ProfileAPIHandler.findContacts(email, emiratesId);
            if (contactList.size() == 1) {
                authenticationWrapper.contact = RETL_ProfileAPIHandler.prepareContactData(contactList[0]);
            }
            //  Error conditions — only if BOTH lists are in error states
            Boolean isAccountError = accountList.size() > 1 && contactList.isEmpty() && !isValid;  //Added !isValid check by Tajinkmar
            Boolean isContactError = contactList.size() > 1 && accountList.isEmpty();
            Boolean isOnlyAccountMultiple = accountList.size() > 1 && contactList.size() == 1 && !isValid;  //Added !isValid check by Tajinkmar
            Boolean isOnlyContactMultiple = contactList.size() > 1 && accountList.size() == 1;
            
            if (isAccountError || isOnlyAccountMultiple) {
                authenticationWrapper.error = new ErrorWrapper(CustomerAPIConstants.STATUS_CODE_SYSTEM_MULTI_ACCOUNT, CustomerAPIConstants.MESSAGE_MULTI_ACCOUNT_FOUND);
            } else if (isContactError || isOnlyContactMultiple) {
                authenticationWrapper.error = new ErrorWrapper(CustomerAPIConstants.STATUS_CODE_SYSTEM_MULTI_CONTACT, CustomerAPIConstants.MESSAGE_MULTI_CONTACT_FOUND);
            }
            
            // Always return success if at least one valid record found
            profileModelMap = new Map<String, Object>{'success' => authenticationWrapper.toApiResponse()};
            //V1.1 Added by Protiviti  End here
            // Check Authentication from ForgeRock
        } else {
            //V1.1 Added below line by Protiviti for capturing the list of bussiness account details.
            ProfileModel profileModel = new ProfileModel();
            // Check for Account with Sales Order
            //V1.1 Modified by Protiviti. Instead of whereClause added personAccountWhereClause.
            accountList = CustomerServiceUtility.getAccountDetail(whereClause);
            if (!accountList.isEmpty() && accountList.size() == 1) {
                profileModel.account = accountList[0];
                isValid = true; 
            } else {
                Integer count = 0;
                for (Account acc: accountList) {
                    //Commented by Tajinkumar
                    /*if (acc.CustomerAppWebUser__c && !acc.Opportunity_Units__r.isEmpty()) {
profileModel.account = acc;
isValid = true;
count = 1;
break;                        
} else */
                    
                    if (!acc.Opportunity_Units__r.isEmpty()) {                       
                        profileModel.account = acc;
                        isValid = true;                        
                        count++;                      
                    }                    
                }               
                if (count > 1) {                   
                    isValid = false;                   
                }                
            }  
            // Check for Account with Sales Order
            if (isValid) {
                Set<String> documentPlaceHolderSet = new Set<String>();
                for (DocumentPlaceHolder__mdt documentPlaceHolder: DocumentPlaceHolder__mdt.getall().values()) {
                    if ((documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT) && documentPlaceHolder.AvailableForCustomer__c) {
                        documentPlaceHolderSet.add(documentPlaceHolder.DocumentType__c);                       
                    }                    
                }
                // Account Manager for VIP Customer
                 if (profileModel.account.CMAccountManager__c != null) {
                    profileModel.accountManager.put('name', profileModel.account.CMAccountManager__r.Name);
                    profileModel.accountManager.put('id', profileModel.account.CMAccountManager__c);                   
                    profileModel.accountManager.put('phone', profileModel.account.CMAccountManager__r.Phone);                   
                    profileModel.accountManager.put('mobile', profileModel.account.CMAccountManager__r.MobilePhone);
                    profileModel.accountManager.put('email',profileModel.account.CMAccountManager__r.Email);
                }
                if (profileModel.account.KeyAccountManager__c != null) {
                    profileModel.salesManager.put('name', profileModel.account.KeyAccountManager__r.Name);
                    profileModel.salesManager.put('id', profileModel.account.KeyAccountManager__c);
                    profileModel.salesManager.put('phone', profileModel.account.KeyAccountManager__r.Phone); 
                    profileModel.salesManager.put('mobile', profileModel.account.KeyAccountManager__r.MobilePhone);
                    profileModel.salesManager.put('email', profileModel.account.KeyAccountManager__r.Email);
                }
                
                // Account Manager for VIP Customer  
                //Added by Sarah on Apr 10, April 29 - 2024 for ASF-2796, ASF-2847 - From here
                 DateTime latestDateTime;
                DateTime latestManualKYCUploadedDateTime;
                if(profileModel.account.Communication_Preferences__r != null && profileModel.account.Communication_Preferences__r.size() != 0) {
                    for(Communication_Preference__c cp : profileModel.account.Communication_Preferences__r){
                        if(cp.Active__c==true){
                            if(cp.Category__c =='Booking'){
                            profileModel.digitalSales.add(cp);
                        }else if(cp.Category__c =='FastTrack'){
                            if(profileModel.fasttrackRecord == null){                                
                                profileModel.fasttrackRecord	= cp;                               
                                if(cp.Status__c != 'Fasttrack Completed'){                                  
                                    profileModel.enableFastTrack 	= true;                                    
                                }else{                                  
                                    profileModel.enableFastTrack 	= false;                                 
                                }
                            }
                        }
                        else if(cp.Category__c =='NOC-Fasttrack'){
                            if(profileModel.NocFastTrack == null){
                                profileModel.NocFastTrack	= cp;
                                if(cp.Status__c != 'Fasttrack Completed'){
                                    profileModel.enableNOCFastTrack 	= true;
                                }else{                                  
                                    profileModel.enableNOCFastTrack 	= false;                                   
                                }
                            }
                        } 
                        if(cp.Category__c =='Digital SPA' && (cp.Status__c =='Link Sent') ){
                            profileModel.digitalSPA.add(cp);
                            system.debug('insideDigitalSPA');
                        }
                         //Added by Harsh@Aldar 21/03/2025 Parking

                        if(cp.Category__c =='Premium Parking' && cp.Status__c =='Link Sent'){

                            profileModel.premParkAddendum.add(cp);

                        }
                    }
                        
                        if(!cp.isFastTrackAutoCompleted__c && cp.FastTrack_Completion_Date_Time__c != null && (cp.Category__c =='Booking' || cp.Category__c =='Fasttrack')){
                            if(latestDateTime == null || cp.FastTrack_Completion_Date_Time__c > latestDateTime){
                                latestDateTime =cp.FastTrack_Completion_Date_Time__c;
                            }
                        }
                    }
                    profileModel.latestDigitalFastTrackCompletionDate = latestDateTime;
                } else {
                    profileModel.enableFastTrack            = false;
                }
                //Residential Leasing START
                 Set<Id> oppIds = new Set<Id>();
                For(Opportunity opp : [Select Id, RecordType.Name From Opportunity Where (RecordType.Name ='Leasing' OR RecordType.DeveloperName ='ECSS_Parent') AND AccountId=:profileModel.account.Id]){
					oppIds.add(opp.Id);
                }
                profileModel.LeasingOpportunityIds.addAll(oppIds);
                Set<Id> ContractId = new Set<Id>();
                For(Contract Con :[SELECT Id,AccountId FROM Contract WHERE AccountId =:profileModel.account.Id AND ECSS_ContractOrganizationType__c='Tenancy']){
                    profileModel.ContractIds.add(con.Id);
                }
                //Residential Leasing END
                //Till here
                // Attaching Profile Picture Base 64 and other document along with CIS Sheet(if Any)
                for (Document__c doc: profileModel.account.Documents__r) {
                    
                    Boolean isKYCForm = doc.DocumentType__c == CustomerAPIConstants.DOCUMENT_TYPE_SIGNED_KYC_FORM;
                    Boolean isProfilePicture = doc.DocumentType__c == CustomerAPIConstants.DOCUMENT_TYPE_PROFILE_PICTURE;
                    
                    if(isKYCForm || isProfilePicture) {
                        ContentVersion contentVersion = CustomerServiceUtility.getContentVersion(doc.Id);
                        System.debug('>>contentVersion : ' + contentVersion);
                        if(isProfilePicture && contentVersion != null){
                        profileModel.profilePicture = contentVersion.VersionData;
                            System.debug('>>isProfilePicture : ' + isProfilePicture + '-' + contentVersion.title);
                            
                        }
                        if(isKYCForm && contentVersion != null && doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED){
                            profileModel.manualKYCUploadedDate = contentVersion.CreatedDate;
                            if (latestManualKYCUploadedDateTime == null || contentVersion.CreatedDate > latestManualKYCUploadedDateTime) {
                                latestManualKYCUploadedDateTime = contentVersion.CreatedDate;
                                System.debug('>>Selected KYC CreatedDate: ' + contentVersion.CreatedDate + ' - ' + contentVersion.Title);
                            } 
                        }
                    }
                     else if (documentPlaceHolderSet.contains(doc.DocumentType__c)) {
                        DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                        documentQueryModel.isUploaded = (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED) ? true : false;
                        documentQueryModel.isUploadable = true;
                        profileModel.documents.add(documentQueryModel);
                    } else if (doc.DocumentType__c == CustomerAPIConstants.DOCUMENT_TYPE_SIGNED_CIS_SHEET && doc.Case__c != null && !doc.Case__r.IsClosed && (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.Status__c == CustomerAPIConstants.DOCUMENT_STATUS_DOCUSIGN_PENDING)) {
                        profileModel.isEditProfileUnderReview = true;
                    } else if (doc.DocumentType__c == CustomerAPIConstants.DOCUMENT_TYPE_CIS_SHEET && doc.Case__c != null && !doc.Case__r.IsClosed) {
                        profileModel.isEditProfileInProgress = true;
                        profileModel.cisSheetId = doc.Id;
                    }
                }
                profileModel.manualKYCUploadedDate = latestManualKYCUploadedDateTime;
                
                if (profileModel.isEditProfileUnderReview) {
                    profileModel.isEditProfileInProgress = false;
                    profileModel.cisSheetId = null;                    
                }
                // Attaching Profile Picture Base 64 and other document along with CIS Sheet(if Any) 
                // String accWhereClause = ' (PersonEmail = \'' + accountList[0].PersonEmail + '\') ';
                // String accQuery = 'SELECT Id, Name, PersonEmail, MobileCountryCode__pc, MobilePhone__pc FROM Account';
                // List<Account> allAccountList = Database.query(accQuery + ' WHERE ' + accWhereClause);
                // List<Id> accIds = new List<Id>();
                // for (Account acc: allAccountList) {
                //  accIds.add(acc.Id);
                // }
                // String accIdsStr = String.join(accIds, '\',\'');
                // List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(accIds);
                // Get All Sales Order including Joint Owner
                List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{profileModel.account.Id});
                //CustomerResellPreference__c
                String soIdsStr = String.join(soIds, '\',\'');
                String GovtProjects = String.join(System.Label.GovtProjects.split(','), '\',\'');
                
                String cancelledWhereCaluse = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\'  AND Status__c != \'' + Constants.SO_STATUS_RTO_CONVERTED + '\'   AND Status__c != \'RTOConverted\'  ) ';
                String salesOrderWhrClause = '';
                system.debug('accId::'+profileModel.account.Id);
                if (!soIds.isEmpty()) {
                    // salesOrderWhrClause = ' ((Account__c IN (\'' + accIdsStr + '\') OR Id IN (\'' + soIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
                    salesOrderWhrClause = ' ((Account__c = \'' + profileModel.account.Id + '\' OR Id IN (\'' + soIdsStr + '\')) AND  Unit__r.Project__r.Name NOT IN(\''+GovtProjects+'\') AND Unit__r.Project__r.City__c !=\'London\' AND ' + cancelledWhereCaluse + ') ';
                } else {
                    // salesOrderWhrClause = ' ((Account__c IN (\'' + accIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
                    salesOrderWhrClause = ' ((Account__c = \'' + profileModel.account.Id + '\')  AND  Unit__r.Project__r.Name NOT IN(\''+GovtProjects+'\') AND Unit__r.Project__r.City__c !=\'London\' AND ' + cancelledWhereCaluse + ') ';
                } 
                System.debug('>>SO QUERY>>'+salesOrderWhrClause);
                List<SalesOrder__c> salesOrderList2 = new List<SalesOrder__c>();
                List<SalesOrder__c> salesOrderList1 = CustomerServiceUtility.getSalesOrderDetailForProfile(salesOrderWhrClause);
                for(SalesOrder__c sl :salesOrderList1){
                    if(sl.is_Digital_Sales__c == true && sl.Status__c =='Reservation In Progress' ){
                       
                    }else{
                         salesOrderList2.add(sl);
                    }
                }
                
                ///Added by CHirag For NOC 
                Map<Id,HexaBPM__Service_Request__c> SRMap = new Map<Id,HexaBPM__Service_Request__c>();
                List<HexaBPM__Service_Request__c> existingSRs = [SELECT Id, Case__c,SalesOrder__c,IsSellerConfirmsTransfer__c FROM HexaBPM__Service_Request__c WHERE SalesOrder__c IN: salesOrderList2 AND HexaBPM__Customer__c = :profileModel.account.Id AND SRType__c ='Property Transfer NOC' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled','Closed') AND Origin__c IN ('Customer Portal','Customer App') ORDER BY CreatedDate];
                for(HexaBPM__Service_Request__c sr :existingSRs){
                    if(!SRMap.containsKey(sr.SalesOrder__c)){
                        SRMap.put(sr.SalesOrder__c,sr);
                    }                    
                }   
                List<SalesOrder__c>salesOrderList = new List<SalesOrder__c>();
                List<Id> SalesOrderIdstoberemoved = new List<Id>();
                for(HexaBPM__Service_Request__c sr: SRMap.values()){
                    if(sr.IsSellerConfirmsTransfer__c == true){
                        SalesOrderIdstoberemoved.add(sr.SalesOrder__c);
                    }
                }
                //END
                for(SalesOrder__c soorder: salesOrderList2){
                    if(!SalesOrderIdstoberemoved.contains(soorder.Id)){
                        salesOrderList.add(soorder);
                    }
                }
                profileModel.totalProperties = salesOrderList.size();
                profileModel.isNameEditable = profileModel.totalProperties > 0 ? false : true;
                profileModel.salesOrders = salesOrderDetails(profileModel.account.Id, salesOrderList);
                profileModel.previousResaleUnits = getPreviousResaleUnits(profileModel.account.Id);
                List<Id>soldIds = new List<Id>();
                for (SalesOrder__c salesOrder: salesOrderList) {
                    profileModel.projects.add(salesOrder.Unit__r.Project__c);
                    if(salesOrder.Status__c =='Sold'){
                        soldIds.add(salesOrder.Id);
                    }
                }
                if(soldIds.size() ==salesOrderList.size()){
                    profileModel.isEditProfile = true;
                }
                
                
                // Adding all Sales Order Details
                //V1.1 Commented below line by Protiviti.
                //profileModelMap.put('success', profileModel);
            }
            //get otherverticalData and customer contact Data
            contactList = RETL_ProfileAPIHandler.findContacts(email, emiratesId);
            RETL_ProfileAPIHandler.ContactModel  contactData;
            if (!contactList.isEmpty() && contactList.size() == 1) {
                contactData = RETL_ProfileAPIHandler.processProfileAPI(contactList[0]);
                profileModel.contact = contactData;
                if(accountList.isEmpty()){
                    profileModel.account = null;
            }
        }
            else if (!contactList.isEmpty() && contactList.size() > 1){
                contactData = new RETL_ProfileAPIHandler.ContactModel();
                contactData.error = new RETL_ProfileAPIHandler.ErrorWrapper(CustomerAPIConstants.STATUS_CODE_SYSTEM_MULTI_CONTACT, CustomerAPIConstants.MESSAGE_MULTI_CONTACT_FOUND);
                profileModel.Contact = contactData;
            }
            //if Account is multiple and single contact
            if( !accountList.isEmpty() && accountList.size() > 1 && !contactList.isEmpty() &&  contactList.Size() == 1 && !isValid){
                profileModel.account = null;
                profileModelMap = new Map<String, Object>{'invalidAccountValidContact'=> profileModel};
            }
            else {
                profileModelMap = new Map<String, Object>{'success'=> profileModel};
            }
            //V1.1 Added by Protiviti  End here
        }
        // Executed when Multiple Accounts is found
        if (!accountList.isEmpty() && accountList.size() > 1 && (authentication || !isValid)) {
            //V1.1 Commented by Protiviti
            //profileModelMap = new Map<String, Object>{'multiAccountFound'=> null};
                //Added by Sarah on Mar 07, 2024 for ASF-2591 - From here
            List<Case> caseList = [SELECT Id, AccountId, Account.PersonEmail, Status, SubVertical__c, CaseCategory__c FROM Case WHERE AccountId =:accountList[0].Id
                                       AND Account.PersonEmail =: accountList[0].PersonEmail AND Status !=:CustomerProfileWebservice.CLOSED
                                       AND SubVertical__c =:CustomerProfileWebservice.CASE_SUBVERTICAL_CUSTOMERPORTAL_LIVEALDAR AND CaseCategory__c =:CustomerProfileWebservice.CASE_CASECATEGORY_DATA_ACCOUNTMERGE];
            if(caseList == null || caseList.isEmpty()){
                Case newCaseToCreate = createCaseHelper(accountList, authentication);
                insertCase(JSON.serialize(newCaseToCreate)); // Added by Tajinkumar       
            }
            //Till here
        }
        //V1.1 Added by Protiviti  Starts here.
        if(!contactList.isEmpty() && contactList.size() > 1){
             List<Case> caseList = [SELECT Id, ContactId,  Status, SubVertical__c, CaseCategory__c FROM Case WHERE ContactId =:contactList[0].Id
                                   AND Contact.Email =: contactList[0].Email AND Status !=:CustomerProfileWebservice.CLOSED
                                   AND SubVertical__c =:CustomerProfileWebservice.CASE_SUBVERTICAL_CUSTOMERPORTAL_LIVEALDAR AND CaseCategory__c =:CustomerProfileWebservice.CASE_CASECATEGORY_DATA_ACCOUNTMERGE WITH USER_MODE];
            if(caseList == null || caseList.isEmpty()){
                Case newCaseToCreate = RETL_ProfileAPIHandler.createCaseHelperForContact( contactList,  authentication);
                try{
                    insert as user newCaseToCreate;
                }
                catch(exception e){
                    LoggerService.save(LoggerService.addApexLog(e,'DuplicateContactCaseCreation','CustomerProfileWebservice','getProfileData'));
                }
            }
        }
        // Executed when  Accounts and  Contact Related to Bussiness account is not found
        if (accountList.isEmpty() && contactList.isEmpty()) {
            profileModelMap = new Map<String, Object>{'noDataFound'=> null};
                }// Executed when  Multiple Accounts and  Contact Related to Bussiness account is found
        else if(!accountList.isEmpty() && !contactList.isEmpty() && accountList.Size()>1 && contactList.Size()>1 && !isValid){ //Added !isValid check by Tajinkumar 
            profileModelMap = new Map<String, Object>{'multipleAccountContactFound'=> null};
                }// Executed when  Multiple Contact Related to Bussiness account is found
        else if( !contactList.isEmpty() && contactList.size() > 1  && accountList.isEmpty()){
            profileModelMap = new Map<String, Object>{'multiContactFound'=> null};
                }// Executed when  Multiple Accounts is found
        else if( !accountList.isEmpty() && accountList.size() > 1 && contactList.isEmpty() && !isValid){ //Added !isValid check by Tajinkumar 
            profileModelMap = new Map<String, Object>{'multiAccountFound'=> null};
                }
        //V1.1 Added by Protiviti  Ends here.
        return profileModelMap;
    }

    public static List<PreviousUnitDetails> getPreviousResaleUnits(String accountId){
        List<PreviousUnitDetails> previousResaleUnits = new List<PreviousUnitDetails>();
        for( TransferHistory__c th : [Select ID,SalesOrder__r.Unit__r.Name,SalesOrder__r.Unit__r.ProjectName__c, CreatedDate FROM TransferHistory__c where FromAccount__c = :accountId AND SalesOrder__r.Unit__r.ResaleStatus__c = 'Transfer Completed' LIMIT 10]){
            PreviousUnitDetails unitDetail = new PreviousUnitDetails();
            unitDetail.unitName = th.SalesOrder__r.Unit__r.Name;
            unitDetail.projectName = th.SalesOrder__r.Unit__r.ProjectName__c;
            unitDetail.saleDate = th.CreatedDate;
            previousResaleUnits.add(unitDetail);
        }
        return previousResaleUnits;
    }
    public static List<SalesOrderModel> salesOrderDetails(String accountId, List<SalesOrder__c> salesOrderList) {
        List<SalesOrderModel> soDetails = new List<SalesOrderModel>();
        for (SalesOrder__c salesOrder: salesOrderList) {
            SalesOrderModel soModel = new SalesOrderModel(salesOrder, accountId);
            soDetails.add(soModel);
        }
        return soDetails;
    }
    public static Case createCaseHelper(List<Account> accountList, Boolean isRegistration) {
        Group queue                                                       = Utilities.getQueueInformation('MergeCaseQueue');
        String caseOwnerId                                          = queue.Id != null ? queue.Id : UserInfo.getUserId();
        Case newCase                                                   = new Case();
        newCase.RecordTypeId                    = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
        newCase.CustomerType__c                          = CustomerAPIConstants.CASE_CUSTOMER_TYPE_OWNER;
        newCase.Origin                                                 = CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL;
        newCase.AccountId                                         = accountList[0].Id;
        newCase.SubVertical__c                  = 'Customer Portal and App - Live Aldar';
        newCase.CaseCategory__c                           = 'Data - Account Merge';
        newCase.Subject                                = CustomerAPIConstants.MULTI_ACCOUNT_FOUND_SUBJECT + ' ' + accountList[0].PersonEmail;
        newCase.CustomerComment__c = isRegistration ? CustomerAPIConstants.MULTI_ACCOUNT_FOUND_REGISTRATION : CustomerAPIConstants.MULTI_ACCOUNT_FOUND_LOGIN;
        newCase.OwnerId                              = caseOwnerId;
        newCase.isValidationBypass__c = true;
        Database.DMLOptions options                                                  = new Database.DMLOptions();
        options.assignmentRuleHeader.useDefaultRule = false;
        newCase.setOptions(options);
        return newCase;
    }
    public class PreviousUnitDetails{
        public String unitName                                              {get;set;}
        public String projectName                                           {get;set;}
        public DateTime saleDate                                            {get;set;}
    }
    public class ProfileModel {//Modified by Protiviti by adding bussiness contact property to wrapper.
        public Account account                                              {get;set;}
        public Boolean isNameEditable                                       {get;set;}
        public List<PreviousUnitDetails> previousResaleUnits                {get;set;}
        public Blob profilePicture                                          {get;set;}
        public Decimal totalProperties                                      {get;set;}
        public Decimal transferFee                                          {get;set;}
        public Set<String> projects                                         {get;set;}
        public List<SalesOrderModel> salesOrders                            {get;set;}
        public List<DocumentQueryModel> documents                           {get;set;}
        public Map<String, Object> accountManager                           {get;set;}
        public Map<String, Object> salesManager                             {get;set;}
        public Boolean isEditProfileInProgress                              {get;set;}
        public Boolean isEditProfileUnderReview                             {get;set;}
        public String cisSheetId                                            {get;set;}
        public Communication_Preference__c fasttrackRecord                                                             {get;set;}//Added by Sarah on Apr 30, 2024 for ASF-2847
        public Boolean enableFastTrack                                                                                                                                     {get;set;}//Added by Sarah on Apr 10, 2024 for ASF-2796
        public List<Communication_Preference__c> digitalSPA                                                                            {get;set;}
        public List<Communication_Preference__c> digitalSales {get;set;}
        public Communication_Preference__c NocFastTrack {get;set;}
        public String defaultDigitalSalesManagerId {get;set;} // Added by Tajinkumar - LAC-1988
        public DateTime latestDigitalFastTrackCompletionDate {get;set;}
        public DateTime manualKYCUploadedDate {get;set;}
        public List<Communication_Preference__c> premParkAddendum {get;set;}////Harsh
        public Boolean enableNOCFastTrack	{get;set;}
        public Boolean isEditProfile {get;set;}
        public Set<Id>ContractIds{get;set;}
        public Set<Id> LeasingOpportunityIds {get;set;}
        public RETL_ProfileAPIHandler.ContactModel contact;//V1.1 added by Protiviti
        public ProfileModel() {
            this.account = new Account();
            this.isNameEditable = false;
            this.profilePicture = null;
            this.totalProperties = 0;
            this.projects = new Set<String>();
            this.salesOrders = new List<SalesOrderModel>();
            this.documents = new List<DocumentQueryModel>();
            this.accountManager = new Map<String, Object>();
            this.salesManager = new Map<String, Object>();
            this.isEditProfileInProgress = false;
            this.isEditProfileUnderReview = false;
            this.cisSheetId = null;
            this.previousResaleUnits = new List<PreviousUnitDetails>();
            this.fasttrackRecord        = null;
            this.latestDigitalFastTrackCompletionDate = null;
            this.defaultDigitalSalesManagerId = System.Label.Digital_SalesManager; // Added by Tajinkumar - LAC-1988
            this.manualKYCUploadedDate = null;
            this.digitalSPA          = new List<Communication_Preference__c>();
            this.enableFastTrack       = null;
            this.digitalSales = new List<Communication_Preference__c>();
            this.NocFastTrack = null;
            this.enableNOCFastTrack = false; 
            this.premParkAddendum = new List<Communication_Preference__c>();//Harsh
            this.isEditProfile = false;
            this.ContractIds = new Set<Id>();
            this.LeasingOpportunityIds = new Set<Id>();
            this.contact = null;
            // Added by Daksh - TrensferFee
            try {
                List<ChargeRule__c> chargeRuleList = [ SELECT Id, Name, SRType__c, ChargeType__c, ChargeAmount__c, VATChanges__c FROM ChargeRule__c WHERE SRType__c = 'Property Transfer'
                                                      AND ChargeType__c = 'Transfer Normal' AND IsActive__c = true LIMIT 1 ];
                
                if (!chargeRuleList.isEmpty()) {
                    ChargeRule__c rule = chargeRuleList[0];
                    Decimal chargeAmount =  rule.ChargeAmount__c ?? 0;
                    Decimal vatPercent   = rule.VATChanges__c ?? 0;
                    this.transferFee = (chargeAmount + (chargeAmount * vatPercent / 100)).round();
                } else {
                    this.transferFee = 0;
                }
            } catch (Exception e) {
                this.transferFee = 0;
                System.debug('⚠️ Error calculating transfer fee: ' + e.getMessage());
            }
        }
    }
    public class SalesOrderModel {
        public SalesOrder__c salesOrder                                                         {get;set;}
        public Decimal totalOutstanding                                                         {get;set;}
        public Decimal amountPaid                                                               {get;set;}
        public Decimal totalInvestment                                                          {get;set;}
        public Decimal ownerPercentage                                                          {get;set;}
        public String projectLocation                                                           {get;set;}
        public String type                                                                      {get;set;}
        public String unitType                                                                  {get;set;}
        public Boolean eligibleForResale                                                        {get;set;}
        public Boolean hasActiveResaleCase                                                      {get;set;}
        public String customerResellPreference                                                  {get;set;}
        public String unitCategory                                 {get;set;}  // Added UnitCategory__c on Apr 14, 2025 by Neelesh : OB-2266 : desc:: Added for furniture project
        public Boolean eligibleForPropertyTransfer { get; set; } // Added by Daksh - Property Transfer Logic
        
        public SalesOrderModel(SalesOrder__c salesOrder, String accId) {
            this.salesOrder = salesOrder;
            this.unitCategory = salesOrder.UnitCategory__c;   // Added UnitCategory__c on Apr 14, 2025 by Neelesh : OB-2266 : desc:: Added for furniture project
            this.totalOutstanding = salesOrder.OutstandingAmount__c;
            if (this.totalOutstanding <= Decimal.valueOf(System.Label.BufferOutstandingAmount)) {
                this.totalOutstanding = 0;
            }
            for (SalesOrderOtherCharges__c otherCharge: salesOrder.SalesOrdersOtherCharges__r) {
                if (otherCharge.OutstandingAmount__c > Decimal.valueOf(System.Label.BufferOutstandingAmount) && otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES) {
                    totalOutstanding += otherCharge.OutstandingAmount__c;
                }
            }
            this.totalInvestment = salesOrder.NetAmount__c;
            this.amountPaid = (this.totalOutstanding == 0 ? this.totalInvestment : salesOrder.TotalBilled__c);
            this.projectLocation = salesOrder.Unit__r.Project__r.Name + (String.isNotBlank(salesOrder.Unit__r.Project__c) && String.isNotBlank(salesOrder.Unit__r.Project__r.City__c) ? ', ' + salesOrder.Unit__r.Project__r.City__c : '');
            this.type = salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT ? CustomerAPIConstants.UNIT_TYPE_PLOT : salesOrder.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c <= salesOrder.BookingDate__c ? CustomerAPIConstants.UNIT_TYPE_READY : CustomerAPIConstants.UNIT_TYPE_OFF_PLAN;
            this.unitType = salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT ? 'Plot' : salesOrder.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c != null ? 'Ready' : 'Off Plan';
            //this.unitType = salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT ? 'Plot' : salesOrder.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c <= salesOrder.BookingDate__c ? 'Ready' : 'Off Plan';
            if (salesOrder.Account__c == accId) {
                this.ownerPercentage = salesOrder.OwnerSharePercentage__c;
            } else {
                for (JointOwner__c jointOwner: salesOrder.Joint_OwnersSalesOrder__r) {
                    if (jointOwner.Account__c == accId) {
                        this.ownerPercentage = jointOwner.SharePercentage__c;
                        //this.customerResellPreference = jointOwner.Account__r.CustomerResellPreference__c;
                        break;
                    }
                }
            }
            this.customerResellPreference = salesOrder.Account__r.CustomerResellPreference__c;
            /*// eligible for resale flag
Decimal totalOutstanding2 = salesOrder.TotalOutstanding__c != null ? salesOrder.TotalOutstanding__c : 0;
Decimal lastInstallmentRebate = salesOrder.LastInstallmentRebate__c != null ? salesOrder.LastInstallmentRebate__c : 0;
Decimal otherRebateAmount = salesOrder.OtherRebateAmount__c != null ? salesOrder.OtherRebateAmount__c : 0;
if(totalOutstanding2 + Decimal.valueOf(System.Label.BufferOutstandingAmount) > (lastInstallmentRebate + otherRebateAmount)){
this.eligibleForResale = true;
}*/
            // has active resale case flag
            this.hasActiveResaleCase = (salesOrder.Cases__r != null && salesOrder.Cases__r.size() > 0) ? true : false;
            // ---------------------------------------------------
            // Eligible For Property Transfer logic
            // ---------------------------------------------------
            this.eligibleForPropertyTransfer = true; // default true
            
            try {
                if (salesOrder.HoldFlag__c == true || salesOrder.OwnerSharePercentage__c != 100) {
                    this.eligibleForPropertyTransfer = false;
                }else{
                    List<HexaBPM__Service_Request__c> srList = [
                        SELECT Id, SRType__c, HexaBPM__External_SR_Status__r.Name
                        FROM HexaBPM__Service_Request__c
                        WHERE Unit__c =:salesOrder.Unit__c AND
                        SRType__c IN ('Property Transfer (Off Plan)', 'SPA Registration')
                    ];
                    Boolean hasSPAClosed = false;
                    Integer ptCount = 0;
                    Boolean hasValidPT = false;
                    Boolean hasInvalidPT = false;
                    
                    for (HexaBPM__Service_Request__c sr : srList) {
                        String st = sr.HexaBPM__External_SR_Status__r.Name != null ?sr.HexaBPM__External_SR_Status__r.Name.toLowerCase() : '';
                        if (sr.SRType__c == 'SPA Registration') {
                            if (st == 'closed') {
                                hasSPAClosed = true;
                            }
                        }
                        
                        if (sr.SRType__c == 'Property Transfer (Off Plan)') {
                            ptCount++;
                            if (st == 'closed' || st == 'cancelled' || st.contains('reject')) {
                                hasValidPT = true;
                            } else {
                                hasInvalidPT = true;
                            }
                        }
                    }
                    
                    if (!hasSPAClosed) {
                        this.eligibleForPropertyTransfer = false;
                    }else if (ptCount == 0 && hasSPAClosed) {
                        this.eligibleForPropertyTransfer = true;
                    }else if (hasInvalidPT) {
                        this.eligibleForPropertyTransfer = false;
                    }else if (hasSPAClosed && hasValidPT && !hasInvalidPT) {
                        this.eligibleForPropertyTransfer = true;
                    }else {
                        this.eligibleForPropertyTransfer = false;
                    }
                }
                
            } catch (Exception e) {
                this.eligibleForPropertyTransfer = true; // fallback safe
                System.debug('Error computing eligibleForPropertyTransfer: ' + e.getMessage());
            }
        }
    }

    //V1.1 Added by Protiviti  Starts here
    public class AuthenticationDataWrapper {//wrapper for creating response for Login API.
        public Account account;
        public ErrorWrapper error;
        public Map<String, Object> contact; // Flattened contact map
        
        public Map<String, Object> toApiResponse() {
            Map<String, Object> response = new Map<String, Object>();
            if (account != null) {
                Map<String, Object> accMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.Serialize(account));
                response.putAll(accMap);
            } 
            response.put('contact', contact );
            response.put('error', error  );
            return response;
        }
    }

    public class ErrorWrapper {//wrapper for capturing data when error occur.
        public Integer errorCode;
        public String message;
        public ErrorWrapper(Integer code, String msg) {//constructor with parameter
            errorCode = code;
            message = msg;    
        }
    }

    //V1.1 Added by Protiviti  End here
    
    //Added by Tajinkumar Start
    public static boolean getActiveAccounts(List<Account> getAccountList,AuthenticationDataWrapper authenticationWrapper, Boolean isValid){
        if(!getAccountList.isEmpty() && getAccountList.size() > 1){  
            Integer count = 0;
            for(Account acc : getAccountList){
                if(!acc.Opportunity_Units__r.isEmpty()) {
                    authenticationWrapper.account = acc;
                    isValid = true;
                    count++;
                }
                if(count > 1){
                    isValid = false;
                }
            }
        }
        return isValid;
    } 
    
    @future
    public static void insertCase(String createCaseRecord) {
        if(!String.isBlank(createCaseRecord)){
            Case newCaseToCreate = (Case) JSON.deserialize(createCaseRecord, Case.class);
            try{
                insert newCaseToCreate;
            }
            catch(exception ex){
                LoggerService.save(LoggerService.addApexLog(ex,'DuplicateAccountCaseCreation','CustomerProfileWebservice','getProfileData'));
            }
        }
    }
    //Added by Tajinkumar End
}