public without sharing class VirtualAccountService {
    
    public static void updateUnitVA(Map<Id,String> somap){
        
        Map<Unit__c, Id> unitVAMap = new Map<Unit__c, Id>();
        Map<Unit__c, Id> unitCorporateVAMap = new Map<Unit__c, Id>();
        Set<Id> unitIds = new Set<Id>();
        Map<Id,Id> unitsomap = new Map<Id,Id>();
        Set<Id> projectList = new Set<Id>();
        
        Map<Id,Unit__c> unitlistmap = new Map<Id,Unit__c>();
        Map<Id,BankVirtualAccounts__c> valistmap = new Map<Id,BankVirtualAccounts__c>();
        
        Map<Id,Unit__c> unitCorporatelistmap = new Map<Id,Unit__c>();
        Set<String> CorporateIBANSet = new Set<String>();
        for(SalesOrder__c so: [SELECT
                               Id,
                               unit__c,
                               unit__r.id,
                               unit__r.project__c,
                               unit__r.VirtualAccountNumber__c,
                               unit__r.CorporateVirtualAccountNumber__c
                               FROM SalesOrder__c
                               WHERE id in :somap.keyset()]){  
                                   unitsomap.put(so.Unit__c,so.id);
                                   unitIds.add(so.Unit__c);
                               }
        if(!unitIds.isEmpty()){
            for(Unit__c unit: [SELECT Id,Project__c,VirtualAccountNumber__c,CorporateVirtualAccountNumber__c, BuildingSectionName__c,BuildingSectionName__r.IBANNoCorporate__c,
                               Project__r.IBANNoCorporate__c FROM Unit__c WHERE Id in :unitIds
                               AND (VirtualAccountNumber__c != null OR CorporateVirtualAccountNumber__c != null)]){
                                   
                                   if(unit.VirtualAccountNumber__c != null){
                                       unitVAMap.put(unit, unit.VirtualAccountNumber__c);
                                   }
                                   if(unit.CorporateVirtualAccountNumber__c != null){
                                       unitCorporateVAMap.put(unit, unit.CorporateVirtualAccountNumber__c);
                                   }
                                   projectList.add(unit.Project__c);
                                   projectList.add(unit.BuildingSectionName__c);
                                   CorporateIBANSet.add(unit.Project__r.IBANNoCorporate__c);
                               }
        }
        if(!projectList.isEmpty()){
            for(BankVirtualAccounts__c va: [SELECT  Id, Name , Project__c,BuildingSection__c, Virtual_Account_Type__c, EscrowIBANAccountNumber__c FROM BankVirtualAccounts__c
                                            WHERE ( (Project__c IN :projectList OR BuildingSection__c IN: projectList) OR (Virtual_Account_Type__c = 'Aldar Corporate' AND Unit__c = null ))
                                            AND BufferFlag__c=true ORDER BY name ASC]){
                                                if(!unitVAMap.keyset().isEmpty() && va.Virtual_Account_Type__c == 'Escrow'){
                                                    for(Unit__c updunit : unitVAMap.keyset()){
                                                        if(!unitlistmap.containskey(updunit.id) && !valistmap.containskey(va.id)){
                                                            unitlistmap.put(updunit.id, new Unit__c(id=updunit.id, VirtualAccountNumber__c=va.id));
                                                            valistmap.put(va.id, new BankVirtualAccounts__c(id= va.id, unit__c=updunit.id, BufferFlag__c=false));
                                                        }
                                                        if(!valistmap.containskey(unitVAMap.get(updunit))){
                                                            valistmap.put(unitVAMap.get(updunit),new BankVirtualAccounts__c(id=unitVAMap.get(updunit),SalesOrder__c=unitsomap.get(updunit.id),StatusFlag__c=somap.get(unitsomap.get(updunit.id)))); 
                                                        } 
                                                    }   
                                                }
                                                if(!unitCorporateVAMap.keyset().isEmpty() && va.Virtual_Account_Type__c == 'Aldar Corporate'){
                                                    system.debug(unitCorporateVAMap.keyset());
                                                    system.debug(unitCorporateVAMap.keyset());
                                                    for(Unit__c updunit : unitCorporateVAMap.keyset()){
                                                        if(!unitCorporatelistmap.containskey(updunit.id) && !valistmap.containskey(va.id) && updunit.CorporateVirtualAccountNumber__c != null && (va.EscrowIBANAccountNumber__c==updunit.BuildingSectionName__r.IBANNoCorporate__c || va.EscrowIBANAccountNumber__c==updunit.Project__r.IBANNoCorporate__c) ){
                                                            system.debug('va:::'+va);
                                                            unitCorporatelistmap.put(updunit.id, new Unit__c(id=updunit.id, CorporateVirtualAccountNumber__c=va.id));
                                                            valistmap.put(va.id, new BankVirtualAccounts__c(id= va.id, unit__c = updunit.id, BufferFlag__c=false));
                                                        }
                                                        if(!valistmap.containskey(unitCorporateVAMap.get(updunit))){
                                                            valistmap.put(unitCorporateVAMap.get(updunit),new BankVirtualAccounts__c(id=unitCorporateVAMap.get(updunit),SalesOrder__c=unitsomap.get(updunit.id),StatusFlag__c=somap.get(unitsomap.get(updunit.id)))); 
                                                        }   
                                                    } 
                                                }
                                            }
            
            system.debug('unitCorporatelistmap:::'+unitCorporatelistmap);
            system.debug('valistmap:::'+valistmap);
            if(valistmap.size()>0){
                update valistmap.values();
            }
            if(unitlistmap.size()>0){
                update unitlistmap.values();
            }
            if(unitCorporatelistmap.size()>0){
                upsert unitCorporatelistmap.values();
            }
        }       
    }
    
}