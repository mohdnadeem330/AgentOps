@isTest
public class CryptoTransactionResponseTest {
    
    @isTest
    public static void testCryptoTransactionResponse() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c = 'Aldar Academies';
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;       
        
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitrecord.Id;
        insert salesOrder;        
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receiptAcknowledgement.CryptoTransactionId__c = 'TEST123456';
        insert receiptAcknowledgement;
        
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/crypto/response';
        request.httpMethod = 'POST';       
        
        CryptoTransactionResponse.TransactionData transactionData = new CryptoTransactionResponse.TransactionData();
        transactionData.ID = '123';
        transactionData.Amount = '123';
        transactionData.Expiry = 'TEST_SRC';
        transactionData.InvoiceID = 'TEST_DEST';
        transactionData.created_at = 'TEST';
        transactionData.CallbackURL = '123.00';
        transactionData.CustomerName = '123.00';
        transactionData.TransactionID = '123.00';
        transactionData.BankReference = '0.006';
        transactionData.TradeReference = 'AED';
        transactionData.UnitVAIBANNumber = 'TEST';
        transactionData.SettlementCurrency = 'TEST123456';

        
        String transactionJson = JSON.serialize(transactionData);
        
        // Set the request body
        request.requestBody = Blob.valueOf(transactionJson);
        
        // Set the RestContext
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        try {
            CryptoTransactionResponse.doPost();
        }catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    
    @isTest
    public static void testCryptoTransactionResponseEx() {
        
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/crypto/response';
        request.httpMethod = 'POST';       
        
        CryptoTransactionResponse.TransactionData transactionData = new CryptoTransactionResponse.TransactionData();
        transactionData.TransactionID = 'TEST123456';
        
        String transactionJson = JSON.serialize(transactionData);
        
        // Set the request body
        request.requestBody = Blob.valueOf(transactionJson);
        
        // Set the RestContext
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        try {
            CryptoTransactionResponse.doPost();
        }catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

}