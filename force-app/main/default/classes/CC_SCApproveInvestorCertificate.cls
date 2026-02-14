/*
* SR Type : Investor Certificate
* Purpose : To enforce service charge
*/
global without sharing class CC_SCApproveInvestorCertificate implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SCApproveInvestorCertificate : Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, SRType__c,Exceptional_Reason__c,Credit_Note_Sub_Type__c,No_Charge_Fee_Required__c,ChequeReplacementStatus__c, ProposalPaymentPlan__c, SalesOrder__c, Unit__c, Unit__r.Name, Unit__r.BuildingSectionName__r.TaxPercentage__c, NewNetAmount__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c, HexaBPM__Contact__c, SummaryReport__c
                 FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                if(!sRRecord.No_Charge_Fee_Required__c && stp.HexaBPM__Summary__c == 'Approve the Investor Certificate' && stp.HexaBPM__Step_Status__c == 'Approved') {
                    ReceiptAcknowledgement__c rack = prepareReceiptAck(sRRecord);
                    Map<Id, HexaBPM__Service_Request__c> srIdWithSR = new Map<Id, HexaBPM__Service_Request__c>();
                    srIdWithSR.put(sRRecord.Id,sRRecord);
                    Map<Id, ReceiptAcknowledgement__c> srIdWithRcptAcknowledgmentMap = new Map<Id, ReceiptAcknowledgement__c>();
                    srIdWithRcptAcknowledgmentMap.put(sRRecord.Id,rack);
                    SRPostPaymentHandler.paymentExtensionTypePayment(srIdWithSR,srIdWithRcptAcknowledgmentMap);
                }

                if(stp.Step_Template_Code__c == 'Charge Fees'){
                    if(stp.HexaBPM__Step_Status__c == 'Customer Not Paid'){
                        string receiptStatus = [SELECT Status__c FROM ReceiptAcknowledgement__c WHERE ServiceRequest__c =:sRRecord.Id AND Receipt_Type__c = 'Charge Fee' order by createddate DESC LIMIT 1]?.Status__c;
                        if(string.IsBlank(receiptStatus)){
                            return 'No related charge fee type receipt found for this service request.';
                        } else {
                            if(receiptStatus == 'Received' || receiptStatus == 'Cleared') {
                                return 'Receipt status shows customer has already paid.';
                            }
                        }
                    }              
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+' :CC_SCApproveInvestorCertificate';
        }
        return result;
    }
    public static ReceiptAcknowledgement__c prepareReceiptAck(HexaBPM__Service_Request__c sRRecord) {
        ReceiptAcknowledgement__c rack = new ReceiptAcknowledgement__c();
        
        //Decimal chargeAmount = [SELECT ChargeAmount__c from ChargeRule__c WHERE SRType__c =:Constants.LPC_WAIVER_TYPE AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]?.ChargeAmount__c;
        Decimal chargeAmount = 0;
        for(ChargeRule__c chargeRule : [SELECT ChargeAmount__c,ChargePercentage__c,VATChanges__c from ChargeRule__c WHERE SRType__c =:sRRecord.SRType__c AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]){
            Decimal amountWithoutVAT = chargeRule.ChargeAmount__c;
            Decimal vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
            chargeAmount = amountWithoutVAT + vatAmount;
        }
        if(chargeAmount <> Null && chargeAmount > 0) {
            Timer__mdt paymentGatewayLinkTimer = Utilities.getTimer(Constants.PAYMENT_GATEWAY_LINK);
            String timerUnit = PaymentGatewayLinkTimer.Time__c;
            Integer timerDetails = Integer.valueOf(PaymentGatewayLinkTimer.Timer__c);
            if (timerUnit == Constants.HOURS) {
                timerDetails = timerDetails * 60;
            }
            rack.Account__c = sRRecord.HexaBPM__Customer__c;
            rack.SalesOrder__c = sRRecord.SalesOrder__c;
            rack.Amount__c = chargeAmount;
            rack.Status__c = Constants.LINK_SENT;
            rack.PaymentType__c = Constants.ONLINE;
            rack.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            rack.PaymentSubType__c = sRRecord.Credit_Note_Sub_Type__c;
            rack.ServiceRequest__c = sRRecord.Id;
            rack.RegeneratePaymentLink__c = true;
            rack.DoNotSendPaymentURL__c = false;
            rack.Contact__c = sRRecord.HexaBPM__Contact__c;
            rack.Opportunity__c = sRRecord.SalesOrder__r.Opportunity__c;
            rack.Receipt_Type__c = 'Charge Fee';
            //rack.IsStopSyncingWithERP__c = true;
            //Commneted BY Yash shrivastava for regenerate payment link issue.
            //rack.EncryptedRecordId__c = EncodingUtil.urlEncode(EncryptionUtils.encryptString(sRRecord.Id+''), 'UTF-8');
            rack.PaymentLinkExpiry__c = system.now().addMinutes(timerDetails);    
            insert rack;
        }
        
        return rack;
    }
}