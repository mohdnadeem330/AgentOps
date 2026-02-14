@isTest(SeeAllData=false)
public class CreateAccountRelationshipWebServiceTest {
    @isTest static void setupMethod() {

        Account accountRecord1 = TestObjectsFactory.getOrganisationAccountRecord('CompanyName1', 'Ysjs657');
        insert accountRecord1;

        Account accountRecord2 = TestObjectsFactory.getOrganisationAccountRecord('CompanyName2', 'Ysjs765');
        insert accountRecord2;

        TestObjectsFactory.initializeRestContext(null, '/CreateActivity');
        createAccountRelationshipWebService.doPost(accountRecord1.Id, accountRecord2.Id, 'Spouse Of');
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        
        createAccountRelationshipWebService.doPost(accountRecord1.Id, accountRecord2.Id, 'Spouse');
        
        Test.stopTest();
    }
}