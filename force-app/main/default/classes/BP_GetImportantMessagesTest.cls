@isTest
public class BP_GetImportantMessagesTest {
	
    @testSetup
    static void createData(){
        CommunicationTemplate__c commTemp = new CommunicationTemplate__c();
        commTemp.Status__c = 'Published';
        commTemp.Title__c = 'Test';
		commTemp.PlainTextBody__c = 'test';
        insert commTemp;
        Communication__c comm = new Communication__c();
        comm.Recipient__c = userInfo.getUserId();
		comm.CommunicationTemplate__c = commTemp.Id;
        insert comm;
    }

     @isTest
    static void testExecute(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getImportantMessagesInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('userId', UserInfo.getUserId());
       
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetImportantMessages.execute();
        Test.stopTest();
		
		RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 200);
    }
    
    
     @isTest 
    static void testExecuteInvalid2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getImportantMessagesInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetImportantMessages.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 500);
		
    }
}