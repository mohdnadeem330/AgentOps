public with sharing class TaskService {

    public static void newTaskRecord(List<Task> newList){
        //Added by Harsh@Aldar 09/08/2023 -- Separate the Resale Opportunity since we are not updating stage after sending offer START
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, String> oppId_SaleTypeMap = new Map<Id, String>();

        for(Task newTask : newList){
            Id opportunityId= newTask.WhatId;
            String sObjName = opportunityId != null ? opportunityId.getSObjectType().getDescribe().getName() : '';
            if (sObjName == 'Opportunity') {
                oppIdSet.add(opportunityId);
            }
        }

        if(oppIdSet.size() > 0){
            for(Opportunity thisOpp: [SELECT Id, SaleType__c FROM Opportunity WHERE Id IN: oppIdSet]){
                oppId_SaleTypeMap.put(thisOpp.Id, (String)thisOpp.SaleType__c);
            }
        }

        //Added by Harsh@Aldar 09/08/2023 -- Separate the Resale Opportunity since we are not updating stage after sending offer END
        for(Task newTask : newList){
            Id opportunityId= newTask.WhatId;
            String sObjName = opportunityId != null ? opportunityId.getSObjectType().getDescribe().getName() : '';
            //separate the resale opp -- Harsh@Aldar 09/08/2023
            if (sObjName == 'Opportunity' && oppId_SaleTypeMap != null && oppId_SaleTypeMap.get(opportunityId) != '' && oppId_SaleTypeMap.get(opportunityId) != 'Resale') {
                OpportunityService.updateOpportunityStage(newTask.WhatId,newTask.Subject);
            }
        }
    }

    public static List<Task> fetchTaskForAPIByUser(String userId) {
        String customerReached = Constants.CUSTOMER_REACHED;
        String openStatus = Constants.TASK_OPEN;
        String completedStatus = Constants.TASK_COMPLETED;
        return [SELECT
                Id,
                Subject,
                OwnerId,
                Status,
                CustomerResponse__c,
                ActivityDate,
                ReminderDateTime,
                CreatedDate,
                LastModifiedDate
                FROM Task
                WHERE Status =: completedStatus
                AND TaskType__c =: Constants.TASK_TYPE_DAY1
                AND OwnerId =: userId AND CreatedDate = THIS_FISCAL_YEAR 
                ORDER BY CreatedDate DESC LIMIT 20000];
    }
    
    public static List<Task> fetchTasksByAccountId(String accountId) {        
         return [SELECT Id, OwnerId, Status FROM Task where whatId =: accountId];        
    }
    
    //--- Get all the tasks with status customer reached
    public static List<Task> getCustomerReachedTasks(Set<Id> recordIds){

        List<Task> taskList = [SELECT WhoId,OwnerId,Status FROM Task where whoId IN: recordIds AND CustomerResponse__c =: Constants.CUSTOMER_REACHED];

        return taskList ;
    }

    //--- Get all the tasks that have a CustomerResponse not equal null
    public static List<Task> getTasksHaveCustomerResponse(Set<Id> recordIds){

        List<Task> taskList = [SELECT WhoId,OwnerId,Status FROM Task where whoId IN: recordIds AND CustomerResponse__c != null];

        return taskList ;
    }

    public static List<Task> getTasksNumberOneRecords(Set<Id> recordIds){

        Datetime datetimePlus1Hour = datetime.now().addHours(1);
        Integer offset = UserInfo.getTimezone().getOffset(datetimePlus1Hour);
        Datetime local = datetimePlus1Hour.addSeconds(offset/1000);

        List<Task> taskList = [SELECT WhoId,OwnerId,Status FROM Task where Subject LIKE '%Day 1 - Task 1%' AND whoId IN: recordIds AND CustomerResponse__c = null AND ReminderDateTime > :datetimePlus1Hour];

        system.debug('Point: localDateTimePlus1Hour '+local);
        system.debug('Point: getTasksNumberOneRecords '+taskList);

        return taskList ;
    }
    
    //------To get the activities related to current user
    public static List<Task> getActivitiesForCurrentUser(Map<String, String> mapFieldApiFieldValues){
        
        List<String> andConditions = new List<String>();
        if (mapFieldApiFieldValues == null)
        mapFieldApiFieldValues = new Map<String, String>();
      mapFieldApiFieldValues.put('ownerid', UserInfo.getUserId());

      Utilities.objType = 'Task';
      String whereConditionFromMap = Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
      if (String.isNotBlank(whereConditionFromMap))
          andConditions.add(whereConditionFromMap);
      System.debug(whereConditionFromMap);
      String whereCondition = String.join(andConditions, ' AND ');

      System.debug('**Query**'+whereCondition);
      List<Task> taskList = fetchActivities(whereCondition);

        //List<Task> taskList = new List<Task>();
        return taskList;
    }

    //------To fetch the activities based on condition prepared in getActivitiesForCurrentUser method
    public static List<Task> fetchActivities(string whereCondition){
        List<Task> activityList = new List<Task>();
        try {
            String strQuery = 'select id,Subject,Who.Name,ActivityDate,CustomerResponse__c, What.Name, Status,Description,Priority,TaskType__c,LeadOpportunityNumber__c,IsCustomerResponseUpdateable__c From task where Status != null';
            if(whereCondition != null && string.isNotEmpty(whereCondition)){
                strQuery += ' and ('+whereCondition+')';
            }
            strQuery += ' limit 1000';	
            system.debug('--Activity Query--'+strQuery);
            activityList = Database.query(strQuery);

            return activityList;
            
        } catch (Exception e) {
            system.debug('*** Exception e***'+e.getMessage());
            throw e;
            
        }
    }

    //-----To fetch Status picklist values
    public static List<String> getStatusPicklistValues(){

        List<String> pickListValuesList= new List<String>();  
        Schema.DescribeFieldResult fieldResult = Task.Status.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}     
        System.debug('pickListValuesList '+pickListValuesList);
		return pickListValuesList;

    }

    //-----To fetch Priority picklist values
    public static List<String> getPicklistValues (){
        Schema.DescribeFieldResult fieldResult = Task.Priority.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> priorityList = new List<String>();
        
        for( Schema.PicklistEntry pickListVal : ple){
			priorityList.add(pickListVal.getLabel());
		}   
                      
        return priorityList;
               
    }
    
    public static Lead getLeadRecord(String leadId)
    {
        return [select id, IsConverted from Lead where id =: leadId];
    }


    //-----To fetch Customer Response picklist values
    public static List<String> getCustomerResponsePicklistValues(){

        List<String> pickListValuesList= new List<String>();  
        Schema.DescribeFieldResult fieldResult = Task.CustomerResponse__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}     
        System.debug('pickListValuesList '+pickListValuesList);
		return pickListValuesList;

    }
    
}