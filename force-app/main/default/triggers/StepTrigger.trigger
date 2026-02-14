trigger StepTrigger on HexaBPM__Step__c (before insert, before update, after insert, after update) {
    try {
        StepTriggerHandler newStepTriggerHandler = new StepTriggerHandler();
        newStepTriggerHandler.run('HexaBPM__Step__c');
    } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e, 'StepTrigger', 'StepTriggerHandler', '')); throw e; } 
}