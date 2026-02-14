public class FeatureFlagUtil {
	// Returns TRUE if the feature is Disabled
    public static Boolean isFeaturedisabled(String developerName) {
        Feature_Flag__mdt flag = Feature_Flag__mdt.getInstance(developerName);
        // If Custom Metadata record missing, default to false/disabled
        return flag != null && flag.Is_Disabled__c;
    }
}