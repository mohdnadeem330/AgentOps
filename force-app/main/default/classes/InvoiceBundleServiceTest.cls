/*
 *  Test class for InvoiceBundleService, BatchToIntegrateInvoiceBundleWithERP,BatchToInvoiceBundle.
 */
@isTest
public class InvoiceBundleServiceTest {
    @testSetup static void setupData() {
        Account acc = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
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
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.ExternalCommissionAmount__c = 10000000;
        salesOrderRecord.AmountPayable__c = 500000;
        salesOrderRecord.NetAmount__c = 1000000000;
        salesOrderRecord.Status__c = 'Sold';
        insert salesOrderRecord;
        
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        list<CommissionLineItem__c> externalCommission= new list<CommissionLineItem__c>();
        
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            if (tempInstallmentLine.BrokerPayoutPercentage__c!=null && tempInstallmentLine.BrokerPayoutPercentage__c!=0) {
                CommissionLineItem__c commissionLineExtenalRecord = new CommissionLineItem__c();
                commissionLineExtenalRecord.BrokerAgent__c = conRecord.id;
                commissionLineExtenalRecord.BrokerAgency__c = conRecord.AccountId;
                commissionLineExtenalRecord.CommissionAmount__c = (totalCommission * (tempInstallmentLine.BrokerPayoutPercentage__c/100)).setScale(2);
                commissionLineExtenalRecord.CommissionPercentage__c = tempInstallmentLine.BrokerPayoutPercentage__c;
                commissionLineExtenalRecord.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
                commissionLineExtenalRecord.SalesManager__c = UserInfo.getUserId();
                commissionLineExtenalRecord.SalesOrder__c = salesOrderRecord.Id;
                commissionLineExtenalRecord.Status__c = 'Ready for Submission';
                externalCommission.add(commissionLineExtenalRecord);
            }
        }
        if(!externalCommission.isEmpty()){
           insert externalCommission;
        } 
    }
    @isTest static void InvoiceBundleRecords1() {
        list<CommissionLineItem__c> cliList = new list<CommissionLineItem__c>();
        list<CommissionLineItem__c> commissionLineItems = [SELECT BrokerAgency__c,Id,InstallmentLine__c,InstalmentNumber__c,InstalmentPaid__c,InstalmentPercentage__c,InvoiceBundle__c,InvoiceDate__c,InvoiceNumber__c,Name,Project__c,QuarterlyBonusCommission__c,
                                                           QuarterlyPayout__c,SalesOrder__c,Status__c,TotalExternalCommissionPercentage__c,TotalPayableCommission__c,Total_External_Commission__c,Unit_Number__c,Unit__c FROM CommissionLineItem__c
                                                           WHERE InvoiceBundle__c = null AND BrokerAgency__c != null AND CALENDAR_YEAR(SalesOrder__r.createdDate)= 2023 
                                                           AND CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION
                                                           AND SalesOrder__r.Status__c != 'Cancelled' AND Status__c = 'Ready for Submission'];
        
        test.startTest();
        BatchToInvoiceBundle batch = new BatchToInvoiceBundle();
        database.executeBatch(batch);
        test.stopTest();
    }
    @isTest static void InvoiceBundleRecords2() {
        list<CommissionLineItem__c> cliList = new list<CommissionLineItem__c>();
        Integer currentYear = System.today().year();
        list<CommissionLineItem__c> commissionLineItems = [SELECT BrokerAgency__c,Id,InstallmentLine__c,InstalmentNumber__c,InstalmentPaid__c,InstalmentPercentage__c,InvoiceBundle__c,InvoiceDate__c,InvoiceNumber__c,Name,Project__c,QuarterlyBonusCommission__c,
                                                           QuarterlyPayout__c,SalesOrder__c,Status__c,TotalExternalCommissionPercentage__c,TotalPayableCommission__c,Total_External_Commission__c,Unit_Number__c,Unit__c FROM CommissionLineItem__c
                                                           WHERE InvoiceBundle__c = null AND BrokerAgency__c != null AND CALENDAR_YEAR(SalesOrder__r.createdDate)= :currentYear
                                                           AND CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION
                                                           AND SalesOrder__r.Status__c != 'Cancelled' AND Status__c = 'Ready for Submission'];
        
        test.startTest();
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
        invoiceBundle.BrokerAgency__c = commissionLineItems[0].BrokerAgency__c;
        invoiceBundle.BundleName__c = 'brokerAgencyId';
        invoiceBundle.Status__c = 'Not Ready';
        invoiceBundle.BundleNumber__c = 1;
        insert invoiceBundle;
        
        invoiceBundle.Status__c = 'Ready for Submission';
        //update invoiceBundle;

        for(CommissionLineItem__c cli: commissionLineItems){
            CommissionLineItem__c clitem = new CommissionLineItem__c();
            clitem.id = cli.Id;
            clitem.InvoiceBundle__c = invoiceBundle.Id;
            cliList.add(clitem);
        }
        update cliList;
        list<CommissionLineItem__c> commissionLineItems1 = [SELECT BrokerAgency__c,Id,InstallmentLine__c,InstalmentNumber__c,InstalmentPaid__c,InstalmentPercentage__c,InvoiceBundle__c,InvoiceDate__c,InvoiceNumber__c,Name,Project__c,QuarterlyBonusCommission__c,
                               QuarterlyPayout__c,SalesOrder__c,Status__c,TotalExternalCommissionPercentage__c,TotalPayableCommission__c,Total_External_Commission__c,Unit_Number__c,Unit__c FROM CommissionLineItem__c
                               WHERE Id In: cliList];
        InvoiceBundleController.getInvoiceBundles(null, null);
        InvoiceBundleController.cliSubmitForReview(commissionLineItems1[0].Id, 'Test', true);
        
        String CypherInvoiceBundleId  = EncryptionUtils.encryptString(invoiceBundle.Id); 
        
        InvoiceBundleController.updateStatus(CypherInvoiceBundleId, Constants.COMMISSION_LINE_STATUS_ACCEPTED,'Test comment');
        InvoiceBundleController.generateInvoiceDocument(invoiceBundle.Id);
        List<InvoiceBundleTriggerHandler.InputVariables> inputVariables = new List<InvoiceBundleTriggerHandler.InputVariables>();
        InvoiceBundleTriggerHandler.InputVariables inputVariable = new InvoiceBundleTriggerHandler.InputVariables();
        inputVariable.invoiceBundleList = new List<InvoiceBundle__c>{invoiceBundle};
        inputVariables.add(inputVariable);
        InvoiceBundleTriggerHandler.prepareCallout(inputVariables);
        
        InvoiceBundleTriggerHandler.updateAllCLIStatuses(new List<InvoiceBundle__c>{invoiceBundle});
        String json = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "fa3ae840-6c1d-11ee-b8bc-024bdfb6b45d","results": [{ "sfRequestId": "fa3ae840-6c1d-11ee-b8bc-024bdfb6b45d","sfBundleId":"'+invoiceBundle.Id+'","status": "Failure", "errorMsg": "Bundle a3T25000000uez7EAA is already exists" }]}';
        
        InvoiceBundleTriggerHandler.updateERPResponse(json);
        InvoiceBundleWrapper.parseResponse(json);
        
        PageReference testPage = Page.QuarterlyInvoicePDF; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('invoiceId', CypherInvoiceBundleId);
        
        BrokerInvoiceBundlePDFController ext = new BrokerInvoiceBundlePDFController();
        
        invoiceBundle.Status__c = 'Pending Invoice Verification';
        invoiceBundle.ApprovalStatus__c = 'Approved';
        invoiceBundle.AgencyAdmin__c = UserInfo.getUserId();
        update invoiceBundle;
        
        BatchToIntegrateInvoiceBundleWithERP batch = new BatchToIntegrateInvoiceBundleWithERP();
        database.executeBatch(batch);

        InvoiceBundleService.deReferenceCommissionLinesOnRejection(new List<InvoiceBundle__c>{invoiceBundle});
        InvoiceBundleService.getCountOnInvoiceBunlde (new List<Id>{invoiceBundle.id});
        test.stopTest();
    }
    @isTest static void InvoiceBundleRecords3() {
        Integer currentYear = System.today().year();
        List<InvoiceBundle__c> invList = new List<InvoiceBundle__c>();
        list<CommissionLineItem__c> commissionLineItems = [SELECT BrokerAgency__c,Id,InstallmentLine__c,InstalmentNumber__c,InstalmentPaid__c,InstalmentPercentage__c,InvoiceBundle__c,InvoiceDate__c,InvoiceNumber__c,Name,Project__c,QuarterlyBonusCommission__c,
                                                           QuarterlyPayout__c,SalesOrder__c,Status__c,TotalExternalCommissionPercentage__c,TotalPayableCommission__c,Total_External_Commission__c,Unit_Number__c,Unit__c FROM CommissionLineItem__c
                                                           WHERE InvoiceBundle__c = null AND BrokerAgency__c != null AND CALENDAR_YEAR(SalesOrder__r.createdDate)= :currentYear 
                                                           AND CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION
                                                           AND SalesOrder__r.Status__c != 'Cancelled' AND Status__c = 'Ready for Submission'];
        
        test.startTest();
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
        invoiceBundle.BrokerAgency__c = commissionLineItems[0].BrokerAgency__c;
        invoiceBundle.BundleName__c = 'brokerAgencyId';
        invoiceBundle.Status__c = 'Not Ready';
        invoiceBundle.BundleNumber__c = 1;
        invoiceBundle.BrokerManager__c = UserInfo.getUserId();
        insert invoiceBundle;
        system.debug('invoiceBundle::'+invoiceBundle);
        InvoiceBundle__c invBundle = [Select Id, Status__c, BrokerAgency__c, BundleName__c, BundleNumber__c from InvoiceBundle__c where Id =: invoiceBundle.Id];
        system.debug('invBundle list ::'+invBundle);
        invBundle.Status__c = 'Ready for Submission';
        invBundle.AgencyAdmin__c = UserInfo.getUserId(); 
        invList.add(invBundle);
        //update invList;
        system.debug('invBundle::'+invBundle);
        invBundle.Status__c='Sent to Finance';
        update invBundle;
        
        invBundle.Status__c='Paid';
        //update invBundle;
        
        String CypherInvoiceBundleId  = EncryptionUtils.encryptString(invBundle.Id); 
       
        InvoiceBundleController.getInvoiceBundles(null,null);
        InvoiceBundleController.getCommissionTrail(CypherInvoiceBundleId);
        
        TestObjectsFactory.initializeRestContext(null, '/update/InvoiceBundle');
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');        
        RestContextHandler handler = new RestContextHandler(false);
        //InvoiceBundleWebService.doPost();
        test.stopTest();
    }
    
    @isTest static void InvoiceBundleTrigerTest() {
        list<CommissionLineItem__c> cliList = new list<CommissionLineItem__c>();
        Integer currentYear = System.today().year();
        list<CommissionLineItem__c> commissionLineItems = [SELECT BrokerAgency__c,Id,InstallmentLine__c,InstalmentNumber__c,InstalmentPaid__c,InstalmentPercentage__c,InvoiceBundle__c,InvoiceDate__c,InvoiceNumber__c,Name,Project__c,QuarterlyBonusCommission__c,
                                                           QuarterlyPayout__c,SalesOrder__c,Status__c,TotalExternalCommissionPercentage__c,TotalPayableCommission__c,Total_External_Commission__c,Unit_Number__c,Unit__c FROM CommissionLineItem__c
                                                           WHERE InvoiceBundle__c = null AND BrokerAgency__c != null AND CALENDAR_YEAR(SalesOrder__r.createdDate)= :currentYear
                                                           AND CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION
                                                           AND SalesOrder__r.Status__c != 'Cancelled' AND Status__c = 'Ready for Submission'];
        
        test.startTest();
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
        invoiceBundle.BrokerAgency__c = commissionLineItems[0].BrokerAgency__c;
        invoiceBundle.BundleName__c = 'brokerAgencyId';
        invoiceBundle.Status__c = 'Not Ready';
        invoiceBundle.BundleNumber__c = 1;
        insert invoiceBundle;
        InvoiceBundle__c ib = [SELECT Id,Status__c from InvoiceBundle__c where id =: invoiceBundle.id Limit 1];
        System.debug(Trigger.isBefore+'--'+Trigger.isUpdate);
        //update new InvoiceBundle__c(id = ib.id, Status__c = 'Ready for Submission', AgencyAdmin__c = UserInfo.getUserId(), BrokerManager__c = UserInfo.getUserId());
        
        //update new InvoiceBundle__c(id = ib.id, Status__c = 'Sent to Finance');
        test.stopTest();
        
    }
    
    
    
}