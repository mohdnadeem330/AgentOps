@IsTest
public class ECSS_DecodeIdHelper_Test {
    
   
    @IsTest
    static void testDecodeWithValidSalesforceId() {
        // Directly pass a normal Id (should just return same)
        Account acc = new Account(Name = 'Direct Id Test');
        insert acc;
        
        Test.startTest();
        List<String> decodedList = ECSS_DecodeIdHelper.decodeIds(new List<String>{ acc.Id });
        Test.stopTest();
        
        System.assertEquals(acc.Id, decodedList[0], 'Valid SFDC Id should return as-is');
    }
    
    
     @IsTest
    static void testDecodeWithUser() {
        // Directly pass a normal Id (should just return same)
       User cca = TestObjectsFactory.getUserRecord(Constants.CONTACT_CENTER_AGENT, 'cca1');
        System.runAs(cca) {
        Account acc = new Account(Name = 'Direct Id Test');
        insert acc;
        
        Test.startTest();
        List<String> decodedList = ECSS_DecodeIdHelper.decodeIds(new List<String>{ acc.Id });
        Test.stopTest();
        
        System.assertEquals(acc.Id, decodedList[0], 'Valid SFDC Id should return as-is');
        }
    }
    

}