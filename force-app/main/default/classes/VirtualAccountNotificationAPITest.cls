@isTest
private class VirtualAccountNotificationAPITest {
    
    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Org', AccountNumber = 'G123456');
        insert acc;

        Account acc2 = new Account(Name = 'Organization Account', AccountNumber = '123223376');
        insert acc2;

        Contact con = new Contact(FirstName = 'Anayak', LastName = 'Test', AccountId = acc.Id, Email = 'anayak@aldar.com');
        insert con;

        Opportunity opp = new Opportunity(Name = 'Opportunity 1', AccountId = acc.Id, CloseDate = Date.today(), StageName = 'Prospecting');
        insert opp;

        Project__c p = TestObjectsFactory.getProjectRecord('25083');
        insert p;

        Unit__c unit = TestObjectsFactory.unitDataSetup(p.Id);
        insert unit;

        SalesOrder__c salesOrder = new SalesOrder__c(Opportunity__c = opp.Id, Account__c = acc.Id, Unit__c = unit.Id, Status__c = 'Reservation In Progress');
        insert salesOrder;

        BankVirtualAccounts__c bankVirtualAccount = new BankVirtualAccounts__c(
            VirtualAccountNumber__c = '1200000000',
            SalesOrder__c = salesOrder.Id,
            Unit__c = unit.Id,
            Project__c = p.Id,
            Virtual_Account_Type__c = 'Aldar Corporate'
        );
        insert bankVirtualAccount;
    }
    
    @isTest
    static void testSuccessfulNotificationProcessing() {
        String requestBody = '{' +
            '"requestId": "07cf70d0-7a36-11ea-bb18-ac1c89250010",' +
            '"requesteDateTime": "20200409110460",' +
            '"serviceName": "notifyVATransactions",' +
            '"serviceCode": "SVC0124",' +
            '"custCode": "10000088",' +
            '"langCode": "EN",' +
            '"message": {' +
                '"vaIban": "AE760357412010000000009",' +
                '"virtualAccountID": "1200000000",' +
                '"realAccNo": "12786555456",' +
                '"transferType": "D",' +
                '"amount": "100.00",' +
                '"currency": "AED",' +
                '"pymntDtls": "Test Debit Transaction on VA",' +
                '"transactionRef": "121212331221212",' +
                '"customerRefNo": "testVV112",' +
                '"txnStatus": "S",' +
                '"txnStatusDesc": "Successfully posted in VAM"' +
            '}' +
        '}';
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/VirtualAccountNotification';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        VirtualAccountNotificationAPI.processNotification();
        Test.stopTest();
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
    }
    
    @isTest
    static void testMissingMandatoryFields() {
        String requestBody = '{' +
            '"requestId": "07cf70d0-7a36-11ea-bb18-ac1c89250010",' +
            '"serviceName": "notifyVATransactions",' +
            '"message": {' +
                '"virtualAccountID": "1200000000",' +
                '"amount": "100.00"' +
            '}' +
        '}';
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/VirtualAccountNotification';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        VirtualAccountNotificationAPI.processNotification();
        Test.stopTest();
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
    }
    
    @isTest
    static void testInvalidDateTimeFormat() {
        String requestBody = '{' +
            '"requestId": "07cf70d0-7a36-11ea-bb18-ac1c89250010",' +
            '"requesteDateTime": "2020-04-09",' + // Invalid format
            '"serviceName": "notifyVATransactions",' +
            '"serviceCode": "SVC0124",' +
            '"custCode": "10000088",' +
            '"langCode": "EN",' +
            '"message": {' +
                '"vaIban": "AE760357412010000000009",' +
                '"virtualAccountNo": "1200000000",' +
                '"realAccNo": "12786555456",' +
                '"transferType": "D",' +
                '"amount": "100.00",' +
                '"currency": "AED",' +
                '"pymntDtls": "Test Transaction",' +
                '"transactionRef": "121212331221212",' +
                '"customerRefNo": "testVV112",' +
                '"txnStatus": "S",' +
                '"txnStatusDesc": "Success"' +
            '}' +
        '}';
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/VirtualAccountNotification';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        VirtualAccountNotificationAPI.processNotification();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
    }
}