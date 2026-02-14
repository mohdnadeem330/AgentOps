global class BatchToEmiratesIdValidation implements Schedulable, Database.Batchable<sObject>,Database.AllowsCallouts {
    
    global BatchToEmiratesIdValidation(){
    }
    
    global void execute(SchedulableContext ctx) {
        
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        String BrokerRecordTypeId = Schema.SObjectType.COntact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
        String BrokerAgentStatus = 'Active';
        String nationalityVerified = '';
        String query = 'SELECT Birthdate,Name,NationalIdNumber__c,Nationality__c, UAENationalityVerified__c FROM Contact where  Birthdate != null and NationalIdNumber__c != null and Nationality__c != null AND RecordTypeId =: BrokerRecordTypeId AND AgentStatus__c =:BrokerAgentStatus AND UAENationalityVerified__c =:nationalityVerified ';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> contactList){
        List<Contact> contactListToUpdate = new List<Contact>();
        for(Contact con: contactList){
            contactListToUpdate.add(EmiratesIdValidationController.makeCallout(con));
        }
        if(!contactListToUpdate.isEmpty()){
            update contactListToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC){
        
    }
}