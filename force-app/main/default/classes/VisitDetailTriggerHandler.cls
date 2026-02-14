/**********************************************************************************************************************
* Name               : VisitDetailTriggerHandler                                                        
* Description        : This class is to write all the trigger automations for the VisitDetail__c object
* Usage              : VisitDetailTrigger
* Created By         : PWC Digital Middle East                                                     
******************************************************************************************************************/

public with sharing class VisitDetailTriggerHandler extends TriggerHandler{
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
    	 set<ID> fileFound = new set<ID>();
         for(ContentDocumentLink cdl : [select id,LinkedEntityId from ContentDocumentLink where LinkedEntityId in :newMap.keyset()]){
            fileFound.add(cdl.LinkedEntityId);                 
         }
         for(VisitDetail__c tempRecord : (List<VisitDetail__c>)newList){     
            VisitDetail__c oldRecord = (VisitDetail__c)oldMap.get(tempRecord.Id);
         	map<id,VisitDetail__c> visitDataToValidate =new map<id,VisitDetail__c>();
            if(tempRecord.CompletionDate__c != oldRecord.CompletionDate__c && oldRecord.CompletionDate__c == null && !fileFound.contains(tempRecord.Id)){
                 tempRecord.addError('Please upload document before completing the visit');
            }
         }
    }
}