/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for OffersPromotionsService & OffersPromotionsTriggerHandler
*/
@isTest
private class OffersPromotionsServiceTest {

    static Project__c projectRec ;
    static OffersPromotions__c offerRec ;
    static List<Unit__c> unitRecords ;
    
    static void init(){

        projectRec = TestObjectsFactory.getProjectRecord('12345');
        insert projectRec ;

        AllocationGroup__c allocationGroup = TestObjectsFactory.getAllocationGroup('AUH Team','AUH');
        insert allocationGroup ;

        offerRec = TestObjectsFactory.getOfferPromotion(null,projectRec.Id);
        offerRec.AllocationGroup__c = 'AUH' ;
        insert offerRec ;

        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRec.Id);
        insert offerLine ;

        Unit__c unitRec = TestObjectsFactory.unitDataSetup('1234');
        unitRec.Project__c = projectRec.Id ;
        insert unitRec ;

        BuildingSection__c building = new BuildingSection__c();
        building.Id = unitRec.BuildingSectionName__c ;
        building.Project__c = projectRec.Id ;
        update building ;


        unitRecords = UnitService.getAllUnitsById(new Set<Id>{unitRec.Id});
    }

    /*
    * Scenario 1 : Test All menthods in Offers & Promotions Service
    */
    private static testMethod void testOffers() {
        Test.startTest();
        init();
        OffersPromotionsService.getSelectedOffersAndPromotions(offerRec.Id);
        OffersPromotions__c offerPromo = TestObjectsFactory.getOfferPromotion(null,projectRec.Id);
        OffersPromotionsService.insertOffersPromotions(new List<OffersPromotions__c>{offerPromo});
        OffersPromotionsService.getOffersPromotionsByName(new Set<String>{offerRec.Name});
        OffersPromotionsService.getActiveOffersPromotions(null,unitRecords,Utilities.getLoggedInUserDetail());
        OffersPromotionsService.getActiveOffersAndPromotions(null, new Set<Id>{projectRec.Id});
        Test.stopTest();
    }

    /*
    * Scenario 2 : Test Booking Memo Offer
    */
    private static testMethod void testMemoOffers() {
        Test.startTest();
        init();
        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(null);
        insert bookingMemo ; 
        OffersPromotionsService.getActiveOffersPromotions(null,unitRecords,Utilities.getLoggedInUserDetail());
        OffersPromotionsService.lastCreatedIdOffersPromotions(bookingMemo.Id,unitRecords[0].Id);
        Test.stopTest();
    }

    /*
    * Scenario 3 : Test Building Offer 
     */
    private static testMethod void testBuidlingOffers() {
        Test.startTest();
        init();
        offerRec.BuildingSectionName__c = unitRecords[0].BuildingSectionName__c ;
        update offerRec ; 
        OffersPromotionsService.getActiveOffersPromotions(null,unitRecords,Utilities.getLoggedInUserDetail());
        Test.stopTest();
    }
   


    

}