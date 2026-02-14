public class BuildingSectionMappingTriggerHandler extends TriggerHandler {
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        Map<Id, PaymentPlan__c> changedPPMap;
        List<String> changedBSMSet	= new List<String>();
        
        for(BuildingSectionMapping__c bsmRecord : (List<BuildingSectionMapping__c>)newList){
            changedBSMSet.add(bsmRecord.PaymentPlan__c);
        }
        
        if(!changedBSMSet.isEmpty()){
            changedPPMap = new Map<Id, PaymentPlan__c>([SELECT Id, Name, isActive__c, PaymentPlanDiscount__c, Description__c FROM PaymentPlan__c WHERE Id IN:changedBSMSet]);
            PaymentPlanTriggerHandler.processPPChangesForDamascus(changedPPMap, changedBSMSet);
        }
    }
    public override void afterDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
        Map<Id, PaymentPlan__c> changedPPMap;
        List<String> changedBSMSet	= new List<String>();
        
        for(BuildingSectionMapping__c bsmRecord : (List<BuildingSectionMapping__c>)oldList){
            changedBSMSet.add(bsmRecord.PaymentPlan__c);
        }
        
        if(!changedBSMSet.isEmpty()){
            changedPPMap = new Map<Id, PaymentPlan__c>([SELECT Id, Name, isActive__c, PaymentPlanDiscount__c, Description__c FROM PaymentPlan__c WHERE Id IN:changedBSMSet]);
            PaymentPlanTriggerHandler.processPPChangesForDamascus(changedPPMap, changedBSMSet);
        }
    }
}