/* 
* SalesOfferUtilityTest
*
* Test class for SalesOfferUtility
*/
@isTest
private class SalesOfferUtilityTest{
    @testSetup static void setupData() {
        //Create Setupdata
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.ReferralType__c= Constants.OPPORTUINTY_REFERRAL_STAFF;
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.DigitalSignatureApplied__c = true;
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        buildingRecord.HomeMaintenanceFee__c = 10;
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.AnticipatedServiceCharges__c = 100.00;
        unitrecord.EscalationServiceCharge__c=100.00;
        insert unitrecord;
        InternalCommission__c intCommision = TestObjectsFactory.getInternalCommission();
        intCommision.Project__c = projectRecord.Id;
        insert intCommision;
        insert new unitDesign__c (Unit__c= unitrecord.Id,DesignType__c='Arabic');
        
         BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(opp.id);
        insert bookingMemo;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.BrokerPortalFlag__c = true;
        paymentPlanRecord.StandardFlag__c = 'Yes';
        paymentPlanRecord.BookingMemo__c =  bookingMemo.id;
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
        
        OpportunityEOI__c OppEOI = TestObjectsFactory.getOpportunityEOIRecord(opp.id,'Wire Transfer');
        
        OppEOI.ComplianceStatus__c= 'Cleared';
        insert OppEOI;
        
    }
    //Retrive SalesOffer
    @isTest static void retriveSalesOfferTest() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Account aaa = [select id from Account limit 1];
        test.startTest();
        // Create Lead From Account Record
        Lead leadRecord = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRecord.ExistingAccount__c = aaa.Id;
        leadRecord.IsCreateFromExistingAccount__c = true;
        insert leadRecord;
        test.stopTest();
        
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        PaymentPlan__c ppRecord= [select id from PaymentPlan__c limit 1];
        OffersPromotions__c offerRecord= [select id from OffersPromotions__c limit 1];
        list<SalesOfferUtility.SaleOfferInputParam> soInputList = new list<SalesOfferUtility.SaleOfferInputParam>();
        SalesOfferUtility.SaleOfferInputParam inputObj = new SalesOfferUtility.SaleOfferInputParam();
        inputObj.unitId=unitrecord.Id;
        inputObj.offerId = offerRecord.Id;
        inputObj.multiPurposeAmountApplicable =true;
        inputObj.paymentMethod ='';
        inputObj.amount =0;
        inputObj.amountType ='';
        inputObj.unitFinishes ='Cool';
        inputObj.mortgageBank =SalesOrder__c.mortgageBank__c.getDescribe().getPicklistValues()[0].getValue();
        inputObj.mortgageApplicable =true;
        inputObj.selectedPayments = new list<ID>{ppRecord.Id};
            inputObj.podiumSelection = 'Kitchen';
        
        soInputList.add(inputObj);
        map<id,SalesOfferUtility.SalesOfferDetails> result = OpportunityUnitSearchController.generateSalesOffer(soInputList,optyRecord.Id);
        System.assertEquals(result.isEmpty(),false);
        
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        offerLine.LowerBound__c=1;
        offerLine.UpperBound__c=2;
        insert offerLine;
        Unit_Add_on__c unitAddon1 = new Unit_Add_on__c(Unit__c = unitRecord.Id, Name_of_Add_on__c = 'Basement Options',isactive__C = True, SubName_of_AddOns__c = 'Option 1');
        Unit_Add_on__c unitAddon2 = new Unit_Add_on__c(Unit__c = unitRecord.Id, Name_of_Add_on__c = 'Landscape Options',isactive__C = True, SubName_of_AddOns__c = 'Linear');
        insert new List<Unit_Add_on__c> { unitAddon1, unitAddon2 };
        SalesOfferUtility.UnitAddonWrapperdata unitAddOnWrap = new SalesOfferUtility.UnitAddonWrapperdata();
        unitAddOnWrap.key = unitAddon1.Id;
        unitAddOnWrap.value = unitAddon1.Name_of_Add_on__c;
        inputObj.UnitAddonList = new List<SalesOfferUtility.UnitAddonWrapperdata>{unitAddOnWrap};
        result = OpportunityUnitSearchController.generateSalesOffer(soInputList,optyRecord.Id);
        
        SalesOfferUtility.overrideUnitDetails(new Unit__C(), new UnitDesign__c());
        SalesOfferUtility.PaymentPlanWrapper pr = new SalesOfferUtility.PaymentPlanWrapper();
        pr.serviceChargeAmount = 11;
        pr.serviceChargeWaivedYears = 11;
        pr.homeMaintenanceWaiverFee = 11;
        pr.externalComissionAmount= 11;
        pr.mortgageSubsidy= 11;
        pr.darnaAmount= 11;
        pr.internalComissionAmount= 11;
        pr.internalStaffComissionAmount= 11;
        pr.internalReferralComissionAmount= 11;
        
        
    }
    //Retrive SalesOffer
    @isTest static void retriveSalesOfferLeadTest() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetBitlyShortenURLSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Account aaa = [select id from Account limit 1];
        test.startTest();
        // Create Lead From Account Record
        Lead leadRecord = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRecord.ExistingAccount__c = aaa.Id;
        leadRecord.IsCreateFromExistingAccount__c = true;
        insert leadRecord;
        test.stopTest();
        
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        PaymentPlan__c ppRecord= [select id from PaymentPlan__c limit 1];
        OffersPromotions__c offerRecord= [select id from OffersPromotions__c limit 1];
        list<SalesOfferUtility.SaleOfferInputParam> soInputList = new list<SalesOfferUtility.SaleOfferInputParam>();
        SalesOfferUtility.SaleOfferInputParam inputObj = new SalesOfferUtility.SaleOfferInputParam();
        inputObj.unitId=unitrecord.Id;
        inputObj.offerId = offerRecord.Id;
        inputObj.multiPurposeAmountApplicable =true;
        inputObj.paymentMethod ='';
        inputObj.amount =0;
        inputObj.amountType ='';
        inputObj.unitFinishes ='Cool';
        inputObj.mortgageBank =SalesOrder__c.mortgageBank__c.getDescribe().getPicklistValues()[0].getValue();
        inputObj.mortgageApplicable =true;
        inputObj.selectedPayments = new list<ID>{ppRecord.Id};
            inputObj.podiumSelection = 'Kitchen';
        soInputList.add(inputObj);
        map<id,SalesOfferUtility.SalesOfferDetails> result = OpportunityUnitSearchController.generateSalesOffer(soInputList,leadRecord.Id);
        System.assertEquals(result.isEmpty(),false);
        //result[0].
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        offerLine.LowerBound__c=1;
        offerLine.UpperBound__c=2;
        insert offerLine;
        result = OpportunityUnitSearchController.generateSalesOffer(soInputList,optyRecord.Id);
        
    }
}