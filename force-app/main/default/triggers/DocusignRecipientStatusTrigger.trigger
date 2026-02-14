trigger DocusignRecipientStatusTrigger on dfsle__RecipientStatus__c (after insert,after update) {
    
//    if(trigger.isAfter && trigger.isUpdate){
        try{
            new DocusignRecipientTriggerHelper().run('dfsle__RecipientStatus__c');
            //            DocusignRecipientTriggerHelper.updateSalesOrder((List<dfsle__RecipientStatus__c>) trigger.new, (Map<Id,dfsle__RecipientStatus__c>) trigger.oldMap );
            if(DocusignRecipientTriggerHelper.GET_EXCEPTION) {
                if(Test.isRunningTest())
                {
                    Integer x = 1/0; //Controller will reach here only when code is runninging test mode and will throw exception e.
                }
            }
        }catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'DocusignRecipientStatusTrigger','DocusignRecipientTriggerHelper',''));
            
        }
   //     try{
          //  new DocusignRecipientTriggerHelper().run('dfsle__RecipientStatus__c');
            
        /*} catch(Exception e) {   
            LoggerService.save(LoggerService.addApexLog(e,'DocusignRecipientStatusTrigger','DocusignRecipientTriggerHelper',''));
            throw e;
        } */
//    }
    
    
  
    
}