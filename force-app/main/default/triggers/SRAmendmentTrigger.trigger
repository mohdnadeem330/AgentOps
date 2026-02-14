trigger SRAmendmentTrigger on AgencyTeam__c (before insert, before update) {
    try {
        SRAmendmentTriggerHandler obj= new SRAmendmentTriggerHandler();
        obj.run('AgencyTeam__c');
    } catch(Exception e) {LoggerService.save(LoggerService.addApexLog(e, 'SRAmendmentTrigger', 'SRAmendmentTriggerHandler', ''));throw e;
    } 
}