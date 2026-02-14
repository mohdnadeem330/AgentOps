@isTest
public class BatchToUpdateAgencyStatusTest {
    @isTest
    public static void BatchToUpdateAgencyStatusExecute() {
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency','Test1234567');
        acc.CurrentAgencyStatus__c = 'Newly Registered';
        acc.DateOfRegistration__c = Date.valueOf('2022-01-01');
        acc.LastSalesOrderClosureDate__c = Date.valueOf('2022-12-12');
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        insert acc;
        
        Test.startTest();
        BatchToUpdateAgencyStatus batch = new BatchToUpdateAgencyStatus();
        database.executeBatch(batch);
        Test.stopTest();
    }
}