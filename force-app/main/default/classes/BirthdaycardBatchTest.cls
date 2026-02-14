@isTest
public class BirthdaycardBatchTest {
	@isTest
    public static void test(){
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.PersonBirthdate = System.Today().addYears(-30);//Date.valueOf('2023-01-26');
        acc.FirstName ='';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        Test.startTest();
        BirthdaycardBatch bc = new BirthdaycardBatch();
        Database.executeBatch(bc,1);
        
        Test.stopTest();
        
    }
    @isTest
    public static void jointOwnerTest(){
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.PersonBirthdate = System.Today().addYears(-30);//Date.valueOf('2023-01-26');
        acc.FirstName ='';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        salesOrder1.Status__c = 'Cancelled';
        insert salesOrder1;
        
        JointOwner__c jo = TestObjectsFactory.getJointOwnerRecord(salesOrder1.Id, acc.Id, 'Spouse Of');
        insert jo;

        Test.startTest();
        BirthdaycardBatch bc = new BirthdaycardBatch();
        Database.executeBatch(bc,1);
                    
        Test.stopTest();
        
    }
}