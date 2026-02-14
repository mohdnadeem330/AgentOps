@IsTest 
private class QueryUtilityClassTest {
    
    @IsTest(SeeAllData=true) 
    public static void checkExceptions() {
        
        try {
            Account testAccount = TestObjectsFactory.getAccountRecord('Organization Account',true,'JO20220212');
            testAccount.Name='===================================================================================================Some string which is longer than 255 characters================================================================================================================';
            insert testAccount;

        } catch(DMLException e){
            Test.startTest();
            System.debug('The following exception has occurred: ' + e.getMessage());
            QueryUtilityClass.getMessageFromDMLException(e);
            Test.stopTest();
        }

        try {
            Account testAccount = TestObjectsFactory.getAccountRecord('Organization Account',true,'JO20220212');
            testAccount.NumberOfEmployees = 1234567891;
            insert testAccount;

        } catch(DMLException e){
            System.debug('The following exception has occurred: ' + e.getMessage());
            QueryUtilityClass.getMessageFromDMLException(e);
        }
    }
}