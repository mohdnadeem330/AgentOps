@IsTest
public class ECSS_LeadOverrideHelper_test {
    @IsTest
    static void testHasECSSPermission() {
        Boolean result = ECSS_LeadOverrideHelper.hasECSSPermission();
        System.debug('hasECSSPermission result: ' + result);
    }
}