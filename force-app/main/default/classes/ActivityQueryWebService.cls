/*
* Purpose : To query activities related to user
* Created by : Ajay Thakur
*/
@RestResource (urlMapping = '/query/activity')
global with sharing class ActivityQueryWebService {
    
    @HttpPost
    global static void doPost(){

        RestContextHandler handler = new RestContextHandler(false);
        Set<Id> leadID = new Set<Id>();
        Set<Id> opportunityID = new Set<Id>();
        
        try {
            ActivityDetailModel activityResponse = new ActivityDetailModel();
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();            
            List<Task> taskList = TaskService.getActivitiesForCurrentUser(mapFieldApiFieldValues);

            //activityResponse.taskList
            for(Task taskRecord : taskList)
            {
                if(taskRecord.WhoId != Null)
                {
                    if(taskRecord.WhoId.getSObjectType() == Lead.SObjectType )
                        leadID.add(taskRecord.WhoId);
                }
                if(taskRecord.WhatId != Null)
                {
                    if(taskRecord.WhatId.getSObjectType() == Opportunity.SObjectType)
                        opportunityID.add(taskRecord.WhatId);
                }
            }
            
            Map<id,String> leadIdNumberMap = LeadService.fetchLeadNumber(leadID);            
            Map<id,String> opportunityIdNumberMap = OpportunityService.fetchOpportunityNumber(opportunityID);
            
            List<Task> newTaskList = new     List<Task>();
            for (Task taskRecord : taskList) {
                if(leadIdNumberMap.containsKey(taskRecord.WhoId)){
                    taskRecord.LeadOpportunityNumber__c = leadIdNumberMap.get(taskRecord.WhoId) ;
                }
                if(opportunityIdNumberMap.containsKey(taskRecord.WhatId)){
                    taskRecord.LeadOpportunityNumber__c = opportunityIdNumberMap.get(taskRecord.WhatId) ;
                }
                
                newTaskList.add(taskRecord);
            }
            activityResponse.taskList = newTaskList;
            activityResponse.statusPicklistValues = TaskService.getStatusPicklistValues();
            activityResponse.priorityPicklistValues = TaskService.getPicklistValues();
            activityResponse.customerResponsePicklistValues = TaskService.getCustomerResponsePicklistValues(); 
            
            handler.response.success = true;
            handler.response.data = activityResponse;
            handler.finalize();
        }
        catch(Exception e)
        {
            System.debug('msg '+e.getMessage());
            System.debug('line no '+e.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }
    
    public class ActivityDetailModel{
        public List<Task> taskList                         {get;set;}   
        public List<String> customerResponsePicklistValues {get;set;}        
        public List<String> statusPicklistValues           {get;set;}
        public List<String> priorityPicklistValues         {get; set;}
        
        public ActivityDetailModel(){
            this.taskList = new List<Task>();
            this.customerResponsePicklistValues = new List<String>();
            this.statusPicklistValues = new List<String>();
            this.priorityPicklistValues = new List<String>();
        }
    }
    
}