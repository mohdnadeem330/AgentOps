/*
* SR Type : Payment Extension
* Purpose : To approve and update the installment date to the new extension date 
*/
global without sharing class CC_ApproveExtensionRequest implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ApproveExtensionRequest: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, Payment_Extension_Period_In_Days__c,No_Charge_Fee_Required__c, SRType__c, InstallmentLine__c, InstallmentLine__r.OutstandingAmount__c,PaymentExtensionDate__c, PaymentExtensionPeriod__c, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Status__c, ReceiptAcknowledgement__r.StatusReason__c,HexaBPM__Customer__c,SalesOrder__c,ChargeCollected__c,Exceptional_Reason__c,Amount__c,ChargeType__c,Credit_Note_Sub_Type__c,SalesOrder__r.Opportunity__c,HexaBPM__Contact__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                //--- update instalment date

                if(stp.Step_Template_Code__c == 'Approval by Development Finance' && sRRecord.PaymentExtensionPeriod__c > 2){
                    HexaBPM__SR_Status__c srStatus = [Select Id From HexaBPM__SR_Status__c Where Name = 'Approved' LIMIT 1];
                    sRRecord.HexaBPM__External_SR_Status__c =  srStatus.Id;
                    sRRecord.HexaBPM__Internal_SR_Status__c =  srStatus.Id;
                    update sRRecord;
                }
                else{
                    if(sRRecord.No_Charge_Fee_Required__c) {
                        if(stp.HexaBPM__Step_Status__c == 'Approved' && (stp.Step_Template_Code__c == 'Approval by Development Finance' || stp.Step_Template_Code__c == 'Approval by EDCC')){
                            HexaBPM__SR_Status__c srStatus = [Select Id From HexaBPM__SR_Status__c Where Name = 'Closed' LIMIT 1];
                            sRRecord.HexaBPM__External_SR_Status__c =  srStatus.Id;
                            sRRecord.HexaBPM__Internal_SR_Status__c =  srStatus.Id;
                            update sRRecord;
                        }  
                        InstallmentLines__c instLine = new InstallmentLines__c(Id=sRRecord.InstallmentLine__c, InstallmentDate__c=sRRecord.PaymentExtensionDate__c);
                        update instLine;
                        PaymentExtensionCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});                                 
                    } else {
                        ReceiptAcknowledgement__c rack = prepareReceiptAck(sRRecord);
                        Map<Id, HexaBPM__Service_Request__c> srIdWithSR = new Map<Id, HexaBPM__Service_Request__c>();
                        srIdWithSR.put(sRRecord.Id,sRRecord);
                        Map<Id, ReceiptAcknowledgement__c> srIdWithRcptAcknowledgmentMap = new Map<Id, ReceiptAcknowledgement__c>();
                        srIdWithRcptAcknowledgmentMap.put(sRRecord.Id,rack);
                        SRPostPaymentHandler.paymentExtensionTypePayment(srIdWithSR,srIdWithRcptAcknowledgmentMap);
                    }
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+' :CC_ApproveExtensionRequest';
        }
        return result;
    }

    public static ReceiptAcknowledgement__c prepareReceiptAck(HexaBPM__Service_Request__c sRRecord) {
        ReceiptAcknowledgement__c rack = new ReceiptAcknowledgement__c();
        if(sRRecord.InstallmentLine__c <> NULL && sRRecord.InstallmentLine__r.OutstandingAmount__c <> NULL){

        Decimal chargeAmount = 0;
        for(ChargeRule__c chargeRule : [SELECT ChargePercentage__c,VATChanges__c from ChargeRule__c WHERE SRType__c =:Constants.PAYMENT_EXTENSION_TYPE AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]){
            Decimal amountWithoutVAT = sRRecord.Payment_Extension_Period_In_Days__c <> 0 && sRRecord.Payment_Extension_Period_In_Days__c <> null ? (chargeRule.ChargePercentage__c * sRRecord.InstallmentLine__r.OutstandingAmount__c * sRRecord.Payment_Extension_Period_In_Days__c)/100 : (chargeRule.ChargePercentage__c * sRRecord.InstallmentLine__r.OutstandingAmount__c)/100;
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
           // rack.EncryptedRecordId__c = EncodingUtil.urlEncode(EncryptionUtils.encryptString(sRRecord.Id+''), 'UTF-8');
            rack.PaymentLinkExpiry__c = system.now().addMinutes(timerDetails);    
            insert rack;
        }
        }
        return rack;
    }
}