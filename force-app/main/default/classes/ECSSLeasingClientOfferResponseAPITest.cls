@isTest
private class ECSSLeasingClientOfferResponseAPITest {

    @testSetup
    static void setupTestData() {
        
         Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.Emirates_ID__c ='784123123123123';
        insert acc;
        insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );
        Id RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Leasing').getRecordTypeId();
       
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Opportunity' ;
        newOppty.Lead_Type__c ='Lease';
        newOppty.AccountId = acc.id ; 
        newOppty.CloseDate = system.today().adddays(10);
        newOppty.StageName = 'New';
        newOppty.ExpectedEndDate__c=System.Today();
        newOppty.EnquiryCategory__c = 'Aldar Employees';
        newOppty.EnquiryTrigger__c = 'Aldar';
        newOppty.SalesTypefromLead__c = 'Commercial Land';
        newOppty.PropertyUsage__c = 'Land';
        newOppty.Project__c = 'Al Falah';
        newOppty.LeadSource = 'Direct Call';
        newOppty.RecordTypeId =RecordTypeId;
        insert newOppty;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

       Product2 prod = new Product2(
            Name = 'Apartment',
            IsActive = true,
            Family = 'Housing'
        );
        insert prod;
        
        Product2 prod2 = new Product2(
            Name = 'TAF',
            IsActive = true
        );
        insert prod2;
        
        Product2 prod3 = new Product2(
            Name = 'Security Deposit',
            IsActive = true
        );
        insert prod3;
        

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod.Id, UnitPrice = 0, IsActive = true);
        insert pbe;
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod2.Id, UnitPrice = 0, IsActive = true);
        insert pbe2;
        PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod3.Id, UnitPrice = 0, IsActive = true);
        insert pbe3;
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        insert project;

        BuildingSection__c building = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert building;
        List<Asset> AssetsToInsert = new list<Asset>();
        Asset asset1 = new Asset(Name = 'Test Asset1', Status = 'Available', Building__c = building.Id, ECSS_Unit_Type__c = 'Apartment', ExternalIdentifier = 'Test 333');
        AssetsToInsert.add(asset1);
        Asset asset2 = new Asset(Name = 'Test Asset2', Status = 'Available', Building__c = building.Id, ECSS_Unit_Type__c = 'Apartment', ExternalIdentifier = 'test235');
        AssetsToInsert.add(asset2);
         Asset asset3 = new Asset(Name = 'Test Asset3', Status = 'Available', Building__c = building.Id, ECSS_Unit_Type__c = 'Apartment', ExternalIdentifier = 'Test123');
        AssetsToInsert.add(asset3);
        
        Insert AssetsToInsert;
       
        

        // Quote with all collections TRUE
        Quote q1 = new Quote(Name = 'Quote1', OpportunityId = newOppty.Id, ECSS_Payment_terms__c = 24,
                             Status = 'Draft', ECSS_OfferStatus__c = 'Created',
                             ECSS_TAF_Collection__c = true, ECSS_Booking_Fee_Collection__c = true,
                             ECSS_Security_Deposit_Collection__c = true);
        insert q1;

        // Quote with missing collections
        Quote q2 = new Quote(Name = 'Quote2', OpportunityId = newOppty.Id,ECSS_Payment_terms__c = 36,
                             Status = 'Draft', ECSS_OfferStatus__c = 'Created',
                             ECSS_TAF_Collection__c = false, ECSS_Booking_Fee_Collection__c = true,
                             ECSS_Security_Deposit_Collection__c = true);
        insert q2;

        // Quote for rejection scenario
        Quote q3 = new Quote(Name = 'Quote3', OpportunityId = newOppty.Id, ECSS_Payment_terms__c = 12,
                             Status = 'Draft', ECSS_OfferStatus__c = 'Created',
                             ECSS_TAF_Collection__c = true, ECSS_Booking_Fee_Collection__c = true,
                             ECSS_Security_Deposit_Collection__c = true);
        insert q3;

 
     

        // QuoteLineItems
        Insert new List<QuoteLineItem>{
            new QuoteLineItem(PricebookEntryId = pbe.id,Product2Id = prod.Id,QuoteId = q1.Id, Quantity = 1, UnitPrice = 100, Asset__c = asset1.Id),
            new QuoteLineItem(PricebookEntryId = pbe2.id,Product2Id = prod2.Id,QuoteId = q2.Id, Quantity = 1, UnitPrice = 100, Asset__c =  asset2.Id),
            new QuoteLineItem(PricebookEntryId = pbe3.id,Product2Id = prod3.Id,QuoteId = q3.Id, Quantity = 1, UnitPrice = 100, Asset__c =  asset3.Id)
        };
    }

    @isTest
    static void testAcceptedWithAllCollections() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Quote1' LIMIT 1];
        List<ECSSLeasingClientOfferResponseAPI.BookingRequest> requests = new List<ECSSLeasingClientOfferResponseAPI.BookingRequest>{
            new ECSSLeasingClientOfferResponseAPI.BookingRequest()
        };
        requests[0].quoteId = q.Id;
        requests[0].quoteStatus = 'Accepted';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(requests));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<ECSSLeasingClientOfferResponseAPI.BookingResponse> responses = ECSSLeasingClientOfferResponseAPI.doPost();
        Test.stopTest();

        System.assertEquals(true, responses[0].success, 'Should succeed');
        System.assertEquals('Processed', responses[0].message);
        
        // Verify Quote and Asset updates
        Quote updatedQuote = [SELECT Status, ECSS_OfferStatus__c FROM Quote WHERE Id = :q.Id];
         system.debug('Quote2' + updatedQuote);
        System.assertEquals('Booked', updatedQuote.Status);
        System.assertEquals('Released', updatedQuote.ECSS_OfferStatus__c);

        Asset updatedAsset = [SELECT id,Status FROM Asset  where Name = 'Test Asset1'];
        system.debug('Asset1' + updatedAsset);
        System.assertEquals('Booked with Payments', updatedAsset.Status);

        Opportunity updatedOpp = [SELECT StageName FROM Opportunity LIMIT 1];
        System.assertEquals('Booked', updatedOpp.StageName);
    }

    @isTest
    static void testAcceptedWithoutAllCollections() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Quote2' LIMIT 1];
        List<ECSSLeasingClientOfferResponseAPI.BookingRequest> requests = new List<ECSSLeasingClientOfferResponseAPI.BookingRequest>{
            new ECSSLeasingClientOfferResponseAPI.BookingRequest()
        };
        requests[0].quoteId = q.Id;
        requests[0].quoteStatus = 'Accepted';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(requests));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<ECSSLeasingClientOfferResponseAPI.BookingResponse> responses = ECSSLeasingClientOfferResponseAPI.doPost();
        Test.stopTest();

        System.assertEquals(true, responses[0].success);
        
        Quote updatedQuote = [SELECT Status FROM Quote WHERE Id = :q.Id];
         system.debug('Quote1' + updatedQuote);
        System.assertEquals('Accepted', updatedQuote.Status);

        Asset updatedAsset = [SELECT id, Name, Status FROM Asset WHERE Name = 'Test Asset2'];
         system.debug('Asset2' + updatedAsset);
        System.assertEquals('Booked', updatedAsset.Status);
    }

    @isTest
    static void testRejectedScenario() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Quote3' LIMIT 1];
        List<ECSSLeasingClientOfferResponseAPI.BookingRequest> requests = new List<ECSSLeasingClientOfferResponseAPI.BookingRequest>{
            new ECSSLeasingClientOfferResponseAPI.BookingRequest()
        };
        requests[0].quoteId = q.Id;
        requests[0].quoteStatus = 'Rejected';
        requests[0].reason = 'Customer declined';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(requests));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<ECSSLeasingClientOfferResponseAPI.BookingResponse> responses = ECSSLeasingClientOfferResponseAPI.doPost();
        Test.stopTest();

        System.assertEquals(true, responses[0].success);
        
        Quote updatedQuote = [SELECT Status, ECSS_OfferStatus__c, AdditionalName FROM Quote WHERE Id = :q.Id];
         system.debug('Quote3' + updatedQuote);
        System.assertEquals('Rejected', updatedQuote.Status);
        System.assertEquals('Cancelled', updatedQuote.ECSS_OfferStatus__c);
        System.assertEquals('Customer declined', updatedQuote.AdditionalName);

        Asset updatedAsset = [SELECT id, Status, Name FROM Asset WHERE Name = 'Test Asset3'];
         system.debug('Asset3' + updatedAsset);
        System.assertEquals('Available for Lease', updatedAsset.Status);
    }

    @isTest
    static void testInvalidPayload() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('Invalid JSON');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<ECSSLeasingClientOfferResponseAPI.BookingResponse> responses = ECSSLeasingClientOfferResponseAPI.doPost();
        Test.stopTest();

        System.assertEquals(false, responses[0].success);
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingQuoteId() {
        List<ECSSLeasingClientOfferResponseAPI.BookingRequest> requests = new List<ECSSLeasingClientOfferResponseAPI.BookingRequest>{
            new ECSSLeasingClientOfferResponseAPI.BookingRequest()
        };
        requests[0].quoteStatus = 'Accepted';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(requests));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<ECSSLeasingClientOfferResponseAPI.BookingResponse> responses = ECSSLeasingClientOfferResponseAPI.doPost();
        Test.stopTest();

        System.assertEquals(false, responses[0].success);
    }
}