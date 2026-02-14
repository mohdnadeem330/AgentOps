@isTest
public class Dm_PortalUserCreationTest {
  @isTest
    static void Dm_PortalUserCreation(){
        Test.startTest();
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id,
            Email = 'test@example.com',
            MobilePhone = '971554571398',
        recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('DM_Contact').getRecordTypeId());
        insert testContact;
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'DM Requestor Partner Login' LIMIT 1];
        Dm_PortalUserCreation.createPortalUser(testContact.id,false);
        Test.stopTest();
    }
}