/*
* Class Name : DLPZoneControllerTest
* Created By : R3-DLP implementation-Smaartt
* Description: Test class for DLPZoneController unit search under Account
*/
@isTest
private class DLPZoneControllerTest {

    @isTest
    static void testDlpZoneRetrieve() {       
        Account testAccount = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        testAccount.MobileNumber__c = '123456789';
        insert testAccount;        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(testAccount.Id);
        insert opp;
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        insert p;
        Unit__c testUnit = TestObjectsFactory.unitDataSetup(p.Id);        
        insert testUnit;
        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,testAccount.Id);
        sa.Unit__c = testUnit.Id;
        insert sa;         
        SalesOrder__c testSalesOrder = new SalesOrder__c(
            Account__c = testAccount.Id,
            Unit__c = testUnit.Id,
            CustomerDLPStartDate__c = system.today(),
            DLPDate__c = system.today() + 30
        );    
        //insert testSalesOrder;
        Case testCase1 = new Case(
            Subject = 'Case 1',
            AccountId = testAccount.Id,
            Status = 'Open',
            RecordTypeId = Schema.SObjectType.Case.RecordTypeInfosByName.get('DLP').RecordTypeId
        );
        Case testCase2 = new Case(
            Subject = 'Case 2',
            AccountId = testAccount.Id,
            Status = 'Closed',
            DLP_Closure_Reason__c='Attended',
            RecordTypeId = Schema.SObjectType.Case.RecordTypeInfosByName.get('DLP').RecordTypeId
        );
        insert new List<Case>{testCase1, testCase2};
        Test.startTest();
        List<DLPZoneController.DLPWrapper> result = DLPZoneController.dlpZoneRetrieve(testAccount.Id);
        DLPZoneController.CheckJointRelationAccount(testAccount.Id);
        DLPZoneController.getCasesForAccount(testAccount.id);
        Test.stopTest();       
    }
}