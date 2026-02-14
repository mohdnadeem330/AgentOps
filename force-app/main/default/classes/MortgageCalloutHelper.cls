/*
* Purpose: To prepare the data for sending data to ERP System
* SR Type: Mortgage Registration, Mortgage Discharge
*/
public with sharing class MortgageCalloutHelper {
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
        List<Object> mortgageReqList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            Map<String, Object> mortgageReqMap = new Map<String, Object>();            
            
            mortgageReqMap.put('bankRepresentativeEmail', serviceRequest.BankRepresentativeEmail__c);
            mortgageReqMap.put('bankRepresentative', serviceRequest.BankRepresentative__c);
            mortgageReqMap.put('banksEmail', serviceRequest.BanksEmail__c);
            mortgageReqMap.put('mortgageApplicationNo', serviceRequest.MortgageApplicationNumber__c);
            mortgageReqMap.put('endDate', serviceRequest.EndDate__c);
            mortgageReqMap.put('startDate', serviceRequest.StartDate__c);
            mortgageReqMap.put('financedAmount', String.valueOf(serviceRequest.MortgageAmount__c));
            mortgageReqMap.put('partyId', serviceRequest.HexaBPM__Customer__r.ERPID__c);
            mortgageReqMap.put('financerName', serviceRequest.MortgageBank__r.Name);
            if(serviceRequest.SRType__c == Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE)
                mortgageReqMap.put('mortgageType', Constants.MORTGAGE_DISCHARGE_INTEGRATION);
            else if(serviceRequest.SRType__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE)
                mortgageReqMap.put('mortgageType', Constants.MORTGAGE_REGISTRATION_INTEGRATION);
            mortgageReqMap.put('sfSalesOrderId', serviceRequest.SalesOrder__c);
            mortgageReqMap.put('sfServiceReqId', serviceRequest.Id);
            mortgageReqList.add(mortgageReqMap);
        }
        finalMap.put('mortgageReq', mortgageReqList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!mortgageReqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.MORTGAGE_INTEGRATION, srIds));
        }
    }

    public static void processMortgageResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
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
            System.debug('responseRecord.status '+responseRecord.status);
            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                srRecord.ERPID__c = responseRecord.erpId;
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
        System.debug('srSuccessList '+srSuccessList);
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