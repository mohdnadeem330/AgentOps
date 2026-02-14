public without sharing class ECSS_caseDocumentCustomerUpload {
    
    @AuraEnabled (cacheable=false)
    public static List<Document__c> getCustomerDocuments(string recordId){
        String ECSSCaseDocumentRT = Label.ECSS_Case_Document;
       	Id CaseDocumentRecordType = Schema.SObjectType.Document__c.getRecordTypeInfosByName().get(ECSSCaseDocumentRT).getRecordTypeId();
       // system.debug('rec:'+CaseDocumentRecordType);
        return [SELECT Id, DocumentType__c, status__c FROM Document__c WHERE Status__c='Pending' AND RecordTypeId=:CaseDocumentRecordType AND Case__c=:recordId];
    }
    
    @AuraEnabled
    public static List<Document__c> uploadDocuments(String recordId, List<Map<String, String>> documents, List<String> requiredDocIds) {
        try {
            //List<ContentVersion> contentVersions = new List<ContentVersion>();
            List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
            Map<Id,ContentVersion> docContentVersionMap = new Map<Id,ContentVersion>();
           // Set<Id> docIdSet = new Set<Id>();
            List<Document__c> docToUpdateList = new List<Document__c>();
            for (Map<String, String> docItem : documents) {
                String docId = docItem.get('docId');
                String fileName = docItem.get('fileName');
                String base64Data = docItem.get('base64Data');
                
                ContentVersion cv = new ContentVersion();
                cv.Title = fileName;
                cv.PathOnClient = fileName;
                cv.VersionData = EncodingUtil.base64Decode(base64Data);
                docContentVersionMap.put(docId,cv);
                //docIdSet.add(docId);
                
                Document__c doc = new Document__c();
                doc.id = docId;
                doc.Status__c = 'Uploaded';
                docToUpdateList.add(doc);
              
            }
            insert docContentVersionMap.values();
            
            //get all content version ids
            Set<Id> contentVersionIds = new Set<Id>();
            for (string docId : docContentVersionMap.keyset()) {
                 contentVersionIds.add(docContentVersionMap.get(docId).Id);
            }
          	Map<Id,ContentVersion> contentVersionMap = new Map<Id,ContentVersion>([SELECT ContentDocumentId FROM ContentVersion where Id in:contentVersionIds ]);
            system.debug(contentVersionMap);
            
            for (Map<String, String> doc : documents) {
                string docId = doc.get('docId');
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = recordId; 
                cdl.ContentDocumentId = contentVersionMap.get(docContentVersionMap.get(docId).Id).contentDocumentId;
                cdl.ShareType = 'V';  
                contentLinks.add(cdl);
                
            }
            
			insert contentLinks;
            update docToUpdateList;
            
            
            boolean alldocumentsUploaded = true;
          
            for (Id docId : requiredDocIds) 
            {	
               // system.debug('DOCUMENT FOUND'+docIdSet.contains(docId));
                if(!docContentVersionMap.keySet().contains(docId))
                {
                    alldocumentsUploaded = false;
                }
            }
            
            if(alldocumentsUploaded)
            {
                Case c = new Case();
                c.Id = recordId;
                c.ECSS_Customer_Documents_Uploaded__c = true;
                update c;
            }
            
            return docToUpdateList;
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading documents: ' + e.getMessage());
            
        }
    }
    
    
}