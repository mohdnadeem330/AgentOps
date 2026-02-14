/**
Class       : CalloutToBlobstorage
Author      : Smaartt
Description : this api to get SAS URL from blobstorage
TestClass   : CalloutToBlobstorageTest,MockHttpResponseGen
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              24/07/24           Initial Version 
****************************************************************************************************************/
public class CalloutToBlobstorage {
    @auraEnabled
    public data_Cls data {get;set;}
    @auraEnabled
    public string status {get;set;}
    
    public class data_cls{
        @auraEnabled
        public string fileSasUrl {get;set;}
    }      
    
    @auraEnabled
    public static string getSASUrl(String url, String type){     
        APISetting__mdt  blobAPI = Utilities.getServiceDetails('BlobGetSasUrl');
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = blobAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = blobAPI.ProductionURL__c ; 
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();        
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('CLIENT_ID', blobAPI.APIKey__c);
        request.setHeader('CLIENT_SECRET', blobAPI.SecretKey__c);
        request.setTimeout(120000);
        request.setEndpoint(endPointURL);
        request.setMethod(blobAPI.Method__c);   
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        //Added by Harsh@Aldar 14/10/2024 - Separate DLP and LFU
        //type = LFU for DM and DLP for DLP Live Aldar
        gen.writeStringField('type', type);
        gen.writeStringField('blobPath', url);
        gen.writeEndObject();
        request.setBody(gen.getAsString());//'{"type": "LFU","blobPath": "aldar/liveAldar/a1dKH000000Co3AYAS/1721388730882.png"}');        
        HttpResponse response = http.send(request);  
        system.debug(response.getBody());
        if(response.getBody() != null){
            CalloutToBlobstorage bl = new CalloutToBlobstorage();
            if(!test.isRunningTest())
            bl = (CalloutToBlobstorage) System.JSON.deserialize(response.getbody(), CalloutToBlobstorage.class); 
            if(bl != null){                 
                if(bl.status == 'success'){
                    system.debug(bl.data.fileSasUrl);
                    return bl.data.fileSasUrl;
                }           
            }else{
                throw new AuraHandledException('Not able to retrive the response.'+response.getbody());
            } 
        }
        
        return 'error';        
    }
    @AuraEnabled
    public static List<Map<String, String>> getBulkSASUrls(List<String> urls) {
        List<Map<String, String>> results = new List<Map<String, String>>();
        String filetype = 'LFU';
        
        for (String url : urls) {
            try {
                results.add(new Map<String, String>{
                    'originalUrl' => url,
                        'signedUrl' => getSASUrl(url, filetype)
                        });
            } catch (Exception ex) {
                System.debug('Error getting signed URL for: ' + url + ' - ' + ex.getMessage());
                results.add(new Map<String, String>{
                    'originalUrl' => url,
                        'signedUrl' => null
                        });
            }
        }
        
        return results;
    }
}