@isTest //add for coverage
public class LeadVerifyWebServiceTest {
    static Lead leadRec ;

    static void init(){
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupetestemail@test.com';
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
        
    }
    
    static testmethod void testVerifyLead(){

        init();
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'123223376');
        personAcc.PersonEmail = 'dupetestemail@test.com';
        insert personAcc;
        Id leadId = [SELECT Id from Lead Limit 1].Id;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Success","data":{"isPhoneValid":null,"isEmailValid":null,"hasDuplicates":null,"DuplicateAccounts":[{"SalesOrderCount":0,"Name":"Feb14 Test broker","CustomerType":"New Customer","CustomerSubType":null,"AccountNumber":"A00072961"}]}}';
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/verify/lead');
        LeadVerifyWebService.doPost(leadId);
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        LeadVerifyWebService.doPost(leadId);        
        Test.stopTest();
    }
    static testmethod void testVerifyLeadNDupes(){

        init();
        Id leadId = [SELECT Id from Lead Limit 1].Id;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Success","data":{"isPhoneValid":null,"isEmailValid":null,"hasDuplicates":null,"DuplicateAccounts":[{"SalesOrderCount":0,"Name":"Feb14 Test broker","CustomerType":"New Customer","CustomerSubType":null,"AccountNumber":"A00072961"}]}}';
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/verify/lead');
        LeadVerifyWebService.doPost(leadId);
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        LeadVerifyWebService.doPost(leadId);        
        Test.stopTest();
    }

}