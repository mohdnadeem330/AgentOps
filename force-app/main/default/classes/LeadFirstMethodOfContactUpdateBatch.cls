global class LeadFirstMethodOfContactUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    public dateTime finalCreatedDate;
    public dateTime finalEndDate;
    public boolean executeSkipRecords;
    global LeadFirstMethodOfContactUpdateBatch(dateTime startDate, dateTime finalEndDate,boolean executeSkipRecords){
        this.finalCreatedDate = startDate;
        this.finalEndDate = finalEndDate;
        this.executeSkipRecords = executeSkipRecords;
    }
    
	global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime dtFinalCreatedDate = this.finalCreatedDate;
        datetime finalEndDate = this.finalEndDate;
        String strStatus = 'Retired Lead';
        String query = 'SELECT Email,MobilePhone,CreatedDate,LeadSource,LeadNumber__c,FirstMethodofContact__c,EnquiryCategory__c,EnquiryTrigger__c,FirstEnquiryCategory__c,FirstEnquiryTrigger__c FROM Lead WHERE CreatedDate>=:dtFinalCreatedDate AND CreatedDate <=: finalEndDate ';
        if(executeSkipRecords){
            query += ' AND FirstEnquiryCategory__c = null ';
        }
         query += ' ORDER BY CreatedDate ASC';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<lead> lstLeads){ 
        map<String,Lead> mapLeadNumbers = new map<String,Lead>();
        LeadFirstMethodOfContactService.updateLeadFirstMethodofContact(lstLeads, mapLeadNumbers);
        if(!mapLeadNumbers.isEmpty()){
            LeadFirstMethodOfContactService.updateSalesOrderFirstMethodofContactRelatedLeads(mapLeadNumbers);
        }
    }
    
    global void finish(Database.BatchableContext bc){}
}