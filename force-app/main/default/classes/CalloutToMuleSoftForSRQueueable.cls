public with sharing class CalloutToMuleSoftForSRQueueable implements Queueable, Database.AllowsCallouts {
    public String requestBody;
    public Boolean processResponse;
    public String processName;
    public List<Id> recordIds;
    
    public CalloutToMuleSoftForSRQueueable(String requestBody, Boolean processResponse, String processName, List<Id> recordIds) {
        this.requestBody = requestBody;
        this.processResponse = processResponse;
        this.processName = processName; 
        this.recordIds = recordIds;
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

            request.setHeader('Content-Type', 'application/json');
            request.setHeader('client_secret', mulesoftAPI.APIKey__c);
            request.setHeader('client_id', mulesoftAPI.APIId__c);
            request.setTimeout(120000);
            request.setEndpoint(endPointURL);
            request.setMethod(mulesoftAPI.Method__c);
            System.debug('**Request Body**' + requestBody);
            request.setBody(requestBody);

            HttpResponse response = http.send(request);
            muleRes = response.getBody() ;
            System.debug('**Response Body**' + muleRes);

            if (processName == Constants.OWNERSHIP_CHANGE_INTEGRATION) {
                //processName == Constants.PAYMENT_PLAN_CHANGE || 
                //processName == Constants.LPC_INTEGRATION ||  REMOVED by SS_JSON_CHANGE to accomodate JSON format resoponse change on 110723
                //processName == Constants.PROPERTY_TRANS_INTEGRATION || REMOVED by SS_JSON_CHANGE to accomodate JSON format resoponse change on 130723
                //processName == Constants.CANCELLATION_INTEGRATION || REMOVED by SS_JSON_CHANGE to accomodate JSON format resoponse change on 170723
                MuleSOResponeWrapper responseBody = soParse(muleRes);
                if (responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS) {
                    LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes, null));
                } else {
                    processMuleSOResponse(responseBody, processName, processResponse, (requestBody.length() < 131072 ? requestBody : ''), muleRes);
                }
            } else if (processName == Constants.PAYMENT_PLAN_CHANGE || processName == Constants.LPC_INTEGRATION || processName == Constants.PROPERTY_TRANS_INTEGRATION || processName == Constants.CANCELLATION_INTEGRATION) {
                //ADDED by SS_JSON_CHANGE to accomodate JSON format resoponse change
                System.debug('##** processName > '+processName);
                Boolean isNotSuccess = false;
                if(processName == Constants.LPC_INTEGRATION || processName == Constants.PAYMENT_PLAN_CHANGE) {
                    MulePOSResponeWrapper responseBody = lpcParse(muleRes);
                    isNotSuccess = responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS;
                    if(!isNotSuccess) {
                        processLPCMuleResponse(responseBody, processName, processResponse, (requestBody.length() < 131072 ? requestBody : ''), muleRes);
                    }
                } else if(processName == Constants.PROPERTY_TRANS_INTEGRATION || processName == Constants.CANCELLATION_INTEGRATION) {
                    MulePOSSingleResponseWrapper responseBody = posParse(muleRes);
                    isNotSuccess = responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS;
                    System.debug('**## isNotSuccess -> '+isNotSuccess);
                    if (!isNotSuccess) {
                        System.debug('**## processPOSMuleResponse -> '+isNotSuccess);
                        //MulePOSSingleResponseWrapper responseBody1 = posParse('{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "results": { "prpTransRs": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "a0Q25000005B7EZEA0", "srERPId": "2310073", "status": "Success", "errorMsg": "", "othChgRes": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "a0Q25000005B7EZEA0", "sfId": "a29250000023HAiAAM", "erpId": "9061916", "recAcct": "02.00.A340010.122101.02.00.000.000", "expAcct": "02.10.A340010.233167.02.00.000.000", "taxAcct": "02.10.A340010.233169.02.00.000.000", "status": "Success", "errorMsg": "", "invoiceNo": "70083143" } ], "prpTransJORs": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "a0Q25000005B7EZEA0", "soSFId": "a2A8d000000LeQDEA0", "cusSFId": "0018d00000ECUtbAAH", "cusERPId": "22562", "sfTransferSFID": "a1O25000002NIWWEA4", "status": "Success", "errorMsg": "" }, { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "a0Q25000005B7EZEA0", "soSFId": "a2A8d000000LeQDEA0", "cusSFId": "0012500001rDGwjAAG", "cusERPId": "22563", "sfTransferSFID": "a1O25000002NIWlEAO", "status": "Success", "errorMsg": "" }, { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "a0Q25000005B7EZEA0", "soSFId": "a2A8d000000LeQDEA0", "cusSFId": "0012500001wttCxAAI", "cusERPId": "22564", "sfTransferSFID": "a1O25000002NIWqEAO", "status": "Success", "errorMsg": "" } ] } ] } }');
                        processPOSMuleResponse(responseBody, processName, processResponse, (requestBody.length() < 131072 ? requestBody : ''), muleRes);
                    }
                }
                if(isNotSuccess) {
                    LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes, null));
                }
            } else {
                MuleResponeWrapper responseBody = parse(muleRes);
                if (responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS) {
                    LoggerService.save(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes, null));
                } else {
                    processMuleResponse(responseBody, processName, processResponse, (requestBody.length() < 131072 ? requestBody : ''), muleRes);
                }
            }
        } catch (DMLException ex) {
            String errorMessage = ex.getStackTraceString()+' ***---*** Exception Message: '+ex.getMessage();
            updateStatusAsFailed(this.recordIds, processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes, errorMessage);
            // LoggerService.save(LoggerService.createApexLog(ex,processName,'CalloutToMuleSoftQueueable','calloutMuleSoft'));
        } catch (Exception e) {
            String errorMessage = e.getStackTraceString()+' ***---*** Exception Message: '+e.getMessage();
            updateStatusAsFailed(this.recordIds, processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes, errorMessage);
            // LoggerService.save(LoggerService.addApexServiceCallsLog(e, 'CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, (requestBody.length() < 131072 ? requestBody : ''), muleRes));
        }
    }

    public static void processLPCMuleResponse(MulePOSResponeWrapper responseBody, String processName, Boolean processResponse, String requestBody, String muleRes){
        //ADDED by SS_JSON_CHANGE to accomodate JSON format resoponse change
        //MulePOSResponeWrapper.Results results = responseBody.results; 
        System.debug('$$ processLPCMuleResponse');
        if (processResponse) {
            System.debug('responseBody.results.size() > '+responseBody.results.size());
            if (processName == Constants.LPC_INTEGRATION && responseBody.results.size()>0) {
                LPCCalloutHelper.processLPCResponse(responseBody.results[0], processName, requestBody, muleRes);
            } else if (processName == Constants.PAYMENT_PLAN_CHANGE && responseBody.results.size()>0) {
                PaymentPlanChangeCalloutHelper.processPPCResponse(responseBody.results[0], processName, requestBody, muleRes);
            }
        }
    }
    
    public void processPOSMuleResponse(MulePOSSingleResponseWrapper responseBody, String processName, Boolean processResponse, String requestBody, String muleRes){
        //ADDED by SS_JSON_CHANGE to accomodate JSON format resoponse change
        System.debug('$$ processPOSMuleResponse');
        if (processResponse) {
            if (processName == Constants.PROPERTY_TRANS_INTEGRATION) {
                PropertyTransferCalloutHelper.processPropertyTransferResponse(responseBody.results, processName, requestBody, muleRes);
            } else if (processName == Constants.CANCELLATION_INTEGRATION) { // SS_JSON_IMPLEMENTATION 17-Jul-23
                CancellationCalloutHelper.processCancellationResponse(responseBody.results, processName, requestBody, muleRes);
            }
        }
    }
    
    public void processMuleResponse(MuleResponeWrapper responseBody, String processName, Boolean processResponse, String requestBody, String muleRes){
        List<MuleResponeWrapper.MuleResponse> results = responseBody.results; 
        System.debug('processName>>>' + processName);
        System.debug('processResponse>>>' + processResponse);
        System.debug('results>>>' + results);

        if (processResponse) {
            if (processName == Constants.PAYMENT_EXTN_INTEGRATION) {
                PaymentExtensionCalloutHelper.processPaymentExtensionResponse(results, processName, requestBody, muleRes);
            } else if(processName == Constants.DEFAULT_INTEGRATION) {
                DefaultAndTerminationCalloutHelper.processDefaultSRResponse(results, processName, requestBody, muleRes);
            } else if(processName == Constants.HANDOVER_INTEGRATION) {
                HandoverCalloutHelper.processHandoverResponse(results, processName, requestBody, muleRes);
            } else if(processName ==Constants.MILESTONE_INTEGRATION) {
                DefaultAndTerminationCalloutHelper.processInstallmentResponse(results, processName, requestBody, muleRes);
            } else if(processName ==Constants.MORTGAGE_INTEGRATION) {
                MortgageCalloutHelper.processMortgageResponse(results, processName, requestBody, muleRes);
            } else if(processName ==Constants.REBATE_REINSTATE_INTEGRATION) {
                RebateReinstateCalloutHelper.processRebateResponse(results, processName, requestBody, muleRes);
            } else if(processName ==Constants.ADM_FEE_REFUND_INTEGRATION){
                ADMFeeRefundCalloutHelper.processADMFeeRefundResponse(results, processName, requestBody, muleRes);
            } else if (processName == Constants.FREEZE_LPC_INTEGRATION) {
                LPCCalloutHelper.processLPCFreezeResponse(results, processName, requestBody, muleRes);
            }
            //Monika: Rebate Request **Start
            else if (processName == 'RebateRequest') {
                CustomRulesHelper.processRebateRequestResponse(results, processName, requestBody, muleRes);
            }
            //Monika: Rebate Request **End
        }
    }

    public void processMuleSOResponse(MuleSOResponeWrapper responseBody, String processName, Boolean processResponse, String requestBody, String muleRes){
        MuleSOResponeWrapper.MuleResponse results = responseBody.results; 
        System.debug('processName>>>' + processName);
        System.debug('processResponse>>>' + processResponse);
        System.debug('results>>>' + results);

        if (processResponse) {
            /*
             * REMOVED by SS_JSON_CHANGE to accomodate JSON format resoponse change
             * if (processName == Constants.LPC_INTEGRATION) {
                LPCCalloutHelper.processLPCResponse(results, processName, requestBody, muleRes);
            } else 
            if (processName == Constants.PROPERTY_TRANS_INTEGRATION) {
                PropertyTransferCalloutHelper.processPropertyTransferResponse(results, processName, requestBody, muleRes);
            } else
            if (processName == Constants.CANCELLATION_INTEGRATION) {
                CancellationCalloutHelper.processCancellationResponse(results, processName, requestBody, muleRes);
            } else
            if (processName == Constants.PAYMENT_PLAN_CHANGE) {
                PaymentPlanChangeCalloutHelper.processPPCResponse(results, processName, requestBody, muleRes);
            } else*/
            if (processName == Constants.OWNERSHIP_CHANGE_INTEGRATION) {
                JointOwnerR2CalloutHelper.processJointOwnerResponse(results, processName, requestBody, muleRes);
            }
        }
    }

    public MuleResponeWrapper parse(String json){
        return (MuleResponeWrapper)System.JSON.deserialize(json, MuleResponeWrapper.class);
    }

    public static MuleSOResponeWrapper soParse(String json){
         return (MuleSOResponeWrapper)System.JSON.deserialize(json, MuleSOResponeWrapper.class);
    }
    
    public static MulePOSSingleResponseWrapper posParse(String json){
        return (MulePOSSingleResponseWrapper)System.JSON.deserialize(json, MulePOSSingleResponseWrapper.class);
    }
    
    public static MulePOSResponeWrapper lpcParse(String json){
        return (MulePOSResponeWrapper)System.JSON.deserialize(json, MulePOSResponeWrapper.class);
    }
    
    public static void updateStatusAsFailed(List<Id> recordIds, String processName, String requestBody, String muleRes, String errorMessage) {
        if (!recordIds.isEmpty()) {
            String objectType = '';
            if (recordIds[0].getSObjectType() == HexaBPM__Service_Request__c.SObjectType) {
                objectType = 'HexaBPM__Service_Request__c';
            }
            
            if(String.isNotBlank(objectType)){
                List<SObject> updateSObjectList = new List<SObject>();
                List<Logger__c> loggerList = new List<Logger__c>();
                for (Id rId: recordIds) {
                    SObject updateSObject = Schema.getGlobalDescribe().get(objectType).newSObject();
                    updateSObject.put('Id', rId);
                    if (processName == Constants.FREEZE_LPC_INTEGRATION) {
                        updateSObject.put('LPCFreezeStatus__c', Constants.STATUS_FAILED);
                    } else {
                        updateSObject.put('SyncStatus__c', Constants.STATUS_FAILED);
                    }
                    updateSObject.put('ErrorReason__c', muleRes);
                    updateSObjectList.add(updateSObject);

                    Logger__c logger = LoggerService.addApexServiceCalls('CalloutToMuleSoftForSRQueueable', 'updateStatusAsFailed', processName, requestBody, muleRes, rId);
                    logger.StackTrace__c = errorMessage;
                    loggerList.add(logger);
                }
                if (!updateSObjectList.isEmpty()) {
                    update updateSObjectList;
                    insert loggerList;
                }
            }
        }
    }
}