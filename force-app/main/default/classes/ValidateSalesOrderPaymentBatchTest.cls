/* 
* ValidateSalesOrderPaymentBatchTest
*
* Test class for ValidateSalesOrderPaymentBatch
*/
@isTest
private class ValidateSalesOrderPaymentBatchTest{
    //Create test data
    @testSetup static void setupData() {
            //offer
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            acc.CustomerVertical__c = 'LSQ';
            insert acc;
            Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
            orgAcc.CustomerVertical__c = 'LSQ';
            insert orgAcc;
            Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id); 
        
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        	opp.SaleType__c = 'New Sale';
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
    //Validate the batch 
    @isTest static void validatePaymentTest() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id, SaleType__c from opportunity limit 1];
        optyRecord.SaleType__c = 'New Sale';
        update optyRecord;
        
        System.debug('optyRecord==>' + optyRecord);
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
        salesOrderRecord.Status__c=Constants.OPPO_UNIT_STATUS_PENDING;
        salesOrderRecord.CustomerSPASigned__c = true;
        salesOrderRecord.CustomerSignedSPADate__c = date.today();
         salesOrderRecord.ComplianceStatus__c = Constants.STATUS_CLEARED;
        update salesOrderRecord;
        
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        list<CommissionLineItem__c> externalCommission= new list<CommissionLineItem__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c=system.today().addDays(-5), 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                InvoicedAmount__c=totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }
        if(!installmentLines.isEmpty()){
            insert installmentLines;
        }
        
        list<SalesOrderOtherCharges__c>  soOthCharges = new list<SalesOrderOtherCharges__c>();
        soOthCharges.add(new SalesOrderOtherCharges__c(
            SalesOrder__c = salesOrderRecord.Id,
            TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE,
            Amount__c = 100,
            InvoicedAmount__c = 100,
            Account__C = accRecord.id
        ));
        
        SalesOrderOtherCharges__c sorc = new SalesOrderOtherCharges__c();
        sorc.SalesOrder__c = salesOrderRecord.Id;
        sorc.TypeOfCharge__c = 'ADM Admin Fee';
        sorc.Amount__c = 100;
        sorc.InvoicedAmount__c = 100;
        sorc.Account__C = accRecord.id;
        soOthCharges.add(sorc);
        insert soOthCharges;
        
        test.startTest();
        System.schedule('ValidateSalesOrderPaymentBatch-Test', '0 0 * * * ?', new ValidateSalesOrderPaymentBatch() );
        test.stopTest();
        
    }
}