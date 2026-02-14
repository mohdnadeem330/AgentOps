public with sharing class AccountTriggerHandler extends TriggerHandler{
    public static Boolean skipAccountTrigger = false;
    
    private static set<Id> currentUserProfileIdDetails = null;
    // Added By Moh Sarfaraj for BPE-164
    public static Set<Id> setAccountIdsToSendBankDetailsToERP = new Set<Id>();
    
    public static Map<String, String> stateToCityMap = new Map<String, String>{'AJ' => 'Ajman', 'AZ' => 'Abu Dhabi', 'DU' => 'Dubai', 'EK' => 'Ras Al Khaimah', 'FU' => 'Fujairah', 'SH' => 'Sharjah', 'UQ' => 'Umm Al Quwain'};
        public List<String> CustomerSubTypes = System.Label.CustomerSubTypes.split(',');
    public List<String> ProfileNames = System.Label.ProfileNames.split(',');
    public static String ACCOUNT_CUSTOMER_SUB_TYPE_CORPORATE = 'CORPORATE'; // Changes Related to ASF-3387
    public static String ACCOUNT_CUSTOMER_SUB_TYPE_WEALTH = 'WEALTH'; // Changes Related to ASF-3387
    // public static Map<Id,User> LOGIN_USER_PROFILE_MAP; // static variable to keep the login user's profile name
    public static User usr;
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        
        // check usr variable already has login user's details or not: Bashim
        if(usr == null){
            usr = Utilities.getLoggedInUserDetail();
        }
        
        
        if(!TriggerControlVariables.stopTriggerForDuplicates){
            AccountService.updateUniqueKeys(newList);
            AccountMergeUtility.checkForDuplicateAccounts(newList);
        }
        
        for(Account acc : (List<Account>)newList){
            
            /* Added by Cloudzlab*/
            if(acc.CustomerVertical__c!=null)
            {
                List<String> selections = acc.CustomerVertical__c.split(';');
                if (selections.contains('Aldar Estates'))
                {
                    acc.ECSS_Aldar_Estate__c = true;
                }
            } /* End */
            else{
                //Added by Chirag START
                CustomerVertical__c cvt = CustomerVertical__c.getInstance(usr.Profile.Name);
                if(cvt != null && cvt.bypass__c == false && (acc.CustomerVertical__c=='' || acc.CustomerVertical__c== null)){
                    acc.CustomerVertical__c= cvt.Default_Vertical__c;
                }
                //Added by Chirag END
            }
            
            
            if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID || acc.RecordTypeId == Constants.ORGANIZATION_RECORD_TYPE_ID){
                if(acc.BillingCountry == 'United Arab Emirates' && acc.BillingStateCode != null ){
                    acc.BillingCity = stateToCityMap.get(acc.BillingStateCode);
                }
                if(acc.ShippingCountry == 'United Arab Emirates' && acc.ShippingStateCode != null){
                    acc.ShippingCity = stateToCityMap.get(acc.ShippingStateCode);
                }
            }
            
            if(CustomerSubTypes.contains(acc.CustomerSubType__c)  && ProfileNames.contains(usr.Profile.Name) && UtilitiesWithoutSharing.bypassValidation){
                acc.addError(System.Label.CustomerSubType_ValidationError);
            }
            
            if (acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID) {
                acc.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            }
            //Added by Chirag SFMC    
            /*  if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID){
acc.Sync_with_SFMC__pc = true;
}
if(acc.RecordTypeId == Constants.ORGANIZATION_RECORD_TYPE_ID || acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID){
acc.Sync_with_SFMC__c = true;
} */
            //END by CHirag SFMC
			
			//Added by Rijwan SFMC
            Set<String> existingVerticals = acc.CustomerVertical__c == NULL || String.isBlank(acc.CustomerVertical__c) ? new Set<String>() : new Set<String>(acc.CustomerVertical__c.split(';'));
            UnifiedAccountController.setCustomerVerticalCheckboxes(acc, existingVerticals);
            //END by Rijwan SFMC

            Boolean isResident = acc.ResidentStatus__pc == 'Resident';
            Boolean isNonResident = acc.ResidentStatus__pc == 'Non-Resident';
            Boolean visaNotApplicable = acc.VisaType__c == 'Visa not applicable';
            
            if (!LeadTriggerHandler.isLeadInvolve && isResident && visaNotApplicable) {
                acc.addError('If Resident, VisaType cannot be Visa not applicable.');
            } else if (!LeadTriggerHandler.isLeadInvolve && isNonResident && !visaNotApplicable && acc.VisaType__c != NULL) {
                acc.addError('If Non-Resident, VisaType must be Visa not applicable.');
            }
        }
        checkAndUpdateShippingAddress(newList);
        updateArabicValue(newList);
        if(currentUserProfileIdDetails == null){
            currentUserProfileIdDetails = Utilities.getSimillarProfileIds(Constants.CUSTOMER_MGMT_PROFILE);
        }
        if(!currentUserProfileIdDetails.isEmpty() && currentUserProfileIdDetails.contains(userinfo.getProfileId())){
            duplicateAccountPrevention(newList,null);
        }
        if(!Label.ProfilesToBypassDuplicateLogic.contains(usr.Profile.Name) && !SearchBrokerLeads.bypassDuplicateLogic){
            duplicateCheck(newList,null);
        }
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap)
    {
        // check usr variable already has login user's details or not: Bashim
        if(usr == null){
            usr = Utilities.getLoggedInUserDetail();
        }
        List<Account> accountsToBeShared = new List<Account>();
        Set<Id> AccountOwnerIdSet = new Set<Id>();
        Set<Id> oldSubAccountManagerIds = new Set<Id>();
        //Added by Chirag
        Set<String> Emailset =new Set<String>();
        List<Account> accountDocumentsToBeShared = new List<Account>();
        
        // @story ASF-3613 VIP Automation Changes Get all account owner ids
        
        Set<Id> accountOwnerIds = new Set<Id>();
        for(Account acc : (List<Account>)newList){
            if(acc.VIP_Change_Apporval_Status__c != acc.VIP_Change_Apporval_Status__c && acc.VIP_Change_Apporval_Status__c == 'Approved'){
                accountOwnerIds.add(acc.OwnerId);
            }

            Boolean isResident = acc.ResidentStatus__pc == 'Resident';
            Boolean isNonResident = acc.ResidentStatus__pc == 'Non-Resident';
            Boolean visaNotApplicable = acc.VisaType__c == 'Visa not applicable';
            
            if (!LeadTriggerHandler.isLeadInvolve && isResident && visaNotApplicable) {
                acc.addError('If Resident, VisaType cannot be Visa not applicable.');
            } else if (!LeadTriggerHandler.isLeadInvolve && isNonResident && !visaNotApplicable && acc.VisaType__c != NULL) {
                acc.addError('If Non-Resident, VisaType must be Visa not applicable.');
            }
        } 
        
        // @story ASF-3613 VIP Automation Changes Query users once and store in a map
        Map<Id, User> accountOwnerMap = new Map<Id, User>();
        if(!accountOwnerIds.isEmpty()){
            accountOwnerMap = Utilities.getOwnersDetail(accountOwnerIds);
        } 
        
        // @story ASF-3613 VIP Automation Changes Query users once
        
        /* Map<Id, User> accountOwnerMap = new Map<Id, User>([SELECT Id, IsActive, Profile.Name 
FROM User 
WHERE Id IN :accountOwnerIds]);*/

        // @story FIN-54 Integration callouts will only be triggered when specific fields from Account_Integration_Field__mdt are changed, as part of sai Kumar changes
        // Query integration fields from custom metadata
        Map<String, Account_Integration_Fields__c> brokerFields = new Map<String, Account_Integration_Fields__c>();
        Map<String, Account_Integration_Fields__c> customerFields = new Map<String, Account_Integration_Fields__c>();
        
        if (Label.Account_Integration_Field_Check == 'true') {
            for(Account_Integration_Fields__c field : Account_Integration_Fields__c.getAll().values()) {
                if(field.Is_Active__c && field.Integration_Type__c == 'Broker_Agency') {
                    brokerFields.put(field.API__c, field);
                } else if(field.Is_Active__c && field.Integration_Type__c == 'Customer') {
                    customerFields.put(field.API__c, field);
                }
            }
        }
        
        for (Account acc : (List<Account>)newList) {
            Account oldAcc2 = (Account)oldMap.get(acc.Id);
            
            if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID || acc.RecordTypeId == Constants.ORGANIZATION_RECORD_TYPE_ID){
                if(acc.BillingCountry == 'United Arab Emirates' && acc.BillingStateCode != null &&
                   (acc.BillingStateCode != oldAcc2.BillingStateCode || acc.BillingCity != oldAcc2.BillingCity )){
                       acc.BillingCity = stateToCityMap.get(acc.BillingStateCode);
                   } 
                if(acc.ShippingCountry == 'United Arab Emirates' && acc.ShippingStateCode != null &&
                   (acc.ShippingStateCode != oldAcc2.ShippingStateCode || acc.ShippingCity != oldAcc2.ShippingCity)){
                       acc.ShippingCity = stateToCityMap.get(acc.ShippingStateCode);
                   }  
            }
            if(CustomerSubTypes.contains(acc.CustomerSubType__c)  && ProfileNames.contains(usr.Profile.Name) && UtilitiesWithoutSharing.bypassValidation && oldAcc2.CustomerSubType__c != acc.CustomerSubType__c){
                acc.addError(System.Label.CustomerSubType_ValidationError);
            }
            
            if (acc.SubAccountManager__c != null && acc.SubAccountManager__c != oldAcc2.SubAccountManager__c ){
                AccountOwnerIdSet.add(acc.OwnerId);
                accountsToBeShared.add(acc);
                if(oldAcc2.SubAccountManager__c != null){  oldSubAccountManagerIds.add(oldAcc2.SubAccountManager__c);
                                                        }
            }
            if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID && acc.PersonEmail != null && acc.PersonEmail != oldAcc2.PersonEmail){
                Emailset.add(acc.PersonEmail);
            }
            if(oldAcc2.SubAccountManager__c != null && acc.SubAccountManager__c == null){
                oldSubAccountManagerIds.add(oldAcc2.SubAccountManager__c);accountsToBeShared.add(acc);
            }
            
            if(acc.InterestedInListing__c != null && oldAcc2.InterestedInListing__c != acc.InterestedInListing__c){
                acc.InterestLoggedBy__c = usr.Id;
                acc.InterestDateTime__c = System.now();
            }
            if(acc.OwnerId != oldAcc2.OwnerId){                accountDocumentsToBeShared.add(acc);
                                              }
            
            // Added By Moh Sarfaraj for BPE-164 starts
            if(acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID && String.isNotBlank(acc.ProposedBankDetailStatus__c) && 
               acc.ProposedBankDetailStatus__c != oldAcc2.ProposedBankDetailStatus__c && acc.ProposedBankDetailStatus__c == 'Approved'){
                   
                   acc.OldBankName__c = acc.BankName__c;
                   acc.OldBankAccountNumber__c = acc.BankAccountNumber__c;
                   acc.OldBankCountry__c = acc.BankCountry__c;
                   acc.OldBranchAddress__c = acc.BranchAddress__c;
                   acc.OldIBANNumber__c = acc.IBANNumber__c;
                   acc.OldSwiftCode__c = acc.SwiftCode__c;
                   // Added By Moh Sarfaraj for BPM-428
                   acc.OldBeneficiaryName__c = acc.BeneficiaryName__c;
                   
                   acc.BankName__c = acc.ProposedBankName__c;
                   acc.BankAccountNumber__c = acc.ProposedBankAccountNumber__c;
                   acc.BankCountry__c = acc.ProposedBankCountry__c;
                   acc.BranchAddress__c = acc.ProposedBranchAddress__c;
                   acc.IBANNumber__c = acc.ProposedIBANNumber__c;
                   acc.SwiftCode__c = acc.ProposedSwiftCode__c;
                   // Added By Moh Sarfaraj for BPM-428
                   acc.BeneficiaryName__c = acc.ProposedBeneficiaryName__c;
                   
                   setAccountIdsToSendBankDetailsToERP.add(acc.Id);
               }
            //Changes related ASF-3387 starts here
            if((acc.CustomerSubType__c !=ACCOUNT_CUSTOMER_SUB_TYPE_CORPORATE && acc.CustomerSubType__c !=ACCOUNT_CUSTOMER_SUB_TYPE_WEALTH)&& acc.CustomerSubType__c !=  oldAcc2.CustomerSubType__c){
                acc.CorporateWealthName__c = '';
            }
            //Changes related ASF-3387 End here
            if(acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID && String.isNotBlank(acc.ProposedBankDetailStatus__c) && 
               acc.ProposedBankDetailStatus__c == 'ERP NotSynced'){
                   
                   setAccountIdsToSendBankDetailsToERP.add(acc.Id);
               }
            // Added By Moh Sarfaraj for BPE-164 end
           
            //@story ASF-3613 VIP Automation Changes
            
            if(acc.VIP_Change_Apporval_Status__c != acc.VIP_Change_Apporval_Status__c && acc.VIP_Change_Apporval_Status__c == 'Approved'){
                
                // Validate account owner is active and Sales Manager
                User accOwner = accountOwnerMap.get(acc.OwnerId);
                if(!accOwner.IsActive || accOwner.Profile.Name != 'Sales Manager'){
                    acc.addError('Account owner must be an active Sales Manager to approve VIP Class changes');
                }
                acc.VIP_Status_Updated_on__c = System.now();
                acc.Is_VIP_Status_Updated__c = true;
                acc.Previous_VIP_Class__c = acc.VIPClass__c;
                acc.Previous_Customer_Type__c = acc.CustomerType__c;
                acc.Previous_Customer_Sub_Type__c = acc.CustomerSubType__c;
                acc.VIPClass__c = acc.Proposed_New_VIP_Class__c;
                acc.CustomerType__c = acc.Proposed_New_Customer_Type__c;
                acc.CustomerSubType__c = acc.Proposed_New_Customer_Sub_type__c;
            }
        } 
        // Duplicate account related changes
        if(!Label.ProfilesToBypassDuplicateLogic.contains(usr.Profile.Name) && !SearchBrokerLeads.bypassDuplicateLogic){
            duplicateCheck(newList,oldMap);
        }
        /*if(!accountDocumentsToBeShared.isEmpty()){           documentShareWithAccountOwner(accountDocumentsToBeShared);
}*/
        accountSharewithSubManagers(AccountOwnerIdSet, accountsToBeShared, oldSubAccountManagerIds);
        //Added by Chirag
        Map<String,List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>DuplicateEmailMap = new Map<String,List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>();
        if(Emailset.size()>0){
            DuplicateEmailMap=UtilitiesWithoutSharing.findDuplicateAccountsByEmail(Emailset);
        }
        if(!TriggerControlVariables.stopTriggerForDuplicates){
            AccountService.updateUniqueKeys(newList);
            AccountMergeUtility.checkForDuplicateAccounts(newList);
        }
        //commented for deployment - Rohit
        //Boolean isNameUpdated = false;
        if(currentUserProfileIdDetails == null){
            currentUserProfileIdDetails = Utilities.getSimillarProfileIds(Constants.CUSTOMER_MGMT_PROFILE);
        }
        for(Account acc : (List<Account>)newList){
            Account oldAcc = (Account)oldmap.get(acc.Id);
            /*if (acc.AgencyStatus__c != oldAcc.AgencyStatus__c) {
acc.PreviousAgencyStatus__c = oldAcc.AgencyStatus__c;
}*/
            if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && acc.SyncTime__c == oldAcc.SyncTime__c && acc.SyncStatus__c == Constants.STATUS_SYNCED) {
                // @story FIN-54 Integration callouts will only be triggered when specific fields from Account_Integration_Field__mdt are changed
                if (Label.Account_Integration_Field_Check == 'true') {
                    handleIntegrationFieldChanges(acc, oldAcc, brokerFields, customerFields);
                } else {
                    // Original behavior when feature flag is disabled
                    acc.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
                    acc.IsBrokerChange__c = true;
                }
            }
            if (!acc.IsBrokerChange__c && acc.IsAgentChange__c == oldAcc.IsAgentChange__c) {
                acc.IsBrokerChange__c = true;
            }
            //Added by Chirag
            if(DuplicateEmailMap.get(acc.PersonEmail) != null){
                acc.hasDuplicateEmail__c = true;
            }
            if(!currentUserProfileIdDetails.isEmpty() && currentUserProfileIdDetails.contains(userinfo.getProfileId()) && (acc.NationalIdNumber__pc!=oldAcc.NationalIdNumber__pc || acc.PassportNumber__pc!=oldAcc.PassportNumber__pc)){
                duplicateAccountPrevention(newList,oldMap);
            }
            // Added by Rijwan via Partial Commit using Copado CLI
            if(acc.Merging_Status__c != oldAcc.Merging_Status__c && acc.Merging_Status__c == 'Rejected') {
                acc.EligibleForMerge__c = false;
                acc.MasterAccount__c = NULL;
            }
      
            Set<String> existingVerticals = acc.CustomerVertical__c == NULL ||                  String.isBlank(acc.CustomerVertical__c) ? new Set<String>() : new Set<String>(acc.CustomerVertical__c.split(';'));
            UnifiedAccountController.setCustomerVerticalCheckboxes(acc, existingVerticals);
			
            /*Commented for deployment -Rohit
if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && (acc.FirstName != oldAcc.FirstName || acc.LastName != oldAcc.LastName || acc.Name != oldAcc.Name)) {
isNameUpdated = true;
}*/
        }
        /*Comment for Deployment - Rohit
if (isNameUpdated) {
checkNameUpdation(newList, oldMap);
}*/
        checkAndUpdateShippingAddress(newList);
        updateArabicValue(newList);      
        KYCValidityController.populateKycStatusIfKycMandatoryFieldsUpdated(newMap, oldMap);
        // Added By Moh Sarfaraj for BPE-164
        updateApprovalComments(newList, oldMap);
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        list<Account> accountToProcess = new list<Account>();
        for(Account acc : (List<Account>)newList){
            if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID || ( acc.RecordTypeId == Constants.ORGANIZATION_RECORD_TYPE_ID && acc.Type != 'Contractor')){
                accountToProcess.add(acc);
            }
        }
        if(!accountToProcess.isEmpty()){
            createAccountDocuments(accountToProcess);
        }
        changeAccountContactRelationship(newList,null);
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        
        List<Id> accIds = new List<Id>();
        List<Id> accInvoiceIdSet = new List<Id>();
        List<Id> callAppSystemAccIdSet = new List<Id>();
        List<Id> custIds = new List<Id>();
        List<Id> blockedUsersAccountIds = new List<Id>();        
        List<Id> activeUsersAccountIds = new List<Id>();
        Map<Id, Id> agentsChangedAccountIds = new Map<Id, Id>();
        List<Account> accountRecords = new List<Account>();
        list<Account> accountToProcess = new list<Account>();
        Map<Id, Id> accountIdWithSubManagerNew = new Map<Id, Id>();
        Map<Id, Id> accountIdWithSubManagerOld = new Map<Id, Id>();
        // Commented by Moh Sarfaraj for deployment
        //        List<String> emailRecipients    = new List<String>();//Added by Sarah on Mar 29, 2024 for LIVEICE-530
        //        Set<Id> accountIds              = new Set<Id>();//Added by Sarah on Mar 29, 2024 for LIVEICE-530
        
        // Added By Moh Sarfaraj for BPM-391
        Set<Id> setSuspendedAgencyIds = new Set<Id>();
        Set<Id> setActiveSuspendedAgencyIds = new Set<Id>();
        // Added by Rijwan via Partial Commit using CLI
        Set<Id> mergeAccountIdsERP = new Set<Id>();
        Set<Id> directmergeAccountIds = new Set<Id>();
        
        //added by Dharnesh for nintex doc issue Start
        List<Id> accIdsForJoSrUpdate = new List<Id>();
        //added by Dharnesh for nintex doc issue End
        
        for (Account acc: (List<Account>) newList) {
            Account oldAccount = (Account)oldmap.get(acc.Id);
            // Commented by Moh Sarfaraj for deployment
            /*if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID && acc.isCustomerAppLocked__c && acc.isCustomerAppLocked__c != oldAccount.isCustomerAppLocked__c) {//Added by Sarah on Mar 29, 2024 for LIVEICE-530
accountIds.add(acc.Id);
emailRecipients.add(acc.PersonEmail);
}*/
            String CustomerVertical = acc.CustomerVertical__c !=null ? acc.CustomerVertical__c:'No Value';
            // Added by rajat jain SERVICE-765 if condition 
            if(!CustomerVertical.contains('Government')){
                if (acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID && acc.AgencyStatus__c != Constants.PENDING_VERIFICATION && acc.SyncStatus__c == Constants.STATUS_IN_PROGRESS) {
                    accIds.add(acc.Id);
                } else if (acc.SyncStatus__c == Constants.STATUS_IN_PROGRESS && acc.ERPID__c != null) {
                    custIds.add(acc.Id);
                }
            }
            /*if (acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID && acc.AgencyStatus__c != Constants.PENDING_VERIFICATION && acc.SyncStatus__c == Constants.STATUS_IN_PROGRESS) {
accIds.add(acc.Id);
} else if (acc.SyncStatus__c == Constants.STATUS_IN_PROGRESS && acc.ERPID__c != null) {
custIds.add(acc.Id);
}*/
            if ( acc.AgencyStatus__c == Constants.UNIT_STATUS_BLOCKED &&  acc.AgencyStatus__c != oldAccount.AgencyStatus__c) {
                blockedUsersAccountIds.add(acc.Id);
            }
            // Updated by Moh Sarfaraj for BPM-391
            if ( acc.AgencyStatus__c == Constants.ACTIVE && oldAccount.AgencyStatus__c != 'Suspended' && acc.AgencyStatus__c != oldAccount.AgencyStatus__c) {
                activeUsersAccountIds.add(acc.Id);
            }
            if(acc.BrokerAgent__c != null && acc.BrokerAgent__c != oldAccount.BrokerAgent__c && oldAccount.BrokerAgent__c != null){
                agentsChangedAccountIds.put(acc.Id, oldAccount.BrokerAgent__c);
            }
            if((acc.NationalIdNumber__pc != oldAccount.NationalIdNumber__pc && acc.NationalIdNumber__pc != '') || (acc.PassportNumber__pc != oldAccount.PassportNumber__pc  && acc.PassportNumber__pc != '')  || (acc.RegistrationNumber__c != oldAccount.RegistrationNumber__c && acc.RegistrationNumber__c != '')){
                accountRecords.add(acc);
            }
            if(acc.CustomerType__c != null && acc.CustomerType__c != oldAccount.CustomerType__c && acc.CustomerType__c.trim().equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) ){
                accountToProcess.add(acc);
            }
            if (acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID){
                if(acc.UAEVATRegisterNumber__c != oldAccount.UAEVATRegisterNumber__c) {
                    accInvoiceIdSet.add(acc.Id);
                }
                if(acc.SubAccountManager__c != null && acc.SubAccountManager__c != oldAccount.SubAccountManager__c) {
                    accountIdWithSubManagerNew.put(acc.Id, acc.SubAccountManager__c);
                }
                if(oldAccount.SubAccountManager__c != null && acc.SubAccountManager__c != oldAccount.SubAccountManager__c){
                    accountIdWithSubManagerOld.put(acc.Id, oldAccount.SubAccountManager__c);
                }
            }
            //Added by Tharun as per BPM-346
            if (acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID && 
                (acc.BrokerClassification__c != oldAccount.BrokerClassification__c) ||
                (acc.AllowAdditionalAppointmentSlots__c != oldAccount.AllowAdditionalAppointmentSlots__c) || 
                (acc.AgencyStatus__c != oldAccount.AgencyStatus__c) || 
                (acc.AdditionalAppointmentSlots__c  != oldAccount.AdditionalAppointmentSlots__c) || 
                (acc.AllowDigitalSale__c != oldAccount.AllowDigitalSale__c) || 
                (acc.Name != oldAccount.Name) ||
                (acc.BillingCountry != oldAccount.BillingCountry)) {
                    callAppSystemAccIdSet.add(acc.Id);
                    if(acc.AgencyStatus__c == Constants.ACTIVE && oldAccount.AgencyStatus__c == 'Suspended' ){
                        setActiveSuspendedAgencyIds.add(acc.Id); 
                    }
                    if (acc.AgencyStatus__c == Constants.SUSPENDED &&  acc.AgencyStatus__c != oldAccount.AgencyStatus__c) {
                        setSuspendedAgencyIds.add(acc.Id);
                    }
                }
            //Added by Chirag
            if(acc.CustomerSubType__c != null && acc.CustomerSubType__c != oldAccount.CustomerSubType__c && acc.CustomerSubType__c.trim().equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_SUBTYPE_CORPORATE) ){
                accountToProcess.add(acc);
            }
            // Added by Rijwan via Partial Commit using Copado CLI
            if(acc.Merging_Status__c != oldAccount.Merging_Status__c && ((acc.Merging_Status__c == 'Approved' && acc.ERPID__c == NULL) || (acc.Merging_Status__c == 'ERP Merge Completed'))) {
                directmergeAccountIds.add(acc.Id);
            } else if(acc.Merging_Status__c != oldAccount.Merging_Status__c && acc.Merging_Status__c == 'Approved' && acc.ERPID__c != NULL) {
                mergeAccountIdsERP.add(acc.Id);
            }
            // Added By Moh Sarfaraj for BPM-391
            /*if (acc.AgencyStatus__c == 'Suspended' &&  acc.AgencyStatus__c != oldAccount.AgencyStatus__c) {
setSuspendedAgencyIds.add(acc.Id);
}
// Added By Moh Sarfaraj for BPM-391
if (acc.AgencyStatus__c == Constants.ACTIVE && oldAccount.AgencyStatus__c == 'Suspended' && acc.AgencyStatus__c != oldAccount.AgencyStatus__c) {
setActiveSuspendedAgencyIds.add(acc.Id);
callAppSystemAccIdSet.add(acc.Id);
} */
            
            
            //added by Dharanesh for nintex doc issue Start
            if(acc.FirstName != oldAccount.FirstName || acc.MiddleName != oldAccount.MiddleName ||
               acc.LastName != oldAccount.LastName || acc.Name != oldAccount.Name ||acc.NameInArabic__c != oldAccount.NameInArabic__c || 
               acc.Nationality__pc != oldAccount.Nationality__pc || acc.NationalityinArabic__pc != oldAccount.NationalityinArabic__pc
               ||acc.PassportNumber__pc!=oldAccount.PassportNumber__pc ) {
                   accIdsForJoSrUpdate.add(acc.Id);
               }
            
            //added by Dharanesh for nintex doc issue End
        }
        
        //added by Dharanesh for nintex doc issue Start
        
        if (!accIdsForJoSrUpdate.isempty()){
            List<JointOwner__c> jo = [SELECT Id FROM JointOwner__c WHERE Account__c IN :accIdsForJoSrUpdate];
            List<AgencyTeam__c> sr = [SELECT Id FROM AgencyTeam__c WHERE Account__c IN :accIdsForJoSrUpdate];
            if (!jo.isempty()){
                update jo;
            } 
            
            if (!sr.isempty()){
                update sr;
            }
        }
        
        //added by Dharanesh for nintex doc issue End
        
        // Commented by Moh Sarfaraj for deployment
        
        /*  if(accountIds != null && !accountIds.isEmpty()) {//Added by Sarah on Mar 29, 2024 for LIVEICE-530
UtilitiesWithoutSharing.sendWhatsAppMessage(accountIds, 'Test Customer Name', '5UT_project_5bed', 'Test', '1234567', 'MarketingComms', 'DynamicURL', 'any-attribute-2', 'any-attribute-3', 'any-attribute-4', 'any-attribute-5', 'test', 'test', 'test', 'test', 'test', 'Customer_App_Locker');
}

if(emailRecipients != null && !emailRecipients.isEmpty()) {//Added by Sarah on Mar 29, 2024 for LIVEICE-530
EmailTemplate template = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'UnsuccessfulLoginEmailTemplate' LIMIT 1];
OrgWideEmailAddress owEmail = [SELECT Address,Id FROM OrgWideEmailAddress WHERE Address = 'customercare@aldar.com' LIMIT 1];

Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setTargetObjectId(UserInfo.getUserId());
email.setTemplateId(template.Id);
email.setSaveAsActivity(false);
email.setToAddresses(emailRecipients);
email.setOrgWideEmailAddressId(owEmail.Id);
List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
for(Messaging.SendEmailResult result : emailResults) {
if(!result.isSuccess()) {
for(Messaging.SendEmailError err:result.getErrors()){
System.debug('Error on AccountTriggerHanlder - Error Message:' +err.message);
}
}
}
}*/
        
        if(!accountRecords.isEmpty()){ updateDDRIds(accountRecords);
                                     }
        
        // To share the Account Record with all Agency Admin Related to the new BrokerAgent__c.
        if(!agentsChangedAccountIds.isEmpty()){
            ShareHelper.shareAccountRecordWhenBrokerAgentChanged(agentsChangedAccountIds, Constants.READ_ACCESS);
        }
        
        User usr = Utilities.getLoggedInUserDetail();
        if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !accIds.isEmpty()) {
            AccountCalloutHelper.PrepareDataForCallout(accIds);
        } else if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !custIds.isEmpty()) {
            CustomerCalloutHelper.PrepareDataForCallout(custIds, new List<Id>(), '');
        }
        if (!blockedUsersAccountIds.isEmpty()) {
            AccountService.blockedAgencyUsersActions(blockedUsersAccountIds, true);
        }
        if (!activeUsersAccountIds.isEmpty()) {
            AccountService.blockedAgencyUsersActions(activeUsersAccountIds, false);
        }
        changeAccountContactRelationship(newList, oldMap);
        if(!accountToProcess.isEmpty()){
            createAccountDocuments(accountToProcess);
        }
        if(!accInvoiceIdSet.isEmpty()){
            updateInvoiceBundle(accInvoiceIdSet);
        }
        
        // Added By Moh Sarfaraj for BPE-164
        requestedBankDetailUpdatedStatus(newList, oldMap);
        
        //Added by Tharun as per BPM-346
        if(!callAppSystemAccIdSet.isEmpty()){
            AppointmentController.processNewBrokerAgency(callAppSystemAccIdSet);
        }
        
        // Added By Moh Sarfaraj for BPM-391 start
        if(!setSuspendedAgencyIds.isEmpty()){
            suspendActiveAgencyRelatedAgents(setSuspendedAgencyIds, 'Active');
        }
        
        if(!setActiveSuspendedAgencyIds.isEmpty()){
            suspendActiveAgencyRelatedAgents(setActiveSuspendedAgencyIds, 'Suspended');
        }
        // Added By Moh Sarfaraj for BPM-391 end
        System.debug('Check KP '+ accountIdWithSubManagerNew.keySet().isEmpty());
        if(!accountIdWithSubManagerNew.keySet().isEmpty()){
            VFSSharingHelper.shareInvoicesAndCommisionsWithVFSTeam(accountIdWithSubManagerNew.keySet());
        }
        if(!accountIdWithSubManagerOld.keySet().isEmpty()){
            VFSSharingHelper.removeShareForVFSTeam(accountIdWithSubManagerOld);
        }
        
        // Start SR Step automation
        map<string, HexaBPM__Status__c> stepStatusMap = new map<string, HexaBPM__Status__c>();
        for (HexaBPM__Status__c srStepStatus : [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name IN ('Completed')]) {
            stepStatusMap.put(srStepStatus.Name, srStepStatus);
        }
        List<HexaBPM__Step__c> srStepsToUpdateList = new List<HexaBPM__Step__c>();
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : (List<Account>)newList){
            accountIds.add(acc.Id);      
        }
        if(!accountIds.IsEmpty()){
            list<HexaBPM__Service_Request__c> relatedSR = [SELECT ID FROM HexaBPM__Service_Request__c WHERE BuyerName__c IN:accountIds AND origin__c='Customer Portal' and srtype__c='Property Transfer NOC'];
            system.debug('relatedSR::'+relatedSR);
            if(!relatedSR.IsEmpty()){
                for(HexaBPM__Step__c srStep : [SELECT Id,HexaBPM__Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c =: relatedSR[0].Id AND HexaBPM__Summary__c = 'Verification of Buyer Profile' AND HexaBPM__Step_Status__c = 'Pending']){
                    srStep.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;
                    srStepsToUpdateList.add(srStep);
                    system.debug('srStepsToUpdateList ::'+srStepsToUpdateList);
                    
                }
            }
        }
        if(!srStepsToUpdateList.IsEmpty()){
            update srStepsToUpdateList;
            system.debug('Updated succesfully ::'+srStepsToUpdateList[0]);
        }
        // Added by Rijwan via Partial Commit using Copado CLI
        if(!directmergeAccountIds.isEmpty()) {
            List<Id> mergeAccountIdsList = new List<Id>(directmergeAccountIds);
            StartBatchProcess__e event = new StartBatchProcess__e(BatchType__c = 'MergeCustomersBatchNew', RecordIds__c = String.join(mergeAccountIdsList, ','));
            EventBus.publish(event);
        }
        if(!mergeAccountIdsERP.isEmpty()) {
            //submit Account for ERP system
            MergeAccount.processMergeRequest(mergeAccountIdsERP);
        }
    }
    
    /*Commented for Deployment - Rohit
public static void checkNameUpdation(List<SObject> accountList, Map<Id, SObject> accountOldMap) {

List<Id> accIds = new List<Id>();
for(Account acc: (List<Account>)accountList) {
Account oldAcc = (Account)accountOldMap.get(acc.Id);
if ((acc.FirstName != oldAcc.FirstName || acc.LastName != oldAcc.LastName || acc.Name != oldAcc.Name)) {
accIds.add(acc.Id);
}
}

List<JointOwner__c> jointOwnerList = [SELECT Id, SalesOrder__c, Account__c, SharePercentage__c FROM JointOwner__c WHERE Account__c IN: accIds AND SharePercentage__c > 0];
List<String> soIds = new List<String>();
for (JointOwner__c jointOwner: jointOwnerList) {
soIds.add(jointOwner.SalesOrder__c);
}

List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
if (!soIds.isEmpty()) {
salesOrderList = [SELECT Id, Account__c FROM SalesOrder__c WHERE (Account__c IN: accIds OR Id IN: soIds) AND Status__c !=: Constants.SO_STATUS_CANCELLED AND Status__c !=: Constants.SO_STATUS_CANCELLED_BY_USER];
} else {
salesOrderList = [SELECT Id, Account__c FROM SalesOrder__c WHERE Account__c IN: accIds AND Status__c !=: Constants.SO_STATUS_CANCELLED AND Status__c !=: Constants.SO_STATUS_CANCELLED_BY_USER];
}

List<String> accIdList = new List<String>();
for (SalesOrder__c salesOrder: salesOrderList) {
accIdList.add(salesOrder.Account__c);
}

for(Account acc: (List<Account>)accountList) {
Account oldAcc = (Account)accountOldMap.get(acc.Id);
if ((acc.FirstName != oldAcc.FirstName || acc.LastName != oldAcc.LastName || acc.Name != oldAcc.Name) && accIdList.contains(acc.Id)) {
acc.addError('Please note name can not be modified');
}
}
}*/
    
    public static void checkAndUpdateShippingAddress(List<Account> accountList) {
        for(Account acc : accountList){
            if (acc.ResidentialAddressSameAsPermanent__c == 'Yes') {
                acc.ShippingStreet = acc.BillingStreet;
                acc.ShippingCity = acc.BillingCity;
                acc.ShippingState = acc.BillingState;
                acc.ShippingPostalCOde = acc.BillingPostalCode;
                acc.ShippingCountry = acc.BillingCountry;
                acc.ShippingStateCode = acc.BillingStateCode;
                acc.ShippingCountryCode = acc.BillingCountryCode;
            }
        }
    }
    
    public static void updateArabicValue(List<Account> accountList) {
        List<ArabicMapping__mdt> arabicMappingList = ArabicMapping__mdt.getall().values();
        Map<String, String> arabibNationalityValue = new Map<String, String>();
        for (ArabicMapping__mdt arabicMapping: arabicMappingList) {
            if (arabicMapping.Type__c == Constants.NATIONALITY) {
                arabibNationalityValue.put(arabicMapping.Label.toUpperCase(), arabicMapping.ArabicValue__c);
            }
        }
        
        for(Account acc : accountList) {
            if (String.isNotBlank(acc.Nationality__pc) && arabibNationalityValue.containsKey(acc.Nationality__pc.toUpperCase())) {
                acc.NationalityinArabic__pc = arabibNationalityValue.get(acc.Nationality__pc.toUpperCase());
            }
        }
    }
    
    public static void changeAccountContactRelationship(List<SObject> newList,Map<Id, SObject> oldMap){
        system.debug('1111 ppp changeAccountContactRelationship'+ newList);
        set<ID> accountRecordsToProcess = new set<ID>();
        Id agencyRecordTypeID = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        
        for(Account newAccount : (list<Account>)newList){
            Account oldAccount = oldMap!=null?(Account)oldmap.get(newAccount.Id):null;
            if(oldAccount==null && newAccount.ParentId !=null && newAccount.RecordTypeId == agencyRecordTypeID){
                accountRecordsToProcess.add(newAccount.ParentId);
            }
            if(oldAccount!=null && newAccount.ParentId != oldAccount.ParentId && newAccount.RecordTypeId == agencyRecordTypeID){
                if( newAccount.ParentId!=null){
                    accountRecordsToProcess.add(newAccount.ParentId);
                }
                if(oldAccount.ParentId!=null) {
                    accountRecordsToProcess.add(oldAccount.ParentId);
                }
            }
        }
        if(!accountRecordsToProcess.isEmpty()){
            recalculateAccountRelationShip(accountRecordsToProcess , true);
        }
    }
    @future
    public static void recalculateAccountRelationShip(set<id> accountIds){
        if(!accountIds.isEmpty()){
            recalculateAccountRelationShip(accountIds , false);
        }
    }
    public static void recalculateAccountRelationShip(set<id> accountIds, boolean isAccountTrigger){
        //get All Agency Users
        set<id> agencyAdmins = new set<id>();
        map<id,set<Id>> accountToAgencyUserSet = new map<id,set<Id>>();
        
        for(User tempU : [select id,AccountID,ContactId from User where AccountId in :accountIds and profile.Name in (:Constants.AGENCY_ADMIN_PROFILE,:Constants.AGENCY_ADMIN_PROFILE_LOGIN) and isActive = true ]){
            //for(User tempU : [select id,AccountID,ContactId from User where AccountId in :accountIds and profile.Name =:Constants.AGENCY_ADMIN_PROFILE and isActive = true ]){
            if(!accountToAgencyUserSet.containsKey(tempU.AccountID)){
                accountToAgencyUserSet.put(tempU.AccountID, new set<ID>());
            }
            accountToAgencyUserSet.get(tempU.AccountID).add(tempU.ContactId);
            agencyAdmins.add(tempU.ContactId);
        }
        
        //get All child Accounts
        set<ID> childAccountIds = new set<ID>();
        map<id,set<Id>> accountToChildAccountSet= new map<id,set<Id>>();
        for(Account accRecordd : [select id,parentID from Account where parentID in :accountIds ]){
            if(!accountToChildAccountSet.containsKey(accRecordd.parentID)){
                accountToChildAccountSet.put(accRecordd.parentID, new set<ID>());
            }
            accountToChildAccountSet.get(accRecordd.parentID).add(accRecordd.id);
            childAccountIds.add(accRecordd.id);
        }
        
        
        //Check if the Sharing exists otherwise create new
        map<string,AccountContactRelation> recordsToCreate = new map<string,AccountContactRelation> ();
        list<AccountContactRelation> recordToDelete = new list<AccountContactRelation>();
        if(isAccountTrigger){
            for(AccountContactRelation acr : [select id,AccountId,ContactId from AccountContactRelation where ContactId in :agencyAdmins and IsDirect=false]){
                if(!childAccountIds.contains(acr.AccountId)){
                    recordToDelete.add(acr);
                }else{
                    recordsToCreate.put(acr.AccountId+'_'+acr.ContactId,acr);
                }
                
            }
        }else{
            for(AccountContactRelation acr : [select id,AccountId,ContactId from AccountContactRelation where AccountId in :childAccountIds and IsDirect=false]){
                if(!agencyAdmins.contains(acr.ContactId)){
                    recordToDelete.add(acr);
                }else{
                    recordsToCreate.put(acr.AccountId+'_'+acr.ContactId,acr);
                }
                
            }
        }
        for(ID recordID : accountIds ){
            if(accountToAgencyUserSet.containsKey(recordID) && accountToChildAccountSet.containskey(recordID)){
                for(Id conID : accountToAgencyUserSet.get(recordID)){
                    for(Id childID : accountToChildAccountSet.get(recordID)){
                        if(recordsToCreate.containsKey(childID+'_'+conID)){
                            //already present
                            recordsToCreate.remove(childID+'_'+conID);
                        }else{
                            recordsToCreate.put(childID+'_'+conID, new AccountContactRelation(AccountId=childID,ContactId=conID,isActive=true));
                        }
                    }
                }
            }
        }
        if(!recordToDelete.isEmpty()){  delete recordToDelete;
                                     }
        if(!recordsToCreate.isEmpty()){  insert recordsToCreate.values();
                                      }
        
    }
    public static void createAccountDocuments(list<account> accountRecords){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT,
            Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ORGANIZATION
            , Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ALDAR_STAFF});
        map<Id,account> accountIDToRecMap = new map<Id,account>(accountRecords);
        
        if(!documentMap.isEmpty() && !accountIDToRecMap.isEmpty()){
            //get Existing Documents
            map<string,Document__c> existingDocMap = new map<string,Document__c>();
            for(Document__c tempDoc : [select id,DocumentType__c,Account__c from Document__c where Account__c in :accountIDToRecMap.keySet()]){   existingDocMap.put(tempDoc.Account__c+tempDoc.DocumentType__c,tempDoc);
                                                                                                                                              }
            
            for(Account accRecord : accountRecords){
                string documentTypeToProcess; 
                List<DocumentPlaceHolder__mdt> documentsToProcess = new List<DocumentPlaceHolder__mdt>();
                
                if( accRecord.RecordTypeId ==Constants.PERSON_RECORD_TYPE_ID ){
                    documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT;
                }else if(accRecord.RecordTypeId ==Constants.ORGANIZATION_RECORD_TYPE_ID){
                    documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ORGANIZATION;
                }
                if(documentTypeToProcess != null && documentMap.containsKey(documentTypeToProcess)){
                    documentsToProcess.addAll(documentMap.get(documentTypeToProcess));
                }
                // addtional documents to create
                if(accRecord.CustomerType__c != null 
                   && accRecord.CustomerType__c.trim().equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) 
                   && documentMap.containsKey(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ALDAR_STAFF)
                  ){
                      documentsToProcess.addAll(documentMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ALDAR_STAFF));
                  }
                for(DocumentPlaceHolder__mdt tempMetaRec : documentsToProcess){
                    string recordTypeID=null;
                    
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    if(!existingDocMap.containsKey(accRecord.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'',accRecord.Id,recordTypeID);
                        documentRecord.SendForESign__c= tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                        documentRecord.EligibleForeSign__c=tempMetaRec.EligibleForeSign__c;
                        
                        documentListToInsert.add(documentRecord); 
                        existingDocMap.put(accRecord.Id + tempMetaRec.DocumentType__c,documentRecord);       
                    }
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
            insert documentListToInsert;  
        } 
    }
    
    public static void updateDDRIds(list<account> accountRecords){
        List<DirectdebitRequest__c> directDebitRequestsToUpdate = new List<DirectdebitRequest__c>();
        List<DirectdebitRequest__c> directDebitRequests = [SELECT
                                                           Account__c,
                                                           CustomerIDNumber__c,
                                                           CustomerIDTypeandNumber__c,
                                                           CustomerIdType__c,
                                                           Account__r.IsPersonAccount,
                                                           Account__r.NationalIdNumber__pc,
                                                           Account__r.PassportNumber__pc,
                                                           Account__r.RegistrationNumber__c,
                                                           Id 
                                                           FROM DirectDebitRequest__c
                                                           WHERE Account__c In: accountRecords
                                                           AND Status__c not in ('Cancelled', 'Cancellation in progress', 'Approved by Bank')];
        if(!directDebitRequests.isEmpty()){
            for(DirectdebitRequest__c directDebitRequest : directDebitRequests){
                DirectdebitRequest__c ddr = new DirectdebitRequest__c();
                ddr.Id = directDebitRequest.Id;
                if(directDebitRequest.CustomerIdType__c == 'UAE Emirates Identity Card' && directDebitRequest.Account__r.IsPersonAccount){
                    ddr.CustomerIDNumber__c = directDebitRequest.Account__r.NationalIdNumber__pc;
                }else if(directDebitRequest.CustomerIdType__c == 'Passport' && directDebitRequest.Account__r.IsPersonAccount){
                    ddr.CustomerIDNumber__c = directDebitRequest.Account__r.PassportNumber__pc;
                }else if(directDebitRequest.CustomerIdType__c == 'Trade License Number' && !directDebitRequest.Account__r.IsPersonAccount){
                    ddr.CustomerIDNumber__c = directDebitRequest.Account__r.RegistrationNumber__c;
                }
                directDebitRequestsToUpdate.add(ddr);
            }
        }
        if(!directDebitRequestsToUpdate.isEmpty()){ update directDebitRequestsToUpdate;
        }
    }
    
    /*Commented for Deployment - Rohit
Public static void updateDocumentSharing(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
Set<Id> AccountTeamMemberuserIds = new Set<Id>();
List<Account> accountToBeShared = new List<Account> ();
for(AccountTeamMember atm: [SELECT
AccountId,
Id,
UserId FROM AccountTeamMember
WHERE AccountId IN: (List<Account>) newList]){
AccountTeamMemberuserIds.add(atm.UserId);                   
}
if(!AccountTeamMemberuserIds.isEmpty()){
for(Account acc: (List<Account>) newList){
Account oldAccount = (Account)oldmap.get(acc.Id); 
if(acc.OwnerId != oldAccount.OwnerId && !AccountTeamMemberuserIds.contains(acc.OwnerId)){
accountToBeShared.add(acc);
}
}
}
}*/
    
    public static void duplicateAccountPrevention(List<SObject> newList, Map<Id, SObject> oldMap) {       
        Set<String> nationalIdNumberSet = new Set<String>();
        Set<String> passportNumberSet = new Set<String>();
        Map<String,String> accountNumberWithPassportMap = new Map<String,String>();
        Map<String,String> accountNumberWithPNationalIDMap = new Map<String,String>();
        
        for(Account account : (list<Account>)newList){
            //National Id Number field is Mandatory Check
            /*Moved the below validation to Validation Rule
if(string.isBlank(account.NationalIdNumber__pc) && string.isNotBlank(account.ResidentStatus__pc) && account.ResidentStatus__pc.equalsIgnoreCase('Resident')){
account.addError('National Id Number is Required');
}
//Passport Details are Mandatory Check
if(string.isBlank(account.PassportType__pc) || string.isBlank(account.PlaceofIssue__pc) || string.isBlank(account.PassportNumber__pc) || account.PassportIssueDate__pc == NULL || account.PassportExpiryDate__pc == NULL){
account.addError('Passport Details are Required');
} */
            //If Resident
            if(string.isNotBlank(account.ResidentStatus__pc) && account.ResidentStatus__pc.equalsIgnoreCase('Resident')) {
                if(string.isNotBlank(account.NationalIdNumber__pc)) {
                    nationalIdNumberSet.add(account.NationalIdNumber__pc.trim());
                }                   
            }
            //If Non-Resident
            else {
                if(string.isNotBlank(account.PassportNumber__pc)) {
                    passportNumberSet.add(account.PassportNumber__pc.trim());
                } 
            }
        }
        //Get Existing Accounts with Passport Number OR National ID
        for(Account existingAccount : [SELECT Id,AccountNumber__c,PassportNumber__pc,NationalIdNumber__pc from Account WHERE MergedAccount__c = false and (PassportNumber__pc IN :passportNumberSet OR NationalIdNumber__pc IN :nationalIdNumberSet)]) {
            if(string.isNotBlank(existingAccount.PassportNumber__pc)) {
                accountNumberWithPassportMap.put(existingAccount.PassportNumber__pc.trim(),existingAccount.AccountNumber__c);           
            }
            if(string.isNotBlank(existingAccount.NationalIdNumber__pc)) {
                accountNumberWithPNationalIDMap.put(existingAccount.NationalIdNumber__pc.trim(),existingAccount.AccountNumber__c);
            }           
        }
        //Duplicate Check & Prevention
        for(Account account : (list<Account>)newList){
            Account oldAccount = oldMap <> NULL ? (Account)oldmap.get(account.Id) : NULL;
            if(oldMap == NULL || (oldAccount <> null && (account.ResidentStatus__pc <> oldAccount.ResidentStatus__pc || account.NationalIdNumber__pc <> oldAccount.NationalIdNumber__pc || account.PassportNumber__pc <> oldAccount.PassportNumber__pc))){               
                //If Resident
                if(string.isNotBlank(account.ResidentStatus__pc) && account.ResidentStatus__pc.equalsIgnoreCase('Resident')) {
                    //for new account
                    if(oldAccount == null && string.isNotBlank(account.NationalIdNumber__pc) && !accountNumberWithPNationalIDMap.isEmpty() && accountNumberWithPNationalIDMap.containsKey(account.NationalIdNumber__pc.trim())){
                        account.addError('An existing account with the same National Id Number is already present with Account Number : '+accountNumberWithPNationalIDMap.get(account.NationalIdNumber__pc.trim()));
                    }
                    //for an existing account
                    if(oldAccount <> null && string.isNotBlank(account.NationalIdNumber__pc) && !accountNumberWithPNationalIDMap.isEmpty() && accountNumberWithPNationalIDMap.containsKey(account.NationalIdNumber__pc.trim()) && accountNumberWithPNationalIDMap.get(account.NationalIdNumber__pc.trim()) <> account.AccountNumber__c){
                        account.addError('An existing account with the same National Id Number is already present with Account Number : '+accountNumberWithPNationalIDMap.get(account.NationalIdNumber__pc.trim()));
                    }
                }
                //If Non-Resident
                else {
                    //for new account
                    if(oldAccount == null && string.isNotBlank(account.PassportNumber__pc) && !accountNumberWithPassportMap.isEmpty() && accountNumberWithPassportMap.containsKey(account.PassportNumber__pc.trim())){
                        account.addError('An existing account with the same Passport Number is already present with Account Number : '+accountNumberWithPassportMap.get(account.PassportNumber__pc.trim()));
                    }
                    //for an existing account
                    if(oldAccount <> null && string.isNotBlank(account.PassportNumber__pc) && !accountNumberWithPassportMap.isEmpty() && accountNumberWithPassportMap.containsKey(account.PassportNumber__pc.trim()) && accountNumberWithPassportMap.get(account.PassportNumber__pc.trim()) <> account.AccountNumber__c){
                        account.addError('An existing account with the same Passport Number is already present with Account Number : '+accountNumberWithPassportMap.get(account.PassportNumber__pc.trim()));
                    }
                }
            }
        }
    }
    public static void accountSharewithSubManagers(Set<Id> AccountOwnerIdSet, List<Account> newList, Set<Id> oldSubAccountManagerIds){
        Map<Id, AccountShare> actShareMap = new Map<Id, AccountShare>();
        List<AccountShare> subManageraccountShare = new List<AccountShare>();
        if(!AccountOwnerIdSet.isEmpty() && !newList.isEmpty()){
            List<AccountShare> accountShareList = [SELECT
                                                   AccountAccessLevel,
                                                   AccountId,
                                                   CaseAccessLevel,
                                                   ContactAccessLevel,
                                                   Id,OpportunityAccessLevel,
                                                   RowCause,
                                                   UserOrGroupId FROM AccountShare
                                                   WHERE AccountId IN:newList 
                                                   AND UserOrGroupId IN:AccountOwnerIdSet];
            
            for(AccountShare aactshare: accountShareList){  actShareMap.put(aactshare.AccountId, aactshare);
                                                         }
            for(Account act: newList){
                AccountShare managerAccountShare = actShareMap.get(act.Id);
                AccountShare share = new AccountShare();
                share.AccountId = act.id;share.UserOrGroupId = act.SubAccountManager__c;
                if(!Test.isRunningTest() && managerAccountShare != null){
                    share.AccountAccessLevel = managerAccountShare.AccountAccessLevel == 'All' ? 'Edit': managerAccountShare.AccountAccessLevel;
                    share.OpportunityAccessLevel = managerAccountShare.OpportunityAccessLevel;subManageraccountShare.add(share);
                }else{
                    share.AccountAccessLevel = 'Edit';
                    share.OpportunityAccessLevel ='Read';
                }
                
            }
            if(!subManageraccountShare.isEmpty()){   insert subManageraccountShare;
                                                 }
        }
        if(!oldSubAccountManagerIds.isEmpty()){List<AccountShare> AccountSharedWithOldSubManagers = [SELECT
                                                                                                     AccountAccessLevel,
                                                                                                     AccountId,
                                                                                                     CaseAccessLevel,
                                                                                                     ContactAccessLevel,
                                                                                                     Id 
                                                                                                     FROM AccountShare WHERE UserOrGroupId IN: oldSubAccountManagerIds AND AccountId IN: newList];
                                               
                                               if(!AccountSharedWithOldSubManagers.isEMpty()){ delete AccountSharedWithOldSubManagers;
                                                                                             }
                                              }
    } 
    
    public static void updateInvoiceBundle (List<Id> accInvoiceIdSet){
        List<Id> invoiceIdList = new List<Id>();
        //Tharun Modified below where condition to consider un approved invoices
        List<InvoiceBundle__c> bundleInvoiceList = [Select Id FROM InvoiceBundle__c 
                                                    WHERE BrokerAgency__c IN: accInvoiceIdSet 
                                                    AND ApprovalStatus__c != 'Approved'];
        
        for(InvoiceBundle__c inv: bundleInvoiceList){
            invoiceIdList.add(inv.Id);
        }
        if(!invoiceIdList.isEmpty()){
            CommissionLineItemTriggerHandler.getCountOnInvoiceBunlde(invoiceIdList);
        }
    }
    public static void documentShareWithAccountOwner(List<Account> newList){
        try{
            List<Document__Share> documentShareList = new List<Document__Share>();
            Map<Id, List<Document__c>> accountDocumentMap = new Map<Id, List<Document__c>>();
            for(Document__c document: [SELECT
                                       Id,
                                       Account__r.OwnerId,
                                       Account__c,
                                       OwnerId
                                       FROM 
                                       Document__c
                                       WHERE Account__c IN: newList]){
                                           List<Document__c> doclist = accountDocumentMap.get(document.Account__c)  != null ?   accountDocumentMap.get(document.Account__c) : new List<Document__c>();
                                           doclist.add(document)  ;  
                                           accountDocumentMap.put(document.Account__c, doclist);
                                       }
            
            
            for(Account account: newList){
                if(accountDocumentMap.containsKey(account.id)){
                    List<Document__c> doculist = accountDocumentMap.get(account.id);
                    for(Document__c document: doculist){
                        if(document.OwnerId != account.ownerId){
                            Document__Share docShare = new Document__Share();
                            docShare.AccessLevel = 'Edit';
                            docShare.ParentId = document.Id;
                            docShare.UserOrGroupId = account.OwnerId;
                            docShare.RowCause = 'Manual';
                            documentShareList.add(docShare);
                        }
                    }
                }
            }
            
            if(!documentShareList.isEmpty()){
                insert documentShareList;
            }
        }catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'AccountTriggerHandler','insert DocumentShare',''));
            String htmlEmailBody = 'Hello,</br></br> AccountTriggerHandler documentSharewithTeamMember has failed because of below error.</br></br>';
            htmlEmailBody += ' <b> ' + e.getMessage() + ' </b> </br> ' ;
            htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
            htmlEmailBody +=  ' <b> parameters : New List = ' + newList+' </b> ' ;
            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'documentShareList insert Failure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            
        } 
    }
    
    // Added By Moh Sarfaraj for BPE-164
    public static void updateApprovalComments(List<SObject> newList, Map<Id, SObject> oldMap){
        Set<Id> setAccountIds = new Set<Id>();
        for(Account eachAccount : (List<Account>) newList){
            Account oldAccount = (Account) oldMap.get(eachAccount.Id);
            if(eachAccount.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID && 
               String.isNotBlank(eachAccount.ProposedBankDetailStatus__c) && 
               eachAccount.ProposedBankDetailStatus__c != oldAccount.ProposedBankDetailStatus__c && 
               eachAccount.ProposedBankDetailStatus__c == 'Rejected'){
                   
                   setAccountIds.add(eachAccount.Id);
               }
        }
        if(!setAccountIds.isEmpty()){
            Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id,ProposedBankDetailStatus__c,Description,(SELECT Id,IsPending, 
                                                                                                                 ProcessInstanceId,TargetObjectId,StepStatus,OriginalActorId,ActorId, 
                                                                                                                 RemindersSent,Comments,IsDeleted,CreatedDate,CreatedById,SystemModstamp 
                                                                                                                 FROM ProcessSteps ORDER BY CreatedDate DESC LIMIT 1) 
                                                              FROM Account WHERE Id IN :setAccountIds]);
            
            for(Account eachAccount : (List<Account>) newList){
                if(accountMap.containsKey(eachAccount.Id) && !accountMap.get(eachAccount.Id).ProcessSteps.isEmpty()){
                    eachAccount.Description = accountMap.get(eachAccount.Id).ProcessSteps[0].Comments;
                }
            }
        }
    }
    
    // Added By Moh Sarfaraj for BPE-164
    static String APPROVED_MSG = 'Your Change Request to update Banking details has been Approved.';
    static String REJECTED_MSG = 'Your Change Request to update Banking details has been Rejected.';
    
    public static void requestedBankDetailUpdatedStatus(List<SObject> newList, Map<Id, SObject> oldMap){
        Set<Id> setAccountIds = new Set<Id>();
        for(Account eachAccount : (List<Account>) newList){
            Account oldAccount = (Account) oldMap.get(eachAccount.Id);
            if(eachAccount.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID && 
               String.isNotBlank(eachAccount.ProposedBankDetailStatus__c) && 
               eachAccount.ProposedBankDetailStatus__c != oldAccount.ProposedBankDetailStatus__c && 
               (eachAccount.ProposedBankDetailStatus__c == 'Approved' || eachAccount.ProposedBankDetailStatus__c == 'Rejected')){
                   
                   setAccountIds.add(eachAccount.Id);
               }
        }
        if(!setAccountIds.isEmpty()){
            List<Account> listAccountOwnerAdmin = new List<Account>();
            
            String otpReceiver = System.Label.BPM_BankOTPOwnership.deleteWhiteSpace().toUpperCase(); // PrimaryAdmin / PrimaryOwner
            
            if(String.isNotBlank(otpReceiver) && !setAccountIds.isEmpty()){
                if(otpReceiver.equalsIgnoreCase('PRIMARYADMIN') || Test.isRunningTest()){
                    
                    listAccountOwnerAdmin = [SELECT Id,ProposedBankDetailStatus__c,Description,OwnerId,(SELECT Id,Name,
                                                                                                        MobileCountryCode__c,MobilePhone__c FROM Contacts WHERE BrokerType__c = 'Agency Admin' AND 
                                                                                                        PrimaryAgencyAdmin__c = true ORDER By LastModifiedDate DESC LIMIT 1) 
                                             FROM Account WHERE Id IN :setAccountIds];
                    
                }else if(otpReceiver.equalsIgnoreCase('PRIMARYOWNER') || Test.isRunningTest()){
                    
                    listAccountOwnerAdmin = [SELECT Id,ProposedBankDetailStatus__c,Description,OwnerId,(SELECT Id,Name,
                                                                                                        MobileCountryCode__c,MobilePhone__c FROM Contacts WHERE BrokerType__c = 'Partner/Owner' AND 
                                                                                                        PrimaryOwner__c = true ORDER By LastModifiedDate DESC LIMIT 1) 
                                             FROM Account WHERE Id IN :setAccountIds];
                }
            }
            if(!listAccountOwnerAdmin.isEmpty()){
                List<SmsNotificationAPI.SmsRequest> listSMSAPIWrapper = new List<SmsNotificationAPI.SmsRequest>();
                for(Account eachAcc : listAccountOwnerAdmin){
                    if(!eachAcc.Contacts.isEmpty()){
                        Contact primaryOwnerAdmin = eachAcc.Contacts[0];
                        
                        String countryCode = primaryOwnerAdmin.MobileCountryCode__c;
                        if(countryCode.startsWith('+971') || countryCode.startsWith('971') || countryCode.startsWith('+97') || countryCode.startsWith('97')){
                            SmsNotificationAPI.SmsRequest smsAPIWrapper = new SmsNotificationAPI.SmsRequest();
                            smsAPIWrapper.destination = primaryOwnerAdmin.MobileCountryCode__c + primaryOwnerAdmin.MobilePhone__c;
                            smsAPIWrapper.record = eachAcc;
                            
                            String simpleSMSBody = '';
                            if(eachAcc.ProposedBankDetailStatus__c == 'Approved'){
                                simpleSMSBody = 'Dear '+primaryOwnerAdmin.Name+','+'\r\n'+ APPROVED_MSG +'\r\n'+'\r\n';
                            }else if(eachAcc.ProposedBankDetailStatus__c == 'Rejected'){
                                simpleSMSBody = 'Dear '+primaryOwnerAdmin.Name+ ','+'\r\n'+ REJECTED_MSG + '\r\n' +'Due to '+eachAcc.Description+'\r\n'+'\r\n';
                            }
                            simpleSMSBody +=  'Aldar Properties' ;
                            
                            smsAPIWrapper.smsBody = simpleSMSBody;
                            listSMSAPIWrapper.add(smsAPIWrapper);
                        }else{
                            // Implement INTL SMS API
                        }     
                    }
                }
                if(!listSMSAPIWrapper.isEmpty() && !Test.isRunningTest()){SmsNotificationAPI.sendSmsNotification(listSMSAPIWrapper);}  
            }         
        }
    }
    
    // Added By Moh Sarfaraj for BPM-391
    @testVisible
    private static void suspendActiveAgencyRelatedAgents(Set<Id> setAgencyIds, String status){
        List<Contact> listContact = new List<Contact>();
        for(Contact eachContact : [SELECT Id,AgentStatus__c FROM Contact WHERE AgentStatus__c = :status AND AccountId IN : setAgencyIds]) {
            
            if(Approval.isLocked(eachContact.Id)){
                Approval.unlock(eachContact.Id);
            }
            
            if(status == 'Active'){
                eachContact.AgentStatus__c = 'Suspended';
            }else if(status == 'Suspended'){
                eachContact.AgentStatus__c = 'Active';
            }
            listContact.add(eachContact);
        }
        if(!listContact.isEmpty() && !Test.isRunningTest()){
            update listContact;
        }
    }
    // Changes relate to ASF-3337 start here
    // Duplicate account related changes
    public static void duplicateCheck(List<SObject> newList, Map<Id, SObject> oldMap){
        
        Set<String> emiratesId = new Set<String>();
        Set<String> passportSet = new Set<String>();
        Set<String> nationalitySet = new Set<String>();
        Set<Date> dateOfBirthSet = new Set<Date>();
        
        // Retrieve the value of the custom label
        String accountDuplicationEnabled = Label.AccountDuplicationEnabled;
        String profileName = '';
        if(accountDuplicationEnabled == 'true'){
            //  profileName = ([SELECT Id, Profile.Name FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1]).Profile.Name;
            
            // Check if the label is equal to 'true' (as a string)
            // if ( !Label.ProfilesToBypassDuplicateLogic.contains(profileName) ){       
            for(Account eachAccount : (List<Account>) newList){
                if(oldMap==null){
                    if(eachAccount.ResidentStatus__pc == 'Resident' && String.isNotBlank(eachAccount.NationalIdNumber__pc) ){
                        
                        emiratesId.add(eachAccount.NationalIdNumber__pc);
                    }else if(eachAccount.ResidentStatus__pc == 'Non-Resident' && String.isNotBlank(eachAccount.PassportNumber__pc )
                             && String.isNotBlank(eachAccount.Nationality__pc) && eachAccount.PersonBirthdate != null ){
                                 
                                 passportSet.add(eachAccount.PassportNumber__pc.toUpperCase());
                                 nationalitySet.add(eachAccount.Nationality__pc);
                                 dateOfBirthSet.add(eachAccount.PersonBirthdate);
                             }
                }else{
                    Account oldAccount = (Account) oldMap.get(eachAccount.Id);
                    if(eachAccount.ResidentStatus__pc == 'Resident' && String.isNotBlank(eachAccount.NationalIdNumber__pc) 
                       && eachAccount.NationalIdNumber__pc != oldAccount.NationalIdNumber__pc ){
                           
                           emiratesId.add(eachAccount.NationalIdNumber__pc);
                       }else if(eachAccount.ResidentStatus__pc == 'Non-Resident' && String.isNotBlank(eachAccount.PassportNumber__pc) 
                                && String.isNotBlank(eachAccount.Nationality__pc) 
                                && eachAccount.PersonBirthdate != null &&
                                (eachAccount.PassportNumber__pc != oldAccount.PassportNumber__pc || 
                                 eachAccount.Nationality__pc != oldAccount.Nationality__pc ||
                                 eachAccount.PersonBirthdate != oldAccount.PersonBirthdate)){
                                     
                                     passportSet.add(eachAccount.PassportNumber__pc.toUpperCase());
                                     nationalitySet.add(eachAccount.Nationality__pc);
                                     dateOfBirthSet.add(eachAccount.PersonBirthdate);
                                 }
                }
            }
            //}
        }
        if(!emiratesId.isEmpty() || !passportSet.isEmpty()){
            Map<String,Account> residentMap = new Map<String,Account>();
            Map<String,Account> nonResidentMap = new Map<String,Account>();
            for(Account acc:[SELECT ID,ResidentStatus__pc,NationalIdNumber__pc,PassportNumber__pc,Nationality__pc,PersonBirthdate FROM Account WHERE NationalIdNumber__pc IN:emiratesId OR PassportNumber__pc IN:passportSet OR Nationality__pc IN:nationalitySet OR PersonBirthdate IN:dateOfBirthSet]){
                if(acc.ResidentStatus__pc == 'Resident' && String.isNotBlank(acc.NationalIdNumber__pc)){
                    residentMap.put(acc.NationalIdNumber__pc,acc);
                }else if(acc.ResidentStatus__pc == 'Non-Resident' && String.isNotBlank(acc.PassportNumber__pc)){
                    nonResidentMap.put(acc.PassportNumber__pc+acc.Nationality__pc+acc.PersonBirthdate,acc);
                }
            }
            for(Account eachAccount : (List<Account>) newList){
                if(eachAccount.ResidentStatus__pc == 'Resident' && residentMap.containskey(eachAccount.NationalIdNumber__pc)){
                    eachAccount.addError(Label.DuplicateErrorMessageAccount);
                }
                if(eachAccount.ResidentStatus__pc == 'Non-Resident' && String.isNotBlank(eachAccount.PassportNumber__pc)){
                    String keyVal = eachAccount.PassportNumber__pc.toUpperCase()+eachAccount.Nationality__pc+eachAccount.PersonBirthdate;
                    if(nonResidentMap.containskey(keyVal)){
                        eachAccount.addError(Label.DuplicateErrorMessageAccount);
                    }
                }
            }
        }       
    }
    // @story FIN-54 As part of Sai Kumar changes, Handles checking and updating sync status based on integration field changes
    public void handleIntegrationFieldChanges(Account acc, Account oldAcc, 
        Map<String, Account_Integration_Fields__c> brokerFields,
        Map<String, Account_Integration_Fields__c> customerFields) {
            
        Map<String, Account_Integration_Fields__c> fieldsToCheck = 
            acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID 
                ? brokerFields 
                : customerFields;

        Boolean hasChanges = false;
        for (String field : fieldsToCheck.keySet()) {
            if (acc.get(field) != oldAcc.get(field)) {
                hasChanges = true;
                break;
            }
        }

        if (hasChanges) {
            acc.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            acc.IsBrokerChange__c = true;
        }
    }
}