//ECSS//
public class ECSS_UploadCaseInvocable {

    @InvocableMethod
    public static List<returnWrapper> createCases(List<CasesWrapper> casesWrapper){
        
        Map<String,Boolean> catSubCatEltizamMap = new Map<String,Boolean>();
       	Set<String> SubVertCatSubCatSet = new Set<String>();
        List<Case_Field_Dependency_Revised__mdt> dependcyList = [SELECT Id,Category__c,Sub_Category__c,ECSS_Is_ECSS__c,ECSS_Is_Eltizam__c,Sub_Vertical__c 
                                                                 FROM Case_Field_Dependency_Revised__mdt 
                                                                 WHERE ECSS_IS_ECSS__c =true];
        for(Case_Field_Dependency_Revised__mdt currItem : dependcyList){
            catSubCatEltizamMap.put(currItem.Category__c+'|'+currItem.Sub_Category__c,currItem.ECSS_Is_Eltizam__c);
            SubVertCatSubCatSet.add(currItem.Sub_Vertical__c+'|'+currItem.Category__c+'|'+currItem.Sub_Category__c);
            
        }
        Integer indexCase =1;
        for(Case caseObj: casesWrapper[0].casesList)
        {
			
        }
        return null;
    }
    
    public class CasesWrapper{
        @InvocableVariable
        public List<Case> casesList;
    }
    
    public class returnWrapper{
        @InvocableVariable
        public List<String> errorMessages;
    }
    
}