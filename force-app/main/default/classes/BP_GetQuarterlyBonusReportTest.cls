@isTest
public class BP_GetQuarterlyBonusReportTest {
	
    @testSetup
    static void createData(){
        QuarterlyBonusCommission__c qbc = new QuarterlyBonusCommission__c();
		qbc.Year__c = '2024';
        qbc.Quarter__c = 'Q1';
        insert qbc;
    }
	
    @isTest
    static void testExecute(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getQuarterlyBonusReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('year', '2024');
		requestBody.put('quarter','Q1');
		requestBody.put('limit','1' );
		requestBody.put('offset','1');

        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetQuarterlyBonusReport.execute();
        Test.stopTest();
        
		RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 200);
    }
    
     @isTest 
    static void testExecuteInvalid(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getQuarterlyBonusReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetQuarterlyBonusReport.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 400);
		
    }

     @isTest 
    static void testExecuteInvalid2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getQuarterlyBonusReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetQuarterlyBonusReport.execute();
        Test.stopTest();

		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 500);
    }
}