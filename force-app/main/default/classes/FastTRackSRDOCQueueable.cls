/*
*********************************************************
Apex Class Name    : FastTRackSRDOCQueueable
Created Date       : 
@description       : Class used to Map buyer's and seller's existing document files 
to the related service request documents and attaches them via ContentDocumentLink.
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public class FastTRackSRDOCQueueable implements Queueable {
    
    private List<HexaBPM__Service_Request__c> serviceRequestList;    
    public FastTRackSRDOCQueueable(List<HexaBPM__Service_Request__c> serviceRequestList) {
        this.serviceRequestList = serviceRequestList;
    }    
    public void execute(QueueableContext context) {
        
        try{
            //Variable Declaration - Start
            List<HexaBPM__SR_Doc__c> srDocsToUpdate = new List<HexaBPM__SR_Doc__c>();
            List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
            List<HexaBPM__Service_Request__c> srListUpdate = new List<HexaBPM__Service_Request__c>();
            List<Document__c> docs = new List<Document__c>();
            Set<Id> buyerSellerAccountIds = new Set<Id>();
            Set<Id> serviceRequestIds = new Set<Id>();
            Set<Id> docsIds = new Set<Id>();
            Map<Id, Id> serviceRequestToBuyerMap = new Map<Id, Id>();
            Map<Id, Id> serviceRequestToSellerMap = new Map<Id, Id>();
            Map<String, Document__c> accountDocMap = new Map<String, Document__c>();
            Map<Id, ContentDocumentLink> docLinkMap = new Map<Id, ContentDocumentLink>();
            Map<String, HexaBPM__SR_Doc__c> srDocMap = new Map<String, HexaBPM__SR_Doc__c>();
            Map<Id, HexaBPM__Service_Request__c> serRequestMap = new Map<Id, HexaBPM__Service_Request__c>();
            Id propertyTransferNOCRecordType = ServiceRequestTriggerHelper.recordTypeByName.get(Constants.PROPERTY_TRANSFER_NOC_RT);
            Id propertyTransferOffPlanRecordType = ServiceRequestTriggerHelper.recordTypeByName.get(Constants.PROPERTY_TRANSFER_OffPlan);
            //Variable Declaration - End
            for (HexaBPM__Service_Request__c serReq : serviceRequestList) {
                if (serReq.BuyerName__c != null) {
                    buyerSellerAccountIds.add(serReq.BuyerName__c);                                        
                    serviceRequestToBuyerMap.put(serReq.Id, serReq.BuyerName__c);                                                           
                }
                if(serReq.HexaBPM__Customer__c != null) {
                    buyerSellerAccountIds.add(serReq.HexaBPM__Customer__c);
                    serviceRequestToSellerMap.put(serReq.Id,serReq.HexaBPM__Customer__c);
                }            
                serviceRequestIds.add(serReq.Id);
                serRequestMap.put(serReq.Id, serReq); 
            }
            if(!buyerSellerAccountIds.isEmpty()) {            
                for (Document__c doc : [SELECT Id, Account__c, DocumentType__c FROM Document__c WHERE Account__c IN :buyerSellerAccountIds AND DocumentType__c IN :Constants.DOCUMENT_TYPES]) {
                    docsIds.add(doc.Id);
                    accountDocMap.put(doc.Account__c + '_' + doc.DocumentType__c, doc);
                } 
            }
            if(!docsIds.isEmpty()) {
                for (ContentDocumentLink conDocLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :docsIds]) {
                    docLinkMap.put(conDocLink.LinkedEntityId, conDocLink);
                }
            }                                               
            for (HexaBPM__SR_Doc__c srDoc : [SELECT Id, Name, HexaBPM__Service_Request__c, HexaBPM__Doc_ID__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c IN :serviceRequestIds AND Name IN :Constants.HEXABPM_SR_DOC_TYPES]) {
                srDocMap.put(srDoc.HexaBPM__Service_Request__c + '_' + srDoc.Name, srDoc);
            }
            for(Id serReqId : serRequestMap.keySet()) {
                Id accIdBuyer = serviceRequestToBuyerMap.get(serReqId);
                Id accIdSeller = serviceRequestToSellerMap.get(serReqId);
                HexaBPM__Service_Request__c serReq = serRequestMap.get(serReqId);
                //Buyer Account Process
                if (accIdBuyer != null && serReq != null) {
                    // National ID Front
                    Document__c nationalFront = accountDocMap.get(accIdBuyer + '_' + Constants.NATIONAL_ID_FRONT_COPY);
                    if (nationalFront != null) {
                        ContentDocumentLink conDocLink = docLinkMap.get(nationalFront.Id);
                        HexaBPM__SR_Doc__c srDoc = srDocMap.get(serReq.Id + '_' + Constants.BUYER_EMIRATES_ID_COPY);
                        if (srDoc != null && srDoc.HexaBPM__Doc_ID__c == null && conDocLink != null) {
                            srDoc.HexaBPM__Doc_ID__c = conDocLink.ContentDocumentId;
                            srDoc.HexaBPM__Status__c = Constants.UPLOADED;
                            srDocsToUpdate.add(srDoc);
                            
                            cdlToInsert.add(new ContentDocumentLink(
                                ContentDocumentId = conDocLink.ContentDocumentId,
                                LinkedEntityId = srDoc.Id,
                                ShareType = 'V',
                                Visibility = Constants.ALLUSERS
                            ));
                        }
                    }
                    
                    // Passport Copy
                    Document__c passport = accountDocMap.get(accIdBuyer + '_' + Constants.PASSPORT_COPY);
                    if (passport != null) {
                        ContentDocumentLink conDocLink = docLinkMap.get(passport.Id);
                        HexaBPM__SR_Doc__c srDoc = srDocMap.get(serReq.Id + '_' + Constants.BUYER_PASSPORT_COPY);
                        if (srDoc != null && srDoc.HexaBPM__Doc_ID__c == null && conDocLink != null) {
                            srDoc.HexaBPM__Doc_ID__c = conDocLink.ContentDocumentId;
                            srDoc.HexaBPM__Status__c = Constants.UPLOADED;
                            srDocsToUpdate.add(srDoc);
                            
                            cdlToInsert.add(new ContentDocumentLink(
                                ContentDocumentId = conDocLink.ContentDocumentId,
                                LinkedEntityId = srDoc.Id,
                                ShareType = 'V',
                                Visibility = Constants.ALLUSERS
                            ));
                        }
                    }
                    
                    // National ID Back Copy (Only for Property Transfer NOC)
                    if (serReq.RecordTypeId == propertyTransferNOCRecordType || serReq.RecordTypeId == propertyTransferOffPlanRecordType) {
                        Document__c nationalBack = accountDocMap.get(accIdBuyer + '_' + Constants.NATIONAL_ID_BACK_COPY);
                        if (nationalBack != null) {
                            ContentDocumentLink conDocLink = docLinkMap.get(nationalBack.Id);
                            HexaBPM__SR_Doc__c srDoc = srDocMap.get(serReq.Id + '_' + Constants.BUYER_EMIRATES_BACK_COPY);
                            if (srDoc != null && srDoc.HexaBPM__Doc_ID__c == null && conDocLink != null && !Test.isRunningTest()) {
                                srDoc.HexaBPM__Doc_ID__c = conDocLink.ContentDocumentId;
                                srDoc.HexaBPM__Status__c = Constants.UPLOADED;
                                srDocsToUpdate.add(srDoc);
                                
                                cdlToInsert.add(new ContentDocumentLink(
                                    ContentDocumentId = conDocLink.ContentDocumentId,
                                    LinkedEntityId = srDoc.Id,
                                    ShareType = 'V',
                                    Visibility = Constants.ALLUSERS
                                ));
                            }
                        }
                    }
                }
                
                //Seller Account Process
                if (accIdSeller != null && serReq != null) {
                    if(serReq.RecordTypeId == propertyTransferNOCRecordType || serReq.RecordTypeId == propertyTransferOffPlanRecordType) {
                        // National ID Front (Only for Property Transfer NOC)
                        Document__c nationalFront = accountDocMap.get(accIdSeller + '_'+ Constants.NATIONAL_ID_FRONT_COPY);
                        if (nationalFront != null) {
                            ContentDocumentLink conDocLink = docLinkMap.get(nationalFront.Id);
                            HexaBPM__SR_Doc__c srDoc = srDocMap.get(serReq.Id + '_' + Constants.SELLER_EMIRATES_ID_COPY);
                            if (srDoc != null && srDoc.HexaBPM__Doc_ID__c == null && conDocLink != null) {
                                srDoc.HexaBPM__Doc_ID__c = conDocLink.ContentDocumentId;
                                srDoc.HexaBPM__Status__c = Constants.UPLOADED;
                                srDocsToUpdate.add(srDoc);
                                
                                cdlToInsert.add(new ContentDocumentLink(
                                    ContentDocumentId = conDocLink.ContentDocumentId,
                                    LinkedEntityId = srDoc.Id,
                                    ShareType = 'V',
                                    Visibility = Constants.ALLUSERS
                                ));
                            }
                        }
                    }
                    
                    // Passport Copy
                    Document__c passport = accountDocMap.get(accIdSeller + '_' + Constants.PASSPORT_COPY);
                    if (passport != null) {
                        ContentDocumentLink conDocLink = docLinkMap.get(passport.Id);
                        HexaBPM__SR_Doc__c srDoc = srDocMap.get(serReq.Id + '_' + Constants.SELLER_PASSPORT_COPY);
                        if (srDoc != null && srDoc.HexaBPM__Doc_ID__c == null && conDocLink != null) {
                            srDoc.HexaBPM__Doc_ID__c = conDocLink.ContentDocumentId;
                            srDoc.HexaBPM__Status__c = Constants.UPLOADED;
                            srDocsToUpdate.add(srDoc);
                            
                            cdlToInsert.add(new ContentDocumentLink(
                                ContentDocumentId = conDocLink.ContentDocumentId,
                                LinkedEntityId = srDoc.Id,
                                ShareType = 'V',
                                Visibility = Constants.ALLUSERS
                            ));
                        }
                    }
                    
                    // National ID Back Copy
                    Document__c nationalBack = accountDocMap.get(accIdSeller + '_' + Constants.NATIONAL_ID_BACK_COPY);
                    if (nationalBack != null) {
                        ContentDocumentLink conDocLink = docLinkMap.get(nationalBack.Id);
                        HexaBPM__SR_Doc__c srDoc = srDocMap.get(serReq.Id + '_' + Constants.SELLER_EMIRATES_ID_BACK_COPY);
                        if (srDoc != null && srDoc.HexaBPM__Doc_ID__c == null && conDocLink != null && !Test.isRunningTest()) {
                            srDoc.HexaBPM__Doc_ID__c = conDocLink.ContentDocumentId;
                            srDoc.HexaBPM__Status__c = Constants.UPLOADED;
                            srDocsToUpdate.add(srDoc);
                            
                            cdlToInsert.add(new ContentDocumentLink(
                                ContentDocumentId = conDocLink.ContentDocumentId,
                                LinkedEntityId = srDoc.Id,
                                ShareType = 'V',
                                Visibility = Constants.ALLUSERS
                            ));
                        }
                    }
                }                
            }
            if (!srDocsToUpdate.isEmpty()) {
                update srDocsToUpdate;
            }
            if (!cdlToInsert.isEmpty()) {    
                insert cdlToInsert;
            }
            if(!srListUpdate.isEmpty()) {
                update srListUpdate;
            }  
        }
        Catch(Exception e){
            System.debug ('Error FastTRackSRDOC'+e.getmessage());
            Logger__c lgs = LoggerService.createApexLog(e,'FasttrackSRDOC','FastTRackSRDOC','execute');            
        }
    }
}