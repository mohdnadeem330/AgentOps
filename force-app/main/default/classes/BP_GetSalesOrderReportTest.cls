@isTest
public class BP_GetSalesOrderReportTest {
	@testSetup
    static void createData(){
        SalesOrder__c newSalesOrder = TestObjectsFactory.getSalesOrderData(false,'1234');
    }
    
    @isTest
    static void testExecute(){
		SalesOrder__c newSalesOrder = [SELECT Id,AccountName__c,AccountNumber__c,AgentName__c,AgentType__c,ProjectName__c,UnitAreaUOM__c,UnitNumber__c FROM SalesOrder__c];
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getSalesOrderReportInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('accountName', newSalesOrder.AccountName__c);
        requestBody.put('accountNumber', newSalesOrder.AccountNumber__c);
		requestBody.put('agentName', newSalesOrder.AgentName__c);
        requestBody.put('agentType', newSalesOrder.AgentType__c);
        requestBody.put('projectName', newSalesOrder.ProjectName__c);
        requestBody.put('unitNumber', newSalesOrder.UnitNumber__c);
        requestBody.put('unitAreaUOM', newSalesOrder.UnitAreaUOM__c);
        requestBody.put('startDate', String.valueOf(System.today()));
        requestBody.put('endDate', String.valueOf(System.today()));
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetSalesOrderReport.execute();
        Test.stopTest();
		
		RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 200);
    }
	
	 @isTest 
    static void testExecuteInvalid(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getSalesOrderReportInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('accountName', null);
        requestBody.put('accountNumber', null);
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetSalesOrderReport.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 400);
		
    }
	
     @isTest 
    static void testExecuteInvalid2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getSalesOrderReportInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('accountName', null);
        requestBody.put('accountNumber', null);
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetSalesOrderReport.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 500);
		
    }
}