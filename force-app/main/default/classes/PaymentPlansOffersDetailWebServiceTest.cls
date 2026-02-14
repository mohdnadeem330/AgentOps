/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for PaymentPlansOffersDetailWebService
*/
@isTest
private class PaymentPlansOffersDetailWebServiceTest {

    /*
    * Scenario 1 : Fetch Unit Payment Plan and offer
    */
    static testmethod void testPaymentPlanDetail() {

        Test.startTest();

        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        unitRecord.MultiPurposeAmount__c = 12345;
        unitRecord.Swimming_Pool_Price__c = 12345;
        insert unitRecord;

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        List<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;

        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,unitRecord.BuildingSectionName__c);
        insert buldingPaymentMapping;  

        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(unitRecord.BuildingSectionName__c,unitRecord.Project__c);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;

        String PODselection = 'None';
		String SwimmingPoolSelection = 'Yes';
        TestObjectsFactory.initializeRestContext(null, 'query/paymentplansoffers');
        PaymentPlansOffersDetailWebService.doPost(opp.Id, unitRecord.Id,paymentPlanRecord.Id,offerRecord.Id,PODselection,SwimmingPoolSelection,true,new List<Id>{unitRecord.Id},null,null,false);
        Test.stopTest();
    }

    /*
    * Scenario 2 : Fetch Unit Payment Plan and offer
    */
    static testmethod void testMultiplePaymentPlanDetail() {

        Test.startTest();

        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount ; 

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert opp;

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        unitRecord.MultiPurposeAmount__c = 12345;
        unitRecord.Swimming_Pool_Price__c = 12345;
        insert unitRecord;

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        List<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;

        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,unitRecord.BuildingSectionName__c);
        insert buldingPaymentMapping;  

        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(unitRecord.BuildingSectionName__c,unitRecord.Project__c);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;

        String PODselection = 'None';
		String SwimmingPoolSelection = 'Yes';
        TestObjectsFactory.initializeRestContext(null, 'query/paymentplansoffers');
        PaymentPlansOffersDetailWebService.doPost(opp.Id, unitRecord.Id,null,offerRecord.Id,PODselection,SwimmingPoolSelection,true,new List<Id>{unitRecord.Id},new List<Id>{paymentPlanRecord.Id},null,false);
        
        Test.stopTest();
    }

}