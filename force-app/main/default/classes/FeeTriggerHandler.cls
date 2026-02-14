public class FeeTriggerHandler {
    
    public static void handleAfterInsert(Map<Id, Sobject> newMap) {
        Set<String> Permit = new Set<String>();
        
        
        for (Id key : newMap.keySet()) {
            SObject obj = newMap.get(key);
            String status = (String) obj.get('FeeStatus__c');
            String PermitId=(String)obj.get('Permit__c');
            
            if(PermitId != null && (status=='INVOICED' || status=='CREDITED')){
                Permit.add(permitId);  
            }
            
        }
        
        if(!Permit.isEmpty()){
        TasareehFeeBatch batchInstance = new TasareehFeeBatch(Permit);
        Database.executeBatch(batchInstance, 200);    
        
        }
        
    }
  
    // after updates
    public static void handleAfterUpdate(Map<id,SObject> newMap, map<Id, Sobject> oldMap) {
        Set<String> Permit = new Set<String>();
         Map<Id,Fees__c> newFees = (Map<Id,Fees__c>)newMap;
        Map<Id,Fees__c> oldFees = (Map<Id,Fees__c>)oldMap;
        
        for (Fees__c newFee : newFees.Values()) {
            if(newFee.FeeStatus__c != oldFees.get(newFee.id).FeeStatus__c && newFee.Permit__c != null && (newFee.FeeStatus__c=='INVOICED' || newFee.FeeStatus__c=='CREDITED')){
                Permit.add(newFee.Permit__c);
                
            }
        }
            
        if(!Permit.isEmpty()){
        TasareehFeeBatch batchInstance = new TasareehFeeBatch(Permit);
        Database.executeBatch(batchInstance, 200);    
        
        }
        
    }
    
   
   
    
}