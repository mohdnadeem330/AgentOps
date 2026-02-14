@IsTest
private class AccountSearchControllerTest {
    @IsTest
    static void testSearchCases() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Call the method to test
        Test.startTest();
        List<Case> results = AccountSearchController.searchCases('Test');
        Test.stopTest();
        
        // Assert the results
        System.assertEquals(0, results.size(), 'Expected no cases to be returned as we did not create any');
    }
    
}