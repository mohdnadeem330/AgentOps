public without sharing class AccountMergeUtility {
    
    public static map<String,Account> uniqueKeyAccountMap = new map<String,Account>();
    public static map<Id,Account> parentAccountIdMap = new  map<Id,Account>();
    public static Map<String, MasterAccountPriorityField__mdt> masterFieldsMap;
    public static Map<String, SObjectField> accountFieldsMap;
    public static Map<Id,List<SalesOrder__c>> accountOpportunityUnitMap ;

     /*
    * Merge accounts based on the unique keys
    */
    public static List<Account> checkForDuplicateAccounts(List<Account> accountList){

        Set<String> uniqueKey1List = new Set<String>();
        Set<String> uniqueKey2List = new Set<String>();
        Set<String> uniqueKeyOrganisation = new Set<String>();  
        Set<String> uniqueKey2Organisation = new Set<String>();     
        Map<String,Set<Id>> uniqueKeyAccountIdMap = new Map<String,Set<Id>>();
        Set<Id> accountIds = new Set<Id>();

         //------ Add Unique Fields to the set for Querying
         for(Account accountRecord: accountList){
            accountRecord.ExistingAccount__c = null ;
            if(accountRecord.Id != null)
                accountIds.add(accountRecord.Id);
            if((accountRecord.Id != null && accountRecord.isPersonAccount) || (accountRecord.LastName != null)) {                
                if(String.isNotBlank(getUniqueKeyOfAccount(accountRecord,'UniqueKey1__c')))
                    uniqueKey1List.add(accountRecord.UniqueKey1__c.toLowerCase());
                if(String.isNotBlank(getUniqueKeyOfAccount(accountRecord,'UniqueKey2__c')))
                    uniqueKey2List.add(accountRecord.UniqueKey2__c.toLowerCase());
            }else{
                if(String.isNotBlank(getUniqueKeyOfAccount(accountRecord,'UniqueKey1__c')))
                    uniqueKeyOrganisation.add(accountRecord.UniqueKey1__c.toLowerCase());   
                if(String.isNotBlank(getUniqueKeyOfAccount(accountRecord,'UniqueKey2__c')))
                    uniqueKey2Organisation.add(accountRecord.UniqueKey2__c.toLowerCase());             
            }      
        }

        System.debug('Unique 1 List'+uniqueKey1List+' Unique 2 List'+uniqueKey2List);

        //----- Fetch Accounts based on Unique Keys for Person Accounts
       if(!uniqueKey1List.isEmpty() || !uniqueKey2List.isEmpty()){
                Id personAccountRT = Utilities.getRecordTypeId(Constants.ACCOUNT_OBJECT,Constants.PERSON_ACCOUNT_RT);
                for(Account existingAccount : AccountService.queryAllFieldsForDuplicateAccounts(uniqueKey1List,uniqueKey2List,personAccountRT,accountIds)){
                        uniqueKeyAccountIdMap = getUniqueKeyOfAccount(existingAccount,'UniqueKey1__c',uniqueKeyAccountIdMap);
                        uniqueKeyAccountIdMap = getUniqueKeyOfAccount(existingAccount,'UniqueKey2__c',uniqueKeyAccountIdMap);
                    }
        }

         //----- Fetch Accounts based on Unique Keys for Organisation Accounts
         if(!uniqueKeyOrganisation.isEmpty()){
            Id organisationAccountRT = Utilities.getRecordTypeId(Constants.ACCOUNT_OBJECT,Constants.ORGANISATION_ACCOUNT_RT);
                for(Account existingAccount : AccountService.queryAllFieldsForDuplicateAccounts(uniqueKeyOrganisation,new Set<String>(),organisationAccountRT,accountIds)){
                        uniqueKeyAccountIdMap = getUniqueKeyOfAccount(existingAccount,'UniqueKey1__c',uniqueKeyAccountIdMap);             
                }
        }

        System.debug('--AccountIds--'+accountIds);
        System.debug('Exisiting Account with Key '+uniqueKeyAccountMap);
        System.debug('Exisiting Account Id with Key '+uniqueKeyAccountIdMap);

            if(uniqueKeyAccountIdMap.keySet().size()>0){
                 for(Account accountRecord: accountList){
                    if(getParentAccountId(accountRecord,'UniqueKey1__c',uniqueKeyAccountIdMap).ExistingAccount__c ==null)
                        if(getParentAccountId(accountRecord,'UniqueKey2__c',uniqueKeyAccountIdMap).ExistingAccount__c ==null){
                            accountRecord.ExistingAccount__c = null  ;
                   
                        }
                 }           
             }

        return accountList;
    }


     /*
    *   Get Unique Key Value of account.
    */
    public static String getUniqueKeyOfAccount(Account accountRecord,String uniqueKeyAPI){
        String uniqueKeyValue = '' ;
        if(String.isNotBlank(String.valueOf(accountRecord.get(uniqueKeyAPI))))
                uniqueKeyValue = String.valueOf(accountRecord.get(uniqueKeyAPI));
        return uniqueKeyValue ;
    }

    /*
    *   Build existing Accounts Map for unique keys
    */
    public static Map<String,Set<Id>> getUniqueKeyOfAccount(Account existingAccount,String uniqueKeyAPI,Map<String,Set<Id>> uniqueKeyAccountIdMap){
        if(String.isNotBlank(String.valueOf(existingAccount.get(uniqueKeyAPI)))){
            String uniqueKey = UniqueKeyUtility.formatStringValue(String.valueOf(existingAccount.get(uniqueKeyAPI)));
            uniqueKeyAccountMap.put(uniqueKey,existingAccount); 
            parentAccountIdMap.put(existingAccount.Id,existingAccount);
            if(uniqueKeyAccountIdMap.containsKey(uniqueKey))
                uniqueKeyAccountIdMap.get(uniqueKey).add(existingAccount.Id);
            else
                uniqueKeyAccountIdMap.put(uniqueKey,new Set<Id>{existingAccount.Id});
        }
        return uniqueKeyAccountIdMap ;
    }

    /*
    * Get Account with Parent Account for the unique key
    */
    public static Account getParentAccountId(Account accountRecord,String uniqueKeyAPI,Map<String,Set<Id>> uniqueKeyAccountIdMap){
        String uniqueKeyValue = String.valueOf(accountRecord.get(uniqueKeyAPI));       
        if(String.isNotBlank(getUniqueKeyOfAccount(accountRecord,uniqueKeyAPI)) && uniqueKeyAccountIdMap.containsKey(uniqueKeyValue)){
            for(Id accountId : uniqueKeyAccountIdMap.get(uniqueKeyValue)){
                if(accountRecord.Id  !=accountId){
                    accountRecord.ExistingAccount__c = accountId ;
                    accountRecord.ExistingAccount__r = parentAccountIdMap.get(accountId) ;
                }
            }                                  
        }
        return accountRecord ; 
    }

     /*
     * This method takes care of either merging the child with it's master if a duplicate is found and a merge is allowed or normally upserting the record if no duplicate is found or a merge is not allowed.
     * Returns a list of master accounts corresponding to the given list of childAccounts.
     */
    public static List<Account> mergeAccountsWithParents(List<Account> childAccounts) {

        Set<Id> accountIds = new Set<Id>();
        List<Account> masterRecords = new List<Account>();
        List<Account> accountsToUpsert = new List<Account>();

        for(Account childAccount : childAccounts){
            //---- Get all accounts to verify the sales order list
            accountIds.add(childAccount.Id);
            accountIds.add(childAccount.ExistingAccount__c);
        }

        accountOpportunityUnitMap = SalesOrderService.getAccountOpportunityUnitMap(accountIds);

        for (Account childAccount : childAccounts) {
            Account parentAccount = childAccount.ExistingAccount__r;

            //------ If we have a duplicate found
            if (parentAccount != null) {
                //----- If the child does not have an Id, populate the child on the parent, and get rid of the child, update the parent
                if (String.isBlank(childAccount.Id)) {
                    System.debug('Populate child on master, ignore child');
                    Account newParentAccount = populateMasterFromChild(parentAccount, childAccount, false);
                    accountsToUpsert.add(newParentAccount);
                    masterRecords.add(newParentAccount);
                }
                else{
                //---- If child is existing account, find out which is the master using the findMaster method and populate the fields from the child on the master. Merge and get the Id of the master record merge. If no master is found use the child record.
                    List<Account> masterChild = findMaster(childAccount);
                    if (masterChild == null) {
                        System.debug('No master found.');
                        accountsToUpsert.add(childAccount);
                        masterRecords.add(childAccount);
                    }
                    else{
                        System.debug('Master found, merge');
                        Account masterAccount = masterChild[0];
                        if (masterAccount.Id == childAccount.Id)
                            masterAccount = populateMasterFromChild(masterChild[0], masterChild[0], true);
                        else if (masterAccount.Id != childAccount.Id)
                            masterAccount = populateMasterFromChild(masterChild[0], masterChild[1], false);
                        Account master = new Account(Id = masterChild[0].Id);
                        Account child = new Account(Id = masterChild[1].Id);
                        Database.merge(master, child, false);
                        masterChild[0].ExistingAccount__r = null;
                        masterChild[0].ExistingAccount__c = null;
                        masterAccount.ExistingAccount__c = null ;
                        masterAccount.ExistingAccount__r = null ;
                        accountsToUpsert.add(masterAccount);
                        masterRecords.add(masterAccount);    
                    }
                }
            }
            else {
                System.debug('No duplicate found. '+childAccount);
                accountsToUpsert.add(childAccount);
                masterRecords.add(childAccount);
            }
        }
        System.debug('**AccountsToUpsert**'+accountsToUpsert);
        if(!accountsToUpsert.isEmpty())
            upsert accountsToUpsert;

        return masterRecords ;
    }

     /*
     * Populates the field values of child account on parent account, taking into consideration the master account priority fields.
     * If forceUpdate is set to true, the fields on the parent are updated from the child regardless of the priority fields.
     * The priority fields are a list of fields from the MasterAccountPriorityField metadata indicating which fields should not be overriden by the child.
     */
    public static Account populateMasterFromChild(Account parentAccount, Account childAccount, Boolean forceUpdate) {
        Account newParentAccount = new Account();

        //---- Prepare map of the fields which should not be updated on the master from the child.
        if (masterFieldsMap == null && !forceUpdate) {
            
            List<MasterAccountPriorityField__mdt> masterFields = new List<MasterAccountPriorityField__mdt>();
            masterFields = [SELECT Label, PersonAccount__c, OrganisationAccount__c, IsStrict__c FROM MasterAccountPriorityField__mdt];
            masterFieldsMap = new Map<String, MasterAccountPriorityField__mdt>();
            
            for (MasterAccountPriorityField__mdt masterField : masterFields) {
                masterFieldsMap.put(masterField.Label.toLowerCase(), masterField);
            }
        }

        //---- Prepare the map of all account fields
        if (accountFieldsMap == null){
            Schema.DescribeSObjectResult dsr = Account.sObjectType.getDescribe();
            accountFieldsMap = dsr.fields.getMap();
        }

        //---- Get Child Account fields into a map
        Map<String, Object> childAccountMap = childAccount.getPopulatedFieldsAsMap();
        System.debug('Child Account Map '+childAccountMap);

        //---- Check if both the child and parent records are of the same type (Person/Organisation), unless forceUpdate is set to true
        Boolean isChildPerson = (String.isNotBlank(childAccount.Id) && childAccount.IsPersonAccount) || (String.isNotBlank(childAccount.LastName));
        Boolean isParentPerson = (String.isNotBlank(parentAccount.Id) && parentAccount.IsPersonAccount) || (String.isNotBlank(parentAccount.LastName));

        if ((isChildPerson != isParentPerson) && !forceUpdate)
            throw new Exceptions.UpdatingAccountsWithDifferentTypesException();            

        if(childAccount.Id ==parentAccount.Id && isParentPerson){
                System.debug(isParentPerson+'Child account same as Parent Account '+childAccount);
                return childAccount ;                
        }

        for(String fieldAPI : accountFieldsMap.keySet()){
            Boolean skipMapping = false ;
            SObjectField accountField = accountFieldsMap.get(fieldAPI);

             //------ When Broker Agecncy or when it is Person Account, name mapping has to be skipped
            if(fieldAPI == 'IsPartner' || fieldAPI == 'IsCustomerPortal' || (String.isNotBlank(childAccount.LastName) && String.valueOf(fieldAPI) =='name')){
                skipMapping = true;
            }

            System.debug('SkipMapping :'+skipMapping+' isParentPerson :'+isParentPerson+' PersonAccount field: '+String.valueOf(fieldAPI).contains('__pc'));

            MasterAccountPriorityField__mdt masterField = forceUpdate ? null : masterFieldsMap.get(fieldAPI);
            
            Boolean isUpdateable = accountField.getDescribe().isUpdateable();
            Boolean isChildValueEmpty = true;
            Boolean isChildFieldQueried = false;

            //----In case the field is not queried, childAccount.get throws an exception. This is handled gracefully.  
            if(childAccountMap.containsKey(accountField.getDescribe().getName()) && (childAccount.get(fieldAPI) == null)){
                    isChildValueEmpty = true ;  
                    isChildFieldQueried = true;
            }else if(childAccountMap.containsKey(accountField.getDescribe().getName()) && (childAccount.get(fieldAPI) != null || childAccount.get(fieldAPI) == true)){
                    isChildValueEmpty = false;
                    isChildFieldQueried = true;
            }else if(childAccount.get(fieldAPI) == null || childAccount.get(fieldAPI) == false){
                     isChildValueEmpty = true;
                     isChildFieldQueried = false ;
            }                                                
            
            System.debug(' Account Field is '+fieldAPI+' Child Value is'+childAccount.get(fieldAPI)+' Is Updateable ? '+isUpdateable);
            System.debug('isChildValueEmpty '+isChildValueEmpty+' isChildFieldQueried '+isChildFieldQueried+' - '+fieldAPI);
                      

            if (isUpdateable && !skipMapping && (isParentPerson || (!isParentPerson && !String.valueOf(fieldAPI).contains('__pc') ))) { 
                if(childAccount.Id ==parentAccount.Id && !isParentPerson && isChildFieldQueried){
                    newParentAccount.put(fieldAPI, childAccount.get(fieldAPI));
                    System.debug('Child account same as Parent Account '+childAccount.get(fieldAPI));
                }             
                else if(!isChildValueEmpty && isChildFieldQueried){                    
                    if (masterField != null) {
                        
                        system.debug('Master field: ' + fieldAPI);
                        //Check if the field is applicable for the Account's type (Person or Organisation)
                        Object parentAccountValue = parentAccount.get(fieldAPI);
                        Boolean isParentValueEmpty = parentAccountValue == null;
                        system.debug('Master field Empty? ' + isParentValueEmpty);
                        Boolean isValidForAccountType = (isParentPerson != null && masterField.PersonAccount__c) || (!isParentPerson && masterField.OrganisationAccount__c);
                        system.debug('Is Valid? ' + isValidForAccountType);
                        
                        //If the master field should not be overriden by the child, regardless of whether the value on the master
                        //is null or not, then we skip the override.
                        if (!(masterField.isStrict__c && isValidForAccountType)) {

                            //If the priority field is not valid for the account type we are working with, or if the parent value
                            //is empty, then it is safe to override.
                            if (!isValidForAccountType || isParentValueEmpty)
                                newParentAccount.put(fieldAPI, childAccount.get(fieldAPI));
                            else //Added new
                                newParentAccount.put(fieldAPI, parentAccount.get(fieldAPI));     
                        }
                         system.debug('Parent field: ' + newParentAccount.get(fieldAPI));
                    }
                    else {
                            //---- If the field is not a master priority field, then update the parent with the child.
                            system.debug('Not Master Field: ' + fieldAPI +' Value '+childAccount.get(fieldAPI));
                            if(childAccount.get(fieldAPI) !=null)
                                newParentAccount.put(fieldAPI, childAccount.get(fieldAPI));
                    }                   
            
                }else if(parentAccount.get(fieldAPI) !=null){     
                    system.debug('Not Child Field: ' + fieldAPI +' Value '+parentAccount.get(fieldAPI));             
                    newParentAccount.put(fieldAPI, parentAccount.get(fieldAPI));
                }         
            }   
        }

        newParentAccount.Id = parentAccount.Id ;
        System.debug('New Parent Account is : '+newParentAccount);
        return newParentAccount ;
    }

    /*
     * Finds the master between an account and it's parent account.
     */
    public static List<Account> findMaster(Account duplicateAccount){
            
        Account masterAccount ;
        Account childAccount ;

        //----- Check if both don't sales order associated with it
        if(accountOpportunityUnitMap==null || (!accountOpportunityUnitMap.containsKey(duplicateAccount.Id) && !accountOpportunityUnitMap.containsKey(duplicateAccount.ExistingAccount__c))){
            masterAccount = duplicateAccount;
            childAccount = duplicateAccount.ExistingAccount__r;
        }
        //----- If parent has the sales order
        else if(accountOpportunityUnitMap !=null && accountOpportunityUnitMap.containsKey(duplicateAccount.Id) && !accountOpportunityUnitMap.containsKey(duplicateAccount.ExistingAccount__c)){
            masterAccount = duplicateAccount.ExistingAccount__r ;
            childAccount = duplicateAccount;
        }
        //----- If duplicate account has the sales order
        else if(accountOpportunityUnitMap !=null && !accountOpportunityUnitMap.containsKey(duplicateAccount.Id) && accountOpportunityUnitMap.containsKey(duplicateAccount.ExistingAccount__c)){
            masterAccount = duplicateAccount;
            childAccount = duplicateAccount.ExistingAccount__r;
        }

        if (childAccount == null && masterAccount == null)
            return null;
        else 
            return new List<Account>{masterAccount, childAccount}; 
    }

        /**
     * Upserts the given list of accounts on the Id, and returns the list back
     * with the duplicate accounts replaced by their master accounts. The order of the
     * list is maintained.
     */
    public static List<Account> upsertAccounts(List<Account> accounts) {

        TriggerControlVariables.stopTriggerForDuplicates = false;

        system.debug('Accounts : '+accounts);
        
        List<Account> childAccounts = queryInsertedAccounts(accounts);
        //----- Unique Keys are updated on the child Accounts
        AccountService.updateUniqueKeys(childAccounts);
        //----- Parent is populated for the Accounts which have duplicates in the system
        AccountMergeUtility.checkForDuplicateAccounts(childAccounts);
        system.debug('childAccounts : '+childAccounts);
        //----- Do any merge or updates that are necessary
        List<Account> masterAccounts = AccountMergeUtility.mergeAccountsWithParents(childAccounts);
        system.debug('masterAccounts : '+masterAccounts);

        TriggerControlVariables.stopTriggerForDuplicates = true;
        //----- Return the master records in the same order of the given accounts.
        return masterAccounts;
    }
    
    public static Account upsertAccount(Account acc){
        return upsertAccounts(new List<Account>{acc})[0];
    }

     /** 
     * Returns a list of accounts corresponding to the given list of accounts
     * where the already inserted accounts (accounts that have an Id) are replaced 
     * with queried accounts.
     **/
    public static List<Account> queryInsertedAccounts(List<Account> accounts) {

        List<String> accountIds = new List<String>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        List<Account> queriedAccounts = AccountService.queryAllFieldsForAccountIds(accountIds);
        Map<Id, Account> IdToAccountMap = new Map<Id, Account>();

        for (Account acc : queriedAccounts) {
            if (acc.Id != null) {
                IdToAccountMap.put(acc.Id, acc);
            }
        }

        List<Account> childAccounts = new List<Account>();

        for(Account acc : accounts) {
            if (acc.Id != null) {

                Account queriedAccount = IdToAccountMap.get(acc.Id);
                if (queriedAccount != null) {
                    System.debug('QueriedAccount '+queriedAccount);
                    Account newParentAccount = AccountMergeUtility.populateMasterFromChild(queriedAccount, acc, true);
                    System.debug('PopulatedAccount '+newParentAccount);
                    childAccounts.add(newParentAccount);
                }
            }
            else
                childAccounts.add(acc);
        }

        return childAccounts;
    }

}