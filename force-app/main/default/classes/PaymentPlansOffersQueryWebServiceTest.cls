/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for PaymentPlansOffersQueryWebService
*/
@isTest
private class PaymentPlansOffersQueryWebServiceTest {

    /*
    * Scenario 1 : Fetch Unit Payment Plan and offer
    */
    static testmethod void testPaymentPlan() {

        Test.startTest();

        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
            insert projectRecord;
            BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
            insert buildingRecord;

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        unitRecord.EligibleforUnitFurnishing__c = true ;
        unitRecord.DigitalSales__c = true;
        unitRecord.BuildingSectionName__c = buildingRecord.Id;
        insert unitRecord;
        
        Unit_Add_On__c newAddon = new Unit_Add_On__c();
        newAddon.Name_of_Add_on__c = 'Basement Options';
        newAddon.SubName_of_AddOns__c = 'Option 1';
        newAddon.Unit__c = unitRecord.Id;
        newAddon.IsActive__c = True;
        insert newAddon;

        UnitDesign__c unitDesignRec = new UnitDesign__c();
        unitDesignRec.Unit__c = unitRecord.Id ;
        unitDesignRec.DesignType__c= 'Arabic' ;
        unitDesignRec.SellingPrice__c = 50000000 ;
        unitDesignRec.PremiumAmount__c  = 2000 ; 
        insert unitDesignRec ; 
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.DigitalSales__c = true;
        	insert paymentPlanRecord;
        	list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        	insert installmentLines;
        	paymentPlanRecord.IsActive__c =Constants.YES;
        	update paymentPlanRecord;
        	BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
            insert buldingPaymentMapping;    
           
            OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        	offerRecord.DigitalSales__c = true;
        	insert offerRecord;
        	OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        	insert offerLine;

        TestObjectsFactory.initializeRestContext(null, 'query/paymentplansoffers');
        PaymentPlansOffersQueryWebService.doPost(opp.Id, new List<Id>{unitRecord.Id},true);
        Test.stopTest();
    }

}