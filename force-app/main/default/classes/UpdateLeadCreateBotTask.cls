@RestResource (urlMapping = '/update/lead/create/task')
global with sharing class UpdateLeadCreateBotTask 
{
    @HttpPost
    global static void doPost(Task taskRecord, String leadRecordId) 
    {
        RestContextHandler handler = new RestContextHandler(true);
        try 
        {
            List<Task> taskCreatedList          = new List<Task>();
            Task task                           = new Task();
            Lead toBeUpdatedLead                = new Lead();
            
            if(String.isNotBlank(leadRecordId) && leadRecordId != null && leadRecordId != '')
            {
                List<Task> openAutodaillerTasks = [Select id, OwnerId, Subject, Status, ActivityDate, isClosed 
                                                   FROM Task 
                                                   WHERE whoId = :leadRecordId
                                                   AND Subject LIKE 'Autodailler Call%' 
                                                   ORDER BY Subject DESC];
                //If there are any existing Autodailler calls then create a new task with subject increment
                if(!openAutodaillerTasks.isEmpty()){
                    task.Subject                    = 'Autodailler Call - '+ (openAutodaillerTasks.size() + 1);
                }
                //No Autodailler tasks are created, then create a new Autodailler task
                else{
                    task.Subject                    = 'Autodailler Call - 1';
                }
                
                task.whoId                      = leadRecordId != Null ? leadRecordId : '';
                task.ActivityDate               = Date.today();
                task.Priority                   = 'Normal';
                task.Status                     = 'Completed';
                task.AgentActivityHistory__c    = true;
                task.CustomerResponse__c        = taskRecord.CustomerResponse__c;
                task.TaskNumber__c            = 6;
                taskCreatedList.add(task);
            }
            
            if(!taskCreatedList.isEmpty()){
                insert taskCreatedList;
                handler.response.message = 'Task Created/Updated Successfully';
                handler.response.success = true;
                handler.response.data    = taskCreatedList ;
                handler.finalize();
            }
            
        }
        catch (DMLException exc){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            //handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.response.message = ex.getStackTraceString() + ex.getMessage();
            handler.finalize(ex);
        }
    }
    
}