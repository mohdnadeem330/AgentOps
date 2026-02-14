/*
* Purpose: Create Internal Mortgage Registration from Current SR.
* SR Type: Internal Mortgage Registration
*/
global without sharing class CC_SRCreateMortgageRegistration implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        HexaBPM__Service_Request__c handoverSR = SRUtility.createNewSRFromSR(serviceRequest, Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        return Constants.SUCCESS_RETURN_MESSAGE;
    }
}