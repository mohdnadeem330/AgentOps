@RestResource(urlMapping='/file/upload')
global with sharing class FileUploadWebService {

    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);

        try {   
            
                RestRequest req = RestContext.request;
                String JsonBody = req.requestBody.toString();
                FileUploadModel fileWrapper = (FileUploadModel)JSON.deserializeStrict(JsonBody,FileUploadModel.class);

                DocumentQueryModel newDocument = new DocumentQueryModel();
                System.debug(fileWrapper.fileTitle+'**fileContent**'+fileWrapper.fileData);
                Blob fileContent = fileWrapper.fileData;
                
                if(fileWrapper.accountId != null){
                    Document__c documentRec = new Document__c();
                    Id recordTypeID = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();

                    String accountPlaceholderCategory = '';

                    Map<Id,List<Document__c>> accountDocumentMap = DocumentService.getDocumentbyAccountId(new Set<Id>{fileWrapper.accountId});

                    if(accountDocumentMap!=null && accountDocumentMap.containsKey(fileWrapper.accountId)){
                        for(Document__c document : accountDocumentMap.get(fileWrapper.accountId)){
                            if(document.DocumentType__c == fileWrapper.documentType){
                                documentRec = document ;
                            }
                        }
                    }

                    if(documentRec.Id==null){
                        documentRec = DocumentService.createDocumentRecord('','','',fileWrapper.documentType,'',fileWrapper.accountId,recordTypeID);
                        insert documentRec ;
                    }/*else{
                        if(fileWrapper.documentType.contains('Signed'))
                            documentRec.Status__c = 'Completed';
                        update documentRec ;
                    }*/
                          
                    newDocument = DocumentService.uploadFileToParentRecord(documentRec, fileWrapper.fileTitle, fileContent);
                }
                else if(fileWrapper.documentId != null){
                    Document__c documentRec = DocumentService.getDocumentRecordById(fileWrapper.documentId);
                    newDocument = DocumentService.uploadFileToParentRecord(documentRec, fileWrapper.fileTitle, fileContent);
                    
                    if(documentRec.DocumentType__c.contains('Signed'))
                            documentRec.Status__c = 'Completed';
                        update documentRec ;

                }
                handler.response.data = newDocument ;          
                handler.response.success = true;
                handler.finalize();
            
            if(Test.isRunningTest())
                System.debug('Document '+Decimal.valueOf(JsonBody));
            
        }catch (DMLException exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }catch(Exception ex){

            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }

    
}