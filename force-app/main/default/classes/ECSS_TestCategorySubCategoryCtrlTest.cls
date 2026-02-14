@isTest
public class ECSS_TestCategorySubCategoryCtrlTest {
    
    @testSetup
    static void createData(){
                TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
        Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
        insert newAccount;
        
        Case caseObj = TestObjectsFactory.getProvisComplaintCase(newAccount);
        insert caseObj;
        
        Contract cont = TestObjectsFactory.getKhidmahContracts(newAccount.Id);
        insert cont;
        
        Unit_Contract__c unitCont = TestObjectsFactory.getKhidmahContractDetail(caseObj.AssetId,cont.Id);
        insert unitCont;
        
        Account comp = TestObjectsFactory.getECSSCompany();
        insert comp;
        }
    }
    @isTest
    public static void testGetCategories(){
        Test.startTest();
        ECSS_TestCategorySubCategoryController.getCategoryProjectMap();
        Test.stopTest();
    }
    @isTest
    public static void testGetUnitDetails(){
        Test.startTest();
        List<Case> caseList = [Select Id, AccountId,AssetId,Unit__c  from Case Limit 1];
        ECSS_TestCategorySubCategoryController.getECSSUnitDetails(caseList[0].Unit__c);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetContracts(){
        Test.startTest();
       // List<Asset> unitList = [Select Id from Asset Limit 1 ];
        List<Case> caseList = [Select Id, AccountId,AssetId  from Case Limit 1];
        ECSS_TestCategorySubCategoryController.getKhidmahContracts(caseList[0].AssetId, caseList[0].accountId, '');
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
}