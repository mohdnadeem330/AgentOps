@isTest
public class CustomerPaymentReceiptWebServiceTest {
    
    private static void setupRestRequest(String requestBody){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/paymentReceipt';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPaymentReceiptWebService.createPaymentReceipts(requestBody);
        Test.stopTest();
    }
    
    @testSetup
    public static void testSetupData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Is_Digital_Sales__c = true;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLine = TestObjectsFactory.createInstallmentLines(salesOrder.Id,1);
        
        SalesOrderOtherCharges__c salesOrderOtherCharge = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id,'Wire Transfer');
        receipt.Amount__c = 100;
        insert receipt;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receipt.Id,salesOrder.Id, acc.Id,installmentLine[0].Id);
        receiptAllocation.AmountApplied__c = 100;
        insert receiptAllocation;
    }
    
    @isTest
    public static void createReceiptWithInstallment() {
        
        SalesOrder__c salesOrder = [SELECT Id, Account__c, Opportunity__c FROM SalesOrder__c LIMIT 1];
        InstallmentLines__c install = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppo = [SELECT Id FROM Opportunity LIMIT 1];
        
        String refNum = 'UT-REF-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        String authRef = String.valueOf(Crypto.getRandomInteger()) + '-auth';
        String jsonBody =
            '{' +
            '"ReceiptAcknowledgement__c":{' +
            '"SalesOrder__c":"' + salesOrder.Id + '",' +
            '"Opportunity__c":"' + oppo.Id + '",' +
            '"Account__c":"' + acc.Id + '",' +
            '"Amount__c": 250.75,' +
            '"ReferenceNumber__c":"' + refNum + '",' +
            '"AuthenticationReferenceNumber__c":"' + authRef + '"' +
            '},' +
            '"ReceiptAllocation__c":[' +
            '{' +
            '"AmountApplied__c": 250.75,' +
            '"InstallmentLine__c":"' + install.Id + '",' +
            '"SalesOrderOtherCharges__c":""' +
            '}' +
            '],' +
            '"Source":"Lean"' +
            '}';
        
        setupRestRequest(jsonBody);
    }
    
    @isTest
    public static void createReceiptWithOtherCharge() {
        
        SalesOrder__c salesOrder = [SELECT Id, Account__c, Opportunity__c FROM SalesOrder__c LIMIT 1];
        SalesOrderOtherCharges__c otherCharge = [SELECT Id FROM SalesOrderOtherCharges__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppo = [SELECT Id FROM Opportunity LIMIT 1];
        
        String refNum = 'UT-REF-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        String authRef = String.valueOf(Crypto.getRandomInteger()) + '-auth';
        String jsonBody =
            '{' +
            '"ReceiptAcknowledgement__c":{' +
            '"SalesOrder__c":"' + salesOrder.Id + '",' +
            '"Opportunity__c":"' + oppo.Id + '",' +
            '"Account__c":"' + acc.Id + '",' +
            '"Amount__c": 250.75,' +
            '"ReferenceNumber__c":"' + refNum + '",' +
            '"AuthenticationReferenceNumber__c":"' + authRef + '"' +
            '},' +
            '"ReceiptAllocation__c":[' +
            '{' +
            '"AmountApplied__c": 250.75,' +
            '"SalesOrderOtherCharges__c":"' + otherCharge.Id + '",' +
            '"InstallmentLine__c":""' +
            '}' +
            '],' +
            '"Source":"Lean"' +
            '}';
        
        setupRestRequest(jsonBody);
    }
    
    @isTest
    public static void negativeTestingWithInvalidSalesOrder() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppo = [SELECT Id FROM Opportunity LIMIT 1];
        
        String refNum = 'UT-REF-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        String authRef = String.valueOf(Crypto.getRandomInteger()) + '-auth';
        String jsonBody =
            '{' +
            '"ReceiptAcknowledgement__c":{' +
            '"SalesOrder__c":"' + 'a2AFV000000zFDS2A3' + '",' +
            '"Opportunity__c":"' + oppo.Id + '",' +
            '"Account__c":"' + acc.Id + '",' +
            '"Amount__c": 250.75,' +
            '"ReferenceNumber__c":"' + refNum + '",' +
            '"AuthenticationReferenceNumber__c":"' + authRef + '"' +
            '},' +
            '"ReceiptAllocation__c":[' +
            '{' +
            '"AmountApplied__c": 250.75,' +
            '"SalesOrderOtherCharges__c":"' + 'a29FV000000EaQDYA0' + '",' +
            '"InstallmentLine__c":""' +
            '}' +
            '],' +
            '"Source":"Lean"' +
            '}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/paymentReceipt';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPaymentReceiptWebService.doPost();
        Test.stopTest();
     }
}