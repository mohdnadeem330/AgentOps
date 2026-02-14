/**********************************************************************************
 * Name             : BP_SubmitBrokerRequest
 * Description      : API Call for Submit Broker Request
 * Created Date     : 21/03/25
 * Created By       : Moh Sarfaraj
 * Test Class       : 
 * -------------------------------------------------------------------------------*
Version     |   Date(DD/MM/YYYY)    |   Last Modified By    | Comments
----------------------------------------------------------------------------------
1.0         |   21/03/25            |   Moh Sarfaraj        | Initial Draft
**********************************************************************************/
@RestResource (urlMapping = '/submitBrokerRequest')
global without sharing class BP_SubmitBrokerRequest extends BP_BaseRestResource {

    @HttpPost
    global static void execute(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();  
            BP_SubmitBrokerRequest service = new BP_SubmitBrokerRequest();
            ApiResponse response = service.processRequest(params, requestBody);
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        }catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        } 
        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        String brokerRequestId = null;
        try{
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            brokerRequestId = (String) requestBodyData.get('brokerRequestId');
            String invoiceStatus = (String) requestBodyData.get('invoiceStatus');
            String type = (String) requestBodyData.get('type');
            String documentBase64 = (String) requestBodyData.get('documentBase64');
            String documentExtension = (String) requestBodyData.get('documentExtension');
            String description = (String) requestBodyData.get('description');

            if(String.isBlank(brokerRequestId)){
                return new ApiResponse(false, 400,'Broker Request Id is invalid', null);
            }

            if(String.isBlank(invoiceStatus)){
                return new ApiResponse(false, 400,'Invoice Status is invalid', null);
            }

            if(String.isBlank(type)){
                return new ApiResponse(false, 400,'Broker Request type is invalid', null);
            }

            if(String.isBlank(documentBase64)){
                return new ApiResponse(false, 400,'Invoice Document is invalid', null);
            }

            List<BrokerRequest__c> listBrokerRequest = [SELECT Id,Name FROM BrokerRequest__c WHERE Id = :brokerRequestId];

            if(listBrokerRequest == null || listBrokerRequest.isEmpty()){
                return new ApiResponse(false, 400,'Broker Request Id is invalid ', null);
            }

            //Boolean isLockedBefore = false;
            //if(Approval.isLocked(brokerRequestId)){
                //Approval.unlock(brokerRequestId);
                //isLockedBefore = true;
            //}

            BrokerRequest__c brokerRequest = new BrokerRequest__c();
            brokerRequest.Id = brokerRequestId;
            brokerRequest.InvoiceStatus__c = invoiceStatus;
            brokerRequest.Comment__c = description;

            // Set Submitted Date By Agency if invoiceStatus is 'Pending Invoice Verification'
            if(invoiceStatus == 'Pending Invoice Verification'){
                brokerRequest.SubmittedbyAgency__c = Date.today();
            }

            update brokerRequest;

            //if(isLockedBefore){
                //Approval.lock(brokerRequestId);
            //}

            List<Document__c> listDoc = [SELECT Id,DocumentType__c,BrokerRequest__r.Name FROM Document__c 
                                         WHERE BrokerRequest__c =:brokerRequestId 
                                         AND DocumentType__c = 'Broker Marketing Reimbursement' 
                                         LIMIT 1];

            if(listDoc != null && !listDoc.isEmpty()){
                String fileName = listDoc[0].BrokerRequest__r.Name +' - '+ listDoc[0].DocumentType__c + 
                                  (String.isNotBlank(documentExtension) ? '.'+documentExtension : '.pdf');
                ContentVersion cv = createContentVersion(documentBase64, fileName);
                createContentLink(cv.Id, listDoc[0].Id);
            }

            return new ApiResponse(true, 200, 'Broker Request updated successfully', brokerRequest);

        } catch (Exception e){
            LoggerService.save(LoggerService.addApexLog(e, 'Broker2.0 API', 'BP_SubmitBrokerRequest', brokerRequestId));
            return new ApiResponse(false, 400,'Failed to submit Broker Request: ' + e.getMessage(), null);
        }
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
        Network network =  [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        cv.NetworkId = network.Id;

        insert cv;
        return cv;
    }

    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        insert cdl;
        return cdl;
    }
}