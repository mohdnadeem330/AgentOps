@isTest
public class DuplicateAccountExceptionRequestTest {
    
    static void init(){
        Lead leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupetestemail@test.com';
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
        
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'123223376');
        personAcc.PersonEmail = 'dupetestemail@test.com';
        insert personAcc;
        
    }
    
    static testmethod void testEmailExceptionWithLeadId(){

        init();
         DuplicateAccountExceptionRequest.dummy();
        Id leadId = [SELECT Id from Lead Limit 1].Id;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Submitted for Approvals.","data":null}';
		Test.startTest();
       
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/email/exception');
        DuplicateAccountExceptionRequest.doPost(leadId, '','Family/Relative', 'Test Comments');
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        DuplicateAccountExceptionRequest.doPost(leadId, '','Family/Relative', 'Test Comments');        
        Test.stopTest();
    }
    static testmethod void testEmailExceptionWithLeadNumber(){

        init();
        Lead lead = [SELECT Id,LeadNumber__c from Lead Limit 1];
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Submitted for Approvals.","data":null}';
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/email/exception');
        DuplicateAccountExceptionRequest.doPost('', lead.LeadNumber__c,'Family/Relative', 'Test Comments');
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        DuplicateAccountExceptionRequest.doPost('', lead.LeadNumber__c,'Family/Relative', 'Test Comments');        
        Test.stopTest();
    }
    static testmethod void testEmailExceptionWithAccount(){

        init();
        Account acc = [SELECT Id from Account Limit 1];
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Submitted for Approvals.","data":null}';
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/email/exception');
        DuplicateAccountExceptionRequest.doPost(acc.Id, '','Family/Relative', 'Test Comments');
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        DuplicateAccountExceptionRequest.doPost(acc.Id, '','Family/Relative', 'Test Comments');        
        Test.stopTest();
    }

}