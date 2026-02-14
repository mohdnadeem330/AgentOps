public class TasareehNotificationReviews {
    public Id recId;
    public string empname;		
    public String escalated;	
    public List<WorkflowTask__c> tasks { get; set; }
    
    public void setrecId(Id recId) {
        this.recId = recId;
        
    }
    
    public void setempname(String empname) {
        if(recId==NULL){
            return;
        }
        this.empname = empname;
        
        TasareehNotificationReviews();
    }
    
    
    
    public void setescalated(String escalated) {
        this.escalated = escalated;
        
    }
    
    public void getrecId() {
        this.recId = recId;
    }
    
    public void getescalated() {
        this.escalated = escalated;
    }
    
    public void getempname() {
        this.empname = empname;
    }
    
    public List<WorkflowTask__c> TasareehNotificationReviews() {
        
        tasks = new List<WorkflowTask__c>();
        if (String.isNotBlank(empname) && escalated=='N') {
            List<WorkflowTask__c> results = [SELECT Name, Permit__r.Name,Employee_Name_Backend__c, Actual_Due_Date__c,Due_Date_for_Email_Alert__c, Comments__c
                     FROM WorkflowTask__c
                     WHERE Employee_Name_Backend__c = :empname AND Actual_Due_Date__c!=null
                     AND Notification_Date__c = TODAY];
             if (!results.isEmpty()) {
                tasks = results;
            }
        }else if(escalated=='Y'){
            List<WorkflowTask__c> results = [SELECT Name, Permit__r.Name, Actual_Due_Date__c,Due_Date_for_Email_Alert__c, Employee_Name_Backend__c,Comments__c
                     FROM WorkflowTask__c
                     WHERE Department__c in ('AldarPD', 'OS01','ALDAR - Tasareeh OS1') AND Actual_Due_Date__c!=null AND
                     Escalated_On__c = TODAY];
             if (!results.isEmpty()) {
                tasks = results;
            }
            
        }
        else {
            tasks = new List<WorkflowTask__c>();
        }
        return tasks;
    }
     public Boolean getHasTasks() {
        return tasks != null && !tasks.isEmpty();
    }
}