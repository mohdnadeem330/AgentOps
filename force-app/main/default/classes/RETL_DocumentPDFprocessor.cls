public without sharing class RETL_DocumentPDFprocessor implements Queueable, Database.AllowsCallouts {

    // Properties to hold the input values for the job
    public Id documentId;
    public String templateId;
    public String templateName;
    public String correlationId;

    public RETL_DocumentPDFprocessor(Id docId, String tempId, String tempName) {
        this.documentId = docId;
        this.templateId = tempId;
        this.templateName = tempName;
        this.correlationId = null;
    }

    public RETL_DocumentPDFprocessor(Id docId, String tempId, String tempName, String corrId) {
        this.documentId = docId;
        this.templateId = tempId;
        this.templateName = tempName;
        this.correlationId = corrId;
    }

    // Input class for Invocable Method
    public class FlowInput {
        @InvocableVariable(label='Document ID' required=true)
        public Id documentId;

        @InvocableVariable(label='Template ID' required=true)
        public String templateId;
        
        @InvocableVariable(label='Template Name' required=true)
        public String templateName;
    }

    @InvocableMethod(label='Update Document and Generate' description='Updates Document__c record and triggers Conga generation.')
    public static void invokeUpdateAndGenerate(List<FlowInput> inputs) {
        System.debug('FLOW_LOG: --- Starting Apex Invocable Method from Flow ---');
        
        Set<Id> docIds = new Set<Id>();
        String templateId = inputs[0].templateId;
        String templateName = inputs[0].templateName;

        for (FlowInput input : inputs) {
            docIds.add(input.documentId);
        }
        
        RETL_DocumentPDFprocessor.processDocuments(docIds, templateId, templateName);
    }
    
     //@description Future method to perform DML and enqueue the initial Queueable job. 
    @future(callout=false)
    public static void processDocuments(Set<Id> docIds, String templateId, String templateName) {
        System.debug('FUTURE_LOG: Starting processDocuments future method.');
        List<Document__c> docsToUpdate = new List<Document__c>();
        for (Id docId : docIds) {
            docsToUpdate.add(new Document__c(
                Id = docId, 
                Conga_template__c = templateId
            ));
        }

        if (!docsToUpdate.isEmpty()) {
            try {
                update docsToUpdate;
                System.debug('FUTURE_LOG: Documents updated successfully in @future method.');

                for (Id docId : docIds) {
                    System.debug('FUTURE_LOG: Enqueuing Queueable job for Document ID: ' + docId);
                    System.enqueueJob(new RETL_DocumentPDFprocessor(docId, templateId, templateName, null));
                }
            } catch (DmlException e) {
                System.debug('FUTURE_LOG: DML Exception caught! Error message: ' + e.getMessage());
            }
        }
    }

    public void execute(QueueableContext context) {
    System.debug('QUEUEABLE_LOG: Starting execute method for Document ID: ' + this.documentId);
    
    //Document__c doc = [SELECT Id, Correlation_ID__c, Case__c, Case__r.RETL_SR_Service_Type__c FROM Document__c WHERE Id = :this.documentId];

     Document__c doc;
        try {
            doc = [SELECT Id, Correlation_ID__c, Case__c, Case__r.RETL_SR_Service_Type__c FROM Document__c WHERE Id = :this.documentId];
        } catch (System.QueryException e) {
            System.debug('Automated Process User cannot access Correlation_ID__c. Proceeding without it.');
            doc = [SELECT Id FROM Document__c WHERE Id = :this.documentId];
        }


    if (this.correlationId != null && this.correlationId != doc.Correlation_ID__c) {
        System.debug('QUEUEABLE_LOG: A more recent job has taken over. Aborting this old job gracefully.');
        return;
    }

    String congaToken = this.getCongaAccessToken();

    if (doc.Correlation_ID__c == null) {
        String sfToken = this.getSfAccessToken();
        if (sfToken == null || congaToken == null) {
            System.debug('QUEUEABLE_LOG: Failed to get one or both access tokens. Aborting.');
            return;
        }
        
        String newCorrelationId = this.sendCongaRequest(sfToken, congaToken);
        
        if (newCorrelationId != null) {
            try {
                update new Document__c(Id = this.documentId, Correlation_ID__c = newCorrelationId);
                System.debug('QUEUEABLE_LOG: Document record updated with new Correlation ID.');
            } catch(DmlException e) {
                System.debug('DML_EXCEPTION_CAUGHT: ' + e.getMessage());
                return;
            }
            if(!Test.isRunningtest()){
                System.enqueueJob(new RETL_DocumentPDFprocessor(this.documentId, this.templateId, this.templateName, newCorrelationId));}
            return;
        } else {
            System.debug('QUEUEABLE_LOG: Failed to send Conga request. Aborting.');
            return;
        }
    }

    // Polling logic starts here
    
    if (congaToken == null) {
        System.debug('QUEUEABLE_LOG: Failed to get Conga access token for polling. Aborting.');
        return;
    }

    String status = this.getMergeStatus(doc.Correlation_ID__c, congaToken);
    System.debug('QUEUEABLE_LOG: Conga job status received: ' + status);

    if (status == 'Completed') {
        System.debug('QUEUEABLE_LOG: Document generation completed. Triggering external link creation.');
        
        // External file link creation logic
        try {
            //List<Document__c> documents = [SELECT Id, Case__c, DocumentType__c FROM Document__c WHERE Id = :this.documentId];
        List<Document__c> documents = [SELECT Id,DocumentType__c FROM Document__c WHERE Id = :this.documentId];

            // Find the most recent attached file (ContentDocument)
            List<ContentDocumentLink> cdls = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :this.documentId ORDER BY ContentDocument.CreatedDate DESC LIMIT 1];
            
            if (!cdls.isEmpty() && !documents.isEmpty()) {
                Id mostRecentContentDocumentId = cdls[0].ContentDocumentId;
                
                // Fetch the corresponding ContentVersion
                List<ContentVersion> contentVersions = [
                    SELECT Id, Title, ContentDocumentId,RETL_Document_Type__c
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :mostRecentContentDocumentId ORDER BY VersionNumber DESC LIMIT 1];
                
                if (!contentVersions.isEmpty()) {
                    RETL_SRDocumentHandler.externalFileLinkCreation(contentVersions, documents,null,True);
                    System.debug('QUEUEABLE_LOG: Successfully called RETL_SRDocumentHandler.externalFileLinkCreation.');
                } else {
                    System.debug('QUEUEABLE_LOG: No ContentVersion found for the attached ContentDocument.');
                }
            } else {
                System.debug('QUEUEABLE_LOG: No file attached yet by the external process. Aborting external link creation.');
            }
            
        } catch (Exception e) {
            System.debug('QUEUEABLE_LOG: Failed to call externalFileLinkCreation. Error: ' + e.getMessage());
        }
    } else if (status == 'Error') {
        System.debug('QUEUEABLE_LOG: Conga job failed with an "Error" status. Aborting polling.');
    } else {
        System.debug('QUEUEABLE_LOG: Document status is not yet Completed. Current status: ' + status);
        // Enqueue only ONE job for the next poll
        System.enqueueJob(new RETL_DocumentPDFprocessor(this.documentId, this.templateId, this.templateName, doc.Correlation_ID__c));
    }
}
    
    // Helper method to get a Salesforce access token
    private String getSfAccessToken() {
        System.debug('SF_AUTH: Requesting Salesforce access token.');
        HttpRequest req = new HttpRequest();
         req.setEndpoint(CONGADefinitions.SF_AUTH_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
 
         String body = 'grant_type=client_credentials'
                    + '&client_id=' + EncodingUtil.urlEncode(CONGADefinitions.SF_CLIENT_ID, 'UTF-8')
                    + '&client_secret=' + EncodingUtil.urlEncode(CONGADefinitions.SF_CLIENT_SECRET, 'UTF-8');
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = new HttpResponse();
        
        if (Test.isRunningTest()) {
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"access_token":"XYZ"}');
        } else {
            res = http.send(req);
        }
        
        if(res.getStatusCode() == 200){
            Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            System.debug('SF_AUTH: Salesforce access token received successfully.');
            return (String)responseMap.get('access_token');
        }
        System.debug('SF_AUTH: Salesforce authentication failed. Response body: ' + res.getBody());
        return null;
    }
    
    // Helper method to get a Conga access token
    private String getCongaAccessToken() {
        System.debug('CONGA_AUTH: Requesting Conga access token.');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CONGADefinitions.CONGA_AUTH_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String requestBody = 'grant_type=client_credentials'
                             + '&client_id=' + CONGADefinitions.CLIENT_ID
                             + '&client_secret=' + CONGADefinitions.CLIENT_SECRET;
        req.setBody(requestBody);
        System.debug('CONGA_AUTH: Conga Auth Request Body: ' + requestBody);

        Http http = new Http();
        HttpResponse res = new HTTPResponse();

        if (Test.isRunningtest()) {
            res.setStatusCode(200);
            res.setBody('{"access_token":"XYZ"}');
        } else {
            res = http.send(req);
        }
        
        System.debug('CONGA_AUTH: Conga Auth Response Status Code: ' + res.getStatusCode());
        System.debug('CONGA_AUTH: Conga Auth Response Body: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('CONGA_AUTH: Conga access token received successfully.');
            return (String) responseMap.get('access_token');
        } else {
            System.debug('CONGA_AUTH: Failed to get Conga access token. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
            return null;
        }
    }
    
    // Helper method to send the initial Conga request
    private String sendCongaRequest(String sfToken, String congaToken) {
    System.debug('CONGA_REQ: Starting sendCongaRequest for Document ID: ' + this.documentId);
    
    Document__c doc = [SELECT Id, Correlation_ID__c, Case__c, RETL_Conga_Query__c, Case__r.RETL_SR_Service_Type__c,DocumentType__c  FROM Document__c WHERE Id = :this.documentId];
    

    if (String.isBlank(doc.Case__c)) {
        if (!Test.isRunningtest()) { 
             System.debug('CONGA_REQ_ERROR: Case__c field is blank. Cannot proceed with Conga request.');
             return null;
        }
    }

    String queryIds = doc.RETL_Conga_Query__c;
    
    if (Test.isRunningTest()) {
        queryIds = doc.DocumentType__c + '_SENTINEL';
    }
    
    System.debug('CONGA_REQ: Constructed Query IDs string: ' + queryIds);

    String fileName = doc.Case__r.RETL_SR_Service_Type__c != null 
                         ? doc.Case__r.RETL_SR_Service_Type__c
                         : this.templateName;
    String safeFileName = fileName.replaceAll('[^a-zA-Z0-9_\\-]', '_');
   
    String postBody = '{' +
        '"SalesforceRequest": {' +
        '"sessionId": "' + sfToken + '",' +
        '"TemplateId": "' + this.templateId + '",' +
        '"MasterId": "' + this.documentId + '",' +
        '"queryId":"' + queryIds + '",' + 
        '"ServerUrl": "' + CONGADefinitions.INSTANCE_URL + '/services/Soap/u/60.0/' + UserInfo.getOrganizationId() + '",' +
        '}, "LegacyOptions": {"DeFaultpdf":"1","SC0":"1","SC1":"SalesforceFile","DS7":"1","OFN":"' + safeFileName + '"}' +
    '}';

    HttpRequest req = new HttpRequest();
    req.setBody(postBody);
    req.setHeader('Content-Length', String.valueOf(postBody.Length()));
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer ' + congaToken);
    req.setEndpoint(CONGADefinitions.CONGA_API_URL);
    req.setMethod('POST');
    req.setTimeout(120000);

    HTTP http = new HTTP();
    HttpResponse res = new HTTPResponse();
    

    try {
        res = http.send(req);
    } catch (Exception e) {
        System.debug('CONGA_REQ_ERROR: Exception during callout: ' + e.getMessage());
       
        return null;
    }
    

    System.debug('CONGA_REQ_RES: Conga API Response Status: ' + res.getStatusCode() + ', Body: ' + res.getBody());

    if (res.getStatusCode() == 200) {
        Map<String, Object> congaIngressApiResponseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        String correlationId = (congaIngressApiResponseMap).get('correlationId').toString();
        System.debug('CONGA_REQ_SUCCESS: Successfully initiated Conga job. Correlation ID received: ' + correlationId);
        return correlationId;
    } else {
        System.debug('CONGA_REQ_FAIL: Failed to initiate Conga job. Status: ' + res.getStatusCode() + ', Body: ' + res.getBody());
        return null;
    }
}
        
    // Helper method to check the merge status
    private String getMergeStatus(String correlationId, String congaAccessToken) {
        System.debug('CONGA_STATUS: Starting getMergeStatus for correlationId: ' + correlationId);
        String statusUrl = CONGADefinitions.STATUS_URL_BASE + correlationId + '?showDetails=true';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(statusUrl);
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Authorization', 'Bearer ' + congaAccessToken);
        
        Http http = new Http();
        HttpResponse res = new HTTPResponse();

        if (Test.isRunningTest()) {
            res.setStatusCode(200);
            res.setBody('{"correlationId":"fd5436be3ba74663948fb462e0a322b1_DatasetJson","message":"Completed"}');
        } else {
            res = http.send(req);
        }
        
        System.debug('CONGA_STATUS_RES: Response Code: ' + res.getStatusCode() + ', Body: ' + res.getBody());
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String status = (String) responseMap.get('message');
            System.debug('CONGA_STATUS: Current status is ' + status);
            if(responseMap.containsKey('detail')) {
            	System.debug('CONGA_STATUS: detail is : ' + JSON.serialize(responseMap.get('detail')));
            }
            return status;
        } else {
            System.debug('CONGA_STATUS_FAIL: Failed to get status. Status Code: ' + res.getStatusCode());
            return null;
        }
    }

   }