public without sharing class ContentDocumentLinkService {
@AuraEnabled
public static  String getContentDocumentLinkRecord(String docId){
      try {
            System.debug('inside cdlink+'+docId);
            ContentDocumentLink files = [SELECT ContentDocumentId  FROM ContentDocumentLink where  LinkedEntityId=:docId order by SystemModstamp desc limit 1 ];
            String fileId=files.ContentDocumentId;
            System.debug('fileId+'+fileId);
            return fileId;
            
      } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
      }
}  

@AuraEnabled
public static  List<ContentDocumentLink> getAllContentDocumentLinkRecord(String caseId){
      try {
            system.debug('##########################333caseId'+caseId);
            List<ContentDocumentLink> files = [SELECT ContentDocumentId  FROM ContentDocumentLink where  LinkedEntityId=:caseId ORDER BY SystemModstamp desc limit 1];
            system.debug('#########3contentdocService'+files);
            // String fileId=files.ContentDocumentId;
            return files;
            
      } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
      }
}  

      @AuraEnabled(cacheable=false)
      public static List<ContentDocumentLink> fetchFiles(String docId){
            system.debug('[docid>>>> fetchfiles'+ docId);
          return [SELECT LinkedEntityId, ContentDocument.CreatedDate, ContentDocument.Title, ContentDocument.ContentSize, ContentDocument.FileType 
                      FROM ContentDocumentLink  
                  WHERE LinkedEntityId  =:docId];
      }

      @AuraEnabled(cacheable=false)
      public static List<String> fetchTitle(String caseId){
          List<String> getTitle= new List<String>();
          List<ContentDocumentLink> contentDocRec= [SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted,ContentDocument.Title,ContentDocument.createdDate, ContentDocument.FileType FROM ContentDocumentLink where  LinkedEntityId=:caseId ];
          for(ContentDocumentLink c:contentDocRec){
                getTitle.add(c.ContentDocument.Title);
          }
          return getTitle;
      } 

      public static Map<Id,ContentDocumentLink> getLatestDocumentByParentId(Set<Id> linkedEntityIds){
            Map<Id,ContentDocumentLink> documentAttachedMap = new Map<Id,ContentDocumentLink>();

            for(ContentDocumentLink documentLink : [SELECT LinkedEntityId, ContentDocument.CreatedDate, ContentDocument.Title, ContentDocument.ContentSize, ContentDocument.FileType,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId  IN:linkedEntityIds Order By ContentDocument.CreatedDate DESC]){
                  if(!documentAttachedMap.containsKey(documentLink.LinkedEntityId)){
                        documentAttachedMap.put(documentLink.LinkedEntityId,documentLink);
                  }
            }

            return documentAttachedMap ;       
      }

      public static Map<Id, Map<String, String>> getIdUSLMap(List<Id> relatedIds) {
            Map<Id, Map<String, String>> idURLMap = new Map<Id, Map<String, String>>();
            List<ContentDistribution> cdList = [SELECT Id, DistributionPublicUrl, RelatedRecordId, ContentVersionId FROM ContentDistribution WHERE RelatedRecordId IN :relatedIds ORDER BY CreatedDate DESC];
            for (ContentDistribution cd: cdList) {
                  if (!idURLMap.containsKey(cd.RelatedRecordId)) {
                        Map<String, String> inMap = new Map<String, String>();
                        inMap.put('Id', cd.ContentVersionId);
                        inMap.put('URL', cd.DistributionPublicUrl);
                        idURLMap.put(cd.RelatedRecordId, inMap);
                  }
            }
            return idURLMap;
      }

      public static void createContentDocumentLinks(List<ContentVersion> files, Id recordId) {
            System.debug(recordId+'**Files**'+files);
            if (files != null && recordId != null) {
                List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
                Set<Id> contentVersionIds = new Set<Id>();
                for(ContentVersion contentVersionRec : files){
                    if (contentVersionRec.Id != null)
                        contentVersionIds.add(contentVersionRec.Id);
                }
    
                List<ContentVersion> uploadedFiles = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionIds];
                Map<Id,Id> contentVersionDocumentMap = new Map<Id,Id>();
                for(ContentVersion contentVersionRec : uploadedFiles){
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = contentVersionRec.ContentDocumentId;
                    cdl.LinkedEntityId = recordId;
                    cdl.Visibility = 'InternalUsers';
                    contentDocumentLinkList.add(cdl);
                }
                System.debug(contentDocumentLinkList.size()+'**Uploaded Files**'+contentDocumentLinkList);
                if(contentDocumentLinkList!=null && contentDocumentLinkList.size()>0)
                    insert contentDocumentLinkList ;
            }
      }
}