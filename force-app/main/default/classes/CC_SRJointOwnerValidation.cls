/*
* Purpose: To validate the Joint Owner is Added in SR Amendments.
* SR Type: Addition Joint Owner, Deletion Joint Owner and Ownership Change
*/
global without sharing class CC_SRJointOwnerValidation implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];

        if (serviceRequest.Partners__r.isEmpty()) {
            if (serviceRequest.SRType__c == Constants.ADDITION_JOINT_OWNER_RT) {
                return Utilities.getSystemMessages(Constants.ADDITION_JOINT_OWNER_VALIDATION).Message__c;
            } else if (serviceRequest.SRType__c == Constants.DELETION_JOINT_OWNER_RT) {
                return Utilities.getSystemMessages(Constants.DELETION_JOINT_OWNER_VALIDATION).Message__c;
            } else {
                return Utilities.getSystemMessages(Constants.OWNERSHIP_CHANGE_VALIDATION).Message__c;
            }
        }
        return Constants.SUCCESS_RETURN_MESSAGE;
    }
}