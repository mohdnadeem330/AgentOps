global class IdentifyAccountDuplicate implements  database.batchable<sObject>,Database.Stateful{
    public Integer duplicateCount = 0;
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String fields = MergeCustomersBatchNew.getEditableFields();
        String query = 'SELECT Id,name,PersonEmail, MobilePhone__pc ,CreatedDate,NationalIdNumber__pc FROM Account WHERE MasterAccount__c =null AND MergedAccount__c = false AND RecordType.Name = \'Person Account\'   and NationalIdNumber__pc != \'\' and MobilePhone__pc != \'\' and PersonEmail != \'\' order by NationalIdNumber__pc';
        System.debug('---SCOPE Query --'+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        accountsToUpdate = IdentifyDuplicatesForAccount.identifyDuplicates(scope,false);
        system.debug('++=accountsToUpdate  '+accountsToUpdate);
        duplicateCount += accountsToUpdate.size();
       
        List<Database.SaveResult> updateResults= Database.update(accountsToUpdate,false);
        List<Logger__c> loggerList = new List<Logger__c>();
        for(Database.SaveResult result:updateResults){
            system.debug('++result '+result);
            if (!result.isSuccess()) {
                //result.getId();
                for(Database.Error error : result.getErrors()) {
                    system.debug('error::'+error.getMessage());
                    String errorMessage = result.getId() + ' - ' + error.getStatusCode() + ': ' + error.getMessage() + ' Fields that affected the error: ' + error.getFields();
                    Logger__c newLog = new Logger__c(Message__c = errorMessage,ExecutingProcessName__c = 'IdentifyAccountDuplicate',ExceptionLogId__c = 'IdentifyAccountDuplicate'+string.valueof(system.now()));
                    loggerList.add(newLog);
                }
            }
        } 
        if(loggerList.size() > 0){
            Insert loggerList;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        system.debug('duplicateCount '+duplicateCount);
    }
}