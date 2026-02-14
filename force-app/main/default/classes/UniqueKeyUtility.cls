/*
*Description : Class to have generic methods for Unique Keys
*/
public with sharing class UniqueKeyUtility {

    public static String getUniqueKeyWithAllFields(sObject newRecord, List<String> uniqueKeyAPIs){
        String uniqueKey = '' ;
             for(String key : uniqueKeyAPIs){                  
                    if(newRecord.get(key) != null){
                        uniqueKey = (uniqueKey=='') ? formatStringValue(String.valueOf(newRecord.get(key))) : uniqueKey+'_'+ formatStringValue(String.valueOf(newRecord.get(key))) ;                       
                    }                                              
                    else{ 
                        return null ;                 
                    }
            }
        return uniqueKey ; 
    }

    public static String getUniqueKey(sObject newRecord, List<String> uniqueKeyAPIs){
        String uniqueKey = '' ;
             for(String key : uniqueKeyAPIs){                  
                    if(newRecord.get(key) != null){
                        uniqueKey = (uniqueKey=='') ? formatStringValue(String.valueOf(newRecord.get(key))) : uniqueKey+'_'+ formatStringValue(String.valueOf(newRecord.get(key))) ;                       
                    }                                              
                    /*else{             In this case we will set the Lead Unique Key field as empty string.
                        uniqueKey = '';    
                        return uniqueKey ;                 
                    }*/
            }
        return uniqueKey ; 
    }

    public static Map<String,List<String>> getUniqueKeyMappings(){

        Map<String,List<String>> uniqueKeyMapping = new Map<String,List<String>>();
        for(UniqueKeyMapping__mdt uniqueKeys : [SELECT Id,DeveloperName,Values__c,Description__c FROM UniqueKeyMapping__mdt]){
            List<String> uniqueKeyAPIs = uniqueKeys.Values__c.split(';');
            uniqueKeyMapping.put(uniqueKeys.DeveloperName,uniqueKeyAPIs);
        }
        return uniqueKeyMapping ; 
    }


    public static String formatStringValue(String originalString){
            String formatedString = String.escapeSingleQuotes(originalString.trim().toLowerCase());
            return formatedString ; 
    }
}