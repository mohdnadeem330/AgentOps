@isTest(SeeAllData=false)
public class UpsertAccountRelationshipWebServiceTest {
    @isTest static void setupMethod() {

        Account accountRecord1 = TestObjectsFactory.getOrganisationAccountRecord('CompanyName1', 'Ysjs657');
        insert accountRecord1;
                
        Account accountRecord2 = TestObjectsFactory.getOrganisationAccountRecord('CompanyName2', 'Ysjs765');
        insert accountRecord2;
        
        AccountRelationship__c accountRelationship = new AccountRelationship__c();
        accountRelationship.Account__c = accountRecord1.id;
        accountRelationship.RelatedAccount__c = accountRecord2.id ;
        accountRelationship.RelationshipType__c = 'Third Party';
        insert accountRelationship;

        TestObjectsFactory.initializeRestContext(null, '/CreateActivity');
        UpsertAccountRelationshipWebService.doPost(accountRecord1.Id, accountRecord2.Id, 'Third Party', '','Child','25.00');
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        
        UpsertAccountRelationshipWebService.doPost('','' , 'Third Party', accountRelationship.id,'Child','25.00');
        
         
        UpsertAccountRelationshipWebService.doPost(null, '', null, accountRelationship.id,'Child','25.00');
        
        TestObjectsFactory.initializeRestContext(null, '/CreateActivity');
        UpsertAccountRelationshipWebService.doPost('1233','3233' , 'Third Party', '','Child','25.00');
        
        Test.stopTest();
    }
}