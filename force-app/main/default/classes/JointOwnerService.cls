public with sharing class JointOwnerService {
    public static List<JointOwner__c> queryAllFieldsWithExtraFields(List<Id> joIds) {
        Set<String> joFieldList = Schema.getGlobalDescribe().get('JointOwner__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(joFieldList);
        String fields = string.join(strList,',');

        String joIdsStr = String.join(joIds, '\',\'');
        String query = 'SELECT ' + fields + ' , CreatedBy.Email, Owner.Email, Account__r.ERPID__c, SalesOrder__r.ERPID__c FROM JointOwner__c WHERE Id IN (\'' + joIdsStr + '\')';
        System.debug('***JointOwner query***'+query);
        List<JointOwner__c> JointOwners = Database.Query(query);
        System.debug('***JointOwner Queried***'+JointOwners);
        return JointOwners;
    }
}