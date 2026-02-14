@isTest(SeeAllData=false)
public class BookingMemoTriggerHandlerTest {
    @isTest static void setupData() {

        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc;

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
        insert opportunityRecord;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.id);
        insert bookingMemo;

        BookingMemo__c bookingMemo1 = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.id);
        insert bookingMemo1;

        MemoLines__c memoLine = TestObjectsFactory.getMemoLineRecord(bookingMemo.Id,unit.id);
        memoLine.SubsidyPercentage__c = 0;
        insert memoLine;

        List<BookingMemo__c> updateList = new List<BookingMemo__c>();

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.BookingMemo__c=bookingMemo.Id;
        paymentPlanRecord.Unit__c=unit.Id;
        insert paymentPlanRecord;

        InstallmentLineChangesService.createInstallmentLineChanges(new list<String>{'100'},new list<String>{'100'}, new list<String>{''},new list<String>{'100'},paymentPlanRecord.Id,bookingMemo.id,unit.id);

        Test.startTest();

        TriggerHandler.processedIds = new Set<Id>();
        bookingMemo.MemoSubject__c = 'Memo Subject';
        bookingMemo.ApprovalStatus__c = Constants.STATUS_APPROVED;
        bookingMemo.ApprovalProgress__c = Constants.APPROVAL_PROGRESS_APPROVED;
        //update bookingMemo;
        updateList.add(bookingMemo);
        update updateList;

        bookingMemo1.MemoSubject__c = 'Memo Subject';
        bookingMemo1.ApprovalStatus__c = Constants.STATUS_REJECTED;

        updateList.add(bookingMemo1);

        TriggerHandler.processedIds = new Set<Id>();
        update updateList;

        Test.stopTest();

    }
}