public class CalloutToMuleSoft {
    public static Boolean isFromTrigger = FALSE; //If invoking from Trigger, then this will be true.  SARAVANAN SEKAR
  public static Boolean updateSOSyncStatus = false;
  public static Boolean updateInstallmentSyncStatus = false; 
    
    public static List<String> bankVirtualAccountProcesses = new List<String>{'BankIntegrationVA','BankIntegrationVACancel','FABBankIntegrationVA','ADIBBankIntegrationVA','ADIBBankIntegrationVACancel', 'FABBankIntegrationVACancel', 'FABBankIntegrationVAModify', 'ADIBBankIntegrationVAModify', 'MashreqBankIntegrationVA', 'MashreqBankIntegrationVAEnquiry', 'MashreqBankIntegrationVACancel', 'MashreqBankIntegrationVAModify'}; //FIN-43,FIN-77
    public static List<String> bankDirectDebitAPIProcesses = new List<String>{'ADCBRegistrationMandate','ADIBRegistrationMandate', 'ADIBRegistrationMandateFileUpload', 'ADCBRegistrationCancel', 'ADIBRegistrationCancel', 'ADIBRegistrationMandateFileUpload','ADIBCollectionMandate'};
    
    @future(callout = true)
    public static void calloutFutureService(String requestBody, Boolean processResponse,String processName,List<Id> recordIds){
        calloutService(requestBody,processResponse,processName,recordIds);
    }
    //Added by Harsh@Aldar 25/01/2025
    public static HttpResponse makeCallout(String processName,String requestBody){
        //---- Fetch mulesoft URLs
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(processName);
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        System.debug('@@@endPointURL'+endPointURL);
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setHeader('Content-Type','application/json');
        request.setHeader('client_secret',mulesoftAPI.APIKey__c);
        request.setHeader('client_id',mulesoftAPI.APIId__c);
        request.setTimeout(120000);
        request.setEndpoint(endPointURL);
        request.setMethod(mulesoftAPI.Method__c);
        System.debug('**Request Body**'+requestBody);
        request.setBody(requestBody);

        return http.send(request);
    }
    
    public static void calloutService(String requestBody, Boolean processResponse,String processName,List<Id> recordIds){
        System.debug('calloutService invoked');
        System.debug('@@@processName'+processName);
        String muleRes = '';
        try{
            //---- Fetch mulesoft URLs
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(processName);
            Organization org = Utilities.getOrganizationDetails();
            
            String endPointURL = mulesoftAPI.SandboxURL__c ;
            system.debug('@@@endPointURL'+endPointURL);
            
            if(!org.IsSandbox){
                endPointURL = mulesoftAPI.ProductionURL__c ; 
            }

            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setHeader('Content-Type','application/json');
            request.setHeader('client_secret',mulesoftAPI.APIKey__c);
            request.setHeader('client_id',mulesoftAPI.APIId__c);
            request.setTimeout(120000);
            request.setEndpoint(endPointURL);
            request.setMethod(mulesoftAPI.Method__c);
            System.debug('**Request Body**'+requestBody);
            request.setBody(requestBody);

            HttpResponse response = http.send(request);
            
            muleRes = response.getBody();
           
            System.debug('**Response Body**'+muleRes);
            System.debug('processName'+processName);
            if (processName == Constants.AGENCY_INTEGRATION || processName == Constants.SALESORDER_INTEGRATION || processName == Constants.PAYMENT_CHQ_INTEGRATION) {
                if(muleRes.contains(Label.BlankResultFor500Mule)){
                    muleRes = muleRes.replace(Label.BlankResultFor500Mule, '"results": {}');
                }
                MuleSOResponeWrapper responseBody = soParse(muleRes);
                if(responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS){
                    //To handle 500 and 504 errors
                    if( processName == Constants.SALESORDER_INTEGRATION  && (responseBody.statusCode =='500' || responseBody.statusCode =='504' || responseBody.statusCode =='503') ){
                        processSOMuleResponse(responseBody,processName,processResponse,(requestBody.length() < 131072 ? requestBody : ''), muleRes);
                    }else{
                        LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoft','calloutService',processName,(requestBody.length() < 131072 ? requestBody : ''),muleRes,null));
                    }
                }else{
                    processSOMuleResponse(responseBody,processName,processResponse,(requestBody.length() < 131072 ? requestBody : ''), muleRes);
                }
            } 
            else if(processName == 'ddrRequestToBank') {
               // if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                    system.debug('response.getStatusCode()::'+response.getStatusCode());
                    BatchToDirectDebitCalloutHelper.updateDDTransaction(muleRes, recordIds, requestBody);
                    
               /* }else{
                    LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoft','calloutService',processName,(requestBody.length() < 131072 ? requestBody : ''),muleRes,null));
                } */ 
            }else if(bankVirtualAccountProcesses.contains(processName)){
                BankVirtualAccountController.updateBankVirtualAccountResponse(muleRes, requestBody, processName); 
            }else if(bankDirectDebitAPIProcesses.contains(processName)){
                BatchToDirectDebitCalloutAPIHelper.updateDdtransactionResponse(muleRes, recordIds, requestBody, processName, String.ValueOf(response.getStatusCode()));
              //Loggers for DirectDebit
                LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoft','calloutService',processName,(requestBody.length() < 131072 ? requestBody : requestBody.left(131070)),(muleRes.length() < 131072 ? muleRes : muleRes.left(131070)),null));
            }else if(processName == 'InvoiceBundle'){
                InvoiceBundleTriggerHandler.updateERPResponse(muleRes);
            }
            
            else {
                if(muleRes.contains(Label.BlankResultFor500Mule)){
                    muleRes = muleRes.replace(Label.BlankResultFor500Mule, '"results": [{}]');
                }
                MuleResponeWrapper responseBody = parse(muleRes);
                if(responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS){
                    LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoft','calloutService',processName,(requestBody.length() < 131072 ? requestBody : ''),muleRes,null));
                }else{
                    processMuleResponse(responseBody,processName,processResponse,(requestBody.length() < 131072 ? requestBody : ''), muleRes);
                }
            }
        }catch (DMLException ex) {
            //SAL-597 SARAN Below Lines Swapped to capture the Logger__c Id in Base Record
            Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(ex,processName,'CalloutToMuleSoft','calloutService'));
            updateStatusAsFailed(recordIds, lgs.Id);
            System.debug('DMLException lgs.Id -> '+lgs.Id);
        }catch(Exception e){
            //SAL-597 SARAN Below Lines Swapped to capture the Logger__c Id in Base Record
            Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.addApexServiceCallsLog(e, 'CalloutToMuleSoft', 'calloutService', processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes));
            updateStatusAsFailed(recordIds, lgs.Id);
            System.debug('Exception lgs.Id -> '+lgs.Id);
        } 
    }

    public static void processMuleResponse(MuleResponeWrapper responseBody, String processName,Boolean processResponse, String requestBody, String muleRes){
        List<Unit__c> updatedUnitList = new List<Unit__c>();
        List<Project__c> updatedProjectList = new List<Project__c>();
        List<PaymentPlan__c> updatedPaymentPlanList = new List<PaymentPlan__c>();

        List<MuleResponeWrapper.MuleResponse> results = responseBody.results ; 
        if(processResponse){
            List<Logger__c> loggerListForSync = new List<Logger__c>();

            if(processName == Constants.PRICE_UPDATE){    
                for(MuleResponeWrapper.MuleResponse responseRecord : results){
                    updatedUnitList.add(new Unit__c(Id=responseRecord.sfId,PriceSyncStatus__c=responseRecord.status,PriceFailureReason__c=responseRecord.errorMessage,ReprocessCallout__c=null));
                    if(responseRecord.status == 'Success'){
                        Logger__c log = LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId);
                        log.Unit__c = responseRecord.sfId;
                        loggerListForSync.add(log);
                    }else{
                        Logger__c log = LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId);
                        log.Unit__c = responseRecord.sfId;
                        loggerListForSync.add(log);
                    }
                }
            }  
            if(processName == Constants.STATUS_UPDATE){    
                for(MuleResponeWrapper.MuleResponse responseRecord : results){
                    // Add status sync time stamp
                    // Add unit lookup in logger
                    updatedUnitList.add(new Unit__c(Id=responseRecord.sfId,StatusSyncStatus__c=responseRecord.status,StatusFailureReason__c=responseRecord.errorMessage,ReprocessCallout__c=null));
                    if(responseRecord.status == 'Success'){
                        Logger__c log = LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId); log.Unit__c = responseRecord.sfId;
                        loggerListForSync.add(log);
                    }else{ 
                        Logger__c log =LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId);
                        log.Unit__c = responseRecord.sfId;
                        loggerListForSync.add(log);
                    }
                }
            }
            //Added by Chirag
            if(processName == Constants.Damascus_Callback_Property){
                CalloutToMuleSoft.DamascusResponse damRes = (CalloutToMuleSoft.DamascusResponse)JSON.deserialize(muleRes,CalloutToMuleSoft.DamascusResponse.class);
        if(damRes.data != null && damRes.data.size() >0){
                    for(CalloutToMuleSoft.cls_data dt : damRes.data){
                        String state = '';
                        if(dt.status == '200' || dt.status =='201'){
                            state = 'Success';
                        }else{
                            state = 'Error';
                        }
                        updatedUnitList.add(new Unit__c(Id=dt.id,DamascusSyncStatus__c= state,DamascusStatusFailureReason__c=dt.errorMsg ,ReprocessCallout__c=null));
                    }
                }
            }
            if(updatedUnitList!=null && updatedUnitList.size()>0){ update updatedUnitList; }
            if (!loggerListForSync.isEmpty()) { insert loggerListForSync; }
            
            //Project Response
            if(processName == Constants.Damascus_Callback_Project){
                CalloutToMuleSoft.DamascusResponse damRes = (CalloutToMuleSoft.DamascusResponse)JSON.deserialize(muleRes,CalloutToMuleSoft.DamascusResponse.class);
                if(damRes.data != null && damRes.data.size() >0){
                    for(CalloutToMuleSoft.cls_data dt : damRes.data){
                        String state = '';
                        if(dt.status == '200' || dt.status =='201'){
                            state = 'Success';
                        }else{
                            state = 'Error';
                        }
                        System.debug('Project Id check '+ dt.id);
                        
                        updatedProjectList.add(new Project__c(Id=dt.id, DamascusSyncStatus__c=state, DamascusStatusFailureReason__c=dt.errorMsg));
                        
                    } 
                }
            }
            if(!updatedProjectList.isEmpty()){ update updatedProjectList; }

            //Payment Plan Response
            if(processName == Constants.Damascus_Callback_Payment_Plan){
                CalloutToMuleSoft.DamascusResponse damRes = (CalloutToMuleSoft.DamascusResponse)JSON.deserialize(muleRes,CalloutToMuleSoft.DamascusResponse.class);
                if(damRes.data != null && damRes.data.size() >0){
                    for(CalloutToMuleSoft.cls_data dt : damRes.data){
                        String state = '';
                        if(dt.status == '200' || dt.status =='201'){
                            state = 'Success';
                        }else{
                            state = 'Error';
                        }
                        System.debug('Payment Plan Id Check: '+ dt.id);
                        updatedPaymentPlanList.add(new PaymentPlan__c(Id=dt.id,DamascusSyncStatus__c=state, DamascusStatusFailureReason__c=dt.errorMsg));
                    } 
                }
            }
            if(!updatedPaymentPlanList.isEmpty()){ update updatedPaymentPlanList; }

            if (processName == Constants.CUSTOMER_INTEGRATION) {
                List<String> accIds = new List<String>();
                for(MuleResponeWrapper.MuleResponse responseRecord : results){
                    if (responseRecord.status == Constants.MULESOFT_FAILED){
                        accIds.add(responseRecord.sfId);
                    }
                }
                Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, RetryCount__c FROM Account WHERE Id IN :accIds]);

                List<Account> accSuccessList = new List<Account>();
                List<Account> accFailedList = new List<Account>();
                List<Logger__c> loggerList = new List<Logger__c>();
                for (MuleResponeWrapper.MuleResponse responseRecord : results) {
                    Account acc = new Account();
                    if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                        acc.Id = responseRecord.sfId;
                        acc.SyncStatus__c = Constants.STATUS_SYNCED;
                        acc.ERPID__c = responseRecord.partyId;
                        acc.OtherERPID__c = JSON.serialize(responseRecord);
                        acc.SyncTime__c = Datetime.now();
                        acc.RetryCount__c = 0;
                        acc.ErrorReason__c = '';
                        accSuccessList.add(acc);
                        loggerList.add(LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId));
                    } else if (responseRecord.status == Constants.MULESOFT_FAILED) {
                        acc.Id = responseRecord.sfId;
                        acc.SyncStatus__c = Constants.STATUS_FAILED;
                        acc.SyncTime__c = Datetime.now();
                        acc.RetryCount__c = accMap.get(responseRecord.sfId).RetryCount__c == null ? 1 : accMap.get(responseRecord.sfId).RetryCount__c + 1;
                        acc.ErrorReason__c = responseRecord.errorMsg;
                        accFailedList.add(acc);
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId));
                    }
                }
                if (!accSuccessList.isEmpty()) {
                    AccountTriggerHandler.skipAccountTrigger = true;
                    update accSuccessList;
                    AccountTriggerHandler.skipAccountTrigger = false;
                }
                if (!accFailedList.isEmpty()) {
                    AccountTriggerHandler.skipAccountTrigger = true;
                    update accFailedList;
                    AccountTriggerHandler.skipAccountTrigger = false;
                }
                if (!loggerList.isEmpty()) { insert loggerList; }
                
            } else if (processName == Constants.JOINTOWNER_INTEGRATION) {
                List<String> joIds = new List<String>();
                for(MuleResponeWrapper.MuleResponse responseRecord : results){
                    if (responseRecord.status == Constants.MULESOFT_FAILURE){
                        joIds.add(responseRecord.sfId);
                    }
                }
                Map<Id, JointOwner__c> joMap = new Map<Id, JointOwner__c>([SELECT Id, RetryCounter__c FROM JointOwner__c WHERE Id IN :joIds]);

                List<JointOwner__c> joSuccessList = new List<JointOwner__c>();
                List<JointOwner__c> joFailedList = new List<JointOwner__c>();
                List<JointOwner__c> deleteJOList = new List<JointOwner__c>();
                List<Logger__c> loggerList = new List<Logger__c>();
                for (MuleResponeWrapper.MuleResponse responseRecord : results) {
                    JointOwner__c jo = new JointOwner__c();
                    if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                        if (responseRecord.mode == Constants.MULESOFT_DELETE_MODE) {
                            jo.Id = responseRecord.sfId;
                            deleteJOList.add(jo);
                        } else {
                            jo.Id = responseRecord.sfId;
                            jo.SyncStatus__c = Constants.STATUS_SYNCED;
                            jo.ERPID__c = responseRecord.jointOwnerId;
                            jo.SyncTime__c = Datetime.now();
                            jo.RetryCounter__c = 0;
                            jo.ErrorResponse__c = '';
                            joSuccessList.add(jo);
                        }
                    } else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                        jo.Id = responseRecord.sfId;
                        jo.SyncStatus__c = Constants.STATUS_FAILED;
                        jo.SyncTime__c = Datetime.now();
                        jo.RetryCounter__c = joMap.get(responseRecord.sfId).RetryCounter__c == null ? 1 : joMap.get(responseRecord.sfId).RetryCounter__c + 1;
                        jo.ErrorResponse__c = responseRecord.errorMsg;
                        joFailedList.add(jo);
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId));
                    }
                }
                if (!joSuccessList.isEmpty()) { update joSuccessList; }
                if (!joFailedList.isEmpty()) { update joFailedList; }
                if (!deleteJOList.isEmpty()) { delete deleteJOList; }
                if (!loggerList.isEmpty()) { insert loggerList; }
            } else if (processName == Constants.MARKETING_REIMBURSEMENT_INTEGRATION) {
                List<String> brIds = new List<String>();
                for(MuleResponeWrapper.MuleResponse responseRecord : results){
                    if (responseRecord.status == Constants.MULESOFT_FAILED){
                        brIds.add(responseRecord.sfId);
                    }
                }
                Map<Id, BrokerRequest__c> brMap = new Map<Id, BrokerRequest__c>([SELECT Id, RetryCount__c FROM BrokerRequest__c WHERE Id IN :brIds]);

                List<BrokerRequest__c> brSuccessList = new List<BrokerRequest__c>();
                List<BrokerRequest__c> brFailedList = new List<BrokerRequest__c>();
                List<Logger__c> loggerList = new List<Logger__c>();
                for (MuleResponeWrapper.MuleResponse responseRecord : results) {
                    BrokerRequest__c br = new BrokerRequest__c();
                    if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                        br.Id = responseRecord.sfId;
                        br.SyncStatus__c = Constants.STATUS_SYNCED;
                        br.ERPID__c = responseRecord.erpId;
                        br.SyncTime__c = Datetime.now();
                        br.RetryCount__c = 0;
                        br.ErrorReason__c = '';
                        brSuccessList.add(br);
                    } else if (responseRecord.status == Constants.MULESOFT_FAILED) {
                        br.Id = responseRecord.sfId;
                        br.SyncStatus__c = Constants.STATUS_FAILED;
                        br.SyncTime__c = Datetime.now();
                        br.RetryCount__c = brMap.get(responseRecord.sfId).RetryCount__c == null ? 1 : brMap.get(responseRecord.sfId).RetryCount__c + 1;
                        br.ErrorReason__c = responseRecord.errorMsg;
                        brFailedList.add(br);
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId));
                    }
                }
                if (!brSuccessList.isEmpty()) { update brSuccessList; }
                if (!brFailedList.isEmpty()) { update brFailedList; }
                if (!loggerList.isEmpty()) { insert loggerList; }
            }
        }
    }
 
    public static void processSO500MuleErrorResponse(MuleSOResponeWrapper responseBody,String processName, String requestBody, String muleRes){
        
        List<SalesOrder__c> soFailedList = new List<SalesOrder__c>();
        List<Logger__c> loggerList = new List<Logger__c>();
        Map<String, Object> level1 = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
        List<Object> objList       = (List<Object>)level1.get('salesOrderDetails');
        List<String> soIds = new List<String>();
        
        Map<Integer, Map<String, Object>> level2 = new Map<Integer, Map<String, Object>>();
        for(Integer i=0; i<objList.size(); i++){
            Map<String, Object> maps = (Map<String, Object>)objList[i];
            level2.put(i, maps);
        }
        
        
        for(Integer i:level2.keySet()){
            Map<String, Object> maps = level2.get(i);
            if(maps.get('sfSalesOrderNum') != null){
                soIds.add(String.valueof(maps.get('sfSalesOrderNum')));
            }
        }
        
        Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>([SELECT Id, RetryCount__c FROM SalesOrder__c WHERE Id IN :soIds]);
        
        for(String ids: soIds){
            SalesOrder__c so = new SalesOrder__c(); 
            so.Id = ids;so.SyncStatus__c = Constants.STATUS_FAILED;so.SyncTime__c = Datetime.now();so.RetryCount__c = soMap.get(ids).RetryCount__c == null ? 1 : soMap.get(ids).RetryCount__c + 1;
            so.ErrorReason__c =responseBody.statusCode;soFailedList.add(so);
            loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, ids));
        }
        
        system.debug('soIds:::'+soIds); 
        if(!soFailedList.isEmpty()){ update soFailedList; } 
        if(!loggerList.isEmpty() ){ Insert loggerList; }
    }
    public static void processSOMuleResponse(MuleSOResponeWrapper responseBody, String processName,Boolean processResponse, String requestBody, String muleRes){
        MuleSOResponeWrapper.MuleResponse results = responseBody.results;
        system.debug('results::'+results);
        if(processResponse){
            if (processName == Constants.AGENCY_INTEGRATION) {
                List<String> accIds = new List<String>();
                for (MuleSOResponeWrapper.SOResponse responseRecord : results.supplBrokerRes){
                    if (responseRecord.status == Constants.MULESOFT_FAILURE){
                        accIds.add(responseRecord.sfSupplierId);
                    }
                }
                Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, RetryCount__c FROM Account WHERE Id IN :accIds]);

                List<Account> accSuccessList = new List<Account>();
                List<Account> accFailedList = new List<Account>();
                List<Contact> conList = new List<Contact>();
                List<Logger__c> loggerList = new List<Logger__c>();
                for (MuleSOResponeWrapper.SOResponse responseRecord : results.supplBrokerRes) {
                    Account acc = new Account();
                    Map<String, Object> otherERPMap = new Map<String, Object>();
                    if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                        otherERPMap.put('oracleSupplierId',responseRecord.oracleSupplierId != null ? responseRecord.oracleSupplierId : '');
                        otherERPMap.put('oracleSiteId',responseRecord.oracleSiteId != null ? responseRecord.oracleSiteId :'');
                        otherERPMap.put('oracleResourceId',responseRecord.oracleResourceId != null ? responseRecord.oracleResourceId : '');
                        otherERPMap.put('oracleContactId',responseRecord.oracleContactId != null ? responseRecord.oracleContactId : '');
                        acc.Id = responseRecord.sfSupplierId;
                        acc.SyncStatus__c = Constants.STATUS_SYNCED;
                        acc.ERPID__c = responseRecord.oracleResourceId;
                        acc.OtherERPID__c = JSON.serialize(otherERPMap);
                        acc.SyncTime__c = Datetime.now();
                        acc.IsBrokerChange__c = false;
                        acc.IsAgentChange__c = false;
                        acc.RetryCount__c = 0;
                        acc.ErrorReason__c = '';
                        // Added By Moh Sarfaraj for BPE-164
                        if(String.isNotBlank(responseRecord.bankDetailsStatus)){
                            acc.ProposedBankDetailStatus__c = responseRecord.bankDetailsStatus;
                        }
                        accSuccessList.add(acc);
                        for (MuleSOResponeWrapper.SOResponse responseRecordChild : responseRecord.brkrAgentDtls) {
                            Contact con = new Contact();
                            con.Id = responseRecordChild.sfAgentId;con.ERPID__c = responseRecordChild.oracleAgentId;
                            conList.add(con);
                        }
                        loggerList.add(LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfSupplierId));
                    } else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                        acc.Id = responseRecord.sfSupplierId;
                        acc.SyncStatus__c = Constants.STATUS_FAILED;
                        acc.SyncTime__c = Datetime.now();
                        acc.RetryCount__c = accMap.get(responseRecord.sfSupplierId).RetryCount__c == null ? 1 : accMap.get(responseRecord.sfSupplierId).RetryCount__c + 1;
                        acc.ErrorReason__c = responseRecord.errorMessage;
                        accFailedList.add(acc);
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfSupplierId));
                    }
                }
                /*for (MuleSOResponeWrapper.SOResponse responseRecord : results.brkrAgentDtls) {
                    Contact con = new Contact();
                    con.Id = responseRecord.sfAgentId;
                    con.ERPID__c = responseRecord.oracleAgentId;
                    conList.add(con);
                }*/
                if (!conList.isEmpty()) {
                    update conList;
                }
                
                if (!accSuccessList.isEmpty()) {
                    AccountTriggerHandler.skipAccountTrigger = true;
                    update accSuccessList;
                    AccountTriggerHandler.skipAccountTrigger = false;
                }
                if (!accFailedList.isEmpty()) {
                    AccountTriggerHandler.skipAccountTrigger = true;
                    update accFailedList;
                    AccountTriggerHandler.skipAccountTrigger = false;
                }
                if (!loggerList.isEmpty()) {
                    insert loggerList;
                }
            } 
            else if (processName == Constants.SALESORDER_INTEGRATION) {
                // NEW CODE FOR JSON START
                system.debug('processName::'+processName);
                if(responseBody.statusCode == '500' || responseBody.statusCode == '504' || responseBody.statusCode == '503'){
                    processSO500MuleErrorResponse( responseBody,processName,requestBody,muleRes);
                }else{
                    List<String> soIds = new List<String>();
                    for(MuleSOResponeWrapper.SOResponse responseRecord : results.salesOrderRes){
                        if(responseRecord.sfSalesOrderNum != null)
                            soIds.add(responseRecord.sfSalesOrderNum);
                    }
                    Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>([SELECT Id, RetryCount__c,(SELECT Id,ERPID__c,SyncStatus__c FROM InstallmentLines__r),(SELECT Id,ERPID__c,SyncStatus__c FROM CommissionLineItems__r) FROM SalesOrder__c WHERE Id IN :soIds]);
                    
                    List<SalesOrder__c> soSuccessList = new List<SalesOrder__c>();
                    List<SalesOrder__c> soFailedList = new List<SalesOrder__c>();
                    List<Logger__c> loggerList = new List<Logger__c>();
                    List<InstallmentLines__c> ilList = new List<InstallmentLines__c>();
                    List<CommissionLineItem__c> cliList = new List<CommissionLineItem__c>();
                    List<SalesOrder__c> soListToUpdate = new List<SalesOrder__c>();
                    for (MuleSOResponeWrapper.SOResponse responseRecord : results.salesOrderRes) {
                        SalesOrder__c so = new SalesOrder__c();
                        so.Id = responseRecord.sfSalesOrderNum;
                        so.SyncTime__c = Datetime.now();
                        String salesOrderErrorMessage = '';
                        Map<Id, CommissionLineItem__c> idCommLines = new Map<Id, CommissionLineItem__c>(soMap.get(responseRecord.sfSalesOrderNum).CommissionLineItems__r);
                        Map<Id, InstallmentLines__c> idInstallments = new Map<Id, InstallmentLines__c>(soMap.get(responseRecord.sfSalesOrderNum).InstallmentLines__r);
                        if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                            so.ERPID__c = responseRecord.erpSalesOrderId;
                            so.Logger_Id__c = '';
                            // Processing installments
                            system.debug('responseRecord.salesOrderlineRes::'+responseRecord.salesOrderlineRes);
                            for (MuleSOResponeWrapper.SOResponse installmentRec : responseRecord.salesOrderlineRes) {
                                InstallmentLines__c il = new InstallmentLines__c();
                                il.Id = installmentRec.sfInstId;
                                system.debug('---- installmentRec.erpInstId '+installmentRec.erpInstId);
                                system.debug('---- idInstallments.get(il.Id).ERPID__c '+idInstallments.get(il.Id).ERPID__c);
                                system.debug('---- installmentRec.status '+installmentRec.status);
                                system.debug('---- idInstallments.get(il.Id).SyncStatus__c '+idInstallments.get(il.Id).SyncStatus__c);
                                String installmentSyncStatus = '';
                                if(idInstallments.get(il.Id).SyncStatus__c == 'Synced'){
                                    installmentSyncStatus = Constants.MULESOFT_SUCCESS;
                                }else if(idInstallments.get(il.Id).SyncStatus__c == 'Failed'){
                                    installmentSyncStatus = Constants.MULESOFT_FAILURE;
                                }
                                if((idInstallments.containsKey(il.Id) && 
                                    (installmentRec.erpInstId != idInstallments.get(il.Id).ERPID__c ||
                                     installmentRec.status != installmentSyncStatus )) ||
                                   !idInstallments.containsKey(il.Id)){
                                      system.debug('---- UPDATING '+il);
                                      //il.SyncTime__c = Datetime.now(); Commenting this as we have sync time on SO
                                      if (installmentRec.status == Constants.MULESOFT_SUCCESS) {
                                          il.SyncStatus__c = Constants.STATUS_SYNCED;
                                          il.ERPID__c = installmentRec.erpInstId;
                                          il.ErrorReason__c = '';
                                      } else if (installmentRec.status == Constants.MULESOFT_FAILURE) {
                                          salesOrderErrorMessage += installmentRec.errorMsg + '\n';il.SyncStatus__c = Constants.STATUS_FAILED;il.ErrorReason__c = installmentRec.errorMsg;
                                      }
                                      ilList.add(il);
                                  }
                            }
                            if(responseRecord.salesOrderlineRes != null && !responseRecord.salesOrderlineRes.isEmpty()){
                            // Processing commissions
                            	for (MuleSOResponeWrapper.SOResponse commissionRec : responseRecord.salesConsultantRes) {
                                CommissionLineItem__c comm = new CommissionLineItem__c();
                                comm.Id = commissionRec.sfRecId;
                                String commissionSyncStatus = '';
                                if(idCommLines.get(comm.Id).SyncStatus__c == 'Synced'){
                                    commissionSyncStatus = Constants.MULESOFT_SUCCESS;
                                }else if(idCommLines.get(comm.Id).SyncStatus__c == 'Failed'){
                                    commissionSyncStatus = Constants.MULESOFT_FAILURE;
                                }
                                if((idCommLines.containsKey(comm.Id) && 
                                    (commissionRec.saleConsulRecId != idCommLines.get(comm.Id).ERPID__c ||
                                     commissionRec.status != commissionSyncStatus) ) ||
                                   !idCommLines.containsKey(comm.Id)){
                                       //idCommLines.get(comm.Id).SyncStatus__c
                                       system.debug('----commissionRec '+commissionRec);
                                       //                                        comm.SyncTime__c = Datetime.now();  Commenting this as we have sync time on SO
                                       if (commissionRec.status == Constants.MULESOFT_SUCCESS) {
                                           comm.SyncStatus__c = Constants.STATUS_SYNCED;
                                           if(commissionRec.saleConsulRecId != '' && commissionRec.saleConsulRecId != null ){
                                               comm.ERPID__c = commissionRec.saleConsulRecId;
                                           }
                                           comm.ErrorReason__c = '';
                                       } else if (commissionRec.status == Constants.MULESOFT_FAILURE) {
                                           salesOrderErrorMessage += commissionRec.errorMsg + '\n';comm.SyncStatus__c = Constants.STATUS_FAILED;comm.ErrorReason__c = commissionRec.errorMsg;
                                       }
                                       cliList.add(comm);
                                   }
                            }
                            }
                            if(salesOrderErrorMessage != ''){
                                so.Id = responseRecord.sfSalesOrderNum;
                                so.SyncStatus__c = Constants.STATUS_FAILED;so.SyncTime__c = Datetime.now(); so.RetryCount__c = soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c == null ? 1 : soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c + 1;so.ErrorReason__c = 'INS/COMM failure - '+salesOrderErrorMessage;
                                loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfSalesOrderNum));
                            }else{
                                so.SyncStatus__c = Constants.STATUS_SYNCED;
                                so.IsSalesOrderChange__c = false;
                                so.IsInstallmentLinesChange__c = false;
                                so.IsOtherChargesChange__c = false;
                                so.IsSalesOffersChange__c = false;
                                so.IsSalesConsultantsChange__c = false;
                                so.RetryCount__c = 0;
                                so.ErrorReason__c = '';
                                loggerList.add(LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfSalesOrderNum));
                            }
                            soListToUpdate.add(so);
                        } 
                        else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                            so.SyncStatus__c = Constants.STATUS_FAILED;
                            so.RetryCount__c = soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c == null ? 1 : soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c + 1;
                            so.ErrorReason__c = responseRecord.errorMsg;
                             // Processing installments to failed
                            for (MuleSOResponeWrapper.SOResponse installmentRec : responseRecord.salesOrderlineRes) {
                                InstallmentLines__c il = new InstallmentLines__c();
                                il.Id = installmentRec.sfInstId;
                                String installmentSyncStatus = '';
                                if(idInstallments.get(il.Id).SyncStatus__c == 'Synced'){
                                    installmentSyncStatus = Constants.MULESOFT_SUCCESS;
                                }else if(idInstallments.get(il.Id).SyncStatus__c == 'Failed'){
                                    installmentSyncStatus = Constants.MULESOFT_FAILURE;
                                }
                                if((idInstallments.containsKey(il.Id) && 
                                    (installmentRec.erpInstId != idInstallments.get(il.Id).ERPID__c ||
                                     installmentRec.status != installmentSyncStatus )) || 
                                   !idInstallments.containsKey(il.Id) ){
                                        il.SyncStatus__c = Constants.STATUS_FAILED;
                                        il.ErrorReason__c = 'Sales order integration failed.';
                                        ilList.add(il);
                                    }
                            }
                            // Processing commissions to failed
                            for (MuleSOResponeWrapper.SOResponse commissionRec : responseRecord.salesConsultantRes)  {
                                CommissionLineItem__c comm = new CommissionLineItem__c();
                                comm.Id = commissionRec.sfRecId;
                                String commissionSyncStatus = '';
                                if(idCommLines.get(comm.Id).SyncStatus__c == 'Synced'){
                                    commissionSyncStatus = Constants.MULESOFT_SUCCESS;
                                }else if(idCommLines.get(comm.Id).SyncStatus__c == 'Failed'){
                                    commissionSyncStatus = Constants.MULESOFT_FAILURE;
                                }
                                if((idCommLines.containsKey(comm.Id) && 
                                    (commissionRec.saleConsulRecId != idCommLines.get(comm.Id).ERPID__c ||
                                     commissionRec.status != commissionSyncStatus )) ||
                                   !idCommLines.containsKey(comm.Id)){
                                        comm.SyncStatus__c = Constants.STATUS_FAILED;
                                        comm.ErrorReason__c = 'Sales order integration failed.';
                                        cliList.add(comm);
                                    }
                            }
                            loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfSalesOrderNum));
                            soListToUpdate.add(so);
                        }
                    }
                    
                    if (!ilList.isEmpty()) {
                        updateInstallmentSyncStatus = true;
                        update ilList;
                        updateInstallmentSyncStatus = false;
                    }
                    if (!cliList.isEmpty()) {
                        update cliList;
                    }
                    if (!soListToUpdate.isEmpty()) {
                        updateSOSyncStatus = true;
                        update soListToUpdate;
                        updateSOSyncStatus = false;
                    }
                    if (!loggerList.isEmpty()) {
                        insert loggerList;
                    }
                    
                }
             // NEW CODE FOR JSON END     
       /* OLD CODE BEFORE JSON START        
         
          system.debug('processName::'+processName);
                if(responseBody.statusCode == '500' || responseBody.statusCode == '504' || responseBody.statusCode == '503'){
                    processSO500MuleErrorResponse( responseBody,processName,requestBody,muleRes);
                }else{
                    List<String> soIds = new List<String>();
                    for(MuleSOResponeWrapper.SOResponse responseRecord : results.salesOrderRes){
                        if (responseRecord.status == Constants.MULESOFT_FAILURE){
                            soIds.add(responseRecord.sfSalesOrderNum);
                        }
                    }
                    Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>([SELECT Id, RetryCount__c,(SELECT Id,ERPID__c,SyncStatus__c FROM InstallmentLines__r),(SELECT Id FROM CommissionLineItems__r) FROM SalesOrder__c WHERE Id IN :soIds]);
                    
                    List<SalesOrder__c> soSuccessList = new List<SalesOrder__c>();
                    List<SalesOrder__c> soFailedList = new List<SalesOrder__c>();
                    List<Logger__c> loggerList = new List<Logger__c>();
                    for (MuleSOResponeWrapper.SOResponse responseRecord : results.salesOrderRes) {
                        SalesOrder__c so = new SalesOrder__c();
                        if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                            so.Id = responseRecord.sfSalesOrderNum;
                            so.SyncStatus__c = Constants.STATUS_SYNCED;
                            so.ERPID__c = responseRecord.erpSalesOrderId;
                            so.SyncTime__c = Datetime.now();
                            so.IsSalesOrderChange__c = false;
                            so.IsInstallmentLinesChange__c = false;
                            so.IsOtherChargesChange__c = false;
                            so.IsSalesOffersChange__c = false;
                            so.IsSalesConsultantsChange__c = false;
                            so.RetryCount__c = 0;
                            so.ErrorReason__c = '';
                            soSuccessList.add(so);
                            loggerList.add(LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfSalesOrderNum));
                        } else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                            so.Id = responseRecord.sfSalesOrderNum;
                            so.SyncStatus__c = Constants.STATUS_FAILED;
                            so.SyncTime__c = Datetime.now();
                            so.RetryCount__c = soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c == null ? 1 : soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c + 1;
                            so.ErrorReason__c = responseRecord.errorMsg;
                            soFailedList.add(so);
                            loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.sfSalesOrderNum));
                        }
                    }
 
                    List<InstallmentLines__c> ilList = new List<InstallmentLines__c>();
                    for (MuleSOResponeWrapper.SOResponse responseRecord : results.salesOrderlineRes) {
                        InstallmentLines__c il = new InstallmentLines__c();
                        il.Id = responseRecord.sfInstId;
                        //       if(idInstallments.get(responseRecord.sfInstId).ERPID__c !=responseRecord.erpInstId) { //INTEG_ISSUE_FIX_SS
                        il.ERPID__c = responseRecord.erpInstId;
                        ilList.add(il);
                        //       }
                        
                    }
                    if (!ilList.isEmpty()) {
                        update ilList;
                    }
                    List<CommissionLineItem__c> cliList = new List<CommissionLineItem__c>();
                    //                Map<Id, CommissionLineItem__c> commIdComm = new Map<Id,CommissionLineItem__c>();
                    for (MuleSOResponeWrapper.SOResponse responseRecord : results.salesConsultantRes) {
                        CommissionLineItem__c comm = new CommissionLineItem__c();
                        comm.Id = responseRecord.sfRecId;
                        //  if(idCommLines.get(responseRecord.sfRecId).ERPID__c != responseRecord.saleConsulRecId) { //INTEG_ISSUE_FIX_SS
                        comm.ERPID__c =  responseRecord.saleConsulRecId;
                        //                        commIdComm.put(responseRecord.sfRecId, comm);
                        cliList.add(comm); //INTEG_ISSUE_FIX_SS
                        // }
                    }
                    if (!cliList.isEmpty()) {
                        update cliList;
                    }
                    
                    if (!soSuccessList.isEmpty()) {
                        update soSuccessList;
                    }
                    if (!soFailedList.isEmpty()) {
                        update soFailedList;
                    }
                    if (!loggerList.isEmpty()) {
                        insert loggerList;
                    }
                } 
OLD CODE BEFORE JSON END
*/
            } 
            else if (processName == Constants.PAYMENT_CHQ_INTEGRATION) {
                List<String> raIds = new List<String>();
                for(MuleSOResponeWrapper.SOResponse responseRecord : results.paymentRes){
                    //  if (responseRecord.status == Constants.MULESOFT_FAILURE){
                    if(responseRecord.recordId != null){
                        raIds.add(responseRecord.recordId);
                    }
                    //  }
                }
                Map<Id, ReceiptAcknowledgement__c> raMap = new Map<Id, ReceiptAcknowledgement__c>([SELECT Id, RetryCount__c FROM ReceiptAcknowledgement__c WHERE Id IN :raIds]);

                List<ReceiptAcknowledgement__c> raSuccessList = new List<ReceiptAcknowledgement__c>();
                List<ReceiptAcknowledgement__c> raFailedList = new List<ReceiptAcknowledgement__c>();
                List<Logger__c> loggerList = new List<Logger__c>();
                // -------- new code---------
                List<ReceiptAllocation__c> rallList = new List<ReceiptAllocation__c>();

                for (MuleSOResponeWrapper.SOResponse receiptAckResponse : results.paymentRes) {
                    ReceiptAcknowledgement__c ra = new ReceiptAcknowledgement__c();
                    ra.Id = receiptAckResponse.recordId;
                    ra.SyncTime__c = Datetime.now();
                    if (receiptAckResponse.status == Constants.MULESOFT_SUCCESS) {
                        String rallFailedMsgstring = '';
                        ra.ERPID__c = receiptAckResponse.erpCheckId;
                        ra.Logger_Id__c = '';
                        for (MuleSOResponeWrapper.SOResponse receiptAllocationResponse : receiptAckResponse.receiptApplRes) {
                            ReceiptAllocation__c rall = new ReceiptAllocation__c();
                            rall.Id = receiptAllocationResponse.recordId;
                            if (receiptAllocationResponse.status == Constants.MULESOFT_SUCCESS) {
                                rall.SyncTime__c = Datetime.now();
                                rall.SyncStatus__c = Constants.STATUS_SYNCED;
                                rall.ERPID__c = receiptAllocationResponse.erpCheckApplId;
                                rall.ErrorReason__c = '';
                            } else if (receiptAllocationResponse.status == Constants.MULESOFT_FAILURE) {
                                rallFailedMsgstring += receiptAllocationResponse.errorMsg + '\n';rall.SyncTime__c = Datetime.now();rall.SyncStatus__c = Constants.STATUS_FAILED;rall.ErrorReason__c = receiptAllocationResponse.errorMsg;
                            }
                            rallList.add(rall);
                        }
                        if(rallFailedMsgstring != ''){
                            ra.SyncStatus__c = Constants.STATUS_FAILED;
                            ra.RetryCount__c = raMap.get(receiptAckResponse.recordId).RetryCount__c == null ? 1 : raMap.get(receiptAckResponse.recordId).RetryCount__c + 1; ra.ErrorReason__c = 'Allocation sync failed - '+rallFailedMsgstring; raFailedList.add(ra);
                            loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, receiptAckResponse.recordId));
                        }
                        else{// Success
                            ra.SyncStatus__c = Constants.STATUS_SYNCED;
                            ra.RetryCount__c = 0;
                            ra.ErrorReason__c = '';
                            ra.IsReceiptAcknowledgementChange__c = false;
                            //ra.IsReceiptAllocationChange__c = false; Commented since ERP is not using this flag anymore.
                            ra.ERPCustomerNumber__c = receiptAckResponse.custAccountNum != null ? receiptAckResponse.custAccountNum : '';
                            raSuccessList.add(ra);
                            loggerList.add(LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, receiptAckResponse.recordId));
                        }
                    } 
                    else if (receiptAckResponse.status == Constants.MULESOFT_FAILURE) {
                        ra.SyncStatus__c = Constants.STATUS_FAILED;
                        ra.RetryCount__c = raMap.get(receiptAckResponse.recordId).RetryCount__c == null ? 1 : raMap.get(receiptAckResponse.recordId).RetryCount__c + 1;
                        ra.ErrorReason__c = receiptAckResponse.errorMsg;
                        ra.Logger_Id__c = '';
                        raFailedList.add(ra);
                        for (MuleSOResponeWrapper.SOResponse receiptAllocaitonResponse : receiptAckResponse.receiptApplRes) {
                            ReceiptAllocation__c rall = new ReceiptAllocation__c();
                            rall.Id = receiptAllocaitonResponse.recordId;
                            rall.SyncTime__c = Datetime.now();
                            rall.SyncStatus__c = Constants.STATUS_FAILED;
                            rall.ErrorReason__c = 'Receipt acknowledgment integraiton failed.';
//                            raFailedList.add(ra);
                            rallList.add(rall);
                        } 
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, receiptAckResponse.recordId));
                    }
                  
                }

                /*---------- OLD CODE ------------------
                for (MuleSOResponeWrapper.SOResponse responseRecord : results.paymentRes) {
                    ReceiptAcknowledgement__c ra = new ReceiptAcknowledgement__c();
                    if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                        ra.Id = responseRecord.recordId;
                        ra.SyncStatus__c = Constants.STATUS_SYNCED;
                        ra.ERPID__c = responseRecord.erpCheckId;
                        ra.SyncTime__c = Datetime.now();
                        ra.RetryCount__c = 0;
                        ra.ErrorReason__c = '';
                        ra.IsReceiptAcknowledgementChange__c = false;
                        ra.IsReceiptAllocationChange__c = false;
                        raSuccessList.add(ra);
                    } else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                        ra.Id = responseRecord.recordId;
                        ra.SyncStatus__c = Constants.STATUS_FAILED;
                        ra.SyncTime__c = Datetime.now();
                        ra.RetryCount__c = raMap.get(responseRecord.recordId).RetryCount__c == null ? 1 : raMap.get(responseRecord.recordId).RetryCount__c + 1;
                        ra.ErrorReason__c = responseRecord.errorMsg;
                        raFailedList.add(ra);
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, muleRes, responseRecord.recordId));
                    }
                }

                for (MuleSOResponeWrapper.SOResponse responseRecord : results.receiptApplRes) {
                    ReceiptAllocation__c rall = new ReceiptAllocation__c();
                    rall.Id = responseRecord.recordId;
                    rall.ERPID__c = responseRecord.erpCheckApplId;
                    rallList.add(rall);
                }
                */
                if (!rallList.isEmpty()) {
                    // FIN-140: Bypass ReceiptAllocation trigger during DML to prevent trigger recursion
                    // Added by Sai Kumar
                    ReceiptAllocationTriggerHandler.skipReceiptAllocationTrigger = true;
                    update rallList;
                    ReceiptAllocationTriggerHandler.skipReceiptAllocationTrigger = false;
                }

                if (!raSuccessList.isEmpty()) {
                    // FIN-140: Bypass ReceiptAcknowledgement trigger during DML to prevent trigger recursion
                    // Added by Sai Kumar
                    ReceiptAcknowledgementTriggerHandler.skipReceiptAcknowledgementTrigger = true;
                    update raSuccessList;
                    ReceiptAcknowledgementTriggerHandler.skipReceiptAcknowledgementTrigger = false;
                }
                if (!raFailedList.isEmpty()) {
                    // FIN-140: Bypass ReceiptAcknowledgement trigger during DML to prevent trigger recursion
                    // Added by Sai Kumar
                    ReceiptAcknowledgementTriggerHandler.skipReceiptAcknowledgementTrigger = true;
                    update raFailedList;
                    ReceiptAcknowledgementTriggerHandler.skipReceiptAcknowledgementTrigger = false;
                }
                if (!loggerList.isEmpty()) {
                    insert loggerList;
                }
            }
        }
    }

    public static MuleResponeWrapper parse(String json){
        return (MuleResponeWrapper)System.JSON.deserialize(json, MuleResponeWrapper.class);
    }

    public static MuleSOResponeWrapper soParse(String json){
        return (MuleSOResponeWrapper)System.JSON.deserialize(json, MuleSOResponeWrapper.class);
    }

    public static void updateStatusAsFailed(List<Id> recordIds, String loggerId) { //SAL-597 SARAN Added loggerId parameter
        String exceptionMessage = '';
        for(Logger__c log : [SELECT Id,ExceptionMessage__c FROM Logger__c WHERE ID =:loggerId ]){
            exceptionMessage = log.ExceptionMessage__c;
        }
        boolean addReason = false;
        if (!recordIds.isEmpty()) {
            String objectType = '';
            if (recordIds[0].getSObjectType() == Account.SObjectType) {
                objectType = 'Account';
                addReason = true;
            } else if (recordIds[0].getSObjectType() == BrokerRequest__c.SObjectType) {
                objectType = 'BrokerRequest__c';
                addReason = true;
            } else if (recordIds[0].getSObjectType() == JointOwner__c.SObjectType) {
                objectType = 'JointOwner__c';
            } else if (recordIds[0].getSObjectType() == ReceiptAcknowledgement__c.SObjectType) {
                objectType = 'ReceiptAcknowledgement__c';
                addReason = true;
            } else if (recordIds[0].getSObjectType() == SalesOrder__c.SObjectType) {
                objectType = 'SalesOrder__c';
                addReason = true;
            } /*else if (recordIds[0].getSObjectType() == CommissionLineItem__c.SObjectType) {  
                objectType = 'CommissionLineItem__c';  
            }*/
            if (objectType != '') {
                List<SObject> updateSObjectList = new List<SObject>();
                for (Id rId: recordIds) {
                    SObject updateSObject = Schema.getGlobalDescribe().get(objectType).newSObject();
                    updateSObject.put('Id', rId);updateSObject.put('SyncStatus__c', Constants.STATUS_FAILED);updateSObject.put('Logger_Id__c', loggerId);//SAL-597 SARAN
                    if(addReason){
                        updateSObject.put('ErrorReason__c','LOGGER - '+ exceptionMessage);
                    }
                    updateSObjectList.add(updateSObject);
                }
                if (!updateSObjectList.isEmpty()) {
                    // FIN-140: Bypass triggers for ReceiptAcknowledgement and ReceiptAllocation during DML to prevent trigger recursion
                    // Added by Sai Kumar
                    if (objectType == 'ReceiptAcknowledgement__c') {
                        ReceiptAcknowledgementTriggerHandler.skipReceiptAcknowledgementTrigger = true;
                    } else if (objectType == 'ReceiptAllocation__c') {
                        ReceiptAllocationTriggerHandler.skipReceiptAllocationTrigger = true;
                    }
                    update updateSObjectList;
                    // Reset trigger bypass flags
                    if (objectType == 'ReceiptAcknowledgement__c') {
                        ReceiptAcknowledgementTriggerHandler.skipReceiptAcknowledgementTrigger = false;
                    } else if (objectType == 'ReceiptAllocation__c') {
                        ReceiptAllocationTriggerHandler.skipReceiptAllocationTrigger = false;
                    }
                }
            }
        }
    }
    public class DamascusResponse{
        public Integer statusCode;  //201
        public cls_Error error;  //test
        public String message;  //Success
        public cls_data[] data;
    }
    public class cls_data{
        public String status;
        public String errorMsg;
        public String id;
    }
     public class cls_Error{
        public String errorName;
        public String details;
        public String path;
        public String timestamp;
    }
}