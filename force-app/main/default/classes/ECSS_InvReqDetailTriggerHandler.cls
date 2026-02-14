public class ECSS_InvReqDetailTriggerHandler {
    public static void isAfterUpdate(List<Inventory_Request_Details__c> oldList, List<Inventory_Request_Details__c>newList, Map<Id, Inventory_Request_Details__c>oldMap, Map<Id, Inventory_Request_Details__c> newMap) {
        ECSS_InvReqDetailTriggerHelper.requestTypeHandler(newList,oldMap);
        //InvReqDetailTriggerHelper.PriceChangeRequestApproval(newList, oldMap);
        //InvReqDetailTriggerHelper.handleUploadStatusChange(newList,oldMap);
    }
    
}