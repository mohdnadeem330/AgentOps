@RestResource(urlMapping='/uploadTradeLicenceDocument')  
global without sharing class BP_UploadTradeLicenceDoc extends BP_BaseRestResource {

    @HttpPatch
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
  
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            if (!String.isEmpty(requestBody)) {
                BP_UploadTradeLicenceDoc service = new BP_UploadTradeLicenceDoc();
                ApiResponse response = service.processRequest(params, requestBody);

                handler.response.data = response.data;
                handler.response.success = response.success;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
            }
        
            handler.finalize();
        
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            String fileName = (String) requestBodyData.get('fileName');
            String fileDataBase64 = (String) requestBodyData.get('fileData');
            String fileExtension = (String) requestBodyData.get('fileExtension');
            Date tradeLicenceExpiryDate = Date.valueOf((String) requestBodyData.get('tradeLicenceExpiryDate'));
            id accountId =(id)requestBodyData.get('accountId');
           
            if (accountId == null) {
                return new ApiResponse(false, 400, 'Unable to determine associated Account', null);
            }

            if (checkExistingApprovalProcess(accountId)) {
                return new ApiResponse(false, 400, 'A Trade Licence document submission is already in progress', 
                    new Map<String, Object>{'message' => 'Existing approval process detected'});
            }

            Blob fileData = EncodingUtil.base64Decode(fileDataBase64);
            String contentDocumentId = insertAndLinkTradeLicenceDocument(accountId, fileName, fileData, fileExtension);
            
            submitTradeLicenceForApproval(accountId, tradeLicenceExpiryDate);
            
            return new ApiResponse(true, 200, 'Trade Licence document uploaded and submitted for approval', 
                new Map<String, Object>{
                    'message' => 'Trade Licence document submitted successfully',
                    'documentId' => contentDocumentId
                });

        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to process the request: ' + e.getMessage(), null);
        }
    }

  private static Boolean checkExistingApprovalProcess(Id accountId) {
    Id processDefinitionId;
    
    try {
        processDefinitionId = [
            SELECT Id FROM ProcessDefinition 
            WHERE Name = 'Broker Documents' LIMIT 1
        ].Id;
    } catch (Exception e) {
        return false; 
    }

    return ![
        SELECT Id FROM ProcessInstance 
        WHERE TargetObjectId = :accountId AND ProcessDefinitionId = :processDefinitionId 
        AND Status IN ('Pending', 'Started')
    ].isEmpty();
}


    public static String insertAndLinkTradeLicenceDocument(Id accountId, String fileName, Blob fileData, String fileExtension) {
        try {
            HexaBPM__SR_Doc__c relatedDocument = [
                SELECT Id FROM HexaBPM__SR_Doc__c  
                WHERE HexaBPM__Customer__c = :accountId 
                AND HexaBPM__Document_Name__c = 'Trade/Commercial License'
                LIMIT 1
            ];
            Network network =  [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        
            ContentVersion newContentVersion = new ContentVersion();
            newContentVersion.Title = fileName;
            newContentVersion.PathOnClient = fileName + '.' + fileExtension;
            newContentVersion.VersionData = fileData;
            newContentVersion.NetworkId = network.Id;
            insert newContentVersion;

            String contentDocumentId = [
                SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newContentVersion.Id LIMIT 1
            ].ContentDocumentId;

            ContentDocumentLink documentLink = new ContentDocumentLink();
            documentLink.ContentDocumentId = contentDocumentId;
            documentLink.LinkedEntityId = relatedDocument.Id;
            documentLink.ShareType = 'V';
            documentLink.Visibility = 'AllUsers';
            insert documentLink;

            return contentDocumentId;

        } catch (Exception e) {
            throw new AuraHandledException('Error inserting and linking Trade Licence document: ' + e.getMessage());
        }
    }

    Public static void submitTradeLicenceForApproval(Id accountId, Date tradeLicenceExpiryDate) {
        try {
            Account accountUpdate = new Account();
            accountUpdate.Id = accountId;
            accountUpdate.ProposedExpiryDate__c = tradeLicenceExpiryDate;
            update accountUpdate;

            Account adminAccount = [SELECT Id, OwnerId FROM Account WHERE Id = :accountId LIMIT 1];
            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Trade Licence document uploaded for review.');
            req.setObjectId(adminAccount.Id);
            req.setSubmitterId(adminAccount.OwnerId);
            req.setProcessDefinitionNameOrId('BrokerDocuments');
            
            Approval.process(req);

        } catch (Exception ex) {
            throw new AuraHandledException('Error submitting Trade Licence for approval: ' + ex.getMessage());
        }
    }

    private static Map<String, Object> parseRequestBody(String requestBody) {
        return (Map<String, Object>) JSON.deserializeUntyped(requestBody);
    }

   
}