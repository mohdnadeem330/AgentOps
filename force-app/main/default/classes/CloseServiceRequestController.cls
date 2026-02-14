public with sharing class CloseServiceRequestController {
    
    @AuraEnabled
    public static String closeServiceRequest(Id serviceRequestId) {
        if (serviceRequestId == null) {
            throw new AuraHandledException('Invalid Service Request Id.');
        }

        // 1. Get Service Request with related fields
        HexaBPM__Service_Request__c sr = [
            SELECT Id, Name, SalesOrder__c,InstallmentLine__r.OutstandingAmount__c,
                   HexaBPM__Internal_SR_Status__c,
                   HexaBPM__External_SR_Status__c
            FROM HexaBPM__Service_Request__c
            WHERE Id = :serviceRequestId
            LIMIT 1
        ];
        

        if (sr.SalesOrder__c == null) {
            throw new AuraHandledException('No Sales Order linked to this Service Request.');
        }else if(sr.InstallmentLine__r != null && sr.InstallmentLine__r.OutstandingAmount__c > Decimal.valueOf(Label.DandTBufferAmount)){
            throw new AuraHandledException('You cannot close this Service Request because there are pending Installment Lines.');
        }else{
            HexaBPM__SR_Status__c srClosedStatus = [select id,name from HexaBPM__SR_Status__c where name = 'Closed' limit 1];

            sr.HexaBPM__External_SR_Status__c = srClosedStatus.id;
            sr.HexaBPM__Internal_SR_Status__c = srClosedStatus.id;
        }
        
        if(sr != null){
         update sr;

        } 
	
        return 'Service Request closed successfully.';

    }
}