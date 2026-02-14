@isTest
public class SearchBrokerLeadsTest {
    static Lead leadRec ;
    static Lead leadRec1;
    static void init(){
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        User us = TestObjectsFactory.getUserRecord('Sales Manager','SM1');
        User loginUser = [SELECT Id, ManagerId FROM User WHERE Id =: UserInfo.getUserId() ];
        System.runAs (loginUser) {
            insert us;
            loginUser.ManagerId = us.Id;
            update loginUser;
        }
        leadRec.Email = 'chiragraiyani2@gmail.com';
        leadRec.MobilePhone = '918980676862';
        leadRec.LeadSource = 'Broker Portal' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
        
    }
    static testmethod void testAllOpportunity(){
        
        init();
        Lead ld = [SELECT Id,Email,MobilePhone,LeadSource,IsConverted,LeadNumber__c from Lead WHERE CustomerType__c!='VIP' Limit 1];
        Test.startTest();
        String responseBody = '{"success":true}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        SearchBrokerLeads.getExistingOpportunity(ld.LeadNumber__c);
        SearchBrokerLeads.getLeadDetails(ld.LeadNumber__c);
        SearchBrokerLeads.SearchBrokerLeadFlow(ld.LeadNumber__c);
        SearchBrokerLeads.sentforApproval(ld.Id,'Test','Family/Relative');
        SearchBrokerLeads.checkduplicateEmail('chiragraiyani2@gmail.com','1234567890');
        Test.stopTest();
        
    }
    static testmethod void testAllOpportunity2(){
        
        init();
        Lead ld = [SELECT Id,Email,MobilePhone,LeadSource,IsConverted,LeadNumber__c from Lead WHERE CustomerType__c!='VIP' Limit 1];
        Test.startTest();
        String responseBody = '{"success":true}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        SearchBrokerLeads.sentforApproval(ld.Id,'Test','VIP Reason Lead');
        SearchBrokerLeads.addacocuntTeamMember(null,ld.Id,ld.LeadNumber__c);
        Test.stopTest();
        
    }
    static testmethod void testAllOpportunity3(){
        
        init();
        Lead ld = [SELECT Id,Email,MobilePhone,LeadSource,IsConverted,LeadNumber__c from Lead WHERE CustomerType__c!='VIP' Limit 1];
        Test.startTest();
        String responseBody = '{"success":true}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        SearchBrokerLeads.sentforApproval(ld.Id,'Test','Broker Reason Lead');
        SearchBrokerLeads.addacocuntTeamMember(null,ld.Id,ld.LeadNumber__c);
        Test.stopTest();
        
    }
    
    
}