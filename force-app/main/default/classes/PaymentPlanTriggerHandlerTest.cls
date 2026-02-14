/**
* PaymentPlanTriggerHandlerTest
*
* Test class for PaymentPlanTriggerHandler
*/
@isTest
private class PaymentPlanTriggerHandlerTest {
    
    @testSetup static void setupData() {
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.IBANNoCorporate__c = '1234567890';
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
    }
    //Test document placeholder creation
    @isTest static void PaymentPlanTest() {
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        List<Document__c> docRecords = [select id from Document__c where PaymentPlan__c=:paymentPlanRecord.Id];
        System.assertEquals(docRecords.isEmpty(),false);
        
        PaymentPlan__c pp = [SELECT Id, OnlineFlag__c FROM PaymentPlan__c LIMIT 1];
        pp.OnlineFlag__c = true;
        update pp;
    }
}