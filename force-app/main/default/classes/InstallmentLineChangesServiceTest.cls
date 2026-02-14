/**
* EventTriggerHandlerTest
*
* Test class for EventTriggerHandler
*/
@isTest
private class InstallmentLineChangesServiceTest {
    //Create Test Data
    @testSetup static void setupData() {
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
    }

    //test Installment Line Changes Service
    @isTest static void InstallmentLineChangesTest() {
        List<InstallmentLineChanges__c> lineList = InstallmentLineChangesService.getInstallmentLineChangesQuery('select id from InstallmentLineChanges__c');
        System.assertEquals(lineList.isEmpty(),true);
        
        Unit__c unitrecord =[select id from unit__c limit 1];
        BookingMemo__c  memo= new BookingMemo__c ();
        insert memo;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.BookingMemo__c=memo.Id;
        paymentPlanRecord.Unit__c=unitrecord.Id;
        insert paymentPlanRecord;
        InstallmentLineChangesService.createInstallmentLineChanges(new list<String>{'1000'},new list<String>{'1000'}, new list<String>{''},new list<String>{'1000'},paymentPlanRecord.Id,memo.id,unitrecord.id);
        
        
        lineList = InstallmentLineChangesService.getInstallmentLineChangesByBookinMemoId(memo.id);
        System.assertEquals(lineList.isEmpty(),false);
    }
}