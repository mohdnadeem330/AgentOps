/*
* Purpose: To validate the aldar staff propert transfer Price Plan and Equity percentage
* SR Type: Property Transfer
*/
global class CC_AldarStaffValidationPTCtrl implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
        return ServiceRequestTriggerHandlerNew.aldarstaffPTValidation(serviceRequest,salesOrder);
     }
}