/*
* Purpose: Creating sales order other chanrges for ADM Refund.
* SR Type: ADM Fe Refund
*/
global without sharing class CC_SRADMFeeRefundController implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];

        List<SalesOrderOtherCharges__c> soOtherChargeList = new List<SalesOrderOtherCharges__c>();
        
        /*
        * Logic: Create a Sales Order Other Charges as a Debit Memo for ADM Refund Amount.
        */
        if (serviceRequest.ADMRefundAmount__c != null && serviceRequest.ADMRefundAmount__c > 0) {
            soOtherChargeList.add(SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO, Constants.OTHER_CHARGES_Charge_TYPE_ADM_Fee_REFUND, serviceRequest.ADMRefundAmount__c, serviceRequest));
        }

        if (!soOtherChargeList.isEmpty()) {
            insert soOtherChargeList;
        }

        ADMFeeRefundCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});

        return Constants.SUCCESS_RETURN_MESSAGE;

    }
}