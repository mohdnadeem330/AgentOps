//ECSS
public class ECSSPicklistValueFetcher {
    @AuraEnabled(cacheable=true)
    public static List<String> pickListValues(String compId){
        System.debug('entered the method'+compId);
        if(compId == null || compId == ''){
            return new List<String>();
        }
        Account comp = [SELECT Id, ECSS_Case_Types__c   FROM Account WHERE Id =: compId];
        List<String> outputValues = new List<String>();
        if(comp == null){
            return new List<String>();
        }
        if(comp.ECSS_Case_Types__c == null){
            return new List<String>();
        }
        outputValues = comp.ECSS_Case_Types__c.split(';');
        System.debug('outputValues: '+outputValues);
        return outputValues;
    }
}