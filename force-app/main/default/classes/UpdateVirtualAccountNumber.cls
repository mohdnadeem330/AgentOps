public class UpdateVirtualAccountNumber {
    @InvocableMethod(label='Assign virtual Account Number on Unit for SR Completion')
    public static void AssignVirtualAccountNumber(List<Id> request) {
        Map<Id,Unit__c> unitsToUpdate = new Map<Id,Unit__c>();
        Set<Id> updateStatusOfVirtualAccountNumber = new Set<Id>();
        for(HexaBPM__Service_Request__c req : [select id, Unit__c, Unit__r.Project__c, Unit__r.VirtualAccountNumberForSR__c, Unit__r.VirtualAccountNumber__c from HexaBPM__Service_Request__c where id=:request and Unit__r.VirtualAccountNumberForSR__c<>null]){
			//system.debug('unit:::'+req.Unit__c+':::VA SR:::'+req.Unit__r.VirtualAccountNumberForSR__c);
            if(!unitsToUpdate.containskey(req.Unit__c) && string.isNotBlank(req.Unit__c) && req.Unit__r.VirtualAccountNumberForSR__c<>null){
                unitsToUpdate.put(req.Unit__c,new Unit__c(Id=req.Unit__c, VirtualAccountNumber__c=req.Unit__r.VirtualAccountNumberForSR__c, VirtualAccountNumberForSR__c=null));
            }
            updateStatusOfVirtualAccountNumber.add(req.Unit__r.VirtualAccountNumber__c);
        }
        if(!unitsToUpdate.isempty()){
            update unitsToUpdate.values();
        }
        
        List<BankVirtualAccounts__c> virtualAccountToUpdate = new List<BankVirtualAccounts__c>();
        for(BankVirtualAccounts__c virtualAccount : [SELECT
                                                     Id,
                                                     ServiceRequest__r.SalesOrder__c,
                                                     StatusFlag__c
                                                     FROM BankVirtualAccounts__c
                                                     WHERE id=:updateStatusOfVirtualAccountNumber 
                                                     AND Virtual_Account_Type__c = 'Escrow']){
            virtualAccount.StatusFlag__c = 'Transferred';
            virtualAccount.SalesOrder__c = virtualAccount.ServiceRequest__r.SalesOrder__c;
            virtualAccountToUpdate.add(virtualAccount);
        }
        
        if(!virtualAccountToUpdate.isempty()){
            update virtualAccountToUpdate;
        }
    }
}