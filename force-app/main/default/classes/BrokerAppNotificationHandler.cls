/*****************************************************************************************************************
* Name               : BrokerAppNotificationHandler                                                        
* Description        : Handler class for BrokerAppNotificationTrigger
* Created By         : Tharun    
* Created Date		 : 15 Jan 2024
******************************************************************************************************************/
public class BrokerAppNotificationHandler extends TriggerHandler {
	//*** After Insert Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        Set<Id> publishedBANIds = new Set<Id>();
        for(BrokerAppNotification__c banSingle : (List<BrokerAppNotification__c>)newList){
            BrokerAppNotification__c banOld = (BrokerAppNotification__c)oldMap.get(banSingle.Id);
            
            if (banOld.Status__c != banSingle.Status__c && banSingle.Status__c == 'Published' && banSingle.ShortMessage__c != null) {
                publishedBANIds.add(banSingle.Id); 
            }
        }
        if(!publishedBANIds.isEmpty()){
            Database.executeBatch(new BrokerAppBellNotificationBatch(publishedBANIds),200);
        }
    }
}