public class ECSS_LeadOverrideHelper {
    @AuraEnabled(cacheable=true)
    public static Boolean hasECSSPermission() {
        return FeatureManagement.checkPermission('ECSS_Lead'); // API Name of your custom permission
    }
}