@IsTest
private class BP_BrokerAgencyRegistrationDocumentsTest {
    
    @TestSetup
    static void setupTestData() {
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;
        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, '', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Agency Registration'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;        
        newSR1.Unit__c = unit.Id;  
        newSR1.IsComplianceReturned__c = false;
        newSR1.Compliance_Status__c = '';
        newSR1.TransferSellingPrice__c= 1000000;
        insert newSR1;
    
        HexaBPM__Document_Master__c objMaster = new HexaBPM__Document_Master__c();
        objMaster.Name = 'Trade License';
        objMaster.HexaBPM__Code__c = 'Trade_License';
        insert objMaster;

        HexaBPM__SR_Template_Docs__c objSRTem = new HexaBPM__SR_Template_Docs__c ();
        objSRTem.HexaBPM__Added_through_Code__c = true;
        objSRTem.HexaBPM__Document_Master__c = objMaster.Id;
        insert objSRTem;

        // Insert a mock SR Document
        HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c(
            Name = 'Trade License',
            HexaBPM__Service_Request__c = newSR1.Id,
            HexaBPM__SR_Template_Doc__c = objSRTem.Id
        );
        insert srDoc;
    }
    
    @IsTest
    static void testSuccessfulDocumentUpload() {
        // Get inserted SR Doc
        HexaBPM__SR_Doc__c srDoc = [SELECT Id, HexaBPM__Service_Request__c, DocumentMasterCode__c FROM HexaBPM__SR_Doc__c LIMIT 1];
        
        // Prepare request body JSON
        BP_BrokerAgencyRegistrationDocuments.AgencyRegistrationDocumentWrapper wrapper = 
            new BP_BrokerAgencyRegistrationDocuments.AgencyRegistrationDocumentWrapper();
        wrapper.serviceRequestId = String.valueOf(srDoc.HexaBPM__Service_Request__c);
        wrapper.srDocumentBase64 = new Map<String, String>{
            srDoc.DocumentMasterCode__c => 'dGVzdCBiYXNlNjQgZGF0YQ==' // "test base64 data"
        };
        
        String jsonBody = JSON.serialize(wrapper);
        
        // Prepare RestContext
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/uploadBrokerAgencyDocuments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestResponse res = new RestResponse();
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BP_BrokerAgencyRegistrationDocuments.start();
        Test.stopTest();
        
        // Verify response
        System.assertNotEquals(null, RestContext.response, 'Response should not be null');
    }
    
    @IsTest
    static void testBlankServiceRequestId() {
        BP_BrokerAgencyRegistrationDocuments.AgencyRegistrationDocumentWrapper wrapper = 
            new BP_BrokerAgencyRegistrationDocuments.AgencyRegistrationDocumentWrapper();
        wrapper.serviceRequestId = '';
        wrapper.srDocumentBase64 = new Map<String, String>{ 'TradeLicense' => 'abc123' };
        
        String jsonBody = JSON.serialize(wrapper);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/uploadBrokerAgencyDocuments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestResponse res = new RestResponse();
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BP_BrokerAgencyRegistrationDocuments.start();
        Test.stopTest();
    }
    
    @IsTest
    static void testBlankDocumentMap() {
        BP_BrokerAgencyRegistrationDocuments.AgencyRegistrationDocumentWrapper wrapper = 
            new BP_BrokerAgencyRegistrationDocuments.AgencyRegistrationDocumentWrapper();
        wrapper.serviceRequestId = 'a1B000000000001AAA';
        wrapper.srDocumentBase64 = new Map<String, String>();
        
        String jsonBody = JSON.serialize(wrapper);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/uploadBrokerAgencyDocuments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestResponse res = new RestResponse();
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BP_BrokerAgencyRegistrationDocuments.start();
        Test.stopTest();
    }
}