public with sharing class PropertyTransferCalloutHelper {

    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        
        List<Id> custAccountIds = new List<Id>();
        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            if (String.isBlank(serviceRequest.BuyerName__r.ERPID__c)) {
                custAccountIds.add(serviceRequest.BuyerName__c);
            }
            for (AgencyTeam__c agencyTeam: serviceRequest.Partners__r) {
                if (String.isBlank(agencyTeam.Account__r.ERPID__c)) {
                    custAccountIds.add(agencyTeam.Account__c);
                }
            }
        }
        if (!custAccountIds.isEmpty()) {
            CustomerCalloutHelper.PrepareDataForCallout(custAccountIds, srIds, 'ServiceRequest_PropertyTransfer');
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
        Map<Id, List<SalesOrderOtherCharges__c>> otherChargeMap = new Map<Id, List<SalesOrderOtherCharges__c>>();
        for (SalesOrder__c so: salesOrderList) {
            List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
            for (SalesOrderOtherCharges__c otherCharge: so.SalesOrdersOtherCharges__r) {
                otherChargeList.add(otherCharge);
            }
            otherChargeMap.put(so.Id, otherChargeList);
        }
        
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> propTranReqList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            Map<String, Object> propTranReqMap = new Map<String, Object>();
            
            propTranReqMap.put('srSFID', serviceRequest.Id);
            propTranReqMap.put('srNumber', serviceRequest.Name);
            propTranReqMap.put('appointmentDate', serviceRequest.AppointmentDate__c != null ? date.newinstance(serviceRequest.AppointmentDate__c.year(), serviceRequest.AppointmentDate__c.month(), serviceRequest.AppointmentDate__c.day()) : null);
            propTranReqMap.put('buyerName', serviceRequest.BuyerName__r.Name);
            propTranReqMap.put('buyerSFID', serviceRequest.BuyerName__c);
            propTranReqMap.put('srCase', serviceRequest.Case__c);
            propTranReqMap.put('chargeRule', serviceRequest.ChargeRule__c);
            propTranReqMap.put('chargeToBeCollected', serviceRequest.ChargeCollected__c != null ? String.valueOf(serviceRequest.ChargeCollected__c) : '');
            propTranReqMap.put('chargeType', serviceRequest.ChargeType__c);
            propTranReqMap.put('chargeWaivedOff', serviceRequest.ChargeWaivedOff__c ? 'Y' : 'N');
            propTranReqMap.put('closedDateTime', serviceRequest.HexaBPM__Closed_Date_Time__c != null ? date.newinstance(serviceRequest.HexaBPM__Closed_Date_Time__c.year(), serviceRequest.HexaBPM__Closed_Date_Time__c.month(), serviceRequest.HexaBPM__Closed_Date_Time__c.day()) : null);
           // propTranReqMap.put('closedDateTime', serviceRequest.TransferDate__c);
            propTranReqMap.put('closedStatus', serviceRequest.HexaBPM__IsClosedStatus__c ? 'Y' : 'N');
            propTranReqMap.put('createdDate', date.newinstance(serviceRequest.CreatedDate.year(), serviceRequest.CreatedDate.month(), serviceRequest.CreatedDate.day()));
            propTranReqMap.put('customer', serviceRequest.HexaBPM__Customer__r.Name);
            propTranReqMap.put('customerSFID', serviceRequest.HexaBPM__Customer__c);
            propTranReqMap.put('exemptValidation', serviceRequest.ExemptValidations__c ? 'Y' : 'N');
            propTranReqMap.put('exemptionReason', serviceRequest.ExemptionReason__c);
            propTranReqMap.put('nextAppover', serviceRequest.NextAppover__c);
            propTranReqMap.put('parentSR', serviceRequest.HexaBPM__Parent_SR__c);
            propTranReqMap.put('paymentType', serviceRequest.PaymentType__c);
            propTranReqMap.put('recordTypeName', serviceRequest.RecordType.Name);
            propTranReqMap.put('salesOrder', serviceRequest.SalesOrder__r.Name);
            propTranReqMap.put('salesOrderSFID', serviceRequest.SalesOrder__c);
            propTranReqMap.put('srTemplate', serviceRequest.HexaBPM__SR_Template__c);
            propTranReqMap.put('srType', serviceRequest.SRType__c);
            propTranReqMap.put('status', serviceRequest.HexaBPM__External_Status_Name__c);
            propTranReqMap.put('transferSellingPrice', serviceRequest.TransferSellingPrice__c != null ? String.valueOf(serviceRequest.TransferSellingPrice__c) : '');
            propTranReqMap.put('unit', serviceRequest.Unit__c);
            propTranReqMap.put('documentPrintdate', serviceRequest.DocumentPrintedDate__c);
            propTranReqMap.put('thresholdAmount', '');
            propTranReqMap.put('transferType', serviceRequest.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT ? 'NOC' : serviceRequest.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT ? 'Plot' : serviceRequest.TransferType__c);

            List<Object> jointOwnerList = new List<Object>();
            if (!serviceRequest.Partners__r.isEmpty()) {
                for (AgencyTeam__c jo: serviceRequest.Partners__r) {
                    Map<String, Object> jointOwnerMap = new Map<String, Object>();
                    jointOwnerMap.put('sfTransferSFID', jo.Id);
                    jointOwnerMap.put('customerName', jo.Account__r.Name);
                    jointOwnerMap.put('customerSFID', jo.Account__c);
                    jointOwnerMap.put('salesOrderSFID', serviceRequest.SalesOrder__c);
                    jointOwnerMap.put('shareHoldPerc', String.valueOf(jo.ShareHoldingPercentage__c));
                    jointOwnerMap.put('relationshipType', jo.RelationshipType__c);
                    jointOwnerMap.put('srSFID', serviceRequest.Id);
                    jointOwnerList.add(jointOwnerMap);
                }
            } else {
                Map<String, Object> jointOwnerMap = new Map<String, Object>();
                    jointOwnerMap.put('sfTransferSFID', '');
                    jointOwnerMap.put('customerName', '');
                    jointOwnerMap.put('customerSFID', '');
                    jointOwnerMap.put('salesOrderSFID', '');
                    jointOwnerMap.put('shareHoldPerc', '');
                    jointOwnerMap.put('relationshipType', '');
                    jointOwnerMap.put('srSFID', '');
                    jointOwnerList.add(jointOwnerMap);
            }
            propTranReqMap.put('jointOwner', jointOwnerList);
			System.debug('otherChargeMap '+otherChargeMap);
            List<Object> othChgList = new List<Object>();
            
            if (otherChargeMap.containsKey(serviceRequest.SalesOrder__c)) {
                for (SalesOrderOtherCharges__c otherCharge: otherChargeMap.get(serviceRequest.SalesOrder__c)) {
                    if (otherCharge.ServiceRequest__c ==serviceRequest.Id && (otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_TRANSFER_FEE_CHARGE || otherCharge.TypeOfCharge__c == Constants.BUDGET_LINE_ADMFEE && otherCharge.Account__c == ServiceRequest.BuyerName__c)) {
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
            propTranReqMap.put('othChg', othChgList);

            propTranReqList.add(propTranReqMap);
        }
        finalMap.put('prpTransRq', propTranReqList);
        
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        if (!propTranReqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.PROPERTY_TRANS_INTEGRATION, srIds));
        }
    }

    public static void processPropertyTransferResponse(MulePOSSingleResponseWrapper.results results, String processName, String requestBody, String muleRes) {
        List<String> srIds = new List<String>();//To Handle Failure PT SRs - START
        //To Handle JOs - START
        List<String> soIdSet = new List<String>();
        List<String> custIdSet = new List<String>();
        Map<String, String> erpIdMap = new Map<String, String>();
        //To Handle JOs - END
        
        //To Handle SOs - START
        List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
        //To Handle SOs - END
        
        List<HexaBPM__Service_Request__c> srSuccessList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srFailedList = new List<HexaBPM__Service_Request__c>();
        List<Logger__c> loggerList = new List<Logger__c>();
        
        for (MulePOSSingleResponseWrapper.PrpTransRs responseRecord: results.prpTransRs) {
            if (responseRecord.status == Constants.MULESOFT_FAILURE){
                srIds.add(responseRecord.srSFId);
            }
        }

        Map<Id, HexaBPM__Service_Request__c> srMap = 
            new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, RetryCount__c FROM HexaBPM__Service_Request__c 
                                                      WHERE Id IN :srIds]);        
        
        for (MulePOSSingleResponseWrapper.prpTransRs responseRecord: results.prpTransRs) {
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                srRecord.Id = responseRecord.srSFId;
                srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                srRecord.ERPID__c = responseRecord.srERPId;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = 0;
                srRecord.ErrorReason__c = '';
                srSuccessList.add(srRecord);
            } else if (responseRecord.status == Constants.MULESOFT_FAILURE) {
                srRecord.Id = responseRecord.srSFId;
                srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                srRecord.SyncTime__c = Datetime.now();
                srRecord.RetryCount__c = srMap.get(responseRecord.srSFId).RetryCount__c == null ? 1 : srMap.get(responseRecord.srSFId).RetryCount__c + 1;
                srRecord.ErrorReason__c = responseRecord.errorMsg;
                srFailedList.add(srRecord);
                loggerList.add(LoggerService.addApexServiceCalls('PropertyTransferCalloutHelper', 'processPropertyTransferResponse', processName, requestBody, muleRes, responseRecord.srSFId));
            }
            
            for (MulePOSSingleResponseWrapper.PrpTransJORs responseRecord_jo : responseRecord.prpTransJORs) {
                if (String.isNotBlank(responseRecord_jo.cusERPId)) {
                    soIdSet.add(responseRecord_jo.soSFId);
                    custIdSet.add(responseRecord_jo.cusSFId);
                    erpIdMap.put(responseRecord_jo.soSFId + '_' + responseRecord_jo.cusSFId, responseRecord_jo.cusERPId);
                }
            }
            
            for (MulePOSSingleResponseWrapper.OthChgRes responseRecord_oc : responseRecord.othChgRes) {
                SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
                otherCharge.Id = responseRecord_oc.sfId;
                otherCharge.ERPID__c = responseRecord_oc.erpId;
                otherCharge.ReceivableAccount__c = responseRecord_oc.recAcct;
                otherCharge.RevenueAccount__c = responseRecord_oc.expAcct;
                otherCharge.TaxAccount__c = responseRecord_oc.taxAcct;
                otherCharge.InvoiceNumber__c = responseRecord_oc.invoiceNo;
                otherChargeList.add(otherCharge);
            }
        }
        
        List<JointOwner__c> jointOwnerList = [SELECT Id, SalesOrder__c, Account__c FROM JointOwner__c 
                                              WHERE SalesOrder__c IN: soIdSet AND Account__c IN: custIdSet];

        List<JointOwner__c> updateJointOwnerList = new List<JointOwner__c>();
        for (JointOwner__c jo: jointOwnerList) {
            if (erpIdMap.containsKey(jo.SalesOrder__c + '_' + jo.Account__c)) {
                jo.ERPID__c = erpIdMap.get(jo.SalesOrder__c + '_' + jo.Account__c);
                jo.SyncStatus__c = Constants.STATUS_SYNCED;
                updateJointOwnerList.add(jo);
            }
        }
        
        if (!updateJointOwnerList.isEmpty()) {
            update updateJointOwnerList;
        }

        if (!otherChargeList.isEmpty()) {
            update otherChargeList;
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