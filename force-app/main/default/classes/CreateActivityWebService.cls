/*
* Purpose : For creating / updating activitis on Lead / Opportunity from mobile app
* Created by : Ajay Thakur
*/
@RestResource (urlMapping = '/upsert/activity')
global with sharing class CreateActivityWebService {
    
    @HttpPost
    global static void doPost(Task taskRecord) {
        RestContextHandler handler = new RestContextHandler(true);
        CreateActivityModel createActivityModel = new CreateActivityModel();
        
        try {
            System.debug(taskRecord.Id+' '+String.isNotBlank(taskRecord.Id));
            
            if (taskRecord.Id != Null && String.isNotBlank(taskRecord.Id)) {
                update taskRecord;
            }
            else {
                Task task = new Task(); 
                task = taskRecord;
                task.AgentActivityHistory__c = TRUE;
                insert task;
            }

            createActivityModel.taskRecordDetail = taskRecord;           

            if(taskRecord.WhoId != Null && String.isNotBlank(taskRecord.WhoId) && taskRecord.WhoId.getSObjectType() == Lead.SObjectType)
            {
                Lead leadRecord = TaskService.getLeadRecord(taskRecord.WhoId);
                createActivityModel.isConvertedToOpportuinity = leadRecord.IsConverted;
            }
                
            
            handler.response.success = true;
            handler.response.data = createActivityModel ;
            handler.finalize(); 
            
        } catch (DMLException exc) {
            System.debug('msg '+exc.getMessage());
            System.debug('line no '+exc.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        
        catch (Exception ex) {
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);                                    
        }
    }

    public class CreateActivityModel{
        Task taskRecordDetail;            
        Boolean isConvertedToOpportuinity;

    }
}