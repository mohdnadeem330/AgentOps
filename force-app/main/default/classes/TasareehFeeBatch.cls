global class TasareehFeeBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<String> permitIds;
    
    public TasareehFeeBatch(Set<String> permitIds) {
        this.permitIds = permitIds;
        System.debug('permit'+permitIds);
    } 
    
     global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id,Permit__c
            FROM Fees__c
            WHERE Permit__c IN :permitIds
        ]);
    }
    
     global void execute(Database.BatchableContext BC, List<Fees__c> scope) {
         
     Set<String> permitIds = new Set<String>();
        for (Fees__c fee : scope) {
            system.debug('Inside execute '+fee.Permit__c);
            permitIds.add(fee.Permit__c);
        }
        
        if (permitIds.isEmpty()) {
            return;
        }
        
        Set<String> permitsWithOnlyCreditedFees = new Set<String>();
        
        // Find all permits that have any non-Credited fees
        Set<String> permitsWithNonCreditedFees = new Set<String>();
        Set<String> permitsWithInvoicedFees = new Set<String>();
        List<AggregateResult> nonCreditedPermits = [SELECT Permit__c
                                                    FROM Fees__c
                                                    WHERE Permit__c IN :permitIds
                                                    AND FeeStatus__c != 'CREDITED'
                                                    GROUP BY Permit__c];
        
        for (AggregateResult ar : nonCreditedPermits) {
            permitsWithNonCreditedFees.add((String) ar.get('Permit__c'));
            
            
        }
        system.debug('Non credited Fees '+permitsWithNonCreditedFees);
        // Permits with only credited fees
        for (String permitId : permitIds) {
            if (!permitsWithNonCreditedFees.contains(permitId)) {
                permitsWithOnlyCreditedFees.add(permitId);
            }
        }
         Set<Id> permitIdSet = new Set<Id>();
         list<Permit__c> permitToUpdate = new  list<Permit__c>();
        
        if (!permitsWithOnlyCreditedFees.isEmpty()) {
          
        
        
        // Query the latest Fee Apply Date for these credited fee permits
        List<AggregateResult> latestFeeDates = [SELECT Permit__c, MAX(FeeApplyDate__c) latestDate
                                                FROM Fees__c
                                                WHERE Permit__c IN :permitsWithOnlyCreditedFees
                                                AND FeeStatus__c = 'CREDITED'
                                                GROUP BY Permit__c];
        
        Map<String, DateTime> permitToLatestDate = new Map<String, DateTime>();
        for (AggregateResult ar : latestFeeDates) {
            String permitId = (String) ar.get('Permit__c');
            DateTime latestDate = (DateTime) ar.get('latestDate');
            permitToLatestDate.put(permitId, latestDate);
        }
        
        // Query all fee records for these credited fee permits
        List<Fees__c> feesToUpdate = [SELECT Id, Permit__c, FeeApplyDate__c, Latest_Record__c
                                      FROM Fees__c
                                      WHERE Permit__c IN :permitsWithOnlyCreditedFees
                                      AND FeeStatus__c = 'CREDITED'];
        
        for (Fees__c fee : feesToUpdate) {
            DateTime latestDate = permitToLatestDate.get(fee.Permit__c);
            fee.Latest_Record__c = (fee.FeeApplyDate__c == latestDate);
        }
        
        // Update the Fee records
        if (!feesToUpdate.isEmpty()) {
            update feesToUpdate;
        }
        
      
          List<Permit__c> CreditedpermitToUpdate = [SELECT Id, All_Credited_Fees__c FROM Permit__c
                                      WHERE Id IN :permitsWithOnlyCreditedFees];
        
         for (Permit__c P : CreditedpermitToUpdate) {
           
             P.All_Credited_Fees__c=true;
             if (!permitIdSet.contains(P.Id)){
                 permitIdSet.add(P.Id);
             permitToUpdate.add(p);
             }
                }
        }
        
         system.debug('Credited Fee Permit to update'+permitToUpdate);
         if (!permitsWithNonCreditedFees.isEmpty()) {
           List<Permit__c> InvoicedpermitToUpdate = [SELECT Id, All_Credited_Fees__c FROM Permit__c
                                      WHERE Id IN :permitsWithNonCreditedFees and All_Credited_Fees__c=true];
         
          for (Permit__c P : InvoicedpermitToUpdate) {
             P.All_Credited_Fees__c=false;
              if (!permitIdSet.contains(P.Id)){
                 permitIdSet.add(P.Id);
             permitToUpdate.add(p);
             }
             
                }
         }
         
         system.debug('Permit to Update '+permitToUpdate);
        // Update the Permit records with only credited fees
        if (!permitToUpdate.isEmpty()) {
            update permitToUpdate;
        }
                                      
    }
    
    global void finish(Database.BatchableContext BC) {
       system.debug('Batch Finished');
    }
    
   

}