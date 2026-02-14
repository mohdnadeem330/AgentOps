/*
* Purpose: To prepare the data for sending data to ERP System
* SR Type: ADM Fee Refund
*/
public with sharing class ADMFeeRefundCalloutHelper {
    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        prepareDataForCallout(serviceRequestList);
    }

    public static void prepareDataForCallout(List<HexaBPM__Service_Request__c> serviceRequestList){
        List<Id> srIds = new List<Id>();
        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            srIds.add(serviceRequest.Id);
        }
        
        SalesOrderOtherCharges__c soCharges = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c =: serviceRequestList[0].SalesOrder__c AND SubType__c =: Constants.OTHER_CHARGES_Charge_TYPE_ADM_Fee_REFUND Order By CreatedDate Desc Limit 1];

        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> admFeeRefReqList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            Map<String, Object> admFeeRefReqMap = new Map<String, Object>();            
            
            admFeeRefReqMap.put('soOtherChargeSfId', soCharges.Id);
            admFeeRefReqMap.put('admWaivedAmount', String.valueOf( serviceRequest.ADMWaivedAmount__c));
            admFeeRefReqMap.put('admFeeAmount', String.valueOf( serviceRequest.ADMFeeAmount__c ));
            admFeeRefReqMap.put('admRefundAmount', String.valueOf( serviceRequest.ADMRefundAmount__c ));
            admFeeRefReqMap.put('unitSfId', serviceRequest.Unit__c);
            
            admFeeRefReqMap.put('sfSalesOrderId', serviceRequest.SalesOrder__c);
            admFeeRefReqMap.put('sfServiceReqId', serviceRequest.Id);
            admFeeRefReqList.add(admFeeRefReqMap);
        }
        finalMap.put('admRefRq', admFeeRefReqList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!admFeeRefReqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.ADM_FEE_REFUND_INTEGRATION, srIds));
        }
    }

    public static void processADMFeeRefundResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
        List<String> srIds = new List<String>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            if (responseRecord.status == Constants.MULESOFT_FAILED){
                srIds.add(responseRecord.sfServiceReqId);
            }
        }
        Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, RetryCount__c FROM HexaBPM__Service_Request__c WHERE Id IN :srIds]);

        List<HexaBPM__Service_Request__c> srSuccessList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srFailedList = new List<HexaBPM__Service_Request__c>();
        List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
        List<Logger__c> loggerList = new List<Logger__c>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
            SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
            System.debug('responseRecord.status '+responseRecord.status);
            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                srRecord.ERPID__c = responseRecord.erpId;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = 0;
                srRecord.ErrorReason__c = '';
                if(responseRecord.soOtherChargeSfId != null){
                    otherCharge.Id = responseRecord.soOtherChargeSfId;
                    otherCharge.ERPID__c = responseRecord.erpId;
                    otherCharge.ReceivableAccount__c = responseRecord.recAcct;
                    otherCharge.RevenueAccount__c = responseRecord.expAcct;
                    otherCharge.TaxAccount__c = responseRecord.taxAcct;
                    otherChargeList.add(otherCharge);
                }                
                srSuccessList.add(srRecord);
            } else if (responseRecord.status == Constants.MULESOFT_FAILED) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = srMap.get(responseRecord.sfServiceReqId).RetryCount__c == null ? 1 : srMap.get(responseRecord.sfServiceReqId).RetryCount__c + 1;
                srRecord.ErrorReason__c = responseRecord.errorMsg;
                srFailedList.add(srRecord);
                loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord.sfServiceReqId));
            }
        }
        System.debug('srSuccessList '+srSuccessList);

      /*  List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
        for (MuleSOResponeWrapper.SOResponse responseRecord : results.othChgRes) {
            SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
            otherCharge.Id = responseRecord.srSFId;
            otherCharge.ERPID__c = responseRecord.erpId;
            otherCharge.ReceivableAccount__c = responseRecord.recAcct;
            otherCharge.RevenueAccount__c = responseRecord.expAcct;
            otherCharge.TaxAccount__c = responseRecord.taxAcct;
            otherChargeList.add(otherCharge);
        }}*/

        if (!otherChargeList.isEmpty()) {
            update otherChargeList;
        }
        

        if (!srSuccessList.isEmpty()) {
            update srSuccessList;
        }
        
        System.debug('srFailedList '+srFailedList);
        if (!srFailedList.isEmpty()) {
            update srFailedList;
            if (!loggerList.isEmpty()) {
                insert loggerList;
            }
        }
    }
}