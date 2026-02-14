trigger InstallmentLinesTrigger on InstallmentLines__c (before Insert,before update,after update) {
    try {if(!CalloutToMuleSoft.updateInstallmentSyncStatus){
        new InstallmentLinesTriggerHandler().run('InstallmentLines__c');}} catch(Exception e) {LoggerService.save(LoggerService.createApexLog(e,'InstallmentLinesTrigger','InstallmentLinesTrigger',''));throw e;
    }  
}