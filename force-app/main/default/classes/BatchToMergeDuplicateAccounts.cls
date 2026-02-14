global class BatchToMergeDuplicateAccounts implements Schedulable, database.batchable<sObject>{

        global void execute(SchedulableContext sContext) {
            BatchToMergeDuplicateAccounts mergeAccountBatch = new BatchToMergeDuplicateAccounts ();
            database.executeBatch(mergeAccountBatch,1);
        }
    
        global Database.QueryLocator start(Database.BatchableContext BC) {
            Set<String> accFieldList = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
            List<String> strList = new List<String>();
            strList.addAll(accFieldList);
            String fields = string.join(strList,',');
            String query = 'SELECT ' + fields + ' FROM Account WHERE ExistingAccount__c !=null';
            System.debug('Query --'+query);
            return Database.getQueryLocator(query);
        }
    
        global void execute(Database.BatchableContext BC, List<Account> scope) {
    
                List<Id> parentAccounts = new List<Id>();
                List<Account> childAccounts = new List<Account>(scope);
                system.debug('Child Accounts Count'+childAccounts.size());
    
                //----- Get all the child records
                for (Account childAccount : childAccounts) {
                    parentAccounts.add(childAccount.ExistingAccount__c);
                }
                system.debug('**Parent Accounts**'+parentAccounts);
    
                Map<Id,Account> parentAccountsMap =  new Map<Id,Account>();
    
                for(Account parentAccount : AccountService.queryAllFieldsForAccountIds(parentAccounts)){
                    parentAccountsMap.put(parentAccount.Id,parentAccount);
                }
                system.debug('Parent Accounts'+parentAccountsMap);
    
                for(Account childAccount : childAccounts){
                    if(parentAccountsMap.containsKey(childAccount.ExistingAccount__c))
                        childAccount.ExistingAccount__r = parentAccountsMap.get(childAccount.ExistingAccount__c) ;
                }
                system.debug('Child Accounts'+childAccounts);
    
                //----- Do Merge of the accounts
                List<Account> masterAccounts = AccountMergeUtility.mergeAccountsWithParents(childAccounts);   
            
        }
    
    
        global void finish(Database.BatchableContext BC) {
            
        }
    
    }