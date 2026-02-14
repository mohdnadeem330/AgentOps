public class ECSS_InvocableBulkCaseUpload {
    @InvocableMethod
    public static List<returnCaseWrapper> createCases(List<CasesWrapper> casesWrapper){
        List<returnCaseWrapper> rturnWrapper = new List<returnCaseWrapper>();
        List<Case> insertedCases = casesWrapper[0].casesList;
        String recTypeId = casesWrapper[0].recordTypeId;
         
        List<String> sapAccId = new List<String>();
        List<String> sapUnitId = new List<String>();
        List<String> sapCompId = new List<String>();
        Map<String,String> externalToId = new Map<String,String>();
        
        for(Case currCase : insertedCases){
            sapAccId.add(currCase.ECSS_SAP_Account_Id_Bulk_Upload__c);
            sapUnitId.add(currCase.ECSS_UnitSAPExternalId__c);
            sapCompId.add(currCase.ECSS_Company_External_Id__c);
        }
        
        List<Account> accList = [SELECT Id,SapAccountID__c FROM Account WHERE SapAccountID__c in:(sapAccId)];
        List<Asset> asslist = [SELECT Id,ExternalIdentifier  FROM Asset WHERE ExternalIdentifier  IN:(sapUnitId)];
        List<Account> compList = [SELECT Id,ECSS_Company_External_Id__c FROM Account WHERE ECSS_Company_External_Id__c IN:(sapCompId) ];
        
        for(Account acc: accList){
            externalToId.put(acc.SapAccountID__c,acc.Id);
        }
        
        for(Asset currAsset: asslist){
            externalToId.put(currAsset.ExternalIdentifier,currAsset.Id);
        }
        
        for(Account acc: compList){
            externalToId.put(acc.ECSS_Company_External_Id__c,acc.Id);
        }
        
        for(Case currCase : insertedCases){
            currCase.AccountId = externalToId.get(currCase.ECSS_SAP_Account_Id_Bulk_Upload__c);
            currCase.ECSS_Company__c = externalToId.get(currCase.ECSS_Company_External_Id__c);
            currCase.AssetId = externalToId.get(currCase.ECSS_UnitSAPExternalId__c);
            currCase.RecordTypeId = recTypeId; 
        }
        
        
        returnCaseWrapper currCase = new returnCaseWrapper();
        currCase.updatedCaseList = insertedCases;
        rturnWrapper.add(currCase);
        
        return rturnWrapper;
    }
    
    
    
    public class CasesWrapper{
        @InvocableVariable
        public List<Case> casesList;
        @InvocableVariable
        public String recordTypeId;
    }
    public class returnCaseWrapper{
        @InvocableVariable
        public List<Case> updatedCaseList;
    }
}