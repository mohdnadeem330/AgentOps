global class MergeCustomersBatchNew  implements Schedulable, database.batchable<sObject>{
    private Set<Id> accountIds;
    
    global MergeCustomersBatchNew(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    global void execute(SchedulableContext sContext) {
        MergeCustomersBatchNew mergeAccountBatch = new MergeCustomersBatchNew(accountIds);
        database.executeBatch(mergeAccountBatch, 1);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String fields = getEditableFields();
        String query = 'SELECT '+ fields +' , IsDeleted FROM Account WHERE MasterAccount__c !=null AND MergedAccount__c = FALSE AND EligibleForMerge__c = TRUE ';
        
        if (!accountIds.isEmpty()) {
            query += ' AND Id IN :accountIds';
        }

        System.debug('---SCOPE Query --'+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
            List<Document__c> docList = new List<Document__c>();
            String fields = getEditableFields();
            String query = 'SELECT '+ fields +' FROM Account WHERE Id IN (\'' + scope[0].MasterAccount__c + '\')';
            List<Account> parentAccounts = Database.query(query);
            Account masterAcc = parentAccounts[0];
            Account childAcc = scope[0];
            
            docList = [SELECT Id,Account__c FROM Document__c WHERE Account__c =:childAcc.Id];
            System.debug('Parent Account : ' + masterAcc.id);
            System.debug('Child Account : ' + childAcc.id);
    
            AccountTriggerHandler.createAccountDocuments(new List<Account>{masterAcc});
            createAccountTeamMembers(new List<Id>{childAcc.Id});
            Database.MergeResult mr = Database.merge(masterAcc, childAcc, false);
            system.debug('--- mr-- '+mr);
            Map<Id,AccountTeamMember> atmMap = new Map<Id,AccountTeamMember>([SELECT Id FROM AccountTeamMember WHERE AccountId =:childAcc.Id]);
    
            if(mr.isSuccess()){
                Account restoredAccount = new Account(Id=childAcc.id);
                Undelete restoredAccount;
    
                List<document__c> documentsToUpdate = new List<document__c>();
    
                if(docList.size() > 0 ){
                    for(document__c doc : docList){
                        doc.Account__c = restoredAccount.Id;
                        documentsToUpdate.add(doc);
                    }
                    Update documentsToUpdate;
                }
    
                restoredAccount.MergedAccount__c = true;
                restoredAccount.MergedDate__c = date.today();
                restoredAccount.EligibleForMerge__c = false;
                restoredAccount.Merging_Status__c = 'Merge completed';
                restoredAccount.Sync_with_SFMC__pc = false;
                restoredAccount.Sync_with_SFMC__c = false;

                for(User u : [SELECT Id FROM User WHERE Name = 'Aldar Integration User']){
                    restoredAccount.ownerId = u.Id;
                }
    
                //Update restoredAccount;
    
                String childQuery = 'SELECT '+fields+' FROM Account WHERE Id IN (\'' + mr.getMergedRecordIds()[0] + '\')';
                childAcc = database.query(childQuery); 
                
                Set<String> skippedFields = new Set<String>();
                String customLabelValue = Label.Skipped_Account_Fields;
    
                if (!String.isBlank(customLabelValue)) {
                    for (String field : customLabelValue.split(',')) {
                        skippedFields.add(field.trim().toLowerCase());
                    }
                }
                
                List<String> allFields = fields.split(',');
                
                for (String fieldName : allFields) {
                    fieldName = fieldName.trim().toLowerCase();
                    if (skippedFields.contains(fieldName)) {
                        continue;
                    }
                    
                    Object masterValue = masterAcc.get(fieldName);
                    Object childValue = childAcc.get(fieldName);

                    if(fieldName == 'CustomerVertical__c' && masterValue != null && childValue != null) {
                        masterValue = mergeMultiSelect(childValue, masterValue);
                        masterAcc.put(fieldName, masterValue);
                    } else if (masterValue == null && childValue != null) {
                        masterAcc.put(fieldName, childValue);
                        if(checkFieldisExternalId(fieldMap, fieldName)) {
                            restoredAccount.put(fieldName, '');
                        }
                    }
                }
                
                List<Account> updateAccList = new List<Account>();
                //ADDED BY CHIRAG END
                
                updateAccList.add(restoredAccount);
                updateAccList.add(masterAcc);
                Update restoredAccount;
                Update masterAcc;
    
                List<Document__c> childDocuments = [SELECT ID, DocumentType__c, DocgenPackageId__c FROM Document__c WHERE Account__c =: childAcc.Id];
                List<Document__c> parentDocuments = [SELECT ID, DocumentType__c, DocgenPackageId__c FROM Document__c WHERE Account__c =: masterAcc.Id];
    
                if(childDocuments.size() > 0){
                    mapDocumentRecords(childDocuments, parentDocuments);
                }
            } else {
                Database.rollback(sp);
                Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(mr.getErrors()[0], 'Merge Accounts','MergeCustomersBatchNew', 'execute'));
                updateDuplicateAccount(scope[0].Id, mr.getErrors()[0].getMessage());
            }
        } catch(exception e) {
            Database.rollback(sp);
            Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(e, 'Merge Accounts','MergeCustomersBatchNew', 'execute'));
            updateDuplicateAccount(scope[0].Id, e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
    public static void updateDuplicateAccount(Id accId, String fullError) {
        Integer semiColonIndex = fullError.indexOf(';');
        String cleanedError = '';
        if (semiColonIndex != -1 && semiColonIndex + 1 < fullError.length()) {
            cleanedError = fullError.substring(semiColonIndex + 1).trim();
        }
        
        Account childAcc = new Account(Id=accId);
        childAcc.Merging_Status__c = 'Salesforce Merge Failed';
        childAcc.Merging_Error_Message__c = cleanedError != '' ? cleanedError : fullError;
        childAcc.Sync_with_SFMC__pc = true;
        childAcc.Sync_with_SFMC__c = true;
        childAcc.EligibleForMerge__c = true;
        update childAcc;

    }
    
    public static String getEditableFields() {
        Map<String, Schema.SObjectField> describeFlds = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
        List<String> accFields = new List<String>();

        for (String fld : describeFlds.keyset()) {
            if(!fld.equalsIgnoreCase('Name')){
                Schema.DescribeFieldResult fieldInfo = describeFlds.get(fld).getDescribe(); 
                if (fieldInfo.isCreateable() && !fieldInfo.isDeprecatedAndHidden() && ((fieldInfo.isCustom() && !fieldInfo.isCalculated()) || (!fieldInfo.isCustom() && !fieldInfo.isDefaultedOnCreate() && fieldInfo.isUpdateable()))) { // consider fields that are updatable
                    accFields.add(fld);
                }
            }
        }

        String fields = String.join(accFields,',');
        return fields;
    }
    
    public static void  mapDocumentRecords(List<Document__c> childDocuments, List<Document__c> parentDocuments){
        Map<String, Id> contentDocumentIdByDocTypeChild = new Map<String, Id>();
        //Map<String,Document__c> documentByDocTypeChild = new Map<String,Document__c>();
        Map<Id, document__c> childDocMap = new Map<Id, Document__c>(childDocuments);
        /* for(Document__c doc : childDocuments){
            documentByDocTypeChild.put(doc.DocumentType__c,doc);
            childDocMap.put(doc.Id,doc);
        }*/
        for(ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId  IN : childDocMap.keySet()]){
            if(childDocMap.containsKey(cdl.LinkedEntityId) && childDocMap.get(cdl.LinkedEntityId).DocgenPackageId__c == null){
                contentDocumentIdByDocTypeChild.put(childDocMap.get(cdl.LinkedEntityId).DocumentType__c, cdl.ContentDocumentId);
            }
        }

        List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
        for(Document__c doc : parentDocuments){
            if(contentDocumentIdByDocTypeChild.containsKey(doc.DocumentType__c)){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentIdByDocTypeChild.get(doc.DocumentType__c);//Add ContentDocumentId
                cdl.LinkedEntityId = doc.Id;//Add attachment parentId
                cdl.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cdl.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
                cdlToInsert.add(cdl);
            }
        }

        if(!cdlToInsert.isEmpty()){
	        Database.Insert(cdlToInsert,false);  //Added by Arvind 
        }
    }
   
    public static void createAccountTeamMembers(List<Id> childIds){
        List<Account> accountList = [SELECT Id, Owner.IsActive, OwnerId, MasterAccount__c, (SELECT Id, AccountId, UserId FROM AccountTeamMembers WHERE User.IsActive = TRUE) FROM Account WHERE EligibleForMerge__c = TRUE AND Owner.IsActive = TRUE AND Id=:ChildIds];
        List<AccountTeamMember> accountTeamsToInsert = new List<AccountTeamMember>();
        
        for(Account acc : accountList){
        //if(acc.Owner.IsActive){
            Boolean accessFound = false;

            for(AccountTeamMember atmc : acc.AccountTeamMembers){
                if(atmc.accountId == acc.Id && acc.OwnerId != atmc.userId){
                    accessFound = false;
                } else{
                    accessFound = true;
                }
            
                AccountTeamMember atm = new AccountTeamMember(AccountId = acc.MasterAccount__c,UserId = atmc.userId,AccountAccessLevel='Edit',CaseAccessLevel='None',OpportunityAccessLevel='None',TeamMemberRole='Sales Manager');
                accountTeamsToInsert.add(atm);
                
            }

            if(!accessFound){
                AccountTeamMember atm = new AccountTeamMember(AccountId = acc.MasterAccount__c,UserId = acc.OwnerId,AccountAccessLevel='Edit',CaseAccessLevel='None',OpportunityAccessLevel='None',TeamMemberRole='Sales Manager');
                accountTeamsToInsert.add(atm);
            }
        //}
        }
        system.debug('accountTeamsToInsert '+accountTeamsToInsert);

        Insert accountTeamsToInsert;
    }

    /**
     * Merges two multi-select picklist strings into one, removing duplicates.
     * 
     * @param duplicatePicklist The picklist string from the duplicate record
     * @param masterPicklist The picklist string from the master record
     * @return Merged multi-select picklist string
     */
    public static Object mergeMultiSelect(Object duplicatePicklistObj, Object masterPicklistObj) {
        Set<String> mergedValues = new Set<String>();
        String duplicatePicklist = (String)duplicatePicklistObj;
        String masterPicklist = (String)masterPicklistObj;
        // Add values from the duplicate picklist
        if (String.isNotBlank(duplicatePicklist)) {
            List<String> duplicateValues = duplicatePicklist.split(';');
            for (String val : duplicateValues) {
                mergedValues.add(val.trim());
            }
        }

        // Add values from the master picklist
        if (String.isNotBlank(masterPicklist)) {
            List<String> masterValues = masterPicklist.split(';');
            for (String val : masterValues) {
                mergedValues.add(val.trim());
            }
        }

        // Return sorted merged values as a semicolon-separated string
        List<String> resultList = new List<String>(mergedValues);
        resultList.sort();  // Optional: sort alphabetically
        return (Object)String.join(resultList, ';');
    }

    public static Boolean checkFieldisExternalId(Map<String, Schema.SObjectField> fieldMap, String fieldApiName) {
        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
    
        if (fieldDescribe.isExternalID()) {
            return true;
        }

        return false;
    }
    
}