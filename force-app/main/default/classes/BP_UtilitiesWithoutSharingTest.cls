@isTest
public class BP_UtilitiesWithoutSharingTest {

    @testSetup
    static void setupTestData() {
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        insert accountRecord;

        Contact con = new Contact();
        con.LastName = 'Alice';
        con.AccountId = accountRecord.Id;
        con.Email = 'test13@aldar.com';
        con.Phone = '527583669';
        con.OwnerId = UserInfo.getUserId();
        con.MobilePhone = '527583669';
        con.NationalIdNumber__c = '784123456789012';
        insert con;
    }

    @isTest
    static void testBrokerLeadValidation() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Alice' LIMIT 1];

        Lead newLead = new Lead();
        newLead.BrokerAgent__c = con.Id;
        newLead.FirstName = 'Henry';
        newLead.LastName = 'Wong';
        newLead.MobileCountryCode__c = '971';
        newLead.MobileNumber1__c = '52887687';
        newLead.SalesOrigin__c = 'Domestic';
        newLead.LeadOrigin__c = 'United Arab Emirates';
        newLead.LeadSource = 'Online';
        newLead.EnquiryCategory__c = 'Aldar Websites';
        newLead.EnquiryTrigger__c = 'Aldar SMS Campaign';
        newLead.BuyRent__c = 'Buy';
        newLead.SalesType__c = 'Residential Sale';
        newLead.PropertyReadiness__c = '0-3 months';
        newLead.ResidentStatus__c = 'Resident';
        newLead.Project__c = 'Mamsha Al Saadiyat';
        newLead.PropertyUsage__c = 'Residential Sale';
        newLead.CustomerLocation__c = 'Abu Dhabi';
        newLead.LanguagePreference__c = 'English';
        newLead.Email = 'aupendra14@gmail.com';
        newLead.Date_of_Birth__c  = System.today().addMonths(-1234);
        Test.startTest();
        insert newLead;

        String validationResult = BP_UtilitiesWithoutSharing.brokerLeadValidation(newLead);
        BP_UtilitiesWithoutSharing.sendOTP(con.Id, 'EMAIL', 'test13434@aldar.com');
        BP_UtilitiesWithoutSharing.sendOTP(con.Id, 'SMS', '971527583669');
        BP_UtilitiesWithoutSharing.getUser(UserInfo.getUserId());

        System.assertEquals('Duplicate', validationResult);

        Lead insertedLead = [SELECT Id, Status, SalesType__c, Project__c, SalesOrigin__c, LeadSource, Email FROM Lead WHERE Id = :newLead.Id LIMIT 1];

        System.assertNotEquals(null, insertedLead);
        System.assertEquals('New Lead', insertedLead.Status);
        System.assertEquals('Residential Sale', insertedLead.SalesType__c);
        System.assertEquals('Mamsha Al Saadiyat', insertedLead.Project__c);
        System.assertEquals('Domestic', insertedLead.SalesOrigin__c);
        System.assertEquals('Online', insertedLead.LeadSource);
        System.assertEquals('aupendra14@gmail.com', insertedLead.Email);

        Test.stopTest();
    }
}