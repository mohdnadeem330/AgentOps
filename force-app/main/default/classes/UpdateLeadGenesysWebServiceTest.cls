@isTest
public class UpdateLeadGenesysWebServiceTest 
{
    @isTest 
    static void setupMethod() 
    {
       
         // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Lead leadRecord = TestObjectsFactory.getLeadRecord(1, 'Person');
        insert leadRecord;
        Task taskRecord = new Task();
        
        
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/update/lead/status/qualify');
        String LeadRecordId = leadRecord.Id;
        System.debug('LeadRecordId----'+LeadRecordId);
        
        //For UpdateLeadQualifyWebService Apex Class
        UpdateLeadQualifyWebService.doPost(taskRecord, LeadRecordId , 'Abu Dhabi', 'Bulk', '1BHK', '3-3.9 Million', 'Investor', 'Yes', true);
        
        //For UpdateLeadQueueWebService Apex Class
        UpdateLeadQueueWebService.doPost(leadRecord,'Agent Queue' ,'Reason',true );
        
        //For UpdateLeadCreateBotTask Apex Class
        UpdateLeadCreateBotTask.doPost(taskRecord, LeadRecordId);
        
        //For LeadQueryForGenesysWebService Apex Class
        LeadQueryForGenesysWebService.doPost(LeadRecordId);
        
        RestContextHandler handler = new RestContextHandler(false);
        Test.stopTest();
        
    }
    
    @isTest
    static void ExceptionTestCase()
    {
         // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Lead leadRecord = TestObjectsFactory.getLeadRecord(1, 'Person');
        insert leadRecord;
        Task taskRecord = new Task();
        
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/update/lead/status/qualify');
        
        //For UpdateLeadQualifyWebService Apex Class
        UpdateLeadQualifyWebService.doPost(taskRecord,'', '' , 'Bulk', '1BHK', '', '', 'Yes', true);
        
        //For UpdateLeadQueueWebService Apex Class
        //	AlReeman2
        leadRecord.Project__c='AlReeman2';
        leadRecord.LeadSource='Online';
        update leadRecord;
        UpdateLeadQueueWebService.doPost(null,'Agent Queue' ,'Reason',true);
        UpdateLeadQueueWebService.doPost(leadRecord,'Auto Dialer Queue' ,'Reason',true);
        
        //For UpdateLeadCreateBotTask Apex Class
        UpdateLeadCreateBotTask.doPost(taskRecord, '09'+leadRecord.Id);
        
        //For LeadQueryForGenesysWebService Apex Class
        LeadQueryForGenesysWebService.doPost('09'+leadRecord.Id);
        
        RestContextHandler handler = new RestContextHandler(false);
        Test.stopTest();
    }
    
    @isTest
    static void DMLexceptionTestCase()
    {
         // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Lead leadRecord = TestObjectsFactory.getLeadRecord(1, 'Person');
        insert leadRecord;
        Task taskRecord = new Task();
        
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/update/lead/status/qualify');
        String LeadRecordId = leadRecord.Id;
        System.debug('LeadRecordId----'+LeadRecordId);
        UpdateLeadQualifyWebService.doPost(taskRecord, 'Abu Dhabi', LeadRecordId , 'Bulk', '1BHK', 'test', '', 'Yes', true);
        
        RestContextHandler handler = new RestContextHandler(false);
        Test.stopTest();
    }

}