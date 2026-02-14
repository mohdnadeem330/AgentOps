/**
* BrokerInvoicePDFControllerTest
*
* Test class for BrokerInvoicePDFController 
*/
@isTest
private class BrokerInvoicePDFControllerTest{
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
     //Test Commission record creation
    @isTest static void commissionRecords() {
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
            
            //Create Commission
            //split based on the payout 
            if (tempInstallmentLine.BrokerPayoutPercentage__c!=null && tempInstallmentLine.BrokerPayoutPercentage__c!=0) {
                CommissionLineItem__c commissionLineExtenalRecord = new CommissionLineItem__c();
                commissionLineExtenalRecord.BrokerAgent__c = conRecord.id;
                commissionLineExtenalRecord.BrokerAgency__c = accRecord.Id;
                commissionLineExtenalRecord.CommissionAmount__c = (totalCommission * (tempInstallmentLine.BrokerPayoutPercentage__c/100)).setScale(2);
                commissionLineExtenalRecord.CommissionPercentage__c = tempInstallmentLine.BrokerPayoutPercentage__c;
                commissionLineExtenalRecord.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
                commissionLineExtenalRecord.SalesManager__c = UserInfo.getUserId();
                commissionLineExtenalRecord.SalesOrder__c = salesOrderRecord.Id;
                externalCommission.add(commissionLineExtenalRecord);
            }
        }
        if(!installmentLines.isEmpty()){
            insert installmentLines;
        }
        if(!externalCommission.isEmpty()){
            insert externalCommission;
            externalCommission[0].Status__c=Constants.COMMISSION_LINE_STATUS_FIXED;
            externalCommission[0].ApprovalStatus__c = 'Approved';
            //externalCommission[0].GenerateClaimForm__c = true;
            externalCommission[0].InvoiceNumber__c='0';
            list<CommissionLineItem__c> oldRec =new list<CommissionLineItem__c>();
            oldRec.add(new CommissionLineItem__c(id=externalCommission[0].Id,Status__c=null/*,GenerateClaimForm__c=false*/,InvoiceNumber__c='0'));
            oldRec.add(new CommissionLineItem__c(id=externalCommission[1].Id,Status__c=null,InvoiceNumber__c='0'));
        }
        list<CommissionLineItem__c> commissionRecords = [select id from CommissionLineItem__c];
        commissionRecords[0].ApprovalStatus__c='In Progress';
        commissionRecords[0].Comments__c='Update';
        update commissionRecords[0];
        CommissionLineItemTriggerHandler.checkandCreatePublicLink(new set<ID>{ commissionRecords[0].Id});
        System.assertEquals(commissionRecords.isEmpty(), false);
        
        ApexPages.currentPage().getParameters().put('invoiceId',commissionRecords[0].Id);
        BrokerInvoicePDFController controllerObject = new BrokerInvoicePDFController();
        BrokerInvoicePDFController.regenerateBrokerInvoice(commissionRecords[0].Id);
    }
    //test PDF generation
    @isTest static void testNoRecords() {
        ApexPages.currentPage().getParameters().put('invoiceId','testId');
        BrokerInvoicePDFController controllerObject = new BrokerInvoicePDFController();
        System.assertEquals(null, controllerObject.commissionRecord);
    }
}