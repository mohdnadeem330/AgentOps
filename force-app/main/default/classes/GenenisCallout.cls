public class GenenisCallout {
    @InvocableMethod(label='Get Audio From Genenis' description='Sendrequest')
    public static List<String> Sendrequest(List<ID> TaskVoice) { 
       
        
        MuleSoftSetting__mdt erpSOAAPIConfiguration = Utilities.getMuleSoftDetails('GenesisAudio');
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = erpSOAAPIConfiguration.SandboxURL__c;
        
         if(!org.IsSandbox){
                endPointURL = erpSOAAPIConfiguration.ProductionURL__c; 
            }
        
        List<Task> tasks = [SELECT Id, softphone_it__IWS_Interaction_ID__c FROM Task WHERE Id IN :TaskVoice];
        List<String> mediaUriList = new List<String>();
        
        for (Task task : tasks) {
            if(task.softphone_it__IWS_Interaction_ID__c !=null) {
                try{
                String idValue = task.softphone_it__IWS_Interaction_ID__c;
                String updatedURL = endPointURL.replace('ID', idValue); 
                //System.debug('updatedURL' + updatedURL);
                
                HttpRequest request = new HttpRequest();
                request.setEndpoint(updatedURL);
                request.setMethod('GET');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('client_id', erpSOAAPIConfiguration.APIId__c);
                request.setHeader('client_secret', erpSOAAPIConfiguration.APIKey__c);
                
                Http http = new Http(); 
                HttpResponse response = http.send(request);
               // system.debug('response.getStatusCode()'+response.getStatusCode());
                if (response.getStatusCode() == 201) {
                    String responseBody = response.getBody();
                    ApiResponse responses = (ApiResponse) JSON.deserialize(responseBody, ApiResponse.class);
                    Boolean found = false;
                    for (Result result : responses.results) {
                        for (String key : result.mediaUris.keySet()) {
                            mediaUriList.add(result.mediaUris.get(key).mediaUri);
                            found = true;
                            break;
                        }
                        if (found) {
                            break;
                        }
                    }                    
                } else {
                    String errorResponse = response.getBody();                    
                }
                     } catch (Exception e) {
                   LoggerService.save(LoggerService.addApexLog(e,'GenenisCallout','GenenisCallout',''));
                }
            }          
            
        }        
        return mediaUriList;
    }
    
    
    public class ApiResponse {
        public List<Result> results;
    }
    
    public class Result {
        public Map<String, MediaUri> mediaUris;
    }
    
    public class MediaUri {
        public String mediaUri;
    }
}