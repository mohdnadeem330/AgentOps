trigger SRDocTrigger on HexaBPM__SR_Doc__c (after insert, after update, before insert, before update) {    
    try {
        if(!DocuSignHelper.isSkipSrDocTrigger){
            new SRDocTriggerHandler().run('HexaBPM__SR_Doc__c');
        }
    } catch(Exception e) {LoggerService.save(LoggerService.createApexLog(e,'SRDocTrigger','SRDocTriggerHandler',''));}   
}