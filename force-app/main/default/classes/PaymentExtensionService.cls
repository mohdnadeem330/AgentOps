/*
*********************************************************
Apex Class Name    : PaymentExtensionService
Created Date       : June 27 2025
@description       : This Class is used for Specfic for PaymentExtension Service Requests
@author            : 
Modification Log:
Ver   Date         Author                         Modification
1.0   27-06-2025                                  Initial Version
*********************************************************
*/
public with sharing class PaymentExtensionService {
    
    public static final Set<String> srTempNames = new Set<String> {
        Constants.CHEQUE_REPLACEMENT_SR_TYPE,
        Constants.PAYMENT_EXTENSION_SR_TYPE
    };
    public static Map <String, HexaBPM__SR_Template__c> srTempMap;
    public static Map<String, HexaBPM__SR_Template__c> getsrTempMap() {
        if (srTempMap == null) {
            srTempMap = AldarUtilityClass.fetchSRTemplate(srTempNames);
        }
        return srTempMap;
    }
    /*
    *********************************************************
    @Method Name    : paymentExtensionHelperMethod
    @author         : 
    @description    : Method to calculate Payment Extension Value
    @param          : paymentExtSR 
    @return         : void
    ********************************************************
    */
    public static void paymentExtensionHelperMethod(List<HexaBPM__Service_Request__c> paymentExtSR){        
        for(HexaBPM__Service_Request__c paymentExtensionSR : paymentExtSR){
            if(paymentExtensionSR.InstallmentDate__c != null && paymentExtensionSR.PaymentExtensionDate__c != null){
                Integer monthDiff = paymentExtensionSR.InstallmentDate__c.monthsBetween(paymentExtensionSR.PaymentExtensionDate__c);
                if (paymentExtensionSR.PaymentExtensionDate__c.day() >= paymentExtensionSR.InstallmentDate__c.day()) {
                    monthDiff++;
                }
                paymentExtensionSR.PaymentExtensionPeriod__c = monthDiff;
            }
            if(paymentExtensionSR.SRType__c == Constants.CHEQUE_REPLACEMENT_SR_TYPE){
                paymentExtensionSR.HexaBPM__SR_Template__c = getsrTempMap().get(Constants.CHEQUE_REPLACEMENT_SR_TYPE)?.Id;
            } else {
                paymentExtensionSR.HexaBPM__SR_Template__c = getsrTempMap().get(Constants.PAYMENT_EXTENSION_SR_TYPE)?.Id;
            }
        }
    }    
	/*
    *********************************************************
    @Method Name    : paymentExtChargeCalUpdate
    @author         : 
    @description    : Method to calculate Payment Extension Value
    @param          : paymentExtSR 
    @return         : void
    ********************************************************
    */
    public static void paymentExtChargeCalUpdate(List<HexaBPM__Service_Request__c> newSRList,Set<String> serviceChargeSRTypeSet,Set<Id> installmentLinesIdSet) {                  
        Map<Id,InstallmentLines__c> installmentLineMap = new Map<Id,InstallmentLines__c>();
        Map<String,ChargeRule__c> chargeRuleMap = ServiceRequestTriggerHelper.getsrTypeChargeDetailsMap(serviceChargeSRTypeSet); 
        installmentLineMap = ServiceRequestTriggerHelper.getinstallmentLineMap(installmentLinesIdSet);       
        for(HexaBPM__Service_Request__c srRecord : newSRList) {
            Decimal chargeAmount = 0;
            Decimal amountWithoutVAT = 0;
            Decimal vatAmount = 0;            
            ChargeRule__c chargeRule = chargeRuleMap.get(srRecord.SRType__c);
            if(srRecord.SRType__c == Constants.PAYMENT_EXTENSION_TYPE && chargeRule <> null) {                
                if(srRecord.InstallmentLine__c <> NULL && installmentLineMap.containsKey(srRecord.InstallmentLine__c) && installmentLineMap.get(srRecord.InstallmentLine__c).OutstandingAmount__c <> NULL){
                    amountWithoutVAT = srRecord.Payment_Extension_Period_In_Days__c <> 0 && srRecord.Payment_Extension_Period_In_Days__c <> null ? (chargeRule.ChargePercentage__c * installmentLineMap.get(srRecord.InstallmentLine__c).OutstandingAmount__c * srRecord.Payment_Extension_Period_In_Days__c)/100 : (chargeRule.ChargePercentage__c * installmentLineMap.get(srRecord.InstallmentLine__c).OutstandingAmount__c)/100;
                    vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
                    chargeAmount = amountWithoutVAT + vatAmount;
                    srRecord.Calculated_Service_Charge__c = chargeAmount;
                }
            }//ALL OTHERS
            else if(chargeRule <> null){
                amountWithoutVAT = chargeRule.ChargeAmount__c;
                vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
                chargeAmount = amountWithoutVAT + vatAmount;
                srRecord.Calculated_Service_Charge__c = chargeAmount;
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : payMentExtDateUpdate
    @author         : 
    @description    : Method to update Payment Extension Date
    @param          : paymentExtSR 
    @return         : void
    ********************************************************
    */
    public static void payMentExtDaysUpdate(List<HexaBPM__Service_Request__c> newSRList,Set<Id> installmentLinesIdSet) {                
        Map<Id,InstallmentLines__c> installmentLineMap = ServiceRequestTriggerHelper.getinstallmentLineMap(installmentLinesIdSet);         
        for(HexaBPM__Service_Request__c paymentExtSR : newSRList) {
            if(installmentLineMap.containsKey(paymentExtSR.InstallmentLine__c) && installmentLineMap.get(paymentExtSR.InstallmentLine__c).InstallmentDate__c <> null) {
                Integer monthDiff = installmentLineMap.containsKey(paymentExtSR.InstallmentLine__c) ? installmentLineMap.get(paymentExtSR.InstallmentLine__c).InstallmentDate__c.monthsBetween(paymentExtSR.PaymentExtensionDate__c):0;
                Integer daysDiff = installmentLineMap.containsKey(paymentExtSR.InstallmentLine__c) ? installmentLineMap.get(paymentExtSR.InstallmentLine__c).InstallmentDate__c.daysBetween(paymentExtSR.PaymentExtensionDate__c):0;                
                if (installmentLineMap.containsKey(paymentExtSR.InstallmentLine__c) && paymentExtSR.PaymentExtensionDate__c.day() >= installmentLineMap.get(paymentExtSR.InstallmentLine__c).InstallmentDate__c.day()) {
                    monthDiff++;
                }                
                paymentExtSR.PaymentExtensionPeriod__c = monthDiff;
                paymentExtSR.Payment_Extension_Period_In_Days__c = daysDiff;
            }
        }        
    }
    /*
    *********************************************************
    @Method Name    : paymentExtPerUpdate
    @author         : 
    @description    : Method to update Payment Extension Period
    @param          : paymentExtSR 
    @return         : void
    ********************************************************
    */
    public static void paymentExtPerUpdate(List<HexaBPM__Service_Request__c> paymentExtSRList) {
        for(HexaBPM__Service_Request__c paymentExtSR : paymentExtSRList) {
            Integer monthDiff = paymentExtSR.InstallmentDate__c.monthsBetween(paymentExtSR.PaymentExtensionDate__c);
            if (paymentExtSR.PaymentExtensionDate__c.day() >= paymentExtSR.InstallmentDate__c.day()) {
                monthDiff++;
            }
            paymentExtSR.PaymentExtensionPeriod__c = monthDiff;
        }
    }    
}