@isTest
public class QuarterlyBonusControllerTest {

    @testSetup
    static void setupTestData() {
         Account testAccount = new Account(
            Name = 'PWC',
            BankCountry__c = 'Algeria', // Add custom fields
            BankName__c = 'Test Bank',
            BranchAddress__c = '1234 Main Street',
            BankAccountNumber__c = '1234567890',
            IBANNumber__c = 'US12345678901234567890',
            SwiftCode__c = 'TESTUS33',
            BeneficiaryName__c = 'John Doe',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Broker_Agency' LIMIT 1].Id
        );
        insert testAccount; 
        system.debug('result2'+ testAccount);
        List<Broker_Classification_Details__c> brokerDetails = new List<Broker_Classification_Details__c>();
        for (Integer i = 1; i <= 3; i++) {
            Broker_Classification_Details__c detail = new Broker_Classification_Details__c(
                AgencyName__c = testAccount.id,
                Month__c = 3, 
                Year__c = '2025'
               
            );
            brokerDetails.add(detail);
        }
        insert brokerDetails;
    }

    @isTest
    static void testRunQuarterlyBonus_ValidData() {
        
        String quarter = 'Q1';
        String year = String.valueOf(Date.today().year());

        Test.startTest();
        QuarterlyBonusController.runQuarterlyPayout('Quarterly Bonus', quarter, year);
        Test.stopTest();

       
    }

    @isTest
    static void testRunQuarterlyBonus_InvalidFutureQuarter() {
        String quarter = 'Q4';
        String year = String.valueOf(Date.today().year() + 1); // Future year

        Test.startTest();
        try {
            QuarterlyBonusController.runQuarterlyPayout('Quarterly Bonus', quarter, year);
           
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('You cannot run calculations for future quarters'));
        }
        Test.stopTest();
    }

    @isTest
    static void testRunQuarterlyBonus_NoDuplicateProcessing() {
 
        String quarter = 'Q1';
        String year = String.valueOf(Date.today().year());

        insert new QuarterlyBonusCommission__c(Quarter__c = quarter, Year__c = year);

        Test.startTest();
        try {
            QuarterlyBonusController.runQuarterlyPayout('Quarterly Bonus', quarter, year);
         
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Bonus calculation already performed'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testRunMarketinReimbusement_ValidData() {
        
        String quarter = 'Q1';
        String year = String.valueOf(Date.today().year());

        Test.startTest();
        QuarterlyBonusController.runQuarterlyPayout('Marketing Reimbursement', quarter, year);
        Test.stopTest();
    }
    
    @isTest
    static void testRunSubAccountManagerQB_ValidData() {
        
        String quarter = 'Q1';
        String year = String.valueOf(Date.today().year());

        Test.startTest();
        QuarterlyBonusController.runQuarterlyPayout('Sub Account Manager QB', quarter, year);
        Test.stopTest();
    }
}