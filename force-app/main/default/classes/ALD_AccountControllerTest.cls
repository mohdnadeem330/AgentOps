@isTest
public class ALD_AccountControllerTest {

    @isTest
    static void setupData() {
        Account account = TestObjectsFactory.getPersonAccountRecord(1111111, 'India','11111','P11111');
        account.CustomerType__c = 'VIP';
        account.Risk_Score__c = 3;
        insert account;
        Test.startTest();
        ALD_AccountController.accountKYCExpiryCheck(account.Id);
        Test.stopTest();
        
    }
}