@isTest
public class QuarterlyInvoicePDFControllerTest {
    //Setup test Data
    @testSetup static void setupData() {
        //offer
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        insert orgAcc;
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);	
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
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
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
    }
    
    @isTest static void commissionRecords() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
        QuarterlyBonusCommission__c bonus = new QuarterlyBonusCommission__c();
        bonus.BrokerAgency__c = accRecord.Id;
        bonus.Status__c = 'Not Ready';
        bonus.Year__c = '2022';
        bonus.Quarter__c = 'Q4';
        insert bonus;
        
        CommissionLineItem__c cli = new CommissionLineItem__c();
        cli.BrokerAgent__c = conRecord.id;
        cli.BrokerAgency__c = accRecord.Id;
        cli.CommissionAmount__c = 500;
        cli.CommissionPercentage__c = 0.75;
        cli.CommissionType__c = Constants.COMMISSION_LINE_BONUS_COMMISSION;
        cli.SalesManager__c = UserInfo.getUserId();
        cli.SalesOrder__c = salesOrderRecord.Id;
        cli.QuarterlyBonusCommission__c = bonus.Id;
        insert cli;
        
        PageReference testPage = Page.QuarterlyInvoicePDF; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('invoiceId', String.valueOf(bonus.Id));
        
        QuarterlyInvoicePDFController ext = new QuarterlyInvoicePDFController();
        
        QuarterlyBrokerCommissionController.getAllComissions();
        QuarterlyBrokerCommissionController.getCommissionTrail(bonus.Id);
        QuarterlyBrokerCommissionController.updateStatus(bonus.Id,Constants.COMMISSION_LINE_STATUS_ACCEPTED,'test');
    }
}