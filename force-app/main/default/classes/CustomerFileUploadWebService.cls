/*
* Name               : CustomerFileUploadWebService
* Description        : This class is used to upload docuemnt like Profile picture, Passport copy and others 
*/
@RestResource (urlMapping = '/customer/fileupload')
global without sharing class CustomerFileUploadWebService {

    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            handler.response.data = fileUpload(jsonBody);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    public static DocumentQueryModel fileUpload(String jsonBody) {
        DocumentQueryModel newDocument = new DocumentQueryModel();
        
        FileUploadModel fileWrapper = (FileUploadModel)JSON.deserializeStrict(jsonBody, FileUploadModel.class);
        
        if(String.isNotBlank(fileWrapper.contentVersionId)) {
            // Upload File in chunk
            mergeFile(fileWrapper.contentVersionId, fileWrapper.fileData);

            Document__c documentRec = DocumentService.getDocumentRecordById(fileWrapper.documentId);
            newDocument = new DocumentQueryModel(documentRec);
            newDocument.contentVersionId = fileWrapper.contentVersionId;
        } else if (String.isNotBlank(fileWrapper.documentId)) {
            if (((Id)fileWrapper.documentId).getSObjectType() == Document__c.getSObjectType()) {
                // Upload file on Document Id
                Document__c documentRec = CustomerServiceUtility.getDocumentDetail(' (Id = \'' + fileWrapper.documentId + '\') ')[0];
                newDocument = DocumentService.uploadFileToParentRecord(documentRec, fileWrapper.fileTitle, fileWrapper.fileData);

               if(documentRec.DocumentType__c.contains('Signed')) {
                    Document__c DocToUpdate = new Document__c();
                    DocToUpdate.id = documentRec.id;
                    DocToUpdate.Status__c = 'Completed';
                    update DocToUpdate;
                }
                
            } else if (((Id)fileWrapper.documentId).getSObjectType() == SalesOrder__c.getSObjectType()) {
                // Upload file on Sales Order's Document based on document Type
                List<Document__c> docList = CustomerServiceUtility.getDocumentDetail(' (SalesOrder__c = \'' + fileWrapper.documentId + '\' AND DocumentType__c = \'' + fileWrapper.documentType + '\') ');
                if (!docList.isEmpty()) {
                    newDocument = new DocumentQueryModel(docList[0]);
                
                    ContentVersion contentVersionRec = ContentVersionService.createContentVersion(fileWrapper.fileTitle, fileWrapper.fileData);
                    contentVersionRec.IsMajorVersion = false;
                    insert contentVersionRec;

                    newDocument.contentVersionId = contentVersionRec.Id;
                    newDocument.fileExtension = String.valueOf(contentVersionRec.FileExtension);
                    newDocument.title = contentVersionRec.Title;
                    newDocument.documentURL = DocumentService.getFileURL(contentVersionRec.Id);
            
                    ContentDocumentLinkService.createContentDocumentLinks(new List<ContentVersion>{contentVersionRec}, docList[0].Id);
                }
            } else if (((Id)fileWrapper.documentId).getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType()) {
                // Upload file on SR Doc Id
                HexaBPM__SR_Doc__c srDoc = CustomerServiceUtility.getSRDocDetail(' (Id = \'' + fileWrapper.documentId + '\') ')[0];
                newDocument = new DocumentQueryModel(srDoc);
            
                ContentVersion contentVersionRec = ContentVersionService.createContentVersion(fileWrapper.fileTitle, fileWrapper.fileData);
                contentVersionRec.IsMajorVersion = false;
                insert contentVersionRec;

                newDocument.contentVersionId = contentVersionRec.Id;
                newDocument.fileExtension = String.valueOf(contentVersionRec.FileExtension);
                newDocument.title = contentVersionRec.Title;
                newDocument.documentURL = DocumentService.getFileURL(contentVersionRec.Id);
        
                ContentDocumentLinkService.createContentDocumentLinks(new List<ContentVersion>{contentVersionRec}, srDoc.Id);
            } else if (((Id)fileWrapper.documentId).getSObjectType() == HexaBPM__Service_Request__c.getSObjectType()) {
                // Upload file on Service Request's SR Doc based on document Type
                List<HexaBPM__SR_Doc__c> srDocList = CustomerServiceUtility.getSRDocDetail(' (HexaBPM__Service_Request__c = \'' + fileWrapper.documentId + '\' AND Name = \'' + fileWrapper.documentType + '\') ');
                if (!srDocList.isEmpty()) {
                    newDocument = new DocumentQueryModel(srDocList[0]);
                
                    ContentVersion contentVersionRec = ContentVersionService.createContentVersion(fileWrapper.fileTitle, fileWrapper.fileData);
                    contentVersionRec.IsMajorVersion = false;
                    insert contentVersionRec;

                    newDocument.contentVersionId = contentVersionRec.Id;
                    newDocument.fileExtension = String.valueOf(contentVersionRec.FileExtension);
                    newDocument.title = contentVersionRec.Title;
                    newDocument.documentURL = DocumentService.getFileURL(contentVersionRec.Id);
            
                    ContentDocumentLinkService.createContentDocumentLinks(new List<ContentVersion>{contentVersionRec}, srDocList[0].Id);
                }
            } else {
                // Upload file on any record
                ContentVersion contentVersionRec = ContentVersionService.createContentVersion(fileWrapper.fileTitle, fileWrapper.fileData);
                contentVersionRec.IsMajorVersion = false;
                insert contentVersionRec;

                newDocument.contentVersionId = contentVersionRec.Id;
                newDocument.fileExtension = String.valueOf(contentVersionRec.FileExtension);
                newDocument.title = contentVersionRec.Title;
                newDocument.documentURL = DocumentService.getFileURL(contentVersionRec.Id);

                newDocument.id = fileWrapper.documentId;
                ContentDocumentLinkService.createContentDocumentLinks(new List<ContentVersion>{contentVersionRec}, (Id)fileWrapper.documentId);
            }
        } else if (String.isNotBlank(fileWrapper.accountId)) {
            // Upload file based on document type on account level
            Document__c documentRec = new Document__c();
            Id recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();

            Map<Id, List<Document__c>> accountDocumentMap = DocumentService.getDocumentbyAccountId(new Set<Id>{fileWrapper.accountId});
            if(accountDocumentMap != null && accountDocumentMap.containsKey(fileWrapper.accountId)){
                for(Document__c document: accountDocumentMap.get(fileWrapper.accountId)){
                    if(document.DocumentType__c == fileWrapper.documentType){
                        documentRec = document;
                        break;
                    }
                }
            }

            if (documentRec.Id == null) {
                documentRec = DocumentService.createDocumentRecord('', '', '', fileWrapper.documentType, '', fileWrapper.accountId,recordTypeId);
                insert documentRec;
            }
            newDocument = DocumentService.uploadFileToParentRecord(documentRec, fileWrapper.fileTitle, fileWrapper.fileData);
        }
        return newDocument;
    }

    @future
    public static void mergeFile(String contentVersionId, Blob fileData) {
        // Upload File in chunk
        ContentVersion cvObj = [SELECT Id, VersionData FROM ContentVersion WHERE Id =: contentVersionId];
        cvObj.VersionData = EncodingUtil.base64Decode(EncodingUtil.base64Encode(cvObj.VersionData) + EncodingUtil.base64Encode(fileData));
        update cvObj;
    }
}