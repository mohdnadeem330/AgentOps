public without sharing class MonthlySalesTargetService {
    public static AggregateResult[] fetchMonthlySalesTargetForAPIByUser(String userId) {
        String currentYear = String.valueOf(Date.today().year());
        return [SELECT SUM(LaunchTargetAmount__c) launchTarget, SUM(LaunchAchievedAmount__c) launchAchieved, SUM(InventoryTargetAmount__c) inventoryTarget, SUM(InventoryAchievedAmount__c) inventoryAchieved FROM MonthlySalesTarget__c WHERE TargetYear__c =: currentYear AND ResourceName__c =: userId];
    }

    public static List<MonthlySalesTarget__c> fetchAgentRank(String userId) {
        String currentYear = String.valueOf(Date.today().year());
        String currentMonth = String.valueOf(Date.today().month());
        return [SELECT Id, AgentRank__c FROM MonthlySalesTarget__c WHERE TargetMonth__c =: currentMonth AND TargetYear__c =: currentYear AND ResourceName__c =: userId LIMIT 1];
    }

    public static AggregateResult[] fetchMonthlySalesTargetRank() {
        String currentYear = String.valueOf(Date.today().year());
        String salesManagerProfile = Constants.SALES_MANAGER;
        return [SELECT SUM(TargetAmount__c) target, SUM(AchievedAmount__c) achieved, ResourceName__c FROM MonthlySalesTarget__c WHERE TargetYear__c =: currentYear AND ResourceName__r.Profile.Name =: salesManagerProfile AND TargetAmount__c > 0 GROUP BY ResourceName__c];
    }
}