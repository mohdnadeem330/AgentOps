/*
* Purpose: To validate the Bookig process is completed or not.
* SR Type: Unit Swap
*/
global without sharing class CC_SRUnitSwapValidation implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];

        List<Opportunity> oppList = [SELECT Id, (SELECT Id FROM OpportunityUnitsOpportunity__r) FROM Opportunity WHERE 
                                        ServiceRequest__c =: serviceRequest.Id];
        if (oppList.isEmpty() || (!oppList.isEmpty() && oppList[0].OpportunityUnitsOpportunity__r.isEmpty())) {
            return Utilities.getSystemMessages('BOOKING_PROCESS_VALIDATION').Message__c;
        }
        return Constants.SUCCESS_RETURN_MESSAGE;
    }
}