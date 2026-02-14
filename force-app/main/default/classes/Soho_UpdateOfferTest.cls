@IsTest
public class Soho_UpdateOfferTest {
    @TestSetup
    static void makeData(){
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.ResaleListed__c = true;
        unitRecord.Listing_Price__c = 10000000;
        unitRecord.ResaleStatus__c = '';
        insert unitrecord;

        List<Account> accList = new List<Account>();
        Account seller = TestObjectsFactory.getPersonAccountRecord();
            accList.add(seller);
        Account buyer = TestObjectsFactory.getPersonAccountRecord();
            accList.add(buyer);
        insert accList;

        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity sellerOpp = TestObjectsFactory.getOpportunityRecord(buyer.Id);
            sellerOpp.EnquiryTrigger__c=null;
            oppList.add(sellerOpp);
        Opportunity buyerOpp = TestObjectsFactory.getOpportunityRecord(buyer.Id);
            buyerOpp.EnquiryTrigger__c=null;
            oppList.add(buyerOpp);
        insert oppList;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(sellerOpp.Id, seller.Id);
            salesOrder.Unit__c = unitrecord.Id;
            salesOrder.IsBookingCompleted__c = true;
            salesOrder.NetAmount__c = 10000000;
            salesOrder.Account__c = seller.Id;
            salesOrder.Status__c = 'Sold';
        insert salesOrder;

        Resale_Offers__c ro = new Resale_Offers__c(
            Unit__c = unitrecord.Id,
            Comments__c = 'Please Accept', 
            Opportunity__c = buyerOpp.Id, 
            Sales_Order__c = salesOrder.Id, 
            Status__c = 'Accepted', 
            Offer_Price__c = 10000000, 
            Buyer_Account__c = buyer.Id, 
            Seller_Account__c = seller.Id
        );
        insert ro;
    }

    @isTest
    public static void testUpdateOfferMethod(){
        Resale_Offers__c resaleOffer = [SELECT Id,Unit__c,Comments__c,Opportunity__c,Sales_Order__c,Status__c,Offer_Price__c,Buyer_Account__c,Seller_Account__c FROM Resale_Offers__c LIMIT 1];

        String reqBody = JSON.serialize(resaleOffer);
        TestObjectsFactory.initializeRestContext(reqBody, '/updateResaleOffer');       
        Test.startTest();
            Soho_updateOffer.updateOffer();
        Test.stopTest();
    }
    @isTest
    public static void testUpdateOfferMethodDMLException(){
        String reqBody = '{ "Status__c":"Test Subject"}';
        TestObjectsFactory.initializeRestContext(reqBody, '/updateResaleOffer');       
        Test.startTest();
            Soho_updateOffer.updateOffer();
        Test.stopTest();
    }
    @isTest
    public static void testUpdateOfferMethodException(){
        TestObjectsFactory.initializeRestContext(null, '/updateResaleOffer');       
        Test.startTest();
            Soho_updateOffer.updateOffer();
        Test.stopTest();
    }
    @isTest
    public static void testUpdateOfferMethodElse(){
        TestObjectsFactory.initializeRestContext('', '/updateResaleOffer');       
        Test.startTest();
            Soho_updateOffer.updateOffer();
        Test.stopTest();
    }
}