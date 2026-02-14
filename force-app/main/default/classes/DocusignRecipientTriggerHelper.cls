public class DocusignRecipientTriggerHelper  extends TriggerHandler{
    public static final Double aldarRoutingCode = double.valueOf(Label.DSAldarRoutingCode);
    public static Boolean GET_EXCEPTION = false;
    
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        updateSalesOrder((List<dfsle__RecipientStatus__c> )newList, null);
        ResaleUnitService.updateOpportunity((List<dfsle__RecipientStatus__c> )newList, null);
    }
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        updateSalesOrder((List<dfsle__RecipientStatus__c> )newList, oldMap);
        ResaleUnitService.updateOpportunity((List<dfsle__RecipientStatus__c> )newList, oldMap);
    }
    public static void updateSalesOrder(List<dfsle__RecipientStatus__c> newList, Map<Id,SObject> oldMap){
        system.debug('update Sales Order');
        List<dfsle__EnvelopeStatus__c> envelopeStatusList = new List<dfsle__EnvelopeStatus__c>();
        Set<Id> envelopeIds = new Set<Id>();
        Set<Id> sourceIds = new Set<Id>();
        for(dfsle__RecipientStatus__c recipientstatus : newList ){
            //  dfsle__RecipientStatus__c oldRec = Trigger.isAfter ? (dfsle__RecipientStatus__c) oldMap.get(recipientstatus.Id) : null;
            // (  recipientstatus.dfsle__Status__c != '' ) &&(recipientstatus.dfsle__Status__c != oldRec.dfsle__Status__c && Trigger.isUpdate) ||
            
            if(oldMap != null){
                dfsle__RecipientStatus__c oldRec = (dfsle__RecipientStatus__c) oldMap.get(recipientstatus.Id);
                if(recipientstatus.dfsle__Status__c != oldRec.dfsle__Status__c 
                    && recipientstatus.dfsle__Status__c == 'Completed'
                    && recipientstatus.dfsle__RoutingOrder__c != null
                    && recipientstatus.dfsle__RoutingOrder__c < 21){
                        envelopeIds.add(recipientstatus.dfsle__EnvelopeStatus__c);
                        sourceIds.add(recipientstatus.dfsle__SourceId__c);
                        system.debug('++++ dfsle__EnvelopeStatus__c '+envelopeIds);
                    }
            }else{
                if( recipientstatus.dfsle__Status__c == 'Completed' 
                    && recipientstatus.dfsle__RoutingOrder__c != null 
                    && recipientstatus.dfsle__RoutingOrder__c < 21 ){
                        envelopeIds.add(recipientstatus.dfsle__EnvelopeStatus__c);
                        sourceIds.add(recipientstatus.dfsle__SourceId__c);
                        system.debug('++++ dfsle__EnvelopeStatus__c '+envelopeIds);
                    } 
            }
        }
        
        if(envelopeIds.size() > 0){
            Map<Id,Document__c> documentsToProcess = new Map<Id,Document__c>();
            Map<Id,Document__c> docMap = WithoutSharingClass.getDocumentforReciepientStatus(sourceIds);
            Map<Id,List<dfsle__RecipientStatus__c>> recipientsByEnvelope = new Map<Id,List<dfsle__RecipientStatus__c>>();
            for (dfsle__RecipientStatus__c recipient : WithoutSharingClass.getReciepientStatusList(envelopeIds)
            ){
                if(docMap.containsKey(recipient.dfsle__SourceId__c) 
                && !docMap.get(recipient.dfsle__SourceId__c).SalesOrder__r.CustomerSPASigned__c){
                    if(recipientsByEnvelope.containsKey(recipient.dfsle__EnvelopeStatus__c)){
                        recipientsByEnvelope.get(recipient.dfsle__EnvelopeStatus__c).add(recipient);
                    }else{
                        recipientsByEnvelope.put(recipient.dfsle__EnvelopeStatus__c, new List<dfsle__RecipientStatus__c>{recipient});
                    }   
                }
            }
            List<dfsle__RecipientStatus__c> recipientsToProcess = new List<dfsle__RecipientStatus__c>();
            Set<Id> documentIdsToProcess = new Set<Id>();
            for(dfsle__RecipientStatus__c recipientstatus : newList ){
                if(recipientsByEnvelope.containsKey(recipientstatus.dfsle__EnvelopeStatus__c)){
                    List<dfsle__RecipientStatus__c> recipientList = new List<dfsle__RecipientStatus__c>();
                    recipientList = recipientsByEnvelope.get(recipientstatus.dfsle__EnvelopeStatus__c);
                    Integer recipientListSize = recipientsByEnvelope.get(recipientstatus.dfsle__EnvelopeStatus__c).size();
                    for(Integer i = 0;i<recipientListSize; i++){
                        system.debug('+++ recipientListSize[i] '+recipientList[i]);
                        if(recipientList[i].Id == recipientstatus.Id && recipientListSize > i+1 ){
                            system.debug('+++recipientListSize[i+1] '+recipientList[i+1]);
                            system.debug('recipientList[i+1].dfsle__RoutingOrder__c '+recipientList[i+1].dfsle__RoutingOrder__c);
                            //if(recipientList[i+1].dfsle__RoutingOrder__c == 21 && recipientList[i+1].dfsle__Status__c == 'Sent'){
                            if(recipientList[i+1].dfsle__RoutingOrder__c == 21 && 
                               ((recipientList[i+1].CommunicationPreference__c == null && recipientList[i+1].dfsle__Status__c == 'Sent')  ) ){
                                    recipientsToProcess.add(recipientstatus);
                                    documentIdsToProcess.add(recipientstatus.dfsle__SourceId__c);
                                if(docMap.containsKey(recipientstatus.dfsle__SourceId__c)){
                                    documentsToProcess.put(recipientstatus.dfsle__SourceId__c, docMap.get(recipientstatus.dfsle__SourceId__c));
                                }
                                break;
                            }
                        }
                    }
                }
            }
            if(!documentsToProcess.isEmpty()){
                List<SalesOrder__c> soList = new List<SalesOrder__c>();
                List<DocusignUpdateEvent__e> pgEventList = new List<DocusignUpdateEvent__e>();
                for(Document__c doc : documentsToProcess.values()){
                    if(Auth.CommunitiesUtil.isGuestUser()){
                        //Publish Platform Event
                        DocusignUpdateEvent__e pgEvent = new DocusignUpdateEvent__e(SalesOrderId__c = doc.SalesOrder__c);
                        pgEventList.add(pgEvent);
                    }else{
                    SalesOrder__c so = new SalesOrder__c(Id = doc.SalesOrder__c,
                                                         SubStatus__c='Digital SPA Signed',
                                                         CustomerSPASigned__c=true,
                                                         CustomerSignedSPADate__c = system.today());
                    if(doc.SalesOrder__r.SignatureType__c != 'Digital Signature'){
                        so.SignatureType__c='Digital Signature';
                        so.Signaturetypechangereason__c=Label.DocuSignSIgnatureUpdateMessage;
                    }
                    soList.add(so);
                    }
                }
                if(!pgEventList.isEmpty()){
                    EventBus.publish(pgEventList);
                }
                if(!soList.isEmpty()){
                    SalesOrderTriggerHandler.skipSalesOrderTrigger = true;
                    Update soList;
                    SalesOrderTriggerHandler.skipSalesOrderTrigger = false;
                }
            }
            /* Commented as already added SOQL on top
            if(documentIdsToProcess.size() > 0){
                List<SalesOrder__c> soList = new List<SalesOrder__c>();
                for(Document__c doc : [SELECT Id,SalesOrder__c, SalesOrder__r.SignatureType__c FROM Document__c WHERE Id IN:documentIdsToProcess AND SalesOrder__c != ''  ]){
                    SalesOrder__c so = new SalesOrder__c(Id = doc.SalesOrder__c,
                                                            SubStatus__c='Digital SPA Signed',
                                                            CustomerSPASigned__c=true,
                                                            CustomerSignedSPADate__c = system.today());
                    if(doc.SalesOrder__r.SignatureType__c != 'Digital Signature'){
                        so.SignatureType__c='Digital Signature';
                        so.Signaturetypechangereason__c=Label.DocuSignSIgnatureUpdateMessage;
                    }
                    soList.add(so);
                }
                if(!soList.isEmpty()){
                    Update soList;
                }
            }*/
        }
        /* }catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'DocusignRecipientTriggerHelper','updateSalesOrder',''));   
        } */
    }
}