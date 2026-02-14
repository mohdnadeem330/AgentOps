public without sharing class MergeAccount {
   
    
    public class DuplicateAccountWrapper {
        @AuraEnabled
        public Account account{get;set;}
        @AuraEnabled
        public Integer salesOrderCount{get;set;}
        @AuraEnabled
        public String SignedKYCFormDate{get;set;}
        @AuraEnabled
        public String SignedCISFormDate{get;set;}
        @AuraEnabled
        public Boolean isCaseAccountId{get;set;}
    }

	@AuraEnabled
    public static String createMasterAccountRecord(String selectedId, String duplicateRecordId) {
        try{
            Boolean byPassCustomerTypeCheckInMergeAccount = Boolean.valueOf(System.label.ByPassCustomerTypeCheckInMergeAccount);
            Account masterAccount = new Account();
            Account childAccount = new Account();

            for(Account acc :[SELECT Id, CustomerType__c, CustomerSubType__c, Merging_Status__c, SapAccountID__c, PersonEmail, CustomerVertical__c, PersonMobilePhone, NationalIdNumber__pc, PassportNumber__pc, EligibleForMerge__c, ERPID__c, Merging_Error_Message__c FROM Account WHERE Id IN: new Set<String>{selectedId, duplicateRecordId}]) {
                if(acc.Id == selectedId){
                    masterAccount = acc;
                } else if(acc.Id == duplicateRecordId){
                    childAccount = acc; 
                }
            }
            
            List<Account> duplicateAccountIsMasterInProgress = [SELECT Id, MasterAccount__c FROM Account WHERE EligibleForMerge__c = true AND MasterAccount__c =:duplicateRecordId];

            if(masterAccount.EligibleForMerge__c) {
                throw new AuraHandledException('Given master account is already submitted for merging. Please select other record');
            } else if(childAccount.ERPID__c != NULL && masterAccount.ERPID__c == NULL) {
                throw new AuraHandledException('Please sync the Account with ERP to Proceed with Merge');
            } /*else if(childAccount.CustomerVertical__c != NULL && childAccount.CustomerVertical__c.contains('Kingsfield') && masterAccount.PersonMobilePhone != childAccount.PersonMobilePhone) {
                throw new AuraHandledException('You cannot merge kingsfiled account since master is having differnet phone number!!');
            }*/ else if(childAccount.SapAccountID__c != NULL && masterAccount.SapAccountID__c != NULL) {
                throw new AuraHandledException('You cannot merge this account because child and master accounts are in SAP.');
            } else if(!duplicateAccountIsMasterInProgress.isEmpty()) {
                throw new AuraHandledException('Given duplicate account is already submitted for merging with other duplicate record. Please select other record');
            } else if(!byPassCustomerTypeCheckInMergeAccount && childAccount.CustomerSubType__c != NULL && (childAccount.CustomerSubType__c.contains('VIP') || childAccount.CustomerSubType__c.contains('Aldar Staff')) && childAccount.CustomerType__c != masterAccount.CustomerType__c) {
                throw new AuraHandledException('Customer Type should be the same!!');
            } /*else if(childAccount.CustomerSubType__c != masterAccount.CustomerSubType__c) {
                throw new AuraHandledException('Customer Sub Type should be the same!!');
            }*/
            String result = '';
            
            if(childAccount.Merging_Status__c == 'ERP Validation Failure' && childAccount.ERPID__c != NULL){
                String jsonRequest = jsonRequestBody(childAccount, masterAccount);
                result = processERPRequest(jsonRequest, selectedId);
            } else if(childAccount.Merging_Status__c == 'Salesforce Merge Failed') {
                Account acc = new Account();
                acc.Id = childAccount.Id;
                acc.Merging_Status__c = childAccount.ERPID__c != NULL ? 'ERP Merge Completed' : 'Approved';
                acc.Merging_Error_Message__c = '';
                update acc;
                return 'Merge request submitted successfully.';
            } else {
                result = submitForApproval(childAccount.Id, masterAccount.Id);
            }
           
            return result;
        } catch (AuraHandledException aex) {
            // Re-throw it directly (optional if you want to catch it here)
            throw aex;
        } catch(exception ex) {
            String errorMsg = 'The following exception has occurred: ' + ex.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }

    private static String getFieldAPIName(String name){
        if(name == 'Email'){
            return 'PersonEmail';
        }else if(name == 'PhoneNumber'){
            return 'PersonMobilePhone';
        }else if(name == 'EmiratesId'){ 
            return 'NationalIdNumber__pc';
        }else if(name == 'Passport'){
            return 'PassportNumber__pc';
        }else{
            return '';
        }
    }

    public static String jsonRequestBody(Account childAccount , Account masterAccount) {
        List<Map<String, String>> customerMergeList = new List<Map<String, String>>();
        Map<String, Object> requestPayload = new Map<String, Object>();
        Map<String, String> customerMergeMap = new Map<String, String>();
        customerMergeMap.put('fromERPID', childAccount.ERPID__c);
        customerMergeMap.put('fromSFID', childAccount.Id);
        customerMergeMap.put('toERPID', masterAccount.ERPID__c);
        customerMergeMap.put('toSFID', masterAccount.Id);
        customerMergeList.add(customerMergeMap);
        requestPayload.put('customerMerge', customerMergeList);
        String requestBody = JSON.serialize(requestPayload);
        return requestBody;
    }

    public static String processERPRequest(String jsonRequest, String selectedId) {
        Set<Id> accountIds = new Set<Id>();
        String endPointUrl = '';
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails('ERPAPIDetails');
        Organization org = Utilities.getOrganizationDetails();

        if(!org.IsSandbox){
            endPointUrl = mulesoftAPI.ProductionURL__c;
        }else{
            endPointUrl = mulesoftAPI.SandboxURL__c;
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('client_secret', mulesoftAPI.APIKey__c);
        req.setHeader('client_id', mulesoftAPI.APIId__c);
        req.setBody(jsonRequest);

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (Exception e) {
            System.debug('HTTP Callout Failed: ' + e.getMessage());
            throw new AuraHandledException('HTTP Callout Failed: ' + e.getMessage());
        }
        system.debug('res.getBody()@@'+res.getBody());

        if (res.getStatusCode() == 201) {
            try {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                List<Object> results = (List<Object>) responseMap.get('results');
                List<Account> accountsToUpdate = new List<Account>();
                String ERPValidationFailError = 'successfully';

                for (Object obj : results) {
                    Map<String, Object> resultEntry = (Map<String, Object>) obj;
                    String fromSFID = (String) resultEntry.get('fromSFID');
                    String status = (String) resultEntry.get('status');
                    String errorMsg = (String) resultEntry.get('errorMsg');

                    if (status == 'Failure') {
                        Account acc = new Account();
                        acc.Id = fromSFID;
                        acc.Merging_Status__c = 'ERP Validation Failure';
                        acc.Merging_Error_Message__c = errorMsg;
                        accountsToUpdate.add(acc);
                        ERPValidationFailError = errorMsg;
                    } else {
                        Account acc = new Account();
                        acc.Id = fromSFID;
                        acc.EligibleForMerge__c = true;
                        acc.Merging_Status__c = 'ERP submitted for Merge';
                        acc.MasterAccount__c = selectedId;
                        acc.Merging_Error_Message__c = '';
                        accountsToUpdate.add(acc);
                        accountIds.add(fromSFID);
                    }
                }

                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }

                return ERPValidationFailError;
                /*if(accountIds != null && !accountIds.isEmpty()){
                    Database.executeBatch(new MergeCustomersBatchNew(accountIds),1);
                }*/
            } catch (AuraHandledException aex) {
            // Re-throw it directly (optional if you want to catch it here)
                throw aex;
            }catch (Exception e) {
                System.debug('Error processing API response: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            System.debug('Unexpected Response Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
            throw new AuraHandledException('Unexpected Response Code: ' + res.getStatusCode());
        }
    }

    @future(callout=true)
	public static void processMergeRequest(Set<Id> duplicateAccountIds) {
        Set<Id> accountIds = new Set<Id>();
        String endPointUrl = '';
        String jsonRequest;
        String selectedId;
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails('ERPAPIDetails');
        Organization org = Utilities.getOrganizationDetails();
        List<Account> accountsToUpdate = new List<Account>();

        if(!org.IsSandbox){
            endPointUrl = mulesoftAPI.ProductionURL__c;
        }else{
            endPointUrl = mulesoftAPI.SandboxURL__c;
        }

        for(Account act : [SELECT Id, SapAccountID__c, PersonEmail, CustomerVertical__c, PersonMobilePhone, NationalIdNumber__pc, PassportNumber__pc, EligibleForMerge__c, ERPID__c, Merging_Error_Message__c, MasterAccount__r.ERPID__c, MasterAccount__c FROM Account WHERE Id IN: duplicateAccountIds AND MasterAccount__c != NULL]) {
            selectedId = act.MasterAccount__c;
            jsonRequest = jsonRequestBody(act, act.MasterAccount__r);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPointUrl);
            req.setMethod('POST');
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('client_secret', mulesoftAPI.APIKey__c);
            req.setHeader('client_id', mulesoftAPI.APIId__c);
            req.setBody(jsonRequest);

            Http http = new Http();
            HttpResponse res;
            try {
                res = http.send(req);

                if (res.getStatusCode() == 201) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    List<Object> results = (List<Object>) responseMap.get('results');

                    for (Object obj : results) {
                        Map<String, Object> resultEntry = (Map<String, Object>) obj;
                        String fromSFID = (String) resultEntry.get('fromSFID');
                        String status = (String) resultEntry.get('status');
                        String errorMsg = (String) resultEntry.get('errorMsg');

                        if (status == 'Failure') {
                            accountsToUpdate.add(mapAccount(act.Id, errorMsg));
                        } else {
                            accountsToUpdate.add(mapAccount(act.Id, ''));
                        }
                    }
                } else {
                    accountsToUpdate.add(mapAccount(act.Id, 'HTTP Callout Failed'));
                }
            } catch (Exception e) {
                accountsToUpdate.add(mapAccount(act.Id, e.getMessage()));
                Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(e, 'Merge Accounts','MergeAccount', 'processMergeRequest'));
            }

            if(!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        }
    }

    public static Account mapAccount(Id accountId, String errorMessage) {
        Integer semiColonIndex = errorMessage.indexOf(';');
        String cleanedError = '';

        if (semiColonIndex != -1 && semiColonIndex + 1 < errorMessage.length()) {
            cleanedError = errorMessage.substring(semiColonIndex + 1).trim();
        }

        Account acc = new Account();
        acc.Id = accountId;
        acc.Merging_Status__c = String.isNotBlank(errorMessage) ? 'ERP Validation Failure' : 'ERP submitted for Merge';
        acc.Merging_Error_Message__c = cleanedError != '' ? cleanedError : errorMessage;
        return acc;
    }
	
    public static Map<String, List<DuplicateAccountWrapper>> findDuplicateAccountsByValue(Set<String> duplicateValues, String duplicateFieldName, String caseAccountId) {
        Map<String, List<DuplicateAccountWrapper>> dupeWrapperMap = new Map<String, List<DuplicateAccountWrapper>>();
        //Set<Id> contentDocumentIds = new Set<Id>();
        List<Id> contentVersionIds = new List<Id>();
        //list<string> ContentVersionList = new List<string>();
        if(System.Label.DuplicateAccountEnable.trim().toUpperCase() == 'FALSE'){
            return dupeWrapperMap;
        }
        Set<String> valueSet = new Set<String>();
        for(String st : duplicateValues){
            String emailString = st.toLowerCase();
            valueSet.add(emailString);
        }
         
         String salesOrderWhrClause = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
         String accountWhrClause = caseAccountId != '' ? ' ( RecordType.Name = \'' +Constants.PERSON_ACCOUNT_RT + '\' AND (Id =:caseAccountId OR ' + duplicateFieldName + ' IN :duplicateValues))' : ' ( RecordType.Name = \'' +Constants.PERSON_ACCOUNT_RT + '\' AND ' + duplicateFieldName + ' IN :duplicateValues)';
         String query = 'SELECT Id, SapAccountID__c, Merging_Error_Message__c, Merging_Status__c,CustomerVertical__c,Name, PersonEmail,PassportNumber__pc,EmailApprovalsReason__c,KYC_Validity_Status__c,ResidentStatus__pc, AccountNumber__c,CustomerType__c,CustomerSubType__c,NationalIdNumber__pc,SkipDuplicateApprovalStatus__c,EligibleForMerge__c,MasterAccount__r.Name,ERPID__c,MasterAccount__c,PersonBirthdate,PassportExpiryDate__pc,BlacklistReason__c,VIPClass__c,Nationality__pc,PersonMobilePhone,ScreeningStatus__c,NationalIdExpiryDate__pc,SkipLiveAldarReason__c,CustomerAppWebUser__c, (SELECT Id,Name FROM Opportunity_Units__r WHERE '+salesOrderWhrClause+' ),(SELECT Id,LastModifiedDate,DocumentType__c FROM Documents__r WHERE (DocumentType__c=\'Signed KYC Form\' OR DocumentType__c=\'Signed CIS Sheet\') AND Status__c =\'Uploaded\' ORDER BY LastModifiedDate ASC) FROM Account WHERE '+accountWhrClause+' AND MergedAccount__c= false ORDER BY CreatedDate DESC';
        
        //Execute the query
        List<Account> queriedAccounts = Database.query(query);
        
        
        if (!queriedAccounts.isEmpty() && queriedAccounts.size() > 0) {
            
            
            for (Account ac : queriedAccounts) {
                DuplicateAccountWrapper wrapper = new DuplicateAccountWrapper();
                wrapper.account = ac;
                wrapper.salesOrderCount = ac.Opportunity_Units__r != null ? ac.Opportunity_Units__r.size() : 0;
                
                
                
                if (dupeWrapperMap.containsKey((String)ac.get(duplicateFieldName))) {
                    dupeWrapperMap.get((String)ac.get(duplicateFieldName)).add(wrapper);
                } else {
                    dupeWrapperMap.put((String)ac.get(duplicateFieldName), new List<DuplicateAccountWrapper>{wrapper});
                }
            }
        }
        
        
        return dupeWrapperMap;
    }
    
	 @AuraEnabled(cacheable=false)
    public  static List<DuplicateAccountWrapper> getDuplicateRecords(Id recordId,String duplicateField){
        try {
            Id recroddataId = recordId;
            String duplicateValue = '';
            String sObjName = recroddataId.getSObjectType().getDescribe().getName();
            String caseAccountId = '';

            if(sObjName == 'Account') {
                Account acc = [select Id,PersonEmail,PassportNumber__pc,MobilePhone__pc,PersonMobilePhone,NationalIdNumber__pc FROM Account WHERE Id=:recordId LIMIT 1];
                duplicateValue = (String)acc.get(getFieldAPIName(duplicateField));
            } else if(sObjName == 'Case') {
                Case cs = [SELECT Id, Email__c, AccountId FROM Case WHERE Id =: recordId LIMIT 1];
                if(getFieldAPIName(duplicateField) == 'PersonEmail') {
                    duplicateValue = cs.Email__c;
                    caseAccountId = cs.AccountId;
                } else {
                    Account acc = [select Id,PersonEmail,PassportNumber__pc,MobilePhone__pc,PersonMobilePhone,NationalIdNumber__pc FROM Account WHERE Id=:cs.AccountId LIMIT 1];
                    duplicateValue = (String)acc.get(getFieldAPIName(duplicateField));
                }
            }

            

            Map<String,List<DuplicateAccountWrapper>> AccountMap = (duplicateValue != '' && duplicateValue != NULL) ? findDuplicateAccountsByValue(new Set<String>{duplicateValue},getFieldAPIName(duplicateField), caseAccountId) : new Map<String,List<DuplicateAccountWrapper>>();
            List<Account> accList =new List<Account>();
            for(String str :AccountMap.keySet()){
                for(DuplicateAccountWrapper dup :AccountMap.get(str)){
                    accList.add(dup.account);
                }
            }
            Map<String, List<DuplicateAccountWrapper>> dupeWrapperMap = new Map<String, List<DuplicateAccountWrapper>>();
            if(!accList.isEmpty() && accList.size() >0){
                Map<Id, List<Document__c>> accountToDocumentsMap = new Map<Id, List<Document__c>>();
                Set<Id> documentIds = new Set<Id>();
                
                for (Account ac : accList) {
                    if (ac.Documents__r != null) {
                        accountToDocumentsMap.put(ac.Id, ac.Documents__r);
                        for (Document__c doc : ac.Documents__r) {
                            if (doc.DocumentType__c == 'Signed KYC Form' || doc.DocumentType__c == 'Signed CIS Sheet') {
                                documentIds.add(doc.Id);
                            }
                        }
                    }
                }
                
                Map<Id, List<ContentDocumentLink>> documentToLinksMap = new Map<Id, List<ContentDocumentLink>>();
                Set<Id> contentDocumentIds = new Set<Id>();
                if(documentIds.size() >0){
                    for (ContentDocumentLink cdl : [
                        SELECT ContentDocumentId, LinkedEntityId,SystemModstamp
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId IN :documentIds ORDER BY SystemModstamp DESC
                    ]) {
                        if (!documentToLinksMap.containsKey(cdl.LinkedEntityId)) {
                            documentToLinksMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
                        }
                        documentToLinksMap.get(cdl.LinkedEntityId).add(cdl);
                        contentDocumentIds.add(cdl.ContentDocumentId);
                    }
                } 
                
                for (Account ac : accList) {
                    DuplicateAccountWrapper wrapper = new DuplicateAccountWrapper();
                    wrapper.account = ac;
                    wrapper.isCaseAccountId = caseAccountId != '' ? caseAccountId == ac.Id : FALSE;
                    wrapper.salesOrderCount = ac.Opportunity_Units__r != null ? ac.Opportunity_Units__r.size() : 0;
                    
                    if (accountToDocumentsMap.containsKey(ac.Id) && accountToDocumentsMap.get(ac.Id) != null) {
                        for (Document__c doc : accountToDocumentsMap.get(ac.Id)) {
                            List<ContentDocumentLink> cdlList = documentToLinksMap.get(doc.Id);
                            
                            if (cdlList != null && !cdlList.isEmpty()) {
                                if (doc.DocumentType__c == 'Signed KYC Form') {
                                    wrapper.SignedKYCFormDate = cdlList[0].SystemModstamp.format();
                                } else if (doc.DocumentType__c == 'Signed CIS Sheet') {
                                    wrapper.SignedCISFormDate = cdlList[0].SystemModstamp.format();
                                }
                            }
                        }
                    }
                    
                    
                    if (dupeWrapperMap.containsKey(duplicateValue)) {
                        dupeWrapperMap.get(duplicateValue).add(wrapper);
                    } else {
                        dupeWrapperMap.put(duplicateValue, new List<DuplicateAccountWrapper>{wrapper});
                    }
                }
                
            }
            
            
            return dupeWrapperMap.get(duplicateValue);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }  
    }

    /**
     * @description Method to used submit for approval Account_Merge_Approval Request
     * @author rrangrej@aldar.com | 17/07/2025 | Story Number
     * @param Set<Id> recordsToSubmit
     **/
    public static String submitForApproval(Id duplicateAccountId, Id masterAccountId) {
        List<Id> recordsToUnlock = new List<Id>();
        Account acc = new Account();
        acc.Id = duplicateAccountId;
        acc.EligibleForMerge__c = true;
        acc.MasterAccount__c = masterAccountId;
        acc.Merging_Status__c = 'Awaiting Approval';
        acc.DuplicateConfirmedBy__c = UserInfo.getUserId();
        acc.DuplicateConfirmedDate__c = System.today();
        update acc;


        //Submit records for approval
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(duplicateAccountId);
        req.setProcessDefinitionNameOrId('Account_Merge_Approval');
        req.setComments('Auto-submitted for Account merge approval.');

        try {
            Approval.ProcessResult result = Approval.process(req);
            if (result.isSuccess()) {
                recordsToUnlock.add(duplicateAccountId); // Add for unlocking only if submitted
            } else {
                throw new AuraHandledException('Approval submission for Merge failed!!');
            }
            //Unlock the records
            List<Approval.UnlockResult> unlockResults = Approval.unlock(new List<Id>{duplicateAccountId});
            for (Approval.UnlockResult unlockResult : unlockResults) {
                if (unlockResult.isSuccess()) {
                    System.debug('Successfully unlocked record: ' + unlockResult.getId());
                } else {
                    for (Database.Error err : unlockResult.getErrors()) {
                        System.debug('Unlock failed for ' + unlockResult.getId() + ': ' + err.getMessage());
                    }
                    throw new AuraHandledException(unlockResult.getErrors()[0].getMessage());
                }
            }
        } catch (AuraHandledException aex) {
            resetAccountRecord(duplicateAccountId, aex.getMessage());
            throw aex;
        } catch (Exception e) {
            resetAccountRecord(duplicateAccountId, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }

        return 'Merge request submitted for approval successfully.';
    }

    public static void resetAccountRecord(Id duplicateAccountId, String errorMsg) {
        Integer semiColonIndex = errorMsg.indexOf(';');
        String cleanedError = '';

        if (semiColonIndex != -1 && semiColonIndex + 1 < errorMsg.length()) {
            cleanedError = errorMsg.substring(semiColonIndex + 1).trim();
        }

        Account acc = new Account();
        acc.Id = duplicateAccountId;
        acc.EligibleForMerge__c = false;
        acc.MasterAccount__c = NULL;
        acc.Merging_Status__c = '';
        acc.Merging_Error_Message__c = cleanedError != '' ? cleanedError : errorMsg;
        acc.DuplicateConfirmedBy__c = NULL;
        acc.DuplicateConfirmedDate__c = NULL;
        update acc;
    }
}