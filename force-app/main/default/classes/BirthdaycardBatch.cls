global class BirthdaycardBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date today = Date.today();
        Integer currentDay = today.day();
        Integer currentMonth = today.month();
        
        String query = 'SELECT Id,isNotificationSent__c FROM Account WHERE DAY_IN_MONTH(PersonBirthdate) =:currentDay AND CALENDAR_MONTH(PersonBirthdate) =:currentMonth';
       
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        try{
            AccountTriggerHandler.skipAccountTrigger = true;
            Account acc = scope[0];
            List<SalesOrder__c> soList = [SELECT id,Account__c FROM SalesOrder__c WHERE Account__c =:acc.Id AND Status__c NOT IN('Cancelled by User', 'Cancelled')];
            List<JointOwner__c> joList =[SELECT Id,Account__c FROM JointOwner__c WHERE Account__c =:acc.Id];
            if(soList.size() >0){
                acc.isNotificationSent__c = true;
        		update acc;
            }else if(joList.size() >0){ 
                acc.isNotificationSent__c = true;
                update acc;
            }
            
        
        	
        }catch(Exception ex){LoggerService.save(LoggerService.addApexLog(ex,'BirthdaycardBatch','BirthdaycardBatch'+scope[0].Id,''));}
        //System.debug(scope);
        
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    
     public void execute(SchedulableContext context) {
        Database.executeBatch(new BirthdaycardBatch(),1);
    }
}