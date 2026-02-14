@isTest
public class ECSS_Invocable_GetObjectNameTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }
    
    @isTest
    static void testGetObjectName() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<ECSS_Invocable_GetObjectName.Input> inputList = new List<ECSS_Invocable_GetObjectName.Input>();
        ECSS_Invocable_GetObjectName.Input input = new ECSS_Invocable_GetObjectName.Input();
        input.Record = testAccount.Id;
        inputList.add(input);
        Test.startTest();
        List<ECSS_Invocable_GetObjectName.Output> outputList = ECSS_Invocable_GetObjectName.getOabjectName(inputList);
        Test.stopTest();
        System.assertEquals(1, outputList.size(), 'There should be one output record.');
    }
    
    @isTest
    static void testInvalidRecordId() {
        List<ECSS_Invocable_GetObjectName.Input> inputList = new List<ECSS_Invocable_GetObjectName.Input>();
        ECSS_Invocable_GetObjectName.Input input = new ECSS_Invocable_GetObjectName.Input();
        input.Record = '001';
        inputList.add(input);
        Test.startTest();
        List<ECSS_Invocable_GetObjectName.Output> outputList = ECSS_Invocable_GetObjectName.getOabjectName(inputList);
        Test.stopTest();
    }
    
    @isTest
    static void testBlankRecordId() {
        List<ECSS_Invocable_GetObjectName.Input> inputList = new List<ECSS_Invocable_GetObjectName.Input>();
        ECSS_Invocable_GetObjectName.Input input = new ECSS_Invocable_GetObjectName.Input();
        input.Record = '';
        inputList.add(input);
        Test.startTest();
        List<ECSS_Invocable_GetObjectName.Output> outputList = ECSS_Invocable_GetObjectName.getOabjectName(inputList);
        Test.stopTest();
        System.assertEquals(0, outputList.size(), 'There should be no output for a blank record ID.');
    }
}