public class ECSS_TestCategorySubCategoryController{
    
    
    @AuraEnabled(cacheable=true)
    public static CatSubCatWrapper getCategoryProjectMap(){
        
        //List<String> ECSS_OrgnizationNames = new List<String>();
        /*List<String> ECSSCategories = new List<String>();
        List<String> Categories = new List<String>();
        List<String> ECSSSubCategories = new List<String>();
        List<String> SubCategories = new List<String>();*/
        Map<String,Boolean> catSubCatMap = new Map<String,Boolean>();
        Map<String,Boolean> catSubCatEltizamMap = new Map<String,Boolean>();
        Map<String,List<String>> catSubCatSubVerticalMap = new Map<String,List<String>>();
        Map<String,List<SubCatMtdWrapper>> catSubCatMdtMap = new Map<String,List<SubCatMtdWrapper>>();
        Map<String,List<String>> catSubCatOBjCatMap = new Map<String,List<String>>();
        Map<String,String> categoryCodeMap = new Map<String,String>();
        CatSubCatWrapper catSubCatWrap = new CatSubCatWrapper();
        /*
        //Get the organizations used in the ecss project
       String ECSSComRTName = Label.ECSS_CompanyRecordType;
        Id ECSS_recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ECSSComRTName).getRecordTypeId();
       List<Account> ECSS_Organizations = [SELECT Id,Name,RecordTypeId FROM Account WHERE RecordTypeId =: ECSS_recordTypeId];
        
        // Loop through the records and extract the names
        for(Account acc : ECSS_Organizations) {
            ECSS_OrgnizationNames.add(acc.Name);
        }
        System.debug('ECSS_OrgnizationNames:'+ECSS_OrgnizationNames);
        */
        //Get the CategoriesList to extract both
        List<Case_Field_Dependency_Revised__mdt> dependcyList = [SELECT Id,Category__c,Organization__c,Sub_Category__c,
                                                                 ECSS_Is_ECSS__c,ECSS_Is_Eltizam__c,Sub_Vertical__c,Category_Code__c, 
                                                                 ECSS_Sub_Category__c,
                                                                 ECSS_ObjectCategory__c,
                                                                 ECSS_Sub_Category__r.MasterLabel, 
                                                                 ECSS_Sub_Category__r.Complaints__c, ECSS_Sub_Category__r.Inquiry__c, 
                                                                 ECSS_Sub_Category__r.Maintenance__c 
                                                                 FROM Case_Field_Dependency_Revised__mdt];
        for(Case_Field_Dependency_Revised__mdt currItem : dependcyList){
            
            if(currItem.ECSS_Is_ECSS__c) // if ECSS then Sub Category value is found the metadata relationship field
            {
               /* ECSSCategories.add(currItem.Category__c);
                ECSSSubCategories.add(currItem.Sub_Category__c);*/
                categoryCodeMap.put(currItem.Category__c,currItem.Category_Code__c);
                catSubCatMap.put(currItem.Category__c+'|'+currItem.ECSS_Sub_Category__r.MasterLabel,true);
                catSubCatEltizamMap.put(currItem.Category__c+'|'+currItem.ECSS_Sub_Category__r.MasterLabel,currItem.ECSS_Is_Eltizam__c);
                
                if(currItem.Sub_Vertical__c != null)
                {
                    if(catSubCatSubVerticalMap.containsKey(currItem.Category__c+'|'+currItem.ECSS_Sub_Category__r.MasterLabel))
                        catSubCatSubVerticalMap.get(currItem.Category__c+'|'+currItem.ECSS_Sub_Category__r.MasterLabel).add(currItem.Sub_Vertical__c);
                    else
                    {
                        List<String> subVerticalList = new List<String>();
                        subVerticalList.add(currItem.Sub_Vertical__c);
                        catSubCatSubVerticalMap.put(currItem.Category__c+'|'+currItem.ECSS_Sub_Category__r.MasterLabel,subVerticalList);
                    }
                }
                
                if(currItem.ECSS_ObjectCategory__c  !=  null)
                {
                    if(catSubCatOBjCatMap.containsKey(currItem.Category__c+'|'+currItem.ECSS_Sub_Category__r.MasterLabel))
                        catSubCatOBjCatMap.get(currItem.Category__c+'|'+currItem.ECSS_Sub_Category__r.MasterLabel).add(currItem.ECSS_ObjectCategory__c);
                    else
                    {
                        List<String> objList = new List<String>();
                        objList.add(currItem.ECSS_ObjectCategory__c);
                        catSubCatOBjCatMap.put(currItem.Category__c+'|'+currItem.ECSS_Sub_Category__r.MasterLabel,objList);
                    }
                }
                if(currItem.ECSS_Sub_Category__c !=null)
                {
                    SubCatMtdWrapper subCatObj = new SubCatMtdWrapper();
                    subCatObj.subCat =  currItem.ECSS_Sub_Category__r.MasterLabel;
                    subCatObj.Maintenance = currItem.ECSS_Sub_Category__r.Maintenance__c;
                    subCatObj.Complaints = currItem.ECSS_Sub_Category__r.Complaints__c;
                    subCatObj.Inquiries = currItem.ECSS_Sub_Category__r.Inquiry__c;
                    
                    if(catSubCatMdtMap.containsKey(currItem.Category__c))
                    {
                        catSubCatMdtMap.get(currItem.Category__c).add(subCatObj);
                    }
                    else
                    {
                        List<SubCatMtdWrapper> subCatMdtList = new List<SubCatMtdWrapper>();
                        subCatMdtList.add(subCatObj);
                        catSubCatMdtMap.put(currItem.Category__c,subCatMdtList);
                    }
                }
                
               /* Map<String,String>    recTypeSubCatMap = new Map<String,String>();
                if(currItem.ECSS_Sub_Category__r.Complaints__c)
                {
                    recTypeSubCatMap.put('Complaints',currItem.ECSS_Sub_Category__r.MasterLabel);
                }
                if(currItem.ECSS_Sub_Category__r.Maintenance__c)
                {
                    recTypeSubCatMap.put('Maintenance',currItem.ECSS_Sub_Category__r.MasterLabel);
                }
                if(currItem.ECSS_Sub_Category__r.Inquiry__c)
                {
                    recTypeSubCatMap.put('Requests',currItem.ECSS_Sub_Category__r.MasterLabel);
                    recTypeSubCatMap.put('Queries',currItem.ECSS_Sub_Category__r.MasterLabel);
                }*/
              //  catRecTypeSubCatMap.put(currItem.Category__c,recTypeSubCatMap);
                
            }
            else //if Not ECSS then Sub Category value is found in Sub Category picklist
            {
                 /*Categories.add(currItem.Category__c);
                SubCategories.add(currItem.Sub_Category__c);*/
                catSubCatMap.put(currItem.Category__c+'|'+currItem.Sub_Category__c,false);
            }
            /*catSubCatWrap.Categories = Categories;
            catSubCatWrap.ECSSCategories = ECSSCategories;
            catSubCatWrap.SubCategories = SubCategories;
            catSubCatWrap.ECSSSubCategories = ECSSSubCategories;*/
            catSubCatWrap.catSubCatMap = catSubCatMap;
            catSubCatWrap.catSubCatEltizamMap = catSubCatEltizamMap;
            catSubCatWrap.catSubCatSubVerticalMap = catSubCatSubVerticalMap;
            catSubCatWrap.catSubCatMdtMap =  catSubCatMdtMap;
            catSubCatWrap.catSubCatObjCatMap = catSubCatObjCatMap;
            catSubCatWrap.categoryCodeMap = categoryCodeMap;
            
        }
        
        
      /*  List<List<String>> outputList = new List<List<String>>();
        outputList.add(Categories);
        outputList.add(ECSSCategories);
        outputList.add(SubCategories);
        outputList.add(ECSSSubCategories);
        System.debug('Categories: ===>'+ Categories);
        System.debug('ECSSCategories: ===>'+ ECSSCategories);
        System.debug('SubCategories: ===>'+ SubCategories);
        System.debug('ECSSSubCategories: ===>'+ ECSSSubCategories);*/

        return catSubCatWrap;
    }
    
    @AuraEnabled(cacheable=true)
    public static Unit__c getECSSUnitDetails(string unitId){
        return [SELECT ECSS_Unit__c FROM Unit__c WHERE Id=:unitId ];
        
    }
   
    @AuraEnabled(cacheable=true)
    public static ContractWrapper getKhidmahContracts(string ecssUnitId,string accountId,string categoryCode){
        system.debug('catCode:'+categoryCode);
       // system.debug('ecssUni'+ecssUnitId+'acc'+accountId);
        String ECSSContractUnitRTName = Label.ECSS_Contract_Unit_RT;
        String ECSSContractItemRTName = Label.ECSS_Contract_Item_RT;
        String ECSSKhidmahContractRTName = Label.ECSS_Khidmah_Contract_RT;
        Id ContractUnitrecordTypeId = Schema.SObjectType.Unit_Contract__c.getRecordTypeInfosByName().get(ECSSContractUnitRTName).getRecordTypeId();
        Id ContractItemrecordTypeId = Schema.SObjectType.Unit_Contract__c.getRecordTypeInfosByName().get(ECSSContractItemRTName).getRecordTypeId();
        Id KhidmahContractrecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get(ECSSKhidmahContractRTName).getRecordTypeId();
        ContractWrapper cw = new ContractWrapper();
        String catCode = '%'+categoryCode+'%';
      //  List<Contract> activeContractRem = new List<Contract>([SELECT Id, ContractNumber,AccountId,StartDate,EndDate, ECSS_Package__c, ECSS_Material_Spares__c,(SELECT Id, Initial__c,Consumed__c,Remaining__c, Item_Type__c FROM Unit_Contracts__r WHERE Category_Code__c like :catCode and RecordTypeId=:ContractItemrecordTypeId And Remaining__c>0) FROM Contract WHERE /*RecordTypeId=:KhidmahContractrecordTypeId AND*/ AccountId =:accountId AND ECSS_Active__c = true AND  Id IN ( SELECT Contract__c FROM Unit_Contract__c  WHERE ECSS_Unit__c =:ecssUnitId and RecordTypeId=:ContractUnitrecordTypeId)]);
      List<Contract> activeContractRem = new List<Contract>([SELECT Id, ContractNumber,AccountId,StartDate,EndDate, ECSS_Package__c, ECSS_Material_Spares__c,(SELECT Id, ECSS_SAPLineExternalId__c ,Description__c,Service_Material__c FROM Unit_Contracts__r WHERE Category_Code__c like :catCode and RecordTypeId=:ContractItemrecordTypeId) FROM Contract WHERE AccountId =:accountId AND ECSS_Active__c = true AND ECSS_Remaining_Call_Outs__c >0 AND Id IN ( SELECT Contract__c FROM Unit_Contract__c  WHERE ECSS_Unit__c =:ecssUnitId and RecordTypeId=:ContractUnitrecordTypeId)]);
	//  List<Contract> activeContractWORem = new List<Contract>([SELECT Id, ContractNumber,AccountId,StartDate,EndDate, ECSS_Package__c, ECSS_Material_Spares__c, ECSS_Contract_Type__c,(SELECT Id, Initial__c,Consumed__c,Remaining__c, Item_Type__c FROM Unit_Contracts__r WHERE RecordTypeId=:ContractItemrecordTypeId And Remaining__c=0) FROM Contract WHERE /*RecordTypeId=:KhidmahContractrecordTypeId AND*/ AccountId =:accountId AND ECSS_Active__c = true AND  Id IN ( SELECT Contract__c FROM Unit_Contract__c  WHERE ECSS_Unit__c =:ecssUnitId and RecordTypeId=:ContractUnitrecordTypeId)]);
      List<Contract> activeContractWORem = new List<Contract>([SELECT Id, ContractNumber,AccountId,StartDate,EndDate, ECSS_Package__c, ECSS_Material_Spares__c, ECSS_Contract_Type__c,ECSS_Number_of_Call_Outs__c FROM Contract WHERE  AccountId =:accountId AND ECSS_Active__c = true AND ECSS_Remaining_Call_Outs__c =0 AND Id IN ( SELECT Contract__c FROM Unit_Contract__c  WHERE ECSS_Unit__c =:ecssUnitId and RecordTypeId=:ContractUnitrecordTypeId)]);
      
        cw.activeContractsWithRemaining = new List<Contract>();
        for(Contract cont : activeContractRem)
        {
            //if(cont.Unit_Contracts__r.size()>0)
            {
                cw.activeContractsWithRemaining.add(cont);
            }
        }
        
        cw.activeContractsWORemaining = new List<Contract>();
        cw.activeContractsWORemaining.addAll(activeContractWORem);
        system.debug('c'+activeContractWORem);
        system.debug('dd'+cw.activeContractsWORemaining);
       /* for(Contract cont : activeContractWORem)
        {
            if(cont.Unit_Contracts__r.size()>0)
            {
                cw.activeContractsWORemaining.add(cont);
            }
        }*/
        system.debug(cw.activeContractsWithRemaining);
        return cw;
        
    }
    
    /*@AuraEnabled(cacheable=true)
    public static CompanyWrapper getCompanyFromMetadata(string category, string subCategory){
        
        String ECSSComRTName = Label.ECSS_CompanyRecordType;
        Id ECSS_recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ECSSComRTName).getRecordTypeId();
       
        List<Case_Field_Dependency_Revised__mdt> caseDependencyList = new List<Case_Field_Dependency_Revised__mdt>([SELECT Id,Category__c,Organization__c,Sub_Category__c 
                                                                 FROM Case_Field_Dependency_Revised__mdt 
                                                                 WHERE Category__c=:category and Sub_Category__c=:subCategory Limit 1]);
                                                                     
                                                                     
            CompanyWrapper cw = new CompanyWrapper();
        if(caseDependencyList.size()>0)
        {
           List<Account> ECSS_Organizations = [SELECT Id,Name,RecordTypeId FROM Account WHERE RecordTypeId =: ECSS_recordTypeId and Name=:caseDependencyList[0].Organization__c];
           cw.companyId= ECSS_Organizations[0].Id;
           cw.companyName = ECSS_Organizations[0].Name;
  
        }
        
         
        return cw;
        
        
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<Id,CompanyWrapper> getCompanyFromManagedBy(string ecssUnitId)
    {
        //String ECSSComRTName = Label.ECSS_CompanyRecordType;
        //Id ECSS_recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ECSSComRTName).getRecordTypeId();
        //system.debug('ECSSCOMPANYMANAGED:'+ecssUnitId);
        Map<Id,CompanyWrapper> companyWrapperMap = new Map<Id,CompanyWrapper>();
        List<FM_Companies__c> managedByCompaniesList = new List <FM_Companies__c>([SELECT ECSS_Company__c, ECSS_Company__r.Name, 
                                                                                   ECSS_Company__r.ECSS_Eltizam_Company__c
                                                                                   FROM FM_Companies__c
                                                                                   WHERE Unit__c =: ecssUnitId]);
        for(FM_Companies__c fc :managedByCompaniesList)
        {
            CompanyWrapper cw = new CompanyWrapper();
            cw.companyId = fc.ECSS_Company__c;
            cw.companyName = fc.ECSS_Company__r.Name;
            cw.isEltizamCompany = fc.ECSS_Company__r.ECSS_Eltizam_Company__c;
            companyWrapperMap.put(fc.ECSS_Company__c,cw);
            
        }
        return companyWrapperMap;
        
    }
    */
    @AuraEnabled(cacheable=true)
    public static Map<String,Account> getCompanies()
    {
        Map<String,Account> companyAccMap = new Map<String,Account>();
       	String ECSSComRTName = Label.ECSS_CompanyRecordType;
        Id ECSS_recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ECSSComRTName).getRecordTypeId();
        List<Account> companiesList = new List <Account>([SELECT Id,Name,ECSS_Eltizam_Company__c 
                                                                   FROM Account where recordTypeId=:ECSS_recordTypeId]);
        for (Account comp:companiesList)
        {
            companyAccMap.put(comp.Name,comp);
        }
        return companyAccMap;
    }
    
    @AuraEnabled
    public static void insertDocuments(List<String> contentDocIds, Id recId) {
       // system.debug('DD:'+contentDocIds);
       // List<ContentDocumentLink> contentDocList = new List <ContentDocumentLink>([SELECT Id, LinkedEntityId,contentdocumentId from ContentDocumentLink where contentdocumentId in: contentDocIds]);
        
        List<ContentDocumentLink> contentDocumentLinksInsert = new List<ContentDocumentLink>();
        //if(contentDocList.size()>0)
        {
            for (String contentDoc : contentDocIds) {
                //system.debug('IDD'+contentDoc);
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = contentDoc;
                link.LinkedEntityId = recId;
                link.ShareType ='V';
                contentDocumentLinksInsert.add(link);
            }
            insert contentDocumentLinksInsert;
            //delete [SELECT Id from ContentDocumentLink where contentdocumentId in: contentDocIds and LinkedEntityId
        }
    }
    
    @AuraEnabled
    public static String uploadDocuments(String recordId, List<Map<String, String>> documents) {
        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
            
            List<Document__c> docToUpdateList = new List<Document__c>();
            for (Map<String, String> docItem : documents) {
                
                String fileName = docItem.get('fileName');
                String base64Data = docItem.get('base64Data');
                
                ContentVersion cv = new ContentVersion();
                cv.Title = fileName;
                cv.PathOnClient = fileName;
                cv.VersionData = EncodingUtil.base64Decode(base64Data);
                contentVersions.add(cv);
                
            }
            insert contentVersions;
            
            //get all content version ids
            Set<Id> contentVersionIds = new Set<Id>();
            for (ContentVersion cv : contentVersions){
                 contentVersionIds.add(cv.Id);
            }
            System.debug(contentVersions);
            System.debug(contentVersionIds);
            
            for (ContentVersion cv: [SELECT ContentDocumentId FROM ContentVersion where Id in:contentVersionIds] ) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = recordId; 
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.ShareType = 'V';  
                contentLinks.add(cdl);
                
            }
            
            insert contentLinks;
            return 'Success';
        } 
        catch (Exception e) {
            throw new AuraHandledException('Error uploading documents: ' + e.getMessage());
            
        }
    }
    
    public class CompanyWrapper {
        @AuraEnabled 
        public string companyId;
        
        @AuraEnabled
        public string companyName;
        
        @AuraEnabled
        public boolean isEltizamCompany;
          
    }
    public class SubCatMtdWrapper
    {
        @AuraEnabled
        public String subCat;
        @AuraEnabled 
        public boolean maintenance;
        @AuraEnabled
        public boolean complaints;
        @AuraEnabled
        public boolean inquiries;
        
        
    }
    public class CatSubCatWrapper {
        /*@AuraEnabled
        public List<String> eCSSCategories;
        @AuraEnabled
        public List<String> categories;
        @AuraEnabled
        public List<String> eCSSSubCategories; 
        @AuraEnabled
        public List<String> subCategories;*/ 
        @AuraEnabled
        public Map<String,Boolean> catSubCatMap;
        @AuraEnabled
        public Map<String,Boolean> catSubCatEltizamMap;
        @AuraEnabled
        public Map<String,List<String>> catSubCatSubVerticalMap;
        @AuraEnabled
        public Map<String,List<String>> catSubCatObjCatMap;
        @AuraEnabled
        public Map<String,List<SubCatMtdWrapper>> catSubCatMdtMap;
        @AuraEnabled
        public Map<String,String> categoryCodeMap;
    }
    
    public class ContractWrapper
    {
        @AuraEnabled
        public List<Contract> activeContractsWithRemaining;
        
        @AuraEnabled
        public List<Contract> activeContractsWORemaining;
    }
    
    
    
    
}