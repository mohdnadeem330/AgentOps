@IsTest
public class Soho_UnitDetailsTest {

    @TestSetup
    static void setupMethod() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        project.EligibleforResale__c  = true;
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today().addDays(7);
        insert unit;
        
        Account seller = TestObjectsFactory.getPersonAccountRecord();
        seller.MaritalStatus__pc = 'Single';
        seller.VisaType__c='Visa not applicable';
        seller.VisaType__pc='Visa not applicable';
        insert seller;

        Account buyer = TestObjectsFactory.getPersonAccountRecord();
        buyer.MaritalStatus__pc = 'Single';
        buyer.VisaType__c='Visa not applicable';
        buyer.VisaType__pc='Visa not applicable';
        insert buyer;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(seller.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;    
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.id, seller.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = seller.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        Opportunity resaleOpp = TestObjectsFactory.getOpportunityRecord(buyer.Id);
        resaleOpp.Name = 'TestResale';
        resaleOpp.OwnerManger__c = UserInfo.getUserId();
        resaleOpp.SalesOrder__c = salesOrder.id;
        resaleOpp.Unit__c = unit.id;
        resaleOpp.Lead_Type__c = 'Resale';
        resaleOpp.Seller__c = seller.Id;
        resaleOpp.RecordTypeId = ResaleConstants.Resale_Opp_RecordTypeId;
        insert resaleOpp;

        Test.startTest();
        Case resaleCase = TestObjectsFactory.getCaseRecord(ResaleConstants.Resale_Case_RecordTypeId, null, salesOrder.Unit__c, 'Phone');
        insert resaleCase;

        Resale_Offers__c ro = new Resale_Offers__c();
        ro.Case__c = resaleCase.Id;
        ro.Sales_Order__c = salesOrder.Id;
        ro.Unit__c = salesOrder.Unit__c;
        ro.Seller_Account__c = salesOrder.Account__c;
        ro.Opportunity__c = resaleOpp.Id;
        ro.Buyer_Account__c = resaleOpp.AccountId;
        ro.SellerEmail__c = 'test@test.com';
        ro.BuyerEmail__c = 'test@test.com';
        ro.Status__c = 'Sent for Approval';
        TriggerHandler.processedIds = new Set<Id>();
        insert ro;

        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', salesOrder.Id);
        Soho_UnitDetails.getOffersAndSalesRepInfo();
        
        User user_RM = TestObjectsFactory.getUserRecord('Resale Relationship Manager', 'RM1');
        insert user_RM;

        resaleCase.Status = ResaleConstants.CASE_AGREEMENT_SIGNATURE_IN_PROCESS;
        resaleCase.OwnerId = user_RM.Id;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;
        Test.stopTest();
    }

    @isTest
    public static void testListingNotInitiated(){
        SalesOrder__c so = [SELECT Id, Unit__c FROM SalesOrder__c LIMIT 1];
        Case resaleCase = [SELECT Id, Status FROM Case WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        
        resaleCase.Status = ResaleConstants.CASE_CANCELLED;
        resaleCase.CancellationReason__c = 'Other';
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;

        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', so.Id);
        Test.startTest();
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }
    
    @isTest
    public static void testListingAgreementPending(){
        SalesOrder__c so = [SELECT Id, Unit__c FROM SalesOrder__c LIMIT 1];
        
        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', so.Id);
        Test.startTest();
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }

    @isTest
    public static void testListingAgreementReady(){
        SalesOrder__c so = [SELECT Id, Unit__c FROM SalesOrder__c LIMIT 1];
        
        String notifyMockRes = '{ "success": true, "statusCode": 201, "statusMessage": "Notification Sent", "mwCorrelationId": "e5aada10-7ed4-11ee-806c-02b45cff0799", "data": "Notification Sent"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));
        
        Document__c listingDoc = [SELECT Id FROM Document__c WHERE DocumentType__c =: ResaleConstants.CASE_LISTING_AGREEMENT_DOCUMENT_TYPE LIMIT 1];
        TestObjectsFactory.createContentDocumentLink(listingDoc.Id);
        
        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', so.Id);
        Test.startTest();
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }

    @isTest
    public static void testPropertyListed(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM SalesOrder__c LIMIT 1];
        Case resaleCase = [SELECT Id, Status FROM Case WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        
        String notifyMockRes = '{ "success": true, "statusCode": 201, "statusMessage": "Notification Sent", "mwCorrelationId": "e5aada10-7ed4-11ee-806c-02b45cff0799", "data": "Notification Sent"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));
        
        Test.startTest();
        Document__c signedLDoc = [SELECT Id FROM Document__c WHERE DocumentType__c =: ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE LIMIT 1];
        TestObjectsFactory.createContentDocumentLink(signedLDoc.Id);

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        resaleCase.Status = ResaleConstants.CASE_PROPERTY_LISTED;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;

        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', so.Id); Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }

    @isTest
    public static void testOfferAccepted(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM SalesOrder__c LIMIT 1];
        Resale_Offers__c ro = [SELECT Id, Status__c, Sales_Order__c FROM Resale_Offers__c LIMIT 1];
        Case resaleCase = [SELECT Id, Status FROM Case WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        
        String notifyMockRes = '{ "success": true, "statusCode": 201, "statusMessage": "Notification Sent", "mwCorrelationId": "e5aada10-7ed4-11ee-806c-02b45cff0799", "data": "Notification Sent"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));

        Test.startTest();
        Document__c signedLDoc = [SELECT Id FROM Document__c WHERE DocumentType__c =: ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE LIMIT 1];
        TestObjectsFactory.createContentDocumentLink(signedLDoc.Id);

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        resaleCase.Status = ResaleConstants.CASE_PROPERTY_LISTED;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;

        ro.Status__c = ResaleConstants.RO_STATUS_ACCEPTED;
        TriggerHandler.processedIds = new Set<Id>();
        update ro;

        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', so.Id);
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }

    @isTest
    public static void testMOUReadyForSignature(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM SalesOrder__c LIMIT 1];
        Opportunity opp = [SELECT Id, StageName, AccountId, Document_Status__c FROM Opportunity WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        Case resaleCase = [SELECT Id, Status FROM Case WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        Resale_Offers__c ro = [SELECT Id, Status__c, Sales_Order__c FROM Resale_Offers__c LIMIT 1];
        
        String notifyMockRes = '{ "success": true, "statusCode": 201, "statusMessage": "Notification Sent", "mwCorrelationId": "e5aada10-7ed4-11ee-806c-02b45cff0799", "data": "Notification Sent"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));

        Document__c signedLDoc = [SELECT Id FROM Document__c WHERE DocumentType__c =: ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE LIMIT 1];
        TestObjectsFactory.createContentDocumentLink(signedLDoc.Id);

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        resaleCase.Status = ResaleConstants.CASE_PROPERTY_LISTED;
        TriggerHandler.processedIds = new Set<Id>();
        
        Test.startTest();
        update resaleCase;

        ro.Status__c = ResaleConstants.RO_STATUS_ACCEPTED;
        TriggerHandler.processedIds = new Set<Id>();
        update ro;

        opp.StageName = ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS;
        TriggerHandler.processedIds = new Set<Id>();
        update opp;

        Document__c MOUDoc = [SELECT Id FROM Document__c WHERE DocumentType__c = 'Listing MOU' LIMIT 1];
        TriggerHandler.processedIds = new Set<Id>();
        TestObjectsFactory.createContentDocumentLink(MOUDoc.Id);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));

        opp.Document_Status__c = ResaleConstants.RESALE_OPP_MOU_SIGNED_BUYER;
        TriggerHandler.processedIds = new Set<Id>();
        update opp;

        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', so.Id);
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }

    @isTest
    public static void testTransferInitiated(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM SalesOrder__c LIMIT 1];
        Opportunity opp = [SELECT Id, StageName, AccountId, Document_Status__c FROM Opportunity WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        Case resaleCase = [SELECT Id, Status FROM Case WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        Resale_Offers__c ro = [SELECT Id, Status__c, Sales_Order__c FROM Resale_Offers__c LIMIT 1];
        
        String notifyMockRes = '{ "success": true, "statusCode": 201, "statusMessage": "Notification Sent", "mwCorrelationId": "e5aada10-7ed4-11ee-806c-02b45cff0799", "data": "Notification Sent"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));

        Document__c signedLDoc = [SELECT Id FROM Document__c WHERE DocumentType__c =: ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE LIMIT 1];
        TestObjectsFactory.createContentDocumentLink(signedLDoc.Id);

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        resaleCase.Status = ResaleConstants.CASE_PROPERTY_LISTED;
        TriggerHandler.processedIds = new Set<Id>();
        
        Test.startTest();
        update resaleCase;

        ro.Status__c = ResaleConstants.RO_STATUS_ACCEPTED;
        TriggerHandler.processedIds = new Set<Id>();
        update ro;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));

        opp.StageName = ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS;
        opp.Document_Status__c = ResaleConstants.RESALE_OPP_MOU_SIGNED_BUYER;
        TriggerHandler.processedIds = new Set<Id>();
        update opp;
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        Document__c signedMDoc = [SELECT Id FROM Document__c WHERE DocumentType__c = 'Signed Listing MOU' LIMIT 1];
        TriggerHandler.processedIds = new Set<Id>();
        TestObjectsFactory.createContentDocumentLink(signedMDoc.Id);

        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', so.Id);
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }

    @isTest
    public static void testTransferCompleted(){
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM SalesOrder__c LIMIT 1];
        Opportunity opp = [SELECT Id, StageName, AccountId, Document_Status__c FROM Opportunity WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        Case resaleCase = [SELECT Id, Status FROM Case WHERE RecordType.DeveloperName = 'Resale' LIMIT 1];
        Resale_Offers__c ro = [SELECT Id, Status__c, Sales_Order__c FROM Resale_Offers__c LIMIT 1];
        
        String notifyMockRes = '{ "success": true, "statusCode": 201, "statusMessage": "Notification Sent", "mwCorrelationId": "e5aada10-7ed4-11ee-806c-02b45cff0799", "data": "Notification Sent"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));

        Document__c signedLDoc = [SELECT Id FROM Document__c WHERE DocumentType__c =: ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE LIMIT 1];
        TestObjectsFactory.createContentDocumentLink(signedLDoc.Id);

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        resaleCase.Status = ResaleConstants.CASE_PROPERTY_LISTED;
        TriggerHandler.processedIds = new Set<Id>();

        Test.startTest();
        update resaleCase;

        ro.Status__c = ResaleConstants.RO_STATUS_ACCEPTED;
        TriggerHandler.processedIds = new Set<Id>();
        update ro;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));

        opp.StageName = ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS;
        opp.Document_Status__c = ResaleConstants.RESALE_OPP_MOU_SIGNED_BUYER;
        TriggerHandler.processedIds = new Set<Id>();
        update opp;
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        Document__c signedMDoc = [SELECT Id FROM Document__c WHERE DocumentType__c = 'Signed Listing MOU' LIMIT 1];
        TriggerHandler.processedIds = new Set<Id>();
        TestObjectsFactory.createContentDocumentLink(signedMDoc.Id);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(notifyMockRes));
        opp.Transferred__c = true;
        TriggerHandler.processedIds = new Set<Id>();
        update opp;
        
        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', so.Id);
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }
    
    @isTest
    public static void testSalesOrderIdNull(){
        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', null);
        Test.startTest();
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }

    @isTest
    public static void testSalesOrderIdError(){
        TestObjectsFactory.initializeRestContext(null, '/getResaleUnitDetails ');
        RestContext.request.params.put('salesOrderId', 'a2A8d000000LfZBEA0');
        Test.startTest();
            Soho_UnitDetails.getOffersAndSalesRepInfo();
        Test.stopTest();
    }
}


/**
Opportunity resaleOpp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
resaleOpp.Name = 'TestResale';
resaleOpp.OwnerManger__c = UserInfo.getUserId();
resaleOpp.SalesOrder__c = salesOrder.id;
resaleOpp.Unit__c = unit.id;
resaleOpp.Lead_Type__c = 'Resale';
resaleCase.OwnerId = user_RM.Id;
insert resaleOpp;
 */