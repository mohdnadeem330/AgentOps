/*
* Purpose: Charges depending on Service Request SR Type and Charge Type
*/
public with sharing class ChargeRuleService {
    public ChargeRuleService() {}

    public static List<ChargeRuleModel> getChargeRuleByType(List<HexaBPM__Service_Request__c> serviceRequestList) {
        List<ChargeRuleModel> returnList = new List<ChargeRuleModel>();

        Set<String> srTypeList = new Set<String>();
        Set<String> chargeTypeList = new Set<String>();
        Map<String, String> serviceRequestMapByType = new Map<String, String>();
        for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
            srTypeList.add(serviceRequest.SRType__c);
            chargeTypeList.add(serviceRequest.ChargeType__c);
            serviceRequestMapByType.put(serviceRequest.SRType__c + '_' + serviceRequest.ChargeType__c, serviceRequest.Id);
        }
        
        List<ChargeRule__c> chargeRuleList = [SELECT Id, Name, SRType__c, ChargeType__c, ChargeAmount__c, ChargePercentage__c, Project__c, 
                                                StartDate__c, EndDate__c, IsActive__c, VATChanges__c FROM ChargeRule__c WHERE IsActive__c = true AND 
                                                SRType__c IN: srTypeList AND ChargeType__c IN: chargeTypeList];

        for (ChargeRule__c chargeRule: chargeRuleList) {
            String type = chargeRule.SRType__c + '_' + chargeRule.ChargeType__c;
            if (!serviceRequestMapByType.isEmpty() && serviceRequestMapByType.containsKey(type)) {
                ChargeRuleModel charge = new ChargeRuleModel();
                charge.chargeRuleId = chargeRule.Id;
                charge.serviceRequestId = serviceRequestMapByType.get(type);
                charge.vatChanges = chargeRule.VATChanges__c;
                if(chargeRule.ChargeAmount__c != null && chargeRule.ChargeAmount__c != 0){
                    charge.chargeAmountPercentage = chargeRule.ChargeAmount__c;
                    charge.isPercentage = false;
                } else if (chargeRule.ChargePercentage__c != null && chargeRule.ChargePercentage__c != 0) {
                    charge.chargeAmountPercentage = chargeRule.ChargePercentage__c;
                    charge.isPercentage = true;
                } else {
                    charge.serviceRequestId = serviceRequestMapByType.get(type);
                    charge.chargeAmountPercentage = 0;
                }
                returnList.add(charge);
            }
        }
        return returnList;
    }
}