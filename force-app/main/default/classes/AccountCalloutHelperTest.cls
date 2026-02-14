@isTest
public class AccountCalloutHelperTest {

    @testSetup
    static void setupTestData() {
        // Create test Account data
        Account acc1 = new Account(
            Name = 'Test Vendor',
            RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID,
            ERPID__c = '',
            UAEVATRegisterNumber__c = '123456789',
            CurrencyIsoCode = 'AED',
            DateOfRegistration__c = Date.today(),
            RegistrationNumber__c = '987654321',
            BillingCountry = 'United Arab Emirates',
            BillingStreet = '123 Test St',
            BillingCity = 'Abu Dhabi',
            BillingState = 'Abu Dhabi',
            // BillingCountryCode = 'UAE',
            
            BillingPostalCode = '00000',
            Email__c = 'test@test.com',
            Website = 'www.test.com',
            AMLFlag__c = true,
            RegistrationExpiryDate__c = Date.today().addYears(1),
            PreviousAgencyStatus__c = 'Active',
            CurrentAgencyStatus__c = 'Verified',
            // AgencyRegion__c = 'Domestic',
            IsBrokerChange__c = true,
            IsAgentChange__c = false,
            OtherERPID__c = '{"oracleSupplierId":"123","oracleSiteId":"456"}'
        );
        insert acc1;

        Contact con1 = new Contact(
            AccountId = acc1.Id,
            FirstName = 'John',
            LastName = 'Doe',
            MobilePhone = '555-5555',
            Email = 'johndoe@test.com',
            BrokerType__c = 'Agency Admin'
        );
        insert con1;

        // Create another Account with different data
        Account acc2 = new Account(
            Name = 'Another Vendor',
            RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID,
            ERPID__c = 'ERP123',
            UAEVATRegisterNumber__c = '987654321',
            //CurrencyIsoCode = 'USD',
            DateOfRegistration__c = Date.today().addDays(-30),
            RegistrationNumber__c = '123123123',
            //BillingCountry = 'United States',
            //BillingStreet = '456 Test Ave',
            //BillingCity = 'Another City',
            //BillingState = 'Another State',
            //BillingCountryCode = 'US',
           // BillingPostalCode = '11111',
            Email__c = 'another@test.com',
            Website = 'www.another.com',
            AMLFlag__c = false,
            RegistrationExpiryDate__c = Date.today().addYears(2),
            PreviousAgencyStatus__c = '',
            CurrentAgencyStatus__c = '',
            // AgencyRegion__c = 'International',
            IsBrokerChange__c = false,
            IsAgentChange__c = true
        );
        insert acc2;

        Contact con2 = new Contact(
            AccountId = acc2.Id,
            FirstName = 'Jane',
            LastName = 'Doe',
            MobilePhone = '666-6666',
            Email = 'janedoe@test.com',
            BrokerType__c = 'Agent'
        );
        insert con2;
    }

    @isTest
    static void testPrepareDataForCallout() {
        // Test case to validate that data is prepared correctly for the callout
        
        // Fetch test Account records
        List<Account> accList = [SELECT Id,ProposedBankDetailStatus__c FROM Account LIMIT 2];
        accList[0].ProposedBankDetailStatus__c = 'Approved';
        update accList;
        Test.startTest();

        // Call the method
        // AccountCalloutHelper.PrepareDataForCallout(new List<Id>{ accList[0].Id, accList[1].Id });

        Test.stopTest();

        // Assertions can be added to validate any post-conditions, 
        // such as ensuring that a callout was invoked (mock CalloutToMuleSoft) 
        // and certain flags or variables were set correctly.
    }

    @isTest
    static void testPrepareDataForCallout_EmptyList() {
        // Test case to ensure no errors occur when an empty list is passed

        Test.startTest();

        // Call the method with an empty list
        AccountCalloutHelper.PrepareDataForCallout(new List<Id>());

        Test.stopTest();

        // Assertions to ensure no unexpected behavior occurred.
    }

    // @isTest
    // static void testPrepareDataForCallout_WithMock() {
    //     // Mock callout response using HttpCalloutMock (if necessary)
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

    //     // Fetch test Account records
    //     List<Account> accList = [SELECT Id FROM Account LIMIT 2];

    //     Test.startTest();

    //     // Call the method with test data
    //     AccountCalloutHelper.PrepareDataForCallout(new List<Id>{ accList[0].Id, accList[1].Id });

    //     Test.stopTest();

    //     // Assert that the mock callout was invoked with the correct parameters
    //     // (You may need to add appropriate assert statements for your specific case)
    // }
}