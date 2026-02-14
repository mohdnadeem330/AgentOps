/*****************************************************************************************************************
* Name               : BrokerAppNotificationHandlerTest                                                        
* Description        : Test class for BrokerAppNotificationHandler,BrokerAppNotificationTrigger
* Created By         : Tharun    
* Created Date		 : 20 Jan 2024
******************************************************************************************************************/
@IsTest
public class BrokerAppNotificationHandlerTest {
	//Creating setup data
    @TestSetup 
    static void setupData() 
    {
        BrokerAppNotification__c banRecord1 = new BrokerAppNotification__c();
        banRecord1.Title__c					= 'TestTitle';
        banRecord1.ShortMessage__c			= 'Welcome Brokers';
        banRecord1.Status__c				= 'Draft';
        insert banRecord1;
        
        Account accountRecord = TestObjectsFactory.getAgencyAccountRecord('TharunAgency', 'ATTIM52');
        accountRecord.AgencyStatus__c = 'Active';
        insert accountRecord;

        Contact con = new Contact();
        con.Lastname='Alice';
        con.AccountId = accountRecord.Id;
        con.Email = 'test13@aldar.com';  
        con.phone = '527583669';  
        con.MobilePhone = '527583669';
        con.AgentStatus__c = 'Active';
        insert con;
        
        User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE_LOGIN, 'agencyAdmin');
        agencyAdmin.ContactId = con.Id;
        agencyAdmin.Email = 'test13@aldar.com';
        insert agencyAdmin;
    }
    
    @isTest
    static void testSendCommunication()
    {
        Test.StartTest();
        BrokerAppNotification__c bRecord = [SELECT Id, Status__c FROM BrokerAppNotification__c LIMIT 1];
        bRecord.Status__c = 'Published';
        update bRecord;
        Test.StopTest();
    }
        
        
}