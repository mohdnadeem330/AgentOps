public with sharing class PaymentPlanChangeCalloutHelper {	

    public static void getDataForCallout(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        prepareDataForCallout(serviceRequestList);
    }
    
    public static void prepareDataForCallout(List<HexaBPM__Service_Request__c> serviceRequestList){
        List<Id> srIds = new List<Id>();
        Map<Id, Id> srWithSalesOrdersMap = new Map<Id, Id>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            srIds.add(serviceRequest.Id);
            srWithSalesOrdersMap.put(serviceRequest.Id, serviceRequest.SalesOrder__c);
        }
        
        List<SalesOrder__c> SalesOrders = SalesOrderService.queryAllFieldsWithExtraFields(srWithSalesOrdersMap.values());
        Map<Id, SalesOrder__c> soIdWithrecordMap = new Map<Id, SalesOrder__c>();

        for (SalesOrder__c so : SalesOrders) {
            soIdWithrecordMap.put(so.Id, so);
        }

        Map<Id, List<InstallmentLines__c>> soIdWithInstallmentLinesMap = new Map<Id, List<InstallmentLines__c>>();

        for (InstallmentLines__c ilRecords : [Select Id, SalesOrder__c, PaymentPlan__c, PaymentPlan__r.Name, ERPID__c, InstallmentNumber__c, InstallmentPercentage__c, BrokerPayoutPercentage__c, InstallmentAmount__c, InstallmentDate__c, Description__c, CreatedById, OriginalCreationDate__c, RTOStartDate__c, RTOEndDate__c, RTOPaymentFrequency__c, RTOOptionFeeTaxCode__c, ActiveTenancyYear__c, SyncStatus__c From InstallmentLines__c Where SalesOrder__c =: srWithSalesOrdersMap.values() Order By InstallmentNumber__c asc]) {
            if(soIdWithInstallmentLinesMap.get(ilRecords.SalesOrder__c) == null){
                soIdWithInstallmentLinesMap.put(ilRecords.SalesOrder__c, new List<InstallmentLines__c>{ilRecords});
            } else {
                soIdWithInstallmentLinesMap.get(ilRecords.SalesOrder__c).add(ilRecords);
            }
        }

        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> pmtPlanRqList = new List<Object>();

        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            Map<String, Object> pmtPlanRqMap = new Map<String, Object>();
            List<Object> instLinesList = new List<Object>();

            SalesOrder__c soRecord = soIdWithrecordMap.get(serviceRequest.SalesOrder__c);

            pmtPlanRqMap.put('actionMode', 'UPDATE');
            pmtPlanRqMap.put('sfSalesOrderNum', serviceRequest.SalesOrder__c);
            pmtPlanRqMap.put('leadNumber', null);
            pmtPlanRqMap.put('locationCode', serviceRequest.Unit__r.Name);
            pmtPlanRqMap.put('currencyCode', 'AED');
            pmtPlanRqMap.put('orderStatus', 'Sold');
            pmtPlanRqMap.put('orderSubStatus', null);
            pmtPlanRqMap.put('saleEvent', 'Launch');
            pmtPlanRqMap.put('partyId', null);
            pmtPlanRqMap.put('orderDate', soRecord.BookingDate__c != null ? DateTime.newInstance( soRecord.BookingDate__c.year(), soRecord.BookingDate__c.month(),soRecord.BookingDate__c.day()).format('yyyy-MM-dd') : '' +'');
            pmtPlanRqMap.put('remarks', soRecord.Remarks__c);
            pmtPlanRqMap.put('inventoryCategory', soRecord.UnitInventoryCategory__c);
            pmtPlanRqMap.put('saleType', soRecord.OpportunitySaleType__c);
            pmtPlanRqMap.put('dealType', soRecord.OpportunityDealType__c);
            pmtPlanRqMap.put('unitFinishing', soRecord.UnitFinishing__c);
            pmtPlanRqMap.put('bookingType', soRecord.OpportunityBookingType__c);
            pmtPlanRqMap.put('measuredArea', soRecord.MeasuredArea__c);
            pmtPlanRqMap.put('referralType', soRecord.ReferralType__c);
            pmtPlanRqMap.put('employeeName', soRecord.EmployeeName__c);
            pmtPlanRqMap.put('brokerAgency', soRecord.OpportunityBrokerAgencyAccount__c);
            pmtPlanRqMap.put('brokeragent', soRecord.OpportunityBrokerAgentContactName__c);
            pmtPlanRqMap.put('sellingPrice', soRecord.SellingPrice__c + '');
            pmtPlanRqMap.put('multiPurRoomAmt', soRecord.MultipleRoomAmount__c+'');
            pmtPlanRqMap.put('premiumAmount', soRecord.PremiumAmount__c+'');
            pmtPlanRqMap.put('corporateDiscount', soRecord.CorporateDiscount__c + '');
            pmtPlanRqMap.put('bulkDiscount', soRecord.BulkDiscount__c+ '');
            pmtPlanRqMap.put('paytermDiscount', null);
            pmtPlanRqMap.put('discount', soRecord.Discount__c+ '');
            pmtPlanRqMap.put('netAmount', soRecord.NetAmount__c+ '');
            pmtPlanRqMap.put('taxableAmount', soRecord.TaxableAmount__c+ '');
            pmtPlanRqMap.put('amountPayable', soRecord.AmountPayable__c+ '');
            pmtPlanRqMap.put('otherRebateAmt', soRecord.OtherRebateAmount__c+ '');
            pmtPlanRqMap.put('admFeeAmount', soRecord.ADMFeeAmount__c+'');
            pmtPlanRqMap.put('admFeePercent', soRecord.ADMPercentage__c+ '');
            pmtPlanRqMap.put('contractIssuedDate', soRecord.ContractIssuedDate__c != null ? DateTime.newInstance( soRecord.ContractIssuedDate__c.year(), soRecord.ContractIssuedDate__c.month(),soRecord.ContractIssuedDate__c.day()).format('yyyy-MM-dd') : '' +'');
            pmtPlanRqMap.put('contractFinalDeliveryDate', soRecord.ContractFinalDeliveryDate__c != null ? DateTime.newInstance( soRecord.ContractFinalDeliveryDate__c.year(), soRecord.ContractFinalDeliveryDate__c.month(),soRecord.ContractFinalDeliveryDate__c.day()).format('yyyy-MM-dd') : '' +'');
            pmtPlanRqMap.put('email', soRecord.Email__c);
            pmtPlanRqMap.put('phoneNumber', soRecord.MobileNumber__c);
            pmtPlanRqMap.put('holdFlag', soRecord.HoldFlag__c != null && soRecord.HoldFlag__c == true ? 'Y' : 'N');
            pmtPlanRqMap.put('defaultStatus', soRecord.DefaultStatus__c);
            pmtPlanRqMap.put('createdbyid', soRecord.CreatedById);
            pmtPlanRqMap.put('createddate', soRecord.OriginalCreationDate__c != null ? DateTime.newInstance( soRecord.OriginalCreationDate__c.year(), soRecord.OriginalCreationDate__c.month(),soRecord.OriginalCreationDate__c.day()).format('yyyy-MM-dd') : '' +'');
            pmtPlanRqMap.put('vatTaxCode', soRecord.VATTaxCode__c);
            pmtPlanRqMap.put('vatRate', soRecord.VATRate__c+ '');
            pmtPlanRqMap.put('lastInstallmentRebate', soRecord.LastInstallmentRebate__c+'');
            pmtPlanRqMap.put('additionalRebate', soRecord.AdditionalRebate__c+ '');
            pmtPlanRqMap.put('additionalRebate2', soRecord.AdditionalRebate2__c+ '');
            pmtPlanRqMap.put('admFeeWaivedAmount', soRecord.ADMFeeWaivedAmount__c+'');
            pmtPlanRqMap.put('originalSellingPrice', soRecord.RTOOriginalSellingPrice__c+ '');
            pmtPlanRqMap.put('corporatePartner', null);
            pmtPlanRqMap.put('mortgageBank', soRecord.MortgageBank__c);
            pmtPlanRqMap.put('subsidyYears', soRecord.SubsidyYears__c+ '');
            pmtPlanRqMap.put('subsidyAmount', soRecord.SubsidyAmount__c+ '');
            pmtPlanRqMap.put('homeMaintWaivedYears', soRecord.HomeMaintenanceWaivedYears__c+ '');
            pmtPlanRqMap.put('homeMaintenaceAmt', null);
            pmtPlanRqMap.put('ssYasParksAmt', null);
            pmtPlanRqMap.put('ssArtMembershipAmt', null);
            pmtPlanRqMap.put('admWaivePercent', soRecord.ADMWaivedPercentage__c+ '');
            pmtPlanRqMap.put('srvChgWaivedYrs', soRecord.ServiceChargeWaivedYears__c+'');
            pmtPlanRqMap.put('custContactVerifyFlag', null);
            pmtPlanRqMap.put('erpSalesOrderId', soRecord.ERPID__c);
            pmtPlanRqMap.put('cancelledBy', soRecord.SalesOrderCancelledby__c);
            pmtPlanRqMap.put('cancelDate', soRecord.SalesOrderCancelledDate__c != null ? DateTime.newInstance( soRecord.SalesOrderCancelledDate__c.year(), soRecord.SalesOrderCancelledDate__c.month(),soRecord.SalesOrderCancelledDate__c.day()).format('yyyy-MM-dd') : '' +'');
            pmtPlanRqMap.put('cancelReason', soRecord.SalesOrderCancellationReason__c);
            pmtPlanRqMap.put('adminRemarks', soRecord.Remarks__c);
            pmtPlanRqMap.put('allInstProvided', null);
            pmtPlanRqMap.put('downpayStatus', null);
            pmtPlanRqMap.put('blockingCustomer', null);
            pmtPlanRqMap.put('brokerCommStatus', null);
            pmtPlanRqMap.put('contractSignedByCust', null);
            pmtPlanRqMap.put('isHeaderChange', 'Y');
            pmtPlanRqMap.put('isLinesChange', 'Y');
            pmtPlanRqMap.put('isSaleConChange', 'N');
            pmtPlanRqMap.put('isOtherChrgChange', 'N');
            pmtPlanRqMap.put('isPromotionChange', 'N');
            pmtPlanRqMap.put('oppertunityId', soRecord.Opportunity__c);
            pmtPlanRqMap.put('servicechargewaivedamount', soRecord.ServiceChargeWaivedAmount__c + '');
            pmtPlanRqMap.put('darnaamount', soRecord.DARNAAmount__c+ '');
            pmtPlanRqMap.put('unitFurnishing', soRecord.UnitFurnishing__c);
            pmtPlanRqMap.put('designType', soRecord.DesignType__c);
            pmtPlanRqMap.put('paytermClassification', null);
            pmtPlanRqMap.put('approvePendingDate', soRecord.ApprovePendingDate__c != null ? DateTime.newInstance( soRecord.ApprovePendingDate__c.year(), soRecord.ApprovePendingDate__c.month(),soRecord.ApprovePendingDate__c.day()).format('yyyy-MM-dd') : '' +'');
            pmtPlanRqMap.put('salesApprovedDate', soRecord.SalesApprovedDate__c != null ? DateTime.newInstance( soRecord.SalesApprovedDate__c.year(), soRecord.SalesApprovedDate__c.month(),soRecord.SalesApprovedDate__c.day()).format('yyyy-MM-dd') : '' +'');
            pmtPlanRqMap.put('businessUnitId', null);
            pmtPlanRqMap.put('admFlag', 'N');
            pmtPlanRqMap.put('podType', '');
            pmtPlanRqMap.put('podAmount', '');
            pmtPlanRqMap.put('designPremiumAmount', soRecord.DesignPremiumAmount__c+'');
            pmtPlanRqMap.put('newVaIbanAccountNo', null);
            pmtPlanRqMap.put('securityDeposit', soRecord.SecurityDeposit__c+ '');
            pmtPlanRqMap.put('rtoOrigSellPrice', soRecord.RTOOriginalSellingPrice__c+ '');
            pmtPlanRqMap.put('rtoDiscount', soRecord.RTODiscount__c+ '');
            pmtPlanRqMap.put('rtoNetAmount', soRecord.RTONetAmount__c+ '');
            pmtPlanRqMap.put('srSfId', serviceRequest.Id);
            pmtPlanRqMap.put('newNetAmount', serviceRequest.NewNetAmount__c+ '');
            pmtPlanRqMap.put('admToCharge', serviceRequest.ADMToBeCharged__c+ '');

            for(InstallmentLines__c il : soIdWithInstallmentLinesMap.get(serviceRequest.SalesOrder__c)){

                Map<String, Object> instLines = new Map<String, Object>();
                //Id, SalesOrder__c, PaymentPlan__c, PaymentPlan__r.Name, ERPID__c, InstallmentNumber__c, InstallmentPercentage__c, BrokerPayoutPercentage__c, InstallmentAmount__c, 
                //InstallmentDate__c, Description__c, CreatedById, OriginalCreationDate__c, RTOStartDate__c, RTOEndDate__c, RTOPaymentFrequency__c, RTOOptionFeeTaxCode__c, ActiveTenancyYear__c,
                //
                instLines.put('sfSalesOrderNum',il.SalesOrder__c);
                instLines.put('sfPaymentPlanId',il.PaymentPlan__c);
                instLines.put('paymentPlanName',il.PaymentPlan__r.Name);
                instLines.put('sfInstId',il.Id);
                instLines.put('erpInstId',il.ERPID__c);
                instLines.put('installmentNum',il.InstallmentNumber__c + '');
                instLines.put('installmentPerc',il.InstallmentPercentage__c +'');
                instLines.put('brokPayoutPerc',il.BrokerPayoutPercentage__c+'');
                instLines.put('installmentAmount',il.InstallmentAmount__c + '');
                instLines.put('installmentDate', il.InstallmentDate__c != null ? DateTime.newInstance( il.InstallmentDate__c.year(), il.InstallmentDate__c.month(),il.InstallmentDate__c.day()).format('yyyy-MM-dd') : '' +'');
                instLines.put('description',il.Description__c);
                instLines.put('createdbyid',il.CreatedById);
                instLines.put('createddate', il.OriginalCreationDate__c != null ? DateTime.newInstance( il.OriginalCreationDate__c.year(), il.OriginalCreationDate__c.month(),il.OriginalCreationDate__c.day()).format('yyyy-MM-dd') : '' +'');
                instLines.put('optionFeePercent',null);
                instLines.put('optionFeeAmount',null);
                instLines.put('rtoBuyoutPrice',null);
                instLines.put('rtoPriceEsc',null);
                instLines.put('rtoStartDate', il.RTOStartDate__c != null ? DateTime.newInstance( il.RTOStartDate__c.year(), il.RTOStartDate__c.month(),il.RTOStartDate__c.day()).format('yyyy-MM-dd') : '' +'');
                instLines.put('rtoEndDate', il.RTOEndDate__c != null ? DateTime.newInstance( il.RTOEndDate__c.year(), il.RTOEndDate__c.month(),il.RTOEndDate__c.day()).format('yyyy-MM-dd') : '' +'');
                instLines.put('rtoFrequency',il.RTOPaymentFrequency__c+'');
                instLines.put('rtoOptFeeTaxCode',il.RTOOptionFeeTaxCode__c);
                instLines.put('activeTenancyYear',il.ActiveTenancyYear__c + '');
                instLines.put('rtoRebantAmount',null);
                instLines.put('rtoRentPerEsc',null);
                instLines.put('rtoRentDiscount',null);
                instLines.put('rtoRentPercent',null);
                instLines.put('actionMode','CREATE');

                instLinesList.add(instLines);
            }
            pmtPlanRqMap.put('instLines', instLinesList);
            pmtPlanRqList.add(pmtPlanRqMap);
        }
        finalMap.put('pmtPlanRq',pmtPlanRqList);
        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        requestBody = requestBody.replace(':"null"', ':""');

        System.debug('requestBody>>>' + requestBody);

        if (!pmtPlanRqList.isEmpty()) {
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.PAYMENT_PLAN_CHANGE, srIds));
        }
    }

    public static void processPPCResponse(MulePOSResponeWrapper.Results results, String processName, String requestBody, String muleRes) {
        List<String> srIds = new List<String>();
        for (MulePOSResponeWrapper.InstLinesRes responseRecord : results.instLinesRes) {
            if (responseRecord.status != Constants.MULESOFT_SUCCESS){
                srIds.add(responseRecord.sfRequestId);
            }
        }
        Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, RetryCount__c FROM HexaBPM__Service_Request__c WHERE Id IN :srIds]);

        List<HexaBPM__Service_Request__c> srSuccessList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srFailedList = new List<HexaBPM__Service_Request__c>();
        List<InstallmentLines__c> ilList = new List<InstallmentLines__c>();
        List<Id> allSuccessIds = new List<Id>();
        List<Id> allFailedIds = new List<Id>();

        List<Logger__c> loggerList = new List<Logger__c>();
        for (MulePOSResponeWrapper.InstLinesRes responseRecord : results.instLinesRes) {
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
            InstallmentLines__c ilRecord = new InstallmentLines__c();
            if (responseRecord.status == Constants.MULESOFT_SUCCESS) {
                
                if(!allSuccessIds.contains(responseRecord.sfRequestId)){
                    srRecord.Id = responseRecord.sfRequestId;
                    srRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                    srRecord.SyncTime__c = Datetime.now();
                    srRecord.RetryCount__c = 0;
                    srRecord.ErrorReason__c = '';
                    srSuccessList.add(srRecord);
                    allSuccessIds.add(responseRecord.sfRequestId);
                }

                ilRecord.Id = responseRecord.sfInstId;
                ilRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                ilRecord.ERPID__c = responseRecord.erpInstId;
                ilRecord.SyncTime__c = Datetime.now();
                ilRecord.RetryCount__c = 0;
                ilRecord.ErrorReason__c = '';
                ilList.add(ilRecord);
            } else {

                if(!allFailedIds.contains(responseRecord.sfRequestId)){
                    srRecord.Id = responseRecord.sfRequestId;
                    srRecord.SyncStatus__c = Constants.STATUS_FAILED;
                    srRecord.SyncTime__c = Datetime.now();
                    srRecord.RetryCount__c = srMap.get(responseRecord.sfRequestId).RetryCount__c == null ? 1 : srMap.get(responseRecord.sfRequestId).RetryCount__c + 1;
                    srRecord.ErrorReason__c = responseRecord.errorMsg;
                    srFailedList.add(srRecord);
                    allFailedIds.add(responseRecord.sfRequestId);
                }
                

                ilRecord.Id = responseRecord.sfInstId;
                ilRecord.SyncStatus__c = Constants.STATUS_FAILED;
                ilRecord.ERPID__c = responseRecord.erpInstId;
                ilRecord.SyncTime__c = Datetime.now();
                ilRecord.RetryCount__c = srMap.get(responseRecord.sfRequestId).RetryCount__c == null ? 1 : srMap.get(responseRecord.sfRequestId).RetryCount__c + 1;
                ilRecord.ErrorReason__c = responseRecord.errorMsg;
                ilList.add(ilRecord);

                loggerList.add(LoggerService.addApexServiceCalls('CalloutToMuleSoftQueueable', 'calloutMuleSoft', processName, requestBody, muleRes, responseRecord.sfRequestId));
            }
        }

        if (!ilList.isEmpty()) {
            update ilList;
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