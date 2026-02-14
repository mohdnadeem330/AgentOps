global without sharing class CC_VerifyLPCWaverRequest implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        System.debug('CC_VerifyLPCWaverRequest invoked');
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_VerifyLPCWaverRequest: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, No_Charge_Fee_Required__c, PaymentExtensionPeriod__c, SRType__c, Exceptional_Reason__c, TotalLPCAmount__c, WaivedAmount__c, InstallmentLine__c, TotalLPCDue__c, WaivedPercentage__c, WaivedBy__c, SalesOrder__c, LPCFreezeStatus__c,ReceiptAcknowledgement__c, HexaBPM__Customer__c,Credit_Note_Sub_Type__c,SalesOrder__r.Opportunity__c,HexaBPM__Contact__c 
                 FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                 
                if(stp.HexaBPM__Step_Status__c == 'Rejected'){

                    updateInstallmentLines(sRRecord.SalesOrder__c, sRRecord);
                    
                } else{

                    List<String> errorsMessages = new List<String>();

                    if(sRRecord.TotalLPCAmount__c == null){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.TOTAL_LPC_AMOUNT_VERIFY_REQUIST_STEP).Message__c);
                    }
                    if(sRRecord.WaivedAmount__c == null){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.LPC_WAINER_AMOUNT_VERIFY_REQUIST_STEP).Message__c);
                    }
                    if(sRRecord.WaivedAmount__c > sRRecord.TotalLPCDue__c){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.TOTAL_WAIVED_AMOUNT_VALIDATION).Message__c);
                    }
                    if(sRRecord.WaivedPercentage__c > 100){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.WAIVED_PERCENTAGE_VALIDATION).Message__c);
                    }
                    if(String.isBlank(sRRecord.WaivedBy__c)){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.LPC_WAIVED_BY_VALIDATION).Message__c);
                    } 
                    
                    if(!errorsMessages.isEmpty()){
                        return errorsMessages.toString().replace(',','\n');
                    }

                    if(stp.HexaBPM__Summary__c != 'Verify the Request'){

                        if(sRRecord.LPCFreezeStatus__c != 'Synced'){
                            return Utilities.getSystemMessages(Constants.LPC_FREEZE_STATUS_VALIDATION).Message__c;
                        } else{
                            System.debug('#$#$ sRRecord.No_Charge_Fee_Required__c > '+sRRecord.No_Charge_Fee_Required__c);
                            System.debug('#$#$ stp.HexaBPM__Summary__c > '+stp.HexaBPM__Summary__c);
                            System.debug('#$#$ sRRecord.PaymentExtensionPeriod__c > '+sRRecord.PaymentExtensionPeriod__c);

                           /**************** COMPLETE CHANGES MOVED TO ChargeFee Class and config under the LPC Waiver Charge Fee Default Action *******/
                            // Added by Kuhinoor Bug #SSP-187
                            Integer DCM_PaymentExtMinLimit = Integer.valueOf( System.Label.DCM_Payment_Ext_Min_Limit );
                            Integer CCO_PaymentExtMinLimit = Integer.valueOf( System.Label.CCO_Payment_Ext_Min_Limit );
                            Integer CEO_PaymentExtMinLimit = Integer.valueOf( System.Label.CEO_Payment_Ext_Min_Limit );

                             if(!sRRecord.No_Charge_Fee_Required__c && ((stp.HexaBPM__Summary__c == 'Approval by AVP-Default' && sRRecord.PaymentExtensionPeriod__c < DCM_PaymentExtMinLimit) ||
                                (stp.HexaBPM__Summary__c == 'Approval by D-CM' && sRRecord.PaymentExtensionPeriod__c >= DCM_PaymentExtMinLimit && sRRecord.PaymentExtensionPeriod__c < CCO_PaymentExtMinLimit) ||
                                (stp.HexaBPM__Summary__c == 'Approval by CCO' && sRRecord.PaymentExtensionPeriod__c >= CCO_PaymentExtMinLimit && sRRecord.PaymentExtensionPeriod__c < CEO_PaymentExtMinLimit) ||
                                (stp.HexaBPM__Summary__c == 'Approval by CEO' && sRRecord.PaymentExtensionPeriod__c >= CEO_PaymentExtMinLimit))
                              ){
                                ReceiptAcknowledgement__c rack = prepareReceiptAck(sRRecord);
                                Map<Id, HexaBPM__Service_Request__c> srIdWithSR = new Map<Id, HexaBPM__Service_Request__c>();
                                srIdWithSR.put(sRRecord.Id,sRRecord);
                                Map<Id, ReceiptAcknowledgement__c> srIdWithRcptAcknowledgmentMap = new Map<Id, ReceiptAcknowledgement__c>();
                                srIdWithRcptAcknowledgmentMap.put(sRRecord.Id,rack);
                                SRPostPaymentHandler.lpcWaiverTypePayment(srIdWithSR,srIdWithRcptAcknowledgmentMap);
                            } 
                        //}
                            if(stp.HexaBPM__Summary__c == 'Charge Fees'){
                                if(stp.HexaBPM__Step_Status__c == 'Customer Not Paid') {
                                    string receiptStatus = [SELECT Status__c FROM ReceiptAcknowledgement__c WHERE ServiceRequest__c =:sRRecord.Id AND Receipt_Type__c = 'Charge Fee' order by createddate DESC LIMIT 1]?.Status__c;
                                    if(string.IsBlank(receiptStatus)){
                                        errorsMessages.add('No related charge fee type receipt found for this service request.');
                                    } else {
                                        if(receiptStatus == 'Received' || receiptStatus == 'Cleared') {
                                            errorsMessages.add('Receipt status shows customer has already paid.');
                                        } else {
                                            updateInstallmentLines(sRRecord.SalesOrder__c, sRRecord);
                                        }
                                    } 
                                    if(!errorsMessages.isEmpty()){
                                        return errorsMessages.toString().replace(',','\n');
                                    }                      
                                } else {
                                    List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();
            
                                    for (InstallmentLines__c ilRecord:  [SELECT Id, Name, LPCFreezeDate__c, LPCFreezeUntilDate__c FROM InstallmentLines__c WHERE SalesOrder__c =: sRRecord.SalesOrder__c]) {
                                        ilRecord.LPCFreezeUntilDate__c = ilRecord.LPCFreezeUntilDate__c <> null && ilRecord.LPCFreezeUntilDate__c > Date.Today()+30 ? ilRecord.LPCFreezeUntilDate__c : Date.Today() + 30;
                                        installmentLinesList.add(ilRecord);
                                    }
                                    if(!installmentLinesList.isEmpty()){
                                        update installmentLinesList;
                                    }                                    
                                    updateServiceRequestStep(sRRecord.Id, stp.HexaBPM__Summary__c, Constants.COMPLETED_STATUS, '');
                                    sRRecord.LPCFreezeStatus__c = Constants.STATUS_IN_PROGRESS;
                                    update srRecord;
                                    LPCCalloutHelper.getDataForFreezeCallout(new List<Id>{sRRecord.Id}, true);
                                }               
                            }else{
                                   List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();
            					   for (InstallmentLines__c ilRecord:  [SELECT Id, Name, LPCFreezeDate__c, LPCFreezeUntilDate__c FROM InstallmentLines__c WHERE SalesOrder__c =: sRRecord.SalesOrder__c]) {
                                        ilRecord.LPCFreezeUntilDate__c = ilRecord.LPCFreezeUntilDate__c <> null && ilRecord.LPCFreezeUntilDate__c > Date.Today()+30 ? ilRecord.LPCFreezeUntilDate__c : Date.Today() + 30;
                                        installmentLinesList.add(ilRecord);
                                    }
                                    if(!installmentLinesList.isEmpty()){
                                        update installmentLinesList;
                                    }                                    
                                   // updateServiceRequestStep(sRRecord.Id, stp.HexaBPM__Summary__c, Constants.COMPLETED_STATUS, '');
                                    sRRecord.LPCFreezeStatus__c = Constants.STATUS_IN_PROGRESS;
                                    update srRecord;
                                    LPCCalloutHelper.getDataForFreezeCallout(new List<Id>{sRRecord.Id}, true);
                            }                        
                        }
                    } else{
                        if(sRRecord.LPCFreezeStatus__c != 'Synced'){
                            return Utilities.getSystemMessages(Constants.LPC_FREEZE_STATUS_VALIDATION).Message__c;
                        }
                    }
                }
            }
        } catch(Exception e){
            result = e.getMessage()+' :CC_VerifyLPCWaverRequest';
        }
        return result;
    }

    public static void updateInstallmentLines(String salesOrderId, HexaBPM__Service_Request__c srRecord) {
        List<InstallmentLines__c> installmentLinesList = [SELECT Id, Name, LPCFreezeDate__c, LPCFreezeUntilDate__c FROM InstallmentLines__c 
                                                            WHERE SalesOrder__c =: salesOrderId];
                    
        for (InstallmentLines__c ilRecord: installmentLinesList) {
            ilRecord.LPCFreezeDate__c = null;
            ilRecord.LPCFreezeUntilDate__c = null;
        }
        update installmentLinesList;
        Map<Id,InstallmentLines__c> mortgageFreezeUpdateMap = mortgageFreezeUpdate(installmentLinesList);
        if(mortgageFreezeUpdateMap <> null && !mortgageFreezeUpdateMap.values().isEmpty()){
            update mortgageFreezeUpdateMap.values();
        }
        HexaBPM__SR_Status__c srStatus = [SELECT id,name FROM HexaBPM__SR_Status__c WHERE name='Closed'];
        srRecord.LPCFreezeStatus__c = Constants.STATUS_IN_PROGRESS;
        srRecord.HexaBPM__Internal_SR_Status__c = srStatus.Id; //SS_IF_DM_REJECTED_THEN_CLOSE_SR
        update srRecord;
        LPCCalloutHelper.getDataForFreezeCallout(new List<Id>{srRecord.Id}, true);
    }
    
    public static void updateServiceRequestStep(String srId, String stepName, String stepStatus, String stepNotes){
        HexaBPM__Step__c stepRec = [SELECT Name, HexaBPM__Step_Status__c, HexaBPM__SR__c, HexaBPM__SR_Step__r.Name, HexaBPM__Step_Notes__c, HexaBPM__Summary__c 
                                    FROM HexaBPM__Step__c
                                    WHERE HexaBPM__SR__c =: srId AND HexaBPM__Summary__c =: stepName order by CreatedDate Desc limit 1];
        
        if(stepStatus != ''){
            HexaBPM__Status__c stepStatusRecord = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name=: stepStatus];
            stepRec.HexaBPM__Status__c = stepStatusRecord.Id;
        }
        
        if(stepNotes != ''){
            stepRec.HexaBPM__Step_Notes__c = stepNotes;
        }
        update stepRec;
    }

    public static ReceiptAcknowledgement__c prepareReceiptAck(HexaBPM__Service_Request__c sRRecord) {
        ReceiptAcknowledgement__c rack = new ReceiptAcknowledgement__c();
        
        //Decimal chargeAmount = [SELECT ChargeAmount__c from ChargeRule__c WHERE SRType__c =:Constants.LPC_WAIVER_TYPE AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]?.ChargeAmount__c;
        Decimal chargeAmount = 0;
        for(ChargeRule__c chargeRule : [SELECT ChargeAmount__c,ChargePercentage__c,VATChanges__c from ChargeRule__c WHERE SRType__c =:Constants.LPC_WAIVER_TYPE AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]){
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
           //Commneted BY Yash shrivastava for regenerate payment link issue. (Arvind)
           //rack.EncryptedRecordId__c = EncodingUtil.urlEncode(EncryptionUtils.encryptString(sRRecord.Id+''), 'UTF-8');
            rack.PaymentLinkExpiry__c = system.now().addMinutes(timerDetails);    
            insert rack;
        }
        
        return rack;
    }
    public static Map<Id,InstallmentLines__c> mortgageFreezeUpdate(List<InstallmentLines__c> instList){
        Set<Id> instIdset = new Set<Id>();
        Map<Id,InstallmentLines__c> installmentMap = new Map<Id,InstallmentLines__c>();
        for(InstallmentLines__c inst: instList){
            instIdset.add(inst.Id);
        }
        for(ReceiptAllocation__c rAlloc:[SELECT Id,ReceiptAcknowledgement__r.ChequeReceivedDate__c,InstallmentLine__r.LPCFreezeUntilDate__c,InstallmentLine__r.LPCFreezeDate__c,InstallmentLine__c,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.PaymentType__c FROM ReceiptAllocation__c WHERE InstallmentLine__c IN: instIdset AND ReceiptAcknowledgement__r.PaymentType__c ='Mortgage Cheque' AND ReceiptAcknowledgement__r.ChequeReceivedDate__c!=null]){
            InstallmentLines__c instObj = new InstallmentLines__c();
            instObj.Id = rAlloc.InstallmentLine__c;
            instObj.LPCFreezeDate__c = rAlloc.ReceiptAcknowledgement__r.ChequeReceivedDate__c;
            instObj.LPCFreezeUntilDate__c = rAlloc.ReceiptAcknowledgement__r.ChequeReceivedDate__c.addMonths(6);
            installmentMap.put(instObj.Id,instObj);
        }
       return installmentMap;
    }
}