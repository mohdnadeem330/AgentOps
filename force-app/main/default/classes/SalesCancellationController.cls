public class SalesCancellationController {
    
    @AuraEnabled
    public static SalesOrder__c getSalesOrderDetails(Id recordId){
        
        List<SalesOrder__c> soList = new List<SalesOrder__c>();
        List<SalesOrderCancellation__c> inprogressCancellation = new List<SalesOrderCancellation__c>();
        List<Document__c> cancellationRequestDocumentsList = new List<Document__c>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        List<DirectDebitRequest__c> directDebitRequests = new List<DirectDebitRequest__c>();
        
        inprogressCancellation = [SELECT Id FROM SalesOrderCancellation__c WHERE SalesOrder__c =:recordId ];
        if(inprogressCancellation.size() > 0) {
            throw new AuraHandledException('Sales order cancellation is in progess.');
        }
        soList = [SELECT 
                  Id,
                  Unit__c,
                  Offer__c,
                  Opportunity__r.BrokerAgencyAccount__c,
                  PaymentPlan__c,
                  Status__c,
                  SalesManager__c,
                  Has_Active_DirectDebit__c,
                  Directdebitauthorityreferencenumber__c
                  FROM SalesOrder__c
                  WHERE Id=:recordId];
        
        
        if(soList[0].Directdebitauthorityreferencenumber__c != null && soList[0].Directdebitauthorityreferencenumber__c != ''){
            directDebitRequests = [SELECT
                                   Id,
                                   Status__c
                                   FROM
                                   DirectDebitRequest__c
                                   WHERE SalesOrder__c =: soList[0].Id
                                   AND Status__c in ('Cancellation in progress','Cancellation Sent to Bank')];
            
            if(!directDebitRequests.isEmpty()){
                cancellationRequestDocumentsList = [SELECT Id,
                                                    DocumentType__c
                                                    FROM Document__c
                                                    WHERE DirectDebitRequest__c IN: directDebitRequests 
                                                    AND DocumentType__c = 'Signed Direct Debit Cancellation form'];
            }
            
            if(!cancellationRequestDocumentsList.isEmpty()){
                contentDocumentLinks =  [SELECT 
                                         ContentDocumentId,
                                         Id,
                                         IsDeleted,
                                         LinkedEntityId,
                                         ShareType,
                                         SystemModstamp,
                                         Visibility 
                                         FROM ContentDocumentLink 
                                         WHERE LinkedEntityId =:cancellationRequestDocumentsList[0].Id];
            }
            if(contentDocumentLinks.size() == 0 && directDebitRequests.size()>0){
                throw new AuraHandledException(Label.SalesCancellationWithForm); 
            }else if (directDebitRequests.size() == 0){
                throw new AuraHandledException(Label.SalesCancellationWithDDR); 
            }
        }
        return soList[0];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getCancellationReasons() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult =
            SalesOrderCancellation__c.ReasonforCancellation__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            values.add(entry.getValue());
        }
        return values;
    }

}