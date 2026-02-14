public class ECSS_CustomAdvanceLookupCmpController {
    @AuraEnabled(cacheable=true)
    public static List<sObject> getLookupValues(String searchKeyWord, String objectAPIName, String whereCondition, String fieldNames, Integer customLimit, String SelectedUnit) {
        // Check if searchKeyWord is less than 3 characters
        if (String.isBlank(searchKeyWord) || searchKeyWord.length() < 3) {
            System.debug('Search keyword is too short. No query executed.');
            return new List<sObject>(); // Return an empty list
        }     
        String searchKey = '%' + searchKeyWord + '%';        
        List<sObject> returnList = new List<sObject>();
        System.debug('SelectedUnit:'+SelectedUnit);
        // Start forming the query
        String sQuery = 'SELECT Id,Name,Phone,PersonEmail,Email__c,TradeName__c ,RecordtypeId,PersonContactId,PersonMobilePhone,MobileNumber__c';
        
        // Add additional fields if fieldNames are provided and are not 'Name'
        if (String.isNotBlank(fieldNames) && !fieldNames.equalsIgnoreCase('Name')) {
            sQuery += ', ' + fieldNames;
        }
        String ecssDar = 'AlDar Estates';
         whereCondition = '(Phone LIKE:searchKey OR Name LIKE:searchKey OR PersonEmail LIKE:searchKey OR TradeName__c  LIKE:searchKey OR PersonMobilePhone LIKE:searchKey OR Email__c LIKE:searchKey OR MobileNumber__c LIKE:searchKey) AND ECSS_Aldar_Estate__c = true';
        List<String> accIds = new List<String>();
        if(SelectedUnit !='' && SelectedUnit != null){
            System.debug('Entered here:'+ SelectedUnit);
            List<Customer_Unit__c> cs = [SELECT Id,Account__c,Unit__c from Customer_Unit__c WHERE Unit__c =: SelectedUnit ];
            for(Customer_Unit__c currCS : cs){
                accIds.add(currCS.Account__c);
            }
            if(accIds.size()>0)
		    whereCondition = '(Phone LIKE:searchKey OR Name LIKE:searchKey OR PersonEmail LIKE:searchKey OR TradeName__c  LIKE:searchKey OR PersonMobilePhone LIKE:searchKey OR Email__c LIKE:searchKey OR MobileNumber__c LIKE:searchKey) AND ECSS_Aldar_Estate__c = true AND Id in: accIds';
            else{
                List<String> accIdval = new List<String>();
                  whereCondition = '(Phone LIKE:searchKey OR Name LIKE:searchKey OR PersonEmail LIKE:searchKey OR TradeName__c  LIKE:searchKey OR PersonMobilePhone LIKE:searchKey OR Email__c LIKE:searchKey OR MobileNumber__c LIKE:searchKey) AND ECSS_Aldar_Estate__c = true AND Id in: accIdval';
            }
                
        }
        // Build the query string based on whether a whereCondition is provided
        if (String.isNotBlank(whereCondition)) {
            sQuery += ' FROM ' + objectAPIName + ' WHERE ' + whereCondition + ' ORDER BY CreatedDate DESC';
        } else {
            sQuery += ' FROM ' + objectAPIName + ' WHERE ' + fieldNames + ' LIKE :searchKey ORDER BY CreatedDate DESC ';
        }
        
        sQuery += ' LIMIT 10000';
        // Output query for debugging
        System.debug('SOQL Query: ' + sQuery);
        
        // Execute the query
        List<sObject> lstOfRecords = Database.query(sQuery);
        returnList.addAll(lstOfRecords);
        
        // Output records for debugging
        System.debug('Records: ' + lstOfRecords);
        
        return returnList;
    }
      @AuraEnabled(cacheable=true)
    public static List<sObject> getLookupValuesContact(String searchKeyWord, String objectAPIName, String whereCondition, String fieldNames, Integer customLimit, String accountId) {
        List<AccountContactRelation> contactRelation = [SELECT Id,AccountId,ContactId FROM AccountContactRelation WHERE AccountId =: accountId];
        List<String> contactIdExclude = new List<String>();
        for(AccountContactRelation currContRel : contactRelation){
            contactIdExclude.add(currContRel.ContactId);
        }
        System.debug('contactIdExclude:'+contactIdExclude);
        // Check if searchKeyWord is less than 3 characters
        if (String.isBlank(searchKeyWord) || searchKeyWord.length() < 3) {
            System.debug('Search keyword is too short. No query executed.');
            return new List<sObject>(); // Return an empty list
        }     
        String searchKey = '%' + searchKeyWord + '%';        
        List<sObject> returnList = new List<sObject>();
        
        // Start forming the query
        String sQuery = 'SELECT Id,Name,MobilePhoneValue__c,Email';
        
        // Add additional fields if fieldNames are provided and are not 'Name'
        if (String.isNotBlank(fieldNames) && !fieldNames.equalsIgnoreCase('Name')) {
            sQuery += ', ' + fieldNames;
        }
        String ecssDar = 'AlDar Estates';
        whereCondition = '(MobilePhoneValue__c LIKE:searchKey OR Name LIKE:searchKey) AND Id NOT IN:contactIdExclude';
        // Build the query string based on whether a whereCondition is provided
        if (String.isNotBlank(whereCondition)) {
            sQuery += ' FROM ' + objectAPIName + ' WHERE ' + whereCondition + ' ORDER BY CreatedDate DESC';
        } else {
            sQuery += ' FROM ' + objectAPIName + ' WHERE ' + fieldNames + ' LIKE :searchKey  AND Id NOT IN:contactIdExclude ORDER BY CreatedDate DESC ';
        }
        
        sQuery += ' LIMIT 10000';
        // Output query for debugging
        System.debug('SOQL Query: ' + sQuery);
        
        // Execute the query
        List<sObject> lstOfRecords = Database.query(sQuery);
        returnList.addAll(lstOfRecords);
        
        // Output records for debugging
        System.debug('Records: ' + lstOfRecords);
        
        return returnList;
    }

    @AuraEnabled(cacheable=true)
    public static sObject getinitRecord(String recordId, String objectAPIName, String fieldNames) {
        
        String sQuery = 'SELECT Id,Name,Phone,PersonEmail,TradeName__c ,RecordtypeId,PersonContactId,PersonMobilePhone,Email__c,MobileNumber__c';
        
        if (String.isNotBlank(fieldNames)) {
            sQuery += ', ' + fieldNames;
        }
        
        sQuery += ' FROM ' + objectAPIName + ' WHERE Id = :recordId LIMIT 1';
        
        // Execute the query and return the result
        List<sObject> records = Database.query(sQuery);
        if (!records.isEmpty()) {
            System.debug(records[0]);
            return records[0];
        }
        
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<sObject> gerRecentlyCreatedRecords(String objectAPIName, String fieldNames, String whereCondition, Integer customLimit) {
        
        List<sObject> returnList = new List<sObject>();
        String sQuery = 'SELECT Id,Name,Phone,PersonEmail,TradeName__c ,RecordtypeId,PersonContactId,PersonMobilePhone,Email__c,MobileNumber__c';
        
        if (String.isNotBlank(fieldNames) && !fieldNames.equalsIgnoreCase('Name')) {
            sQuery += ', ' + fieldNames;
        }       
        
        
        if (String.isNotBlank(whereCondition)) {
            sQuery += ' FROM ' + objectAPIName + ' WHERE ' + whereCondition + ' ORDER BY CreatedDate DESC' ;
        } else {
            String ecssDar = 'AlDar Estates';
            String wherecond = 'ECSS_Aldar_Estate__c = true';
            sQuery += ' FROM ' + objectAPIName +' WHERE '+wherecond +' ORDER BY CreatedDate DESC';
        }
        sQuery += ' LIMIT 10000';
        // Output query for debugging
        System.debug('SOQL Query: ' + sQuery);
        
        // Execute the query and return results
        List<sObject> lstOfRecords = Database.query(sQuery);
        returnList.addAll(lstOfRecords);
        
        return returnList;
    }
}