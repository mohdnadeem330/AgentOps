/*
 *  Test class for InvoiceBundleTriggerHandler
 */
@isTest
public class InvoiceBundleTriggerHandlerTest {
  @testSetup static void setupData() {
        Account acc = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
        insert acc;
        
     	User usr = TestObjectsFactory.getUserRecord('Broker Manager', 'BM001');
        usr.IsActive = True;
      	insert usr;
      
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
      	orgAcc.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
      	orgAcc.SubAccountManager__c = usr.Id;
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
      
      InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
      invoiceBundle.BrokerAgency__c = orgAcc.Id;
      invoiceBundle.BundleName__c = 'BrokerAgencyId';
      invoiceBundle.Status__c = 'Not Ready';
      invoiceBundle.BrokerManager__c = UserInfo.getUserId();
      invoiceBundle.BundleNumber__c = 1;
      insert invoiceBundle;
    }
    
    @isTest 
    static void testInvoiceStatusChangeUpdates1(){
        Test.startTest();
        InvoiceBundle__c inv = [SELECT Id From InvoiceBundle__c Limit 1];
        inv.Status__c = 'Ready for Submission';
        update inv;
        Test.stopTest();
    }
    @isTest 
    static void testInvoiceStatusChangeUpdates2(){
        Test.startTest();
        InvoiceBundle__c inv = [SELECT Id From InvoiceBundle__c Limit 1];
        inv.Status__c = 'Sent to Finance';
        update inv;
        Test.stopTest();
    }
    @isTest 
    static void testInvoiceStatusChangeUpdates3(){
        Test.startTest();
        InvoiceBundle__c inv = [SELECT Id From InvoiceBundle__c Limit 1];
        inv.Status__c = 'Paid';
        update inv;
        Test.stopTest();
    }
    
    @isTest 
    static void testInvoiceStatusChangeUpdates4(){
        Test.startTest();
        InvoiceBundle__c inv = [SELECT Id From InvoiceBundle__c Limit 1];
        inv.Status__c = 'Pending Invoice Verification';
        update inv; 
        Test.stopTest();
    }
        
    @isTest
    static void testInvoiceCommentTrails() {
        Test.startTest();
        InvoiceBundle__c invoiceBundle = [SELECT Id From InvoiceBundle__c Limit 1];
        invoiceBundle.InvoiceApproverComments__c = 'Updated Comment';
        invoiceBundle.InvoiceApproverName__c = 'Latifa';
        invoiceBundle.InvoiceApprovedDate__c = Date.today();
        update invoiceBundle;
        Test.stopTest();
    }

    @isTest
    static void testPaymentCommentTrails() {
        Test.startTest();
        InvoiceBundle__c invoiceBundle = [SELECT Id From InvoiceBundle__c Limit 1];
        invoiceBundle.PaymentApproverComments__c = 'Updated Comment';
        invoiceBundle.PaymentApproverName__c = 'Latifa';
        invoiceBundle.PaymentApprovedDate__c = Date.today();
        update invoiceBundle;
        Test.stopTest();
    }
    @isTest
    static void testBankCommentTrails() {
        Test.startTest();
        InvoiceBundle__c invoiceBundle = [SELECT Id From InvoiceBundle__c Limit 1];
        invoiceBundle.BankComments__c = 'Updated Comment';
        invoiceBundle.BankApprovedDate__c = Date.today();
        update invoiceBundle;
        Test.stopTest();
    }
    
    @isTest static void InvoiceBundleRecords2() {
        
        InvoiceBundle__c invoiceBundle = [SELECT Id From InvoiceBundle__c Limit 1];
        Test.startTest();
        String CypherInvoiceBundleId  = EncryptionUtils.encryptString(invoiceBundle.Id); 
        
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
        
        Test.stopTest();
    }
    @isTest static void InvoiceBundleRecords3() {
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
        invoiceBundle.BrokerManager__c = UserInfo.getUserId();
        invoiceBundle.BundleNumber__c = 1;
        insert invoiceBundle;
        
        invoiceBundle.Status__c = 'Ready for Submission';
        invoiceBundle.ApprovalStatus__c = 'Approved';
        update invoiceBundle;

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
       
        String CypherInvoiceBundleId  = EncryptionUtils.encryptString(invoiceBundle.Id); 
        
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
        
        test.stopTest();
    }
     @isTest static void InvoiceBundleRecords4() {
        Test.startTest();
        InvoiceBundle__c invoiceBundle = [SELECT Id From InvoiceBundle__c Limit 1];     
        
        invoiceBundle.Status__c = 'Pending Invoice Verification';
        invoiceBundle.ApprovalStatus__c = 'Approved';
        invoiceBundle.AgencyAdmin__c = UserInfo.getUserId();
        invoiceBundle.BrokerManager__c = UserInfo.getUserId();
        update invoiceBundle;
        Test.stopTest();
    }
}