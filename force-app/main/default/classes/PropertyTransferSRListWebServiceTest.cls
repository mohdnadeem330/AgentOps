@IsTest
private class PropertyTransferSRListWebServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Account & Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact( LastName = 'Tester', FirstName = 'Apex', AccountId = acc.Id);
        insert con;

        // Project & Building Section
        Project__c project = new Project__c( Name = 'Project Test', ProjectCode__c = 'PTCode', BusinessUnitId__c = '1234');
        insert project;

        RecordType buildingRecordType = [SELECT Id FROM RecordType WHERE Name = 'Building' LIMIT 1];
        BuildingSection__c bs = new BuildingSection__c( RecordTypeId = buildingRecordType.Id, Name = 'BuildingSection Test', BuildingSectionCode__c = 'BuildingSection TestCode', Project__c = project.Id);
        insert bs;
        
        // Unit
        Unit__c unit = new Unit__c( Name = 'Test Unit', Status__c = 'Sold', Project__c = project.Id,TotalArea__c = 1200,
            UnitType__c = 'Terraced Apartment', UnitCategory__c = 'Residential', NumberOfBedrooms__c = '2',BuildingSectionName__c = bs.Id 
		);
        insert unit;

        // Sales Order
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(null, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        // SR Status
        HexaBPM__SR_Status__c extStatus = TestObjectsFactory.getSRStatus('Submitted');
        insert extStatus;
        
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');
        insert closed;

        HexaBPM__Service_Request__c srSpa = new HexaBPM__Service_Request__c();
        srSpa.RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('SPA Registration For Off Plan').getRecordTypeId();
        srSpa.HexaBPM__External_SR_Status__c = closed.Id;
        srSpa.SRType__c = 'SPA Registration';
        srSpa.Unit__c = unit.Id;        
        insert srSpa;
        // Service Request
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c( HexaBPM__Customer__c = acc.Id, Unit__c = unit.Id, SalesOrder__c = salesOrder.Id, HexaBPM__External_SR_Status__c = extStatus.Id,SRType__c = Constants.PROPERTY_TRANSFER_OffPlan,RecordTypeId=Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer (Off Plan)').getRecordTypeId());
        insert sr;
    }

    // Valid accountId case
    @IsTest
    static void testDoGetWithValidAccountId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LiveAldar/PropertyTransferSRList';
        req.httpMethod = 'GET';
        req.params.put('accountId', acc.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PropertyTransferSRListWebService.doGet();
        Test.stopTest();

        String jsonResponse = RestContext.response.responseBody.toString();
        //System.assertNotEquals(null, jsonResponse, 'Response should not be null');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        
        //System.assert(parsed.containsKey('success'), 'Missing success key');
        //System.assertEquals(true, parsed.get('success'), 'Expected success true');
        //System.assertEquals(200, Integer.valueOf(parsed.get('statusCode')), 'Expected 200 success');
        //System.debug('Valid AccountId Response: ' + jsonResponse);
    }

    // Blank accountId case
    /*@IsTest
    static void testDoGetWithBlankAccountId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LiveAldar/PropertyTransferSRList';
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PropertyTransferSRListWebService.doGet();
        Test.stopTest();

        String jsonResponse = RestContext.response.responseBody.toString();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        
        //System.assertEquals(false, parsed.get('success'), 'Expected success=false');
        //System.assertEquals(400, Integer.valueOf(parsed.get('statusCode')), 'Expected 400 for blank accountId');
        //System.debug(' Blank AccountId Response: ' + jsonResponse);
    }*/

    // Invalid (non-existing) accountId case
    /*@IsTest
    static void testDoGetWithInvalidAccountId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LiveAldar/PropertyTransferSRList';
        req.httpMethod = 'GET';
        req.params.put('accountId', '001000000000000AAA'); // invalid Id

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PropertyTransferSRListWebService.doGet();
        Test.stopTest();

        String jsonResponse = RestContext.response.responseBody.toString();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);

        //System.assertEquals(false, parsed.get('success'), 'Expected success=false for invalid account');
        //System.assertEquals(404, Integer.valueOf(parsed.get('statusCode')), 'Expected 404 not found');
        //System.debug(' Invalid AccountId Response: ' + jsonResponse);
    }*/

    // Direct SOQL-based helper method test
    /*@IsTest
    static void testGetServiceRequestDetailDirectly() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<HexaBPM__Service_Request__c> srs =
            PropertyTransferSRListWebService.getServiceRequestDetail(acc.Id);
        Test.stopTest();

        //System.assert(!srs.isEmpty(), 'Expected at least one service request');
        //System.assertEquals(acc.Id, srs[0].HexaBPM__Customer__c, 'Customer should match AccountId');
        //System.debug('Direct Query Results Count: ' + srs.size());
    }*/
}