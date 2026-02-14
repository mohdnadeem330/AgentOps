@isTest
public class CustomerDocumentWebServiceTest {

    @isTest
    public static void testCustomerDocumentWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.NetAmount__c = 10000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        Document__c docRecord = new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC, Status__c = Constants.DOCUMENT_STATUS_UPLOADED);
        insert docRecord;

        Document__c docRecord1 = new Document__c(Account__c = acc.Id, DocumentType__c = CustomerAPIConstants.DOCUMENT_PASSPORT_COPY, Status__c = Constants.DOCUMENT_STATUS_UPLOADED);
        insert docRecord1;

        Document__c docRecord2 = new Document__c(Unit__c = unit.Id, DocumentType__c = Constants.DOCUMENT_TYPE_FLOOR_PLAN, Status__c = Constants.DOCUMENT_STATUS_UPLOADED);
        insert docRecord2;

        TestObjectsFactory.initializeRestContext(null, '/query/document');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerDocumentWebService.doPost(acc.Id, '', CustomerAPIConstants.ALL, '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerDocumentWebServiceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Document__c docRecord1 = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC, Status__c = Constants.DOCUMENT_STATUS_UPLOADED);
        insert docRecord1;

        TestObjectsFactory.initializeRestContext(null, '/query/document');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerDocumentWebService.doPost(acc.Id + '123', '', CustomerAPIConstants.ALL, '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}