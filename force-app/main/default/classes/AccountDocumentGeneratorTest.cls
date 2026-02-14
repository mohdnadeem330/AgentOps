@isTest
public class AccountDocumentGeneratorTest {
    @TestSetup
    static void makeData(){
        User userRecord1 = TestObjectsFactory.getUserRecord('Sales Manager', 'testUser');
        insert userRecord1;
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.OwnerId = userRecord1.Id;
        insert acc;
        Document__c documentRec = TestObjectsFactory.getAccountDocument(acc.Id);
        documentRec.OwnerId = userRecord1.Id;
        insert documentRec;
        Document__c documentRec1 = TestObjectsFactory.getAccountDocument(acc.Id);
        documentRec1.OwnerId = userRecord1.Id;
        insert documentRec1;  
    }
    @IsTest
    static void testGenerateAllDocuments(){
        List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];
        List<Id> lstDocId = new List<Id>();
        for (Document__c doc : [SELECT Id FROM Document__c]) {
            lstDocId.add(doc.Id);
        }
        Test.startTest();
            AccountDocumentGenerator.generateAllDocuments(lstAccount[0].Id);
            try {
                AccountDocumentGenerator.shareDocumentRecordWithLoggedInUser(lstDocId);
            } catch (Exception e) {
                
            }            
        Test.stopTest();
    }
           
    @IsTest 
    static void testDocGenerationServiceOne(){
        TestObjectsFactory.initializeRestContext(null, '/generate/documents');
        List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];    
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('accountId', lstAccount[0].Id);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        AccountDocumentGeneratorService.doPost();
    }

    @IsTest 
    static void testDocGenerationServiceTwo(){
        TestObjectsFactory.initializeRestContext(null, '/generate/documents');
        // List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];    
        // Map<String, String> searchMap = new Map<String, String>();
        // searchMap.put('accountId', lstAccount[0].Id);
        RestContext.request.requestBody = Blob.valueOf('');
        AccountDocumentGeneratorService.doPost();
        RestContext.request.requestBody = Blob.valueOf('test');
        AccountDocumentGeneratorService.doPost();
    }

    @IsTest 
    static void testDocGenerationServiceThree(){
        TestObjectsFactory.initializeRestContext(null, '/generate/documents');
        // List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];    
        // Map<String, String> searchMap = new Map<String, String>();
        // searchMap.put('accountId', lstAccount[0].Id);
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('test', '');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        AccountDocumentGeneratorService.doPost();
    }
}