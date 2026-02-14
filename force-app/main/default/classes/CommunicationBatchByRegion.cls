/*
*************************************************************************************************************************
Apex Class Name    : CommunicationBatchByRegion
Created Date       : Aug 01, 2025
@description       : This class used to send Communication for Specific Emirates (Calling from CommunicationController)
@author            : Moh Sarfaraj

Modification Log:
Ver   Date              Author                               Modification
1.0   01-08-2025      Moh Sarfaraj                          Initial Version
*************************************************************************************************************************
*/
global class CommunicationBatchByRegion implements Database.Batchable<SObject>, Database.stateful {
    public String regionName;
    public String emirateName;
    public String templateId;
    public String testEmail;
    public String bannerId;
    CommunicationTemplate__c templateRecord;
    Set<Id> contactIds = new Set<Id>();
    List<Communication__c> communicationsToInsert = new List<Communication__c>();

    global CommunicationBatchByRegion(String regionName, String emirateName, String templateId, String testEmail, String bannerId) {
        this.regionName = regionName;
        this.emirateName = emirateName;
        this.templateId = templateId;
        this.testEmail = testEmail;
        this.bannerId = bannerId;

        this.templateRecord = [SELECT Id,Name,Status__c,Compliance__c,SuspensionEndDate__c, SuspensionStartDate__c,Offense__c,Title__c,
                               PlainTextBody__c,HTMLBody__c FROM CommunicationTemplate__c where id = :templateId WITH SECURITY_ENFORCED LIMIT 1];
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> setAgencyRecordTypeIds = new Set<Id>{Constants.BROKER_AGENCY_RECORD_TYPE_ID, Constants.NON_REGISTERED_TYPE_ID};
        String query = 'SELECT Id, Name, BillingCountry FROM Account WHERE RecordTypeId IN : setAgencyRecordTypeIds ';

        if(String.isNotBlank(emirateName)){
            query += ' AND BillingState = :emirateName ';
        }

        if(String.isNotBlank(regionName)){
            query += ' AND AgencyRegion__c = :regionName ';
        }
        query += ' ORDER BY Name';

        return Database.getQueryLocator(query);
       
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        Set<Id> accountIds = new Set<Id>();
        for (SObject obj : scope) {
            accountIds.add(((Account)obj)?.Id);
        }

        Map<Id, User> userMap = new Map<Id, User>();
        if (!accountIds.isEmpty()) {
            userMap = new Map<Id, User>([SELECT Id, AccountId, ContactId, FirstName, LastName, Email FROM User WHERE 
                                        AccountId IN :accountIds AND IsActive = TRUE WITH SECURITY_ENFORCED]);
        }
        // Remove already existing communication recipients
        for (Communication__c comm : [SELECT Id, Recipient__c FROM Communication__c WHERE CommunicationTemplate__c = :templateId WITH SECURITY_ENFORCED]) {
            userMap.remove(comm.Recipient__c);
        }
        
        if(!userMap.isEmpty()){
            for (User u : userMap.values()) {
                if (!contactIds.contains(u?.ContactId)) {
                    communicationsToInsert.add(
                        new Communication__c(
                            CommunicationTemplate__c = templateId,
                            Agency__c = u?.AccountId,
                            Agent__c = u?.ContactId,
                            Recipient__c = u?.Id
                        )
                    );
                    contactIds.add(u?.ContactId);
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        if(!communicationsToInsert.isEmpty() && templateRecord?.Status__c == 'Published'){
            Database.executeBatch(new CommunicationTryBatch(communicationsToInsert, templateRecord?.Id, bannerId));
        }

        if(testEmail != null && testEmail != ''){
            CommunicationController.sendTestEmail(templateRecord, testEmail, bannerId);
        }
    }
}