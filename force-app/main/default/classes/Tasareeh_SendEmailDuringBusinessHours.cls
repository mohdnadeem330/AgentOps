global class Tasareeh_SendEmailDuringBusinessHours implements Database.Batchable<sObject>, schedulable {
    global void execute(SchedulableContext sc){
        Database.executeBatch(new Tasareeh_SendEmailDuringBusinessHours(), 100);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        Datetime currentTime = Datetime.now();
       
        String wtList = TasareehIntegration_Util.TasareehEmailBatchQuery();
        return Database.getQueryLocator(wtList);
    }
    
    global void execute(Database.BatchableContext bc, List<WorkflowTask__c> scope){
        
        BusinessHours defaultBusinessHours = [SELECT Id FROM BusinessHours WHERE Name = 'Tasareeh Business Hours'];
        Date currentDate = System.Today();
        
        for (WorkflowTask__c wt : scope) {
            
            Date nextBusinessDate = calculateNextBusinessDate(defaultBusinessHours.Id, wt.Due_Date_for_Email_Alert__c);
            // System.debug('nextBusinessDate --'  +nextBusinessDate);
            
            if (nextBusinessDate == currentDate) {
                wt.Escalation_Email_Sent__c = true;
                wt.Escalated_On__c=currentDate;
            }
            Date previousBusinessDate = calculatePreviousBusinessDate(defaultBusinessHours.Id, wt.Due_Date_for_Email_Alert__c);
            //  System.debug('previousBusinessDate --'  +previousBusinessDate);
            
            if (previousBusinessDate == currentDate) {
                wt.Email_Alert_Sent__c = true;
                wt.Notification_Date__c=currentDate;
            }
        }
        database.update(scope);
    }
    
    global void finish(Database.BatchableContext bc){
      
        Map<String, WorkflowTask__c> uniqueNotifEmailTasks = new Map<String, WorkflowTask__c>();
        
        List<WorkflowTask__c> tasks=TasareehIntegration_Util.getReviewerNotificationTasks();
        for(WorkflowTask__c wf : tasks){
            if (!uniqueNotifEmailTasks.containsKey(wf.Reviewer_Email__c)) {
                uniqueNotifEmailTasks.put(wf.Reviewer_Email__c, wf);
            }
        }
            Map<String, Object> flowInputs = new Map<String, Object>();
            flowInputs.put('workflowTasks', uniqueNotifEmailTasks.values()); 
            Flow.Interview flow = Flow.Interview.createInterview('Tasareeh_NotificationEmail', flowInputs);
            flow.start();
 }
    
    // Calculate One day before Due Date
    private Date calculatePreviousBusinessDate(Id businessHoursId, Date dueDate) {
        Datetime dueDateTime = Datetime.newInstance(dueDate, Time.newInstance(0, 0, 0, 0));
        Datetime previousBusinessDateTime = BusinessHours.add(businessHoursId, dueDateTime, -1);
        System.debug('previousBusinessDateTime --'  +previousBusinessDateTime);
        return previousBusinessDateTime.date();
    }
    
    // Calculate One day After Due Date
    private Date calculateNextBusinessDate(Id businessHoursId, Date dueDate) {
        Datetime dueDateTime = Datetime.newInstance(dueDate, Time.newInstance(13, 0, 0, 0));
        Datetime nextBusinessDateTime = BusinessHours.add(businessHoursId,dueDateTime,86400000);
        
        System.debug('due date --'  +dueDateTime);
        return nextBusinessDateTime.date();
    } 
}