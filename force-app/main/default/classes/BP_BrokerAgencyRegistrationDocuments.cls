@RestResource (urlMapping = '/uploadBrokerAgencyDocuments')
global with sharing class BP_BrokerAgencyRegistrationDocuments extends BP_BaseRestResource {

    @HttpPost
    global static void start(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            System.debug('requestBody:: '+RestContext.request.requestBody);
            String requestBody = RestContext.request.requestBody.toString();   
            
            if(!String.isEmpty(requestBody)){   
                BP_BrokerAgencyRegistrationDocuments service = new BP_BrokerAgencyRegistrationDocuments();
                ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = response.success;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
                
            }else {
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        } catch(Exception ex){ handler.response.success = false; handler.response.statusCode = 500; handler.response.message = ex.getMessage(); } 
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            AgencyRegistrationDocumentWrapper documentWrapper = (AgencyRegistrationDocumentWrapper) System.JSON.deserialize(requestBody, AgencyRegistrationDocumentWrapper.class);
            
            if(String.isBlank(documentWrapper.serviceRequestId)){
                return new ApiResponse(false, 400,  'Broker Agency Service Request Id is Blank', null);
            }

            HexaBPM__Service_Request__c createdServiceRequest = [SELECT Id FROM HexaBPM__Service_Request__c WHERE Id = :documentWrapper.serviceRequestId];

            if(createdServiceRequest == null || String.isBlank(createdServiceRequest.Id)){
                return new ApiResponse(false, 400,  'Broker Agency Service Request Id is Invalid', null);
            }

            if(documentWrapper.srDocumentBase64 == null || documentWrapper.srDocumentBase64.isEmpty()){
                return new ApiResponse(false, 400,  'Broker Agency Service Request document is/are Blank', null);
            }

            Map<Id,HexaBPM__SR_Doc__c> executedResults = execute(documentWrapper);
            if(executedResults == null || executedResults.isEmpty()){
                return new ApiResponse(false, 400, 'No Document Placeholder found for this document type', null);
            }
            return new ApiResponse(true, 200,  'Broker Agency Documents Uploaded Successfully', executedResults);
        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Broker Agency Documents processing failed: ' + e.getMessage(), null);
        }
    }
    
    public static Map<Id,HexaBPM__SR_Doc__c> execute(AgencyRegistrationDocumentWrapper documentWrapper){
        Map<Id,HexaBPM__SR_Doc__c> mapSRDocs;
        if(documentWrapper != null && documentWrapper.srDocumentBase64 != null && !documentWrapper.srDocumentBase64.isEmpty()){
            mapSRDocs = new Map<Id,HexaBPM__SR_Doc__c>([SELECT Id,Name,DocumentMasterCode__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :documentWrapper.serviceRequestId
                                                    AND DocumentMasterCode__c IN: documentWrapper.srDocumentBase64.keySet()]);
            
            List<Map<String,Object>> filesToUpload = new List<Map<String, Object>>();
            
            for(HexaBPM__SR_Doc__c eachSRDocu : mapSRDocs.values()){
                if(documentWrapper.srDocumentBase64.get(eachSRDocu.DocumentMasterCode__c) != null && documentWrapper.srDocumentBase64.get(eachSRDocu.DocumentMasterCode__c) != '')
                filesToUpload.add(new Map<String, Object>{'base64'=> documentWrapper.srDocumentBase64.get(eachSRDocu.DocumentMasterCode__c), 'fileName'=> eachSRDocu.Name + '.pdf', 'Id'=> eachSRDocu.Id});
            }
            if(!filesToUpload.isEmpty()){ 
                BrokerAgencyRegistrationController.uploadFiles(filesToUpload); 
            }
        }

        return mapSRDocs;
    } 

    public class AgencyRegistrationDocumentWrapper {
        public String serviceRequestId { get; set; } 
        public Map<String,String> srDocumentBase64 { set; get; }
    }
}