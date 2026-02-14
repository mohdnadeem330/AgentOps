/**********************************************************************************************************************
* Name               : DefaultAndTerminationCalloutHelper                                                        
* Description        : This class is used by Default and Milestone process to trigger ERP integration
* Usage              : Default and Milestone process 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class DefaultAndTerminationCalloutHelper {
        //Process Milestone installments Callout
        public static void syncPHPPInstallments(set<id> installmentIds){
           
            Map<String, Object> finalMap = new Map<String, Object>();
            List<Object> installmentMap = new List<Object>();
            list<ID> recordIds = new list<ID>();
            for (InstallmentLines__c installmentRecord: [select id,SalesOrder__c,InstallmentNumber__c,OriginalInstallmentDate__c,InstallmentDate__c from InstallmentLines__c where id in :installmentIds and SyncStatus__c != :Constants.STATUS_SYNCED and SalesOrder__r.Status__c in :HandoverUtility.soldSR]) {
                Map<String, Object> reqMap = new Map<String, Object>();
                reqMap.put('intgType', 'PHPP_EXT');
                reqMap.put('sfServiceReqId', '');
                reqMap.put('sfSalesOrderId', installmentRecord.SalesOrder__c);
                reqMap.put('sfInstallmentId', installmentRecord.Id);
                reqMap.put('instNum', String.valueOf(installmentRecord.InstallmentNumber__c));
                reqMap.put('origInstDate', installmentRecord.OriginalInstallmentDate__c);
                reqMap.put('instDate', installmentRecord.InstallmentDate__c);
                reqMap.put('rebateForfLetSent', '');
                reqMap.put('holdFlag', '');
                reqMap.put('holdReasonCode', '');
                recordIds.add(installmentRecord.id);
                installmentMap.add(reqMap);
            }
            finalMap.put('defTermRq', installmentMap);
            String requestBody = JSON.serialize(finalMap);
            requestBody = requestBody.replace(':null', ':""');
            if (!installmentMap.isEmpty()) {
                System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.MILESTONE_INTEGRATION, recordIds));
            }
        }
    //Process Milestone installments Callout
    public static void syncInstallments(set<id> paymentInstallmentIds){
        map<Id,Date> paymentInstallmentMap = new map<Id,Date>();
        for(PaymentInstallments__c tempRec : [select id,InstallmentDate__c from PaymentInstallments__c where id in :paymentInstallmentIds]){
            paymentInstallmentMap.put(tempRec.Id,tempRec.InstallmentDate__c);
        }
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> installmentMap = new List<Object>();
        list<ID> recordIds = new list<ID>();
        for (InstallmentLines__c installmentRecord: [select id,SalesOrder__c,InstallmentNumber__c,OriginalInstallmentDate__c,InstallmentDate__c from InstallmentLines__c where PaymentInstallments__c in : paymentInstallmentIds and InstallmentDate__c in : paymentInstallmentMap.values() and SyncStatus__c != :Constants.STATUS_SYNCED and SalesOrder__r.Status__c in :HandoverUtility.soldSR]) {
            Map<String, Object> reqMap = new Map<String, Object>();
            reqMap.put('intgType', 'SO_INST_REVDATE');
            reqMap.put('sfServiceReqId', '');
            reqMap.put('sfSalesOrderId', installmentRecord.SalesOrder__c);
            reqMap.put('sfInstallmentId', installmentRecord.Id);
            reqMap.put('instNum', String.valueOf(installmentRecord.InstallmentNumber__c));
            reqMap.put('origInstDate', installmentRecord.OriginalInstallmentDate__c);
            reqMap.put('instDate', installmentRecord.InstallmentDate__c);
            reqMap.put('rebateForfLetSent', '');
            reqMap.put('holdFlag', '');
            reqMap.put('holdReasonCode', '');
            recordIds.add(installmentRecord.id);
            installmentMap.add(reqMap);
        }
        finalMap.put('defTermRq', installmentMap);
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        if (!installmentMap.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.MILESTONE_INTEGRATION, recordIds));
        }
    }

    //sync installments with installment callout batch 
    //Process Milestone installments Callout
    public static void syncInstallmentswithBatch(set<id> installmentIds){
        //map<Id,Date> paymentInstallmentMap = new map<Id,Date>();
        /*for(PaymentInstallments__c tempRec : [select id,InstallmentDate__c from PaymentInstallments__c where id in :paymentInstallmentIds]){
            paymentInstallmentMap.put(tempRec.Id,tempRec.InstallmentDate__c);
        }*/
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> installmentMap = new List<Object>();
        list<ID> recordIds = new list<ID>();
        for (InstallmentLines__c installmentRecord: [select id,SalesOrder__c,InstallmentNumber__c,OriginalInstallmentDate__c,InstallmentDate__c from InstallmentLines__c where id in :installmentIds and SyncStatus__c != :Constants.STATUS_SYNCED and SalesOrder__r.Status__c in :HandoverUtility.soldSR]) {
            Map<String, Object> reqMap = new Map<String, Object>();
            reqMap.put('intgType', 'SO_INST_REVDATE');
            reqMap.put('sfServiceReqId', '');
            reqMap.put('sfSalesOrderId', installmentRecord.SalesOrder__c);
            reqMap.put('sfInstallmentId', installmentRecord.Id);
            reqMap.put('instNum', String.valueOf(installmentRecord.InstallmentNumber__c));
            reqMap.put('origInstDate', installmentRecord.OriginalInstallmentDate__c);
            reqMap.put('instDate', installmentRecord.InstallmentDate__c);
            reqMap.put('rebateForfLetSent', '');
            reqMap.put('holdFlag', '');
            reqMap.put('holdReasonCode', '');
            recordIds.add(installmentRecord.id);
            installmentMap.add(reqMap);
        }
        finalMap.put('defTermRq', installmentMap);
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        if (!installmentMap.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.MILESTONE_INTEGRATION, recordIds));
        }
    }
    //Process Default SR Callout
    public static void syncDefaultServiceRequest(set<id> srIds){
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> extensionMap = new List<Object>();
        list<ID> srIDList = new list<ID>();
        for (HexaBPM__Service_Request__c tempRec: [select id,SalesOrder__c,SalesOrder__r.RebateForfeitureLetterSent__c,SalesOrder__r.HoldFlag__c,SalesOrder__r.HoldReasonCode__c,InstallmentLine__c,InstallmentLine__r.InstallmentNumber__c,InstallmentLine__r.InstallmentDate__c,InstallmentLine__r.OriginalInstallmentDate__c from HexaBPM__Service_Request__c where id in : srIds and SalesOrder__r.Status__c in :HandoverUtility.soldSR]) {
            Map<String, Object> reqMap = new Map<String, Object>();
            reqMap.put('intgType', 'SO_UPD_HOLD');
            reqMap.put('sfServiceReqId', tempRec.Id);
            reqMap.put('sfSalesOrderId', tempRec.SalesOrder__c);
            reqMap.put('sfInstallmentId', tempRec.InstallmentLine__c);
            reqMap.put('instNum', String.valueOf(tempRec.InstallmentLine__r.InstallmentNumber__c));
            reqMap.put('origInstDate', (tempRec.InstallmentLine__r.OriginalInstallmentDate__c == null ? null: tempRec.InstallmentLine__r.OriginalInstallmentDate__c) );
            reqMap.put('instDate', tempRec.InstallmentLine__r.InstallmentDate__c);
            reqMap.put('rebateForfLetSent', tempRec.SalesOrder__r.RebateForfeitureLetterSent__c ==true ? 'Y':'N');
            reqMap.put('holdFlag', tempRec.SalesOrder__r.HoldFlag__c ==true ? 'Y':'N' );
            reqMap.put('holdReasonCode', tempRec.SalesOrder__r.HoldReasonCode__c);
            extensionMap.add(reqMap);
            srIDList.add(tempRec.Id);
        }
        finalMap.put('defTermRq', extensionMap);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        if (!extensionMap.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.DEFAULT_INTEGRATION, srIDList));
        }
    }
    
    //Process Milestone Response
    public static void processInstallmentResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
        //
        List<String> installmentIds = new List<String>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            if (responseRecord.status == Constants.MULESOFT_FAILED || responseRecord.status == Constants.MULESOFT_FAILURE){
                installmentIds.add(responseRecord.sfInstallmentId);
            }
        }
        Map<Id, InstallmentLines__c> srMap = new Map<Id, InstallmentLines__c>([SELECT Id, RetryCount__c FROM InstallmentLines__c WHERE Id IN :installmentIds]);

        List<InstallmentLines__c> inSuccessList = new List<InstallmentLines__c>();
        List<InstallmentLines__c> inFailedList = new List<InstallmentLines__c>();
        List<Logger__c> loggerList = new List<Logger__c>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            InstallmentLines__c inRecord = new InstallmentLines__c();
            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                inRecord.Id = responseRecord.sfInstallmentId;
                inRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                inRecord.SyncTime__c = Datetime.now();
                inRecord.RetryCount__c = 0;
                inRecord.ErrorReason__c = '';
                inSuccessList.add(inRecord);
            } else if (responseRecord.status == Constants.MULESOFT_FAILED || responseRecord.status == Constants.MULESOFT_FAILURE) {
                inRecord.Id = responseRecord.sfInstallmentId;
                inRecord.SyncStatus__c = Constants.STATUS_FAILED;
                inRecord.SyncTime__c = Datetime.now();
                inRecord.RetryCount__c = srMap.get(responseRecord.sfInstallmentId).RetryCount__c == null ? 1 : srMap.get(responseRecord.sfInstallmentId).RetryCount__c + 1;
                inRecord.ErrorReason__c = responseRecord.errorMsg;
                inFailedList.add(inRecord);
                loggerList.add(LoggerService.addApexServiceCalls('DefaultAndTerminationCalloutHelper', 'processInstallmentResponse', processName, requestBody, muleRes, responseRecord.sfInstallmentId));
            }
        }
        if (!inSuccessList.isEmpty()) {
            update inSuccessList;
        }
        
        if (!inFailedList.isEmpty()) {
            update inFailedList;
            if (!loggerList.isEmpty()) {
                insert loggerList;
            }
        }
    }
    
    //Process Default SR Response
    public static void processDefaultSRResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
        List<String> srIds = new List<String>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            if (responseRecord.status == Constants.MULESOFT_FAILED || responseRecord.status == Constants.MULESOFT_FAILURE){
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
            } else if (responseRecord.status == Constants.MULESOFT_FAILED || responseRecord.status == Constants.MULESOFT_FAILURE ) {
                srRecord.Id = responseRecord.sfServiceReqId;
                srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = srMap.get(responseRecord.sfServiceReqId).RetryCount__c == null ? 1 : srMap.get(responseRecord.sfServiceReqId).RetryCount__c + 1;
                srRecord.ErrorReason__c = responseRecord.errorMsg;
                srFailedList.add(srRecord);
                loggerList.add(LoggerService.addApexServiceCalls('DefaultAndTerminationCalloutHelper', 'processDefaultSRResponse', processName, requestBody, muleRes, responseRecord.sfServiceReqId));
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