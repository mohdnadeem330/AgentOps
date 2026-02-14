/*
* Purpose: For sending data to ERP System.
* SR Type: Rebate Reinstate
*/
global with sharing class CC_SRRebateReinstateController implements HexaBPM.iCustomCodeExecutable {

    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {

        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];

        HexaBPM__Service_Request__c updateSRWithReceipt = new HexaBPM__Service_Request__c();
        updateSRWithReceipt.Id = serviceRequest.Id ; 
                
        /*
        * Logic: Create a Sales Order Other Charges as a Debit Memo for ADM Refund Amount.
        */
        if(serviceRequest.HexaBPM__External_Status_Name__c == Constants.CLOSED_SR){

            List<ReceiptAcknowledgement__c> receiptList = [Select Id, Account__c, Contact__c, Opportunity__c, Amount__c FROM ReceiptAcknowledgement__c where SalesOrder__c =: serviceRequest.SalesOrder__c AND PaymentType__c =: Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE AND PaymentSubType__c =: Constants.PAYMENT_SUB_TYPE_REBATE AND Status__c =: Constants.REVERSED_PAYMENT_STATUS Order by LastmodifiedDate Desc Limit 1];

            if(receiptList.size() > 0){
                ReceiptAcknowledgement__c receiptRec = new ReceiptAcknowledgement__c( Account__c = receiptList[0].Account__c, Contact__c = receiptList[0].Contact__c, Opportunity__c = receiptList[0].Opportunity__c, SalesOrder__c = serviceRequest.SalesOrder__c, PaymentType__c = Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE, PaymentSubType__c = Constants.PAYMENT_SUB_TYPE_REBATE, Remarks__c = Constants.BUDGET_LINE_REBATE, Amount__c = receiptList[0].Amount__c, Status__c = Constants.RECEIVED_PAYMENT_STATUS);
                receiptRec.IsStopSyncingWithERP__c = true;
                insert receiptRec;   

                updateSRWithReceipt.ReceiptAcknowledgement__c = receiptRec.Id ;
                update  updateSRWithReceipt ;          
            } 
            else{
                Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
                decimal rebateTotal=0;
                List<HexaBPM__Service_Request__c> handoverSRList = [Select id, SalesOrder__r.LastInstallmentRebate__c, SalesOrder__r.OtherRebateAmount__c, SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__c from HexaBPM__Service_Request__c where SalesOrder__c =: serviceRequest.SalesOrder__c AND HexaBPM__External_Status_Name__c !=: Constants.SR_STATUS_CANCELLED AND RecordTypeId =: handoverRecordTypeId AND (HandoverDetail__r.CHODate__c != null OR HandoverDetail__r.RFODate__c != null) ];
                
                if(handoverSRList.Size() > 0){
                    rebateTotal += (handoverSRList[0].SalesOrder__r.LastInstallmentRebate__c!=null && handoverSRList[0].SalesOrder__r.LastInstallmentRebate__c!= 0) ? handoverSRList[0].SalesOrder__r.LastInstallmentRebate__c : (handoverSRList[0].SalesOrder__r.OtherRebateAmount__c!=null? handoverSRList[0].SalesOrder__r.OtherRebateAmount__c : 0);
                    if(rebateTotal > 0){
                        ReceiptAcknowledgement__c receiptRec = new ReceiptAcknowledgement__c( Account__c=handoverSRList[0].SalesOrder__r.Account__c,
                                                                    Contact__c=handoverSRList[0].SalesOrder__r.Contact__c,
                                                                    Opportunity__c=handoverSRList[0].SalesOrder__r.Opportunity__c,
                                                                    SalesOrder__c=handoverSRList[0].SalesOrder__c,
                                                                    PaymentType__c = Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE,
                                                                    PaymentSubType__c = Constants.PAYMENT_SUB_TYPE_REBATE,
                                                                    Remarks__c = Constants.BUDGET_LINE_REBATE,
                                                                    Amount__c = rebateTotal);
                        receiptRec.IsStopSyncingWithERP__c = true;
                        insert receiptRec;

                        updateSRWithReceipt.ReceiptAcknowledgement__c = receiptRec.Id ;
                        update  updateSRWithReceipt ;
                    }

                }                
            }          

            RebateReinstateCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
        }

        return Constants.SUCCESS_RETURN_MESSAGE;

    }
    
}