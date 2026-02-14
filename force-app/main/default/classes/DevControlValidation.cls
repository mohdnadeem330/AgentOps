public class DevControlValidation {
    //Global Variable - Declaration Start
    public static CaseTriggerMetadata.QueueWrapper queueWrapper = CaseTriggerMetadata.getqueueWrInstance(CaseTriggerHelper.getQueueMap());
    //Global Variable - Declaration End
    public static void DevcontrolUnitValidation(List<Case> newCases){
        Map<Id, SObject> unitRecordMap = new Map<Id, SObject>();
        Id devcontrolRT =Schema.SObjectType.case.getRecordTypeInfosByName().get(Constants.Development_Control).getRecordTypeId();
        Id plotRecordTypeId =Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get(Constants.UNIT_RECORD_TYPE_PLOT).getRecordTypeId();  
        Set<Id> unitIds = new Set<Id>();
        for (case c : newCases) {            
            if (c.Unit__c != null) {
                unitIds.add(c.Unit__c);  
            }
        }        	
        if (!unitIds.isEmpty()) {
            unitRecordMap = new Map<Id, SObject>([SELECT Id, RecordTypeId, GFAArea__c,TotalArea__c FROM Unit__c WHERE Id IN :unitIds]);
        }        
        for (Case c : newCases) {
            if(c.RecordTypeId == devcontrolRT){
                Id unitId = (c.unit__c!=null ? c.unit__c : null);
                if (unitId != null && unitRecordMap.containsKey(unitId)) {
                    SObject unitRecord = unitRecordMap.get(unitId);
                    if (unitRecord.get('RecordTypeId') != plotRecordTypeId) {                        
                        c.addError(System.label.Unit_RecordType_MustBe_Plot);
                    }else if((unitRecord.get('GFAArea__c')==null || unitRecord.get('GFAArea__c')==0)  && (c.Type==Constants.GFA || c.Type==Constants.NONGFA)){
                        c.addError(System.label.Plot_GFAArea_Required);
                    } else if((unitRecord.get('TotalArea__c')==null || unitRecord.get('TotalArea__c')==0) && c.Type!=Constants.GFA  && c.Type!=Constants.NONGFA){
                        c.addError(System.label.Plot_TotalArea_Required);
                    }
                }
            }
        }                
    }
    public static void AccountShare(List<Case> newCases){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> csUnitIds = new Set<Id>();
        List<AccountShare> accountShares = new List<AccountShare>();
        Map<Id, SalesOrder__c> saleOrderMapbyCsUnits = new Map<Id, SalesOrder__c>();
        Map<Id, AccountShare> existingSharesMap = new Map<Id, AccountShare>();
        Id devcontrolRT =Schema.SObjectType.case.getRecordTypeInfosByName().get(Constants.Development_Control).getRecordTypeId();        
        for (Case c : newCases) {
            if (c.AccountId != null && c.RecordTypeId==devcontrolRT) {
                accountIds.add(c.AccountId);
                csUnitIds.add(c.Unit__c);
            }
        }
        if(!accountIds.isEmpty()){
            existingSharesMap = new Map<Id, AccountShare>([SELECT AccountId FROM AccountShare WHERE AccountId IN :accountIds AND UserOrGroupId =: queueWrapper.devControlQueue.id]); 
        }      
        if(!csUnitIds.isEmpty()) {   
            for(SalesOrder__c so : [SELECT Id,Account__c,Unit__c,Status__c FROM SalesOrder__c WHERE Status__c=:Constants.SO_STATUS_SOLD and Unit__c IN :csUnitIds]) {
                saleOrderMapbyCsUnits.put(so.Unit__c,so);
            }     
        }
        for (Case c : newCases) {
            if(c.RecordTypeId==devcontrolRT && c.Unit__c!=null){                               
                if(saleOrderMapbyCsUnits.containsKey(c.Unit__c) && c.AccountId == saleOrderMapbyCsUnits.get(c.Unit__c).Account__c){
                    AccountShare accountShare = new AccountShare();
                    accountShare.AccountId = saleOrderMapbyCsUnits.get(c.Unit__c).Account__c;
                    accountShare.UserOrGroupId = queueWrapper.devControlQueue.id;
                    accountShare.AccountAccessLevel = 'Read'; 
                    accountShare.OpportunityAccessLevel = 'None';
                    accountShare.RowCause = Schema.AccountShare.RowCause.Manual; 
                    if (!existingSharesMap.containsKey(saleOrderMapbyCsUnits.get(c.Unit__c).Account__c)) {
                        accountShares.add(accountShare);
                    }
                } 
            }            
        }
        if (!accountShares.isEmpty()) {
            try {
                insert accountShares;                
            } catch (DmlException e) {                
                System.debug('Failed to share Account: ' + e.getMessage());
            }
        }
    }
}