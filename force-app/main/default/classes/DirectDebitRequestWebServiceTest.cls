@IsTest
private class DirectDebitRequestWebServiceTest {
    
    @testSetup
    static void setupTestData() {
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = new SalesOrder__c(
            Unit__c = unit.Id
        );
        insert salesOrder;
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.Id);
        ddr.CustomerIdType__c = 'Trade License Number';
        insert ddr;
    }
    
    @IsTest
    static void testCreateDirectDebitRequest() {
        SalesOrder__c so = [SELECT Id, Unit__c FROM SalesOrder__c LIMIT 1];
        
        Map<String, Object> inputData = new Map<String, Object>{
            'CustomerIdType' => 'UAE Emirates Identity Card',
            'CustomerBankAccountType' => 'Savings',
            'CustomerBankName' => 'Abu Dhabi Commercial Bank',
            'CustomerIDNumber' => '123456789',
            'CustomerAccountName' => 'Ravi Kumar',
            'CustomerIBANNumber' => 'AE12345678901234567890',
            'SalesOrderId' => so.Id
        };
        
        String requestBody = JSON.serialize(inputData);
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/LiveAldar/DirectDebitRequest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        DirectDebitRequestWebService.createDirectDebitRequest();
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPicklistValues() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/LiveAldar/DirectDebitRequest';
        req.httpMethod = 'GET';
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        DirectDebitRequestWebService.getPicklistValues();
        Test.stopTest();
    }
    
    // Negative POST test for invalid body
    @IsTest
    static void testCreateDirectDebitRequest_withInvalidBody() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/LiveAldar/DirectDebitRequest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"invalid": "data"}'); // missing mandatory fields
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        DirectDebitRequestWebService.createDirectDebitRequest();
        Test.stopTest();
    }
}