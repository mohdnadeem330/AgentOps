@isTest
public class CustomerDocumentDataWebServiceTest {

    @isTest
    public static void testCustomerDocumentDataWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.SourceofFunds__pc = 'Employment Income';
        insert acc;

        Document__c doc = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC);
        insert doc;

        TestObjectsFactory.createContentDocumentLink(doc.Id);

        TestObjectsFactory.initializeRestContext(null, '/query/documentdata');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            Account acc1 = TestObjectsFactory.getPersonAccountRecord();
            acc1.SourceofFunds__pc = 'Employment Income';
            acc1.PersonEmail = 'test@aldar.com';
            insert acc1;
            
        	//CustomerDocumentDataWebService.doPost(doc.Id, acc1.PersonEmail);
        	CustomerDocumentDataWebService.doPost(doc.Id, acc1.PersonEmail,'Yes');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        try {
            CustomerDocumentDataWebService.doPost(doc.Id, acc.PersonEmail,'No');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {
            CustomerDocumentDataWebService.doPost(doc.Id, acc.PersonEmail,'Yes');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        try {
            CustomerDocumentDataWebService.doPost(doc.Id, acc.PersonEmail + '123','Yes');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}