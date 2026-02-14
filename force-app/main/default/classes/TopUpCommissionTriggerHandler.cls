/**********************************************************************************************************************
* Name               : TopUpCommissionTriggerHandler                                                        
* Description        : This class is used as Handle for Helper class
* Usage              : Validation before update/insert                                                          
* Created By         : ALDAR                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0          Syed Noormohamad     15 Feb 2025      Initial Draft       
******************************************************************************************************************/

public class TopUpCommissionTriggerHandler extends TriggerHandler {
     public static Boolean skipTopUpCommissionTrigger = false;      
     public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        TopUpCommissionTriggerHelper.validateDuplicatesTopUpCommBeforeInsert((List<TopUpCommission__c>)newList);
    }     
     public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        TopUpCommissionTriggerHelper.validateDuplicatesTopUpCommBeforeUpdate((List<TopUpCommission__c>)newList,(Map<Id, TopUpCommission__c>)oldMap);
    }
}