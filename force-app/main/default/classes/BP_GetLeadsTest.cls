@istest
public class BP_GetLeadsTest {
	
    @testSetup
    static void createData(){
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test','1234');
		insert acc;
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        Lead leadobj = TestObjectsFactory.getLeadRecord(1,'Person');
		leadobj.BrokerAgent__c = con.Id;
        leadobj.Date_of_Birth__c  = System.today().addMonths(-1234);
        insert leadobj;
    }
	
     @isTest
    static void testExecute(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetLeadsInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        Lead leadObj = [SELECT Id,Name,Project__c,Email,Nationality__c,MobilePhone,AgentName__c,BrokerAgent__c FROM Lead];
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('location',leadObj.Nationality__c);
        requestBody.put('project',leadObj.Project__c);
        requestBody.put('email', leadObj.Email);
        requestBody.put('mobile', leadObj.MobilePhone);
        requestBody.put('leadName', leadObj.Name);
        requestBody.put('agentName', leadObj.AgentName__c);
		requestBody.put('brokerAgentId',leadObj.BrokerAgent__c);
		requestBody.put('startDate', String.valueOf(System.today()));
		requestBody.put('endDate',String.valueOf(System.today()));

        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetLeads.execute();
        Test.stopTest();
        
		RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 400);
    }
	
     @isTest 
    static void testExecuteInvalid(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetLeadsInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetLeads.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 200);
		
    }

     @isTest 
    static void testExecuteInvalid2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetLeadsInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetLeads.execute();
        Test.stopTest();

		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 500);
    }
}