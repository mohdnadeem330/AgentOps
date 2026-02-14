/*
* Purpose: To Equity Transfer from old Sales Order to new Sales Order.
* SR Type: Unit Swap
*/
global without sharing class CC_SRUnitSwapEquityTransfer implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        HexaBPM__Service_Request__c childSR = [SELECT Id, Name, TotalCollectedAmount__c FROM HexaBPM__Service_Request__c WHERE 
                                                HexaBPM__Parent_SR__c =: serviceRequest.Id AND SRType__c =: Constants.CANCELLATION_SR_TYPE 
                                                AND SubType__c =: Constants.UNIT_SWAP_SUB_TYPE LIMIT 1];

        SalesOrder__c oldSalesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
        SalesOrder__c newSalesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SwappedOrder__c})[0];

        List<ReceiptAllocation__c> newReceiptAllocations = new List<ReceiptAllocation__c>();

        Map<String, Decimal> receiptMap = new Map<String, Decimal>();
        Decimal totalAmount = 0;
        for (ReceiptAcknowledgement__c receipt: oldSalesOrder.Payments__r) {
            if (receipt.Status__c == Constants.RECEIPT_STATUS_CLEARED && receipt.OutstandingAmount__c > 0) {
                Decimal amount = receipt.OutstandingAmount__c;
                if (childSR.TotalCollectedAmount__c > receipt.OutstandingAmount__c) {
                    childSR.TotalCollectedAmount__c = childSR.TotalCollectedAmount__c - receipt.OutstandingAmount__c;
                } else {
                    amount = childSR.TotalCollectedAmount__c;
                    childSR.TotalCollectedAmount__c = 0;
                }
                receiptMap.put(receipt.Id, amount);
                totalAmount += amount;
                if (childSR.TotalCollectedAmount__c == 0) {
                    break;
                }
            }
        }
        System.debug('receiptMap>>>' + JSON.serialize(receiptMap));
        System.debug('totalAmount>>>' + totalAmount);

        for (SalesOrderOtherCharges__c otherCharge: oldSalesOrder.SalesOrdersOtherCharges__r) {
            System.debug('otherCharge>>>' + otherCharge);
            if (otherCharge.ServiceRequest__c != null && otherCharge.ServiceRequest__c == childSR.Id && otherCharge.PendingAmount__c > 0) {
                System.debug('otherCharge.PendingAmount__c>>>' + otherCharge.PendingAmount__c);
                Decimal pendingAmount = otherCharge.PendingAmount__c;
                for (String receiptId: receiptMap.keySet()) {
                    Decimal receiptAmount = receiptMap.get(receiptId);
                    if (receiptAmount > 0 && receiptAmount >= pendingAmount) {
                        newReceiptAllocations.add(createReceiptAllocation(serviceRequest.HexaBPM__Customer__c, serviceRequest.SalesOrder__c, receiptId, null, otherCharge.Id, pendingAmount, otherCharge.TypeOfCharge__c));
                        receiptMap.put(receiptId, receiptAmount - pendingAmount);
                        totalAmount = totalAmount - pendingAmount;
                        pendingAmount = 0;
                    } else if (receiptAmount > 0) {
                        newReceiptAllocations.add(createReceiptAllocation(serviceRequest.HexaBPM__Customer__c, serviceRequest.SalesOrder__c, receiptId, null, otherCharge.Id, receiptAmount, otherCharge.TypeOfCharge__c));
                        receiptMap.put(receiptId, 0);
                        totalAmount = totalAmount - receiptAmount;
                        pendingAmount = pendingAmount - receiptAmount;
                    }
                    System.debug('receiptMap>>>' + JSON.serialize(receiptMap));
                    System.debug('totalAmount>>>' + totalAmount);
                    if (pendingAmount == 0 || totalAmount == 0) {
                        break;
                    }
                }
                if (totalAmount == 0) {
                    break;
                }
            }
        }

        if (serviceRequest.UnitFromSameProject__c == Constants.YES) {
            for (InstallmentLines__c installmentLine: newSalesOrder.InstallmentLines__r) {
                if (installmentLine.PendingAmount__c > 0) {
                    Decimal pendingAmount = installmentLine.PendingAmount__c;
                    for (String receiptId: receiptMap.keySet()) {
                        Decimal receiptAmount = receiptMap.get(receiptId);
                        if (receiptAmount > 0 && receiptAmount >= pendingAmount) {
                            newReceiptAllocations.add(createReceiptAllocation(serviceRequest.HexaBPM__Customer__c, serviceRequest.SwappedOrder__c, receiptId, installmentLine.Id, null, pendingAmount, null));
                            receiptMap.put(receiptId, receiptAmount - pendingAmount);
                            totalAmount = totalAmount - pendingAmount;
                            pendingAmount = 0;
                        } else if (receiptAmount > 0) {
                            newReceiptAllocations.add(createReceiptAllocation(serviceRequest.HexaBPM__Customer__c, serviceRequest.SwappedOrder__c, receiptId, installmentLine.Id, null, receiptAmount, null));
                            receiptMap.put(receiptId, 0);
                            totalAmount = totalAmount - receiptAmount;
                            pendingAmount = pendingAmount - receiptAmount;
                        }
                        System.debug('receiptMap>>>' + JSON.serialize(receiptMap));
                        System.debug('totalAmount>>>' + totalAmount);
                        if (pendingAmount == 0 || totalAmount == 0) {
                            break;
                        }
                    }
                    if (totalAmount == 0) {
                        break;
                    }
                }
            }
        }

        if (!newReceiptAllocations.isEmpty()) {
            System.debug('newReceiptAllocations>>>JSON>>>' + JSON.serialize(newReceiptAllocations));
            upsert newReceiptAllocations;
        }
        
        return Constants.SUCCESS_RETURN_MESSAGE;
    }

    public static ReceiptAllocation__c createReceiptAllocation(String customerId, String salesOrderId, String receiptId, String installmentLineId, String otherChargeId, Decimal amount, String typeOfInvoice){
        ReceiptAllocation__c allocationRecord = new ReceiptAllocation__c();
        allocationRecord.Account__c = customerId;
        allocationRecord.SalesOrder__c = salesOrderId;
        allocationRecord.AmountApplied__c = amount;
        allocationRecord.ReceiptAcknowledgement__c = receiptId;
        if (installmentLineId != null) {
            allocationRecord.InstallmentLine__c = installmentLineId;
        } else if (otherChargeId != null) {
            allocationRecord.SalesOrderOtherCharges__c = otherChargeId;
        }
        if (typeOfInvoice != null) {
            allocationRecord.TypeOfInvoice__c = typeOfInvoice;
        }
        
        return allocationRecord;
    }
}