@isTest
public class TasareehSendEmailDuringBusinessHoursTest {
    @testSetup
    static void setup() {
        // Create Business Hours
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'Tasareeh Business Hours'];
    
        
        // Create test data
        WorkflowTask__c task1 = new WorkflowTask__c(
            Name = 'Task 1',
            Department__c = 'ALDARPD',
            IsCompleted__c = 'N',
            Actual_Due_Date__c = Date.today().addDays(-1),
           Update_Actual_Due_Date__c=false
        );
        
        WorkflowTask__c task2 = new WorkflowTask__c(
            Name = 'Task 2',
            Department__c = 'OS01',
            IsCompleted__c = 'N',
            Actual_Due_Date__c = Date.today().addDays(1),
            DueDate__c = Date.today().addDays(1),
            Update_Actual_Due_Date__c=false
        );
        
        insert new List<WorkflowTask__c> { task1, task2 };
    }
    
    @isTest
    static void testScheduledJob() {
        // Schedule the job
        Tasareeh_SendEmailDuringBusinessHours sched = new Tasareeh_SendEmailDuringBusinessHours();
        String cronExp = '0 0 0 * * ?';
        String jobId = System.schedule('Test SendEmailDuringBusinessHours', cronExp, sched);
        
        // Verify the job is scheduled
        CronTrigger ct = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('Test SendEmailDuringBusinessHours', ct.CronJobDetail.Name);
        
        // Abort the scheduled job
        System.abortJob(jobId);
    }
    
    @isTest
    static void testBatchJob() {
        Test.startTest();
        
        // Execute the batch
        Tasareeh_SendEmailDuringBusinessHours batch = new Tasareeh_SendEmailDuringBusinessHours();
        Database.executeBatch(batch, 10);
        
        Test.stopTest();
        
        // Verify the results

    }
}