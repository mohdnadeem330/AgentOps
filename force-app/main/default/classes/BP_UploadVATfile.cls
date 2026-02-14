@RestResource(urlMapping='/uploadVATfilesinfo')
global without sharing class BP_UploadVATfile extends BP_BaseRestResource {
    
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            System.debug('Params: ' + params);
            
            String requestBody = RestContext.request.requestBody.toString();
            System.debug('Request Body: ' + requestBody);
            
            if (!String.isEmpty(requestBody)) {
                BP_UploadVATfile service = new BP_UploadVATfile();
                ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = response.success;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
                System.debug('Response: ' + response);
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
                System.debug('Invalid Request Body');
            }
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
            System.debug('Error: ' + ex.getMessage());
        } finally {
            handler.finalize();
        }
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        System.debug('Entering processRequest with params: ' + params);
        System.debug('Request Body: ' + requestBody);
        
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            System.debug('Parsed Request Body Data: ' + requestBodyData);
            
            Id accountId = (Id) requestBodyData.get('accountId');
            System.debug('Extracted accountId: ' + accountId);
            
            String fileName = (String) requestBodyData.get('fileName');
            String fileDataBase64 = (String) requestBodyData.get('fileData');
            String fileExtension = (String) requestBodyData.get('fileExtension');
            
            Blob fileData = EncodingUtil.base64Decode(fileDataBase64);
            System.debug('Decoded File Data Size: ' + fileData.size());
            
            insertAndLinkVatDocument(accountId, fileName, fileData, fileExtension);
            System.debug('Document inserted successfully');
            
            String proposedStartDateStr = (String) requestBodyData.get('proposedStartDate');
            String proposedExpiryDateStr = (String) requestBodyData.get('proposedExpiryDate');
            System.debug('Proposed Dates: Start - ' + proposedStartDateStr + ', Expiry - ' + proposedExpiryDateStr);
            
            Date proposedStartDate, proposedExpiryDate;
            if (!String.isEmpty(proposedStartDateStr)) {
                proposedStartDate = Date.valueOf(proposedStartDateStr);
            }
            if (!String.isEmpty(proposedExpiryDateStr)) {
                proposedExpiryDate = Date.valueOf(proposedExpiryDateStr);
            }
            
            String proposedUAEVATRegistrationNumberValue = (String) requestBodyData.get('proposedUAEVATRegistrationNumberValue');
            System.debug('Proposed UAE VAT Registration Number: ' + proposedUAEVATRegistrationNumberValue);
            
            UserProfileController.updateProposedExpiryDate(accountId, proposedExpiryDate, proposedUAEVATRegistrationNumberValue, proposedStartDate);
            System.debug('User profile updated successfully');
            
            return new ApiResponse(true, 200, 'VAT document uploaded and Submitted for approval', new Map<String, Object>{'message' => 'Document uploaded successfully'});
            
        } catch (Exception e) {
            System.debug('Error in processRequest: ' + e.getMessage());
            return new ApiResponse(false, 400, 'Failed to process the request: ' + e.getMessage(), null);
        }
        
        
    }
    
    public static void insertAndLinkVatDocument(
        Id accountId,
        String fileName,
        Blob fileData,
        String fileExtension
    ) {
        System.debug('Entering insertAndLinkVatDocument');
        try {
            
            HexaBPM__SR_Doc__c relatedDocument = [
                SELECT Id, Name,HexaBPM__Document_Master__r.Name,HexaBPM__Customer__c
                FROM HexaBPM__SR_Doc__c where HexaBPM__Document_Name__c = 'VAT Registration Certificate' AND HexaBPM__Customer__c = :accountId 
                
                LIMIT 1
            ];
            
            System.debug('Related Document: ' + relatedDocument);
            
            
            
            if (relatedDocument == null) {
                System.debug('No related HexaBPM__SR_Doc__c record found');
                throw new AuraHandledException('No related HexaBPM__SR_Doc__c record found for the account.');
            }
            
            Network network =  [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
                
                ContentVersion newContentVersion = new ContentVersion();
            newContentVersion.Title = fileName;
            newContentVersion.PathOnClient = fileName + '.' + fileExtension;
            newContentVersion.VersionData = fileData;
            newContentVersion.NetworkId = network.Id;
            insert newContentVersion;
            
            System.debug('Inserted ContentVersion: ' + newContentVersion.Id);
            
            
            String contentDocumentId = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :newContentVersion.Id
                LIMIT 1
            ].ContentDocumentId;
            
            System.debug('ContentDocumentId: ' + contentDocumentId);
            
            
            ContentDocumentLink documentLink = new ContentDocumentLink();
            documentLink.ContentDocumentId = contentDocumentId;
            documentLink.LinkedEntityId = relatedDocument.Id;
            documentLink.ShareType = 'V';
            documentLink.Visibility = 'AllUsers';
            insert documentLink;
            
            System.debug('Inserted ContentDocumentLink: ' + documentLink.Id);
        } catch (Exception e) {
            System.debug('Error in insertAndLinkVatDocument: ' + e.getMessage());
            throw new AuraHandledException('Error inserting and linking VAT document: ' + e.getMessage());
        } 
    }
    
    
    private static Map<String, Object> parseRequestBody(String requestBody) {
        return (Map<String, Object>) JSON.deserializeUntyped(requestBody);
    }
}