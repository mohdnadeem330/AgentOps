global class CommunicationTryBatch implements Database.Batchable<sObject>
{
    List<Communication__c> childRecordsReceived = new List<Communication__c>();
    Id communicationRecTemId;
    Id bannerId;
    
    public CommunicationTryBatch(List<Communication__c> receivedCommRecords,Id communicationRecTemId,Id bannerId){
        this.childRecordsReceived.addAll(receivedCommRecords);
        this.communicationRecTemId = communicationRecTemId;
        this.bannerId = bannerId;
    }
    
    global List<Communication__c> start(Database.BatchableContext bc) {
        //String query='select id, Agency__c,Agency__r.Email__c,Agency__r.MobileCountryCode__c,Agency__r.MobileNumber1__c, Agent__c,Agent__r.MobileCountryCode__c,Agent__r.MobilePhone__c, Recipient__c,CommunicationTemplate__c,Recipient__r.MobilePhone from Communication__c where CommunicationTemplate__c = :templateId and Status__c != \'Sent\' order by CommunicationTemplate__c';
        //return Database.getQueryLocator(query);
        return childRecordsReceived;
    }
    
    global void execute(Database.BatchableContext bc, List<Communication__c> scope)
    {
        Database.Insert(scope, false);
    }
    
    global void finish(Database.BatchableContext bc)
    {
        Database.executeBatch(new CommunicationBatch(communicationRecTemId, bannerId),200);
    }
    
}