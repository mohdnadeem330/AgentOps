public with sharing class PaymentExtensionCalloutHelper {

    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        prepareDataForCallout(serviceRequestList);
    }
    
    public static void prepareDataForCallout(List<HexaBPM__Service_Request__c> serviceRequestList){
        List<Id> srIds = new List<Id>();
        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            srIds.add(serviceRequest.Id);
        }
        
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> pmtExtReqList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            Map<String, Object> pmtExtReqMap = new Map<String, Object>();
            
            pmtExtReqMap.put('payTermId', serviceRequest.InstallmentLine__c);
            pmtExtReqMap.put('sfServiceReqId', serviceRequest.Id);
            pmtExtReqMap.put('orgDueDate', serviceRequest.InstallmentDate__c);
            pmtExtReqMap.put('revisedDueDate', serviceRequest.PaymentExtensionDate__c);
            pmtExtReqList.add(pmtExtReqMap);
        }
        finalMap.put('pmtExtnReq', pmtExtReqList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!pmtExtReqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.PAYMENT_EXTN_INTEGRATION, srIds));
        }
    }

    public static void processPaymentExtensionResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
        List<String> srIds = new List<String>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            if (responseRecord.status == Constants.MULESOFT_FAILED){
                srIds.add(responseRecord.sfServiceReqId);
            }
        }
        Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, RetryCount__c FROM HexaBPM__Service_Request__c WHERE Id IN :srIds]);

        List<HexaBPM__Service_Request__c> srSuccessList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srFailedList = new List<HexaBPM__Service_Request__c>();
        List<Logger__c> loggerList = new List<Logger__c>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                srRecord.ERPID__c = responseRecord.erpRequestId;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = 0;
                srRecord.ErrorReason__c = '';
                srSuccessList.add(srRecord);
            } else if (responseRecord.status == Constants.MULESOFT_FAILED) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = srMap.get(responseRecord.sfServiceReqId).RetryCount__c == null ? 1 : srMap.get(responseRecord.sfServiceReqId).RetryCount__c + 1;
                srRecord.ErrorReason__c = responseRecord.errorMsg;
                srFailedList.add(srRecord);
                loggerList.add(LoggerService.addApexServiceCalls('PaymentExtensionCalloutHelper', 'processPaymentExtensionResponse', processName, requestBody, muleRes, responseRecord.sfServiceReqId));
            }
        }
        if (!srSuccessList.isEmpty()) {
            update srSuccessList;
        }
        
        if (!srFailedList.isEmpty()) {
            update srFailedList;
            if (!loggerList.isEmpty()) {
                insert loggerList;
            }
        }
    }
}