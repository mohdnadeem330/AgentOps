@IsTest
public class ECSS_EncodeIdHelper_Test {
    
    @IsTest
    static void testEncodeIds() {
        // Create a test record to get an Id
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Input recordIds list
        List<String> inputIds = new List<String>{ acc.Id };
        
        // Call the method
        Test.startTest();
        List<String> encodedIds = ECSS_EncodeIdHelper.encodeIds(inputIds);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, encodedIds, 'Encoded Ids list should not be null');
        System.assertEquals(1, encodedIds.size(), 'Only one record should be encoded');
        System.assertNotEquals('', encodedIds[0], 'Encoded Id should not be blank');
        
        // Check that result is URL safe (no + / =)
        System.assert(encodedIds[0].indexOf('+') == -1, 'Encoded string should not contain +');
        System.assert(encodedIds[0].indexOf('/') == -1, 'Encoded string should not contain /');
        System.assert(encodedIds[0].indexOf('=') == -1, 'Encoded string should not contain =');
    }
}