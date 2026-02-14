@isTest
private class MobileConfigurationsUtilityTest {
    
    static testmethod void testMobilityConfi() {
        Test.startTest();
        MobileAppConfiguration__mdt configData = MobileConfigurationsUtility.getMobileConfiguration('Android');
        MobileConfigurationsUtility.isOnLatestVersion(String.valueOf(configData.LatestAppVersion__c), String.valueOf(configData.LatestBuildNumber__c+1), configData);
        Test.stopTest();
    }

}