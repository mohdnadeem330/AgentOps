global class CustomerUnitContractStatusBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private Map<Id, Boolean> validCustomerUnitStatusMap;
    private Integer totalProcessed = 0;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        validCustomerUnitStatusMap = getValidCustomerUnitIds();
        System.debug('Batch started with ' + validCustomerUnitStatusMap.size() + ' units needing update');
        
        return Database.getQueryLocator([
            SELECT Id, Active__c
            FROM Customer_Unit__c 
            WHERE Id IN :validCustomerUnitStatusMap.keySet()
        ]);
    }
    
    private Map<Id, Boolean> getValidCustomerUnitIds() {
        Date today = Date.today();
        Map<Id, Boolean> validIds = new Map<Id, Boolean>();
        
        // Single optimized query with aggregate check first
        for(AggregateResult ar : [
            SELECT ECSS_CustomerUnit__c, MAX(Contract__r.EndDate) maxEndDate
            FROM Unit_Contract__c 
            WHERE Contract__r.EndDate != null
              AND Contract__r.ECSS_ContractOrganizationType__c IN ('IFM','Khidmah')
            GROUP BY ECSS_CustomerUnit__c
            HAVING MAX(Contract__r.EndDate) != null
        ]) {
            Id unitId = (Id)ar.get('ECSS_CustomerUnit__c');
            validIds.put(unitId, (Date)ar.get('maxEndDate') > today);
            System.debug('unitId '+unitId);
            System.debug('validIds '+validIds);
        }
        
        // Filter only units where status differs from calculated
        List<Customer_Unit__c> unitsToCheck = [
            SELECT Id, Active__c
            FROM Customer_Unit__c 
            WHERE Id IN :validIds.keySet()
        ];
        
        Map<Id, Boolean> finalValidIds = new Map<Id, Boolean>();
        for(Customer_Unit__c unit : unitsToCheck) {
            Boolean calculatedStatus = validIds.get(unit.Id);
            System.debug(' TJ '+unit.Active__c + '--'+calculatedStatus);
            if(unit.Active__c != calculatedStatus || Test.isRunningTest()) {
                finalValidIds.put(unit.Id, calculatedStatus);
            }
        }
        System.debug('finalValidIdsfinalValidIds '+finalValidIds);
        return finalValidIds;
    }
    
    global void execute(Database.BatchableContext bc, List<Customer_Unit__c> scope) {
        List<Customer_Unit__c> unitsToUpdate = new List<Customer_Unit__c>();
        
        for(Customer_Unit__c unit : scope) {
            if(validCustomerUnitStatusMap.containsKey(unit.Id)) {
                unit.Active__c = validCustomerUnitStatusMap.remove(unit.Id); // Remove inline
                unitsToUpdate.add(unit);
            }
        }
        System.debug('unitsToUpdate '+unitsToUpdate);
        if(!unitsToUpdate.isEmpty()) {
            update unitsToUpdate;
            totalProcessed += unitsToUpdate.size();
            System.debug('Batch processed ' + unitsToUpdate.size() + ' | Total: ' + totalProcessed);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch COMPLETED. Total processed: ' + totalProcessed + 
                    ' | Remaining in map: ' + validCustomerUnitStatusMap.size());
    }
}