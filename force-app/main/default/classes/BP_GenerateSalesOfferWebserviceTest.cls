@IsTest
private class BP_GenerateSalesOfferWebserviceTest {
    
    @IsTest
    static void testExecute_validRequest() {
        
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(Name='Test Opportunity', AccountId=acc.Id, StageName='Prospecting', CloseDate=System.today());
        insert opp;
        
        Project__c newProject = new Project__c();
        newProject.Name = 'Mayan';
        newProject.ProjectCode__c = 'MAYAN';
        newProject.BusinessUnitId__c='1234';
        
        insert newProject;
        
        BuildingSection__c buildingRecord = new BuildingSection__c();
        buildingRecord.Name = 'Building 1';
        buildingRecord.BuildingSectionCode__c = 'Building 1';
        buildingRecord.Project__c = newProject.id;
        buildingRecord.StartDate__c = Date.today();
        buildingRecord.EndDate__c = Date.today().addMonths(6);
        buildingRecord.CompletionCertificateDate__c = Date.today().addMonths(8);
        buildingRecord.EligibileforMultiPurposeRoom__c = true;
        buildingRecord.PropertyManagementFee__c = 10; //added/updated on 26Dec
        buildingRecord.EligibleforUnitFinishes__c = true;
        buildingRecord.RecordTypeId = Schema.SObjectType.BuildingSection__c.getRecordTypeInfosByName().get('Building').getRecordTypeId();
        insert buildingRecord;
        
        Unit__c unitRecord = new Unit__c();
        unitRecord.RecordTypeId = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Unit').getRecordTypeId();
        unitRecord.CurrencyIsoCode = 'AED';
        unitRecord.Name = newProject.Id + 'MAYAN-B1-1001'; // Corrected this line
        unitRecord.ShortNumber__c = '1001';
        unitRecord.Project__c = newProject.id;
        unitRecord.BuildingSectionName__c = buildingRecord.id;
        unitRecord.Status__c = Constants.UNIT_STATUS_AVAILABLE;
        unitRecord.UnitModel__c = '1BHK';
        unitRecord.SellingPrice__c = 52600000;
        unitRecord.FloorNumber__c = '01';
        unitRecord.UnitType__c = 'Apartment';
        unitRecord.NumberOfBedrooms__c = '1';
        unitRecord.StartDate__c = Date.today();
        unitRecord.Mandatory_Premium__c = True;
        unitRecord.Mandatory_POD__c = False;
        unitRecord.PODMultiPurposeRoomPrice__c = 100;
        unitRecord.PODkitchenPrice__c = 100;
        unitRecord.EndDate__c = Date.today().addMonths(6);
        unitRecord.MultiPurposeAmount__c = 1000;
        unitRecord.PropertyStatus__c = 'Sale';
        unitRecord.AnticipatedServiceCharges__c = 1;
        
        insert unitRecord;
        
        OffersPromotions__c offerRecord = new OffersPromotions__c();
        offerRecord.BuildingSectionName__c = buildingRecord.id;
        offerRecord.Project__c = newProject.id;
        offerRecord.EndDate__c = System.Today().addDays(5);
        offerRecord.StartDate__c = System.Today().addDays(-5);
        offerRecord.ExtendOffer__c = true;
        offerRecord.SalesEventCampaignName__c='Test Offer';
        offerRecord.OfferName__c = 'Test Offer';
        
        insert offerRecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.BrokerPortalFlag__c = true;
        paymentPlanRecord.StandardFlag__c = 'Yes';
        insert paymentPlanRecord;
        
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        
        // Prepare request body with valid data
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('opportunityId', opp.Id);
        requestBody.put('CustomerName', 'Test Customer');
        requestBody.put('singleUnitId', unitRecord.id);
        requestBody.put('MarketingPlan', true);
        requestBody.put('SaleOfferInputParam', new List<Map<String, Object>>{
            new Map<String, Object> {
                'unitId' => unitRecord.id,
                    'offerId' => offerRecord.id,
                    'amount' => 100.0,
                    'amountType' => 'USD', 
                    'selectedPayments'=> 
                    new List<Map<String, Object>> {
                        new Map<String, Object> {
                            'paymentId' => paymentPlanRecord.id 
                                }
                    }
            }
        });
        
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/generateSalesOffer';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        system.debug('Request body::'+JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_GenerateSalesOfferWebservice.excute();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
       // System.assertEquals(true, response.get('success'), 'The response should indicate success');
       // System.assertEquals('Offer sent', response.get('message'), 'The success message should match');
    }
    
    @IsTest
    static void testExecute_invalidRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/generateSalesOffer';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(''); // Empty body
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_GenerateSalesOfferWebservice.excute();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        System.assertEquals(false, response.get('success'), 'The response should indicate failure');
        System.assertEquals('Invalid Request Body', response.get('message'), 'The failure message should match');
    }
    
    @IsTest
    static void testExecute_missingFieldInRequest() {
        // Missing CustomerName in request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('opportunityId', 'InvalidOpportunityId');
        requestBody.put('singleUnitId', 'unit123');
        requestBody.put('MarketingPlan', true);
        requestBody.put('SaleOfferInputParam', new List<Map<String, Object>>{
            new Map<String, Object> {
                'unitId' => 'unit123',
                    'offerId' => 'unit1234',
                    'amount' => 100.0,
                    'amountType' => 'USD'
                    }
        });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/generateSalesOffer';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_GenerateSalesOfferWebservice.excute();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
    }
    
    @IsTest
    static void testExecute_withExceptionInProcessRequest() {
        // Triggering an exception in processRequest method
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('opportunityId', 'InvalidOpportunityId'); // Invalid Opportunity ID
        requestBody.put('CustomerName', 'Test Customer');
        requestBody.put('singleUnitId', 'unit123');
        requestBody.put('MarketingPlan', true);
        requestBody.put('SaleOfferInputParam', new List<Map<String, Object>>{
            new Map<String, Object> {
                'unitId' => 'unit123',
                    'offerId' => 'unit1234',
                    'amount' => 100.0,
                    'amountType' => 'USD'
                    }
        });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/generateSalesOffer';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_GenerateSalesOfferWebservice.excute();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
    }
    
    @IsTest
    static void testExecute_withExceptionInSendSalesOfferPDF() {
        // Simulate an exception in sendSalesOfferPDF method
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('opportunityId', 'ValidOpportunityId'); // Valid Opportunity ID
        requestBody.put('CustomerName', 'Test Customer');
        requestBody.put('singleUnitId', 'unit123');
        requestBody.put('MarketingPlan', true);
        requestBody.put('SaleOfferInputParam', new List<Map<String, Object>>{
            new Map<String, Object> {
                'unitId' => 'unit123',
                    'offerId' => 'unit1234',
                    'amount' => 100.0,
                    'amountType' => 'USD'
                    }
        });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/generateSalesOffer';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BP_GenerateSalesOfferWebservice.excute();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        
    }
}