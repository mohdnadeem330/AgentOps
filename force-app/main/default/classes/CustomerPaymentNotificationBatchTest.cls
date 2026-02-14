/**
* CustomerPaymentNotificationBatchTest
*
* Test class for CustomerPaymentNotificationBatch
*/
@isTest
private class CustomerPaymentNotificationBatchTest{
    @testSetup static void setupData() {
            //offer
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
            
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
    //Test Installment records,
    @isTest static void testInstallmentEmailNotification() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
       
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
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
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
            
           
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0].InstallmentDate__c=System.Today().addDays(30);
            insert installmentLines;
        }
        Test.StartTest();
        System.schedule('CustomerPaymentNotificationBatch-Test', '0 0 * * * ?', new CustomerPaymentNotificationBatch() );
        ALD_IL_PaymentReminder.sendReminder(installmentLines[0].Id,'Payment Reminder',null);
        Test.StopTest();
    }
    //Test Installment records,
    @isTest static void testInstallmentEmailNotificationForMilestoneChange() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
       
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
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
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
            
           
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0].InstallmentDate__c=System.Today().addDays(30);
            insert installmentLines;
        }
        Test.StartTest();
        System.schedule('CustomerPaymentNotificationBatch-Test', '0 0 * * * ?', new CustomerPaymentNotificationBatch() );
        ALD_IL_PaymentReminder.sendReminder(installmentLines[0].Id,'Mile stone change letter',salesOrderRecord.Id);
        Test.StopTest();
    }
    //Test Installment records,
    @isTest static void testInstallmentSMSNotification() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        conRecord.MobileCountryCode__c='971';
        conRecord.MobilePhone__c='555555555';
        update conRecord;
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.Contact__c= conRecord.Id;
        insert salesOrderRecord;
        
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
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
            
           
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0].InstallmentDate__c=System.Today().addDays(15);
            insert installmentLines;
        }
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new OutboundCallMockResponse());
        System.schedule('CustomerPaymentNotificationBatch-Test', '0 0 * * * ?', new CustomerPaymentNotificationBatch() );
        Test.StopTest();
    }
}