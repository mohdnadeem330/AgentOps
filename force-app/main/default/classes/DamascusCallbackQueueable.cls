/********************************************************************************************************************
* Name               : DamascusCallbackQueueable                                                        
* Description        : Class to Sync unit details with Damascus 
* Usage              : Property Journey Live Aldar App 
* Created By         : Live Aldar Salesforce Team                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           tdevar@aldar.com     06/11/2025      Initial Draft       
**********************************************************************************************************************/

public class DamascusCallbackQueueable implements Queueable, Database.AllowsCallouts {
    
    public String requestBody;
    public String processName;
    public Boolean processResponse;
    public List<Id> recordIds;
    
    public DamascusCallbackQueueable(String requestBody,Boolean processResponse,String processName,List<Id> recordIds){
        this.requestBody = requestBody;
        this.processResponse = processResponse;
        this.processName = processName;
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext qc){
        CalloutToMuleSoft.calloutService(requestBody,processResponse,processName,recordIds);
    }
}