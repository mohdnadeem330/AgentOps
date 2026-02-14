@IsTest
private class ServiceRequestDetailWebserviceTest {
    
    @testSetup
    static void setupTestData() {
        // Customer & Buyer
        Account acc = new Account(Name = 'Test Customer Account');
        insert acc;
        
        Contact con = new Contact(
            LastName = 'Tester',
            FirstName = 'Apex',
            AccountId = acc.Id
        );
        insert con;
        
        Account buyer = new Account(Name = 'Buyer Account');
        insert buyer;
        
        // External SR Status
        HexaBPM__SR_Status__c extStatus = TestObjectsFactory.getSRStatus('Submitted');
        insert extStatus;
        
        // Project setup
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.AccountNumberCorporate__c   = '12345678';
        projectRecord.BankNameCorporate__c        = 'Test Bank';
        projectRecord.BeneficiaryNameCorporate__c = 'Test Beneficiary';
        projectRecord.BranchCorporate__c          = 'Test Branch';
        projectRecord.IBANNoCorporate__c          = 'AE240354031005788876001';
        projectRecord.SwiftCodeCorporate__c       = 'NBADAEAA';
        insert projectRecord;
        
        // Unit
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord.Id;
        insert unit;
        
        // Sales Order
        SalesOrder__c salesOrder = new SalesOrder__c(Unit__c = unit.Id);
        insert salesOrder;
        
        // Direct Debit Request
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.Id);
        ddr.CustomerIdType__c = 'Trade License Number';
        insert ddr;
        
        // Operating Hours + Territory
        OperatingHours oh = new OperatingHours(Name = 'TestOH');
        insert oh;
        
        ServiceTerritory srvt = new ServiceTerritory();
        srvt.Name = 'Noya';
        srvt.OperatingHoursId = oh.Id;
        srvt.Type__c = 'Property Transfer';
        srvt.Street = 'Street 1';
        srvt.City = 'Abu Dhabi';
        srvt.State = 'Abu Dhabi';
        srvt.Country = 'United Arab Emirates';
        srvt.PostalCode = '00000';
        insert srvt;
        
        // Service Request
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
            HexaBPM__Customer__c = acc.Id,
            HexaBPM__External_SR_Status__c = extStatus.Id,
            BuyerName__c = buyer.Id,
            Pay_By__c = 'BUYER',
            ChargeCollected__c = 100.50,
            Unit__c = unit.Id,
            Service_Territory__c = srvt.Id,
            SalesOrder__c = salesOrder.Id,
            PDC_Collection_date__c = Date.today(),
            PDC_Collection_Location__c = 'Dubai'
        );
        insert sr;
        
        // SR Template + Steps
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.LPC_WAIVER_RT, 'LPCWaiver');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(sr.Id, objSRSteps.Id, objStepTemplate.Id);
        insert newStep;
        
        // SR Document
        HexaBPM__SR_Doc__c srd = new HexaBPM__SR_Doc__c(
            HexaBPM__Service_Request__c = sr.Id,
            Name = 'Buyer Emirates ID Copy',
            HexaBPM__Status__c = 'Generated',
            HexaBPM__Rejection_Reason__c = 'Test'
        );
        insert srd;
        
        // Receipt Acknowledgement
        ReceiptAcknowledgement__c ra = new ReceiptAcknowledgement__c(
            ServiceRequest__c = sr.Id,
            Status__c = 'Link Sent',
            Amount__c = 100.50,
            PaymentType__c = 'Credit Card',
            CurrencyIsoCode = 'AED'
        );
        insert ra;
    }
    
    // Valid Service Request ID
    @IsTest
    static void testDoGet_WithValidServiceRequestId() {
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/LiveAldar/ServiceRequestDetail';
        req.httpMethod = 'GET';
        req.params.put('serviceRequestId', sr.Id);
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ServiceRequestDetailWebservice.doGet();
        Test.stopTest();
        
        // Validate JSON safely
        String jsonResponse = RestContext.response.responseBody.toString();
        System.assertNotEquals(null, jsonResponse, 'Response should not be null');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        System.assert(parsed.containsKey('success'), 'Missing success key');
        System.assert(parsed.containsKey('statusCode'), 'Missing statusCode key');
        System.assert(parsed.containsKey('message'), 'Missing message key');
        System.debug('Response (valid SR): ' + jsonResponse);
    }
    
    // Blank Service Request ID
    @IsTest
    static void testDoGet_WithBlankServiceRequestId() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/LiveAldar/ServiceRequestDetail';
        req.httpMethod = 'GET';
        // no params
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ServiceRequestDetailWebservice.doGet();
        Test.stopTest();
        
        String jsonResponse = RestContext.response.responseBody.toString();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        System.assertEquals(false, parsed.get('success'));
        System.assertEquals(400, Integer.valueOf(parsed.get('statusCode')));
        System.debug('Response (blank SR): ' + jsonResponse);
    }
    
    // Invalid Service Request ID
    @IsTest
    static void testDoGet_WithInvalidServiceRequestId() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/LiveAldar/ServiceRequestDetail';
        req.httpMethod = 'GET';
        req.params.put('serviceRequestId', '001000000000000AAA');
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ServiceRequestDetailWebservice.doGet();
        Test.stopTest();
        
        String jsonResponse = RestContext.response.responseBody.toString();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        System.assertEquals(false, parsed.get('success'));
        System.assertEquals(404, Integer.valueOf(parsed.get('statusCode')));
        System.debug('		Response (invalid SR): ' + jsonResponse);
    }
}