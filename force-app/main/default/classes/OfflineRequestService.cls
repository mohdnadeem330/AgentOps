@RestResource (urlMapping = '/getOfflinerequest')
global class OfflineRequestService {

    @HTTPPost
    global static void doPost(){
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getOfflineRequests();
            handler.response.success = true;
            handler.finalize(); 
        }
        catch(Exception ex){
            handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;   handler.finalize(ex);
        }
    }
    
    public static offlineRequestWrapper getOfflineRequests() {
        offlineRequestWrapper finalMap = new offlineRequestWrapper();
        finalMap.onlineOfflineRequests = OfflineRequestController.getOfflineRequest();
        finalMap.checkApprovedRequest = OfflineRequestController.checkApprovedRequest();
        List<OfflineRequest__c> lstOfflineReq = ( List<OfflineRequest__c>)finalMap.checkApprovedRequest.get('approvedOfflineReq');
        if(finalMap.checkApprovedRequest.get('workingHours') == true && lstOfflineReq.size() == 0 ){
            finalMap.isOnline = true;
        }
        return finalMap;
    }
    global class offlineRequestWrapper {
       
        public List<object> onlineOfflineRequests {get;set;}   
        public Map<String, Object> checkApprovedRequest{get; set;}
        public boolean isOnline = false;
     }

}