@isTest
public class CustomerFileUploadWebServiceTest {

    @isTest
    public static void testAccountDocument() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        TestObjectsFactory.initializeRestContext(null, '/query/fileupload');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"accountId": "' + acc.Id + '","contentVersionId": null,"documentType": "Profile Picture","fileTitle": "Profile Picture.jpg","fileData": "Test File Data"}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();

            ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
            reqBody = '{"accountId": "' + acc.Id + '","contentVersionId": "' + cv.Id + '","documentId": null,"documentType": "Transfer Screenshot","fileTitle": "Transfer Screenshot.jpg","fileData": "Test File Data"}';
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testOtherDocument() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receipt;
        
        TestObjectsFactory.initializeRestContext(null, '/query/fileupload');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"accountId": "' + acc.Id + '","contentVersionId": null,"documentId": "' + receipt.Id + '","documentType": "Receipt","fileTitle": "Receipt.jpg","fileData": "Test File Data"}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testSalesOrderDocument() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        Document__c doc = new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = CustomerAPIConstants.DOCUMENT_SPA_CUSTOMER_COPY);
        insert doc;
        
        TestObjectsFactory.initializeRestContext(null, '/query/fileupload');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"accountId": "' + acc.Id + '","contentVersionId": null,"documentId": "' + salesOrder.Id + '","documentType": "' + CustomerAPIConstants.DOCUMENT_SPA_CUSTOMER_COPY + '","fileTitle": "Receipt.jpg","fileData": "Test File Data"}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();

            reqBody = '{"accountId": "' + acc.Id + '","contentVersionId": null,"documentId": "' + salesOrder.Id + '","documentType": "' + CustomerAPIConstants.DOCUMENT_SPA_CUSTOMER_COPY + '","fileTitle": "Receipt.jpg","fileData": "Test File Data"}';
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();

            reqBody = '{"accountId": "' + acc.Id + '","contentVersionId": null,"documentId": "' + doc.Id + '","documentType": "' + CustomerAPIConstants.DOCUMENT_SPA_CUSTOMER_COPY + '","fileTitle": "Receipt.jpg","fileData": "Test File Data"}';
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testSRDocument() {

        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus(Constants.Compliance_Rejected);       
        insert Submitted; 
        
         HexaBPM__SR_Status__c Submitted1 = TestObjectsFactory.getSRStatus(Constants.Compliance_Cleared);       
        insert Submitted1; 
        
         HexaBPM__SR_Status__c Submitted2 = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted2; 
        
         HexaBPM__Status__c status1 = new HexaBPM__Status__c();
            status1.Name =Constants.Cleared;
            status1.HexaBPM__Code__c =Constants.Cleared;
            insert status1;
        
        HexaBPM__Status__c statusCom = new HexaBPM__Status__c();
        statusCom.Name = 'Completed';
        statusCom.HexaBPM__Code__c = 'Completed';
        insert statusCom;
        
        HexaBPM__Status__c statusApp = new HexaBPM__Status__c();
        statusApp.Name = 'Approved';
        statusApp.HexaBPM__Code__c = 'Approved';
        insert statusApp;
      
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_DEV_RT, 'PropertyTransfer');
        insert objStepTemplate;
                
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');       
        insert closed;
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSRSPA.SalesOrder__c = salesOrder.Id;
        newSRSPA.SPACounterSignedDate__c=Date.today();
        insert newSRSPA;

        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSRSPA.id, objSRSteps.Id, objStepTemplate.id);   
        insert newStep;

        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS;
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id;
        insert docTemp;
        
        HexaBPM__SR_Doc__c doc = new HexaBPM__SR_Doc__c();
        doc.HexaBPM__Document_Master__c = objDocMaster.id;
        doc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        doc.HexaBPM__Service_Request__c = newSRSPA.id;
        doc.Name = CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS;
        insert doc;
        
        TestObjectsFactory.initializeRestContext(null, '/query/fileupload');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
            String reqBody = '{"accountId": "' + newAccount.Id + '","contentVersionId": null,"documentId": "' + newSRSPA.Id + '","documentType": "' + CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS + '","fileTitle": "Receipt.jpg","fileData": "Test File Data"}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();

            reqBody = '{"accountId": "' + newAccount.Id + '","contentVersionId": null,"documentId": "' + newSRSPA.Id + '","documentType": "' + CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS + '","fileTitle": "Receipt.jpg","fileData": "Test File Data"}';
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();

            reqBody = '{"accountId": "' + newAccount.Id + '","contentVersionId": null,"documentId": "' + doc.Id + '","documentType": "' + CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS + '","fileTitle": "Receipt.jpg","fileData": "Test File Data"}';
            req.requestBody = Blob.valueOf(reqBody);
            CustomerFileUploadWebService.doPost();
        Test.stopTest();
    }
}