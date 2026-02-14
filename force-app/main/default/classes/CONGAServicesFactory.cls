/**********************************************************************************************************************
* Name               : CONGAServicesFactory                                                        
* Description        : This class contains all the helper methods for Calling CONGA COMPOSER
* Test Class         : CONGAServicesFactory_Test
* Created By         : Protivity Global                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Charan Vuyyuru          15 Apr 2025     Initial Draft       
******************************************************************************************************************/
public class CONGAServicesFactory{
    
    public static String getCongaAccessToken() {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CONGADefinitions.CONGA_AUTH_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String requestBody = 'grant_type=client_credentials'
                           + '&client_id=' + CONGADefinitions.CLIENT_ID
                           + '&client_secret=' + CONGADefinitions.CLIENT_SECRET;
        req.setBody(requestBody);
        
        Http http = new Http();
        HttpResponse res = new HTTPResponse();
        res.setStatusCode(200);
        res.setBody('{"access_token":"XYZ"}');
        res = test.isRunningtest() ? res : http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Success getCongaAccessToken --'+res.getStatusCode());
            return (String) responseMap.get('access_token');
        }
        return null; 
    }
    
    
    public static String getSfAccessToken() {
        
        //return userinfo.getSessionId();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CONGADefinitions.SF_AUTH_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        /*
        String body = 'grant_type=password'
                    + '&client_id=' + EncodingUtil.urlEncode(CONGADefinitions.SF_CLIENT_ID, 'UTF-8')
                    + '&client_secret=' + EncodingUtil.urlEncode(CONGADefinitions.SF_CLIENT_SECRET, 'UTF-8')
                    + '&username=' + EncodingUtil.urlEncode(CONGADefinitions.SF_USERNAME, 'UTF-8')
                    + '&password=' + EncodingUtil.urlEncode(CONGADefinitions.SF_PASSWORD, 'UTF-8');
        */
        String body = 'grant_type=client_credentials'
                    + '&client_id=' + EncodingUtil.urlEncode(CONGADefinitions.SF_CLIENT_ID, 'UTF-8')
                    + '&client_secret=' + EncodingUtil.urlEncode(CONGADefinitions.SF_CLIENT_SECRET, 'UTF-8');
        req.setBody(body);
		//Start Modifications CloudzLab
        System.debug('Request Body: '+JSON.serializePretty(body));
        //End Modifications CloudzLab
        Http http = new Http();
        HttpResponse res = new HTTPResponse();
        res.setStatusCode(200);
        res.setBody('{"access_token":"XYZ"}');
        res = test.isRunningtest() ? res : http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Success getSfAccessToken --'+res.getStatusCode());
            return (String) responseMap.get('access_token');
      
        } 
        return null;
        
    }
    
    
    @future(callout=true)
    public static void asyncCONGARequest(Id documentId){
        syncCONGARequest(documentId);
    }
    
    public static void syncCONGARequest(Id documentId){
        
        String sfToken = getSfAccessToken();
        String congaToken = getCongaAccessToken();
        HttpRequest req = new HttpRequest();
        Document__c doc = [Select id, name, SalesOrder__c,DocumentType__c, SalesOrder__r.name, Conga_Query_ID__c, GenerateDocument__c, conga_template__c from Document__c where id =: documentId];
        String postBody = '{' +
            '"SalesforceRequest": {' +
                '"sessionId": "'+ sfToken + '",' +
                '"TemplateId": "' + doc.conga_template__c + '",' +
                '"MasterId": "' + doc.Id + '",' +
                '"queryId":"'+doc.Conga_Query_ID__c+'",'+
                '"ServerUrl": "'+ CongaDefinitions.INSTANCE_URL + '/services/Soap/u/60.0/' + UserInfo.getOrganizationId() +'",' +
            '}, "LegacyOptions": {"DeFaultpdf":"1","SC0":"1","SC1":"SalesforceFile","DS7":"1","OFN":"'+doc.DocumentType__c+'"}' +
        '}';
        req.setBody(postBody);
        
        req.setHeader('Content-Length', String.valueOf(postBody.Length()));
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + congaToken);

        req.setEndpoint(CongaDefinitions.CONGA_API_URL);
        req.setMethod('POST');
        req.setTimeout(120000);
        HTTP http = new HTTP();
        HttpResponse res = new HTTPResponse();
        res.setStatusCode(200);
        res.setBody('{"correlationId":"40955dd8240a45eca75a6ad660b72ea2_DatasetJson","status":"Accepted","result":{"statusCode":"Success","statusMessage":[{"code":"SUCC200","description":"Success"}]}}');
        res = test.isRunningtest() ? res : http.send(req);
        system.debug('>>>>>>>>'+res.getBody());
        
        Map<String, Object> congaIngressApiResponseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        String correlationId = (congaIngressApiResponseMap).get('correlationId').toString();
        system.debug('correlationId:' + correlationId);
        update new Document__c(id = documentId, GenerateDocument__c = false, Correlation_ID__c = correlationId);    
            
    }
    

    @InvocableMethod(label='Generate Conga PDF')
    public static List<ResponseWrapper> generateCongaDoc(List<RequestWrapper> requests) {
        List<ResponseWrapper> responses = new List<ResponseWrapper>();
        List<String> results = new List<String>();
        
        for (RequestWrapper input : requests) {
            ResponseWrapper resWrap = new ResponseWrapper();
            String sfToken = getSfAccessToken();
            String congaToken = getCongaAccessToken();
    
            if (sfToken == null || congaToken == null) {
                resWrap.status = 'Error';
                resWrap.errorMessage = 'Missing token(s)';
                responses.add(resWrap);
                continue;
            }
            
               
            HttpRequest req = new HttpRequest();
            req.setEndpoint(CongaDefinitions.CONGA_API_URL);
            req.setMethod('POST');
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + congaToken);
            
            string objectName = '';
            Id recordId = input.masterId;
            if(recordId.getSobjectType() == Document__c.sobjectType){
                objectName = 'Document__c';
            }
            
            if(recordId.getSobjectType() == Account.sobjectType){
                objectName = 'Account';
            }
            
            if(recordId.getSobjectType() == Opportunity.sobjectType){
                objectName = 'Opportunity';
            }
            if(recordId.getSobjectType() == OpportunityEOI__c.sobjectType){
                objectName = 'OpportunityEOI__c';
            }
            if(recordId.getSobjectType() == InstallmentLines__c.sobjectType){
                objectName = 'InstallmentLines__c';
            }
             if(recordId.getSobjectType() == HexaBPM__SR_Doc__c.sobjectType){
                objectName = 'HexaBPM__SR_Doc__c';
            }
            if(recordId.getSobjectType() == Adhoc_Proforma_Invoices__c.sobjectType){
                objectName = 'Adhoc_Proforma_Invoices__c';
            }
             if(recordId.getSobjectType() == Case.sobjectType){
                objectName = 'Case';
            }
             if(recordId.getSobjectType() == SalesOrder__c.sobjectType){
                objectName = 'SalesOrder__c';
            }
            if(recordId.getSobjectType() == SalesOrderOtherCharges__c.sobjectType){
                objectName = 'SalesOrderOtherCharges__c';
            }
            //Start of Modification by CloudzLab
            if(recordId.getSobjectType() == Quote.sObjectType)
            {
                objectName = 'Quote';
            }
            //End of Modification by CloudzLab
            
            
            
            
            //Start of Modifications by CloudzLab
            sobject obj;
            String congaQuery = '';
            if(objectName == 'Quote')
            {
                Quote q = [SELECT Id, Opportunity.PropertyUsage__c,ECSS_Record_Type_Name__c FROM Quote WHERE Id =: recordId AND ECSS_Record_Type_Name__c = 'Leasing' LIMIT 1];
                String tempDocType ='';
                if(q.Opportunity.PropertyUsage__c == 'Residential Lease')
                {
                    tempDocType = 'Residential Leasing Offer Letter';
                }
                else if(q.Opportunity.PropertyUsage__c == 'Commercial')
                {
                    tempDocType = 'Commercial Leasing Offer Letter';
                }
                congaQuery = ECSS_CongaDocumentGenerator.generateCongaQueryString(tempDocType, recordId);
            }
            else
            {
                obj = database.query('Select id, Conga_Query_Id__c from '+objectName+' where id =: recordId');
				congaQuery = string.valueof(obj.get('Conga_Query_Id__c'));
            }

            //'queryId' => '[AccountPerson]0Q_0132AA214247',
            //'queryId' => string.valueof(obj.get('Conga_Query_Id__c')),    
            Map<String, Object> salesforceRequest = new Map<String, Object>{
                'sessionId' => sfToken,
                'templateId' => input.templateId,
                'masterId' => input.masterId,
                'QueryId' => congaQuery,  
                'serverUrl' => CongaDefinitions.INSTANCE_URL + '/services/Soap/u/60.0/' + CongaDefinitions.ORG_ID
            };
            //End of Modifications by CloudzLab
            Map<String, Object> legacyOptions = new Map<String, Object>{
                'OFN' => input.outputFileName,
                'defaultPDF' => '1',
                'DS7'=> '11',
                'SC0'=>'1',
                'SC1'=>'SalesforceFile'
            };
            System.debug('Output file name (OFN): ' + input.outputFileName);
            
            Map<String, Object> outputMap = new Map<String, Object>{
                'generateDocumentDownload'=> true};
            
            Map<String, Object> requestBody = new Map<String, Object>{
                'CongaAccessToken' => congaToken,
                'mergeUrl' => CongaDefinitions.MERGE_URL,
                'sfAccessToken' => sfToken,
                'instanceUrl' => CongaDefinitions.INSTANCE_URL,
                'orgId' => CongaDefinitions.ORG_ID,
                'salesforceRequest' => salesforceRequest,
                'legacyOptions' => legacyOptions,
               'output' => outputMap
            };
            req.setBody(JSON.serialize(requestBody));
            System.debug(JSON.serializePretty(requestBody));
            Http http = new Http();
            HttpResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"correlationId":"40955dd8240a45eca75a6ad660b72ea2_DatasetJson","status":"Pending","result":{"statusCode":"Success","statusMessage":[{"code":"SUCC200","description":"Success"}]}}');
            res = test.isRunningtest() ? res : http.send(req);            
     
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                System.debug('Success Genrate Document Request statuscode --'+res.getStatusCode());
                System.debug('Success Genrate Document body ---'+res.getBody());
                String correlationId = (String) result.get('correlationId');
                System.debug('correlationId --'+correlationId);
                String status = getMergeStatus(correlationId, congaToken);
                resWrap.correlationId = correlationId;
                resWrap.status = status;
                system.debug('>>>>>>>'+status);
                if (status == 'Completed' || status == 'Pending') {
                    
                    //System.enqueueJob(new DemoCongaDownloadQueueable(correlationId, congaToken, 1));
                    if(status == 'Pending' || test.isRunningTest()){
                        /*
                        for (Integer i = 0; i < (test.isRunningTest() ? 1 : 50); i++) {
                            status = getMergeStatus(correlationId, congaToken);
                            if(status == 'Pending')
                                DelayController();
                            else
                                break;
                        }
                        */
                    }
                    if(status == 'Completed'){
                        system.debug('>>>>Coomnpleted>>');
                        //getLatestDocumentURL(input.masterId);
                        //String url = DemoCongaDocumentGenerator.getPresignedDownloadUrl(correlationId, congaToken);
                        //system.debug('>>>>Coomnpleted>>'+url);
                        //String downloadResult = DemoCongaDocumentGenerator.downloadFinalDocumentUsingCorrelationId(correlationId, congaToken, input.masterId);
                        //system.debug('>>>>downloadResult>>'+downloadResult);
                    }
                }
            }
    
            responses.add(resWrap);
        }
    
        return responses;
    }
    
    
    //Merge Status API
    public static String getMergeStatus(String correlationId, String congaAccessToken) {
        system.debug('>>>>>>>>>'+correlationId);
        system.debug('>>>>>>>>>'+congaAccessToken);
        String statusUrl = CongaDefinitions.STATUS_URL_BASE + correlationId + '?showDetails=true';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(statusUrl);
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Authorization', 'Bearer ' + congaAccessToken);
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        HttpResponse res = new HTTPResponse();
        res.setBody('{"correlationId":"fd5436be3ba74663948fb462e0a322b1_DatasetJson","message":"Pending","messageId":"MessageId_1848f02946bc43aa99c1e4bf23b46a33d8ace16227904e69acdea24645be945e","lastUpdateTimeStamp":638799347878191388,"expirationTime":638799383878191389,"createdDate":"2025-04-11T02:19:10.696","detail":[{"id":"c2bb7080-02c0-47d5-8391-66f376909989","correlationId":"fd5436be3ba74663948fb462e0a322b1_DatasetJson","transactionId":"33a26c05-55ce-46a5-83ec-fc4c3bba363b","operation":"composer-merge","message":"Completed","errors":[],"statusCode":599,"detail":"Completed","eventDate":"2025-04-11T02:19:46.576"},{"id":"0d4c6cb4-3285-4549-a7cb-a30bf85ca2be","correlationId":"fd5436be3ba74663948fb462e0a322b1_DatasetJson","transactionId":"c10b5fc4-4913-4304-9324-a66566d7bd11","operation":"ComposerMergeSaga","message":"Completed","errors":[],"statusCode":200,"detail":"ComposerMergeSaga","eventDate":"2025-04-11T02:19:46.591"},{"id":"ccc848b1-9415-45aa-b4a9-7143f94dbc16","correlationId":"fd5436be3ba74663948fb462e0a322b1_DatasetJson","transactionId":"c827f28e-ac76-48a0-b656-cb5da672d23f","operation":"presignedpanda","message":"Completed","errors":[],"statusCode":200,"eventDate":"2025-04-11T02:19:46.989"}],"errors":[],"eventDate":"2025-04-11T02:19:46.989","expirationTimeDateTime":"2025-04-11T03:19:47.819139Z"}');
        res.setStatusCode(200);
        res = test.isrunningTest() ? res : http.send(req); 
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Merge status API - getStatusCode --'+res.getStatusCode());
            String message = (String) responseMap.get('message'); // This is what you want: Pending, Completed, Failed, etc.
            System.debug('Merge status API get body --'+res.getBody());
            System.debug('Merge status API get message --'+message);
            return (String) responseMap.get('message');
        }
        return null;
    }
    
    // Get Downlaod URL
    /*
    public static HTTPResponse getPresignedDownloadUrl(String correlationId, String congaAccessToken) {
        String fullUrl = CongaDefinitions.BASE_DOWNLOAD_URL + correlationId + '?showDetails=true';
            
        HttpRequest req = new HttpRequest();
        req.setEndpoint(fullUrl);
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Authorization', 'Bearer ' + congaAccessToken);
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        
        HttpResponse res = new HTTPResponse();
        res.setStatusCode(200);
        res.setBody('{"isSuccessful":true,"statusCode":200,"preSignedCreateResponseModel":{"correlationId":"e7a7f99b93f4461590a1fbc14d3d98bc_DatasetJson","fileInfoDetailsList":[{"transactionId":"cfefdb5f-aa51-4401-acf3-99740e839c4c","url":"https://coreapps-preview.congacloud.eu/api/presigned/v1/PreSignedService/e7a7f99b93f4461590a1fbc14d3d98bc_DatasetJson/cfefdb5f-aa51-4401-acf3-99740e839c4c/Account+KYC+Form.pdf","fileName":"Account KYC Form.pdf","tags":null}]}}');
        res = test.isRunningTest() ?  res: http.send(req);
        
        System.debug('Download API Response Status: ' + res.getStatusCode());
        System.debug('Download API Raw Body: ' + res.getBody());
        return res;
        
    }
    
    //Download the document
    public static String downloadFinalDocumentUsingCorrelationId(String correlationId, String congaAccessToken, string masterId) {
        
        HTTPResponse presignedUrlResponse = getPresignedDownloadUrl(correlationId, congaAccessToken);
        string presignedURL = '';
        string outputFileName = '';
        if(presignedUrlResponse.getStatusCode() == 200){
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(presignedUrlResponse.getBody());
                
            if (responseMap.containsKey('preSignedCreateResponseModel')) {
                Map<String, Object> innerModel = (Map<String, Object>) responseMap.get('preSignedCreateResponseModel');
                if (innerModel.containsKey('fileInfoDetailsList')) {
                    List<Object> fileList = (List<Object>) innerModel.get('fileInfoDetailsList');
                    if (!fileList.isEmpty()) {
                        Map<String, Object> fileInfo = (Map<String, Object>) fileList[0];  
                        if (fileInfo.containsKey('url')) {
                            presignedURL = (String) fileInfo.get('url');
                            outputFileName = (string) fileInfo.get('fileName');
                        }
                    }
                }
            }
        }
                
                
        if (presignedUrl == null || presignedUrl.startsWith('Error') || presignedUrl.startsWith('Exception')) {
            return 'Failed to get presigned URL: ' + presignedUrl;
        }
        
        String pathPart = presignedUrl.replace(CongaDefinitions.BASE_DOWNLOAD_DOCUMENTFINAL, '');
        List<String> pathSegments = pathPart.split('/');
        if (pathSegments.size() < 2) {
            return 'Could not extract lookup values from URL.';
        }
        
        String lookup1 = pathSegments[0];
        String lookup2 = pathSegments[1];
        String finalDownloadUrl = CongaDefinitions.BASE_DOWNLOAD_DOCUMENTFINAL + lookup1 + '/' + lookup2;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(finalDownloadUrl);
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Authorization', 'Bearer ' + congaAccessToken);
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        res.setBody('124234235');
        res.setStatusCode(200);
        res = test.isrunningTest() ? res : http.send(req);
        
        if (res.getStatusCode() == 200) {
            Blob fileContent = res.getBodyAsBlob();
            
            ContentDocumentLink cdlink = [Select id, contentDocumentId from ContentDocumentLink where linkedEntityId =: masterId order by ContentDocument.createddate desc limit 1];
            //Contentversion cv = [Select id, ContentDocumentId from ContentVersion order by createdDate desc limit 1];
            String instanceUrl = URL.getOrgDomainUrl().toExternalForm();
            String link = instanceUrl + '/sfc/servlet.shepherd/document/download/' + cdlink.ContentDocumentId;
            system.debug('Link of PDF'+link);
            
            return link;
            
        }
        return null;

        
    }
*/

    public static string getLatestDocumentURL(id masterId){
        ContentDocumentLink cdlink = [Select id, contentDocumentId from ContentDocumentLink where linkedEntityId =: masterId order by ContentDocument.createddate desc limit 1];
        String instanceUrl = URL.getOrgDomainUrl().toExternalForm();
        String link = instanceUrl + '/sfc/servlet.shepherd/document/download/' + cdlink.ContentDocumentId;
        system.debug('Link of PDF'+link);
        return link;
    }

    public class RequestWrapper {
        @InvocableVariable(required=true) public String templateId;
        @InvocableVariable(required=true) public String masterId;
        @InvocableVariable(required=true) public String outputFileName;
        //@InvocableVariable(required=true) public String solutionName;
    }
    
    private static void DelayController() {
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        while ((finishTime - startTime) < 1000) {
            //sleep for 1s
            finishTime = DateTime.now().getTime();
        }
    }
    public class ResponseWrapper {
            
        @InvocableVariable public String correlationId;
        @InvocableVariable public String status;
        @InvocableVariable public String errorMessage;
    }
    
    
    
    @AuraEnabled(cacheable=false)
    public static StatusResponse getStatusAndDownload(String correlationId, string recordId) {
      
                                                        
        String token = getCongaAccessToken();
        StatusResponse result = new StatusResponse();
        try {
            system.debug('>>>>>>'+correlationId);
            system.debug('>>>>>>'+token);
            String status = getMergeStatus(correlationId, token);
            result.status = status;
            system.debug('>>>>>>'+status);
            if (status == 'Completed' || test.isrunningTest()) {
                //Call the final document method instead of just the presigned URL
                //String finalLink = downloadFinalDocumentUsingCorrelationId(correlationId, token, recordId);
                String finalLink = getLatestDocumentURL(recordId);
                result.downloadUrl = finalLink;
            }
        } catch (Exception ex) {
            result.status = 'Error';
            result.errorMessage = ex.getMessage();
        }

        return result;
           
    }

    public class StatusResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String downloadUrl;
        @AuraEnabled public String errorMessage;
    }

}