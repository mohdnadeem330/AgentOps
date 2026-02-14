/*
* Purpose: To prepare the data for sending data to ERP System
* SR Type: Rebate Reinstate
*/
public with sharing class RebateReinstateCalloutHelper {
    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        prepareDataForCallout(serviceRequestList);
    }

    public static void prepareDataForCallout(List<HexaBPM__Service_Request__c> serviceRequestList){
        List<Id> srIds = new List<Id>();
        List<Id> receiptIds = new List<Id>();
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> rebateReqList = new List<Object>();
        Map<Id,HexaBPM__Step__c> serviceRequestStepMap = new Map<Id,HexaBPM__Step__c>();
        Map<Id,ReceiptAcknowledgement__c> receiptMap = new Map<Id,ReceiptAcknowledgement__c>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            srIds.add(serviceRequest.Id);
            if(serviceRequest.ReceiptAcknowledgement__c !=null){
                receiptIds.add(serviceRequest.ReceiptAcknowledgement__c);
            }
        }
        
        if(receiptIds !=null && receiptIds.size()>0){
            receiptMap = new Map<Id, ReceiptAcknowledgement__c>([SELECT Id,SalesOrder__c,Amount__c,Remarks__c,ServiceRequest__c FROM ReceiptAcknowledgement__c WHERE Id IN:receiptIds AND  PaymentType__c = :Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE]);
        }

        List<HexaBPM__Step__c> stepList = [select id, Owner.Name, HexaBPM__Step_Notes__c, HexaBPM__Closed_Date__c,HexaBPM__SR__c from HexaBPM__Step__c where HexaBPM__SR__c IN: srIds and HexaBPM__Summary__c =: Constants.Verification_BY_FINANCE];

        for(HexaBPM__Step__c step : stepList){
            serviceRequestStepMap.put(step.HexaBPM__SR__c,step);
        }

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {

            Map<String, Object> rebateReqMap = new Map<String, Object>();        
            rebateReqMap.put('sfSalesOrderId', serviceRequest.SalesOrder__c);
            rebateReqMap.put('sfServiceReqId', serviceRequest.Id);

            HexaBPM__Step__c srStep = serviceRequestStepMap.get(serviceRequest.Id);
            rebateReqMap.put('releaseBy', String.valueOf(srStep.Owner.Name));
            rebateReqMap.put('releaseComments', srStep.HexaBPM__Step_Notes__c);
            rebateReqMap.put('releaseDate', srStep.HexaBPM__Closed_Date__c);        

            if(serviceRequest.ReceiptAcknowledgement__c !=null && receiptMap.containsKey(serviceRequest.ReceiptAcknowledgement__c)){
                rebateReqMap.put('rebateCMSfId',serviceRequest.ReceiptAcknowledgement__c);
                Decimal rebateAmount = receiptMap.get(serviceRequest.ReceiptAcknowledgement__c).Amount__c ;
                rebateReqMap.put('rebateCMAmt', (rebateAmount !=null ? String.valueOf(rebateAmount) : ''));
                rebateReqMap.put('createRebateFlag','Y');
            }
            else{
                rebateReqMap.put('rebateCMSfId','');
                rebateReqMap.put('rebateCMAmt', '');
                rebateReqMap.put('createRebateFlag','');
            }
            rebateReqList.add(rebateReqMap);
        }
        finalMap.put('rebateReq', rebateReqList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!rebateReqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.REBATE_REINSTATE_INTEGRATION, srIds));
        }
    }

    public static void processRebateResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
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
        List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                srRecord.ERPID__c = responseRecord.erpId;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = 0;
                srRecord.ErrorReason__c = '';
                srSuccessList.add(srRecord);

                if(!String.isBlank(responseRecord.rebateCMSfId)){
                    ReceiptAcknowledgement__c receiptRec = new ReceiptAcknowledgement__c();
                    receiptRec.Id = responseRecord.rebateCMSfId ;
                    receiptRec.ERPID__c = responseRecord.rebateERPId ;
                    receiptRec.SyncStatus__c = Constants.STATUS_SYNCED;
                    receiptRec.SyncTime__c = Datetime.now();
                    receiptRec.ClearedDate__c = Date.valueOf(responseRecord.rebateClearedDate) ;
                    receiptRec.Status__c = responseRecord.rebateStatus ;
                    receiptRec.ReceiptNumber__c = responseRecord.rebateTxnNo ;
                    receiptList.add(receiptRec);
                }
            } else if (responseRecord.status == Constants.MULESOFT_FAILED || responseRecord.status == Constants.MULESOFT_FAILURE) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = srMap.get(responseRecord.sfServiceReqId).RetryCount__c == null ? 1 : srMap.get(responseRecord.sfServiceReqId).RetryCount__c + 1;
                srRecord.ErrorReason__c = responseRecord.errorMsg;
                srFailedList.add(srRecord);
                loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord.sfServiceReqId));
            }
        }
        if (!srSuccessList.isEmpty()) {
            update srSuccessList;
        }

        if (!receiptList.isEmpty()) {
            update receiptList;
        }
        
        if (!srFailedList.isEmpty()) {
            update srFailedList;
            if (!loggerList.isEmpty()) {
                insert loggerList;
            }
        }
    }
}