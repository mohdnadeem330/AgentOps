@isTest(SeeAllData=false)
public class BookingMemoServiceTest {
    @isTest static void setupMethod() {

        Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
        insert orgAccount;

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAccount.Id);
        insert opportunityRecord;
        
        BookingMemo__c bookingRecord  = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.Id);
        insert bookingRecord;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        //project.ProjectBudget__c = projectBudget.Id;
        insert project;
        
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(project.id);
        insert buildingRecord;
        
        OffersPromotions__c getOfferPromotion = TestObjectsFactory.getOfferPromotion(buildingRecord.Id, project.Id);
        getOfferPromotion.BookingMemo__c = bookingRecord.Id;
        insert getOfferPromotion;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.BookingMemo__c = bookingRecord.Id;
        insert paymentPlanRecord;

        Test.startTest();

        String result = BookingMemoService.createBookingMemo(opportunityRecord.Id, 'Header', 'Subject', 'New Payment Plan', 'Special Mote');
        BookingMemoService.lastCreatedIdBookingMemo();
        
        BookingMemoService.getMemoDetails(new set<Id>{bookingRecord.Id});
        
        BookingMemoService.getMyOfferDetails(new set<Id>{bookingRecord.Id});
        
        BookingMemoService.getMyPaymentDetails(new set<Id>{bookingRecord.Id});

        Test.stopTest();

    }
}