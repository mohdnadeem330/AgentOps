@isTest
public class ALD_ProfilePermissionSetAutomationTest 
{
    @isTest static void test1Method() 
    {
        User userRecord1 = TestObjectsFactory.getUserRecord('Sales Manager', 'testUser');
        insert userRecord1;
    }
    
    @IsTest
    static void testBatchMethod()
    {
        Test.startTest();
        ALD_BatchToAssignPSLandPS b = new ALD_BatchToAssignPSLandPS();
        Database.executeBatch(b, 2000);
        Test.stopTest();
    }
        
}