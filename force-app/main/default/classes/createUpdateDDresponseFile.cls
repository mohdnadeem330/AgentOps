@RestResource (urlMapping = '/upsert/ddResponseFile')
global with sharing class createUpdateDDresponseFile {
    
    @HTTPPost
    global static void doPost(String File_id, String BankName, String FileType, String fileName, String base64){
        system.debug('+++++++ File_id '+File_id);
        system.debug('+++++++ BankName '+BankName);
        system.debug('+++++++ FileType '+FileType);
        system.debug('+++++++ fileName '+fileName);
        system.debug('+++++++ base64 '+base64);
        RestContextHandler handler = new RestContextHandler(true);
        string errorMsg = '';
        Id conDocId;
        try {  
            
            if(base64 == null || base64 == ''){
                throw New CustomException('File is mandatory to create this record');
            }else {
                DDResponseFiles__c ddresponseFile = new DDResponseFiles__c();
                ddresponseFile.Bank__c = BankName;
                ddresponseFile.Type__c = FileType;
                ddresponseFile.ERP_File_Id__c = File_id; 
                ddresponseFile.Status__c = 'Unprocessed';
                upsert ddresponseFile;
                
                ContentVersion cv = new ContentVersion();
                cv.Title = fileName;
                cv.PathOnClient = fileName;
                cv.VersionData = Blob.valueOf(EncodingUtil.base64Decode( base64).toString());
                cv.IsMajorVersion = true;
                Insert cv;
                if(cv != null){
                    conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
                    
                    ContentDocumentLink cdl = New ContentDocumentLink();
                    cdl.LinkedEntityId = ddresponseFile.Id;
                    cdl.ContentDocumentId = conDocId;
                    cdl.shareType = 'V';
                    Insert cdl;
                }
            }
        }catch (DMLException exc) {
            LoggerService.save(LoggerService.addApexLog(exc,'createUpdateDDresponseFile','doPost',''));
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = exc.getDMLMessage(0);
            handler.finalize(exc);
        } catch (Exception ex) {
            LoggerService.save(LoggerService.addApexLog(ex,'createUpdateDDresponseFile','doPost',''));
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = ex.getMessage() != null ? ex.getMessage(): Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);            
        } 
    }
}