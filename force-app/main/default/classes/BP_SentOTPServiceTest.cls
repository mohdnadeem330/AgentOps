@istest
public class BP_SentOTPServiceTest {
 @isTest
    public static void testConstructor() {
       
        Test.startTest();
        
        
        BP_SentOTPService service = new BP_SentOTPService();
        
        Test.stopTest();
        
      
        System.assertNotEquals(service, null, 'BP_SentOTPService instance should not be null');
    }
}