/**
* @File Name : RETL_SRDocumentHandler.cls
* @Description : Use the test class RETL_ServiceRequestWizardControllerTest for this class
* @Author :
* @Last Modified By :
* @Last Modified On : Oct 14, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Oct 14, 2025 | Abhijith Damodaran (Protiviti) | Initial Version
**/
public without sharing class RETL_SRDocumentHandler {
    @AuraEnabled
    public static String getSessionId() {
        return UserInfo.getSessionId();
    }
    
    
    @AuraEnabled()
    public static Map<String, Object> handleDocuments( String filesData, String parentId, String caseCommentId){
        System.debug('Current Heap Size: ' + Limits.getHeapSize());
        System.debug('filesData: ' + filesData);
        List<DocumentWrapper> documents = (List<DocumentWrapper>) JSON.deserialize(filesData, List<DocumentWrapper>.class);
        system.debug('DocumentRecs'+Documents);
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        List<Document__c> documentRecs = new List<Document__c>();
        Map<String, Id> tempDocToFileLink = new Map<String, Id>();
        List<Id> contentVersionIds = new List<Id>();
        List<Network> tenantPortalNetwork = [
            SELECT Id, Name, UrlPathPrefix
            FROM Network
            WHERE Name = 'Tenant Portal' // or use criteria to find correct site
            LIMIT 1
        ];
        
        Id recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByName().get('SR_Retail').getRecordTypeId();
        for(documentWrapper d : documents){
            // Map<String,Object> d = (Map<String,Object>)o;
            // Create parent Document__c (your custom object)
            Document__c doc = new Document__c(
                recordTypeId = recordTypeId,
                DocumentType__c = d.documentType,
                Case__c = parentId,
                Case_Recordtype__c = 'SR_Retail'
            );
            documentRecs.add(doc);
            if(!d.contentVersions.isEmpty()){
                for(ContentVersionWrapper cv : d.contentVersions){
                    contentVersionIds.add(cv.contentVersionId);  
                }
                
            }
            system.debug('contentVersionIds'+contentVersionIds);
           
        }
        insert documentRecs;
        system.debug('documentRecs'+documentRecs);
        //insert contentVersions;
        
        // fetch documents__c records
        List<Document__c> docList = [Select Id , DocumentType__c From Document__c Where Id IN:documentRecs AND Case__c =: parentId ];
        Map<String,Id> docMap = new Map<String,Id>();
        if( !docList.isEmpty()){
            for(Document__c d : docList){
                docMap.put(d.DocumentType__c,d.Id);
            }
        }
        //  Fetch the ContentDocumentId for each ContentVersion
        List<ContentVersion> insertedCV = [
            SELECT Id, ContentDocumentId, Title, RETL_Document_Type__c
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
        ];
        Map<Id,List<Id>> docIdContentDocumentIDMap = new   Map<Id,List<Id>>();
        
        
        List<External_Files__c> extFiles = new  List<External_Files__c>();
        if( !insertedCV.isEmpty()){
            //Calling method for external file record creation
            extFiles = externalFileLinkCreation(insertedCV,docList,caseCommentId, false);
            for(String docType : docMap.keySet()){
                for(ContentVersion cv : insertedCV){
                    
                    if(cv.Title != null){
                        if(cv.RETL_Document_Type__c == docType){
                            if(!docIdContentDocumentIDMap.ContainsKey(docMap.get(docType))){
                                docIdContentDocumentIDMap.put(docMap.get(docType),new List<Id>{cv.ContentDocumentId});
                            }else{
                                docIdContentDocumentIDMap.get(docMap.get(docType)).add(cv.ContentDocumentId);
                            }
                        }
                    }
                }
            }
        }
        // Link each ContentDocument to the Case
        List<ContentDocumentLink> cdl = new List<ContentDocumentLink>();
        
        if(!docIdContentDocumentIDMap.isEmpty()){
            for( Id docId : docIdContentDocumentIDMap.keySet()){
                for( Id contentDocId : docIdContentDocumentIDMap.get(docId)){
                    cdl.add(new ContentDocumentLink(
                        LinkedEntityId = docId,
                        ContentDocumentId = contentDocId,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    ));
                }
            }
        }
        insert cdl;
        Map<String, Object> documentMap = new Map<String,Object>();
        List<Map<String, Object>> documentList = new List<Map<String, Object>>();
        for (External_Files__c file : extFiles) {
            Map<String, Object> doc = new Map<String, Object>();
            doc.put('fileLink', file.External_URL__c);
            doc.put('fileName',file.File_Name__c.trim());
            documentList.add(doc);
        }
        documentMap.put('DocLinks', documentList);
        return documentMap;
    }
    
    
    
    
    @InvocableMethod(label = 'SR Additional Document Creation' description = 'SR Additional Document Creation')
    public static List<External_Files__c> callExternalFileLinkCreationFromInvocalble(List<InputVariables> inputVariableList){
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<Document__c> documents = new List<Document__c>(); 
        String caseCommentId;
        Boolean isCongaDocument;
        if(!inputVariableList.isEmpty()){
            for(InputVariables iv:inputVariableList){
                if(!iv.contentVersionList.isEmpty()){
                    contentVersionList = iv.contentVersionList;
                }
                if(!iv.documents.isEmpty()){
                    documents = iv.documents;
                }
                if(iv.caseCommentId != null){
                    caseCommentId = iv.caseCommentId;
                }
                if(iv.isCongaDocument != null){
                    isCongaDocument = iv.isCongaDocument;
                }
            }
            
        }
        List<External_Files__c> extFiles = externalFileLinkCreation(contentVersionList, documents, caseCommentId, isCongaDocument);
        return extFiles;
    }
    
    public static List<External_Files__c> externalFileLinkCreation(List<ContentVersion> contentVersionList, List<Document__c> documents, String caseCommentId, Boolean isCongaDocument){
        List<ContentDistribution> cdistList = new List<ContentDistribution>();
        List<External_Files__c> extFiles = new List<External_Files__c>();
        for(Document__c doc : documents){
            for(ContentVersion cv : contentVersionList){
                if(doc.DocumentType__c == cv.RETL_Document_Type__c && isCongaDocument == false){
                    cdistList.add(new ContentDistribution(
                        Name = cv.Title,
                        ContentVersionId = cv.Id,
                        PreferencesAllowViewInBrowser = true,
                        RelatedRecordId = doc.Id,
                        PreferencesAllowPDFDownload =true,
                        PreferencesAllowOriginalDownload = true
                    ));
                }
                else if(isCongaDocument == true){
                    cdistList.add(new ContentDistribution(
                        Name = cv.Title,
                        ContentVersionId = cv.Id,
                        PreferencesAllowViewInBrowser = true,
                        RelatedRecordId = doc.Id,
                        PreferencesAllowPDFDownload =true,
                        PreferencesAllowOriginalDownload = true
                    ));
                }
            }
        }
        if(!cdistList.isEmpty()){
            insert cdistList;
            // query the ContentDistribution object to get the URL
            List<ContentDistribution> createdDistributionList = [SELECT Name, DistributionPublicUrl,ContentDownloadUrl, ContentVersion.ContentDocumentId, RelatedRecordId FROM ContentDistribution WHERE Id IN :cdistList];
            System.debug('Public Link: ' + createdDistributionList);
            for(ContentDistribution cd : createdDistributionList){
                //Create External_Files__c child records
                extFiles.add(new External_Files__c(
                    Document__c = cd.RelatedRecordId,
                    File_Name__c = cd.Name,
                    External_URL__c = cd.ContentDownloadUrl,
                    RETL_Case_Comment_SF_ID__c = caseCommentId != null ? caseCommentId : ''
                ));
            }
            if(!extFiles.isEmpty()){
                insert extFiles;
            }
        }
        return extFiles;
    }
    
    @AuraEnabled
    public static void deleteUploadedFile(Id contentVersionId) {
        try {
            // Get the related ContentDocumentId so both can be deleted safely
            ContentVersion cv = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :contentVersionId
                LIMIT 1
            ];
            
            // Delete ContentDocument (which cascades to its versions)
            delete [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        } catch (Exception e) {
            System.debug('Error deleting file: ' + e.getMessage());
            throw new AuraHandledException('Failed to delete uploaded file: ' + e.getMessage());
        }
    }
    
    public class DocumentWrapper{
        @AuraEnabled public List<ContentVersionWrapper>  contentVersions;
        @AuraEnabled public String documentType;
    }
    
    public class ContentVersionWrapper{
        @AuraEnabled public Id contentVersionId;
        //@AuraEnabled public String fileName;
        //@AuraEnabled public String base64;
    }
    
    public class InputVariables{
        //List<ContentVersion> contentVersionList, List<Document__c> documents, String caseCommentId, Boolean isCongaDocument
        @InvocableVariable
        public List<ContentVersion> contentVersionList;
        @InvocableVariable
        public List<Document__c> documents;
        @InvocableVariable
        public String caseCommentId;
        @InvocableVariable
        public Boolean isCongaDocument;
    }
}