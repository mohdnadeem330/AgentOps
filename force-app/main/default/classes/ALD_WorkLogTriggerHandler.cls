/**
 * @description       : Work Log Trigger
 * @author            : Saravanan Sekar
 * @group             : GDS
 * @last modified on  : 01-01-2024
 * @last modified by  : Saravanan Sekar
**/

public without sharing class ALD_WorkLogTriggerHandler extends TriggerHandler {
    
    public static Boolean StopTrigger = FALSE;

    //*** Before Insert Action***//
    //
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
		//Map<Id, Map<String, Date>> prLogIdAssignedUserIdIdAndDate = new Map<Id, Map<String, Date>>(); // ParentLogId - AssignedUserId and ActualDate
        Map<Id, Map<Id, List<Date>>> caseIdAssignedUserId_Dates = new Map<Id, Map<Id, List<Date>>>();
        Map<Id, List<Date>> AssignedUserId_Dates = new Map<Id, List<Date>>();
        Set<Date> assignedDates = new Set<Date>();
        for(ALD_Work_Log__c wLog : (List<ALD_Work_Log__c>)newList) {
            if(wLog.Is_Auto_Entry__c) {
                //Single case can have only one open worklog. Hence duplicate is impossible and it shouldn't have duplicate
                AssignedUserId_Dates = caseIdAssignedUserId_Dates.get(wLog.Case__c)!=null ? caseIdAssignedUserId_Dates.get(wLog.Case__c) : new Map<Id, List<Date>>();//{wLog.Assigned_User__c => wLog.Assigned_Date_and_Time__c.date()};
                List<Date> Dates = AssignedUserId_Dates.get(wLog.Assigned_User__c)!=null ? AssignedUserId_Dates.get(wLog.Assigned_User__c) : new List<Date>();
                Dates.add(wLog.Assigned_Date__c);
                AssignedUserId_Dates.put(wLog.Assigned_User__c, Dates);
                assignedDates.add(wLog.Assigned_Date__c);
                caseIdAssignedUserId_Dates.put(wLog.Case__c, AssignedUserId_Dates);
            }
            
        }
        
        Map<String, String> existingParentLog = new Map<String, String>();
        for(ALD_Work_Log__c aWLog : [SELECT Id, Assigned_User__c,  Assigned_Date__c
                                     FROM ALD_Work_Log__c 
                                     WHERE Assigned_User__c IN:AssignedUserId_Dates.keySet() and Assigned_Date__c IN:assignedDates  and
                                     Parent_Work_Log__c=null]) 
        {
            existingParentLog.put(aWLog.Assigned_User__c+'_'+aWLog.Assigned_Date__c, aWLog.Id);
        }
        
        List<ALD_Work_Log__c> newPrWLogs = new List<ALD_Work_Log__c>();
        for(Id assigneeId : AssignedUserId_Dates.keySet()) {
            List<Date> Dates = AssignedUserId_Dates.get(assigneeId);
            
            for(Date dte : Dates) {
                if(!existingParentLog.containsKey(assigneeId+'_'+dte)) {
                    newPrWLogs.add(new ALD_Work_Log__c(Assigned_User__c=assigneeId, Assigned_Date__c=dte));
                }
            }
        }

        insert newPrWLogs;
        
        for(ALD_Work_Log__c prWLog : newPrWLogs) {
            existingParentLog.put(prWLog.Assigned_User__c+'_'+prWLog.Assigned_Date__c, prWLog.Id);
        }
        
        //Insert new parent logs and add all existing prlog into the same map.
        //Set the actual parent log below
        for(ALD_Work_Log__c wLog : (List<ALD_Work_Log__c>)newList) {
            if(wLog.Is_Auto_Entry__c) {
            	   wLog.Parent_Work_Log__c = existingParentLog.get(wLog.Assigned_User__c+'_'+wLog.Assigned_Date__c);
            }
        }
        
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        
    }
    
    //*** Before Delete Action***//
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap) { 
        List<ALD_Work_Log__c> allChildLogs = [SELECT Id FROM ALD_Work_Log__c WHERE Parent_Work_Log__c!=null and Parent_Work_Log__c IN:oldMap.keySet()];
        delete allChildLogs;
    }
    
    //beforeInsertMethod -> Before inserting a new child record, this methid will create new parent for that specifix day and update with the new parent.
    //	New child records are being inserted from ALD_WorkLogHelper.upsertWorkLog method (Key to search-InsertBetweenDayLogs)
    //beforeDeleteMethod -> While deletnig the parent day log record, then deleting all related child records as well.
    
}