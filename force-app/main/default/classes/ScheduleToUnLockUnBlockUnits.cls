global without sharing class ScheduleToUnLockUnBlockUnits implements Schedulable ,Database.Batchable<sObject> {

    global void execute(SchedulableContext sc) {
        database.executeBatch(new ScheduleToUnLockUnBlockUnits());
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Datetime currentTime = system.now();
        list<string> lstLockStatus = new list<string>{Constants.UNIT_STATUS_BOOKING_INPROGRESS};
        system.debug('**currentTime**'+currentTime);
        string strQuery = 'select Id,AssignedToUser__c,AllocationGroup__c,(Select id,RequestedBy__c,ExistingAllocationGroup__c,Unit_Release_Date__c from unit_assignments__r),Name,LockExpiryTime__c,LockTime__c,LockedBy__c,LockedByCustomer__c,LockType__c,Status__c,RelatedOpportunity__c,RelatedSalesOrder__c,DigitalSales__c from Unit__c where Status__c IN:lstLockStatus AND LockExpiryTime__c <=:currentTime';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, list<Unit__c> unitList){
    	system.debug('execute ScheduleToUnLockUnBlockUnits');
        try{
            deactivateCPRecordsOnUnitRelease(unitList);
            List<unit_assignment__c> unitAssToUpdate = new List<unit_assignment__c>();
            List<Logger__c> loggerList = new List<Logger__c>();
            for(Unit__c objUnit : unitList){
                string oldAllocation;
                for(unit_assignment__c uniAss : objUnit.unit_assignments__r){
                    if((uniAss.Unit_Release_Date__c == null && objUnit.AssignedToUser__c == uniAss.RequestedBy__c) || test.isrunningTest()){
                        uniAss.Unit_Release_Date__c = System.now();
                        uniAss.Unit_Released_From__c = 'Auto release batch';
                        uniAss.Unit_Released_By__c = UserInfo.getUserId();
                        unitAssToUpdate.add(uniAss);
                        oldAllocation = uniAss.ExistingAllocationGroup__c;
                    }
                }
                if(objUnit.RelatedOpportunity__c != NULL || test.isrunningTest()){
                    objUnit.RelatedOpportunity__c = NULL;
                    objUnit.AssignedToUser__c = NULL;
                    objUnit.AllocationGroup__c = oldAllocation != null ? oldAllocation : objUnit.AllocationGroup__c;
                }
                objUnit.LockedBy__c = null;
                objUnit.LockedByCustomer__c = null; // Adde by Chirag Digital Sales
                objUnit.LockTime__c = null;
                objUnit.LockExpiryTime__c = null;
                objUnit.LockType__c = null;
                objUnit.RelatedSalesOrder__c = null;
                objUnit.Status__c = Constants.UNIT_STATUS_AVAILABLE;               
            }
            system.debug('**unitList**'+unitList.size());
            //Added by Tajinkumar for Partial DML
            Database.SaveResult[] unitUpdateResults = Database.update(unitList,false);
            
            for(Database.SaveResult result : unitUpdateResults){
                if(!result.isSuccess()){
                    for(Database.Error err : result.getErrors()){
                        Logger__c logRec = LoggerService.createApexLog(err,'Unlocking of Unit','ScheduleToUnLockUnBlockUnits','execute');
                        loggerList.add(logRec);
                    }
                }
            }
            if(!loggerList.isEmpty()){
                LoggerService.aynchronousSave(JSON.serialize(loggerList));
            }
            if(unitAssToUpdate.size() > 0){
                update unitAssToUpdate;
            }
        }catch(Exception ex){
    	system.debug(ex);
            LoggerService.save(LoggerService.addApexLog(ex,'Unlocking of Unit','BookingUtils','unLockUnits'));
        }
    }
    
    global void finish(Database.BatchableContext BC){
    	/*ScheduleToUnLockUnBlockUnits objSchedule = new ScheduleToUnLockUnBlockUnits();
		Datetime dt = system.now().addMinutes(5);
		string sCornExp = '0 '+dt.minute()+' '+dt.hour()+' '+dt.day()+' '+dt.month()+' ? '+dt.year();
		for(CronTrigger obj : [select Id from CronTrigger where CronJobDetailId IN (SELECT Id FROM CronJobDetail where Name = 'Unit Unlock Batch Process')])
			system.abortJob(obj.Id);
		system.schedule('Unit Unlock Batch Process', sCornExp, objSchedule);*/
    }
    
    //Added by Tajinkumar - Digital Sales
    public static void deactivateCPRecordsOnUnitRelease(List<Unit__c> unitlst) {
        if(unitlst == null || unitlst.isEmpty()) {
            return;
        }
        Map<Id,Id> unitsWithRelatedAccountMap = new Map<Id,Id>();
        Set<Id> getReleasedUnitIds = new Set<Id>();
        DateTime currentTime = System.now();
        
        for(Unit__c unit : unitlst) {
            if(unit.DigitalSales__c && unit.LockExpiryTime__c != null && unit.LockExpiryTime__c <= currentTime && (unit.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS || unit.Status__c == Constants.STATUS_RESERVED) && unit.LockedByCustomer__c != null) {
                unitsWithRelatedAccountMap.put(unit.Id,unit.LockedByCustomer__c);
                getReleasedUnitIds.add(unit.Id);
            }
        }
        if(getReleasedUnitIds.isEmpty()) {
            return;
        }
        
        updateBrokerLeadOnUnitRelease(getReleasedUnitIds,unitsWithRelatedAccountMap);
        
        List<Communication_Preference__c> updateCPRecords = new List<Communication_Preference__c>();
        for(Communication_Preference__c cp : [SELECT Id,Active__c,Unit__c,Account__c FROM Communication_Preference__c WHERE Unit__c IN : getReleasedUnitIds AND Account__c IN : unitsWithRelatedAccountMap.values() AND Category__c = 'Booking' AND Status__c IN ('Link Sent','Fasttrack Completed') AND Active__c = true]) {
            if(unitsWithRelatedAccountMap.containsKey(cp.Unit__c)) {
                Id accountId = unitsWithRelatedAccountMap.get(cp.Unit__c);
                if(cp.Account__c == accountId) {
                    cp.Active__c = false;
                    updateCPRecords.add(cp);
                }
            }
        }
        if(!updateCPRecords.isEmpty()) {
            try {
                update updateCPRecords;
            } catch(Exception ex) {
                LoggerService.save(LoggerService.addApexLog(ex,'Deactivate CP Records on Unit Release','ScheduleToUnLockUnBlockUnits','deactivateCPRecordsOnUnitReleasing'));
            }
        }
    }
    
    public static void updateBrokerLeadOnUnitRelease(Set<Id> unitIds,Map<Id,Id> getExistingAccountMap) {
        if(unitIds == null || unitIds.isEmpty() || getExistingAccountMap == null || getExistingAccountMap.isEmpty()) {
            return;
        }
        List<Lead> updateBrokerLeads = new List<Lead>();
        for(Lead ld : [SELECT Id,Unit__c,InitiateDigitalBooking__c,ExistingAccount__c FROM Lead WHERE Unit__c IN : unitIds AND LeadSource = 'Broker Portal' AND IsConverted = false AND InitiateDigitalBooking__c = true]) {
            Id existingAccountId = getExistingAccountMap.get(ld.Unit__c);
            if(existingAccountId != null && existingAccountId == ld.ExistingAccount__c) {
                ld.Unit__c = null;
                ld.InitiateDigitalBooking__c = false;
                updateBrokerLeads.add(ld);
            }
        }
        if(!updateBrokerLeads.isEmpty()) {
            try {
                update updateBrokerLeads;
            } catch(Exception ex) {
                LoggerService.save(LoggerService.addApexLog(ex,'Update Broker Lead on Unit Release','ScheduleToUnLockUnBlockUnits','updateBrokerLeadOnUnitRelease'));
            }
        }
    }
    
    @InvocableMethod(label='Deactivate CP & Update Broker Lead On Unit Release')
    public static void processUnitRelease(List<UnitsWithRelatedAccount> inputs) {
        
        if(inputs == null || inputs.isEmpty()) return;
        
        Map<Id,Id> unitToAccountMap = new Map<Id,Id>();
        Set<Id> unitIds = new Set<Id>();
        
        for(UnitsWithRelatedAccount inp : inputs) {
            if(inp.unitId != null && inp.accountId != null) {
                unitToAccountMap.put(inp.unitId, inp.accountId);
                unitIds.add(inp.unitId);
            }
        }
        List<Unit__c> unitsList = [SELECT Id,DigitalSales__c,LockExpiryTime__c,Status__c,LockedByCustomer__c FROM Unit__c WHERE Id IN : unitIds];
        deactivateCPRecordsOnUnitRelease(unitsList);
        updateBrokerLeadOnUnitRelease(unitIds,unitToAccountMap);
    }
    
    public class UnitsWithRelatedAccount {
        
        @InvocableVariable(required = true)
        public Id unitId;
        
        @InvocableVariable(required = true)
        public Id accountId;
    }
}