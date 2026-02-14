/*
* Purpose : To create activies related to agents
* Created by : Ajay Thakur
*/
@Restresource(urlMapping='/CreateActivity')
global class CreateAgentActivityWebservice {
    @httppost
    global static void doPostMethod(String agentId, String leadNumber, String eventName, String comments, String property, String createdBy) {
        RestContextHandler handler = new RestContextHandler(true);
        //-------Fetch againt contact details 
        List<Contact> conList = [SELECT id FROM Contact WHERE agentId__c =: agentId];
        try {  
            //-------check if agents details are found
            if(conList!=null && conList.size()>0){
                //-------for creating activity related to agent
                Contact contactRec = conList[0];
                Task tk = new Task();
                tk.Subject = eventName+' - '+leadNumber;
                tk.WhoId = contactRec.Id;
                tk.ActivityDate = date.today();
                tk.AgentActivityHistory__c = TRUE;
                tk.Description = comments;
                tk.Property__c = property;
                tk.AgentEmailId__c = createdBy;
                tk.EventName__c = eventName;
                tk.Status = 'Completed';
                insert tk;

                handler.response.success = true;
                handler.response.data = tk;
                handler.finalize();
            }
            else{
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_NOT_FOUND;
                handler.response.message = Constants.INVALID_AGENT_ID;
                handler.finalize();
            }            
        }
        catch (DMLException exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        Catch(Exception e)
        {
            System.debug('line no '+e.getLineNumber());
            System.debug('msg '+e.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }        
    }    
}