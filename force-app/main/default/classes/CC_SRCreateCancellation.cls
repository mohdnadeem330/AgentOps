global without sharing class CC_SRCreateCancellation implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        List<HexaBPM__Service_Request__c> cancellationSRList = SRUtility.createNewCancellationSRsFromSR(serviceRequest, Constants.CANCELLATION_RT);
        return Constants.SUCCESS_RETURN_MESSAGE;
    }
}