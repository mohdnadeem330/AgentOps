@isTest
public class BP_GetOpportunitiesTest {
    
	@testSetup
    static void createData(){
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test','1234');
		acc.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
		insert acc;
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
		opp.BrokerAgentContact__c = con.Id;
        opp.BrokerAgencyAccount__c = acc.Id;
        insert opp;
    }
	
    @isTest
    static void testExecute(){
		Opportunity opp = [SELECT Id,Name,SalesManager__r.Name,BrokerAgentName__c,MobileNumberFormula__c,CustomerEmailFormula__c,StageName,BrokerAgentContact__c,BrokerAgencyAccount__c,Project__c,ResidentStatus__c,OpportunityNumber__c FROM Opportunity];
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetOpportunitiesInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('contactId', opp.BrokerAgentContact__c);
        requestBody.put('accountId', opp.BrokerAgencyAccount__c);
		// requestBody.put('startDate', String.valueOf(System.today()));
       // requestBody.put('endDate', String.valueOf(System.today()));
		 requestBody.put('ProjectName', opp.Project__c);
        requestBody.put('ResidentStatus', opp.ResidentStatus__c);
         requestBody.put('OpportunityNumber', opp.OpportunityNumber__c);
        requestBody.put('OppName', opp.Name);
         requestBody.put('Status', opp.StageName);
        requestBody.put('Email', opp.CustomerEmailFormula__c);
        requestBody.put('Mobile', opp.MobileNumberFormula__c);
         requestBody.put('AgentName', opp.BrokerAgentName__c);
        requestBody.put('SalesManagerName', opp.SalesManager__r.Name);
        
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetOpportunities.execute();
        Test.stopTest();
		
		RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 200);
    }
	
    @isTest
    static void testExecuteInvalid3(){
		Opportunity opp = [SELECT Id,BrokerAgentContact__c,BrokerAgencyAccount__c FROM Opportunity];
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetOpportunitiesInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('brokerAgentId', opp.BrokerAgentContact__c);
        requestBody.put('brokerAgencyId', opp.BrokerAgencyAccount__c);
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
		req.params.put('timeUserContext',String.valueOf(System.today()));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetOpportunities.execute();
        Test.stopTest();
		
		RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 400);
    }
	 @isTest 
    static void testExecuteInvalid(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetOpportunitiesInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetOpportunities.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 400);
		
    }

	 @isTest 
    static void testExecuteInvalid2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetOpportunitiesInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetOpportunities.execute();
        Test.stopTest();

		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 500);
    }

}