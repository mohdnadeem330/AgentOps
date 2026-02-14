/**********************************************************************************************************************
* Name               : BuildingSectionTriggerHandler                                                        
* Description        : This class is to write all the trigger automations for the BuildingSection__c object
* Usage              : BuildingSectionTrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022     Initial Draft  
                                                        1. Populate the OriginalAnticipatedCompletionDate__c once the AnticipatedCompletionDate__c is changed
******************************************************************************************************************/

public with sharing class BuildingSectionTriggerHandler extends TriggerHandler{
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 

    }
    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        for(BuildingSection__c newRecord  : (list<BuildingSection__c >) newList){
            BuildingSection__c oldRecord = (BuildingSection__c)oldMap.get(newRecord.Id);
            //If installment date is changed
            if(newRecord.AnticipatedCompletionDate__c  != oldRecord.AnticipatedCompletionDate__c  && newRecord.AnticipatedCompletionDate__c !=null && oldRecord.OriginalAnticipatedCompletionDate__c  ==null){
                newRecord.OriginalAnticipatedCompletionDate__c  = oldRecord.AnticipatedCompletionDate__c ;
            }
        }
    }
}