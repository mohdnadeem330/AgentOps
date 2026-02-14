public class SRPostPaymentHandler {
    /*public static void chequeReplacementTypePayment(Map<Id, HexaBPM__Service_Request__c> srIdWithSR,Map<Id, ReceiptAcknowledgement__c> srIdWithRcptAcknowledgmentMap){
        Savepoint sp = Database.setSavepoint();
        try {
            List<SalesOrderOtherCharges__c> insertedOtherChargeList = createOtherCharge(srIdWithSR,srIdWithRcptAcknowledgmentMap);
            if(insertedOtherChargeList <> null && insertedOtherChargeList.size() > 0 && !srIdWithRcptAcknowledgmentMap.isEmpty()){
                createReceiptAllocation(insertedOtherChargeList,srIdWithRcptAcknowledgmentMap);
            } else {
                Database.rollback(sp);
            }           
        } catch(Exception ex) {
            System.debug('EXCEPTION '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber()+' ## '+ex.getStackTraceString());
            Database.rollback(sp);
        }        
    }*/

    public static void lpcWaiverTypePayment(Map<Id, HexaBPM__Service_Request__c> srIdWithSR,Map<Id, ReceiptAcknowledgement__c> srIdWithRcptAcknowledgmentMap){
        Savepoint sp = Database.setSavepoint();
        try {
            List<SalesOrderOtherCharges__c> insertedOtherChargeList = createOtherCharge(srIdWithSR,srIdWithRcptAcknowledgmentMap);
            if(insertedOtherChargeList <> null && insertedOtherChargeList.size() > 0 && !srIdWithRcptAcknowledgmentMap.isEmpty()){
                createReceiptAllocation(insertedOtherChargeList,srIdWithRcptAcknowledgmentMap);
            } else {
                Database.rollback(sp);
            }           
        } catch(Exception ex) {
            System.debug('EXCEPTION '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber()+' ## '+ex.getStackTraceString());
            Database.rollback(sp);
        } 
    }

    public static void paymentExtensionTypePayment(Map<Id, HexaBPM__Service_Request__c> srIdWithSR,Map<Id, ReceiptAcknowledgement__c> srIdWithRcptAcknowledgmentMap){
        Savepoint sp = Database.setSavepoint();
        try {
            List<SalesOrderOtherCharges__c> insertedOtherChargeList = createOtherCharge(srIdWithSR,srIdWithRcptAcknowledgmentMap);
            if(insertedOtherChargeList <> null && insertedOtherChargeList.size() > 0 && !srIdWithRcptAcknowledgmentMap.isEmpty()){
                createReceiptAllocation(insertedOtherChargeList,srIdWithRcptAcknowledgmentMap);
            } else {
                Database.rollback(sp);
            }           
        } catch(Exception ex) {
            System.debug('EXCEPTION '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber()+' ## '+ex.getStackTraceString());
            Database.rollback(sp);
        } 
    }

    public static List<SalesOrderOtherCharges__c> createOtherCharge(Map<Id, HexaBPM__Service_Request__c> srIdWithSR,Map<Id,ReceiptAcknowledgement__c> srIdWithRcptAcknowledgement) {
        //Decimal chargeAmount = ([SELECT ChargePercentage__c from ChargeRule__c WHERE SRType__c =:Constants.PAYMENT_EXTENSION_TYPE AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]?.ChargePercentage__c * sRRecord.InstallmentLine__r.OutstandingAmount__c)/100;
        Map<String,ChargeRule__c> srTypeWithChargeRuleMap = new Map<String,ChargeRule__c>();
        for(ChargeRule__c chargeRule : [SELECT SRType__c,ChargeAmount__c,VATChanges__c,ChargePercentage__c from ChargeRule__c WHERE SRType__c IN ('Payment Extension','LPC Waiver','Cheque Replacement','Payment Plan Change','Investor Certificate','Letter Issuance','Attested SPA') AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate ASC]){
            srTypeWithChargeRuleMap.put(chargeRule.SRType__c,chargeRule);
        }
        List<SalesOrderOtherCharges__c> otherChargeToInsert = new List<SalesOrderOtherCharges__c>();
        try{ 
            for(HexaBPM__Service_Request__c tempSRRecord : srIdWithSR.values()){
                if(srIdWithRcptAcknowledgement.containsKey(tempSRRecord.Id) && srTypeWithChargeRuleMap.containsKey(tempSRRecord.SRType__c)) {
                    Decimal amountWithoutVAT = 0;
                    if(tempSRRecord.SRType__c == 'Payment Extension'){
                        amountWithoutVAT = tempSRRecord.Payment_Extension_Period_In_Days__c <> 0 && tempSRRecord.Payment_Extension_Period_In_Days__c <> null ? (srTypeWithChargeRuleMap.get(tempSRRecord.SRType__c).ChargePercentage__c * tempSRRecord.InstallmentLine__r.OutstandingAmount__c * tempSRRecord.Payment_Extension_Period_In_Days__c)/100 : (srTypeWithChargeRuleMap.get(tempSRRecord.SRType__c).ChargePercentage__c * tempSRRecord.InstallmentLine__r.OutstandingAmount__c)/100;
                    } else {
                        amountWithoutVAT = srTypeWithChargeRuleMap.get(tempSRRecord.SRType__c).ChargeAmount__c;
                    }
                    Decimal vatAmount = (amountWithoutVAT * srTypeWithChargeRuleMap.get(tempSRRecord.SRType__c).VATChanges__c)/100;
                    Decimal chargeAmount = amountWithoutVAT + vatAmount;
                    //Create Other charge
                    otherChargeToInsert.add(new SalesOrderOtherCharges__c(
                        Account__c = tempSRRecord.HexaBPM__Customer__c,
                        SalesOrder__c = tempSRRecord.SalesOrder__c,
                        Amount__c = chargeAmount,
                        VATAmount__c = vatAmount,
                        AmountWithoutVAT__c = amountWithoutVAT,
                        TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE,
                        ServiceRequest__c = tempSRRecord.Id,
                        Description__c = tempSRRecord.Exceptional_Reason__c,
                        SyncStatus__c = Constants.STATUS_IN_PROGRESS
                    ) );
                }
            }
            if(!otherChargeToInsert.isEmpty()){
                insert otherChargeToInsert;               
            }
        } catch(Exception ex) {
            createLog(ex, 'ServiceFee SR Process', 'SRPostPaymentHandler', 'createOtherCharge');
        }
        return otherChargeToInsert;
    }

    public static void createReceiptAllocation(List<SalesOrderOtherCharges__c> insertedOtherChargeList,Map<Id, ReceiptAcknowledgement__c> srIdWithRcptAcknowledgmentMap){
        List<ReceiptAllocation__c> rcptAllocationsToInsert = new List<ReceiptAllocation__c>();
        try {
            for(SalesOrderOtherCharges__c eachInsertedOtherCharge : insertedOtherChargeList){
                if(srIdWithRcptAcknowledgmentMap.containsKey(eachInsertedOtherCharge.ServiceRequest__c)) {
                    ReceiptAllocation__c allocationRecord = new ReceiptAllocation__c();
                    allocationRecord.Account__c = eachInsertedOtherCharge.Account__c;
                    allocationRecord.SalesOrder__c = eachInsertedOtherCharge.SalesOrder__c;
                    allocationRecord.AmountApplied__c = eachInsertedOtherCharge.Amount__c;
                    allocationRecord.ReceiptAcknowledgement__c = srIdWithRcptAcknowledgmentMap.get(eachInsertedOtherCharge.ServiceRequest__c).Id;
                    allocationRecord.SalesOrderOtherCharges__c = eachInsertedOtherCharge.Id;
                    allocationRecord.TypeOfInvoice__c = Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE;
                    rcptAllocationsToInsert.add(allocationRecord);
                }                
            }
            if(!rcptAllocationsToInsert.isEmpty()){
                insert rcptAllocationsToInsert;               
            }
        } catch(Exception ex) {
            createLog(ex, 'ServiceFee SR Process', 'SRPostPaymentHandler', 'createReceiptAllocationAndUpdateReceiptAcknowledgement');
        }
    }

    private static void createLog(Exception ex, String ProcessName, String ClassName, String MethodName) {
        Logger__c lg = LoggerService.addApexLog(ex, ProcessName, ClassName, MethodName);
        insert lg;
        System.debug('EXCEPTION '+ClassName+' ** '+lg.Id+' ** '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber()+' ## '+ex.getStackTraceString());
    }
}