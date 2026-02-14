public class PermitTriggerHandler {
    
     public static void handleAfterInsert(Map<Id, Sobject> newMap) {
         Set<Id> parentIds = newMap.keySet();
         String parentObj='Permit__c';
         String labelValue = Label.PermitTriggerLabel;
 		 Set<String> childObj = new Set<String>(labelValue.split(','));
		 System.debug('Custom Label Values: ' + childObj);
        // set<String>childObj=new set<String>{'Professional__c','WorkflowTask__c','WorkflowHistory__c','StatusHistory__c'};   
         TasareehUpdateParentIdInChild batch= new TasareehUpdateParentIdInChild(parentIds,parentObj,childObj);
         Database.executeBatch(batch, 10);

}
}