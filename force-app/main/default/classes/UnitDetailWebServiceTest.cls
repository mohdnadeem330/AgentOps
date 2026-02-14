@isTest
public class UnitDetailWebServiceTest {
    
    @isTest
    static void testcase1(){
            
        Test.startTest();
        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        unitRecord.DigitalSales__c = true;
        insert unitRecord;
        
            UnitDesign__c ud = new UnitDesign__c(DesignType__c=UnitDesign__c.DesignType__c.getDescribe().getPicklistValues()[0].getValue(),
                                                GFAArea__c=1,
                                                PremiumAmount__c=1,
                                                SaleableArea__c=1,
                                                SellingPrice__c=1,
                                                TerraceArea__c=1,
                                                Unit__c=unitRecord.id,
                                                WebFloorPlan__c='https://test.com');
            
            insert ud;
            
            ud.WebFloorPlan__c='https://test2.com';
            update ud;
        
        Unit_Add_On__c newAddon = new Unit_Add_On__c();
        newAddon.Name_of_Add_on__c = 'Basement Options';
        newAddon.SubName_of_AddOns__c = 'Option 1';
        newAddon.Unit__c = unitRecord.Id;
        newAddon.IsActive__c = True;
        insert newAddon;

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.DigitalSales__c = true;
        insert paymentPlanRecord;

        List<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;

        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,unitRecord.BuildingSectionName__c);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(unitRecord.BuildingSectionName__c,unitRecord.Project__c);
        offerRecord.DigitalSales__c = true;
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
        
		TestObjectsFactory.initializeRestContext(null, '/query/unitdetail');
        RestContextHandler handler = new RestContextHandler(false);
        UnitDetailWebService.doPost(unitRecord.Id,true);
        Test.stopTest();
    }

    @isTest
    static void testException(){
            
        Test.startTest();
		TestObjectsFactory.initializeRestContext(null, '/query/unitdetail');
        RestContextHandler handler = new RestContextHandler(false);
        UnitDetailWebService.doPost(null,false);
        new UnitDetailWebService.DesignType('test',null);
        Test.stopTest();
    }
}