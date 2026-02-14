/**
* ResaleOfferTriggerTest
*
* Test class for ResaleOfferTriggerHandler, ResaleOfferTriggerHelper
*/
@isTest
public class ResaleOfferTriggerTest {
    @TestSetup
    static void makeData(){
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
            unitrecord.ResaleListed__c = true;
            unitRecord.Listing_Price__c = 10000000;
            // unitRecord.Offer_Accepted__c = false;
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
            Status__c = 'Sent for Approval', 
            Offer_Price__c = 10000000, 
            Buyer_Account__c = buyer.Id, 
            Seller_Account__c = seller.Id,
            BuyerEmail__c = 'test@test.com',
            SellerEmail__c = 'test@test.com'
        );
        insert ro;
    }

    @IsTest
    static void acceptedResaleOfferTest(){
        Resale_Offers__c ro = [ SELECT Id, Status__c,
                                    Unit__c, Opportunity__c, Sales_Order__c, 
                                    Seller_Account__c, Buyer_Account__c 
                                FROM Resale_Offers__c LIMIT 1][0];
        ro.Status__c = 'Accepted';
        
        Test.startTest();
            update ro;
        Test.stopTest();
    }

    @IsTest
    static void acceptedResaleOfferTest_Fail(){
        Resale_Offers__c ro = [ SELECT Id, Status__c,
                                    Unit__c, Opportunity__c, Sales_Order__c, 
                                    Seller_Account__c, Buyer_Account__c 
                                FROM Resale_Offers__c LIMIT 1][0];
        ro.Status__c = 'Accepted';
        update ro;

        Resale_Offers__c newRO = new Resale_Offers__c(
            Unit__c = ro.Unit__c,
            Comments__c = 'Please Accept', 
            Opportunity__c = ro.Opportunity__c, 
            Sales_Order__c = ro.Sales_Order__c, 
            Status__c = 'Sent for Approval', 
            Offer_Price__c = 10000000, 
            Buyer_Account__c = ro.Buyer_Account__c, 
            Seller_Account__c = ro.Seller_Account__c,
            BuyerEmail__c = 'test@test.com',
            SellerEmail__c = 'test@test.com'
        );
        insert newRO;

        newRO.Status__c = 'Accepted';
        Test.startTest();
            try {
                update newRO;   
            } catch (Exception ex) {
                System.debug(ex.getMessage());
            }
        Test.stopTest();
    }

    @IsTest
    static void acceptedResaleOfferTest_Pass(){
        Resale_Offers__c ro = [ SELECT Id, Status__c,
                                    Unit__c, Opportunity__c, Sales_Order__c, 
                                    Seller_Account__c, Buyer_Account__c 
                                FROM Resale_Offers__c LIMIT 1][0];
        
        Resale_Offers__c newRO = new Resale_Offers__c(
            Unit__c = ro.Unit__c,
            Comments__c = 'Please Accept', 
            Opportunity__c = ro.Opportunity__c, 
            Sales_Order__c = ro.Sales_Order__c, 
            Status__c = 'Sent for Approval', 
            Offer_Price__c = 10000000, 
            Buyer_Account__c = ro.Buyer_Account__c, 
            Seller_Account__c = ro.Seller_Account__c,
            BuyerEmail__c = 'test@test.com',
            SellerEmail__c = 'test@test.com'
        );
        insert newRO;
        
        ro.Status__c = 'Accepted';
        update ro;

        List<Resale_Offers__c> roToUpdate = new List<Resale_Offers__c>();
        newRO.Status__c = 'Accepted';
        roToUpdate.add(newRO);
        ro.Status__c = 'Rejected';
        roToUpdate.add(ro);

        Test.startTest();
            try {
                update roToUpdate;
            } catch (Exception ex) {
                System.debug(ex.getMessage());
            }
        Test.stopTest();
    }
}