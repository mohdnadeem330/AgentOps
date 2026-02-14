global class ScheduledOutstandingAccountBatch implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        Boolean isEnabled = BatchUpdateOutstandingAmountAccs__c.getOrgDefaults().Enable_Outstanding_Balance_Check__c;
        System.debug('Outstanding Check Flag: ' + isEnabled);
        if(isEnabled){
            
            BatchUpdateOutstandingAccounts batchClass = new BatchUpdateOutstandingAccounts();
            Database.executeBatch(batchClass, 100);
            
        }
    }
}

/*
String cronExp = '0 0 2 * * ?';  
ScheduledOutstandingAccountBatch schedBatch = new ScheduledOutstandingAccountBatch();
System.schedule('Daily Outstanding Account Batch', cronExp, schedBatch);
*/