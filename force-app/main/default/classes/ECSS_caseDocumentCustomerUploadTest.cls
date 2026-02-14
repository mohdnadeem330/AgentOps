@isTest
public class ECSS_caseDocumentCustomerUploadTest{
    
    @testSetup
    static void createData(){
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            
            Case caseObj = TestObjectsFactory.getEltizamCase(newAccount);
            insert caseObj;  
        }
    }
    
    @isTest
    public static void testGetCustomerDocuments(){
        Test.startTest();
        Case caseObj = [Select Id from Case Limit 1];
        ECSS_caseDocumentCustomerUpload.getCustomerDocuments(caseObj.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void testUploadDocuments(){
        Test.startTest();
        Case caseObj = [Select Id from Case Limit 1];
        //List<Document__c> docList = new List<Document__c>([Select Id,Name from Document__c where Case__c=:caseObj.Id]);
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
            reqIds.add(docItem.Id);
        }
        
        ECSS_caseDocumentCustomerUpload.uploadDocuments(caseObj.Id,docMapList,reqIds);
        Test.stopTest();
    }
    
}