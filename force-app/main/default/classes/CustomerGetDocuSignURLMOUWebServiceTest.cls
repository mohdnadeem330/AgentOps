@isTest
public class CustomerGetDocuSignURLMOUWebServiceTest {

    @isTest
    public static void testCustomerGetDocuSignURLWebService() {

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        List<Account> accsToInsert = new List<Account>();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(acc);
        Account accountRecord = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(accountRecord);
        Account accountRecord2 = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(accountRecord2);
        insert accsToInsert;
        
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        Opportunity oppRecord = TestObjectsFactory.getOpportunityRecord(acc.Id);
            oppRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(ResaleConstants.RESALE_RECORDTYPE).getRecordTypeId();
            oppRecord.Seller__c = accountRecord.Id;
            oppsToInsert.add(oppRecord);
        Opportunity oppRecord2 = TestObjectsFactory.getOpportunityRecord(acc.Id);
            oppsToInsert.add(oppRecord2);
        insert oppsToInsert;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(oppRecord2.Id, accountRecord.Id);
            salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        oppRecord.SalesOrder__c = salesOrder.Id;
        TriggerHandler.processedIds = new Set<Id>();
        update oppRecord;
        
        List<JointOwner__c> josToInsert = new List<JointOwner__c>();
            josToInsert.add(TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, accountRecord.Id, 'Friend Of'));
            josToInsert.add(TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, accountRecord2.Id, 'Spouse Of'));
        insert josToInsert;
        
        List<Document__c> docsToInsert = new List<Document__c>();
        Document__c doc = new Document__c(Opportunity__c = oppRecord.Id, DocumentType__c = 'Listing MOU');
            docsToInsert.add(doc);
        Document__c signDoc = new Document__c(Opportunity__c = oppRecord.Id, DocumentType__c = 'Signed Listing MOU');
            docsToInsert.add(signDoc);
        insert docsToInsert;
        
        TestObjectsFactory.createContentDocumentLink(doc.Id);
        
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/customer/getmoudocusignurl');
        RestContextHandler handler = new RestContextHandler(true);
                
        try {
            String responseBody = '{"access_token":"test","token_type":"test","expires_in":10000,"scope":"test","":"test","envelopeId":"test","uri":"test","statusDateTime":"test","status":"test","url":"test"}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            CustomerGetDocuSignURLMOUWebService.doPost(acc.Id, doc.Id, 'http://localhost', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerGetDocuSignURLWebServiceError() {

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        List<Account> accsToInsert = new List<Account>();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(acc);
        Account accountRecord = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(accountRecord);
        Account accountRecord2 = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(accountRecord2);
        insert accsToInsert;
        
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        Opportunity oppRecord = TestObjectsFactory.getOpportunityRecord(acc.Id);
            oppRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(ResaleConstants.RESALE_RECORDTYPE).getRecordTypeId();
            oppRecord.Seller__c = accountRecord.Id;
            oppsToInsert.add(oppRecord);
        Opportunity oppRecord2 = TestObjectsFactory.getOpportunityRecord(acc.Id);
            oppsToInsert.add(oppRecord2);
        insert oppsToInsert;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(oppRecord2.Id, accountRecord.Id);
            salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        oppRecord.SalesOrder__c = salesOrder.Id;
        TriggerHandler.processedIds = new Set<Id>();
        update oppRecord;
        
        List<JointOwner__c> josToInsert = new List<JointOwner__c>();
            josToInsert.add(TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, accountRecord.Id, 'Friend Of'));
            josToInsert.add(TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, accountRecord2.Id, 'Spouse Of'));
        insert josToInsert;

        Document__c doc = new Document__c(Opportunity__c = oppRecord.Id, DocumentType__c = 'Listing MOU');
        insert doc;

        ContentVersion cv = TestObjectsFactory.getContentVersion();
        insert cv;

        TestObjectsFactory.initializeRestContext(null, '/customer/getmoudocusignurl');
        RestContextHandler handler = new RestContextHandler(true);
        
        CustomerGetDocuSignURLMOUWebService.AuthenticationResponseModel authenticationResponseModel = new CustomerGetDocuSignURLMOUWebService.AuthenticationResponseModel();
        authenticationResponseModel.access_token = 'test';
        authenticationResponseModel.token_type = 'test';
        authenticationResponseModel.expires_in = 1;
        authenticationResponseModel.scope = 'test';

        CustomerGetDocuSignURLMOUWebService.KeyValueModel keyValueModel = new CustomerGetDocuSignURLMOUWebService.KeyValueModel();
        keyValueModel.uaepass = 'test';
        keyValueModel.idnow = 'test';

        CustomerGetDocuSignURLMOUWebService.EnvelopeRequestModel envelopeRequestModel = new CustomerGetDocuSignURLMOUWebService.EnvelopeRequestModel();
        envelopeRequestModel.emailSubject = 'test';
        envelopeRequestModel.documents = new List<CustomerGetDocuSignURLMOUWebService.DocumentModel>{new CustomerGetDocuSignURLMOUWebService.DocumentModel(cv)};
        envelopeRequestModel.recipients = new CustomerGetDocuSignURLMOUWebService.RecipientModel(acc, 'test', 'test');
        envelopeRequestModel.status = 'test';

        CustomerGetDocuSignURLMOUWebService.SignProviderModel signProviderModel = new CustomerGetDocuSignURLMOUWebService.SignProviderModel('test');

        CustomerGetDocuSignURLMOUWebService.TabModel tabModel = new CustomerGetDocuSignURLMOUWebService.TabModel('test');

        CustomerGetDocuSignURLMOUWebService.SignHereModel signHereModel = new CustomerGetDocuSignURLMOUWebService.SignHereModel('anchorString');

        CustomerGetDocuSignURLMOUWebService.EnvelopeResponseModel envelopeResponseModel = new CustomerGetDocuSignURLMOUWebService.EnvelopeResponseModel();
        envelopeResponseModel.envelopeId = 'test';
        envelopeResponseModel.uri = 'test';
        envelopeResponseModel.statusDateTime = 'test';
        envelopeResponseModel.status = 'test';

        CustomerGetDocuSignURLMOUWebService.URLRequestModel urlRequestModel = new CustomerGetDocuSignURLMOUWebService.URLRequestModel('test', acc);
        CustomerGetDocuSignURLMOUWebService.URLResponseModel urlResponseModel = new CustomerGetDocuSignURLMOUWebService.URLResponseModel();
        urlResponseModel.url = 'test';

        Test.startTest();
        try {
            CustomerGetDocuSignURLMOUWebService.doPost(acc.Id, doc.Id, 'http://localhost', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerGetDocuSignURLWebServiceGenerateDoc() {

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        List<Account> accsToInsert = new List<Account>();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(acc);
        Account accountRecord = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(accountRecord);
        Account accountRecord2 = TestObjectsFactory.getPersonAccountRecord();
            accsToInsert.add(accountRecord2);
        insert accsToInsert;
        
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        Opportunity oppRecord = TestObjectsFactory.getOpportunityRecord(acc.Id);
            oppRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(ResaleConstants.RESALE_RECORDTYPE).getRecordTypeId();
            oppRecord.Seller__c = accountRecord.Id;
            oppsToInsert.add(oppRecord);
        Opportunity oppRecord2 = TestObjectsFactory.getOpportunityRecord(acc.Id);
            oppsToInsert.add(oppRecord2);
        insert oppsToInsert;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(oppRecord2.Id, accountRecord.Id);
            salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        oppRecord.SalesOrder__c = salesOrder.Id;
        TriggerHandler.processedIds = new Set<Id>();
        update oppRecord;
        
        List<JointOwner__c> josToInsert = new List<JointOwner__c>();
            josToInsert.add(TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, accountRecord.Id, 'Friend Of'));
            josToInsert.add(TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, accountRecord2.Id, 'Spouse Of'));
        insert josToInsert;

        Document__c doc = new Document__c(Opportunity__c = oppRecord.Id, DocumentType__c = 'Listing MOU');
        insert doc;

        TestObjectsFactory.initializeRestContext(null, '/customer/getmoudocusignurl');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String responseBody = '{"access_token":"test","token_type":"test","expires_in":10000,"scope":"test","":"test","envelopeId":"test","uri":"test","statusDateTime":"test","status":"test","url":"test"}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            CustomerGetDocuSignURLMOUWebService.doPost(acc.Id, doc.Id, 'http://localhost', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}