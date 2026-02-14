@isTest(SeeAllData=false)
public class CreateActivityWebServiceTest {
    @isTest static void setupMethod() {

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id); 

        //Contact conRecord = [select id, AgentID__c	 from contact where id =: contactRecord.Id];
        
        System.debug('contactRecord '+contactRecord);
        Task task = TestObjectsFactory.getAgentActivity(contactRecord.id);
        
        insert task;
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;

        Task newTask = new Task();
        newTask.Subject = 'Task Subject';
        newTask.whoId = leadRec.Id;
        newTask.ActivityDate = Date.today();
        newTask.Priority = 'Normal';
        newTask.Status = 'Open';
        newTask.AgentActivityHistory__c = true;
        
        Task task2 = TestObjectsFactory.getAgentActivity(contactRecord.id);
        task2.ActivityDate = date.today().addDays(-10);
        task2.TaskNumber__c = 0;
        task2.Status = 'Completed';        
        insert task2;
        
        task2.CustomerResponse__c = 'Customer Not Reachable';
        task2.TaskNumber__c = 1;

        TestObjectsFactory.initializeRestContext(null, '/upsert/activity');
        CreateActivityWebService.doPost(task);
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        CreateActivityWebService.doPost(newTask);
        
        CreateActivityWebService.doPost(task2);
        
        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(null, '/upsert/activitiesss');
        CreateActivityWebService.doPost(newTask);
        
        Test.stopTest();
    }
}