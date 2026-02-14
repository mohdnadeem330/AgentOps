@RestResource (urlMapping = '/edds/updateEDirectDebit')
global with sharing class EDDSUpdateDirectDebitWebService {
    
    @HTTPPost
    global static void doPost(String ddaId, String status, String transactionType, String journeyType, String fileBase64){
        RestContextHandler handler = new RestContextHandler(true);
        try {
            Boolean isError = false;
            String errorMessage = '';
            RestRequest req = RestContext.request;
            //validate enum value
            if(EDDSService.isValidJourneyType(journeyType)==false){
                isError = true;
                errorMessage += 'Provide a valid Journey Type. ';
            }
            if(EDDSService.isValidTransactionType(transactionType)==false){
                isError = true;
                errorMessage += 'Provide a valid Transaction Type. ';
            }
            if (EDDSService.isValueInPicklist('DirectDebitRequest__c', 'Status__c', status)==false) {
                isError = true;
                errorMessage += 'Provide a valid Status value. ';
            }
            if(isError) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_NOT_FOUND;
                handler.response.message = errorMessage.trim();
                handler.setResponseStatusCode(Constants.STATUS_CODE_NOT_FOUND);
                handler.finalize();
                return;
            }
            String transactionValue = '';
            if(transactionType == EDDSService.TRANSACTION_TYPE.NewRegistration.name()){
                transactionValue = 'New Registration';
            }else if(transactionType == EDDSService.TRANSACTION_TYPE.Cancellation.name()){
                transactionValue = 'Cancellation';
            }

            List<DDTransaction__c> ddTransactions = [SELECT Id,TransactionStatus__c,EDDS_DDAID__c,EDDS_DDARID__c,EDDS_DDA_Reference_Number__c,DirectDebitRequest__c,DirectDebitRequest__r.Name FROM DDTransaction__c 
                                                WHERE EDDS_DDAID__c = :ddaId AND RequestType__c = :transactionValue LIMIT 1];
            if(!ddTransactions.isEmpty()){
                ddTransactions[0].TransactionStatus__c = status;
                update ddTransactions[0];

                DirectDebitRequest__c dd = EDDSService.getDirectDebitByIdSet(new Set<Id>{ddTransactions[0].DirectDebitRequest__c})[0];

                if(fileBase64!=null && fileBase64 != ''){
                    ContentVersion cv = new ContentVersion();
                    cv.Title = 'Signed-Registration-Document-'+ddTransactions[0].DirectDebitRequest__r.Name+'.pdf';
                    cv.PathOnClient = 'Signed-Registration-Document-'+ddTransactions[0].DirectDebitRequest__r.Name+'.pdf';
                    cv.VersionData = EncodingUtil.base64Decode(fileBase64);
                    cv.IsMajorVersion = true;
                    Insert cv;
                    if(cv != null){
                        Id conDocId;
                        conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
                        
                        ContentDocumentLink cdlDDT = New ContentDocumentLink();
                        cdlDDT.LinkedEntityId = ddTransactions[0].Id;
                        cdlDDT.ContentDocumentId = conDocId;
                        cdlDDT.shareType = 'V';
                        Insert cdlDDT;
    
                        Document__c signedDocument = [SELECT Id FROM Document__c WHERE DocumentType__c =: Constants.DOCUMENT_TYPE_DDRF AND DirectDebitRequest__c =: ddTransactions[0].DirectDebitRequest__c LIMIT 1];
    
                        if(signedDocument != null){
                            ContentDocumentLink cdlDD = New ContentDocumentLink();
                            cdlDD.LinkedEntityId = signedDocument.Id;
                            cdlDD.ContentDocumentId = conDocId;
                            cdlDD.shareType = 'V';
                            Insert cdlDD;
                        }
                    }
                }
                handler.response.data = dd;
                handler.response.success = true;
                handler.response.message = Constants.SUCCESS_MESSAGE;
                handler.finalize();
            }else{
                throw new CustomException('Invalid ddaId');
            }
        } catch (CustomException ex) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_NOT_FOUND;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
            
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.setResponseStatusCode(Constants.STATUS_CODE_SYSTEM_ERROR);
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
   
}