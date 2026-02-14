trigger ServiceAppointmentTrigger on ServiceAppointment (before insert,before update,after insert,after update) {
    try {  
        new ServiceAppointmentTriggerHandler().run('ServiceAppointment'); } catch(Exception e) {   LoggerService.save(LoggerService.addApexLog(e,'ServiceAppointmentTrigger','ServiceAppointmentTriggerHandler',''));throw e;
    }
       
}