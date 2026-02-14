@isTest(SeeAllData=false)
public class ValidateAccountOpportunityWebServiceTest {
    @isTest static void setupMethod() {

        Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
        insert orgAccount;

        Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
        newAccount.MobileCountryCode__pc = '971';
        newAccount.ResidentStatus__pc = 'Non-Resident';
        insert newAccount ; 
        
        Contact contactRecord = TestObjectsFactory.contactDataSetup(orgAccount.id);
        contactRecord.PrimaryContact__c = true;
        update contactRecord;

        TestObjectsFactory.initializeRestContext(null, '/validate/accountopportunity');
        
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');

        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();                
        ValidateAccountOpportunityWebService.doPost(orgAccount.Id);
        ValidateAccountOpportunityWebService.doPost(newAccount.Id);
        Test.stopTest();

    }
}