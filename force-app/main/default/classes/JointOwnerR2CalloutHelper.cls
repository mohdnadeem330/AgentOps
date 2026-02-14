public with sharing class JointOwnerR2CalloutHelper {

    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        List<Id> custAccountIds = new List<Id>();
        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            for (AgencyTeam__c agencyTeam: serviceRequest.Partners__r) {
                if (String.isBlank(agencyTeam.Account__r.ERPID__c)) {
                    custAccountIds.add(agencyTeam.Account__c);
                }
            }
        }
        if (!custAccountIds.isEmpty()) {
            CustomerCalloutHelper.PrepareDataForCallout(custAccountIds, srIds, 'ServiceRequest_JointOwner');
        } else {
            prepareDataForCallout(serviceRequestList);
        }
    }
    
    public static void prepareDataForCallout(List<HexaBPM__Service_Request__c> serviceRequestList){
        List<Id> srIds = new List<Id>();
        List<Id> salesOrderIds = new List<Id>();
        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            srIds.add(serviceRequest.Id);
            salesOrderIds.add(serviceRequest.SalesOrder__c);
        }

        List<SalesOrder__c> salesOrderList = SalesOrderService.queryAllFieldsWithExtraFields(salesOrderIds);
        Map<String, List<SalesOrderOtherCharges__c>> otherChargeMap = new Map<String, List<SalesOrderOtherCharges__c>>();
        Map<String, JointOwner__c> jointOwnerMap = new Map<String, JointOwner__c>();
        for (SalesOrder__c so: salesOrderList) {
            List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
            for (SalesOrderOtherCharges__c otherCharge: so.SalesOrdersOtherCharges__r) {
                if (otherChargeMap.containsKey(so.Id + '_' + otherCharge.Account__c)) {
                    if (otherCharge.TypeOfCharge__c == Constants.BUDGET_LINE_ADMFEE || otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_OWNERSHIP_CHANGE) {
                        otherChargeList = otherChargeMap.get(so.Id + '_' + otherCharge.Account__c);
                        otherChargeList.add(otherCharge);
                        otherChargeMap.put(so.Id + '_' + otherCharge.Account__c, otherChargeList);
                    }
                } else if (otherCharge.TypeOfCharge__c == Constants.BUDGET_LINE_ADMFEE || otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_OWNERSHIP_CHANGE) { 
                    otherChargeList = new List<SalesOrderOtherCharges__c>();
                    otherChargeList.add(otherCharge);
                    otherChargeMap.put(so.Id + '_' + otherCharge.Account__c, otherChargeList);
                }
            }

            for (JointOwner__c jointOwner: so.Joint_OwnersSalesOrder__r) {
                if (!jointOwner.IsDeleted__c) {
                    jointOwnerMap.put(so.Id + '_' + jointOwner.Account__c, jointOwner);
                }
            }
        }
        system.debug('jointOwnerMap>>>' + jointOwnerMap);
        
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> jointOwnerReqList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            for (AgencyTeam__c agencyTeam: serviceRequest.Partners__r) {
                if (agencyTeam.RelationshipType__c == Constants.PRIMARY_OWNER || (agencyTeam.JointOwner__c != null && agencyTeam.ShareHoldingPercentage__c == 0)) {
                    continue;
                }
                Map<String, Object> jointOwnerReqMap = new Map<String, Object>();

                String recordMode;
                if (agencyTeam.Description__c == Constants.PRIMARY_OWNER) {
                    recordMode = Constants.MULESOFT_OWNERSHIP_MODE;
                } else if (agencyTeam.JointOwner__c == null) {
                    recordMode = Constants.MULESOFT_CREATE_MODE;
                } else {
                    recordMode = Constants.MULESOFT_SHAREHOLD_MODE;
                }
                JointOwner__c joRecord = new JointOwner__c();
                if (jointOwnerMap.containsKey(serviceRequest.SalesOrder__c + '_' + agencyTeam.Account__c)) {
                    joRecord = jointOwnerMap.get(serviceRequest.SalesOrder__c + '_' + agencyTeam.Account__c);
                }
                jointOwnerReqMap.put('mode', recordMode);
                jointOwnerReqMap.put('salesOrderId', serviceRequest.SalesOrder__r.ERPID__c);
                jointOwnerReqMap.put('partyId', agencyTeam.Account__r.ERPID__c);
                jointOwnerReqMap.put('custAccountId', '');
                jointOwnerReqMap.put('jointOwnerId', joRecord.ERPID__c);
                jointOwnerReqMap.put('sharePercentage', agencyTeam.ShareHoldingPercentage__c != null ? String.valueOf(agencyTeam.ShareHoldingPercentage__c) : '');
                jointOwnerReqMap.put('createdByUser', serviceRequest.CreatedBy.Email);
                jointOwnerReqMap.put('sfId', joRecord.Id);
                jointOwnerReqMap.put('relationshipCode', agencyTeam.RelationshipType__c);
                jointOwnerReqMap.put('srSfid', serviceRequest.Id);
                jointOwnerReqMap.put('srType', serviceRequest.SRType__c);
                
                List<Object> othChgList = new List<Object>();
                if (otherChargeMap.containsKey(serviceRequest.SalesOrder__c + '_' + agencyTeam.Account__c)) {
                    for (SalesOrderOtherCharges__c otherCharge: otherChargeMap.get(serviceRequest.SalesOrder__c + '_' + agencyTeam.Account__c)) {
                        Map<String, Object> othChgMap = new Map<String, Object>();

                        othChgMap.put('srSfid', serviceRequest.Id);
                        othChgMap.put('sfId', otherCharge.Id);
                        othChgMap.put('name', otherCharge.Name);
                        othChgMap.put('currencyCode', otherCharge.CurrencyIsoCode);
                        othChgMap.put('sfSalesOrderId', otherCharge.SalesOrder__c);
                        othChgMap.put('accountId', otherCharge.Account__c);
                        othChgMap.put('amountReceived', otherCharge.AmountReceived__c != null ? String.valueOf(otherCharge.AmountReceived__c) : '');
                        othChgMap.put('amount', otherCharge.Amount__c != null ? String.valueOf(otherCharge.Amount__c) : '');
                        othChgMap.put('invoiceId', otherCharge.InvoiceId__c);
                        othChgMap.put('invoiceNumber', otherCharge.InvoiceNumber__c);
                        othChgMap.put('opportunity', otherCharge.Opportunity__c);
                        othChgMap.put('outAmountWords', otherCharge.OutstandingAmountinwords__c);
                        othChgMap.put('typeOfCharge', otherCharge.TypeOfCharge__c);
                        othChgMap.put('salesSupportCost', otherCharge.SalesSupportCost__c != null ? String.valueOf(otherCharge.SalesSupportCost__c) : '');
                        othChgMap.put('installmentLine', '');
                        othChgMap.put('amountWithoutVat', otherCharge.AmountWithoutVAT__c != null ? String.valueOf(otherCharge.AmountWithoutVAT__c) : '');
                        othChgMap.put('vatAmount', otherCharge.VATAmount__c != null ? String.valueOf(otherCharge.VATAmount__c) : '');
                        othChgMap.put('subType', otherCharge.SubType__c);

                        othChgList.add(othChgMap);
                    }
                } else {
                    Map<String, Object> othChgMap = new Map<String, Object>();

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

                    othChgList.add(othChgMap);
                }
                jointOwnerReqMap.put('othChg', othChgList);

                jointOwnerReqList.add(jointOwnerReqMap);
            }
        }
        finalMap.put('ownershipDetails', jointOwnerReqList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!jointOwnerReqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.OWNERSHIP_CHANGE_INTEGRATION, srIds));
        }
    }

    public static void processJointOwnerResponse(MuleSOResponeWrapper.MuleResponse results, String processName, String requestBody, String muleRes) {
        List<String> srIds = new List<String>();
        for (MuleSOResponeWrapper.SOResponse responseRecord: results.ownershipChangeResp) {
            if (responseRecord.status == Constants.MULESOFT_FAILURE){
                srIds.add(responseRecord.srSFId);
            }
        }
        Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, RetryCount__c FROM HexaBPM__Service_Request__c WHERE Id IN :srIds]);

        List<HexaBPM__Service_Request__c> srSuccessList = new List<HexaBPM__Service_Request__c>();
        List<JointOwner__c> joSuccessList = new List<JointOwner__c>();
        List<HexaBPM__Service_Request__c> srFailedList = new List<HexaBPM__Service_Request__c>();
        List<Logger__c> loggerList = new List<Logger__c>();
        Set<Id> srSFIds = new Set<Id>();
        Set<Id> joIds = new Set<Id>();
        for (MuleSOResponeWrapper.SOResponse responseRecord: results.ownershipChangeResp) {
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                if (!srSFIds.contains(responseRecord.srSFId)) {
                    srRecord.Id = responseRecord.srSFId;
                    srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                    srRecord.SyncTime__c = Datetime.now();
                    srRecord.RetryCount__c = 0;
                    srRecord.ErrorReason__c = '';
                    srSuccessList.add(srRecord);
                    srSFIds.add(responseRecord.srSFId);
                }

                if (!joIds.contains(responseRecord.sfId)) {
                    JointOwner__c joRecord = new JointOwner__c();
                    joRecord.Id = responseRecord.sfId;
                    joRecord.ERPID__c = responseRecord.jointOwnerId;
                    joRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                    joRecord.SyncTime__c = Datetime.now();
                    joRecord.RetryCounter__c = 0;
                    joRecord.ErrorResponse__c = '';
                    joSuccessList.add(joRecord);
                    joIds.add(responseRecord.sfId);
                }
            } else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                if (!srSFIds.contains(responseRecord.srSFId)) {
                    srRecord.Id = responseRecord.srSFId;
                    srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                    srRecord.SyncTime__c = Datetime.now();
                    srRecord.RetryCount__c = srMap.get(responseRecord.srSFId).RetryCount__c == null ? 1 : srMap.get(responseRecord.srSFId).RetryCount__c + 1;
                    srRecord.ErrorReason__c = responseRecord.errorMsg;
                    srFailedList.add(srRecord);
                    srSFIds.add(responseRecord.srSFId);
                }
                loggerList.add(LoggerService.addApexServiceCalls('JointOwnerR2CalloutHelper', 'processJointOwnerResponse', processName, requestBody, muleRes, responseRecord.srSFId));
            }
        }
        List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
        Set<Id> otherchargeIds = new Set<Id>();
        for (MuleSOResponeWrapper.SOResponse responseRecord : results.othChgRes) {
            if (!otherchargeIds.contains(responseRecord.sfId)) {
                SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
                otherCharge.Id = responseRecord.sfId;
                otherCharge.ERPID__c = responseRecord.erpId;
                otherCharge.ReceivableAccount__c = responseRecord.recAcct;
                otherCharge.RevenueAccount__c = responseRecord.expAcct;
                otherCharge.TaxAccount__c = responseRecord.taxAcct;
                otherCharge.InvoiceNumber__c = responseRecord.invoiceNo;
                otherChargeList.add(otherCharge);
                otherchargeIds.add(responseRecord.sfId);
            }
        }
        if (!otherChargeList.isEmpty()) {
            update otherChargeList;
        }

        if (!joSuccessList.isEmpty()) {
            update joSuccessList;
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