public with sharing class EOIRangeService {

    @AuraEnabled(cacheable=false)
      public static List<EOIRange__c> getEOIRangeQuery(String query) {
      List<EOIRange__c> records = Database.query(query);
      return records;
    }

    public static void newEOIRangeRecord(List<EOIRange__c> newList){
      //---- Update the unique key
      List<String> uniqueKeyAPIs = Utilities.getUniqueKeyMapping(Constants.EOIRANGE_UNIQUE_KEYS).Values__c.split(';');

      for(EOIRange__c newEOIRange : newList){
         newEOIRange.UniqueKey__c = UniqueKeyUtility.getUniqueKey(newEOIRange,uniqueKeyAPIs);
      }
    }
}