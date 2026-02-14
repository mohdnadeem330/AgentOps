trigger JointOwnerTrigger on JointOwner__c (before insert,before update,after insert,after update) {
    try {  
        system.debug('try jotrg'); 
        //Added by cloudzlab to exclude joint owner from ecss without looping//
        Boolean hasPermission = FeatureManagement.checkPermission('ECSS_Lead');
		if(!hasPermission)
        CalloutToMuleSoft.isFromTrigger = true; //INTEG_ISSUE_FIX_SS
        new JointOwnerTriggerHandler().run('JointOwner__c');
        CalloutToMuleSoft.isFromTrigger = false; //INTEG_ISSUE_FIX_SS
        //
                                                    
    } 
    catch(Exception e) { system.debug('excp'); LoggerService.save(LoggerService.addApexLog(e,'JointOwnerTrigger','JointOwnerTriggerHandler','')); throw e;
    } 
}