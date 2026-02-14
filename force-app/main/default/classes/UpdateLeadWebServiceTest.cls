@isTest(SeeAllData=false)
public class UpdateLeadWebServiceTest {
    @isTest static void setupMethod() {
        
        User userRecord1 = TestObjectsFactory.getUserRecord('Sales Manager', 'userName');
        insert userRecord1;
    }
    
    static testmethod void testUpdateLeadWebService(){
        
        User userRecord1 = [SELECT Id FROM User Limit 1];
        Lead leadRecord = TestObjectsFactory.getLeadRecord(1, 'Person');
        leadRecord.LeadSource = '800-Aldar' ;
        leadRecord.EnquiryCategory__c = 'Kiosk' ;
        leadRecord.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRecord;
		Test.startTest();
        
        TestObjectsFactory.initializeRestContext(null, '/update/lead');
        UpdateLeadWebService.doPost(leadRecord);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        
        //insert leadTask;
        //insert opportunityTask;
        leadRecord.MediaSource__c = 'Test';
        //update leadRecord;
        
        //TestObjectsFactory.initializeRestContext(null, '/query/activity');
        
        TestObjectsFactory.initializeRestContext(null, '/update/leadss');
        UpdateLeadWebService.doPost(leadRecord);
        
         System.runAs(userRecord1) {
             TestObjectsFactory.initializeRestContext(null, '/update/lead');
             UpdateLeadWebService.doPost(leadRecord);
         }
        Test.stopTest();
        
    }
    static testmethod void testUpdateLeadWebService1(){
        
        User userRecord1 = [SELECT Id FROM User Limit 1];
        Lead leadRecord = TestObjectsFactory.getLeadRecord(1, 'Person');
        leadRecord.LeadSource = '800-Aldar' ;
        leadRecord.EnquiryCategory__c = 'Kiosk' ;
        leadRecord.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRecord;
		Test.startTest();
        
        TestObjectsFactory.initializeRestContext(null, '/update/lead');
        UpdateLeadWebService.doPost(leadRecord);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        
        //insert leadTask;
        //insert opportunityTask;
        leadRecord.MediaSource__c = 'Test';
        //update leadRecord;
        
        //TestObjectsFactory.initializeRestContext(null, '/query/activity');
        
        TestObjectsFactory.initializeRestContext(null, '/update/leadss');
        UpdateLeadWebService.doPost(null);
        
         System.runAs(userRecord1) {
             TestObjectsFactory.initializeRestContext(null, '/update/lead');
             UpdateLeadWebService.doPost(null);
         }
        Test.stopTest();
        
    }
}