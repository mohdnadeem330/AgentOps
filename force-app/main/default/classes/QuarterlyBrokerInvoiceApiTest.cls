@isTest
public class QuarterlyBrokerInvoiceApiTest {
	//Setup test Data
    @testSetup static void setupData() {
        //offer
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        insert orgAcc;
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);	
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.BrokerAgencyAccount__c = orgAcc.Id;
        opp.BrokerAgentContact__c = conRecord.Id;
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
          SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
        QuarterlyBonusCommission__c bonus = new QuarterlyBonusCommission__c();
        bonus.BrokerAgency__c = acc.Id;
        bonus.Status__c = 'Not Ready';
        bonus.Year__c = '2022';
        bonus.Quarter__c = 'Q4';
        insert bonus;
        
        CommissionLineItem__c cli = new CommissionLineItem__c();
        cli.BrokerAgent__c = conRecord.id;
        cli.BrokerAgency__c = acc.Id;
        cli.CommissionAmount__c = 500;
        cli.CommissionPercentage__c = 0.75;
        cli.CommissionType__c = Constants.COMMISSION_LINE_BONUS_COMMISSION;
        cli.SalesManager__c = UserInfo.getUserId();
        cli.SalesOrder__c = salesOrderRecord.Id;
        cli.QuarterlyBonusCommission__c = bonus.Id;
        insert cli;
        
        
    }
    
    @isTest static void commissionRecords() {
        
        QuarterlyBonusCommission__c bonus = [SELECT Id,BrokerAgency__c,Status__c,Year__c,Quarter__c,
                                             (SELECT Id,Name,BrokerAgency__c,CommissionAmount__c,Unit__c,SalesOrder__c,OrderDate__c,CommissionPercentage__c,
                                              NetAmount__c,BrokerAgency__r.name,BrokerAgency__r.Broker_Classification_Formula__c,Unit__r.Name From Commission_Line_Items__r) From QuarterlyBonusCommission__c Limit 1];
        String responseBody = '{\"applicationName\":\"test\",\"success\":true,\"statusCode\":\"201\",\"correlationId\":\"2345784\",\"results\":{\"BonusInvRes\":[{\"SFID\":\"a2A8d000000M5HwEAK\",\"ErpId\":\"3449458\",\"status\":\"Y\",\"errorMsg\":\"ERPInvoicealreadyexists.Ref#BONINV-Q4-2022-2997405-300323\",\"invoiceNum\":\"BONINV-Q4-2022-2997405-300323\"},{\"SFID\":\"a2A8d000000MSQFEA4\",\"ErpId\":\"3449459\",\"status\":\"Y\",\"errorMsg\":\"ERPInvoicealreadyexists.Ref#BONINV-Q4-2022-2997406-300323\",\"invoiceNum\":\"BONINV-Q4-2022-2997406-300323\"}]}}';
        QuarterlyBrokerInvoiceResponse.parse(responseBody);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        test.startTest();
        
        QuarterlyBrokerInvoiceApi.generateInvoice(new List<QuarterlyBonusCommission__c>{bonus});
      	QuarterlyBrokerRequestPayload.parse(responseBody);
        test.stopTest();
    }
    
}