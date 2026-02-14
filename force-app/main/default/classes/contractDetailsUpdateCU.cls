public class contractDetailsUpdateCU {
    public class BooleanWrapper {
        @InvocableVariable(label='Result Flag')
        public Boolean resultFlag;
    }
    @InvocableMethod(label='Check Contract Details CU and Update CU')
    public static void checkRecords(List<Id> recordIds) {
        List<BooleanWrapper> results = new List<BooleanWrapper>();
        Date today = Date.today();
        List<Customer_Unit__c> unitsToUpdate = new List<Customer_Unit__c>();
        for(Customer_Unit__c unit :  [SELECT Id, Active__c,
                                      (Select id,Contract__r.EndDate from Contract_Details__r WHERE Contract__r.EndDate != null)//, Unit_Contracts__r.EndDate // WHERE Unit_Contracts__r.EndDate != null
                                      FROM Customer_Unit__c 
                                      WHERE Id  =:recordIds])
        {
            Boolean hasActiveContract = false;
            if(unit.Contract_Details__r != null && !unit.Contract_Details__r.isEmpty()) {
                for(Unit_Contract__c detail : unit.Contract_Details__r) {
                    if(detail.Contract__r != null && detail.Contract__r.EndDate != null && detail.Contract__r.EndDate > today) {
                        hasActiveContract = true;
                        break;
                    }
                }
            }
            
            // Update status based on evaluation
            if(unit.Active__c != hasActiveContract) {
                unit.Active__c = hasActiveContract;
                unitsToUpdate.add(unit);
            }
        }
        
        if(!unitsToUpdate.isEmpty()) {
            update unitsToUpdate;
        }
        
    }
}