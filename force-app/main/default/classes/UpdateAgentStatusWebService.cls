@RestResource (urlMapping = '/update/status')
global with sharing class UpdateAgentStatusWebService {
    @HTTPPost
    global static void doPost(String status){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            updateStatus(status);
            handler.response.data = Constants.SUCCESS_MESSAGE;
            handler.response.success = true;
            handler.finalize(); 
        } catch(Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }

    public static void updateStatus(String status) {
        User userDetail = Utilities.getLoggedInUserDetail();

        Set<Id> userSet = new Set<Id>();
        userSet.add(userDetail.Id);

        if (status == Constants.STATUS_AVAILABLE) {
            RoundRobinAssignmentUtility.setAgentAvailable(userSet);
        } else if (status == Constants.STATUS_OFFLINE) {
            RoundRobinAssignmentUtility.setAgentOffline(userSet);
        }
    }
}