public with sharing class CalloutToMuleSoftQueueable implements Queueable, Database.AllowsCallouts {

    public String requestBody;
    public Boolean processResponse;
    public String processName;
    public List<Id> otherObjectIds;
    public String objectName;
    
    public CalloutToMuleSoftQueueable(String requestBody, Boolean processResponse, String processName, List<Id> otherObjectIds, String objectName) {
        this.requestBody = requestBody;
        this.processResponse = processResponse;
        this.processName = processName;
        this.otherObjectIds = otherObjectIds;
        this.objectName = objectName;
    }

    public void execute(QueueableContext context) {
        calloutMuleSoft(this.requestBody, this.processName, this.processResponse);
    }

    public void calloutMuleSoft(String requestBody, String processName, Boolean processResponse){
        String muleRes = '';
        try {
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(processName);
            Organization org = Utilities.getOrganizationDetails();
            
            String endPointURL = mulesoftAPI.SandboxURL__c ;
            
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
            muleRes = response.getBody() ;
            System.debug('**Response Body**'+muleRes);
            if (processName == Constants.SALESORDER_INTEGRATION) {
                MuleSOResponeWrapper responseBody = soParse(muleRes);
                if(responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS){
                    LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable','calloutMuleSoft',processName,(requestBody.length() < 131072 ? requestBody : ''),muleRes,null));
                }else{
                    processSOMuleResponse(responseBody,processName,processResponse, (requestBody.length() < 131072 ? requestBody : ''), muleRes);
                }
            } else {
                MuleResponeWrapper responseBody = parse(muleRes);
                if(responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS){
                    LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable','calloutMuleSoft',processName,(requestBody.length() < 131072 ? requestBody : ''),muleRes,null));
                }else{
                    processMuleResponse(responseBody,processName,processResponse, (requestBody.length() < 131072 ? requestBody : ''), muleRes);
                }
            }
        }catch (DMLException ex) {
            updateStatusAsFailed(this.otherObjectIds);
            LoggerService.save(LoggerService.createApexLog(ex,processName,'CalloutToMuleSoftQueueable','calloutMuleSoft'));
        }catch(Exception e){
            updateStatusAsFailed(this.otherObjectIds);
            LoggerService.save(LoggerService.addApexServiceCallsLog(e, 'CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes));
        }
    }

    public void processMuleResponse(MuleResponeWrapper responseBody, String processName, Boolean processResponse, String requestBody, String muleRes){
        List<MuleResponeWrapper.MuleResponse> results = responseBody.results ; 
        if(processResponse){
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
                Map<String, String> customerMap = new Map<String, String>();
                List<Logger__c> loggerList = new List<Logger__c>();
                List<Id> accountIdsForRetry = new List<Id>(); //ALDAR_CHANGES_TO_FIX_CUSTOEMR_CALLOUT_ISSUE
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
                        
                        customerMap.put(responseRecord.sfId, responseRecord.partyId);
                    } else if (responseRecord.status == Constants.MULESOFT_FAILED) {
                        acc.Id = responseRecord.sfId;
                        //acc.SyncStatus__c = Constants.STATUS_FAILED;//ALDAR_CHANGES_TO_FIX_CUSTOEMR_CALLOUT_ISSUE
                        acc.SyncTime__c = Datetime.now();
                        acc.RetryCount__c = accMap.get(responseRecord.sfId).RetryCount__c == null ? 1 : accMap.get(responseRecord.sfId).RetryCount__c + 1;
                        acc.ErrorReason__c = responseRecord.errorMsg;
                        //ALDAR_CHANGES_TO_FIX_CUSTOEMR_CALLOUT_ISSUE START
                        //"errorMsg": "CUSTOMER ALREADY EXISTS" - If this is the Error then partyId will be there 100% from ERP
                        if(responseRecord.errorMsg =='CUSTOMER ALREADY EXISTS') {
                           //accountMuleResponseMap.put(acc.id, responseRecord);
                            acc.ERPID__c = responseRecord.partyId;
                            acc.OtherERPID__c = JSON.serialize(responseRecord);
                            acc.SyncStatus__c = 'In Progress';
                            accountIdsForRetry.add(acc.Id);

                            accSuccessList.add(acc);
                            customerMap.put(responseRecord.sfId, responseRecord.partyId);
                        }else {
                            acc.SyncStatus__c = Constants.STATUS_FAILED;

                            accFailedList.add(acc);
                        }
                        //ALDAR_CHANGES_TO_FIX_CUSTOEMR_CALLOUT_ISSUE END
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId));
                    }
                }
                List<Account> actToUpdate = new List<Account>();
               // if(!accountIdsForRetry.isEmpty()){
                   // List<Account> accountList = [Select Id,SyncStatus__c  from Account where Id in:accountIdsForRetry ];
                    
                  /*  system.debug('accountMuleResponseMap::'+accountMuleResponseMap);
                    string reqBody = prepareRequestBodyforRetry(accountMuleResponseMap);
                    system.debug('reqBody::'+reqBody);
                    calloutMuleSoft(reqBody, this.processName, this.processResponse); */
               // }
                
                if (!accSuccessList.isEmpty()) {
                    if (!customerMap.isEmpty() && this.objectName == 'SalesOrder__c') {
                        Map<String, String> salesOrderMap = SalesOrderCalloutHelper.PrepareDataForCallout(this.otherObjectIds, true, customerMap);
                        calloutMuleSoft(salesOrderMap.get('requestBody'), salesOrderMap.get('processName'), processResponse);
                    } else if (!customerMap.isEmpty() && this.objectName == 'JointOwner__c') {
                        Map<String, String> jointOwnerMap = JointOwnerCalloutHelper.PrepareDataForCallout(this.otherObjectIds, true, customerMap);
                        calloutMuleSoft(jointOwnerMap.get('requestBody'), jointOwnerMap.get('processName'), processResponse);
                    }

                    update accSuccessList;
                    
                    if (this.objectName == 'ServiceRequest_PropertyTransfer' && !this.otherObjectIds.isEmpty()) {
                        PropertyTransferCalloutHelper.getDataForCallout(this.otherObjectIds);
                    } else if (this.objectName == 'ServiceRequest_JointOwner' && !this.otherObjectIds.isEmpty()) {
                        JointOwnerR2CalloutHelper.getDataForCallout(this.otherObjectIds);
                    }
                }
                
                if (!accFailedList.isEmpty()) {
                    update accFailedList;
                    if ((this.objectName == 'ServiceRequest_PropertyTransfer' || this.objectName == 'ServiceRequest_JointOwner') && !this.otherObjectIds.isEmpty()) {
                        List<HexaBPM__Service_Request__c> updateSRList = new List<HexaBPM__Service_Request__c>();
                        for (Id rId: this.otherObjectIds) {
                            HexaBPM__Service_Request__c updateSR = new HexaBPM__Service_Request__c();
                            updateSR.put('Id', rId);
                            updateSR.put('SyncStatus__c', Constants.STATUS_FAILED);
                            updateSRList.add(updateSR);
                        }
                        if(!updateSRList.isEmpty()){
                            update updateSRList;
                        }
                    }
                    if (!loggerList.isEmpty()) {
                        insert loggerList;
                    }
                }
                if(!accountIdsForRetry.isEmpty()){
                    system.debug('accountIdsForRetry:::'+accountIdsForRetry);
                    BatchToCustomerCallout batch = new BatchToCustomerCallout();
                    database.executeBatch(batch);
                }
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
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutService', processName, requestBody, muleRes, responseRecord.sfId));
                    }
                }
                if (!deleteJOList.isEmpty()) {
                    delete deleteJOList;
                }
                if (!joSuccessList.isEmpty()) {
                    update joSuccessList;
                }
                if (!joFailedList.isEmpty()) {
                    update joFailedList;
                }
                if (!loggerList.isEmpty()) {
                    insert loggerList;
                }
            }
        }
    }

    public void processSOMuleResponse(MuleSOResponeWrapper responseBody, String processName, Boolean processResponse, String requestBody, String muleRes){
        MuleSOResponeWrapper.MuleResponse results = responseBody.results; 
        if(processResponse){
            if (processName == Constants.SALESORDER_INTEGRATION) {
               if(responseBody.statusCode == '500' || responseBody.statusCode == '504' || responseBody.statusCode == '503'){
                    CalloutToMuleSoft.processSO500MuleErrorResponse( responseBody,processName,requestBody,muleRes);
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
                                if(idInstallments.containsKey(il.Id) && 
                                   (installmentRec.erpInstId != idInstallments.get(il.Id).ERPID__c ||
                                    installmentRec.status != installmentSyncStatus ) ){
                                        system.debug('---- UPDATING '+il);
//                                        il.SyncTime__c = Datetime.now(); Commenting this as we have sync time on SO
                                        if (installmentRec.status == Constants.MULESOFT_SUCCESS) {
                                            il.SyncStatus__c = Constants.STATUS_SYNCED;
                                            il.ERPID__c = installmentRec.erpInstId;
                                            il.ErrorReason__c = '';
                                        } else if (installmentRec.status == Constants.MULESOFT_FAILURE) {
                                            salesOrderErrorMessage += installmentRec.errorMsg + '\n';
                                            il.SyncStatus__c = Constants.STATUS_FAILED;
                                            il.ErrorReason__c = installmentRec.errorMsg;
                                        }
                                        ilList.add(il);
                                    }
                            }
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
                                if(idCommLines.containsKey(comm.Id) && 
                                   (commissionRec.saleConsulRecId != idCommLines.get(comm.Id).ERPID__c ||
                                    commissionRec.status != idCommLines.get(comm.Id).SyncStatus__c ) ){
                                        system.debug('----commissionRec '+commissionRec);
//                                        comm.SyncTime__c = Datetime.now();  Commenting this as we have sync time on SO
                                        if (commissionRec.status == Constants.MULESOFT_SUCCESS) {
                                            comm.SyncStatus__c = Constants.STATUS_SYNCED;
                                            comm.ERPID__c = commissionRec.erpInstId;
                                            comm.ErrorReason__c = '';
                                        } else if (commissionRec.status == Constants.MULESOFT_FAILURE) {
                                            salesOrderErrorMessage += commissionRec.errorMsg + '\n';
                                            comm.SyncStatus__c = Constants.STATUS_FAILED;
                                            comm.ErrorReason__c = commissionRec.errorMsg;
                                        }
                                        cliList.add(comm);
                                    }
                            }
                            if(salesOrderErrorMessage != ''){
                                so.Id = responseRecord.sfSalesOrderNum;
                                so.SyncStatus__c = Constants.STATUS_FAILED;
                                so.SyncTime__c = Datetime.now();
                                so.RetryCount__c = soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c == null ? 1 : soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c + 1;
                                so.ErrorReason__c = 'INS/COMM failure - '+salesOrderErrorMessage;
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
                                if(idInstallments.containsKey(il.Id) && 
                                   (installmentRec.erpInstId != idInstallments.get(il.Id).ERPID__c ||
                                    installmentRec.status != idInstallments.get(il.Id).SyncStatus__c ) ){
                                        il.SyncStatus__c = Constants.STATUS_FAILED;
                                        il.ErrorReason__c = 'Sales order integration failed.';
                                        ilList.add(il);
                                    }
                            }
                            // Processing commissions to failed
                            for (MuleSOResponeWrapper.SOResponse commissionRec : responseRecord.salesConsultantRes)  {
                                CommissionLineItem__c comm = new CommissionLineItem__c();
                                comm.Id = commissionRec.sfRecId;
                                if(idCommLines.containsKey(comm.Id) && 
                                   (commissionRec.saleConsulRecId != idInstallments.get(comm.Id).ERPID__c ||
                                    commissionRec.status != idInstallments.get(comm.Id).SyncStatus__c ) ){
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
                        CalloutToMuleSoft.updateInstallmentSyncStatus = true;
                        update ilList;
                        CalloutToMuleSoft.updateInstallmentSyncStatus = false;
                    }
                    if (!cliList.isEmpty()) {
                        update cliList;
                    }
                    if (!soListToUpdate.isEmpty()) {
                        CalloutToMuleSoft.updateSOSyncStatus = true;
                        update soListToUpdate;
                        CalloutToMuleSoft.updateSOSyncStatus = false;
                    }
                    if (!loggerList.isEmpty()) {
                        insert loggerList;
                    }
                    
                }
                
                /*   List<String> soIds = new List<String>();
                for(MuleSOResponeWrapper.SOResponse responseRecord : results.salesOrderRes){
                    if (responseRecord.status == Constants.MULESOFT_FAILURE){
                        soIds.add(responseRecord.sfSalesOrderNum);
                    }
                }
                Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>([SELECT Id, RetryCount__c FROM SalesOrder__c WHERE Id IN :soIds]);

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
                    } else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                        so.Id = responseRecord.sfSalesOrderNum;
                        so.SyncStatus__c = Constants.STATUS_FAILED;
                        so.SyncTime__c = Datetime.now();
                        so.RetryCount__c = soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c == null ? 1 : soMap.get(responseRecord.sfSalesOrderNum).RetryCount__c + 1;
                        so.ErrorReason__c = responseRecord.errorMsg;
                        soFailedList.add(so);
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutService', processName, requestBody, muleRes, responseRecord.sfSalesOrderNum));
                    }
                }

                List<InstallmentLines__c> ilList = new List<InstallmentLines__c>();
                for (MuleSOResponeWrapper.SOResponse responseRecord : results.salesOrderlineRes) {
                    InstallmentLines__c il = new InstallmentLines__c();
                    il.Id = responseRecord.sfInstId;
                    il.ERPID__c = responseRecord.erpInstId;
                    ilList.add(il);
                }
                if (!ilList.isEmpty()) {
                    update ilList;
                }
                
                List<CommissionLineItem__c> cliList = new List<CommissionLineItem__c>();
                for (MuleSOResponeWrapper.SOResponse responseRecord : results.salesConsultantRes) {
                    CommissionLineItem__c comm = new CommissionLineItem__c();
                    comm.Id = responseRecord.sfRecId;
                    comm.ERPID__c = responseRecord.saleConsulRecId;
                    cliList.add(comm);
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
                }*/
            }
        }
    }

    public MuleResponeWrapper parse(String json){
        return (MuleResponeWrapper)System.JSON.deserialize(json, MuleResponeWrapper.class);
    }

    public MuleSOResponeWrapper soParse(String json){
        return (MuleSOResponeWrapper)System.JSON.deserialize(json, MuleSOResponeWrapper.class);
    }

    public static void updateStatusAsFailed(List<Id> otherObjectIds) {
        if (!otherObjectIds.isEmpty()) {
            String objectType = '';
            if (otherObjectIds[0].getSObjectType() == JointOwner__c.SObjectType) {
                objectType = 'JointOwner__c';
            } else if (otherObjectIds[0].getSObjectType() == SalesOrder__c.SObjectType) {
                objectType = 'SalesOrder__c';
            } else if (otherObjectIds[0].getSObjectType() == HexaBPM__Service_Request__c.SObjectType) {
                objectType = 'HexaBPM__Service_Request__c';
            }
            List<SObject> updateSObjectList = new List<SObject>();
            if(objectType!=''){
            for (Id rId: otherObjectIds) {
                SObject updateSObject = Schema.getGlobalDescribe().get(objectType).newSObject();
                updateSObject.put('Id', rId);
                updateSObject.put('SyncStatus__c', Constants.STATUS_FAILED);
                updateSObjectList.add(updateSObject);
            }
            }
            if (!updateSObjectList.isEmpty()) {
                update updateSObjectList;
            }
        }
    }
    
    //ALDAR_CHANGES_TO_FIX_CUSTOEMR_CALLOUT_ISSUE - START
    public static string prepareRequestBodyforRetry(Map<Id, MuleResponeWrapper.MuleResponse> accountMuleResponseMap){
        List<Id> accountIds = new List<Id>();
        for(Id ids: accountMuleResponseMap.keySet()){
            accountIds.add(ids);
        }
        
        List<Account> accList = AccountService.queryAllFieldsWithExtraFields(accountIds);
        system.debug('accList::'+accList);
        
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> cdList = new List<Object>();
        
        for (Account acc: accList) {
            Map<String, Object> cdMap = new Map<String, Object>();
            
            String recordMode = String.isBlank(acc.ERPID__c) ? Constants.MULESOFT_CREATE_MODE : Constants.MULESOFT_UPDATE_MODE;
            String mobileCountryCode = '';
            if (acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT) {
                mobileCountryCode = acc.MobileCountryCode__pc != null && acc.MobileCountryCode__pc.contains('+') ? acc.MobileCountryCode__pc.substring(1, acc.MobileCountryCode__pc.length()) : acc.MobileCountryCode__pc;
            } else {
                mobileCountryCode = acc.MobileCountryCode__c != null && acc.MobileCountryCode__c.contains('+') ? acc.MobileCountryCode__c.substring(1, acc.MobileCountryCode__c.length()) : acc.MobileCountryCode__c;
            }

            cdMap.put('sfId', acc.Id);
            cdMap.put('custType', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? 'ORGANIZATION' : 'PERSON');
            cdMap.put('organizationName', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Name : '');
            cdMap.put('registrationNumber', acc.RegistrationNumber__c != null ? acc.RegistrationNumber__c: '');
            cdMap.put('issueDate', string.valueOf(acc.RegistrationIssueDate__c) != null ? string.valueOf(acc.RegistrationIssueDate__c): '');
            cdMap.put('expiryDate', string.valueOf(acc.RegistrationExpiryDate__c) != null ? string.valueOf(acc.RegistrationExpiryDate__c): '');
            cdMap.put('placeOfRegistration', acc.PlaceOfRegistration__c != null ? acc.PlaceOfRegistration__c : '');
            cdMap.put('nameInArabic', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.NameInArabic__c : ''); // for Organization
            cdMap.put('nameArabic', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.NameInArabic__c : '');   // for Person
            cdMap.put('motherNameArabic', acc.MotherNameArabic__pc != null ? acc.MotherNameArabic__pc : '');
            cdMap.put('tradeName', acc.TradeName__c != null ? acc.TradeName__c : '');
            cdMap.put('unifiedNumber', acc.UnifiedNumber__c != null ? acc.UnifiedNumber__c: '');
            cdMap.put('typeOfCompany', acc.TypeOfCompany__c != null ? acc.TypeOfCompany__c : '');
            cdMap.put('owner', '');   // need to check by Venu
            cdMap.put('fullyOwnedByUaeNational', '');   // need to check by Venu
            cdMap.put('tenantIndustry', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Industry : '');   // List Of Values | by Venu
            cdMap.put('customerClass', '');   // List Of Values | by Venu
            cdMap.put('investmentValue', '');   // List Of Values | by Venu
            cdMap.put('currentValueRating', acc.CurrentValueRating__c != null ? acc.CurrentValueRating__c : '');
            cdMap.put('potentialValueRatingOrg', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.PotentialValueRating__c : ''); // for Organization
            cdMap.put('potentialValueRating', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.PotentialValueRating__c : '');   // for Person
            cdMap.put('influenceRating', '');   // List Of Values | by Venu
            cdMap.put('loyaltyOrg', acc.Loyalty__c != null ? acc.Loyalty__c:'');
            cdMap.put('placeOfIncorporation', '');   // need to check by Venu
            cdMap.put('gateReminderLetter', '');   // Date value
            cdMap.put('gateExpiryLetter', '');   // Date Value
            cdMap.put('preNameAdjunct', acc.Salutation != null ? acc.Salutation: '');
            cdMap.put('firstName', acc.FirstName);
            cdMap.put('middleName', acc.MiddleName != null ? acc.MiddleName: '');
            cdMap.put('lastName', acc.LastName);
            cdMap.put('gender', acc.Gender__pc);
            cdMap.put('dateOfBirth', acc.PersonBirthdate);
            cdMap.put('maritalStatus', acc.MaritalStatus__pc);
            cdMap.put('passportNumber', acc.PassportNumber__pc);
            cdMap.put('passportType', acc.Passport_type__pc);
            cdMap.put('passportPlaceOfIssue', acc.PlaceofIssue__pc);
            cdMap.put('passportIssueDate', acc.PassportIssueDate__pc);
            cdMap.put('passportExpiryDate', acc.PassportExpiryDate__pc);
            cdMap.put('visaNo', acc.VisaUIDNo__pc != null? acc.VisaUIDNo__pc : '');
            cdMap.put('visaExpiry', acc.VisaExpiryDate__pc);
            cdMap.put('nationality', acc.Nationality__pc);
            cdMap.put('nationalIdNumber', acc.NationalIdNumber__pc != null ? acc.NationalIdNumber__pc : '');
            cdMap.put('nationalIdExpiry', string.valueOf(acc.NationalIdExpiryDate__pc) != null ? string.valueOf(acc.NationalIdExpiryDate__pc) : '');
            cdMap.put('homatCardNo', acc.Homatcardnumber__pc != null ? acc.Homatcardnumber__pc :  '');
            cdMap.put('company', acc.Company__pc != null ? acc.Company__pc : '');   // need to check by Venu
            cdMap.put('companyName', acc.Company__pc != null ?acc.Company__pc: '' );   // need to check by Venu
            cdMap.put('uaeFamilyNo', acc.UaeFamilyNumber__pc != null ? acc.UaeFamilyNumber__pc : '');
            cdMap.put('uaeFamilyBookNo', acc.UaeFamilyBookNumber__pc != null ? acc.UaeFamilyBookNumber__pc: '');
            cdMap.put('uaeFbPlaceOfIssue', string.valueOf(acc.UaeFamilyBookPlaceofIssue__pc) != null? string.valueOf(acc.UaeFamilyBookPlaceofIssue__pc): '');
            cdMap.put('uaeFbIssueDate', string.valueOf(acc.UaeFamilyBookDateofIssue__pc) != null ? string.valueOf(acc.UaeFamilyBookDateofIssue__pc):'');
            cdMap.put('customerSegment', acc.CustomerType__c);   // List Of Values | by Venu
            cdMap.put('residencyStatus', acc.ResidentStatus__pc == 'Non-Resident' ? 'Non - Resident' : acc.ResidentStatus__pc);   // List Of Values | by Venu
            cdMap.put('employementStatus', acc.EmploymentStatus__pc);
            cdMap.put('purposeOfInvestment', '');   // need to check by Venu
            cdMap.put('smartPass', acc.SmartPass__pc != null ? acc.SmartPass__pc : '');
            cdMap.put('unifiedNo', acc.UnifiedNumber__c != null ? acc.UnifiedNumber__c: '');
            cdMap.put('loyalty', acc.Loyalty__c != null ? acc.Loyalty__c: '');
            cdMap.put('classification', acc.CustomerSubType__c);   // List Of Values | by Venu
            cdMap.put('partyId', accountMuleResponseMap.get(acc.id).partyId);
            cdMap.put('createdByUser', String.isBlank(acc.ERPID__c) ? acc.CreatedBy.Email : acc.Owner.Email);
            // cdMap.put('createdByUser', 'VPAWAR');
            cdMap.put('sourceOfFunds', acc.SourceofFunds__pc);
            cdMap.put('otherSoruceFund', acc.Other_Source_of_Funds__pc);
            cdMap.put('positionTitle', acc.Position__pc);

            //Pass compound field as a trimmed string.
            string workplaceAddress = acc.Workplace_Street__pc + ' ,'+ acc.Workplace_Country__pc + ' ,'+ acc.Workplace_Postalcode__pc;
            String trimmedworkplaceAddress = workplaceAddress != null ? workplaceAddress.substring(0, Math.min(99, workplaceAddress.length())) : '';

            cdMap.put('companyAddress', trimmedworkplaceAddress != null ? trimmedworkplaceAddress : '');
            cdMap.put('annualTotalIncome', String.valueOf(acc.AnnualIncome__pc));
            cdMap.put('noOfYearsWithCompany', String.valueOf(acc.NoofYearswithCompany__pc) != null ? String.valueOf(acc.NoofYearswithCompany__pc): '');
            cdMap.put('natureOfBusiness', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.Industry : '');   // List Of Values | by Venu
            cdMap.put('emailP', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Email__c : acc.PersonEmail);
            cdMap.put('phoneLineTypeP', 'MOBILE');   // List Of Values // need to change
            cdMap.put('phoneCountryCodeP', mobileCountryCode);
            cdMap.put('phoneAreaCodeP', '');
            cdMap.put('phoneNumberP', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.MobileNumber1__c : acc.MobilePhone__pc);
            cdMap.put('phoneExtensionP', '');
            cdMap.put('countryP', String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : '');
            cdMap.put('address1P', acc.BillingStreet);
            cdMap.put('address2P', '');
            cdMap.put('address3P', '');
            cdMap.put('address4P', '');
            cdMap.put('cityP', acc.BillingCity);
            cdMap.put('postalCodeP', acc.BillingPostalCode);
            cdMap.put('stateP', acc.BillingState);
            cdMap.put('provinceP', '');
            cdMap.put('countyP', '');
            cdMap.put('emailS', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Email__c : acc.PersonEmail);
            cdMap.put('phoneLineTypeS', 'MOBILE');   // List Of Values // need to change
            cdMap.put('phoneCountryCodeS', mobileCountryCode);
            cdMap.put('phoneAreaCodeS', '');
            cdMap.put('phoneNumberS', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.MobileNumber1__c : acc.MobilePhone__pc);
            cdMap.put('phoneExtensionS', '');
            cdMap.put('countryS', String.isNotBlank(acc.ShippingCountry) ? acc.ShippingCountry : '');
            cdMap.put('address1S', acc.ShippingStreet);
            cdMap.put('address2S', '');
            cdMap.put('address3S', '');
            cdMap.put('address4S', '');
            cdMap.put('cityS', acc.ShippingCity);
            cdMap.put('postalCodeS', acc.ShippingPostalCode);
            cdMap.put('stateS', acc.ShippingState);
            cdMap.put('provinceS', '');
            cdMap.put('countyS', '');
            
            Map<String, Object> oIds = new Map<String, Object>();
            if(acc.OtherERPID__c == null){
                acc.OtherERPID__c = JSON.serialize(accountMuleResponseMap.get(acc.id));
            }if (acc.OtherERPID__c != null) {
                oIds = (Map<String, Object>)JSON.deserializeUntyped(acc.OtherERPID__c);
                for (String key: oIds.keySet()) {
                    oIds.put(key.toLowerCase(), oIds.get(key));
                }
            }
           
            cdMap.put('partySiteIdP', !oIds.isEmpty() && oIds.containsKey('partysiteidp') ? String.valueOf(oIds.get('partysiteidp')) : '');
            cdMap.put('partySiteUseIdP', !oIds.isEmpty() && oIds.containsKey('partysiteuseidp') ? String.valueOf(oIds.get('partysiteuseidp')) : '');
            cdMap.put('contactPointIdPhoneP', !oIds.isEmpty() && oIds.containsKey('contactpointidphonep') ? String.valueOf(oIds.get('contactpointidphonep')) : '');
            cdMap.put('contactPointIdEmailP', !oIds.isEmpty() && oIds.containsKey('contactpointidemailp') ? String.valueOf(oIds.get('contactpointidemailp')) : '');
            cdMap.put('locationIdP', !oIds.isEmpty() && oIds.containsKey('locationidp') ? String.valueOf(oIds.get('locationidp')) : '');
            cdMap.put('partySiteIdS', !oIds.isEmpty() && oIds.containsKey('partysiteids') ? String.valueOf(oIds.get('partysiteids')) : '');
            cdMap.put('partySiteUseIdS', !oIds.isEmpty() && oIds.containsKey('partysiteuseids') ? String.valueOf(oIds.get('partysiteuseids')) : '');
            cdMap.put('contactPointIdPhoneS', !oIds.isEmpty() && oIds.containsKey('contactpointidphones') ? String.valueOf(oIds.get('contactpointidphones')) : '');
            cdMap.put('contactPointIdEmailS', !oIds.isEmpty() && oIds.containsKey('contactpointidemails') ? String.valueOf(oIds.get('contactpointidemails')) : '');
            cdMap.put('locationIdS', !oIds.isEmpty() && oIds.containsKey('locationids') ? String.valueOf(oIds.get('locationids')) : '');

            cdList.add(cdMap);
        }
        finalMap.put('customerDetails', cdList);
        String requestBody = JSON.serialize(finalMap);
        return requestBody;
    } 
    //ALDAR_CHANGES_TO_FIX_CUSTOEMR_CALLOUT_ISSUE - END
}