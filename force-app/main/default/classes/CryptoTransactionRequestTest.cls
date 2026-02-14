@isTest
public class CryptoTransactionRequestTest {
    
    private class MyMockResponseGenerator implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            
            HTTPResponse res = new HTTPResponse();
            
            res.setStatusCode(200);
            res.setBody('{"status":"success","data":{"Merchant":"Aldar Real estate","TransactionID":"Transaction-a0f3e413-1ca2-458b-851c-d40cf3c39c4f","Asset":"ETH","RequestedAmount":34.58311,"Address":"0x85b4A4A60bBB843d7db2027981bc28e97B7c659B","Expiry":2400,"Note":null,"MerchantUUID":"Pay-4741ed68-2129-40d1-a448-7c722a200889","Name":"Ethereum","Network":"ethereum","Protocol":"ERC20","Link":"https://sandbox.midchains.com/pay/api/v1/merchant/checkout_selector/Transaction-a0f3e413-1ca2-458b-851c-d40cf3c39c4f/"}}');
        	return res;
        }
    }

    @isTest
    public static void testCryptoTransaction() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c = 'Aldar Academies';
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;       

        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
                
        BankVirtualAccounts__c VA = new BankVirtualAccounts__c();
        VA.VirtualAccountNumber__c = 'AE1231231231313'; 
        VA.Virtual_Account_Type__c = 'Escrow';
        VA.Project__c = projectRecord.Id;
        insert VA;
                
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.VirtualAccountNumber__c = VA.ID;
        insert unitrecord;
              
       
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitrecord.Id;
        insert salesOrder;        
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MyMockResponseGenerator());
        CryptoTransactionRequest.postTransaction(receiptAcknowledgement.Id);     
        Test.stopTest();
    }
}