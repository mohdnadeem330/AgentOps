trigger ContactTrigger on Contact (before insert,before update, after insert, after update) {
    try {
        ContactTriggerHandler objContact;
        objContact = new ContactTriggerHandler();
        objContact.run('Contact');
    } catch(Exception e) { LoggerService.save(LoggerService.addApexLog(e,'ContactTrigger','ContactTriggerHandler',''));throw e; } 
}