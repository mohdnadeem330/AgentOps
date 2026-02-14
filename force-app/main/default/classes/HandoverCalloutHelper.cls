public with sharing class HandoverCalloutHelper {

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
        List<Object> handoverList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            Map<String, Object> tempObj = new Map<String, Object>();
            //CHODate__c,RFODate__c,TitleDeedCompletionDate__c,HexaBPM__Closed_Date_Time__c
            //CHO,RFO,NOC,HO
            string integrationType = '';
            if(serviceRequest.HandoverDetail__r.HandoverCompletionDate__c!=null){
                integrationType = 'HO';
            }else if(serviceRequest.HandoverDetail__r.TitleDeedCompletionDate__c !=null ){
                integrationType = 'NOC';
            }else if(serviceRequest.HandoverDetail__r.RFODate__c !=null){
                integrationType = 'RFO';
            }else if(serviceRequest.HandoverDetail__r.FinanceBilling__c !=null){
                integrationType = 'CHO';
            }
            if(integrationType==''){
                continue;
            }
            System.debug('----->'+integrationType);
            //Rebate value
            decimal rebateTotal = (serviceRequest.SalesOrder__r.AdditionalRebate__c!=null? serviceRequest.SalesOrder__r.AdditionalRebate__c : 0) +(serviceRequest.SalesOrder__r.AdditionalRebate2__c!=null? serviceRequest.SalesOrder__r.AdditionalRebate2__c : 0) ;
            if(serviceRequest.SalesOrder__r.RebateForfeitureLetterSent__c == false ){
                rebateTotal += (serviceRequest.SalesOrder__r.LastInstallmentRebate__c!=null && serviceRequest.SalesOrder__r.LastInstallmentRebate__c!= 0) ? serviceRequest.SalesOrder__r.LastInstallmentRebate__c : (serviceRequest.SalesOrder__r.OtherRebateAmount__c!=null? serviceRequest.SalesOrder__r.OtherRebateAmount__c : 0);
            } 

            tempObj.put('sfServiceReqId', serviceRequest.Id);
            tempObj.put('sfSalesOrderId', serviceRequest.SalesOrder__c);
            tempObj.put('type', integrationType);
            tempObj.put('raSfId',serviceRequest.HandoverDetail__r.RebateLine__c);
            tempObj.put('rebateAmount', String.Valueof(rebateTotal));
            tempObj.put('choDate', serviceRequest.HandoverDetail__r.FinanceBilling__c);
            tempObj.put('installmentBilling',  integrationType=='CHO'?'Y':'N');
            tempObj.put('nocDate', serviceRequest.HandoverDetail__r.TitleDeedCompletionDate__c);
            tempObj.put('rfoDate', serviceRequest.HandoverDetail__r.RFODate__c);
            tempObj.put('handoverCompletionDate', serviceRequest.HandoverDetail__r.HandoverCompletionDate__c);
            handoverList.add(tempObj);
        }
        finalMap.put('handoverRq', handoverList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!handoverList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.HANDOVER_INTEGRATION, srIds));
        }
    }

    public static void processHandoverResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
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
                loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord.sfServiceReqId));
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