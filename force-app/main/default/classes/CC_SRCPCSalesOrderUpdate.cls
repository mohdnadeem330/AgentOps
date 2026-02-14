/*
* Purpose: To change the Sales Order CPC Allocated.
* SR Type: CPC
*/
global without sharing class CC_SRCPCSalesOrderUpdate implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        
        SalesOrder__c salesOrder =  new SalesOrder__c();
        salesOrder.Id = serviceRequest.SalesOrder__c;
        salesOrder.CPCAllocated__c = false;
        update salesOrder;

        // PropertyTransferCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
        return Constants.SUCCESS_RETURN_MESSAGE;
    }
}