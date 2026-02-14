global class BatchToReadAndParseDirectDebitFile implements Database.Batchable<sObject>, Database.Stateful {
    
    Set<Id> file_Ids_ForLog   = new Set<Id>();
    Set<Id> ddResponseFileIdSet;
    
    public BatchToReadAndParseDirectDebitFile(Set<Id> ddResponseFileIdSet){
        this.ddResponseFileIdSet = ddResponseFileIdSet;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name,Status__c, Type__c,Bank__c,SkippedRecordValues__c  FROM DDResponseFiles__c WHERE Id in: ddResponseFileIdSet ORDER BY isAckNack__c DESC';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<DDResponseFiles__c> ddResponseList){
        system.debug('ddResponseList:::'+ddResponseList);
        List<DDResponseFiles__c> allDdResponseFiles = new List<DDResponseFiles__c>();
        for(DDResponseFiles__c ddResponseFiles: ddResponseList){
            system.debug('ddResponseFiles:::'+ddResponseFiles);
            try{
                allDdResponseFiles.add(ddResponseFiles);
            }catch(exception ex){
                system.debug('Exception '+ex);
                file_Ids_ForLog.add(ddResponseFiles.id);
            } 
        }
        if(!allDdResponseFiles.isEmpty()){
            DirectDebitReadAndParseFile.readContentVersionAndParse(allDdResponseFiles); 
        }
        system.debug('file_Ids_ForLog::'+file_Ids_ForLog);
        
    }
    global void finish(Database.BatchableContext BC){
        if(file_Ids_ForLog.size()>0 || test.isRunningTest()){
            try{
                String htmlEmailBody = Label.ReadParseErrorEmailBody + ' </br> ' ;
                htmlEmailBody += ' <b> ' + file_Ids_ForLog +' </b> ' ;
                String recipientString = Label.SysAdminEmailAddress;
                List<String> recipientList = recipientString.split(';');
                //recipientList.add('smanohar@aldar.com');
                Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'File Parsing Email Failure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            }catch(exception ex){
                system.debug(ex);
            }
        }
    }
}