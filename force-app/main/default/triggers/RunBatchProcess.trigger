trigger RunBatchProcess on StartBatchProcess__e (After Insert) {
    for (StartBatchProcess__e event : Trigger.New) {
        if (event.BatchType__c == 'MergeCustomersBatchNew') {
            Set<Id> accountIds = new Set<Id>();
            for (String s : event.RecordIds__c.split(',')) {
                accountIds.add((Id)s);
            }
            // Start the batch
            MergeCustomersBatchNew mergeAccountBatch = new MergeCustomersBatchNew(accountIds);
            database.executeBatch(mergeAccountBatch, 1);
        }
    }
}