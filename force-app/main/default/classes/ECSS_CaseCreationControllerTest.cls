@isTest
public class ECSS_CaseCreationControllerTest {
    
    @testSetup
    static void createData(){
        TestObjectsFactory.createUser(); 
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            
            List<Case> caseInsert = new List<Case>();
            Case caseObj = TestObjectsFactory.getProvisCase(newAccount);
            caseInsert.add(caseObj);
            
            insert caseInsert;
            
            Contract cont = TestObjectsFactory.getKhidmahContracts(newAccount.Id);
            insert cont;
            
            Unit_Contract__c unitCont = TestObjectsFactory.getKhidmahContractDetail(caseObj.AssetId,cont.Id);
            insert unitCont;
            
            Account comp = TestObjectsFactory.getECSSCompany();
            insert comp;
            
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
        
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert ecssUnit;            
            TestObjectsFactory.getCustomerUnit(newAccount.Id, ecssUnit.Id);
            
            FM_Companies__c fm = TestObjectsFactory.getFMCompany(caseObj.AssetId, comp.Id);
            insert fm;
        }
    }
    @isTest
    public static void testRecordTypes(){
        Test.startTest();
        ECSS_CaseCreationController.ecssCaseRecordTypes();
        Test.stopTest();
    }
        @isTest
    public static void testecssAccountRecordTypes(){
        Test.startTest();
        ECSS_CaseCreationController.ecssAccountRecordTypes();
        Test.stopTest();
    }
        @isTest
    public static void testgetCountryValues(){
        Test.startTest();
        ECSS_CaseCreationController.getCountryValues();
        Test.stopTest();
    }
            @isTest
    public static void testgetRelatedAccount(){
        Test.startTest();
        Customer_Unit__c asUnit = [SELECT Id,Unit__c FROM Customer_Unit__c limit 1];
        ECSS_CaseCreationController.getRelatedAccount(asUnit.Unit__c);
        Test.stopTest();
    }
    
    @isTest
    public static void testgetSalutationValues()
    {
        Test.startTest();
        ECSS_CaseCreationController.getSalutationValues();
        Test.stopTest();
    }
        
    @isTest
    public static void testgetNationalityValues()
    {
        Test.startTest();
        ECSS_CaseCreationController.getNationalityValues();
        Test.stopTest();
    }
    
    @isTest
    public static void testAccountDuplicateCheck()
    {
        Test.startTest();
        ECSS_CaseCreationController.accDuplicateCheck('test@test.com', '1234', '567', '123456789','Person','1234567');
        Test.stopTest();
    }
      @isTest
    public static void testContactDuplicateCheck()
    {
        Test.startTest();
        ECSS_CaseCreationController.contactDuplicateCheck('test@test.com', '1234', '567', true,'1234567');
        Test.stopTest();
    }
      @isTest
    public static void testContactDuplicateRetrievalCheck()
    {
        Test.startTest();
        ECSS_CaseCreationController.contactDuplicateRetrieval('test@test.com', '1234', '567', true,'1234567','test@test.com');
        Test.stopTest();
    }
          @isTest
    public static void testOrgContactDuplicateCheck()
    {
        Test.startTest();
        ECSS_CaseCreationController.contactDuplicateCheck('test@test.com', '1234', '567', false,'1234567');
        Test.stopTest();
    }
    @isTest
    public static void testAccountDuplicateOrgCheck()
    {
        Test.startTest();
        ECSS_CaseCreationController.accDuplicateCheck('test@test.com', '1234', '567', '123456789','Organization','1234567');
        Test.stopTest();
    }
    
    
    @isTest
    public static void testGetContracts(){
        Test.startTest();
        // List<Asset> unitList = [Select Id from Asset Limit 1 ];
        List<Case> caseList = [Select Id, AccountId,AssetId  from Case Limit 1];
        ECSS_CaseCreationController.getKhidmahContracts(caseList[0].AssetId, caseList[0].accountId, 'HVAC','','');
        ECSS_CaseCreationController.getKhidmahContracts(caseList[0].AssetId, '', '','khidmah','');
        ECSS_CaseCreationController.getKhidmahContracts('', caseList[0].accountId, '','khidmah','');
        ECSS_CaseCreationController.getKhidmahContracts('', caseList[0].accountId, 'HVAC','khidmah','IFM / Khidmah Home');

        Test.stopTest();
    }
    @isTest
    public static void testComp(){
        Test.startTest();
        List<Case> caseList =  [Select Id, AccountId,AssetId,RecordType.DeveloperName,
                                SubVertical__c,ECSS_Sub_Category_Text__c,CaseCategory__c,ECSS_Object_Category__c
                                from Case Limit 1];
        ECSS_CaseCreationController.CompanysWrapper cw = ECSS_CaseCreationController.companyLinked(caseList[0].CaseCategory__c, caseList[0].ECSS_Sub_Category_Text__c);
        Test.stopTest();
    }
    @isTest
    public static void testCompFromManagedBy(){
        Test.startTest();
        List<Case> caseList =  [Select Id, AccountId,AssetId,RecordType.DeveloperName,
                                SubVertical__c,ECSS_Sub_Category_Text__c,CaseCategory__c,ECSS_Object_Category__c
                                from Case Limit 1];
        ECSS_CaseCreationController.getCompanyFromManagedBy(caseList[0].AssetId);
        Test.stopTest();
    }
    @isTest
    public static void testGetContacts(){
        Test.startTest();
        List<Case> caseList = [Select Id, AccountId,AssetId  from Case Limit 1];
        ECSS_CaseCreationController.relatedContacts(caseList[0].accountId , caseList[0].AssetId);
        Test.stopTest();
    }
    @isTest
    public static void testPhoneValidaty(){
        Test.startTest();
        
        // ECSS_CaseCreationController.phoneValidaty('002', '1223456789');
        Test.stopTest();
    }
    
    /*   @isTest
public static void testDerivedValues(){
Test.startTest();
List<Case> caseList = [Select Id, AccountId,AssetId,RecordType.DeveloperName,
SubVertical__c,ECSS_Sub_Category_Text__c
from Case Where AccountId!=null and RecordType.DeveloperName='ECSS_Inquiry' Limit 1];
ECSS_CaseCreationController.derivedValues dv = ECSS_CaseCreationController.derivedValues(caseList[0].RecordType.DeveloperName, caseList[0].SubVertical__c, caseList[0].ECSS_Sub_Category_Text__c);
Test.stopTest();
}
@isTest
public static void testDerivedValuesComp(){
Test.startTest();
List<Case> caseList = [Select Id, AccountId,AssetId,RecordType.DeveloperName,
SubVertical__c,ECSS_Sub_Category_Text__c
from Case Where AccountId!=null and RecordType.DeveloperName='ECSS_Complaints' Limit 1];
ECSS_CaseCreationController.derivedValues dv = ECSS_CaseCreationController.derivedValues(caseList[0].RecordType.DeveloperName, caseList[0].SubVertical__c, caseList[0].ECSS_Sub_Category_Text__c);
Test.stopTest();
}*/
    @isTest
    public static void testsubCategoryReturnValue(){
        Test.startTest();
        List<Case> caseList = [Select Id, AccountId,AssetId,RecordType.DeveloperName,
                               SubVertical__c,ECSS_Sub_Category_Text__c,CaseCategory__c,ECSS_Object_Category__c
                               from Case Limit 1];
        ECSS_CaseCreationController.subCategoryReturnValue(caseList[0].CaseCategory__c, caseList[0].SubVertical__c,caseList[0].RecordType.DeveloperName,caseList[0].ECSS_Object_Category__c);
        Test.stopTest();
    }
    @isTest
    public static void testcategoryReturnValue(){
        Test.startTest();
        List<Case> caseList = [Select Id, AccountId,AssetId,RecordType.DeveloperName,
                               SubVertical__c,ECSS_Sub_Category_Text__c,CaseCategory__c,ECSS_Object_Category__c
                               from Case Limit 1];
        ECSS_CaseCreationController.categoryReturnValue(caseList[0].RecordType.DeveloperName,caseList[0].ECSS_Object_Category__c,caseList[0].SubVertical__c,caseList[0].ECSS_Sub_Category_Text__c,'');
        Test.stopTest();
    }
    @isTest
    public static void testObjectReturnValue(){
        Test.startTest();
        List<Case> caseList = [Select Id, AccountId,AssetId,RecordType.DeveloperName,
                               SubVertical__c,ECSS_Sub_Category_Text__c,CaseCategory__c,ECSS_Object_Category__c
                               from Case Limit 1];
        List<ECSS_CaseCreationController.ListWrapper> listWrap = ECSS_CaseCreationController.objectCategoryReturnValue(caseList[0].RecordType.DeveloperName,caseList[0].CaseCategory__c,caseList[0].SubVertical__c,caseList[0].ECSS_Sub_Category_Text__c);
        Test.stopTest();
    }
    @isTest
    public static void testObjectReturnMainValue(){
        Test.startTest();
        List<Case> caseList = [Select Id, AccountId,AssetId,RecordType.DeveloperName,
                               SubVertical__c,ECSS_Sub_Category_Text__c,CaseCategory__c,ECSS_Object_Category__c
                               from Case Limit 1];
        Case updCase = new Case();
        updCase.Id = caseList[0].Id;
        updCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Maintenance').getRecordTypeId();
        update updCase;
        List<ECSS_CaseCreationController.ListWrapper> listWrap = ECSS_CaseCreationController.objectCategoryReturnValue('Request',caseList[0].CaseCategory__c,caseList[0].SubVertical__c,caseList[0].ECSS_Sub_Category_Text__c);
        Test.stopTest();
    }
    
    @isTest
    public static void testgetRelatedUnits(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account limit 1];
        Asset aset = [SELECT Id FROM Asset limit 1];
        Customer_Unit__c csUnit = TestObjectsFactory.getCustomerUnit(acc.Id,aset.Id);
        System.debug('Customerunit'+csUnit.Id);
        ECSS_CaseCreationController.getRelatedUnits(acc.Id,'a','','0','0','0','Ecss Unit');
        Test.stopTest();
    }
    @isTest
    public static void testgetRelatedUnitsWithContr(){
        Test.startTest();
        Unit_Contract__c cont = [SELECT Id,Contract__r.AccountId,ECSS_Unit__c FROM Unit_Contract__c limit 1];
        Account acc = [SELECT Id,ParentId FROM Account where Id =: cont.Contract__r.AccountId limit 1];
        Asset aset = [SELECT Id,parentId FROM Asset where Id=: cont.ECSS_Unit__c limit 1];
        Asset parentAss = [SELECT Id FROM Asset where Id !=: aset.Id limit 1];
        aset.ParentId = parentAss.Id;
        update aset;
       
        Customer_Unit__c csUnitParent = new Customer_Unit__c();
        csUnitParent.Account__c = acc.Id;
        csUnitParent.Unit__c = parentAss.Id;
        csUnitParent.Customer_Type__c = 'Tenant';
        csUnitParent.Active__c = true;
        insert csUnitParent;
        Customer_Unit__c csUnit = TestObjectsFactory.getCustomerUnit(acc.Id,aset.Id);
        System.debug('Customerunit'+csUnit.Id);
        ECSS_CaseCreationController.getRelatedUnits(acc.Id,'a','','0','0','0','Ecss Unit');
        Test.stopTest();
    }
      
      
    @isTest
    public static void testgetRelatedUnitsWithInv(){
        Test.startTest();
       // Account acc = [SELECT Id FROM Account limit 1];
        BuildingSection__c buildingSec =[SELECT Id,name FROM BuildingSection__c limit 1 ];
        ECSS_CaseCreationController.getRelatedUnits('','','',buildingSec.name,'0','0','Ecss Unit');
        Test.stopTest();
    }
     @isTest
    public static void testgetInv(){
        Test.startTest();
        ECSS_CaseCreationController.getInvData();
        Test.stopTest();
    }
    @isTest
    public static void testgetRelatedUnitsNoAcc(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account limit 1];
        Asset aset = [SELECT Id FROM Asset limit 1];
        Customer_Unit__c csUnit = TestObjectsFactory.getCustomerUnit(acc.Id,aset.Id);
        ECSS_CaseCreationController.getRelatedUnits('','a','a','0','0','0','');
        Test.stopTest();
    }
    @isTest
    public static void testgetAccRecord(){
        Test.startTest();
        Contract cont = [SELECT Id,AccountId FROM Contract Limit 1];
        ECSS_CaseCreationController.getAccRecord(cont);
        Test.stopTest();
    }
    
    
    /* @isTest
public static void testGetUnitDetails(){
Test.startTest();
List<Case> caseList = [Select Id, AccountId,AssetId,Unit__c  from Case Limit 1];
ECSS_TestCategorySubCategoryController.getECSSUnitDetails(caseList[0].Unit__c);
Test.stopTest();
}


@isTest
public static void testGetCompanies(){
Test.startTest();
// List<Asset> unitList = [Select Id from Asset Limit 1 ];
//  List<Case> caseList = [Select Id, AccountId,AssetId  from Case Limit 1];
ECSS_TestCategorySubCategoryController.getCompanies();
Test.stopTest();
}
@isTest
public static void testUploadDocuments(){
Test.startTest();
Case caseObj = [Select Id from Case Limit 1];
Document__c doc = TestObjectsFactory.getCaseDocument(caseObj.Id);
insert doc;
List<Document__c> docList = new List<Document__c>();
docList.add(doc);
List<String> reqIds = new List<String>();
List<Map<String,String>> docMapList = new List<Map<String,String>>();
for(Document__c docItem: docList)
{
Map<String,String> docMap = new Map<String,String>();
docMap.put('docId',docItem.Id);
docMap.put('fileName', 'file' + docItem.Name + '.pdf');
docMap.put('base64Data', 'VGhpcyBpcyBhIHRlc3QgZmlsZQ==');
docMapList.add(docMap);
//reqIds.add(docItem.Id);
}

ECSS_TestCategorySubCategoryController.uploadDocuments(caseObj.Id,docMapList);
Test.stopTest();
}
*/
    
}