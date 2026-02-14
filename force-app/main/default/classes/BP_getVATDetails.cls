@RestResource(urlMapping='/getVATfilesinformation')
global without sharing class BP_getVATDetails extends BP_BaseRestResource {
    
    public static String accountId;
    
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        
        try {
            String requestBody = RestContext.request.requestBody.toString();
            
            if (!String.isEmpty(requestBody)) {
                BP_getVATDetails service = new BP_getVATDetails();
                Map<String, String> params = RestContext.request.params;
                ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
            }
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = 'Error: ' + ex.getMessage();
        }
        
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            
            accountId = (String) requestBodyData.get('accountId');
            if (String.isEmpty(accountId)) {
                return new ApiResponse(false, 400, 'Account ID is required', null);
            }
            
            Map<String, Object> responseData = new Map<String, Object>();
            responseData.put('files', getVatDocuments(accountId));
            
            return new ApiResponse(true, 200, 'Data fetched successfully', responseData);
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to process request: ' + e.getMessage(), null);
        }
    }
    
    public static Map<String, Object> getVatDocuments(String agencyId) {
        Map<String, Object> fileDetails = new Map<String, Object>();
        HexaBPM__SR_Doc__c doc;
        List<HexaBPM__SR_Doc__c> docList = new List<HexaBPM__SR_Doc__c>();
        
        try {
            Account acc = [SELECT Id, Name, UAEVATRegisterNumber__c,VAT_Approval_Status__c, VATRegistrationtype__c,ProposedVATStartDate__c,ProposedVATExpiryDate__c
                           FROM Account 
                           WHERE Id = :agencyId LIMIT 1];
            
            docList = [SELECT Id, Name, HexaBPM__Customer__c, HexaBPM__Document_Master__r.name 
                                      FROM HexaBPM__SR_Doc__c 
                                      WHERE HexaBPM__Customer__c = :agencyId 
                                      AND HexaBPM__Document_Name__c = 'VAT Registration Certificate'
                                      LIMIT 1];
            if(!docList.isEmpty()){
                doc = docList[0];
            }
            
            if (doc != null) {
                ContentDocumentLink cdl = [SELECT ContentDocumentId, LinkedEntityId 
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId = :doc.Id ORDER BY SystemModstamp DESC  
                                           LIMIT 1];
                
                if (cdl != null) {
                    ContentVersion cv = [SELECT Id, Title, FileExtension, ContentSize,LastModifiedDate, CreatedDate, VersionData, ContentDocumentId 
                                         FROM ContentVersion 
                                         WHERE ContentDocumentId = :cdl.ContentDocumentId 
                                         AND IsLatest = true 
                                         ORDER BY LastModifiedDate LIMIT 1];
                    
                    if (cv != null) {
                        fileDetails.put('accountId', acc.Id);
                        fileDetails.put('accountName', acc.Name);
                        fileDetails.put('vatRegistrationType', acc.VATRegistrationtype__c);
                        fileDetails.put('status', acc.VAT_Approval_Status__c);
                        fileDetails.put('vatRegistrationNumber', acc.UAEVATRegisterNumber__c);
                        fileDetails.put('srDocName', doc.Name);
                        fileDetails.put('fileDataBase64', EncodingUtil.base64Encode(cv.VersionData));
                        fileDetails.put('fileName', cv.Title);
                        fileDetails.put('proposedExpiryDate', acc.ProposedVATExpiryDate__c);
                        fileDetails.put('proposedStartDate', acc.ProposedVATStartDate__c);
                        fileDetails.put('fileExtension', cv.FileExtension);
                        fileDetails.put('lastModifiedDate', String.valueOf(cv.LastModifiedDate)); // Include LastModifiedDate
                     }
                }
            }
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e,'Broker2.0 API','BP_getVATDetails','getVatDocuments'));
            //throw new AuraHandledException('Error fetching VAT documents: ' + e.getMessage());
        }
        
        return fileDetails;
    }
}