/*
*Created By     : Hardik Vitthani
*Description    : Test class for BatchToProjectTargetService
*/
@isTest
public class BatchToProjectTargetServiceTest {
    @isTest
    public static void testProjectTargetService() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Project__c project = TestObjectsFactory.getProjectRecord('Test'); 
        insert project;

        BuildingSection__c building = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert building;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, building.Id);
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.BookingDate__c = date.today();
        insert salesOrder;

        ProjectTargets__c projectTarget = TestObjectsFactory.getProjectTargetRecord(project.Id);
        insert projectTarget;

        try {
            database.executeBatch(new BatchToProjectTargetService());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Project Target Service Batch')]) {
			    System.abortJob(ct.Id);
            }
            System.schedule('Test Project Target Service Batch', '0 0 23 * * ?', new BatchToProjectTargetService());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}