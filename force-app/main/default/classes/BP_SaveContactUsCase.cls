@RestResource(urlMapping = '/saveContactUsCase')
global without sharing class BP_SaveContactUsCase extends BP_BaseRestResource {
    
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        String caseId = null;
        
        try {
            String requestBody = RestContext.request.requestBody.toString();
            BP_SaveContactUsCase service = new BP_SaveContactUsCase();
            ApiResponse response = service.processRequest(RestContext.request.params, requestBody);
            
            handler.response.data = response.data;
            handler.response.success = response.success;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
            
        } catch (Exception ex) {
            LoggerService.save(LoggerService.addApexLog(ex, 'Broker2.0 API', 'BP_SaveContactUsCase', caseId));
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = 'Error: ' + ex.getMessage();
        }
        
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        String caseId = null;
        
        try {
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            String phone = (String) requestData.get('phone');
            String email = (String) requestData.get('email');
            String agentName = (String) requestData.get('agentName');
            String agencyName = (String) requestData.get('agencyName'); 
            String query = (String) requestData.get('query');
            String country = (String) requestData.get('country');
            String brokerState = (String) requestData.get('state'); 
            
            
            if (String.isBlank(phone) || String.isBlank(email) || 
                String.isBlank(agentName) || String.isBlank(query) || 
                String.isBlank(country)) {
                    
                    return new ApiResponse(false, 400, 'Fields phone, email, agencyName, query, and country are mandatory.', null);
                }
            if (country == 'United Arab Emirates') {
                if (String.isBlank(brokerState)) {
                    return new ApiResponse(false, 400, 'Broker State is required when country is United Arab Emirates.', null);
                }
            } else {
                brokerState = null; 
            }
            
            RecordType rt = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Case' AND DeveloperName = 'Broker_Enquiries' 
                LIMIT 1
            ];
            
            List<Group> brokerQueue = [
                SELECT Id, Name 
                FROM Group 
                WHERE Type = 'Queue' AND Name = 'Broker Enquiry Queue' 
                LIMIT 1
            ];
            
            Case newCase = new Case();
            newCase.RecordTypeId = rt.Id;
            newCase.SuppliedPhone = phone;
            newCase.SuppliedEmail = email;
            newCase.ECSS_CompanyName__c = agencyName;
            newCase.Customer_Name__c = agentName;
            newCase.Description = query;
            newCase.Subject = 'Contact Us Submission - ' + agencyName;
            newCase.Category__c = 'Broker Enquiry';
            newCase.Origin = 'Broker Portal';
            newCase.Status = 'New';
            newCase.OwnerId = brokerQueue[0].Id;
            newCase.PermanentCountry__c = country;
            newCase.PermanentState__c = brokerState; 
            
            insert newCase;
            caseId = newCase.Id;
            
            Map<String, Object> responseData = new Map<String, Object>{
                'caseId' => caseId
                    };
                        
                        return new ApiResponse(true, 201, 'Case created successfully', responseData);
            
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e, 'Broker2.0 API', 'BP_SaveContactUsCase', caseId));
            return new ApiResponse(false, 500, 'Failed to create case: ' + e.getMessage(), null);
        }
    }
    
    
}