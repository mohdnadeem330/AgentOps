@IsTest
public class FeatureFlagUtilTest {
    @IsTest
    static void testFeatureDisabled() {
        try{
            // Feature that is disabled
            Boolean result1 = FeatureFlagUtil.isFeaturedisabled('Test_Feature');
           
            // Feature that is enabled
            Boolean result2 = FeatureFlagUtil.isFeaturedisabled('Enabled_Feature');
           
            // Non-existent feature
            Boolean result3 = FeatureFlagUtil.isFeaturedisabled('Non_Existent_Feature');
        }catch(exception e){
            
        }               
    }
}