public without sharing class TaskTriggerHandler extends TriggerHandler {
    
    public static User userDetail = Utilities.getLoggedInUserDetail();
    Id screeningTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Screening_Task').getRecordTypeId();

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        
        Map<String, id> recordMap = CaseTriggerHandler.recordInformation();
        Id QueriesRecordTypeId = recordMap.get(Constants.Queries);
        Id ComplaintsRecordTypeId =  recordMap.get(Constants.Complaints);
        Id RequestsRecordTypeId =  recordMap.get(Constants.Requests);
        
        List<Task> taskList = (List<Task>) newList;
        List<id> Caseid = new list<id>(); 
        // Add users to public group to access the inventory
        TaskService.newTaskRecord(newList);
        
        for (Task ts :taskList ){
            //Case revamp to check log a call 
            if(caseLogaCallCheck(ts)){
                Caseid.add(ts.WhatId);
            }            
        } 
        if(!Caseid.isempty()){
            caseLogChanges(Caseid,QueriesRecordTypeId,ComplaintsRecordTypeId,RequestsRecordTypeId);            
        }
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        List<Task> taskList = (List<Task>) newList;
        Set<String> taskTypes = new Set<String>{Constants.Task_type_Internal, Constants.Task_type_External, Constants.Task_type_Follow_Up, Constants.Task_type_Resolver};
        Boolean isCaseTask = false; 
        List<Id> Caseupdate = new List<Id>(); 
        
        // For validateAndConvert
        Map<Id, Task> filteredNewMap = new Map<Id, Task>();
        Map<Id, Task> filteredOldMap = new Map<Id, Task>();
        
        for(Task taskObj : taskList){
            Task oldtask = (task)oldmap.get(taskObj.Id);
            
            // Filter out tasks with RecordTypeId Screening Task
            if (taskObj.RecordTypeId != screeningTaskRecordTypeId) {
                filteredNewMap.put(taskObj.Id, taskObj);
                if (oldtask != null) {
                    filteredOldMap.put(taskObj.Id, oldtask);
                }
            }
            
            isCaseTask= taskTypes.contains(taskObj.Type__c);
            if(taskTypeCheck(taskObj,oldtask)){
                Caseupdate.add(taskObj.whatid);
            }
        }
        //Case Revamp
        if (!Caseupdate.isEmpty()) {
            taskCompletedOperations(Caseupdate);
        } 
        if(!isCaseTask &&
            	!Constants.CONTACT_CENTER_AGENT.equals(userDetail.ProfileName__c) &&
            	!userDetail.ProfileName__c.startsWithIgnoreCase(Constants.CUSTOMER_MGMT_PROFILE)){
                    
                    if (!filteredNewMap.isEmpty()) {
                        TaskTriggerHandler.validateAndConvert(filteredNewMap, filteredOldMap);
                    }
            
            // TaskTriggerHandler.validateAndConvert(new map<id,Task>(taskList),new map<id,Task> ((list<Task>) oldList));
        }
        
        if(ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE.equalsIgnoreCase( String.valueOf(userDetail.ProfileName__c) )){
            ResaleService.processCaseFromTask((List<Task>)newList, oldMap);
        }
    }
    
   /*
    For checking if the task(Internal or external) is completed
    */
    public static Boolean taskTypeCheck(Task taskObj,Task oldtask){    
        return  taskObj.Status == Constants.TASK_COMPLETED && (taskObj.Type__c == Constants.Task_type_External || taskObj.Type__c == Constants.Task_type_Internal) && taskObj.Status != oldtask.Status;
    }
    /*
    For changing the case substatus when the task(Internal or external) is completed
    */
    Public static void taskCompletedOperations(List<Id> Caseupdate){
        List<Case> updateCases = [SELECT Status FROM Case WHERE Id IN :Caseupdate];
        for (Case cs : updateCases) {
            cs.Sub_Status__c = System.label.Case_Task_Completed_substatus;
        }
        update updateCases;
    }
    /*
    For checking if the task if a log a call task
    */
    public static Boolean caseLogaCallCheck(Task ts){    
        //return  ts.Subject == Constants.Call && ts.Status == Constants.TASK_COMPLETED && ts.Description != null && ts.WhatId != null && String.valueOf(ts.WhatId).startsWith('500');      
        return  ts.Description != null && (ts.Subject == 'Call - Follow up by customer' || ts.Type__c == 'Customer Follow up task') && ts.WhatId != null && String.valueOf(ts.WhatId).startsWith('500');     
    }
    /*
    For Performing the operations when the task is log a call task.
    Increasing the Customer_Follow_up_Count__c 
    Changing the Sub_Status__c to Follow up by Customer
    */
    public static void caseLogChanges(List<id> Caseid,Id QueriesRecordTypeId,Id ComplaintsRecordTypeId,Id RequestsRecordTypeId){
        
        List <case> cases = [Select id,Customer_Follow_up_Count__c,Last_activity__c,status,RecordTypeId from case where id in: Caseid];
        List <case> casesList = new List <case>();
        for(case cs :cases){
            if(cs.RecordTypeId ==QueriesRecordTypeId || cs.RecordTypeId ==ComplaintsRecordTypeId || cs.RecordTypeId ==RequestsRecordTypeId){
                case updateCase=new  case();
                updateCase.Id=cs.ID;
                updateCase.Customer_Follow_up_Count__c = (cs.Customer_Follow_up_Count__c != null) ? cs.Customer_Follow_up_Count__c + 1 : 1;
                updateCase.Last_activity__c = system.now();
                if(cs.status == Constants.CASE_NEW || cs.status == Constants.CASE_WORK_IN_PROGRESS ||cs.status == Constants.Escalated ||cs.status == Constants.Re_Opened){
                    updateCase.Sub_Status__c = System.label.Case_Log_a_call_status_update;
                }
                casesList.add(updateCase);
            }
            
        }
        if(!casesList.isEmpty()){
            update casesList;
        }
    }
    
    
    public static void validateAndConvert(map<id,Task> newTaskMap,map<id,Task> oldTaskMap){
        set<ID> leadIdsToCovert= new set<id>();
        set<String> leadEmails= new set<String>();
        List<Lead> leadIdToUpdate = new List<Lead>();
        map<id,RoundRobinAssignmentMatrix__c> userToAssignmentRecord = new map<id,RoundRobinAssignmentMatrix__c>();
        for(RoundRobinAssignmentMatrix__c tempAssignmentRecord : [select id,User__c from RoundRobinAssignmentMatrix__c WITH SECURITY_ENFORCED ]){
            userToAssignmentRecord.put(tempAssignmentRecord.User__c,tempAssignmentRecord);
        }
        for(Id tempTaskId : newTaskMap.keySet()){
            if(newTaskMap.get(tempTaskId).subject == constants.TASK_DAY1 && newTaskMap.get(tempTaskId).CustomerResponse__c != oldTaskMap.get(tempTaskId).CustomerResponse__c && newTaskMap.get(tempTaskId).WhoId.getsobjecttype() == Lead.sobjecttype && 
               userToAssignmentRecord.containsKey(newTaskMap.get(tempTaskId).OwnerId) ){
                   leadIdsToCovert.add(newTaskMap.get(tempTaskId).WhoId);
                   
                   if(newTaskMap.get(tempTaskId).CustomerResponse__c.equals(Constants.CUSTOMER_REACHED)){
                       Lead leadRec = new Lead();
                       leadRec.Id = newTaskMap.get(tempTaskId).WhoId;
                       leadRec.CustomerContactedBySM__c = true ;
                       leadIdToUpdate.add(leadRec);
                   }
               }
        }
        
        if(!leadIdToUpdate.isEmpty()){
            update leadIdToUpdate;
        }
        
        if(!leadIdsToCovert.isEmpty()){
            System.debug('leadIdsToCovert '+leadIdsToCovert);
            Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> dupeAccountMap = new Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>();
            Map<Id,Lead> leadMap = new Map<Id,Lead>(LeadService.getAllLeadByIds(leadIdsToCovert));
            for(Lead lead : leadMap.values()){
                if(String.isNotBlank(lead.Email) && lead.ExistingAccount__c == null && lead.SkipDuplicateApprovalStatus__c != 'Approved'){
                    leadEmails.add(lead.Email);
                }
            }
            if(!leadEmails.isEmpty()){
                dupeAccountMap = UtilitiesWithoutSharing.findDuplicateAccountsByEmail(leadEmails);
            }
            
            System.debug('dupeAccountMap '+dupeAccountMap);
            if(dupeAccountMap != null && !dupeAccountMap.values().isEmpty()){
                for(Id tempTaskId : newTaskMap.keySet()){
                    if(newTaskMap.get(tempTaskId).WhoId.getsobjecttype() == Lead.sobjecttype){
                        System.debug('Convert Lead Rec '+ leadMap.get(newTaskMap.get(tempTaskId).WhoId));
                        String email = leadMap.get(newTaskMap.get(tempTaskId).WhoId).Email != null ? leadMap.get(newTaskMap.get(tempTaskId).WhoId).Email : '';
                        String duplicateCheckApprovalStatus = leadMap.get(newTaskMap.get(tempTaskId).WhoId).SkipDuplicateApprovalStatus__c;
                        Id existingAccount = leadMap.get(newTaskMap.get(tempTaskId).WhoId).ExistingAccount__c;
                        if(existingAccount == null && dupeAccountMap.containsKey(email) && dupeAccountMap.get(email) != null && duplicateCheckApprovalStatus != 'Approved'){
                            newTaskMap.get(tempTaskId).addError(System.Label.DuplicateAccountErrorMessage);
                        }
                    }
                }
            }else{
                UtilitiesWithoutSharing.convertLeads(leadIdsToCovert);
            }            
        }
    }
}