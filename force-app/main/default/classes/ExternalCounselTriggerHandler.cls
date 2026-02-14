public class ExternalCounselTriggerHandler extends TriggerHandler {
    
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
       
        List<Id>CotactIds =getContact(newList);
        for(External_Counsel__c ex :(List<External_Counsel__c>)newList){
            System.debug(CotactIds);
            if(!CotactIds.isEmpty() && CotactIds.size() >0 && !CotactIds.contains(ex.Contact__c)){ex.addError('Please select the contact associated with the Legal Firm');break;
            }
            if(CotactIds.size() == 0){ex.addError('Please select the contact associated with the Legal Firm');break;
            }
        }
        
        
    }
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        List<Id>CotactIds =getContact(newList);
        for(External_Counsel__c ex :(List<External_Counsel__c>)newList){
            if( !CotactIds.isEmpty() && CotactIds.size() >0 && !CotactIds.contains(ex.Contact__c)){ex.addError('Please select the contact associated with the Law Firm');break;
            }
            if(CotactIds.size() == 0){ex.addError('Please select the contact associated with the Legal Firm');break;
            }
        }
    }
    public static List<Id> getContact(List<SObject> newList){
         List<Id> caseId = new List<Id>();
        List<Id> CotactIds = new List<Id>();
        for(External_Counsel__c ex :(List<External_Counsel__c>)newList){
            caseId.add(ex.Case__c);
        }
        
        List<Contact>conLIst = [SELECT Id,Name FROM Contact WHERE AccountId IN(SELECT Law_Firm__c FROM Case WHERE Id=:caseId AND Law_Firm__c != null) AND AccountId != null];
        
        for(COntact con : conList){
            CotactIds.add(con.Id);
        }
        return CotactIds;
    }
    
}