public class NewRecordController {
    @AuraEnabled
    public static Account getAccount(String rId) {
        Account acc = new Account();
        try {
            List<Account> accList = AccountService.queryAllFieldsWithExtraFields(new List<Id>{rId});
            acc = accList[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return acc;
    }

    @AuraEnabled
    public static String getRecordTypeId(String objName, String recordType) {
        return Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfosByName().get(recordType).getRecordTypeId();
    }
    
    @AuraEnabled
    public static Boolean checkOpportunity(String srId) {
        List<Opportunity> oppList = OpportunityService.fetchOpportunities(' ServiceRequest__c = \'' + srId + '\' ');
        if (!oppList.isEmpty()) {
            return true;
        }
        return false;
    }
}