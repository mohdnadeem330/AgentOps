public with sharing class BatchToDirectDebitCalloutHelper {
    
    public static void PrepareDataForCallout(List<Id> ddTransactionIdList){
        List<Id> linkedEntityIds                                 = new List<Id>();
        List<ContentDocumentLink> contentDocumentLinkList        = new List<ContentDocumentLink>();
        List<Contentversion> contentVersionList                  = new List<Contentversion>();
        List<String> contentDocumentIdList                       = new List<String>();
        Map<Id, List<ContentDocumentLink>> contentDocumentMap    = new Map<Id, List<ContentDocumentLink>>();
        Map<Id, Contentversion> contentVersionMap                = new Map<Id, Contentversion>();  
        Map<Id, Map<Id, Contentversion>> ddtIdcontentVersionMap  = new Map<Id, Map<Id, Contentversion>>();
        List<DdTransactionWrapper> ddTransactionWrapperList      = new List<DdTransactionWrapper>();
        DdTransactionMainWrapper ddsRequestWrapper               = new DdTransactionMainWrapper();
        List<DDTransaction__c> ddTransactionList = [SELECT 
                                                    Id,
                                                    Name,
                                                    DDBank__c,
                                                    Requesttype__c,
                                                    TransactionStatus__c,
                                                    DDBankingReferenceNumber__c,
                                                    DDResponseFileName__c,
                                                    SOReferenceNumber__c,
                                                    DirectDebitRequest__r.SalesOrder__r.Name
                                                    FROM DDTransaction__c
                                                    WHERE ID IN: ddTransactionIdList];
        
        if(!ddTransactionList.isEmpty()) {
            Map<Id,DDTransaction__c> ddMap = new Map<Id,DDTransaction__c>(ddTransactionList);
            contentDocumentLinkList = [SELECT
                                       ContentDocumentId,
                                       Id,
                                       IsDeleted,
                                       LinkedEntityId,
                                       ShareType,
                                       Visibility
                                       FROM ContentDocumentLink 
                                       WHERE LinkedEntityId IN: ddMap.keySet()
                                      ];
        }
        if(!contentDocumentLinkList.isEmpty()) {
            for(ContentDocumentLink contentDocumentLink: contentDocumentLinkList) {
                contentDocumentIdList.add(contentDocumentLink.ContentDocumentId);
                List<contentDocumentLink> conList = contentDocumentMap.get(contentDocumentLink.LinkedEntityId) != null? contentDocumentMap.get(contentDocumentLink.LinkedEntityId): new List<contentDocumentLink>();
                conList.add(contentDocumentLink);
                contentDocumentMap.put(contentDocumentLink.LinkedEntityId, conList);
            } 
        }
        
        if(!contentDocumentIdList.isEmpty()) { 
            contentVersionList = [SELECT
                                  Id,
                                  ContentDocumentId,
                                  versiondata,
                                  FileType,
                                  PathOnClient,
                                  Title
                                  FROM Contentversion
                                  WHERE ContentDocumentId IN: contentDocumentIdList
                                 ];
        }
        if(!contentVersionList.isEmpty()) {
            for(Contentversion contentVersion: contentVersionList) {
                contentVersionMap.put(contentVersion.ContentDocumentId, contentVersion);
            } 
        }
        system.debug('contentVersionMap'+contentVersionMap);
        for(DDTransaction__c ddTransaction: ddTransactionList) {
            DdTransactionWrapper ddTransactionWrapper = new DdTransactionWrapper();
            // List<FileWrapper> fileWrapperList = new List<FileWrapper>();
            // FileWrapper wrapper = new FileWrapper(); 
            if(contentDocumentMap.get(ddTransaction.Id) != null){
                for(ContentDocumentLink contentDocumentLink: contentDocumentMap.get(ddTransaction.Id)) {
                    if(ddTransaction.Id == contentDocumentLink.LinkedEntityId && contentVersionMap.get(contentDocumentLink.ContentDocumentId) != null) {
                        if(contentVersionMap.get(contentDocumentLink.ContentDocumentId).FileType == 'PDF'){
                            ddTransactionWrapper.base64_pdf = EncodingUtil.Base64Encode(contentVersionMap.get(contentDocumentLink.ContentDocumentId).versiondata);
                            ddTransactionWrapper.fileName_pdf = contentVersionMap.get(contentDocumentLink.ContentDocumentId).PathOnClient;
                            ddTransactionWrapper.fileExtention_pdf = 'PDF';
                        }else {
                            ddTransactionWrapper.base64_req = EncodingUtil.Base64Encode(contentVersionMap.get(contentDocumentLink.ContentDocumentId).versiondata);
                            ddTransactionWrapper.fileName_req = contentVersionMap.get(contentDocumentLink.ContentDocumentId).PathOnClient;
                            if(contentVersionMap.get(contentDocumentLink.ContentDocumentId).PathOnClient.split('\\.')[1] == 'DDS'){
                                ddTransactionWrapper.fileExtention_req = 'DDS';
                            }else {
                                ddTransactionWrapper.fileExtention_req = contentVersionMap.get(contentDocumentLink.ContentDocumentId).FileType;
                            }
                        }
                        
                        /*  if(contentVersionMap.get(contentDocumentLink.ContentDocumentId).PathOnClient.split('\\.')[1] == 'DDS'){
wrapper.fileExtention = 'DDS';
}else {
wrapper.fileExtention = contentVersionMap.get(contentDocumentLink.ContentDocumentId).FileType;
} */ 
                        // wrapper.ddTransactionId = ddTransaction.id;
                        //  fileWrapperList.add(wrapper); 
                    }
                }
            }
            
            // ddTransactionWrapper.files                       = wrapper;
            ddTransactionWrapper.ddTransactionId             = ddTransaction.id;
            ddTransactionWrapper.ddTransactionNumber         = ddTransaction.Name;
            ddTransactionWrapper.ddrequestNumber             = ddTransaction.Name;
            ddTransactionWrapper.ddBank                      = ddTransaction.DDBank__c;
            ddTransactionWrapper.ddRequestType               = ddTransaction.Requesttype__c;
            ddTransactionWrapper.ddTransactionStatus         = ddTransaction.TransactionStatus__c;
            ddTransactionWrapper.ddBankingReferenceNumber    = ddTransaction.DDBankingReferenceNumber__c;
            ddTransactionWrapper.ddResponseFileName          = ddTransaction.DDResponseFileName__c;
            ddTransactionWrapper.soReferenceNumber           = ddTransaction.DirectDebitRequest__r.SalesOrder__r.Name;
            ddTransactionWrapperList.add(ddTransactionWrapper);
        }
        ddsRequestWrapper.ddsRequest = ddTransactionWrapperList;
        system.debug('ddTransactionWrapperList::'+ddsRequestWrapper);
        String requestBody = JSON.serialize(ddsRequestWrapper);
        system.debug('requestBody::'+requestBody);
        if (System.IsBatch() == true) { 
            CalloutToMuleSoft.calloutService(requestBody, true, 'ddrRequestToBank', ddTransactionIdList); 
        } 
    }
    public static void updateDDTransaction( String responseBody, List<Id> recordIds,String requestBody ){
        List<DDTransaction__c> DDTransactionListToUpdate = new List<DDTransaction__c>();
        responseWrapper responsewrapper = (responseWrapper) System.JSON.deserialize(responseBody, responseWrapper.class);
        
        if(responsewrapper.statusCode == '200' || responsewrapper.statusCode == '201'){
            if(responsewrapper.results.ddsRes.size()>0){
                for(Integer i=0; i<responsewrapper.results.ddsRes.size(); i++){
                    DDTransaction__c DDTransaction = new DDTransaction__c(); 
                    system.debug('DDTransaction.Id::'+DDTransaction.Id);
                    if(responsewrapper.results.ddsRes[i].status == 'Success'){
                        DDTransaction.Id = responsewrapper.results.ddsRes[i].ddTransactionId;
                        DDTransaction.TransactionStatus__c = 'Processed by Salesforce';
                        DDTransaction.SyncStatus__c = 'Synced';
                        DDTransaction.SyncTime__c = System.now();
                        DDTransactionListToUpdate.add(DDTransaction);
                    }else if(responsewrapper.results.ddsRes[i].status == 'Failure'){
                        DDTransaction.Id = responsewrapper.results.ddsRes[i].ddTransactionId;
                        DDTransaction.SyncStatus__c = 'Failed';
                        DDTransaction.SyncTime__c = System.now();
                        DDTransaction.ErrorReason__c = responsewrapper.results.ddsRes[i].errorMsg;
                        DDTransactionListToUpdate.add(DDTransaction);
                        //LoggerService.save(LoggerService.addApexLog(responsewrapper.results.ddsRes[i].errorMsg,'BatchToDirectDebitCalloutHelper','updateDDTransaction',''));
                    }
                }
            }
            
        } else {
            for(Id ddtransactionId: recordIds){
                DDTransaction__c DDTransaction = new DDTransaction__c();
                DDTransaction.Id = ddtransactionId;
                DDTransaction.SyncStatus__c = 'Failed';
                DDTransaction.SyncTime__c = System.now();
                DDTransaction.ErrorReason__c = 'Mule failure :'+responsewrapper.statusCode;
                DDTransactionListToUpdate.add(DDTransaction); 
                LoggerService.save(LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', 'ddrRequestToBank', (requestBody.length() < 131072 ? requestBody : ''), responseBody, null));
            }
            
        }
        if(!DDTransactionListToUpdate.isEmpty()){
            update DDTransactionListToUpdate;
        }
        
        /*   if(responseBody != null && responseBody != '' && !ddTransactionIdList.isEmpty()){

for(Id ddt_id: ddTransactionIdList){
if(response.getStatusCode() == 201 || response.getStatusCode() == 200){
DDTransaction__c DDTransaction = new DDTransaction__c(); 
DDTransaction.Id = ddt_id;
DDTransaction.TransactionStatus__c = 'Processed by Salesforce';
DDTransaction.SyncStatus__c = 'Synced';
DDTransaction.SyncTime__c = System.now();
DDTransactionListToUpdate.add(DDTransaction);
}else {
DDTransaction__c DDTransaction = new DDTransaction__c(); 
DDTransaction.Id = ddt_id;
DDTransaction.SyncStatus__c = 'Failed';
DDTransaction.SyncTime__c = System.now();
}
}

} */
    }
    public class DdTransactionMainWrapper {
        public List<DdTransactionWrapper> ddsRequest;
    }
    public class DdTransactionWrapper {
        public String ddTransactionId;
        public String ddTransactionNumber;
        public String ddResponseFileName;
        public String ddBankingReferenceNumber;
        public String soReferenceNumber;
        public String ddrequestNumber;
        public String ddBank;
        public String ddRequestType;
        public String ddTransactionStatus;
        public String base64_req;
        public String fileName_req;
        public String fileExtention_req;
        public String base64_pdf;
        public String fileName_pdf;
        public String fileExtention_pdf;
    }
    
    public class responseWrapper{
        public String applicationName;	
        public boolean success;
        public String statusCode;	
        public String correlationId;
        public cls_results results;
    }
    Public class cls_results {
        public List<cls_ddsRes> ddsRes;
    }
    public class cls_ddsRes {
        public String sfRequestId;	
        public String ddTransactionId;
        public String status;
        public String errorMsg;
    }
    
}