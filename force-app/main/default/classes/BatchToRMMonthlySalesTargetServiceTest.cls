@isTest
public class BatchToRMMonthlySalesTargetServiceTest {

    @isTest
    public static void testInventoryMonthlySalesTarget() {
        getData('Inventory');
        Test.startTest();
        try {
            database.executeBatch(new BatchToRMMonthlySalesTargetService());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            //for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Monthly Sales Target Service Batch')]) {
            //    System.abortJob(ct.Id);
            //}
            System.schedule('Test Monthly Sales Target Service Batch', '0 0 24 * * ?', new BatchToRMMonthlySalesTargetService());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    public static void getData(String inventoryLaunch) {
        Account acc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today()+100;
       
        insert unit;

        BuildingSection__c buildingRecord = new BuildingSection__c();
        buildingRecord.Id = unit.BuildingSectionName__c;
        buildingRecord.CompletionCertificateDate__c = null;
        update buildingRecord;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.SalesManager__c = UserInfo.getUserId();
        salesOrder.BrokerManager__c = UserInfo.getUserId();
        salesOrder.InventoryLaunch__c = inventoryLaunch;
        salesOrder.BookingDate__c = date.today().addDays(-3);
        salesOrder.SalesApprovedDate__c = date.today().addDays(-3);
        salesOrder.NetAmount__c = 50000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        Unit__c allunit = [Select Id,OffPlanProperty__c, CompletionDate__c From Unit__c where Id=:unit.Id ];
        System.debug('Unit::'+ [Select Id,OffPlanProperty__c, CompletionDate__c From Unit__c where Id=:unit.Id ]);
        Opportunity reSalesopp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        reSalesopp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Resale').getRecordTypeId();
        reSalesopp.EnquiryCategory__c = 'Aldar Employees';
        reSalesopp.EnquiryTrigger__c = 'Aldar Hospitality';
        reSalesopp.Unit__c = unit.id;
        reSalesopp.TransferredDate__c= system.Today();
        reSalesopp.OwnerId = UserInfo.getUserId();
        reSalesopp.Amount = 10000000;
        reSalesopp.Transferred__c = true;
        insert reSalesopp;
        
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', allunit.Id, '800-Aldar');
        resaleCase.OwnerId = ResaleService.ResaleRRQueue.Id;
        
        insert resaleCase;
        
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        MonthlySalesTarget__c monthlySalesTarget = TestObjectsFactory.getMonthlySalesTargetRecord(usr.Id, 'ReSales');
        insert monthlySalesTarget;
        MonthlySalesTarget__c monthlySalesTarget2 = TestObjectsFactory.getMonthlySalesTargetRecord(usr.Id, 'ReSales');
        monthlySalesTarget2.AchievedAmount__c = 50000;
        insert monthlySalesTarget2;
    }
}