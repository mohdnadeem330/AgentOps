public with sharing class BrokerRequestService {
    public static List<BrokerRequest__c> queryAllFieldsWithExtraFields(List<Id> brokerRequestIds) {
        Set<String> fieldList = Schema.getGlobalDescribe().get('BrokerRequest__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(fieldList);
        String fields = string.join(strList,',');
        
        String brokerRequestIdsStr = String.join(brokerRequestIds, '\',\'');
        String query = 'SELECT ' + fields + ' , AgencyName__r.Name, AgencyName__r.ERPID__c, CreatedBy.Name, CreatedBy.Contact.ERPID__c FROM BrokerRequest__c WHERE Id IN (\'' + brokerRequestIdsStr + '\')';
        System.debug('***Broker Request query***' + query);
        List<BrokerRequest__c> brokerRequests = Database.Query(query);
        System.debug('***Broker Request Queried***' + brokerRequests);
        return brokerRequests;
    }
}