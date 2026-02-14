/**
* PaymentInstallmentsServiceTest
*
* Test class for PaymentInstallmentsService
*/
@isTest
private class PaymentInstallmentsServiceTest {
    //Create setup data
    @testSetup static void setupData() {
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
    }
    //test the Installment lines
    @isTest static void PaymentPlanTest() {
        Unit__c unitrecord =[select id from unit__c limit 1];
        
        
        BookingMemo__c  memo= new BookingMemo__c ();
        insert memo;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.BookingMemo__c=memo.Id;
        paymentPlanRecord.Unit__c=unitrecord.Id;
        insert paymentPlanRecord;
        List<InstallmentLineChanges__c> installmentLineChangesList = new list<InstallmentLineChanges__c>();
        installmentLineChangesList.add(new InstallmentLineChanges__c(InstallmentNumber__c=1,
                                                                    ProposedInstallmentPercentage__c=100,
                                                                    ProposedInstallmentDate__c=System.Today(),
                                                                    Description__c='test',
                                                                    BookingMemo__c=memo.Id,
                                                                    Unit__c=unitrecord.id,
                                                                    PaymentPlan__c = paymentPlanRecord.id));
        PaymentInstallmentsService.insertPaymentInstallments(installmentLineChangesList);
        
        List<PaymentInstallments__c> installmentRecords = [select id from PaymentInstallments__c];
        System.assertEquals(installmentRecords.isEmpty(),false);
    }
}