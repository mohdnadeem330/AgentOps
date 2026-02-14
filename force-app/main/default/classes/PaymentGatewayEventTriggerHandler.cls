public class PaymentGatewayEventTriggerHandler {
    public static void onAfterInsert(list<Payment_Gateway_Event__e> trgnew){
        List<Id> erpRequestIdList = new List<Id>();
        List<Id> docGenPayReqIdList = new List<Id>();
        Set<Id> caseIdSet = new Set<Id>();
        set<Id> IdSet = new Set<Id>();
        //Set<Id> caseIdSet = new Set<Id>();
        List<Id> paymentRequestIdList = new List<Id>();      
        for(Payment_Gateway_Event__e pg : trgnew){
            if(pg.Identifier__c == 'DM-Payment'){
                IdSet.add(pg.Record_Id__c);
                erpRequestIdList.add(pg.Record_Id__c);
            }
            if(pg.Identifier__c == 'DM-Payment-DOCGEN'){
                docGenPayReqIdList.add(pg.Record_Id__c);
            }
            if(pg.Identifier__c == 'DM-UpdateCase'){
                List<String> caseIds = pg.Record_Id__c.split(',');
                
                for (String s : caseIds) {
                    caseIdSet.add((Id)s); // Cast to Id type
                }
                
                List<Case> caseRecords = [
                SELECT Id, Service_Price__c, Received_Amount__c, Status, Sub_Status__c  
                FROM Case  
                WHERE Id IN :caseIdSet];
                PaymentRequestTriggerHandler.updateCaseReceivedAmount(caseRecords);
                //IdSet.add(pg.Record_Id__c);
                //CaseIdList.add(pg.Record_Id__c);
            }
        }

        if(erpRequestIdList.size() > 0){
            Dm_ERPIntegrationCtrl.pushToERPAsync(erpRequestIdList[0]);
        }
        if(docGenPayReqIdList.size() > 0){
            System.enqueueJob(new GenerateInvoicePDFQueueable(docGenPayReqIdList));
        }
    }
}