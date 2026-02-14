public class AssignVirtualAccount {
    
    @InvocableMethod(label='Assign virtual Account Number for SR on Unit')
    public static void AssignVirtualAccountNumber(List<Id> request) {
        system.debug('request '+request);
        List<Unit__c> unitsToUpdate = new List<Unit__c>();
        Map<Id,Id> mapOfProjectIdWithSRId = new Map<Id,Id>();
        Map<Id,Id> mapOfProjectIdWithUnitId = new Map<Id,Id>();
        for(HexaBPM__Service_Request__c req : [select id, Unit__c, Unit__r.Project__c from HexaBPM__Service_Request__c where id=:request]){
            unitsToUpdate.add(new Unit__c(Id=req.Unit__c, Project__c=req.Unit__r.Project__c));
            mapOfProjectIdWithSRId.put(req.Unit__r.Project__c,req.Id);
            mapOfProjectIdWithUnitId.put(req.Unit__r.Project__c,req.Unit__c);
        }
        system.debug('unitsToUpdate '+unitsToUpdate);
        system.debug('mapOfProjectIdWithSRId '+mapOfProjectIdWithSRId);
        
        Map<Id,Id> mapOfProjectIdWithBVNId = new Map<Id,Id>();
        Map<Id,BankVirtualAccounts__c> vitualAccountsToUpdate = new Map<Id,BankVirtualAccounts__c>();
        for(BankVirtualAccounts__c virtualAccount : [SELECT
                                                     Id,
                                                     Name,
                                                     Unit__c,
                                                     Project__c
                                                     FROM BankVirtualAccounts__c
                                                     WHERE Project__c in :mapOfProjectIdWithSRId.keyset()
                                                     AND BufferFlag__c=true
                                                     AND Virtual_Account_Type__c = 'Escrow'
                                                     ORDER BY name asc]){
            if(!mapOfProjectIdWithBVNId.containskey(virtualAccount.Project__c)){
                system.debug('virtualAccount '+virtualAccount);
                mapOfProjectIdWithBVNId.put(virtualAccount.Project__c,virtualAccount.Id);
                virtualAccount.ServiceRequest__c = mapOfProjectIdWithSRId.get(virtualAccount.Project__c);
                virtualAccount.BufferFlag__c = false;
                virtualAccount.Unit__c = mapOfProjectIdWithUnitId.get(virtualAccount.Project__c);
                vitualAccountsToUpdate.put(virtualAccount.id,virtualAccount);
            }
        }
        system.debug('vitualAccountsToUpdate '+vitualAccountsToUpdate);
        
        for(Unit__c unit: unitsToUpdate){
            unit.VirtualAccountNumberForSR__c = mapOfProjectIdWithBVNId.get(unit.Project__c);
        }
         if(!vitualAccountsToUpdate.values().isempty()){
            update vitualAccountsToUpdate.values();
        }
        if(!unitsToUpdate.isempty()){
            update unitsToUpdate;
        }
       
        
    }
}