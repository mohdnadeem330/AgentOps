@isTest
public class VipExceptionRequestTest {
    
    static void init(){
        Lead leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupetestemail@test.com';
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        

        
    }
    
    static testmethod void testEmailExceptionWithLeadId(){

        init();
        Lead ld = [SELECT Id,LeadNumber__c,Approval_Status__c,VIPApproval__c from Lead Limit 1];
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Submitted for Approvals.","data":null}';
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/email/vipexception');
        VipExceptionRequest.doPost(ld.LeadNumber__c, '','Broker Reason Lead', 'Test Comments');
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        VipExceptionRequest.doPost(ld.LeadNumber__c, '','Broker Reason Lead', 'Test Comments');        
        Test.stopTest();
    }
    static testmethod void testEmailExceptionWithLeadNumber(){

        init();
        Lead lead = [SELECT Id,LeadNumber__c,Approval_Status__c,VIPApproval__c from Lead Limit 1];
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Submitted for Approvals.","data":null}';
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/email/exception');
        VipExceptionRequest.doPost(lead.LeadNumber__c, '','VIP Reason Lead', 'Test Comments');
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        VipExceptionRequest.doPost(lead.LeadNumber__c, '','VIP Reason Lead', 'Test Comments');        
        Test.stopTest();
    }
    static testmethod void testEmailExceptionWithAccount(){

        init();
        //Account acc = [SELECT Id from Account Limit 1];
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Submitted for Approvals.","data":null}';
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/email/exception');
        VipExceptionRequest.doPost('', '','Junk Email', 'Test Comments');
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        VipExceptionRequest.doPost('', '','Junk Email', 'Test Comments');        
        Test.stopTest();
    }
    static testmethod void testEmailExceptionWithOppId(){

        init();
        Opportunity opp = [SELECT Id,Name,VIPApproval__c from Opportunity Limit 1];
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Submitted for Approvals.","data":null}';
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
		TestObjectsFactory.initializeRestContext(null, '/email/vipexception');
        VipExceptionRequest.doPost(opp.Id, '','opp Reason Lead', 'Test Comments');
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        VipExceptionRequest.doPost(opp.Id, '','Opp Reason Lead', 'Test Comments');        
        Test.stopTest();
    }

}