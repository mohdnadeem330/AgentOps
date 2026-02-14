public without Sharing class  ProvisOutstandingDuesController {
    @AuraEnabled(continuation=true cacheable=true)
    public static Object getOutstandingFromERP(String recordId) {
        try { 
            Continuation con = new Continuation(120);
            con.continuationMethod = 'handleERPResponse';
            List<HexaBPM__Service_Request__c> SR = [SELECT Id, HexaBPM__Customer__r.ERPID__c, Unit__r.Name  FROM HexaBPM__Service_Request__c WHERE Id = :recordId  AND srtype__c = 'Property Transfer NOC' LIMIT 1];
            if (!SR.isEmpty() && SR[0].HexaBPM__Customer__r.ERPID__c != null && SR[0].Unit__r.Name != null) {
                
              APISetting__mdt ERPOutstandingCalloutDetails = [SELECT APIKey__c, SecretKey__c, APIId__c, Headers__c, SandboxURL__c, ProductionURL__c   FROM APISetting__mdt  WHERE MasterLabel = 'ERPOutstanding' ];
                Organization org = Utilities.getOrganizationDetails();
                String endPointURL = org.IsSandbox ? ERPOutstandingCalloutDetails.SandboxURL__c : ERPOutstandingCalloutDetails.ProductionURL__c;
                
                HttpRequest request = new HttpRequest();
                request.setEndpoint(endPointURL);
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('target', System.label.Outstand_SC_Target);
                if (!org.IsSandbox) {
                    request.setHeader('client_secret', ERPOutstandingCalloutDetails.SecretKey__c);
                    request.setHeader('client_id', ERPOutstandingCalloutDetails.APIKey__c);
                } else {
                    request.setHeader('client_secret', 'test');
                    request.setHeader('client_id', 'test');
                }            
                Map<String, Object> requestBody = new Map<String, Object>{
                    'oracle_party_id' => SR[0].HexaBPM__Customer__r.ERPID__c, 
                        'unit_key' => '[\'' + SR[0].Unit__r.Name + '\']'
                        };
                system.debug('requestBodyActual::'+JSON.serialize(requestBody));
                request.setBody(JSON.serialize(requestBody));
                request.setTimeout(120000);
                
                String requestId = con.addHttpRequest(request);
                System.debug('Request ID::' + requestId);
                
            }
            
            return con;
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
            return 'Error: Exception occurred while processing. '+ ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static Object handleERPResponse(List<String> labels, Object state) { 
        try {
				system.debug('labels::'+Continuation.getResponse(labels[0]));
            HttpResponse response = Continuation.getResponse(labels[0]);
            if (response != null) {
                System.debug('Response Body::' + response.getBody());
                if (response.getStatusCode() == 200) {
                    return response.getBody();  
                } else {
                    return 'Error fetching outstanding dues: Status Code ' + response.getStatusCode();
                }
            } else {
                return 'Error: No response received from ERP.';
            }
        } catch (Exception ex) {
            System.debug('Exception in handleERPResponse: ' + ex.getMessage());
            return 'Error: Exception occurred while handling response. ' + ex.getMessage();
        }
    }
}