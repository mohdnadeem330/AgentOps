global class CloseOpportunities implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query for opportunities created more than 90 days ago and still open
       // Date ninetyDaysAgo = Date.today().addDays(-90);
       //ASF-3667 Added by Syed Noormohamad
       Date fortyFiveDaysAgo = Date.today().addDays(-45);

        return Database.getQueryLocator([SELECT Id, StageName FROM Opportunity WHERE StageName != 'Closed Lost' AND StageName != 'Closed Won' AND RecordType.Name = 'New Sale' AND
                                         CreatedDate < :fortyFiveDaysAgo and LeadSource != 'Broker Portal' and Project__c != 'Balghaiylam'
                                        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        // Update opportunities to Closed status
        for(Opportunity opp : scope) {
            opp.StageName = 'Closed Lost';
            opp.AutoCloseOpportunity__c = true;
            opp.LossReason__c = 'Lost - Future Potential';
            opp.LossComments__c = 'Auto Close after 45 Days';
            // Change 'Closed' to your desired closed status
            opportunitiesToUpdate.add(opp);
        }
        
        // Perform the update
        if(!opportunitiesToUpdate.isEmpty()) {
            DATABASE.update(opportunitiesToUpdate, false);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Optionally, you can add some finishing logic here
    }
    public void execute(SchedulableContext sch)
    {
        Id JObId = Database.executeBatch(new CloseOpportunities());
        system.debug('JObId'+JObId);
    }
}