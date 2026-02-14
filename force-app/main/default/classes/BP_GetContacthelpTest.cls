@isTest
public class BP_GetContacthelpTest {

    @testSetup static void setupData() {
        Account orgAcc = new account();
        orgAcc.Name='SODIC';
        orgAcc.BillingState='Dubai';
        orgAcc.BillingCountry='United Arab Emirates';
        
        insert orgAcc;
        
          Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        conRecord.Title = 'Sales Manager'; // ensure title is set for position mapping
        conRecord.Email = 'sodic_contact@example.com';
        conRecord.MobilePhone = '0123456789';
        conRecord.AgentStatus__c = 'Active';
        conRecord.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker Agent').getRecordTypeId();
        update conRecord;
        
      
        
             // Create a test User
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Resale Relationship Manager' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            Region__c = 'Abu Dhabi',
            
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            Team__c = 'DXB',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = userProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
           
        );
        insert testUser;
        system.debug('result3'+ testUser);
       
        
        ContentVersion contentVer = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('This is a test file.'),
            IsMajorVersion = true
        );
        insert contentVer;

        // Fetch the ContentDocument ID
        ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVer.Id) LIMIT 1];

        // Create ContentDocumentLink to associate it with the Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = conRecord.Id, // Linking to Document
            ContentDocumentId = contentDoc.Id,
            ShareType = 'V' // Viewer permission
        );
        insert cdl;
    }
@isTest
static void testExecute() {
    Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
    User usrObj = [SELECT Id, RoleName__c,Account.BillingCountry,Account.BillingState,Accountid, ProfileName__c FROM User WHERE IsActive = true  LIMIT 1];
    Account acc = [SELECT Name FROM Account WHERE Id = :con.AccountId LIMIT 1];

    RestRequest req = new RestRequest();
    req.requestUri = '/services/apexrest/GetContactHelpInformation';
    req.httpMethod = 'POST';
    req.addHeader('Content-Type', 'application/json');

    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('accountName', acc.Name); // Must match account inserted
    requestBody.put('recordTypeName', 'Broker Agent'); // Match the contact’s RT name
    requestBody.put('roleName', usrObj.RoleName__c);
    requestBody.put('profleName', usrObj.ProfileName__c);
    requestBody.put('limit', 1);
    requestBody.put('offset', 0);

    req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

    RestContext.request = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    BP_GetContacthelp.execute();
    Test.stopTest();

    RestResponse res = RestContext.response;
    String responseBody = res.responseBody.toString();
    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

    System.assertEquals(true, response.containsKey('statusCode'));
    System.assertEquals(200, (Integer) response.get('statusCode'));
}


	 @isTest 
    static void testExecuteInvalid(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetContactHelpInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetContacthelp.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		//System.assertEquals(response.get('statusCode'), 400);
		
    }
	 
    
	 @isTest 
    static void testExecuteInvalid2(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetContactHelpInformation';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
		Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('gghgh', 'gghgh');
        requestBody.put('gghgh', 'gghgh');
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
		Test.startTest();
        BP_GetContacthelp.execute();
        Test.stopTest();
		
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		
		//System.assertEquals(response.get('statusCode'), 500);
		
    }
    
}