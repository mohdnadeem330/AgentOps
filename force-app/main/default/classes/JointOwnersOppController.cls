public with sharing class JointOwnersOppController {

    @AuraEnabled(cacheable=true)
    public  static List<AccountRelationship__c> getRelatedAccountNames(Id recordId){
        try {
           Set<Id> accountRelIds = new   Set<Id>();
            List<String> accountRelRelationType = new    List<String>();
            List<AccountRelationship__c> accountNames=new List<AccountRelationship__c>();
            Set<Id> accountIds = ResaleUnitService.getOpportunityAccountId(recordId);
         
            if( accountIds.size()>0){
                Map<Id,Account> acctWithRelationships=new Map<Id,Account>([SELECT Id ,(SELECT Id ,RelatedAccount__c FROM AccountRelationships__r WHERE RelatedAccount__c != null ) FROM Account WHERE Id IN:accountIds]);
                 
                for(Id acc:accountIds){
                    if(acctWithRelationships.get(acc).AccountRelationships__r.size()>0  ) {
                        for(AccountRelationship__c ar:acctWithRelationships.get(acc).AccountRelationships__r){
                            accountRelIds.add(ar.Id); 
                        }
                    }
                }   
            }  
            if(accountRelIds.size()>0){
                accountNames = AccountRelationshipService.getAccountRelationshipType(accountRelIds);
            }
            return accountNames;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Decimal getTotalSharePercentage(Id recordId){
        try {
            Decimal returnPercentage = 0;
            Opportunity thisOpp = [SELECT Id, SharePercentage__c, (SELECT Id, SharePercentage__c FROM JointOwnersOpportunity__r) FROM Opportunity WHERE Id =: recordId];
            if (!thisOpp.JointOwnersOpportunity__r.isEmpty()) {
                for (JointOwner__c jointOwner: thisOpp.JointOwnersOpportunity__r) {
                    returnPercentage += jointOwner.SharePercentage__c != null ? jointOwner.SharePercentage__c : 0;
                }
            }
            System.debug('returnPercentage>>>' + returnPercentage);
            return returnPercentage;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public  static List<AccountRelationship__c> getRelationType(Id recordId){
        try {
           
         
          Set<Id> accountRelType = new   Set<Id>();
          
            List<AccountRelationship__c> relationType=new List<AccountRelationship__c>();
            Set<Id> accountIds=  SalesOrderService.getSalesOrdersAccountIds(recordId);
         
            if( accountIds.size()>0){
                Map<Id,Account> acctWithRelationships=new Map<Id,Account>([SELECT id ,(SELECT Id ,RelatedAccount__c from AccountRelationships__r WHERE RelatedAccount__c != null ) from Account WHERE Id IN:accountIds]);
                 
                for(Id acc:accountIds){
                
                if(acctWithRelationships.get(acc).AccountRelationships__r.size()>0  ) {
                
                   for(AccountRelationship__c ar:acctWithRelationships.get(acc).AccountRelationships__r){
                      
                    accountRelType.add(ar.Id);

               }
            }
          
           }  
        }  
            if(accountRelType.size()>0){
                
               relationType=  AccountRelationshipService.getAccountRelationshipType(accountRelType);
           
            }
          
        return  relationType;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled  
    public static string saveJointOwner(JointOwner__c  JointOwnerRec) {  
      
        string jointownerId;  
        try{  
            Insert JointOwnerRec;  
           
            jointownerId = JointOwnerRec.Id;  
          
        } catch(Exception ex){  
            system.debug('Exception===>'+ex.getMessage());  
            throw new AuraHandledException(ex.getMessage());
        }  
        return jointownerId;  
    }    
    
}