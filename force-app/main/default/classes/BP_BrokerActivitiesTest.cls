@isTest
public class BP_BrokerActivitiesTest {
	@testSetup
    static void createData(){
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test','1234');
		insert acc;
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        Id recordTypeId = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'BrokerActivities__c' AND Name = 'Activity'].Id;
        BrokerActivities__c brokerActivityRecord = new BrokerActivities__c();
        brokerActivityRecord.StartDate__c = system.today();
        brokerActivityRecord.Name='Test';
        brokerActivityRecord.Description__c ='Test';
        brokerActivityRecord.Type__c = BrokerActivities__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        brokerActivityRecord.Status__c = BrokerActivities__c.Status__c.getDescribe().getPicklistValues()[0].getValue();
		brokerActivityRecord.StartDate__c = System.today();
		brokerActivityRecord.RecordTypeId = recordTypeId;
        insert brokerActivityRecord;

		ActivityMapping__c actMap = new ActivityMapping__c();
        actMap.Agency__c = acc.Id;
        actMap.Activity__c = brokerActivityRecord.Id;
        insert actMap;
    }
	
	@isTest
    static void testExecute(){
        Test.startTest();
        AccountContactRelation accRel = [SELECT Id,AccountId,ContactId FROM AccountContactRelation];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerActivities';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
		User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
			ContactId = accRel.ContactId
        );
        insert testUser;
        System.runAs(testUser){
            Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('userId', testUser.Id);
        requestBody.put('contactId', accRel.ContactId);
        requestBody.put('recordTypeNames', new List<String>{'Activity'});
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		
        BP_BrokerActivities.execute();
        
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 200);
            Test.stopTest();
        }
		
    }
	
	 @isTest 
    static void testExecuteInvalid(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerActivities';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_BrokerActivities.execute();
        Test.stopTest();
		
		RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 500);
    }
	
	@isTest 
    static void testExecuteInvalid2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerActivities';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_BrokerActivities.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		System.assertEquals(response.get('statusCode'), 500);
    }
}