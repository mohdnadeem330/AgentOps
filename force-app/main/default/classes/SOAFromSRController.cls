public with sharing class SOAFromSRController {
    
    @AuraEnabled
    public static HexaBPM__Service_Request__c getServiceRequest(String srId){

        HexaBPM__Service_Request__c serviceRequest = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Where Id =: srId ];
        return serviceRequest;
    }
}