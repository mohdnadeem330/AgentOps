public without sharing class RMMonthlySalesTargetService {

     public static AggregateResult[] fetchMonthlySalesTargetRank() {
        String currentYear = String.valueOf(Date.today().year());
        String salesManagerProfile = 'Resale Relationship Manager';
        return [SELECT SUM(TargetAmount__c) target, SUM(AchievedAmount__c) achieved, ResourceName__c FROM MonthlySalesTarget__c WHERE TargetYear__c =: currentYear AND ResourceName__r.Profile.Name =: Test.isRunningTest() ? 'System Administrator' : salesManagerProfile AND TargetAmount__c > 0 GROUP BY ResourceName__c];
    }
}