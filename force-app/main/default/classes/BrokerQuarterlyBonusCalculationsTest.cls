/**********************************************************************************************************************
* Name               : BrokerQuarterlyBonusCalculationsTest                                                       
* Description        : Test class for Batch to create Quarterly Bonus Commission Records with Commission Line Items
* Usage              : Run for Last Quarter on Sales order by brokers                                               
* Created By         : Sanket Kumar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           sajkumar@aldar.com      10 April 2023   Initial Draft       
******************************************************************************************************************/
@isTest
public class BrokerQuarterlyBonusCalculationsTest {
    //Setup test Data
    @testSetup static void setupData() {

        BrokerClassification__c standardClassification = TestObjectsFactory.getBrokerClassificationRecord();
        standardClassification.Name = 'Standard';
        standardClassification.Quarter1MarketingBudget__c = 0;
        standardClassification.Quarter2MarketingBudget__c = 0;
        standardClassification.Quarter3MarketingBudget__c = 0;
        standardClassification.Quarter4MarketingBudget__c = 0;
        standardClassification.Year__c = String.valueOf(System.Today().year());
        insert standardClassification;
        
        BrokerClassification__c envoyClassification = TestObjectsFactory.getBrokerClassificationRecord();
        envoyClassification.Name = 'Envoy';
        envoyClassification.Quarter1MarketingBudget__c = 20000;
        envoyClassification.Quarter2MarketingBudget__c = 30000;
        envoyClassification.Quarter3MarketingBudget__c = 40000;
        envoyClassification.Quarter4MarketingBudget__c = 50000;
        envoyClassification.Year__c = String.valueOf(System.Today().year());
        insert envoyClassification;
        
        BrokerClassification__c AmbassadorClassification = TestObjectsFactory.getBrokerClassificationRecord();
        AmbassadorClassification.Name = 'Ambassador';
        AmbassadorClassification.Quarter1MarketingBudget__c = 50000;
        AmbassadorClassification.Quarter2MarketingBudget__c = 60000;
        AmbassadorClassification.Quarter3MarketingBudget__c = 70000;
        AmbassadorClassification.Quarter4MarketingBudget__c = 80000;
        AmbassadorClassification.Year__c = String.valueOf(System.Today().year());
        insert AmbassadorClassification;
        
        //offer
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        
        insert orgAcc;
                
        
        Id brokerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Broker_Agency')
            .getRecordTypeId();
        Account brokerAcc1 = new Account(Name='broker1',recordTypeId=brokerRecordTypeId);
        brokerAcc1.BillingCountry = 'United Arab Emirates';
        brokerAcc1.AgencyStatus__c = 'Active';
        brokerAcc1.parentId = orgAcc.Id;
        Insert brokerAcc1;
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id); 
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.BrokerAgencyAccount__c = brokerAcc1.Id;
        opp.SaleType__c = 'New Sale';
        insert opp;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        buildingRecord.LaunchStartDate__c = Date.today().addDays(-365);
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
    
    //for eligible sales order
    /*@isTest static void commissionRecords() {
        
        Account accRecord = [select id from Account where IsPersonAccount=true limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id, accountid from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.BookingDate__c = Date.today()-90;
        salesOrderRecord.SalesApprovedDate__c = Date.today()-90;
        salesOrderRecord.Status__c = 'Sold';
        insert salesOrderRecord;
        Datetime yesterday = Datetime.now().addDays(-90);
        Test.setCreatedDate(salesOrderRecord.Id, yesterday);
       
        test.startTest();
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrderRecord.Id, 2);
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrderRecord.Id, optyRecord.AccountId);
    
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, optyRecord.AccountId, optyRecord.Id, 'Credit Card');
        insert receiptAcknowledgement;
        //receiptAcknowledgement.Status__c = 'Cleared';
        //update receiptAcknowledgement;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, optyRecord.AccountId, installmentLineList[0].Id);
        insert receiptAllocation;
        
        ReceiptAllocation__c receiptAllocation1 = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, optyRecord.AccountId, salesOrderOtherCharges.Id);
        insert receiptAllocation1;
        
        Decimal netAmount = 0;
        for(InstallmentLines__c il: installmentLineList){
            il.InstallmentAmount__c = 450000000;
            il.InvoicedAmount__c = il.InstallmentAmount__c;
            netAmount = netAmount + il.InstallmentAmount__c;
        }
        update installmentLineList;
        salesOrderRecord.NetAmount__c = netAmount;
        //update salesOrderRecord;
        
        
        
        system.debug('salesorder '+[select createddate, opportunity__r.BrokerAgencyAccount__c,NetAmount__c,TotalBilled__c from SalesOrder__c]);
        
        Database.executeBatch(new BrokerQuarterlyBonusCalculationsBatch(), 1);
        test.stopTest();
    }*/
    
    //for not eligible sales order
    @isTest static void commissionRecordsNotEligible() {
        test.startTest();
        Account brokerAcc = [SELECT Id from Account where RecordType.Name = 'Broker Agency' Limit 1];
        Account accRecord = [select id from Account where IsPersonAccount=true limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id, accountid,BrokerAgencyAccount__c from opportunity limit 1];
        optyRecord.BrokerAgencyAccount__c = brokerAcc.Id;
        Unit__c unitrecord = [select id from Unit__c limit 1];
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.BookingDate__c = Date.today()-90;
        salesOrderRecord.SalesApprovedDate__c = Date.today()-90;
        salesOrderRecord.Status__c = 'Sold';
        salesOrderRecord.ExcludeFromBonusInvoice__c = false;
        insert salesOrderRecord;
        
        Datetime yesterday = Datetime.now().addDays(-90);
        //Test.setCreatedDate(salesOrderRecord.Id, yesterday);
        
        //test.startTest();
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrderRecord.Id, 2);
        for(InstallmentLines__c il: installmentLineList){
            il.InstallmentPercentage__c = 50.00;
        }
        update installmentLineList;
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrderRecord.Id, optyRecord.AccountId);
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, optyRecord.AccountId, optyRecord.Id, 'Credit Card');
        insert receiptAcknowledgement;
        receiptAcknowledgement.Status__c = 'Cleared';
        receiptAcknowledgement.ClearedDate__c = Date.Today();
        update receiptAcknowledgement;
        
        //ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, optyRecord.AccountId, installmentLineList[0].Id);
        //receiptAllocation.IsStopSyncingWithERP__c = true;
        //insert receiptAllocation;
        
        //ReceiptAllocation__c receiptAllocation1 = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, optyRecord.AccountId, salesOrderOtherCharges.Id);
        //insert receiptAllocation1;
        
        Map<Id,String> agenciesVsClassification = new Map<Id,String>();
        String QuarterValue;
        Integer QuarterNumber;
        Integer Year;
        
        system.debug('salesorder '+[select createddate, opportunity__r.BrokerAgencyAccount__c,NetAmount__c,TotalBilled__c from SalesOrder__c]);
        agenciesVsClassification.put(brokerAcc.id, 'consul');
        
        Database.executeBatch(new BrokerQuarterlyBonusCalculationsBatch(), 1);
        database.executeBatch(new ALD_QuarterlyBonusGeneratorBatch(agenciesVsClassification,'Q4',2, 2024), 1);
        test.stopTest();
    }
    
    @isTest static void qBonusGenerationTest() {
        test.startTest();
        Account parentAcc = [SELECT Id from Account where RecordType.Name = 'Broker Agency' Limit 1];
        Account accRecord = [select id from Account where IsPersonAccount=true limit 1];
        //accRecord.ParentId = parentAcc.Id;
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id, accountid,BrokerAgencyAccount__c from opportunity limit 1];
        optyRecord.BrokerAgencyAccount__c = parentAcc.Id;
        Unit__c unitrecord = [select id from Unit__c limit 1];
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.BookingDate__c = Date.today()-90;
        salesOrderRecord.SalesApprovedDate__c = Date.today()-90;
        salesOrderRecord.Status__c = 'Sold';
        salesOrderRecord.ExcludeFromBonusInvoice__c = false;
        insert salesOrderRecord;
        
        Datetime yesterday = Datetime.now().addDays(-90);
        //Test.setCreatedDate(salesOrderRecord.Id, yesterday);
        
        //test.startTest();
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrderRecord.Id, 2);
        for(InstallmentLines__c il: installmentLineList){
            il.InstallmentPercentage__c = 50.00;
        }
        update installmentLineList;
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrderRecord.Id, optyRecord.AccountId);
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, optyRecord.AccountId, optyRecord.Id, 'Credit Card');
        insert receiptAcknowledgement;
        receiptAcknowledgement.Status__c = 'Cleared';
        receiptAcknowledgement.ClearedDate__c = Date.Today();
        update receiptAcknowledgement;
        
        //ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, optyRecord.AccountId, installmentLineList[0].Id);
        //receiptAllocation.IsStopSyncingWithERP__c = true;
        //insert receiptAllocation;
        //
        //ReceiptAllocation__c receiptAllocation1 = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, optyRecord.AccountId, salesOrderOtherCharges.Id);
        //insert receiptAllocation1;
        
        Map<Id,String> agenciesVsClassification = new Map<Id,String>();
        String QuarterValue;
        Integer QuarterNumber;
        Integer Year;
        
        system.debug('salesorder '+[select createddate, opportunity__r.BrokerAgencyAccount__c,NetAmount__c,TotalBilled__c from SalesOrder__c]);
        agenciesVsClassification.put(parentAcc.id, 'consul');
        
        Database.executeBatch(new BrokerQuarterlyBonusCalculationsBatch(), 1);
        database.executeBatch(new ALD_QuarterlyBonusGeneratorBatch(agenciesVsClassification,'Q3',3, 2024), 1);
        ALD_QuarterlyBonusGeneratorBatch.getQuarter(Date.Today());
        ALD_QuarterlyBonusGeneratorBatch.getQuarter(Date.Today().addMonths(3));
        ALD_QuarterlyBonusGeneratorBatch.getQuarter(Date.Today().addMonths(6));
        ALD_QuarterlyBonusGeneratorBatch.getQuarter(Date.Today().addMonths(9));
        ALD_QuarterlyBonusGeneratorBatch.getQuarter(Date.Today().addMonths(10));
        test.stopTest();
        Database.executeBatch(new BrokerQuarterlyBonusCalculationsBatch(), 1);
    }
}