public class BatchToDirectDebitEnquiryCalloutHelper {
    public static string ADIBBankName = 'Abu Dhabi Islamic Bank';
    public static string ADCBBankName = 'Abu Dhabi Commercial Bank';
    public static string FABBankName = 'Abu Dhabi FAB Bank';
    public static string REGISTRATION = 'New Registration';
    public static string COLLECTION = 'Collection';
    // Mandate Enquiry API callout
    public static void getMandateEnquiryResult(List<DDTransaction__c> ddTransactionList, String requestType){
        try {
            Map<String, String> paramToBeReplacedInEndPoint = new Map<String, String>();
            Map<String, String> queryParams = new Map<String, String>();
            List<Id> ddTransactionIdList = new List<Id>(BatchToDirectDebitCalloutAPIHelper.getIds(ddTransactionList));
            
            Map<Id,SalesOrder__c> soMap = BatchToDirectDebitCalloutAPIHelper.getSalesOrderMap(ddTransactionList);
            
            for(DDTransaction__c ddtransaction: ddTransactionList){
                
                String mandateReference = soMap.get(ddtransaction.DirectDebitRequest__r.SalesOrder__c).Unit__r.VirtualAccountNumber__c != null ? 
                    					  soMap.get(ddtransaction.DirectDebitRequest__r.SalesOrder__c).Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c : '';
                
                paramToBeReplacedInEndPoint.put('(OICCode)', ddtransaction.DirectDebitRequest__r.OIC__c);//'940000331'
                paramToBeReplacedInEndPoint.put('(RequestType)', BatchToDirectDebitCalloutAPIHelper.getRequestType(requestType));
                
                //String customerReference = ddtransaction.DirectDebitRequest__r.Name.right(5)+ddtransaction.Name.right(5);
               
                //queryParams.put('customerReference', customerReference);
                
                if(String.isNotBlank(mandateReference)){
                    queryParams.put('mandateReferenceNumber', mandateReference);                
                }else{
                    queryParams.put('bankReference', ddtransaction.BankReferenceNumber__c != '' ? ddtransaction.BankReferenceNumber__c : '');
                }
                
                if (System.IsBatch() == true || Test.isRunningTest()){ 
                    if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADCBBankName && (requestType == REGISTRATION)){
                        BatchToDirectDebitEnquiryCalloutHelper.calloutService('ADCBRegistrationMandateEnquiry', true, paramToBeReplacedInEndPoint, queryParams, ddTransactionIdList); 
                    }else if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == ADIBBankName && (requestType == REGISTRATION || requestType == 'Cancellation')){
                        BatchToDirectDebitEnquiryCalloutHelper.calloutService('ADIBRegistrationMandateEnquiry', true, paramToBeReplacedInEndPoint, queryParams, ddTransactionIdList); 
                    }
                }
            }
        } catch (Exception e) {
            LoggerService.save(LoggerService.createApexLog(e,'Mandate Enquiry API Call','BatchToDirectDebitCalloutAPIHelper','PrepareDataForCalloutForMandateEnquiry'));
        }
    }

     // Mandate Collection Enquiry API callout
     public static void getMandateCollectionEnquiryResult(List<DDTransaction__c> ddTransactionList, String requestType){
        try {
            Map<String, String> paramToBeReplacedInEndPoint = new Map<String, String>();
            Map<String, String> queryParams = new Map<String, String>();
            List<Id> ddTransactionIdList = new List<Id>(BatchToDirectDebitCalloutAPIHelper.getIds(ddTransactionList));
            
            for(DDTransaction__c ddtransaction: ddTransactionList){
                paramToBeReplacedInEndPoint.put('(OICCode)', ddtransaction.DirectDebitRequest__r.OIC__c);
                paramToBeReplacedInEndPoint.put('(RequestType)', BatchToDirectDebitCalloutAPIHelper.getRequestType(requestType));
                //String customerReference = ddtransaction.DirectDebitRequest__r.Name.right(5)+ddtransaction.Name.right(5);
                //queryParams.put('customerReference', customerReference);
                //queryParams.put('bankReference', ddtransaction.BankReferenceNumber__c);
                queryParams.put('collectionBatchId', ddtransaction.CollectionBatchId__c);
                //queryParams.put('mandateReferenceNumber', ddtransaction.DirectDebitRequest__r.MandateReferenceNumber__c != '' ? ddtransaction.DirectDebitRequest__r.MandateReferenceNumber__c : '');                
                
                if (System.IsBatch() == true || Test.isRunningTest()){ 
                    if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c== ADCBBankName && (requestType == REGISTRATION)){
                        BatchToDirectDebitEnquiryCalloutHelper.calloutService('ADCBRegistrationMandateCollectionEnquiry', true, paramToBeReplacedInEndPoint, queryParams, ddTransactionIdList); 
                    }else if(ddtransaction.DirectDebitRequest__r.DirectDebitBank__c== ADIBBankName && requestType == COLLECTION){
                        BatchToDirectDebitEnquiryCalloutHelper.calloutService('ADIBRegistrationMandateCollectionEnquiry', true, paramToBeReplacedInEndPoint, queryParams, ddTransactionIdList); 
                    }
                }
            }
        } catch (Exception e) {
            LoggerService.save(LoggerService.createApexLog(e,'Mandate Collection Enquiry API Call','BatchToDirectDebitCalloutAPIHelper','PrepareDataForCalloutForMandateEnquiry'));
        }
    }

    public static void calloutService(String processName, Boolean processResponse, Map<String, String> paramToBeReplacedInEndPoint, Map<String, String> queryParams, List<Id> ddTransactionIdList){
        
        String muleRes = '';
       try {
            //---- Fetch mulesoft URLs
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(processName);
            Organization org = Utilities.getOrganizationDetails();
            
            String endPointURL = mulesoftAPI.SandboxURL__c;
            System.debug('Endpoint : '+endPointURL);
            if(!org.IsSandbox){
                endPointURL = mulesoftAPI.ProductionURL__c; 
            }
        	System.debug('paramToBeReplacedInEndPoint '+paramToBeReplacedInEndPoint);
            for (String param : paramToBeReplacedInEndPoint.keySet()) {
                endPointURL = endPointURL.replace(param, paramToBeReplacedInEndPoint.get(param));
            }
            if (queryParams != null) {
                endPointURL = endPointURL + '?';
                for (String queryParam : queryParams.keySet()) {
                    endPointURL = endPointURL + queryParam + '=' + queryParams.get(queryParam)+'&';
                }
            }
        	
        if (endPointURL.endsWith('&')) {
            endPointURL = endPointURL.substring(0, endPointURL.length() - 1);
        }
        
        	System.debug('Endpoint ADIB Enquery: '+endPointURL);

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setHeader('Content-Type','application/json');
            request.setHeader('client_secret',mulesoftAPI.APIKey__c);
            request.setHeader('client_id',mulesoftAPI.APIId__c);
            request.setTimeout(120000);
            request.setEndpoint(endPointURL);
            request.setMethod(mulesoftAPI.Method__c);
            
             //request.setBody(requestBody);

            HttpResponse response = http.send(request);
            muleRes = response.getBody();
            System.debug('**Response Body**'+muleRes);
            System.debug('processName'+processName);
            if (processName == 'ADCBRegistrationMandateEnquiry' || processName == 'ADIBRegistrationMandateEnquiry') { 
                System.debug('response.getStatusCode() ' + response.getStatusCode());
                BatchToDirectDebitEnquiryCalloutHelper.updateDdtransactionResponse(processName, response.getStatusCode(), muleRes, ddTransactionIdList);
                
                //Loggers for DirectDebit
                LoggerService.save(LoggerService.addApexServiceCalls('ADIBRegistrationMandateEnquiry','ADIBRegistrationMandateEnquiry',processName,endPointURL,(muleRes.length() < 131072 ? muleRes : muleRes.left(131070)),null));
            
            } else if (processName == 'ADCBRegistrationMandateCollectionEnquiry' || processName == 'ADIBRegistrationMandateCollectionEnquiry') {
                System.debug('response.getStatusCode() ' + response.getStatusCode());
                BatchToDirectDebitEnquiryCalloutHelper.updateDdtransactionResponse(processName, response.getStatusCode(), muleRes, ddTransactionIdList);
                
                //Loggers for DirectDebit
                LoggerService.save(LoggerService.addApexServiceCalls('ADIBRegistrationMandateEnquiry','ADIBRegistrationMandateEnquiry',processName,endPointURL,(muleRes.length() < 131072 ? muleRes : muleRes.left(131070)),null));
            
            }
        } catch (DMLException ex) {
            Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(ex,processName,'CalloutToMuleSoft','calloutService'));
            // updateStatusAsFailed(recordIds, lgs.Id);
            System.debug('DMLException lgs.Id -> '+lgs.Id);
        } catch(Exception e){
            Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.addApexServiceCallsLog(e, 'CalloutToMuleSoft', 'calloutService', processName, null, muleRes));
            // updateStatusAsFailed(recordIds, lgs.Id);
            System.debug('Exception lgs.Id -> '+lgs.Id);
        }
    }
    
    
   public static void updateDdtransactionResponse(String processName, Integer statusCode, String responseBody, List<Id> ddTransactionIdList){
        List<DDTransaction__c> DDTransactionListToUpdate = new List<DDTransaction__c>();
       	List<DirectDebitRequest__c> DDRecordsToUpdate = new List<DirectDebitRequest__c>();
        Id directDebitId = [SELECT DirectDebitRequest__c From DDTransaction__c WHERE Id =: ddTransactionIdList[0]].DirectDebitRequest__c;
        System.debug('DD Record Id '+ directDebitId);
        
        //1. Mandate Enquiry Response Process
        if( (statusCode == 201 || statusCode == 200) && (processName == 'ADCBRegistrationMandateEnquiry' || processName == 'ADIBRegistrationMandateEnquiry')){
            ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper  successWrapper = (ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.successResponsewrapper.class);
            if(successWrapper.Data != null){
                String transactionStatus = '';
                switch on successWrapper.Data.Status.Code {
                    when 'K' {
                        transactionStatus = 'ACK';
                    }
                    when 'N' {
                        transactionStatus = 'NAK';
                    }
                    when 'R' {
                        transactionStatus = 'Rejected';
                    }
                    when 'S' {
                        transactionStatus = 'Sent to Bank';
                    }
                    when 'A' {
                        transactionStatus = 'Approved';
                    }
                    when else {
                        transactionStatus = 'Response received from Bank';
                    }
                }
                DDTransactionListToUpdate.add(new DDTransaction__c(Id=ddTransactionIdList[0], 
                                                                   TransactionStatus__c = transactionStatus,
                                                                   BankAPIsyncstatus__c = 'Mandate Enquiry response received',
                                                                   //BankReferenceNumber__c=successWrapper.Data.BankReference,
                                                                   BankStatusCode__c = successWrapper.Data.Status.Code,
                                                                   BankStatusMessage__c = successWrapper.Data.Status.Message,
                                                                   //DDRReference__c = successWrapper.Data.DDRReference,
                                                                   AckNackResponse__c = getMandateCodeMessage(successWrapper.Data.Status.Code)));
                if(successWrapper.Data.Status.Code == 'A'){
                     DDRecordsToUpdate.add(new DirectDebitRequest__c(Id = directDebitId,
                                                                	 Status__c = 'Approved by Bank',
                                                                     DDAreferencenumber__c = successWrapper.Data.DDRReference));
                }
                else if(successWrapper.Data.Status.Code == 'R'){
                     DDRecordsToUpdate.add(new DirectDebitRequest__c(Id = directDebitId,
                                                                	 Status__c = 'Rejected by Bank',
                                                                     Rejection_Reason__c = successWrapper.Data.Status.Message));
                }
               
                
            }
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            System.debug('Fail Mandate Enquiry : '+ failureWrapper);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = ddTransactionIdList[0],
                                                                   TransactionStatus__c = 'Response received from Bank',
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'Mandate Enquiry API failed'));
            }                        
        } else if( (statusCode != 201 && statusCode != 200) && (processName == 'ADCBRegistrationMandateEnquiry' || processName == 'ADIBRegistrationMandateEnquiry')){
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            System.debug('Fail : '+ failureWrapper);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = ddTransactionIdList[0],
                                                                   TransactionStatus__c = 'Response received from Bank',
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'Mandate Enquiry API failed'));
            }
        }
        
        //2. Collection Enquiry Response Process
        if( (statusCode == 201 || statusCode == 200) && (processName == 'ADCBRegistrationMandateCollectionEnquiry' || processName == 'ADIBRegistrationMandateCollectionEnquiry')){
            ADCBAndADIBCollectionEnqueryWrapper  successWrapper = (ADCBAndADIBCollectionEnqueryWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBCollectionEnqueryWrapper.class);
            System.debug('Success : '+ successWrapper);
            if(successWrapper.Data != null){
                String transactionStatus = '';
                switch on successWrapper.Data.Collection[0].Status.Code {
                    when 'K' {
                        transactionStatus = 'ACK';
                    }
                    when 'NK' {
                        transactionStatus = 'NAK';
                    }
                    when 'R' {
                        transactionStatus = 'Rejected';
                    }
                    when 'S' {
                        transactionStatus = 'Sent to Bank';
                    }
                    when 'P' {
                        transactionStatus = 'Approved';
                    }
                    when else {
                        transactionStatus = 'Response received from Bank';
                    }
                }
                
                DDTransactionListToUpdate.add(new DDTransaction__c(Id=ddTransactionIdList[0],
                                                                   TransactionStatus__c = transactionStatus,
                                                                   BankAPIsyncstatus__c = 'Mandate Collection Enquiry response received',
                                                                   BankReferenceNumber__c=successWrapper.Data.Collection[0].BankReference,
                                                                   AckNackResponse__c = getCollectionCodeMessage(successWrapper.Data.Collection[0].Status.Code)));
            }            
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            System.debug('Fail Mandate Enquiry : '+ failureWrapper);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = ddTransactionIdList[0],
                                                                   TransactionStatus__c = 'Response received from Bank',
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'Mandate Collection Enquiry API Failed'));
            }                        
        } else if( (statusCode != 201 && statusCode != 200) && (processName == 'ADCBRegistrationMandateCollectionEnquiry' || processName == 'ADIBRegistrationMandateCollectionEnquiry')){
            ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper  failureWrapper = (ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper)System.JSON.deserialize(responseBody, ADCBAndADIBMandateResponseWrapperClass.failureResponseWrapper.class);
            System.debug('Fail : '+ failureWrapper);
            if(failureWrapper.Errors != null){
                DDTransactionListToUpdate.add(new DDTransaction__c(Id = ddTransactionIdList[0],
                                                                   TransactionStatus__c = 'Response received from Bank',
                                                                   DDTError__c = failureWrapper.Errors[0].ErrorCode,
                                                                   DDTErrorMessage__c = failureWrapper.Errors[0].Message.length() <= 255 ? failureWrapper.Errors[0].Message : failureWrapper.Errors[0].Message.left(250),
                                                                   BankAPIsyncstatus__c = 'Mandate Collection Enquiry API Failed'));
            }
        }
        
        if(!DDTransactionListToUpdate.isEmpty()){
            update DDTransactionListToUpdate;
        }
       if(!DDRecordsToUpdate.isEmpty()){
            update DDRecordsToUpdate;
        }
       
    }
    
    
    public static String getMandateCodeMessage(String code){
        String message = '';
        switch on code{
            when 'C'{
                message = 'Checker Approved';
            }
            when 'M'{
				message = 'Maker Entered';                
            }
            when 'A'{
                message = 'Accepted';
            }
            when 'S'{
				message = 'Sent to Central MMS';                
            }
            when 'F'{
                message = 'Checker Failed';
            }
            when 'K'{
				message = 'Acknowledgement Received';                
            }
            when 'N'{
                message = 'Negative Acknowledgement Received';
            }
            when 'R'{
                message = 'Rejected';
            }
            when 'U'{
				message = 'Pending';                
            }
            when 'Y'{
                message = 'Ready For Verification';
            }
            when 'V'{
				message = 'Ready For Authorization';                
            }
            when 'P'{
				message = 'Ready For Confirmation';                
            }
        }
        
        return message;
    }
    
    public static String getCollectionCodeMessage(String code){
        String message = '';
        switch on code{
            when 'P'{
                message = 'Checker Approved';
            }
            when 'int'{
				message = 'Maker Entered';                
            }
            when 'NK'{
                message = 'Negative Acknowledgement Received';
            }
            when 'R'{
				message = 'Un Paid';                
            }
            when 'PP'{
                message = 'Partially Paid';
            }
            when 'K'{
				message = 'Acknowledgement Received';                
            }
            when 'S'{
                message = 'Sent For Clearing';
            }
            when 'C'{
                message = 'Checker Approved';
            }
            when 'SP'{
				message = 'Status Pending';                
            }
        }
        
        return message;
    }

}