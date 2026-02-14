@isTest
private class DLPMilestoneTimeCalculatorTest {
  
    @isTest
    public static void callMethod (){
        Test.startTest();

        Account account = TestObjectsFactory.getPersonAccountRecord();
        insert account;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Project__c pr = new Project__c(Id=unit.Project__c);
        pr.AsiteProjectName__c = 'Test';
        update pr;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 100000;
        insert salesOrder;
        
        Case cs = TestObjectsFactory.getStandardCase(account.Id, null, 'Compliance');
        cs.Category__c = '';
        cs.SubVertical__c = 'DLP';
        cs.CaseCategory__c = 'Civil';
        cs.SubCategory__c = 'Walls/Ceiling';
        cs.Unit__c = unit.Id;
        cs.Priority = 'Emergency';
        cs.ResolutionType__c = 'Repair';
        insert cs;
        
        TriggerHandler.processedIds = new Set<Id>();

        Case cs1 = TestObjectsFactory.getStandardCase(account.Id, null, 'Compliance');
        cs1.Category__c = '';
        cs1.SubVertical__c = 'DLP';
        cs1.Appointment_Date__c =  DateTime.now();
        cs1.Appointment_Booking_Date__c =  DateTime.now();
        cs1.CaseCategory__c = 'Civil';
        cs1.SubCategory__c = 'Walls/Ceiling';
        cs1.Unit__c = unit.Id;
        cs1.Priority = 'P1';
        cs1.ResolutionType__c = 'Replace';
        insert cs1;
        
        TriggerHandler.processedIds = new Set<Id>();

        Case cs2 = TestObjectsFactory.getStandardCase(account.Id, null, 'Compliance');
        cs2.Category__c = '';
        cs2.SubVertical__c = 'DLP';
        cs2.Appointment_Date__c =  DateTime.now();
        cs2.Appointment_Booking_Date__c =  DateTime.now();
        cs2.CaseCategory__c = 'Civil';
        cs2.SubCategory__c = 'Walls/Ceiling';
        cs2.Unit__c = unit.Id;
        insert cs2;
        DLPMilestoneTimeCalculator obj = new DLPMilestoneTimeCalculator();
        obj.calculateMilestoneTriggerTime(cs2.Id,'');
        
        Test.stopTest();
    }
}