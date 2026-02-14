@isTest
private class BP_GetOfferDetailsTest {
    @isTest
    private static void testValidRequest() {
      
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.ReferralType__c = Constants.OPPORTUINTY_REFERRAL_STAFF;
        insert opp;
        
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.DigitalSignatureApplied__c = true;
        insert projectRecord;
        
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        buildingRecord.HomeMaintenanceFee__c = 10;
        insert buildingRecord;
        
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingRecord.id);
        unitrecord.AnticipatedServiceCharges__c = 100.00;
        unitrecord.EscalationServiceCharge__c = 100.00;
        insert unitrecord;
        
        InternalCommission__c intCommision = TestObjectsFactory.getInternalCommission();
        intCommision.Project__c = projectRecord.Id;
        insert intCommision;
        
        insert new unitDesign__c(Unit__c = unitrecord.Id, DesignType__c = 'Arabic');
        
        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(opp.id);
        insert bookingMemo;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.BrokerPortalFlag__c = true;
        paymentPlanRecord.StandardFlag__c = 'Yes';
        paymentPlanRecord.BookingMemo__c = bookingMemo.id;
        insert paymentPlanRecord;
        
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;
        
        BuildingSectionMapping__c buildingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id, buildingRecord.Id);
        insert buildingPaymentMapping;
        
        OffersPromotions__c offerRecord = TestObjectsFactory.getOfferPromotion(buildingRecord.Id, projectRecord.Id);
        insert offerRecord;
        
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
        
        OpportunityEOI__c OppEOI = TestObjectsFactory.getOpportunityEOIRecord(opp.id, 'Wire Transfer');
        OppEOI.ComplianceStatus__c = 'Cleared';
        insert OppEOI;
        
        // REST Request
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{' +
            '"opportunityId":"' + opp.Id + '",' +
            '"currentUnit":"' + unitrecord.Id + '",' +
            '"currentOffer":"' + offerRecord.Id + '"}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BP_GetOfferDetails.excute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        System.assert(res.responseBody.toString().contains('Offer Details are fetched'));
        Test.stopTest();
    }
    
    @isTest
    private static void testInvalidRequestBody() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(''); // Empty request body
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BP_GetOfferDetails.excute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        System.assert(res.responseBody.toString().contains('Invalid Request Body'));
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionHandling() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{invalid json'); 
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BP_GetOfferDetails.excute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        System.assert(res.responseBody.toString().contains('Failed to load Offer Details'));
        Test.stopTest();
    }
@isTest
    private static void testValidOfferDetailsRequest() {
        Test.startTest();
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;
        
        String requestBody = '{"opportunityId": "' + opp.Id + '", "currentUnit": "Unit123", "currentOffer": "Offer123", "otherUnits": "Unit456", "selectedPayments": "Pay1|Pay2", "multiPurposeAmount": "true", "selectedDesign": "Design123", "affectionPlan": "Plan123", "PODSelection": "Podium1", "swimmingPoolSelection": "Pool1", "marketingPlan": "MarketingPlan1"}';
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
     
        BP_GetOfferDetails.excute();
        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        
        
        Test.stopTest();
    }
    
    @isTest
    private static void testInvalidRequestBody1() {
        Test.startTest();
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(''); 
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BP_GetOfferDetails.excute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        System.assert(res.responseBody.toString().contains('Invalid Request Body'));
        
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionHandling2() {
        Test.startTest();
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{invalid json');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BP_GetOfferDetails.excute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        System.assert(res.responseBody.toString().contains('Failed to load Offer Details'));
        
        Test.stopTest();
    }
}