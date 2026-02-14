public with sharing class ShipmentRequestService {
    public static List<ShipmentRequest__c> queryAllFieldsWithExtraFields(List<Id> srIds) {
        Set<String> srFieldList = Schema.getGlobalDescribe().get('ShipmentRequest__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(srFieldList);
        String fields = string.join(strList,',');

        String srIdsStr = String.join(srIds, '\',\'');
        String query = 'SELECT ' + fields + ' FROM ShipmentRequest__c WHERE Id IN (\'' + srIdsStr + '\')';
        System.debug('***ShipmentRequest query***' + query);
        List<ShipmentRequest__c> ShipmentRequests = Database.Query(query);
        System.debug('***ShipmentRequest Queried***' + ShipmentRequests);
        return ShipmentRequests;
    }
}