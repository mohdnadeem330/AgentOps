/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for CommissionService
*/
@isTest
private class BuildingSectionMappingServiceTest {
    
    /*
    * Scenario 1 : Create Payment Plan for Memo Installment Lines and associate with building
    */
    private static testMethod void createBuildingSectionMapping() {
        Test.startTest();
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opportunityRecord;

        Unit__c unitRec = TestObjectsFactory.unitDataSetup('1234');
        insert unitRec ;

        PaymentPlan__c paymentPlan = TestObjectsFactory.getPaymentPlan();
        List<PaymentInstallments__c> paymentInstallmentList = TestObjectsFactory.getPaymentInstallments(paymentPlan.Id,5);

        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.Id);
        insert bookingMemo ;

        MemoLines__c memoLine = TestObjectsFactory.getMemoLineRecord(bookingMemo.Id, unitRec.Id);
        insert memoLine ;

        List<InstallmentLineChanges__c> installmentChangeList = new List<InstallmentLineChanges__c>();

        InstallmentLineChanges__c installmentChange = new InstallmentLineChanges__c();
        installmentChange.PaymentPlan__c = paymentPlan.Id ;
        installmentChange.BookingMemo__c = bookingMemo.Id ;
        installmentChange.InstallmentNumber__c = paymentInstallmentList[0].InstallmentNumber__c ;
        installmentChange.InstallmentPercentage__c = paymentInstallmentList[0].InstallmentPercentage__c ;
        installmentChange.ProposedInstallmentPercentage__c = 20 ;
        installmentChange.InstallmentDate__c = paymentInstallmentList[0].InstallmentDate__c ;
        installmentChange.ProposedInstallmentDate__c = paymentInstallmentList[0].InstallmentDate__c ;
        insert installmentChange ;

        installmentChangeList.add(installmentChange);

        PaymentPlan__c memoPaymentPlan = paymentPlan.clone(false, false, false, false);
        memoPaymentPlan.BookingMemo__c = bookingMemo.Id ;
        memoPaymentPlan.Unit__c = unitRec.Id;
        insert memoPaymentPlan;

        BuildingSectionMappingService.insertBuildingSectionMapping(installmentChangeList);
        Test.stopTest();
    }
}