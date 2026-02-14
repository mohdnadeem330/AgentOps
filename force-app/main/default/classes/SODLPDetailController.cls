public with sharing class SODLPDetailController {
    
    @AuraEnabled(cacheable=true)
    public static SalesOrder__c getSODetails(String recordID) {
       list<SalesOrder__c> tempRecord = [select id,Name,CustomerDLPStatus__c,AMCStatus__c,PMAStatus__c, DLPDate__c,Unit__r.DLPZone__r.ContractorDLPStatus__c, CustomerDLPStartDate__c, Unit__r.DLPZone__r.ContractorDLPStartDate__c,Unit__r.DLPZone__r.ContractorDLPEndDate__c,
                                   AMCStartDate__c, AMCEndDate__c, PMAStartDate__c, PMAEndDate__c from SalesOrder__c where id = :recordID limit 1];
       return tempRecord.isEmpty()?null:tempRecord[0];
    }
    
    @AuraEnabled(cacheable=true)
    public static List< VisitDetail__c > getVisitDetails(String recordID) {
       return [select id,Name,Completion_Reason__c,PlannedDate__c,VisitDate__c,PlannedVendor__c,Status__c,VisitAttended__c,CompletionDate__c from VisitDetail__c where SalesOrder__c = :recordID order by PlannedDate__c,CompletionDate__c];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getCaseDetails(String recordID) {
       return [select id,CaseNumber, Status, Priority,Subject,CreatedDate,LastModifiedDate,CaseCategory__c,SubCategory__c from Case where SalesOrder__c = :recordID and SubVertical__c = :Constants.DLP_SUB_VERTICAL order by CreatedDate];
    }
}