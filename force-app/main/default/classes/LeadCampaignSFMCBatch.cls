global class LeadCampaignSFMCBatch implements Database.Batchable<sObject> {
    
    // Variables to hold the starting offset and limit
    private Integer LimitNumber;
    private String soqlString;
    
    // Constructor to initialize offset and limit
    global LeadCampaignSFMCBatch(Integer LimitNumber ) {
        this.LimitNumber = LimitNumber;
    }
    global LeadCampaignSFMCBatch(String soqlString ) {
        this.soqlString = soqlString;
    }
    
    // Start method to query the Leads with offset
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(soqlString != null){
            return Database.getQueryLocator(soqlString);
        }else{
            return Database.getQueryLocator('SELECT Id, Name, Company, Phone, Status,ExistingAccount__c FROM Lead WHERE CampaignMemberProcessed__c = false AND IsConverted= false ORDER BY OriginalCreationDate__c LIMIT:LimitNumber');
        }
    }
    
    // Execute method to process each Lead
    global void execute(Database.BatchableContext bc, List<Lead> scope) {
        try{
        CampaignMemberController.createCampaignMember(scope);
        List<Lead> leadList = new List<Lead>();
        for(Lead ld :scope){
            ld.CampaignMemberProcessed__c = true;
            leadList.add(ld);
        }
        if(!leadList.isEmpty()){
            LeadFirstMethodOfContactService.skipLeadTrigger = true;
            update leadList;
            LeadFirstMethodOfContactService.skipLeadTrigger = false;
        }
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'CampaignMemberController','createCampaignMember',scope[0].Id));
        }
          
    }
    
    // Finish method (optional) to execute post-processing logic
    global void finish(Database.BatchableContext bc) {
        // Optionally, perform any post-processing tasks
    }
}