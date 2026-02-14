global without sharing class CC_LPCWaverFinalApproval implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_LPCWaverFinalApproval: Invalid SR or SR Step';
            }else{
                
                HexaBPM__Service_Request__c sRRecord = [SELECT Id, TotalLPCAmount__c, WaivedAmount__c, HexaBPM__Customer__c, HexaBPM__Contact__c, SalesOrder__c, SalesOrder__r.Opportunity__c, 
                                                        ChargeCollected__c, InstallmentLine__c, WaivedPercentage__c, IsChargeReceiptCreated__c, LPCFreezeStatus__c 
                                                        FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                List<SalesOrderOtherCharges__c> lpcSOchargesList = [SELECT Id,InvoicedAmount__c FROM SalesOrderOtherCharges__c WHERE TypeOfCharge__c ='Late Payment Charges' AND ServiceRequest__c =:stp.HexaBPM__SR__c];
                
                if(sRRecord.TotalLPCAmount__c == null){
                    return Utilities.getSystemMessages(Constants.TOTAL_LPC_AMOUNT_VERIFY_REQUIST_STEP).Message__c;
                }
                
                if(sRRecord.WaivedAmount__c == null){
                    return Utilities.getSystemMessages(Constants.LPC_WAINER_AMOUNT_VERIFY_REQUIST_STEP).Message__c;
                }
                
                if(!sRRecord.IsChargeReceiptCreated__c && sRRecord.WaivedPercentage__c < 100){
                    return Utilities.getSystemMessages(Constants.LPC_ENTER_REICEPT_ERROR).Message__c;
                }
                
                if(sRRecord.LPCFreezeStatus__c != 'Synced'){
                    return Utilities.getSystemMessages(Constants.LPC_FREEZE_STATUS_VALIDATION).Message__c;
                }
                
                SalesOrderOtherCharges__c waivedAmountOtherCharges;
                if(lpcSOchargesList.isEmpty()){
                	waivedAmountOtherCharges = SRUtility.createSalesOrderOtherCharge(sRRecord,Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT,sRRecord.WaivedAmount__c);
                }
                if(sRRecord.WaivedPercentage__c == 100){
                    LPCCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
                    return result;
                }
                
                List<ReceiptAcknowledgement__c> rAccs = [Select Id, Name, ServiceRequest__c, Account__c, SalesOrder__c, Amount__c, Status__c,OutstandingAmount__c From ReceiptAcknowledgement__c Where ServiceRequest__c=: sRRecord.Id and Receipt_Type__c != 'Charge Fee' AND OutstandingAmount__c!=0 and OutstandingAmount__c!=null order by OutstandingAmount__c ASC]; //SS_MULTIPLE_RECEIPTS_TO_SINGLE_OC_IN_SR
                
                List<ReceiptAllocation__c> allocationRecordList = new List<ReceiptAllocation__c>();
                
                Decimal totalReceived = 0;
                for(ReceiptAcknowledgement__c ra:rAccs) {
                    if(ra.Status__c != Constants.RECEIPT_STATUS_CLEARED){
                        return Utilities.getSystemMessages(Constants.LPC_RECEPT_NOT_PAID).Message__c;
                    } else {
                        totalReceived = totalReceived + ra.OutstandingAmount__c;
                    }
                    System.debug('### 2 rAccs '+rAccs.size());
                }
                System.debug('### TT totalReceived -> '+totalReceived);
                System.debug('### TT ChargeCollected__c -> '+sRRecord.ChargeCollected__c);
              
                if((totalReceived + Decimal.valueOf(System.Label.LPCChargesBufferAmount) < sRRecord.ChargeCollected__c) && (lpcSOchargesList.isEmpty() || (!lpcSOchargesList.isEmpty() && lpcSOchargesList[0].InvoicedAmount__c <> null &&  lpcSOchargesList[0].InvoicedAmount__c+Decimal.valueOf(System.Label.LPCChargesBufferAmount) < sRRecord.ChargeCollected__c))) {
                    //If the SR LPC Amount not matching to the Sum of Receipts outstading, then error will throw
                    return Utilities.getSystemMessages(Constants.LPC_RECEPT_NOT_PAID).Message__c;
                }
                SalesOrderOtherCharges__c customerPaidAmountOtherCharges;
                 if(lpcSOchargesList.isEmpty()){
                  customerPaidAmountOtherCharges   = SRUtility.createSalesOrderOtherCharge(sRRecord,Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES ,sRRecord.ChargeCollected__c);
                 }
                Decimal chargeToBeCollected = sRRecord.ChargeCollected__c;
                Decimal chargeCollected = 0;
                Integer numberOfAllocation = 0;
                System.debug('### 1 rAccs  '+rAccs.size());
                for(ReceiptAcknowledgement__c ra:rAccs) {
                    
                    if(ra.OutstandingAmount__c == 0 || ra.OutstandingAmount__c == null) {
                        //If the receipt don't have outstanding but tagged to the SR, then it should be removed from the SR, so setting below attribute to 0\\\\\\\\\\\\\\\
                        numberOfAllocation = 0; //Setting to 0, if 0 or lesser than rAccs size, show error
                        continue;
                    }
                    Decimal remainingTBCollected = (chargeToBeCollected - chargeCollected) - ra.OutstandingAmount__c;
                    Decimal amountToCollect = 0;
                    /*Below is positive case*/
                    //  remainingTBCollected = (2500 - 0) - 1000    = 1500
                    //  So remainingTBCollected = 1500
                    //  amountToCollect = 1000;
                    //  chargeCollected = 1000;
                    
                    //  remainingTBCollected = (2500 - 1000) - 1200 = 300
                    //  So remainingTBCollected = 300
                    //  amountToCollect = 1200;
                    //  chargeCollected = chargeCollected + 1200 = 1000 + 1200 = 2200
                    
                    /*Below is negative case*/
                    //  remainingTBCollected = (2500 - 2200) - 10000 = -9700
                    //  So remainingTBCollected = 2500 - 2200 = 300
                    //  amountToCollect = 300;
                    //  chargeCollected = chargeCollected + 300 = 2200 + 300 = 2500
                    
                    System.debug('### remainingTBCollected -> '+remainingTBCollected);
                    if(remainingTBCollected > 0) {
                        //Positive Value
                        System.debug('### chargeCollected ve '+chargeCollected);
                        System.debug('### OutstandingAmount__c '+ra.OutstandingAmount__c);
                        
                        amountToCollect = ra.OutstandingAmount__c;
                        chargeCollected = chargeCollected + ra.OutstandingAmount__c;
                        
                        System.debug('### chargeCollected +ve '+chargeCollected);
                        System.debug('### amountToCollect >  '+amountToCollect);
                    } else {
                        //Negative Value
                        System.debug('### chargeCollected nve '+chargeCollected);
                        System.debug('### remainingTBCollected '+remainingTBCollected);
                        
                        amountToCollect = chargeToBeCollected - chargeCollected;//remainingTBCollected;
                        chargeCollected = chargeCollected + remainingTBCollected;
                        
                        System.debug('### chargeCollected -ve '+chargeCollected);
                        System.debug('### amountToCollect '+amountToCollect);
                    }
                    
                    System.debug('### amountToCollect >>> on '+ra.Name+' > '+amountToCollect);
                    
                    System.debug('##### chargeCollected '+chargeCollected);
                    System.debug('##### chargeToBeCollected '+chargeToBeCollected);
                    System.debug('##### Amount__c '+amountToCollect);
                    if(chargeCollected < chargeToBeCollected && amountToCollect <= chargeToBeCollected ) {
                        System.debug('##### $$$$ ra Name -> '+ra.Name);
                        //50 < 100
                        ReceiptAllocation__c allocationRecord = new ReceiptAllocation__c();
                        allocationRecord.Account__c = ra.Account__c;
                        allocationRecord.SalesOrder__c = ra.SalesOrder__c;
                        allocationRecord.AmountApplied__c = amountToCollect;//ra.Amount__c;
                        allocationRecord.TypeOfInvoice__c = Constants.LPC_INVOICE_TYPE;
                        allocationRecord.ReceiptAcknowledgement__c = ra.Id;
                        allocationRecord.SalesOrderOtherCharges__c = customerPaidAmountOtherCharges.Id;
                        allocationRecordList.add(allocationRecord);                        
                        numberOfAllocation = numberOfAllocation + 1;
                    }
                }
                if(allocationRecordList.size()>0) {
                    System.debug('### 85 allocationRecordList');
                    insert allocationRecordList;
                }
                if(numberOfAllocation != rAccs.size()) {
                    return 'Please remove the unwanted Receipts > '+numberOfAllocation+' > '+rAccs.size();                
                }
                
                
                LPCCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
            } 
        } catch(Exception e){
            result = e.getMessage()+' :CC_LPCWaverFinalApproval';
        }
        return result;
    }
}