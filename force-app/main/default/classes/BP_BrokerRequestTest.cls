@istest
public class BP_BrokerRequestTest {
	@testSetup
    static void createData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord();
		insert acc;
		BrokerRequest__c brokObj = TestObjectsFactory.getMarketingReimbursementRecord(acc);
		insert brokObj;
    }
	
    @isTest
    static void testExecute(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerRequest';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		String accId = [SELECT Id FROM Account].Id;
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('accountId', 'accId');
        requestBody.put('type', 'Adv');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_BrokerRequest.execute();
        Test.stopTest();
        
		RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 200);
    }
    
    @isTest 
    static void testExecuteInvalid(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerRequest';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_BrokerRequest.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 400);
		
    }
	
     @isTest 
    static void testExecuteInvalid2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerRequest';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_BrokerRequest.execute();
        Test.stopTest();

		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 500);
    }
}