public with sharing class LPCCalloutHelper {

    //Used when LPC SR is closed
    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        prepareDataForCallout(serviceRequestList);
    }
    
    //Used when LPC SR is closed
    public static void prepareDataForCallout(List<HexaBPM__Service_Request__c> serviceRequestList){
        List<Id> srIds = new List<Id>();
        Map<Id, Id> srWithSalesOrdersMap = new Map<Id, Id>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            srIds.add(serviceRequest.Id);
            srWithSalesOrdersMap.put(serviceRequest.Id, serviceRequest.SalesOrder__c);
        }
        
        Map<Id, SalesOrderOtherCharges__c> soIdWithSOOtherChargesMap = new Map<Id, SalesOrderOtherCharges__c>();
        List<String> lpcStrings = new List<String>{Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES, Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT};
        for (SalesOrderOtherCharges__c soOtherCharges : [Select Id, Name, CurrencyIsoCode, SalesOrder__c, Account__c, AmountReceived__c, Amount__c, InvoiceId__c, InvoiceNumber__c, Opportunity__c, OutstandingAmountinwords__c, TypeOfCharge__c, SalesSupportCost__c, AmountWithoutVAT__c, VATAmount__c, SubType__c From SalesOrderOtherCharges__c Where SalesOrder__c in : srWithSalesOrdersMap.values() AND TypeOfCharge__c IN : lpcStrings order by CreatedDate asc]) {
            soIdWithSOOtherChargesMap.put(soOtherCharges.SalesOrder__c, soOtherCharges);
        }

        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> lpcRqList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            Map<String, Object> lpcRqMap = new Map<String, Object>();
            List<Object> othChg = new List<Object>();

            lpcRqMap.put('srSfid', serviceRequest.Id);
            lpcRqMap.put('sfSalesOrderId', serviceRequest.SalesOrder__c);
            lpcRqMap.put('sfId', serviceRequest.Id);
            lpcRqMap.put('typeOfCharge', (serviceRequest.WaivedPercentage__c == 100 ? Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT : Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES));
            lpcRqMap.put('amount', '');
            lpcRqMap.put('amountwithoutVat', '');
            lpcRqMap.put('vatAmount', '');
            lpcRqMap.put('totalLPCAmount', serviceRequest.TotalLPCAmount__c != null ? String.valueOf(serviceRequest.TotalLPCAmount__c) : '');
            lpcRqMap.put('totalLPCDue', serviceRequest.TotalLPCDue__c != null ? String.valueOf(serviceRequest.TotalLPCDue__c) : '');
            lpcRqMap.put('totalLPCCollected', serviceRequest.TotalLPCCollected__c != null ? String.valueOf(serviceRequest.TotalLPCCollected__c) : '');
            lpcRqMap.put('totalLPCWaivedAmount', serviceRequest.TotalLPCWaivedAmount__c != null ? String.valueOf(serviceRequest.TotalLPCWaivedAmount__c) : '');
            lpcRqMap.put('waivedPercentage', serviceRequest.WaivedPercentage__c != null ? String.valueOf(serviceRequest.WaivedPercentage__c) : '');
            lpcRqMap.put('waivedAmount', serviceRequest.WaivedAmount__c != null ? String.valueOf(serviceRequest.WaivedAmount__c) : '');
            lpcRqMap.put('chargesToBeCollected', serviceRequest.ChargeCollected__c != null ? String.valueOf(serviceRequest.ChargeCollected__c) : '');
            
            if(serviceRequest.WaivedPercentage__c == 100){
                lpcRqMap.put('othChg', othChg);
                lpcRqList.add(lpcRqMap);
                continue;
            } 
            Map<String, String> othChgMap = new Map<String, String>();
            if (soIdWithSOOtherChargesMap.containsKey(serviceRequest.SalesOrder__c)) {
                SalesOrderOtherCharges__c soOtherCharges = soIdWithSOOtherChargesMap.get(serviceRequest.SalesOrder__c);
                othChgMap.put('srSfid', serviceRequest.Id);
                othChgMap.put('sfId', soOtherCharges.Id);
                othChgMap.put('name', soOtherCharges.Name);
                othChgMap.put('currencyCode', soOtherCharges.CurrencyIsoCode);
                othChgMap.put('sfSalesOrderId', soOtherCharges.SalesOrder__c);
                othChgMap.put('accountId', soOtherCharges.Account__c);
                othChgMap.put('amountReceived', soOtherCharges.AmountReceived__c != null ? String.valueOf(soOtherCharges.AmountReceived__c) : '');
                othChgMap.put('amount', soOtherCharges.Amount__c != null ? String.valueOf(soOtherCharges.Amount__c) : '');
                othChgMap.put('invoiceId', soOtherCharges.InvoiceId__c);
                othChgMap.put('invoiceNumber', soOtherCharges.InvoiceNumber__c);
                othChgMap.put('opportunity', soOtherCharges.Opportunity__c);
                othChgMap.put('outAmountWords', soOtherCharges.OutstandingAmountinwords__c);
                othChgMap.put('typeOfCharge', soOtherCharges.TypeOfCharge__c);
                othChgMap.put('salesSupportCost', soOtherCharges.SalesSupportCost__c != null ? String.valueOf(soOtherCharges.SalesSupportCost__c) : '');
                othChgMap.put('installmentLine', '');
                othChgMap.put('amountWithoutVat', soOtherCharges.AmountWithoutVAT__c != null ? String.valueOf(soOtherCharges.AmountWithoutVAT__c) : '');
                othChgMap.put('vatAmount', soOtherCharges.VATAmount__c != null ? String.valueOf(soOtherCharges.VATAmount__c) : '');
                othChgMap.put('subType', soOtherCharges.SubType__c);

                lpcRqMap.put('amount', soOtherCharges.Amount__c != null ? String.valueOf(soOtherCharges.Amount__c) : '');
                lpcRqMap.put('amountwithoutVat', soOtherCharges.AmountWithoutVAT__c != null ? String.valueOf(soOtherCharges.AmountWithoutVAT__c) : '');
                lpcRqMap.put('vatAmount', soOtherCharges.VATAmount__c != null ? String.valueOf(soOtherCharges.VATAmount__c) : '');
            } else {
                othChgMap.put('srSfid', '');
                othChgMap.put('sfId', '');
                othChgMap.put('name', '');
                othChgMap.put('currencyCode', '');
                othChgMap.put('sfSalesOrderId', '');
                othChgMap.put('accountId', '');
                othChgMap.put('amountReceived', '');
                othChgMap.put('amount', '');
                othChgMap.put('invoiceId', '');
                othChgMap.put('invoiceNumber', '');
                othChgMap.put('opportunity', '');
                othChgMap.put('outAmountWords', '');
                othChgMap.put('typeOfCharge', '');
                othChgMap.put('salesSupportCost', '');
                othChgMap.put('installmentLine', '');
                othChgMap.put('amountWithoutVat', '');
                othChgMap.put('vatAmount', '');
                othChgMap.put('subType', '');
            }
            othChg.add(othChgMap);

            lpcRqMap.put('othChg', othChg);
            lpcRqList.add(lpcRqMap);
        }
        
        finalMap.put('lpcRq',lpcRqList);
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);

        if (!lpcRqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.LPC_INTEGRATION, srIds));
        }
    }

    //Used when LPC SR is closed
    public static void processLPCResponse(MulePOSResponeWrapper.Results results, String processName, String requestBody, String muleRes) {
        List<String> srIds = new List<String>();
        System.debug('## processLPCResponse');

        System.debug('**results.lpcRes**'+results.lpcRes);
        for (MulePOSResponeWrapper.LpcRes responseRecord : results.lpcRes) {
            if(responseRecord.othChgRes!=null){
                for (MulePOSResponeWrapper.OthChgRes responseRecord_oc: responseRecord.othChgRes) {
                    if (responseRecord_oc.status == Constants.MULESOFT_FAILED || responseRecord_oc.status == Constants.MULESOFT_FAILURE){
                        srIds.add(responseRecord_oc.srSFId);
                    }
                }
            }
        }
        System.debug('##** srIds -> '+srIds);
        Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, RetryCount__c FROM HexaBPM__Service_Request__c WHERE Id IN :srIds]);
        
        List<SObject> srSuccessList = new List<SObject>();
        List<HexaBPM__Service_Request__c> srFailedList = new List<HexaBPM__Service_Request__c>();
        List<Logger__c> loggerList = new List<Logger__c>();
        
        for (MulePOSResponeWrapper.LpcRes responseRecord : results.lpcRes) {
            
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
            if(responseRecord.othChgRes!=null){
                for (MulePOSResponeWrapper.OthChgRes responseRecord_oc: responseRecord.othChgRes) {
                    SalesOrderOtherCharges__c soOtherCharges = new SalesOrderOtherCharges__c();
                    if (responseRecord_oc.status == Constants.MULESOFT_SUCCESS) {
                       if(responseRecord.srSfid <> '' && responseRecord.srSfid <> null && validateId(responseRecord.srSfid)){
						    srRecord.Id = responseRecord_oc.srSFId;
                            srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                            srRecord.ERPID__c = responseRecord_oc.erpId;
                            srRecord.SyncTime__c = Datetime.now();
                            srRecord.RetryCount__c = 0;
                            srRecord.ErrorReason__c = '';
                            srSuccessList.add(srRecord);
                       }
                        soOtherCharges.Id = responseRecord_oc.sfId;
                        soOtherCharges.ERPID__c = responseRecord_oc.erpId;
                        soOtherCharges.InvoiceNumber__c = responseRecord_oc.invoiceNo;
                        srSuccessList.add(soOtherCharges);
                        
                    } else {
                      if(responseRecord.srSfid <> '' && responseRecord.srSfid <> null && validateId(responseRecord.srSfid)){
							srRecord.Id = responseRecord_oc.srSFId;
                            srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                            srRecord.SyncTime__c = Datetime.now();
                            
                            srRecord.RetryCount__c = srMap.get(responseRecord_oc.srSFId).RetryCount__c == null ? 1 : srMap.get(responseRecord_oc.srSFId).RetryCount__c + 1;
                            srRecord.ErrorReason__c = responseRecord_oc.errorMsg;
                            srFailedList.add(srRecord);
                      }
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord_oc.srSFId));
                    }
                }
            } else {
                //if(responseRecord.othChgRes==null)
                System.debug('### responseRecord.status -> '+responseRecord.status);
                if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                  if(responseRecord.srSfid <> '' && responseRecord.srSfid <> null && validateId(responseRecord.srSfid)){
                        srRecord.Id = responseRecord.srSfid;
                        srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                        srRecord.ERPID__c = responseRecord.erpId;
                        srRecord.SyncTime__c = Datetime.now();
                        srRecord.RetryCount__c = 0;
                        srRecord.ErrorReason__c = '';
                        srSuccessList.add(srRecord);
                  }
                } else {
                   if(responseRecord.srSfid <> '' && responseRecord.srSfid <> null && validateId(responseRecord.srSfid)){
                        srRecord.Id = responseRecord.srSfid;
                        srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                        srRecord.SyncTime__c = Datetime.now();
                        srRecord.RetryCount__c = srMap.get(responseRecord.srSfid).RetryCount__c == null ? 1 : srMap.get(responseRecord.srSfid).RetryCount__c + 1;
                        srRecord.ErrorReason__c = responseRecord.errorMsg;
                        srFailedList.add(srRecord);
                        loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord.srSfid)); 
                       }
                }
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
    
    //Used when LPC SR is Submitted or Approved
    public static void getDataForFreezeCallout(List<Id> srIds, Boolean firstCall) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        prepareDataForFreezeCallout(serviceRequestList, firstCall);
    }

    //Used when LPC SR is Submitted or Approved
    public static void prepareDataForFreezeCallout(List<HexaBPM__Service_Request__c> serviceRequestList, Boolean firstCall){
        Map<Id, Id> salesOrdersWithSRMap = new Map<Id, Id>();
        List<String> srIds = new List<String>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            salesOrdersWithSRMap.put(serviceRequest.SalesOrder__c ,serviceRequest.Id);
            srIds.add(serviceRequest.Id);
        }

        Map<Id, List<InstallmentLines__c>> soIdWithInstallmentsListMap = new Map<Id, List<InstallmentLines__c>>();

        Map<String, List<Object>> finalMap = new Map<String, List<Object>>();
        finalMap.put('lpcwfRq', new List<Object>());

        for (InstallmentLines__c ilRecord : [Select Id, InstallmentNumber__c, LPCFreezeDate__c, LPCFreezeUntilDate__c, SalesOrder__c, SyncStatus__c, SyncTime__c, InvoiceNumber__c From InstallmentLines__c Where SalesOrder__c in : salesOrdersWithSRMap.keySet() AND InvoiceNumber__c != null order by InstallmentNumber__c asc]) {
            
            if(firstCall){
                Map<String,String> ilRequest = new Map<String,String>();
                ilRequest.put('srSfid',salesOrdersWithSRMap.get(ilRecord.SalesOrder__c));
                ilRequest.put('sfSalesOrderId',ilRecord.SalesOrder__c);
                ilRequest.put('instNum',ilRecord.InstallmentNumber__c + '');
                ilRequest.put('lpcFreezeDate',ilRecord.LPCFreezeDate__c != null ? DateTime.newInstance(ilRecord.LPCFreezeDate__c.year(), ilRecord.LPCFreezeDate__c.month(), ilRecord.LPCFreezeDate__c.day()).format('yyyy-MM-dd') : '');
                ilRequest.put('lpcFreezeUntilDate',ilRecord.LPCFreezeUntilDate__c != null ? DateTime.newInstance(ilRecord.LPCFreezeUntilDate__c.year(), ilRecord.LPCFreezeUntilDate__c.month(), ilRecord.LPCFreezeUntilDate__c.day()).format('yyyy-MM-dd') : '');
    
                finalMap.get('lpcwfRq').add(ilRequest);
            } else if(!firstCall && ilRecord.SyncStatus__c == Constants.STATUS_FAILED){
                Map<String,String> ilRequest = new Map<String,String>();
                ilRequest.put('srSfid',salesOrdersWithSRMap.get(ilRecord.SalesOrder__c));
                ilRequest.put('sfSalesOrderId',ilRecord.SalesOrder__c);
                ilRequest.put('instNum',ilRecord.InstallmentNumber__c + '');
                ilRequest.put('lpcFreezeDate',ilRecord.LPCFreezeDate__c != null ? DateTime.newInstance(ilRecord.LPCFreezeDate__c.year(), ilRecord.LPCFreezeDate__c.month(), ilRecord.LPCFreezeDate__c.day()).format('yyyy-MM-dd') : '');
                ilRequest.put('lpcFreezeUntilDate',ilRecord.LPCFreezeUntilDate__c != null ? DateTime.newInstance(ilRecord.LPCFreezeUntilDate__c.year(), ilRecord.LPCFreezeUntilDate__c.month(), ilRecord.LPCFreezeUntilDate__c.day()).format('yyyy-MM-dd') : '');

                finalMap.get('lpcwfRq').add(ilRequest);
            }
            
        }

        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);

        if (!finalMap.get('lpcwfRq').isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.FREEZE_LPC_INTEGRATION, srIds));
        } else {
            List<Id> serviceRequestsIdsList = new List<Id>();
            for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
                serviceRequestsIdsList.add(serviceRequest.Id);
            }
            updateSRs(serviceRequestsIdsList);
        }
    }

    @future
    public static void updateSRs(List<Id> serviceRequestsIdsList) {
        List<HexaBPM__Service_Request__c> serviceRequestList = new List<HexaBPM__Service_Request__c>();

        for(Id srId : serviceRequestsIdsList){
            HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c(Id=srId);
            serviceRequest.LPCFreezeStatus__c = Constants.STATUS_SYNCED;
            serviceRequest.SyncTime__c = Datetime.now();
            serviceRequest.ErrorReason__c = 'No Installments Available for LPC Freeze Call.';
            serviceRequestList.add(serviceRequest);
        }
        update serviceRequestList;
    }

    //Used when LPC SR is Submitted or Approved
    public static void processLPCFreezeResponse(List<MuleResponeWrapper.MuleResponse> results, String processName, String requestBody, String muleRes) {
        List<String> srIds = new List<String>();
        List<String> soIds = new List<String>();

        Map<String, InstallmentLines__c> salesorder_InstNumberWithInstRecord = new Map<String, InstallmentLines__c>();

        System.debug('**results**'+results);
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            if (responseRecord.status == Constants.MULESOFT_FAILED || responseRecord.status == Constants.MULESOFT_FAILURE){
                srIds.add(responseRecord.srSfid);
            }
            soIds.add(responseRecord.sfSalesorderId);
        }
        Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, RetryCount__c FROM HexaBPM__Service_Request__c WHERE Id IN :srIds]);

        for (InstallmentLines__c ilRecord : [Select Id, InstallmentNumber__c, SyncStatus__c, SyncTime__c, RetryCount__c, ErrorReason__c, SalesOrder__c From InstallmentLines__c Where SalesOrder__c in : soIds order by InstallmentNumber__c asc]) {
            salesorder_InstNumberWithInstRecord.put(ilRecord.SalesOrder__c + '_' + ilRecord.InstallmentNumber__c, ilRecord);
        }
        System.debug('**salesorder_InstNumberWithInstRecord**'+salesorder_InstNumberWithInstRecord);

        Map<Id,SObject> srSuccessList = new Map<Id, SObject>();
        Map<Id,SObject> srFailedList = new Map<Id, SObject>();
        List<Logger__c> loggerList = new List<Logger__c>();
        for (MuleResponeWrapper.MuleResponse responseRecord: results) {
            System.debug('$$$ applicationName >>> '+responseRecord.srSfid);
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
            InstallmentLines__c ilRecord = salesorder_InstNumberWithInstRecord.get(responseRecord.sfSalesorderId + '_' + responseRecord.instNum);

            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                 if(responseRecord.srSfid <> '' && responseRecord.srSfid <> null && validateId(responseRecord.srSfid)){
				    srRecord.Id = responseRecord.srSfid;
                    srRecord.LPCFreezeStatus__c = Constants.STATUS_SYNCED;
                    srRecord.SyncTime__c = Datetime.now();
                    srRecord.RetryCount__c = 0;
                    srRecord.ErrorReason__c = '';
                    srSuccessList.put(srRecord.Id, srRecord);
               }
                if(ilRecord != null){
                    ilRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                    ilRecord.SyncTime__c = Datetime.now();
                    ilRecord.RetryCount__c = 0;
                    ilRecord.ErrorReason__c = '';
                    ilRecord.LPCFreezeDateSyncStatus__c = Constants.STATUS_SYNCED;
                    srSuccessList.put(ilRecord.Id, ilRecord);
                }
            } else if (responseRecord.status == Constants.MULESOFT_FAILED || responseRecord.status == Constants.MULESOFT_FAILURE) {
                if(responseRecord.srSfid <> '' && responseRecord.srSfid <> null && validateId(responseRecord.srSfid)){
                    srRecord.Id = responseRecord.srSfid;
                    srRecord.LPCFreezeStatus__c = Constants.STATUS_FAILED;
                    srRecord.SyncTime__c = Datetime.now();
                    srRecord.RetryCount__c = srMap.get(responseRecord.srSfid).RetryCount__c == null ? 1 : srMap.get(responseRecord.srSfid).RetryCount__c + 1;
                    srRecord.ErrorReason__c = responseRecord.errorMsg;
                    srFailedList.put(srRecord.Id, srRecord);
                }
                if(ilRecord != null){
                    ilRecord.SyncStatus__c = Constants.STATUS_FAILED;
                    ilRecord.SyncTime__c = Datetime.now();
                    ilRecord.LPCFreezeDateSyncStatus__c =  Constants.STATUS_FAILED;
                    ilRecord.RetryCount__c = ilRecord.RetryCount__c == null ? 1 : ilRecord.RetryCount__c + 1;
                    ilRecord.ErrorReason__c = responseRecord.errorMsg;
                    srFailedList.put(ilRecord.Id, ilRecord);
                }

                loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord.srSfid));
            }
        }
        if (!srSuccessList.isEmpty()) {
            update srSuccessList.values();
        }
        
        if (!srFailedList.isEmpty()) {
            update srFailedList.values();
            if (!loggerList.isEmpty()) {
                insert loggerList;
            }
        }
    }
    //Helps in sync IL data from SF to ERP
    public static void prepareDataForERPSync(List<InstallmentLines__c> updatedInstallmentLineList){
        System.debug('## prepareDataForERPSync > ');
        Set<String> SyncObjectIds = new Set<String>();
        Map<String, List<Object>> finalMap = new Map<String, List<Object>>();
        finalMap.put('lpcwfRq', new List<Object>());

        for (InstallmentLines__c ilRecord : [Select Id, InstallmentNumber__c, LPCFreezeDate__c, LPCFreezeUntilDate__c, SalesOrder__c, SyncStatus__c, SyncTime__c, InvoiceNumber__c From InstallmentLines__c Where Id IN :updatedInstallmentLineList AND InvoiceNumber__c != null order by InstallmentNumber__c asc]) {
            
                Map<String,String> ilRequest = new Map<String,String>();
                ilRequest.put('srSfid','STANDALONE');
                ilRequest.put('sfSalesOrderId',ilRecord.SalesOrder__c);
                ilRequest.put('instNum',ilRecord.InstallmentNumber__c + '');
                ilRequest.put('lpcFreezeDate',ilRecord.LPCFreezeDate__c != null ? DateTime.newInstance(ilRecord.LPCFreezeDate__c.year(), ilRecord.LPCFreezeDate__c.month(), ilRecord.LPCFreezeDate__c.day()).format('yyyy-MM-dd') : '');
                ilRequest.put('lpcFreezeUntilDate',ilRecord.LPCFreezeUntilDate__c != null ? DateTime.newInstance(ilRecord.LPCFreezeUntilDate__c.year(), ilRecord.LPCFreezeUntilDate__c.month(), ilRecord.LPCFreezeUntilDate__c.day()).format('yyyy-MM-dd') : '');

                finalMap.get('lpcwfRq').add(ilRequest);
                SyncObjectIds.add(ilRecord.Id);
            
        }

        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);

        if (!finalMap.get('lpcwfRq').isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.FREEZE_LPC_INTEGRATION, new List<String>(SyncObjectIds)));
        } 
    }
    public static Boolean validateId(String Idparam) {
        String id = String.escapeSingleQuotes(Idparam);
        return ((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id));

    }
}