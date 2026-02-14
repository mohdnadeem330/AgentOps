/**
* ValidateCrateDandTSRBatchTest
*
* Test class for ValidateCrateDandTSRBatchTest
*/
@isTest
private class ValidateCrateDandTSRBatchTest{
    @testSetup static void setupData() {
        ReceiptSalesOrderOtherCharge__c soChargeIsActive = new ReceiptSalesOrderOtherCharge__c();
        soChargeIsActive.ActiveSOChargeCreation__c = true;
        insert soChargeIsActive;
        
        ChargeRule__c chrg = new ChargeRule__c();
        chrg.ChargeAmount__c = 500;
        chrg.VATChanges__c = 5;
        chrg.SRType__c = ALD_Constants.CHARGE_RULE_SALES_ORDER_OTHER_CHARGES;
        chrg.ChargeType__c = ALD_Constants.CHARGE_RULE_REVERSAL_CHARGE_TYPE;
        insert chrg;
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
        
        //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.DEFAULT_AND_TERMINATION;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.DEFAULT_AND_TERMINATION;
        insert SR_Template;
        
        // STEP AND STEP TEMPLATE
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        ST.HexaBPM__Code__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{TestObjectsFactory.getSRStatus(Constants.SUBMITTED),TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT)};
            
            ReceiptAcknowledgement__c receiptAcknowledgementOne = TestObjectsFactory.getReceiptAcknowledgementRecord(null, acc.Id, opp.Id, 'Online');
        
        receiptAcknowledgementOne.ChequeReceived__c = false;
        //receiptAcknowledgementOne.PaymentType__c = 'Online';
        insert receiptAcknowledgementOne;
        
        
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
        unitrecord.Status__c = COnstants.UNIT_STATUS_SOLD;
        update unitrecord;
        
        
        
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
            insert installmentLines;
            
            ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, accRecord.Id, optyRecord.Id, 'Credit Card');
            receiptAcknowledgement.ChequeReceived__c = true;
           // receiptAcknowledgement.PaymentType__c = 'Mortgage Cheque';
            receiptAcknowledgement.Status__c ='Reversed';
            receiptAcknowledgement.StatusReason__c = 'Account Closed';
            insert receiptAcknowledgement;
            
            receiptAcknowledgement.ChequeReceived__c = true;
            update receiptAcknowledgement;
            
            ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, accRecord.Id, installmentLines[0].Id);
            insert receiptAllocation;

        }
        Test.StartTest(); 
        Database.executeBatch(new ValidateCrateDandTSRBatch(new Set<Id>{installmentLines[0].Id}),1);
        Database.executeBatch(new PreDefaultBatch(new Set<Id>{installmentLines[0].Id}),1);
       // System.schedule('ValidateCrateDandTSRBatch-Test', '0 0 * * * ?', new ValidateCrateDandTSRBatch(null) );
        Test.StopTest();
    }
    
}