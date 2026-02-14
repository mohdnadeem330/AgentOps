trigger UnitDesignTrigger on UnitDesign__c (after insert,after update, before insert, before update ) {
    
    try {    
        new UnitDesignTriggerHandler().run('UnitDesign__c');

    } catch(Exception e) {   
        LoggerService.save(LoggerService.addApexLog(e,'UnitDesignTrigger','UnitDesignTrigger',''));
        throw e;
    } 
}