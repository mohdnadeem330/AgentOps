/*
* Purpose: Update the Sales Order and associate records.
* SR Type: Cancellation
*/
global without sharing class CC_SRCancelSalesOrderController implements HexaBPM.iCustomCodeExecutable {

    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
        
        /*
        * Logic: Unapply all receipts
        */
        List<ReceiptAllocation__c> receiptAllocationList = new List<ReceiptAllocation__c>();
        for (ReceiptAllocation__c receiptAllocation: salesOrder.ReceiptAllocations__r) {
            if (String.isNotBlank(receiptAllocation.InstallmentLine__c)) {
                receiptAllocation.AmountApplied__c = 0;
                receiptAllocation.Unapply__c = true;
                receiptAllocation.IsStopSyncingWithERP__c = true;
                receiptAllocationList.add(receiptAllocation);
            }
        }
        
        List<SalesOrderOtherCharges__c> soOtherChargeList = new List<SalesOrderOtherCharges__c>();
        List<ReceiptAcknowledgement__c> soReceiptList = new List<ReceiptAcknowledgement__c>();
        /*
        * Logic: Create Sales Order Other Charges (in negative) for Installment Line where Invoice No is available
        */
        Map<String, Id> installmentLineMap = new Map<String, Id>();
        for (InstallmentLines__c line: salesOrder.InstallmentLines__r) {
            if (String.isNotBlank(line.InvoiceNumber__c) && line.InstallmentAmount__c != null && line.InstallmentAmount__c != 0) {
                // soOtherChargeList.add(SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE, Constants.OTHER_CHARGES_SUB_TYPE_INSTALLMENT, (0 - line.InstallmentAmount__c)));
                ReceiptAcknowledgement__c receipt = SRUtility.createReceiptAcknowledgementFromSO(serviceRequest, salesOrder, Constants.PAYMENT_TYPE_CREDIT_NOTE, (0 - line.InstallmentAmount__c));
                receipt.IsCreatedFromLink__c = true;
                receipt.PaymentSubType__c = Constants.PAYMENT_SUB_TYPE_INSTALLMENT_REVERSAL;
                receipt.Remarks__c = Constants.INVOICE_TYPE_INSTALLMENT + ' ' + line.InstallmentNumber__c;
                receipt.IsStopSyncingWithERP__c = true;
                installmentLineMap.put(Constants.INVOICE_TYPE_INSTALLMENT + ' ' + line.InstallmentNumber__c, line.Id);
                soReceiptList.add(receipt);
            }
        }
        if (!soReceiptList.isEmpty()) {
            insert soReceiptList;
            for (ReceiptAcknowledgement__c receipt: soReceiptList) {
                ReceiptAllocation__c receiptAllocation = new ReceiptAllocation__c();
                receiptAllocation.Account__c = receipt.Account__c;
                receiptAllocation.SalesOrder__c = receipt.SalesOrder__c;
                receiptAllocation.AmountApplied__c = receipt.Amount__c;
                receiptAllocation.ReceiptAcknowledgement__c = receipt.Id;
                receiptAllocation.IsStopSyncingWithERP__c = true;
                receiptAllocation.InstallmentLine__c = installmentLineMap.get(receipt.Remarks__c);

                receiptAllocationList.add(receiptAllocation);
            }
        }
        if (!receiptAllocationList.isEmpty()) {
            upsert receiptAllocationList;
        }

        /*
        * Logic: Create a Sales Order Other Charges as a Debit Memo if the Refund Amount is applicable, otherwise as a Cancellation Fee.
        */
        // if (serviceRequest.RefundAmount__c != null && serviceRequest.RefundAmount__c < 0) {
        //     soOtherChargeList.add(SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_CANCELLATION_FEE, '', (0 - serviceRequest.RefundAmount__c), serviceRequest));
        // } else 
        if (serviceRequest.RefundAmount__c != null && serviceRequest.RefundAmount__c > 0) {
            soOtherChargeList.add(SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO, Constants.OTHER_CHARGES_SUB_TYPE_CUSTOMER_REFUND, serviceRequest.RefundAmount__c, serviceRequest));
        }
        
        /*
        * Logic: If the Reallocation Amount is applicable then creating a Receipt Acknowledgement.
        */
        /*
        if (serviceRequest.ReallocationAmount__c != null && serviceRequest.ReallocationAmount__c > 0) {
            // soOtherChargeList.add(SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_CREDIT_MEMO, Constants.OTHER_CHARGES_SUB_TYPE_REALLOCATED_AMOUNT, serviceRequest.ReallocationAmount__c));
            ReceiptAcknowledgement__c newRA = SRUtility.createReceiptAcknowledgementFromSR(serviceRequest, Constants.PAYMENT_TYPE_CREDIT_NOTE, serviceRequest.ReallocationAmount__c);
        }
        */

        if (serviceRequest.SubType__c == Constants.UNIT_SWAP_SR_TYPE && serviceRequest.ReallocationAmount__c != null && serviceRequest.ReallocationAmount__c > 0) {
            HexaBPM__Service_Request__c parentSR = [SELECT Id, Unit__c, Unit__r.Project__r.Name, SwappedUnit__c, SwappedUnit__r.Project__r.Name 
                                                        FROM HexaBPM__Service_Request__c WHERE Id =: serviceRequest.HexaBPM__Parent_SR__c];
            if (parentSR.Unit__r.Project__r.Name != parentSR.SwappedUnit__r.Project__r.Name) {
                soOtherChargeList.add(SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO, Constants.OTHER_CHARGES_SUB_TYPE_REALLOCATED_AMOUNT, serviceRequest.ReallocationAmount__c, serviceRequest));
            }
        }

        /*
        * Logic: Create a Sales Order Other Charges as a Debit Memo for Forfeit Amount.
        */
        if (serviceRequest.ForfeitAmount__c != null && serviceRequest.ForfeitAmount__c > 0) {
            soOtherChargeList.add(SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO, Constants.OTHER_CHARGES_SUB_TYPE_FORFEITURE_AMOUNT, serviceRequest.ForfeitAmount__c, serviceRequest));
        }
        
         
        if (serviceRequest.Provision_Fund__c != null && serviceRequest.Provision_Fund__c > 0) {
            soOtherChargeList.add(SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO, 'Provision Fund', serviceRequest.Provision_Fund__c, serviceRequest));
        }

        if (!soOtherChargeList.isEmpty() && serviceRequest.SRType__c != Constants.RTO_CANCELLATION_SR_TYPE) {
            insert soOtherChargeList;
        }
       

        if ((serviceRequest.SRType__c == Constants.RTO_CANCELLATION_SR_TYPE || (serviceRequest.SRType__c=='Cancellation'&& (serviceRequest.SubType__c =='Sales Cancellation'))) && serviceRequest.Refund_Amount__c != null && serviceRequest.Refund_Amount__c > 0) {
            SalesOrderOtherCharges__c otherCharge = SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO, Constants.OTHER_CHARGES_SUB_TYPE_CUSTOMER_REFUND, serviceRequest.Refund_Amount__c, serviceRequest);
            insert otherCharge;
        }
        if (serviceRequest.SRType__c == Constants.RTO_CANCELLATION_SR_TYPE && serviceRequest.ChargeCollected__c > 0) {
            SalesOrderOtherCharges__c soOtherCharge = SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_CANCELLATION_FEE, '', serviceRequest.ChargeCollected__c, serviceRequest);
            insert soOtherCharge;
            if (!serviceRequest.Receipt_Acknowledgements__r.isEmpty()) {
                ReceiptAllocation__c receiprAllocation = SRUtility.createReceiptAllocation(soOtherCharge, serviceRequest);
            }
        }

        /*
        * Logic: Create Sales Order Cancellation Record for Sales Order
        */
        if(serviceRequest.SubType__c !='Sales Cancellation'){
        SalesOrderCancellation__c newSalesCancellationRecord = new SalesOrderCancellation__c();
        newSalesCancellationRecord.SalesOrder__c = salesOrder.Id;
        //Jira - SSP-588 - Assign SalesOrder object to retrive status values inside flow    
        newSalesCancellationRecord.SalesOrder__r = salesOrder;    
        newSalesCancellationRecord.Unit__c = salesOrder.Unit__c;
        newSalesCancellationRecord.PaymentPlan__c = salesOrder.PaymentPlan__c;
        newSalesCancellationRecord.SalesManager__c = salesOrder.SalesManager__c;
        newSalesCancellationRecord.CancellationRequestDate__c = Date.today();
        newSalesCancellationRecord.Business_Justification__c='Justification';
        newSalesCancellationRecord.Cancellation_Status__c = Constants.CANCELLATION_STATUS_AWAITING_APPROVAL;
        if (salesOrder.Opportunity__c != null && salesOrder.Opportunity__r.BrokerAgencyAccount__c != null) {
            newSalesCancellationRecord.BrokerageAgencyName__c = salesOrder.Opportunity__r.BrokerAgencyAccount__c;
        }
        newSalesCancellationRecord.ExistingPromoOrOffer__c = salesOrder.Offer__c;
        newSalesCancellationRecord.DownPaymentStatus__c = Constants.DOWN_PAYMENT_STATUS_PAID;
        newSalesCancellationRecord.ReasonforCancellation__c = Constants.CANCELLATION_REASON_OTHER;
        newSalesCancellationRecord.OtherReason__c = serviceRequest.CancellationReason__c;
        if (serviceRequest.RefundAmount__c != null && serviceRequest.RefundAmount__c > 0) {
            newSalesCancellationRecord.RefundAmount__c = serviceRequest.RefundAmount__c;
            newSalesCancellationRecord.RefundApplicable__c = true;
            newSalesCancellationRecord.RefundReason__c = 'Social Reason: ' + serviceRequest.SocialReason__c;
        }
        insert newSalesCancellationRecord;

        newSalesCancellationRecord.Cancellation_Status__c = Constants.CANCELLATION_STATUS_APPROVED;
        update newSalesCancellationRecord;
        }
        if(serviceRequest.RecordType.Name != Constants.Golden_Visa_RT){
            salesOrder.Status__c = Constants.SO_STATUS_CANCELLED;
            salesOrder.SubStatus__c = Constants.SUB_STATUS_POST_SALES_CANCELLATION;
            update salesOrder;
        }

        List<HexaBPM__Service_Request__c> handoverSRList = [SELECT Id FROM HexaBPM__Service_Request__c WHERE RecordTypeId =: Constants.HANDOVER_RT AND SalesOrder__c =: serviceRequest.SalesOrder__c AND HexaBPM__External_Status_Name__c !=: Constants.SR_STATUS_CLOSED AND HexaBPM__External_Status_Name__c !=: Constants.SR_STATUS_CANCELLED];
        if (!handoverSRList.isEmpty()) {
            HandoverUtility.cancelHandoverSR(new set<ID>{serviceRequest.Unit__c});
        }

        CancellationCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
        return Constants.SUCCESS_RETURN_MESSAGE;
    }
}