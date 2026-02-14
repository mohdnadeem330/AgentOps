@isTest(SeeAllData=false)
public class CreateUpdateJointOwnerWebServiceTest {
    @isTest static void setupMethod() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        //acc.ERPID__c = '12346';
        insert acc;

        Account relatedAccount = TestObjectsFactory.getPersonAccountRecord();
        //acc.ERPID__c = '12346';
        insert relatedAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        AccountRelationship__c accountRelationship = TestObjectsFactory.getAccountRelationship(acc.id, relatedAccount.Id, 'Joint Owner P-P');
        insert accountRelationship;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(relatedAccount.Id, 10,'Joint Owner P-P'); 
        jointOwner.SalesOrder__c = salesOrder.Id;
        insert jointOwner;

        //String sharePercentage = '40';

        TestObjectsFactory.initializeRestContext(null, '/upsert/jointonwer');
        createUpdateJointOwnerWebService.doPost(salesOrder.id, '' , acc.Id, '40',false,123);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        //insert leadTask;
        //insert opportunityTask;
        //update leadRecord;
        
        TestObjectsFactory.initializeRestContext(null, '/query/activity');
        createUpdateJointOwnerWebService.doPost(salesOrder.id, jointOwner.Id, relatedAccount.Id, 'abc',false,123);
        createUpdateJointOwnerWebService.doPost(salesOrder.id, jointOwner.Id, relatedAccount.Id, '200',false,123);
        
        Test.stopTest();
    }
}