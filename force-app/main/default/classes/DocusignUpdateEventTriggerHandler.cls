public class DocusignUpdateEventTriggerHandler {
	 public static void onAfterInsert(List<DocusignUpdateEvent__e> pgEventList){
        Set<Id> soIds = new Set<Id>();
        for(DocusignUpdateEvent__e pgEvent : pgEventList){
            soIds.add(pgEvent.SalesOrderId__c);
        }
        if(!soIds.isEmpty()){
            List<SalesOrder__c> soList = new List<SalesOrder__c>();
            for(SalesOrder__c so :[SELECT Id,SubStatus__c,CustomerSPASigned__c,CustomerSignedSPADate__c,SignatureType__c,Signaturetypechangereason__c FROM   SalesOrder__c WHERE Id=:soIds]){
               SalesOrder__c sorder = new SalesOrder__c();
                sorder.Id = so.Id;
                sorder.SubStatus__c='Digital SPA Signed';
                sorder.CustomerSPASigned__c=true;
                sorder.CustomerSignedSPADate__c = system.today();
                if(sorder.SignatureType__c != 'Digital Signature'){
                    sorder.SignatureType__c='Digital Signature';
                    sorder.Signaturetypechangereason__c=Label.DocuSignSIgnatureUpdateMessage;
                }
                soList.add(sorder);
            }
            if(!soList.isEmpty()){
                SalesOrderTriggerHandler.skipSalesOrderTrigger = true;
                Update soList;
                SalesOrderTriggerHandler.skipSalesOrderTrigger = false;
                
            }
        }
    }
}