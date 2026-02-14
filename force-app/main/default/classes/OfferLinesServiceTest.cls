/*
*Created By     : Pavithra Gajendra
*Created Date   : 29/07/2022
*Description    : Test class for OfferLinesService
*/
@isTest
private class OfferLinesServiceTest {
    
    private static testMethod void testAllMethods() {
        OfferLinesService.getOfferLinesQuery('Select Id FROM OfferLines__c');
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opportunityRecord;

        Unit__c unitRec = TestObjectsFactory.unitDataSetup('1234');
        insert unitRec ;

        OffersPromotions__c offerRecord = TestObjectsFactory.getOfferPromotion(unitRec.BuildingSectionName__c,unitRec.Project__c);
        insert offerRecord ;

        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.Id);
        insert bookingMemo ;

        MemoLines__c memoLine = TestObjectsFactory.getMemoLineRecord(bookingMemo.Id, unitRec.Id);
        insert memoLine ;
        
        OffersPromotions__c promotion = offerRecord.clone(false, false, false, false);
        promotion.BookingMemo__c = bookingMemo.Id ;
        promotion.Unit__c = unitRec.Id;
        insert promotion;

        OfferLinesService.insertOfferLines(new List<MemoLines__c>{memoLine},promotion.Id);

    }
    
}