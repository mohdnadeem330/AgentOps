public without sharing class ContentVersionService {
  
   public static List<ContentVersion> getFileIds(List<Id> fileIDs){
       try {
        List<ContentVersion> docs = [SELECT Id, ContentDocumentId, FileExtension, Title, ContentDocument.FileType, ContentDocument.LatestPublishedVersionId,VersionData 
        FROM ContentVersion WHERE ContentDocumentId IN : fileIDs order by CreatedDate desc];  
        return docs;
       } catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
       }
   }

   @AuraEnabled
    public static list<ContentVersion> returnFiles(list<String> lstFileIds){
        return [SELECT Id, Title FROM ContentVersion WHERE Id IN :lstFileIds];
    }

    public static ContentVersion createContentVersion(String title, Blob fileContent) {
        ContentVersion contentVersionRec = new ContentVersion();
        contentVersionRec.PathOnClient = title;
        contentVersionRec.Title = title;
        contentVersionRec.VersionData = fileContent;
        contentVersionRec.ContentLocation = 'S';
        return contentVersionRec ;
    }

}