@isTest
private class BP_GetPromotionsTest {
	@testSetup
    static void createData(){
         // Setup test data
        Account acc = TestObjectsFactory.getPersonAccountRecord();
         acc.CustomerSubType__c = 'CORPORATE';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.ReferralType__c = Constants.OPPORTUINTY_REFERRAL_STAFF;
       
        insert opp;

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.DigitalSignatureApplied__c = true;
        insert projectRecord;

        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.Id);
        buildingRecord.HomeMaintenanceFee__c = 10;
        insert buildingRecord;

        Unit__c unitRecord = TestObjectsFactory.getUnitDetail(projectRecord.Id, buildingRecord.Id);
        unitRecord.AnticipatedServiceCharges__c = 100.00;
        unitRecord.EscalationServiceCharge__c = 100.00;
        insert unitRecord;

        BookingMemo__c bookingrecords=TestObjectsFactory.getBookingMemoRecord(opp.id);
        insert bookingrecords;
        OffersPromotions__c offerRecord = TestObjectsFactory.getOfferPromotion(buildingRecord.Id, projectRecord.Id);
        offerRecord.BrokerPortalFlag__c=true;
        offerRecord.BookingMemo__c=bookingrecords.id;
        insert offerRecord;
        
        InternalCommission__c intCommision = TestObjectsFactory.getInternalCommission();
        intCommision.Project__c = projectRecord.Id;
        insert intCommision;
        insert new unitDesign__c (Unit__c= unitrecord.Id,DesignType__c='Arabic');
         
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.BrokerPortalFlag__c = true;
        paymentPlanRecord.StandardFlag__c = 'Yes';
        paymentPlanRecord.BookingMemo__c =  bookingrecords.id;
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        OffersPromotions__c offerRecord2 = TestObjectsFactory.getOfferPromotion(buildingRecord.Id, projectRecord.Id);
        offerRecord2.BookingMemo__c=null;
        insert offerRecord2;
            OpportunityEOI__c OppEOI = TestObjectsFactory.getOpportunityEOIRecord(opp.id,'Wire Transfer');
        
        OppEOI.ComplianceStatus__c= 'Cleared';
        insert OppEOI;
        OffersPromotions__c offerRecord1 = new OffersPromotions__c();
        offerRecord1.Project__c=projectRecord.Id;
        offerRecord1.EndDate__c=System.Today().addDays(5);
        offerRecord1.StartDate__c=System.Today().addDays(-5);
        offerRecord1.ExtendOffer__c=true;
        offerRecord1.OfferName__c='Test Offer';
        offerRecord1.SalesEventCampaignName__c='Test Offer';
        insert offerRecord1;

        
          OfferLines__c offerLine1 = TestObjectsFactory.getOfferLine(offerRecord.Id);
        offerLine1.CustomerType__c = 'DOMESTIC';
        offerLine1.OfferType__c = 'Rebate';
        offerLine1.OfferOn__c = 'Selling Price';
        offerLine1.OfferValueType__c = '%';
        offerLine1.AgentType__c = 'Direct';
        insert offerLine1;
		
        OfferLines__c offerLine2 = TestObjectsFactory.getOfferLine(offerRecord.Id);
        offerLine2.CustomerType__c = 'INTERNATIONAL';
        offerLine2.OfferType__c = 'Rebate';
        offerLine2.OfferOn__c = 'Selling Price';
        offerLine2.OfferValueType__c = '%';
        insert offerLine2;
		
        OfferLines__c offerLine3 = TestObjectsFactory.getOfferLine(offerRecord.Id);
        offerLine3.CustomerType__c = 'DOMESTIC';
        offerLine3.OfferType__c = 'Additional Discount';
        offerLine3.OfferOn__c = 'Selling Price';
        offerLine3.OfferValueType__c = '%';
        insert offerLine3;
        OfferLines__c offerLine4 = TestObjectsFactory.getOfferLine(offerRecord.Id);
    	/*offerLine4.CustomerType__c  = 'CORPORATE';
        offerLine4.OfferType__c =  System.Label.Rebate;
        offerLine4.AgentType__c =System.Label.Direct;
        offerLine4.Nationality__c = 'Afghanistan';
        offerLine4.ResidentStatus__c = 'Non-Resident';
        offerLine4.LeadSource__c = 'Online';
        offerLine4.Unit__c = unitRecord.Id;
        offerLine4.UnitType__c = 'Anchor';
        offerLine4.UnitModel__c = '1BHK';
        offerLine4.LowerBound__c = 200000;
        offerLine4.UpperBound__c = 700000;
        offerLine4.Bulk__c = false;*/
    	insert offerLine4;
        
        System.debug('offerLine1>>'+offerLine1.Id);
        System.debug('offerLine2>>'+offerLine2.Id);
        System.debug('offerLine3>>'+offerLine3.Id);
        System.debug('offerLine4>>'+offerLine4.Id);        
        Lead leadobj = TestObjectsFactory.getLeadRecord(1,'Person');
		leadObj.CustomerSubType__c = 'CORPORATE';
        leadObj.BrokerAgency__c = acc.Id;
        leadobj.Date_of_Birth__c  = System.today().addMonths(-1234);
        insert leadobj;
    }
    
    @isTest
    private static void testValidRequest() {
       Unit__c unitRecord = [SELECT Id From Unit__c limit 1];
       Opportunity opp = [SELECT Id FROM Opportunity limit 1];
        // REST Request
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{' +
            '"unitId":"' + unitRecord.Id + '",' +
            '"opportunityOrLedId":"' + opp.Id + '"}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        BP_GetPromotions.excute();

        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
       
        Test.stopTest();
    }
    
    @isTest
    private static void testValidRequest3() {
       Unit__c unitRecord = [SELECT Id From Unit__c limit 1];
       Opportunity opp = [SELECT Id FROM Opportunity limit 1];
        Lead leadObj = [SELECT Id FROM Lead limit 1];
        // REST Request
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{' +
            '"unitId":"' + unitRecord.Id + '",' +
            '"opportunityOrLedId":"' + leadObj.Id + '"}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        BP_GetPromotions.excute();

        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
       
        Test.stopTest();
    }
    
     @isTest
    private static void testValidRequest2() {
       Unit__c unitRecord = [SELECT Id From Unit__c limit 1];
       Opportunity opp = [SELECT Id FROM Opportunity limit 1];
        opp.AgentType__c = System.Label.Direct;
		update opp;
        BookingMemo__c bm = [SELECT Id FROM BookingMemo__c];
        List<OffersPromotions__c> offerRecordList = new List<OffersPromotions__c>();
        Id offer1Id;
        List<OfferLines__c> offerLineList = new List<OfferLines__c>();
       for(OffersPromotions__c offerRecord:  [SELECT Id,BrokerPortalFlag__c FROM OffersPromotions__c ]){
            offerRecord.BrokerPortalFlag__c = true;
            offerRecord.BookingMemo__c = bm.Id;
           offer1Id = offerRecord.Id;
			offerRecordList.add(offerRecord);
        }
        update offerRecordList;
        OfferLines__c offerLine3 = TestObjectsFactory.getOfferLine(offer1Id);
        offerLine3.CustomerType__c  = 'VVVIP TIER 3';
        offerLine3.OfferType__c =  System.Label.Rebate;
        offerLine3.AgentType__c =System.Label.Direct;
        offerLine3.OfferOn__c = 'Selling Price';
        offerLine3.OfferValueType__c = '%';
        insert offerLine3;
        // REST Request
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{' +
            '"unitId":"' + unitRecord.Id + '",' +
            '"opportunityOrLedId":"' + opp.Id + '"}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        BP_GetPromotions.excute();

        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
       
        Test.stopTest();
    }
  


    @isTest
    private static void testInvalidData() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{' +
                                       '"unitId":"asdfg",' +
                                       '"opportunityOrLedId":"asdfg"}');
        
        
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BP_GetPromotions.excute();
        
        RestResponse res = RestContext.response;
      
        System.assert(res.responseBody.toString().contains('Failed to fetch Offer '));
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

        BP_GetPromotions.excute();

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

        BP_GetPromotions.excute();

        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        System.assert(res.responseBody.toString().contains('Failed to fetch Offer and Promotions'));
        Test.stopTest();
    }
    
    @isTest
    private static void testExceptionHandling2() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = null;
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        BP_GetPromotions.excute();

        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        Test.stopTest();
    }
    
   /* @isTest
    static void testGetApplicableOfferLines() {
        Test.startTest();
 
        List<OfferLines__c> listOffers = [SELECT LowerBound__c,UnitFeatures__c,NumberOfBedrooms__c,UnitModel__c,UnitType__c,Unit__c, DiscountType__c,LeadSource__c,ResidentStatus__c ,Id, CustomerType__c, OfferType__c,Nationality__c, AgentType__c,BudgetTaskName__c FROM OfferLines__c];
        List<Unit__c> allUnitsData = [SELECT Id FROM Unit__c];
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>( [SELECT Id, Name, AccountId,Contact__c,Contact__r.LastName, Account.Name,Account.CustomerSubType__c FROM Opportunity] );
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id FROM Lead]);
 
        Decimal totalOfAllUnitSalesPrice = 10000;
 
        System.assert(listOffers.size() > 0, 'listOffers should not be empty');
        System.assert(allUnitsData.size() > 0, 'allUnitsData should not be empty');
        System.assert(opportunityMap.size() > 0, 'opportunityMap should not be empty');
        System.assert(leadMap.size() > 0, 'leadMap should not be empty');
 
        List<OfferLines__c> allApplicableOfferLines = SalesOfferUtility.getApplicableOfferLines(
            listOffers,
            allUnitsData.isEmpty() ? null : allUnitsData[0],
            opportunityMap.isEmpty() ? new Opportunity() : opportunityMap.values()[0],
            leadMap.isEmpty() ? new Lead() : leadMap.values()[0],
            allUnitsData.size(),
            totalOfAllUnitSalesPrice
        );
 
        System.assertNotEquals(null, allApplicableOfferLines, 'Offer Lines should not be null');
        System.assert(allApplicableOfferLines.size() > 0, 'Offer Lines should not be empty');
 
        Boolean isDirectPresent = false;
        Map<String, String> applicableOffersByCustomerType = new Map<String, String>();
 
        for (OfferLines__c oli : allApplicableOfferLines) {
            if (oli.CustomerType__c != null && oli.OfferType__c != null) {
                applicableOffersByCustomerType.put(oli.OfferType__c, oli.CustomerType__c);
            }
            if (oli.AgentType__c != null && oli.AgentType__c == 'Direct') {
                isDirectPresent = true;
            }
            System.debug('Id that come>>'+oli.Id);
        }
 
        System.assertEquals(true, isDirectPresent, 'Direct Agent Offer should be present');
        System.assert(applicableOffersByCustomerType.containsKey('Rebate'), 'Rebate offer should be present');
 
        Test.stopTest();
    }*/
}