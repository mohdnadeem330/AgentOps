global class InstallmentCallout_Batch implements Schedulable,Database.Batchable<sObject>,Database.AllowsCallouts {
    
    global void execute(SchedulableContext ctx) { 
        Integer batchSize = Utilities.getConstantValue('InstallmentDateAPIBatchSize');
        database.executebatch(new InstallmentCallout_Batch(), batchSize);
        
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select id,PaymentInstallments__c from InstallmentLines__c where SyncStatus__c = \'' + Constants.STATUS_FAILED + '\'' ;
       system.debug('query@@@'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope){
        /*set<ID> paymentPlanIds = new set<ID>();
        for(InstallmentLines__c tempRec : scope){
            paymentPlanIds.add(tempRec.PaymentInstallments__c);
        }*/
        system.debug('@@@scope'+scope);
        set<ID> installmentIds = new set<ID>();
        for(InstallmentLines__c temprec : scope){
            installmentIds.add(temprec.id);
        }
        system.debug('Calling integration class******');
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> installmentMap = new List<Object>();
        list<ID> recordIds = new list<ID>();
        for (InstallmentLines__c installmentRecord: [select id,SalesOrder__c,InstallmentNumber__c,OriginalInstallmentDate__c,InstallmentDate__c from InstallmentLines__c where id in :installmentIds and SyncStatus__c != :Constants.STATUS_SYNCED and SalesOrder__r.Status__c in :PaymentInstallmentTriggerHandler.soldSR]) {
           system.debug('@@@installmentRecord'+installmentRecord);
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
        System.debug('@requestBody@'+requestBody);
        if (!installmentMap.isEmpty()) {
           // System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.MILESTONE_INTEGRATION, recordIds));
             calloutMuleSoft(requestBody, true, Constants.MILESTONE_INTEGRATION, recordIds);
        }
        
       //  DefaultAndTerminationCalloutHelper.syncInstallmentswithBatch(installmentIds);
    }    
    global void finish(Database.BatchableContext bc){} 
    
    public void calloutMuleSoft(String requestBody,Boolean processResponse, String processName ,list<ID> recordIds){
        String muleRes = '';
        try {
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(processName);
            system.debug('mulesoftAPI@@'+mulesoftAPI);
            Organization org = Utilities.getOrganizationDetails();
            system.debug('Org@@'+org);
            String endPointURL = mulesoftAPI.SandboxURL__c ;
            if(!org.IsSandbox){
                endPointURL = mulesoftAPI.ProductionURL__c ; 
            }
            system.debug('endPointURL@@'+endPointURL);
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setHeader('Content-Type', 'application/json');
            request.setHeader('client_secret', mulesoftAPI.APIKey__c);
            request.setHeader('client_id', mulesoftAPI.APIId__c);
            request.setTimeout(120000);
            request.setEndpoint(endPointURL);
            request.setMethod(mulesoftAPI.Method__c);
            System.debug('**Request Body**' + requestBody);
            request.setBody(requestBody);

            HttpResponse response = http.send(request);
            System.debug('**Response Body**' + response);
            muleRes = response.getBody() ;
            System.debug('**Response Body**' + muleRes);

      
                MuleResponeWrapper responseBody = parse(muleRes);
                if (responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS) {
                    LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes, null));
                } else {
                    processMuleResponse(responseBody, processName, processResponse, (requestBody.length() < 131072 ? requestBody : ''), muleRes);
                }
          
        } catch (DMLException ex) {
             LoggerService.save(LoggerService.createApexLog(ex,processName,'CalloutToMuleSoftQueueable','calloutMuleSoft'));
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexServiceCallsLog(e, 'CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes));
        }
    }
    
 
    
    public void processMuleResponse(MuleResponeWrapper responseBody, String processName, Boolean processResponse, String requestBody, String muleRes){
        List<MuleResponeWrapper.MuleResponse> results = responseBody.results; 
        
                processInstallmentResponse(results, processName, requestBody, muleRes);
            
          
    }
    
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

 
    public MuleResponeWrapper parse(String json){
        return (MuleResponeWrapper)System.JSON.deserialize(json, MuleResponeWrapper.class);
    }

    
}