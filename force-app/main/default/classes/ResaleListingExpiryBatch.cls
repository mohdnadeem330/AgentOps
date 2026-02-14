public class ResaleListingExpiryBatch implements Schedulable, Database.Batchable<SObject>{
    public ResaleListingExpiryBatch() {
        // default constructor
    }

    public void execute(SchedulableContext scon) {
        Database.executeBatch(new ResaleListingExpiryBatch(), 50);
    }
        
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT Id, Status
            FROM Case
            WHERE ( Status =: ResaleConstants.CASE_PROPERTY_LISTED )
                AND Expiry_Date__c != null AND Expiry_Date__c <= TOMORROW
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Case> scope){
        for(Case cs : scope){
            cs.Status = ResaleConstants.CASE_CANCELLED;
            cs.CancellationReason__c = ResaleConstants.CASE_CANCELLATION_REASON_OTHER;
        }
        update scope;
    }
    
    public void finish(Database.BatchableContext BC){

    }
}