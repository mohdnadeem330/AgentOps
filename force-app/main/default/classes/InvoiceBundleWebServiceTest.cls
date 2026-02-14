/*
 *  Test class for InvoiceBundleWebService
*/

@isTest
public class InvoiceBundleWebServiceTest {
    
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
    
    
    private static InvoiceBundle__c createInvoiceBundle(String status) {
        
        list<CommissionLineItem__c> cliList = new list<CommissionLineItem__c>();
        Integer currentYear = System.today().year();
        list<CommissionLineItem__c> commissionLineItems = [SELECT BrokerAgency__c,Id,InstallmentLine__c,InstalmentNumber__c,InstalmentPaid__c,InstalmentPercentage__c,InvoiceBundle__c,InvoiceDate__c,InvoiceNumber__c,Name,Project__c,QuarterlyBonusCommission__c,
                                                           QuarterlyPayout__c,SalesOrder__c,Status__c,TotalExternalCommissionPercentage__c,TotalPayableCommission__c,Total_External_Commission__c,Unit_Number__c,Unit__c FROM CommissionLineItem__c
                                                           WHERE InvoiceBundle__c = null AND BrokerAgency__c != null AND CALENDAR_YEAR(SalesOrder__r.createdDate)= :currentYear
                                                           AND CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION
                                                           AND SalesOrder__r.Status__c != 'Cancelled' AND Status__c = 'Ready for Submission'];
        
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
        invoiceBundle.BrokerAgency__c = commissionLineItems[0].BrokerAgency__c;
        invoiceBundle.BundleName__c = 'brokerAgencyId';
        invoiceBundle.Status__c = status;
        invoiceBundle.BundleNumber__c = 1;
        insert invoiceBundle;
        return invoiceBundle;
    }
    
    @isTest
    static void test_doPost_InvoiceApprovalInProgress() {
        // Create a test InvoiceBundle record
        InvoiceBundle__c invoiceBundle = createInvoiceBundle('Invoice Approval In Progress');
        
        // Prepare the JSON payload
        String jsonPayload = '{"InvoiceBundleId": "' + invoiceBundle.Id + '",'
            + '"Status": "Invoice Approval In Progress",'
            + '"ErpId": "TestERP",'
            + '"invResponse": "Approved",'
            + '"invApprName": "John Doe",'
            + '"invApprComments": "Test Approval",'
            + '"invApprDate": "2025-01-24"}';
        
        // Create a mock RestContext
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the doPost method
        InvoiceBundleWebService.doPost();
        
        // Verify the changes in the InvoiceBundle record
        InvoiceBundle__c updatedInvoiceBundle = [SELECT Id, Status__c, InvoiceResponse__c, 
                                                 InvoiceApproverName__c, InvoiceApproverComments__c, 
                                                 InvoiceApprovedDate__c 
                                                 FROM InvoiceBundle__c WHERE Id = :invoiceBundle.Id];
        
        System.assertEquals('Invoice Approval In Progress', updatedInvoiceBundle.Status__c);
        System.assertEquals('Approved', updatedInvoiceBundle.InvoiceResponse__c);
        System.assertEquals('John Doe', updatedInvoiceBundle.InvoiceApproverName__c);
        System.assertEquals('Test Approval', updatedInvoiceBundle.InvoiceApproverComments__c);
        System.assertEquals(Date.valueOf('2025-01-24'), updatedInvoiceBundle.InvoiceApprovedDate__c);
        
        Test.stopTest();
    }
    
    @isTest
    static void test_doPost_PaymentApprovalInProgress() {
        // Create a test InvoiceBundle record
        InvoiceBundle__c invoiceBundle = createInvoiceBundle('Payment Approval In Progress');
        
        // Prepare the JSON payload
        String jsonPayload = '{"InvoiceBundleId": "' + invoiceBundle.Id + '",'
            + '"Status": "Payment Approval In Progress",'
            + '"ErpId": "TestERP",'
            + '"payResponse": "Approved",'
            + '"payApprName": "Jane Doe",'
            + '"payApprComments": "Payment Approved",'
            + '"payApprDate": "2025-01-25"}';
        
        // Create a mock RestContext
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the doPost method
        InvoiceBundleWebService.doPost();
        
        // Verify the changes in the InvoiceBundle record
        InvoiceBundle__c updatedInvoiceBundle = [SELECT Id, Status__c, PaymentResponse__c, 
                                                 PaymentApproverName__c, PaymentApproverComments__c, 
                                                 PaymentApprovedDate__c 
                                                 FROM InvoiceBundle__c WHERE Id = :invoiceBundle.Id];
        
        System.assertEquals('Payment Approval In Progress', updatedInvoiceBundle.Status__c);
        System.assertEquals('Approved', updatedInvoiceBundle.PaymentResponse__c);
        System.assertEquals('Jane Doe', updatedInvoiceBundle.PaymentApproverName__c);
        System.assertEquals('Payment Approved', updatedInvoiceBundle.PaymentApproverComments__c);
        System.assertEquals(Date.valueOf('2025-01-25'), updatedInvoiceBundle.PaymentApprovedDate__c);
        
        Test.stopTest();
    }
    
    @isTest
    static void test_doPost_PaymentUnderBankClearance() {
        // Create a test InvoiceBundle record
        InvoiceBundle__c invoiceBundle = createInvoiceBundle('Payment Under Bank Clearance');
        
        // Prepare the JSON payload
        String jsonPayload = '{"InvoiceBundleId": "' + invoiceBundle.Id + '",'
            + '"Status": "Payment Under Bank Clearance",'
            + '"ErpId": "TestERP",'
            + '"bankResponse": "Clear",'
            + '"bankComments": "Bank Cleared",'
            + '"bankApprDate": "2025-01-26"}';
        
        // Create a mock RestContext
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the doPost method
        InvoiceBundleWebService.doPost();
        
        // Verify the changes in the InvoiceBundle record
        InvoiceBundle__c updatedInvoiceBundle = [SELECT Id, Status__c, BankResponse__c, 
                                                 BankComments__c, BankApprovedDate__c 
                                                 FROM InvoiceBundle__c WHERE Id = :invoiceBundle.Id];
        
        System.assertEquals('Payment Under Bank Clearance', updatedInvoiceBundle.Status__c);
        System.assertEquals('Clear', updatedInvoiceBundle.BankResponse__c);
        System.assertEquals('Bank Cleared', updatedInvoiceBundle.BankComments__c);
        System.assertEquals(Date.valueOf('2025-01-26'), updatedInvoiceBundle.BankApprovedDate__c);
        
        Test.stopTest();
    }
    
    @isTest
    static void test_doPost_ExceptionHandling() {
        // Create a mock RestContext with invalid data
        String jsonPayload = '{"InvoiceBundleId": "InvalidId", "Status": "Invoice Approval In Progress"}';
        
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the doPost method
        InvoiceBundleWebService.doPost();
        
        // Verify that the response is a failure (since InvalidId doesn't exist)
        //System.assertEquals(400, RestContext.response.statusCode);
        
        Test.stopTest();
    }
    
}