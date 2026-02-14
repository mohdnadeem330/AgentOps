public with sharing class ProjectService {
    @AuraEnabled(cacheable=true)
    public static list<Project__c> getAllActiveProjects(){
        return [select id,Name,AccountNumberEscrow__c,AccountNumberCorporate__c from Project__c where IsActive__c =true  WITH SECURITY_ENFORCED order by Name ];
    }
    // @AuraEnabled(cacheable=true)
    // public static List<Project__c> getActiveProjects(){
    //    system.debug('inside active proj');
    //     return [select id,Name from Project__c where IsActive__c =true WITH SECURITY_ENFORCED ];
    // }

  
}