public class BatchToDirectDebitCalloutAPIHelper {

    public static string ADIBBankName   		           = 'Abu Dhabi Islamic Bank';
    public static string ADCBBankName   		           = 'Abu Dhabi Commercial Bank';
    public static string FABBankName    		           = 'Abu Dhabi FAB Bank';
    public static string ADCBDateFormat 				   = 'dd-MM-yyyy'; //FIN-155
    public static string ADIBCollectionDateFormat		   = 'yyyy-MM-dd'; //FIN-156
    public static string REGISTRATION   				   = 'New Registration';
    public static string AMENDMENT      				   = 'Amendment';
    public static string CANCELLATION   				   = 'Cancellation';
    public static string COLLECTION     				   = 'Collection';
    public static string RQST          					   = 'RQST';
    public static string AMND           		   		   = 'AMND'; 
    public static string CNCL                   		   = 'CNCL';
    public static string COLL                     		   = 'COLL';
    public static string MANDATE_API_PROCESS     		   = 'MandateApiProcess';
    public static string FIlE_UPLOAD_PROCESS    		   = 'FileUploadProcess';
    public static string COLLECTION_API_PROCESS 		   = 'CollectionAPIProcess';
    public static string ADCBRegistrationMandate		   = 'ADCBRegistrationMandate';
    public static string ADIBRegistrationMandate		   = 'ADIBRegistrationMandate';
    public static string ADCBRegistrationCancel		   	   = 'ADCBRegistrationCancel';
    public static string ADIBRegistrationCancel		   	   = 'ADIBRegistrationCancel';
    public static string ADIBRegistrationMandateFileUpload = 'ADIBRegistrationMandateFileUpload';
    public static string ADIBCollectionMandate 			   = 'ADIBCollectionMandate';
    public static string StatusCode200					   = '200';
    public static string StatusCode201					   = '201';
    public static List<string> successStatusCode		   = new List<String>{StatusCode200, StatusCode201};
    
    public static void PrepareDataForCalloutForMandate(List<DDTransaction__c> ddTransactionList, String requestType){
        
        try {
            
            Map<Id,SalesOrder__c> soMap = getSalesOrderMap(ddTransactionList);
            
           	List<Id> ddTransactionIdList = new List<Id>(getIds(ddTransactionList));
            
            for(DDTransaction__c ddtransaction: ddTransactionList){  
                //Prepare Request Body for callout mandate
                String mandateReference = soMap.get(ddtransaction.DirectDebitRequest__r.SalesOrder__c).Unit__r.VirtualAccountNumber__c != null ? 
                    					  soMap.get(ddtransaction.DirectDebitRequest__r.SalesOrder__c).Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c : '';
                
                String requestBody = DirectDebitCalloutAPIRequestWrapper.PrepareDataForCalloutForMandate(ddtransaction, requestType, mandateReference);
                system.debug('requestBody::'+requestBody);
                
                if (System.IsBatch() == true){ 
                    if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADCBBankName && requestType == REGISTRATION){
                        CalloutToMuleSoft.calloutService(requestBody, true, ADCBRegistrationMandate, ddTransactionIdList); 
                    }else if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c== ADIBBankName && requestType == REGISTRATION){
                        CalloutToMuleSoft.calloutService(requestBody, true, ADIBRegistrationMandate, ddTransactionIdList); 
                    }else if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADCBBankName && requestType == CANCELLATION){
                        CalloutToMuleSoft.calloutService(requestBody, true, ADCBRegistrationCancel, ddTransactionIdList); 
                    }else if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c== ADIBBankName && requestType == CANCELLATION){
                        CalloutToMuleSoft.calloutService(requestBody, true, ADIBRegistrationCancel, ddTransactionIdList); 
                    }
                }                
            }
        } catch (Exception e) {
            LoggerService.save(LoggerService.createApexLog(e,'Mandate API Call','BatchToDirectDebitCalloutAPIHelper','PrepareDataForCalloutForMandate'));
        } 
    }
    
    // File upload call
    public static void PrepareDataForCalloutForFileUpload(List<DDTransaction__c> ddTransactionList, String requestType){
        try { 
            
            /* Declarations */
            List<Id> linkedEntityIds                                 = new List<Id>();
            List<ContentDocumentLink> contentDocumentLinkList        = new List<ContentDocumentLink>();
            List<Contentversion> contentVersionList                  = new List<Contentversion>();
            List<String> contentDocumentIdList                       = new List<String>();
            Map<Id, List<ContentDocumentLink>> contentDocumentMap    = new Map<Id, List<ContentDocumentLink>>();
            Map<Id, Contentversion> contentVersionMap                = new Map<Id, Contentversion>();  
            Map<Id, Map<Id, Contentversion>> ddtIdcontentVersionMap  = new Map<Id, Map<Id, Contentversion>>();
            Map<Id, DDTransaction__c> ddMap;
            
            List<Id> ddTransactionIdList = new List<Id>(getIds(ddTransactionList));
            
            if(!ddTransactionList.isEmpty()) {
                ddMap = new Map<Id,DDTransaction__c>(ddTransactionList);
                contentDocumentLinkList = [SELECT ContentDocumentId, Id, IsDeleted, LinkedEntityId, ShareType, Visibility
                                           FROM ContentDocumentLink WHERE LinkedEntityId IN: ddMap.keySet() ];
            } else {
                return;
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
                contentVersionList = [SELECT Id, ContentDocumentId, versiondata, FileType, PathOnClient, Title
                                      FROM Contentversion WHERE ContentDocumentId IN: contentDocumentIdList AND FileType = 'PDF'];
            }
            if(!contentVersionList.isEmpty()) {
                for(Contentversion contentVersion: contentVersionList) {
                    contentVersionMap.put(contentVersion.ContentDocumentId, contentVersion);
                } 
            }
            System.debug('contentVersionMap'+contentVersionMap);
            
            // make callouts to send files to API
            for(DDTransaction__c ddtransaction: ddTransactionList) {        
                if(contentDocumentMap.get(ddtransaction.Id) != null){
                    /*Prepare the wrapper data and pass request body */
                    for(ContentDocumentLink contentDocumentLink: contentDocumentMap.get(ddtransaction.Id)) {
                        if(ddtransaction.Id == contentDocumentLink.LinkedEntityId && contentVersionMap.get(contentDocumentLink.ContentDocumentId) != null) {//&& contentVersionMap.get(contentDocumentLink.ContentDocumentId).FileType == 'PDF'
                            /* Call for ADCB/ADIB Bank File Upload */
                            if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADCBBankName || ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADIBBankName){
                                ADCBAndADIBFileWrapperClass fileReqWrapper = new ADCBAndADIBFileWrapperClass(); 
                                fileReqWrapper.Data.RequestType = getRequestType(requestType);
                                fileReqWrapper.Data.BankReference = ddtransaction.BankReferenceNumber__c != null ? ddtransaction.BankReferenceNumber__c : '';
                                fileReqWrapper.Data.OICCode = ddtransaction.DirectDebitRequest__r.OIC__c; //940000331
                                fileReqWrapper.Data.File = EncodingUtil.Base64Encode(contentVersionMap.get(contentDocumentLink.ContentDocumentId).versiondata);
                                fileReqWrapper.Data.FileName = ddtransaction.DDAFileName__c ;
                                String fileApiRequestBody = JSON.serialize(fileReqWrapper);
                                System.debug('requestBody::'+fileApiRequestBody); 
                                
                                if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADCBBankName){
                                    //CalloutToMuleSoft.calloutService(fileApiRequestBody, true, 'ADCBFileUpload', ddTransactionIdList);
                                }else if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADIBBankName){
                                    CalloutToMuleSoft.calloutService(fileApiRequestBody, true, ADIBRegistrationMandateFileUpload, ddTransactionIdList);
                                }
                                /* Call for FAB Bank File Upload */
                            } 
                            //FAB-Code-Comments
                            /*else if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == FABBankName){
                                // place holder wrapper for FAB bank
                                FABFileWrapperClass fileReqWrapper = new FABFileWrapperClass(); 
                                fileReqWrapper.Data.RequestType = getRequestType(requestType);
                                //fileReqWrapper.Data.BankReference = ddtransaction.DirectDebitRequest__r.BankReferenceNumber__c;
                                fileReqWrapper.Data.OICCode = ddtransaction.DirectDebitRequest__r.OIC__c;
                                fileReqWrapper.Data.File = EncodingUtil.Base64Encode(contentVersionMap.get(contentDocumentLink.ContentDocumentId).versiondata);
                                fileReqWrapper.Data.FileName = contentVersionMap.get(contentDocumentLink.ContentDocumentId).PathOnClient;
                                String fileApiRequestBody = JSON.serialize(fileReqWrapper);
                                System.debug('requestBody::'+fileApiRequestBody); 
                                CalloutToMuleSoft.calloutService(fileApiRequestBody, true, '<create a service in Mule soft metadata and pass it here>', ddTransactionIdList); 
                            }*/
                        }
                    }
                }
            }
        } catch (Exception e) {
            LoggerService.save(LoggerService.createApexLog(e,'File Upload API Call','BatchToDirectDebitCalloutAPIHelper','PrepareDataForCalloutForFileUpload'));
        }
    }
    
    public static void PrepareDataForCalloutForCollection(List<DDTransaction__c> ddTransactionList, String requestType){
        
        
        List<Id> ddTransactionIdList = new List<Id>(getIds(ddTransactionList));
        Map<Id,SalesOrder__c> soMap = getSalesOrderMap(ddTransactionList);
        
        // make callouts to send files to API
        for(DDTransaction__c ddTransaction: ddTransactionList) {
            if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADCBBankName || ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADIBBankName){
                ADCBAndADIBBulkCollectionWrapperClass collectionReqWrapper = new ADCBAndADIBBulkCollectionWrapperClass(); 
                                
                ADCBAndADIBBulkCollectionWrapperClass.ClaimedAmount amountwrap = new ADCBAndADIBBulkCollectionWrapperClass.ClaimedAmount();
                amountwrap.Amount = String.valueOf(ddtransaction.CollectionAmount__c);
                amountwrap.Currency_Z = ddtransaction.DirectDebitRequest__r.CurrencyIsoCode;
                
                ADCBAndADIBBulkCollectionWrapperClass.Instruction instructionwrap = new ADCBAndADIBBulkCollectionWrapperClass.Instruction();
                instructionwrap.OriginatorAccountNumber = ddtransaction.DirectDebitRequest__r.Originator_Account_Number__c;//12961810
                instructionwrap.IBAN = ddtransaction.DirectDebitRequest__r.CustomerIBANNumber__c;
                instructionwrap.DueDate = String.valueOf(System.Now().format(ADIBCollectionDateFormat));//FIN-156
                instructionwrap.ClaimedAmount = amountwrap;
                
                List<ADCBAndADIBBulkCollectionWrapperClass.Collection> lstcollectionwrap = new List<ADCBAndADIBBulkCollectionWrapperClass.Collection>();
                ADCBAndADIBBulkCollectionWrapperClass.Collection collectionwrap = new ADCBAndADIBBulkCollectionWrapperClass.Collection();
                String customerReference = ddtransaction.DirectDebitRequest__r.Name.right(5)+ddtransaction.Name.right(5);
                collectionwrap.CustomerReference = customerReference;//ddtransaction.DirectDebitRequest__r.PayerIdentification__c; 
                collectionwrap.DDRReference = ddTransaction.DirectDebitRequest__r.DDAreferencenumber__c; //DDR Bank Reference nmber //FIN-153
                
                String mandateReference = soMap.get(ddtransaction.DirectDebitRequest__r.SalesOrder__c).Unit__r.VirtualAccountNumber__c != null ? 
                    					  soMap.get(ddtransaction.DirectDebitRequest__r.SalesOrder__c).Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c : '';
                
                collectionwrap.MandateReferenceNumber = mandateReference;
                collectionwrap.RepresentmentFlag = '';
                collectionwrap.instruction = instructionwrap;
                lstcollectionwrap.add(collectionwrap);
                
                
                ADCBAndADIBBulkCollectionWrapperClass.Data crwData = new ADCBAndADIBBulkCollectionWrapperClass.Data();
                crwData.OICCode = ddtransaction.DirectDebitRequest__r.OIC__c;
                crwData.RequestType = getRequestType(requestType);
                crwData.Collection = lstcollectionwrap;
                collectionReqWrapper.Data = crwData;
                
                String collectionApiRequestBody = JSON.serialize(collectionReqWrapper);
                collectionApiRequestBody = collectionApiRequestBody.replace('Currency_Z','Currency');
                System.debug('requestBody::- collection '+ collectionApiRequestBody);                            
                CalloutToMuleSoft.calloutService(collectionApiRequestBody, true, ADIBCollectionMandate, ddTransactionIdList);                                
                /* Call for FAB Bank File Upload */
            } 
            //FAB-Code-Comment
            /*else if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == FABBankName){
                // place holder wrapper for FAB bank
                FABFileWrapperClass fileReqWrapper = new FABFileWrapperClass(); 
                fileReqWrapper.Data.RequestType = getRequestType(requestType);
                //fileReqWrapper.Data.BankReference = ddtransaction.DirectDebitRequest__r.BankReferenceNumber__c;
                fileReqWrapper.Data.OICCode = ddtransaction.DirectDebitRequest__r.OIC__c;
                String fileApiRequestBody = JSON.serialize(fileReqWrapper);
                System.debug('requestBody::'+fileApiRequestBody); 
                CalloutToMuleSoft.calloutService(fileApiRequestBody, true, '<create a service in Mule soft metadata and pass it here>', ddTransactionIdList); 
            }*/
        }
    }

    public static void updateDdtransactionResponse(String responseBody, List<Id> recordIds, String requestBody, String ProcessName, String StatusCode){
       	System.debug('StatusCode '+StatusCode);
        System.debug('ProcessName '+ProcessName);
        
        List<DDTransaction__c> DDTransactionListToUpdate = new List<DDTransaction__c>();
        List<DirectDebitRequest__c> DDRecordsToUpdate = new List<DirectDebitRequest__c>();
        Id directDebitId = [SELECT DirectDebitRequest__c From DDTransaction__c WHERE Id =: recordIds[0]].DirectDebitRequest__c;
        
        System.debug('DD Record Id '+ directDebitId);
        
        //1. Process Registration Response
        if(successStatusCode.contains(StatusCode) && (ProcessName == ADCBRegistrationMandate || ProcessName == ADIBRegistrationMandate)){
            ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper  successWrapper = (ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper.class);
            System.debug(' Success wrapper \n'+ successWrapper);
            if(successWrapper.Data != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   BankReferenceNumber__c = successWrapper.Data.BankReference,
                                                                   //MandateReferenceNumber__c = successWrapper.Data.MandateReferenceNumber,
                                             					   BankAPIsyncstatus__c = 'Ready for file upload API',
                                                                   //TransactionStatus__c = 'Processed by Salesforce',
                                                                   DDTError__c = '',
                                                                   DDTErrorMessage__c = ''));
            }
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   TransactionStatus__c = 'Unprocessed',
                                                                   BankAPIsyncstatus__c = 'Registration Mandate API failed'));
            }
        }else if(!successStatusCode.contains(StatusCode) && (ProcessName == ADCBRegistrationMandate || ProcessName == ADIBRegistrationMandate)){
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   TransactionStatus__c = 'Unprocessed',
                                                                   BankAPIsyncstatus__c = 'Registration Mandate API failed'));
            }
        } 
        
        //2. Process File Upload Response
        if(successStatusCode.contains(StatusCode) && ProcessName == ADIBRegistrationMandateFileUpload){
            ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper  successWrapper = (ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper.class);
            System.debug(' Success wrapper ADIBRegistrationMandateFileUpload \n'+ successWrapper);
            if(successWrapper.Data != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   BankAPIsyncstatus__c = 'Registration sent to bank',
                                                                   TransactionStatus__c = 'Processed by Salesforce',
                                                                   DDTError__c = '',
                                                                   DDTErrorMessage__c = ''));
                DDRecordsToUpdate.add(new DirectDebitRequest__c(Id = directDebitId,
                                                                Status__c = 'Sent to Bank'));
            }
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'File upload API failed'));
            }
        }else if( !successStatusCode.contains(StatusCode) && ProcessName == ADIBRegistrationMandateFileUpload){
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'File upload API failed'));
            }
        }
        
        /*if(successStatusCode.contains(StatusCode) && ProcessName == 'ADCBFileUpload' ){
            ADCBAndADIBFileWrapperClass  fileSuccessWrapper = (ADCBAndADIBFileWrapperClass)System.JSON.deserialize(responseBody, ADCBAndADIBFileWrapperClass.class);
        }else if(!successStatusCode.contains(StatusCode) && ProcessName == 'ADCBFileUpload'){
            ADCBAndADIBFileWrapperClass  fileFailureWrapper = (ADCBAndADIBFileWrapperClass)System.JSON.deserialize(responseBody, ADCBAndADIBFileWrapperClass.class);
        }*/
        
        // 3. COllection API Response handling
        if( successStatusCode.contains(StatusCode) && ProcessName == ADIBCollectionMandate ){
            ADCBAndADIBCollectionAPIResponse collectionSuccess = (ADCBAndADIBCollectionAPIResponse)System.JSON.deserialize(responseBody, ADCBAndADIBCollectionAPIResponse.class);
            System.debug('collectionSuccess.Data '+collectionSuccess.Data);
            if(collectionSuccess.Data != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   CollectionBatchId__c = collectionSuccess.Data.CollectionBatchId,
                                                                   BankAPIsyncstatus__c = 'Collection sent to bank'));
            }
            if(collectionSuccess.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   DDTError__c = collectionSuccess.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = collectionSuccess.Errors[0].Message.length() <= 255 ? collectionSuccess.Errors[0].Message : collectionSuccess.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'Collection API failed'));
            }
            
        }else if(!successStatusCode.contains(StatusCode) && ProcessName == ADIBCollectionMandate){
            ADCBAndADIBCollectionAPIResponse collectionfailure = (ADCBAndADIBCollectionAPIResponse)System.JSON.deserialize(responseBody, ADCBAndADIBCollectionAPIResponse.class);
            if(collectionfailure.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   DDTError__c = collectionfailure.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = collectionfailure.Errors[0].Message.length() <= 255 ? collectionfailure.Errors[0].Message : collectionfailure.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'Collection API failed'));
            }
        }
        
        //4. Cancellation API Response handling
        if(successStatusCode.contains(StatusCode) && (ProcessName == ADIBRegistrationCancel || ProcessName == ADCBRegistrationCancel)){
            ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper  successWrapper = (ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper.class);
            System.debug(' Success wrapper \n'+ successWrapper);
            if(successWrapper.Data != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   BankReferenceNumber__c = successWrapper.Data.BankReference,
                                                                   //MandateReferenceNumber__c = successWrapper.Data.MandateReferenceNumber,
                                             					   BankAPIsyncstatus__c = 'Cancellation sent to bank'));
            }
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'Cancellation API failed'));
            }
        }else if( !successStatusCode.contains(StatusCode) && (ProcessName == ADIBRegistrationCancel || ProcessName == ADCBRegistrationCancel)){
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = recordIds[0],
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'Cancellation API failed'));
            }
        }
        
        if(!DDTransactionListToUpdate.isEmpty()){
            update DDTransactionListToUpdate;
        }
        if(!DDRecordsToUpdate.isEmpty()){
            update DDRecordsToUpdate;
        }
        
        /*Let all the Response updates go in this method */
    }
    
    public static String getRequestType(String requestType) {
        if (requestType == REGISTRATION) {
            return RQST;
        } else if (requestType == AMENDMENT) {
            return AMND;
        } else if (requestType == CANCELLATION) {
            return CNCL;
        } else if (requestType == COLLECTION) {
            return COLL;
        }
        return null;
    }

    public static String getCustomerIdType(String CustomerIdType){
        String customerIdtypeValue;
        switch on CustomerIdType{
            when 'Passport'{
                customerIdtypeValue = 'PASSP';
            }
            when 'UAE Emirates Identity Card'{
                customerIdtypeValue = 'EIDAC';
            }
            when 'UAE Driving License Number'{
                customerIdtypeValue = 'DRVLN';
            }
            when 'Family Book Number'{
                customerIdtypeValue = 'FAMBK';
            }
            when 'Trade License Number'{
                customerIdtypeValue = 'TRDLN';
            }
            when 'Emiree Decree Number'{
                customerIdtypeValue = 'EMRDN';
            }
            when 'Chamber Certification Number'{
                customerIdtypeValue = 'CHMCN';
            }
        }
        return customerIdtypeValue;
    }
    
    public static Set<Id> getIds( List<sObject> objs ){
        Map<Id, sObject> objectMap = new Map<Id, sObject>();
        objectMap.putAll( objs );
        Set<Id> ids = objectMap.keySet().clone();
        ids.remove(null);
        return ids;
    }
    
    public static Map<Id,SalesOrder__c> getSalesOrderMap(List<DDTransaction__c> ddTransactionList){
        Set<Id> setOfDirectDebitIds = new Set<Id>();
        Set<Id> setOfSalesOrderIds = new Set<Id>();
        Map<Id,SalesOrder__c> mapOfSalesOrders = new Map<Id,SalesOrder__c>();
        for(DDTransaction__c ddtransaction: ddTransactionList){
            //setOfDirectDebitIds.add(ddtransaction.DirectDebitRequest__c);
            setOfSalesOrderIds.add(ddtransaction.DirectDebitRequest__r.SalesOrder__c);
        }
        /*for(DirectDebitRequest__c ddr : [SELECT Id,SalesOrder__c From DirectDebitRequest__c WHERE Id IN : setOfDirectDebitIds]){
            if(ddr.SalesOrder__c != null){
                setOfSalesOrderIds.add(ddr.SalesOrder__c);
            }
        }*/
        Map<Id,SalesOrder__c> soMap = new Map<Id,SalesOrder__c>([SELECT Id, Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c
                                                                 FROM SalesOrder__c 
                                                                 WHERE Id IN: setOfSalesOrderIds]);
        return soMap;
    }
    
}