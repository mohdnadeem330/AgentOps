public without sharing class ServiceRequestDocumentService {

    public static void getCaseUploadedFiles(Id caseId, Id srId, String srDocName){

        List<HexaBPM__SR_Doc__c> supportingDocuments = [SELECT Id, Name FROM HexaBPM__SR_Doc__c WHERE Name =: srDocName AND HexaBPM__Service_Request__c =: srId];
        
        if(!supportingDocuments.isEmpty()){
            List<ContentDocumentLink> filesList = ContentDocumentLinkService.getAllContentDocumentLinkRecord(caseId);

            List<ContentDocumentLink> allFiles = new List<ContentDocumentLink>();
            allFiles.addAll(filesList);

            Map<ID, EmailMessage> emailsIdsRelatedToCase = new Map<ID, EmailMessage>([SELECT Id, RelatedToId FROM EmailMessage WHERE RelatedToId =: caseId]);
            if(!emailsIdsRelatedToCase.isEmpty()){
                List<ContentDocumentLink> filesFromEmailsRelatedToCase = [SELECT ContentDocument.title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : EmailsIdsRelatedToCase.keySet()];
                allFiles.addAll(filesFromEmailsRelatedToCase);
            }

            List<ContentDocumentLink> filesToBeSharedWithSR = new List<ContentDocumentLink>();

            if(!allFiles.isEmpty()){
                for (ContentDocumentLink file : allFiles) {
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.ContentDocumentId = file.ContentDocumentId;
                    cd.LinkedEntityId = supportingDocuments[0].Id;
                    cd.ShareType = 'V';
                    filesToBeSharedWithSR.add(cd);
                }
                insert filesToBeSharedWithSR;
            }
        }
    }
    
    public static void getExistingUploadedFiles(Id recordId, Id srId, String srDocName, String relatedDocumentType){

        String sObjName = recordId.getSObjectType().getDescribe().getName();

        List<Document__c> documentsList = new List<Document__c>();

        if(sObjName == 'SalesOrder__c'){
            documentsList = [Select Id From Document__c Where SalesOrder__c =: recordId AND DocumentType__c =: relatedDocumentType];
        }

        List<HexaBPM__SR_Doc__c> supportingDocuments = [SELECT Id, Name FROM HexaBPM__SR_Doc__c WHERE Name =: srDocName AND HexaBPM__Service_Request__c =: srId];
        
        if(!supportingDocuments.isEmpty()){
            List<ContentDocumentLink> filesList = [SELECT ContentDocumentId  FROM ContentDocumentLink where  LinkedEntityId=: documentsList[0].Id];

            List<ContentDocumentLink> filesToBeSharedWithSR = new List<ContentDocumentLink>();

            if(!filesList.isEmpty()){
                for (ContentDocumentLink file : filesList) {
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.ContentDocumentId = file.ContentDocumentId;
                    cd.LinkedEntityId = supportingDocuments[0].Id;
                    cd.ShareType = 'V';
                    filesToBeSharedWithSR.add(cd);
                }
                insert filesToBeSharedWithSR;
            }
        }
    }
}