@isTest
public class CustomerUpdateDocuSignWebServiceTest {

    @isTest
    public static void testCustomerUpdateDocuSignWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Document__c doc = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC);
        insert doc;

        Document__c signDoc = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_KYC);
        insert signDoc;

        TestObjectsFactory.initializeRestContext(null, '/query/updatedocusign');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String responseBody = '{"access_token":"test","token_type":"test","expires_in":10000,"scope":"test","":"test","envelopeId":"test","uri":"test","statusDateTime":"test","status":"test","url":"test"}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            CustomerUpdateDocuSignWebService.doPost(acc.Id, doc.Id, '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerUpdateDocuSignWebServiceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Document__c doc = new Document__c(Account__c = acc.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC);
        insert doc;

        TestObjectsFactory.initializeRestContext(null, '/query/updatedocusign');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerUpdateDocuSignWebService.doPost(acc.Id, doc.Id, '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerUpdateDocuSignWebServiceSRDoc() {

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
        insert salesOrder;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;

        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_TYPE, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesorder.Id;
        insert newSR;

        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = CustomerAPIConstants.DOCUMENT_HANDOVER_NOC_LETTER;
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id;
        insert docTemp;

        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        objSRDoc.Name = CustomerAPIConstants.DOCUMENT_HANDOVER_NOC_LETTER;
        insert objSRDoc;

        HexaBPM__Document_Master__c objDocMaster2 = new HexaBPM__Document_Master__c();
        objDocMaster2.HexaBPM__Code__c = CustomerAPIConstants.DOCUMENT_SIGNED_HANDOVER_NOC_LETTER;
        objDocMaster2.HexaBPM__Available_to_client__c = true;
        insert objDocMaster2;
        
        HexaBPM__SR_Template_Docs__c docTemp2 = new HexaBPM__SR_Template_Docs__c();
        docTemp2.HexaBPM__Document_Master__c = objDocMaster2.id;
        insert docTemp2;

        HexaBPM__SR_Doc__c objSRDoc2 = new HexaBPM__SR_Doc__c();
        objSRDoc2.HexaBPM__Document_Master__c = objDocMaster2.id;
        objSRDoc2.HexaBPM__SR_Template_Doc__c = docTemp2.id;
        objSRDoc2.HexaBPM__Service_Request__c = newSR.id;
        objSRDoc2.Name = CustomerAPIConstants.DOCUMENT_SIGNED_HANDOVER_NOC_LETTER;
        insert objSRDoc2;

        TestObjectsFactory.initializeRestContext(null, '/query/updatedocusign');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerUpdateDocuSignWebService.doPost(acc.Id, objSRDoc.Id, '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}