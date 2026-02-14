/**
* OpportunityUnitSearchControllerTest
*
* Test class for OpportunityUnitSearchController
*/
@isTest
private class OpportunityUnitSearchControllerTest{ 
    //Create setupData
    @testSetup static void setupData() {
        //offer
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c=null;
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.IBANNoCorporate__c = '1234567890';
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        
        
        BankVirtualAccounts__c va1 = TestObjectsFactory.getBankVirtualAccounts();
        va1.Project__c = projectRecord.id;
        va1.BufferFlag__c = true;
        va1.Virtual_Account_Type__c = 'Escrow';
        va1.Statusflag__c = 'Available';
        insert va1;
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        paymentPlanRecord.RebatePercentage__c = 2;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id); 
        insert offerLine;
    }
    
     
    //Retrive all the picklist values
    @isTest static void retrivePicklistData() {
        Opportunity optyRecord = [select id from opportunity limit 1];
        map<String,Object> getsObjectType = OpportunityUnitSearchController.getsObjectType(optyRecord.Id);
        System.assertEquals(getsObjectType.containsKey('Opportunity'), true);
        Unit__c unitrecord = [select id from Unit__c limit 1];
        getsObjectType=OpportunityUnitSearchController.getsObjectType(unitrecord.Id);
        System.assertEquals(getsObjectType.containsKey('Unit__c'), true);
        //unit ID
        //OpportunityUnitSearchController.getsObjectType();
        
        list<map<String,string>> unitFinishingValues = OpportunityUnitSearchController.unitFinishingValues();
        unitFinishingValues = OpportunityUnitSearchController.unitFurnishingValues();
        System.assertEquals(unitFinishingValues.isEmpty(), false);
        
        list<map<String,string>> mortgageApplicableValues = OpportunityUnitSearchController.mortgageApplicableValues();
        System.assertEquals(mortgageApplicableValues.isEmpty(), false);
        
        list<map<String,string>> mortgageBankValues = OpportunityUnitSearchController.mortgageBankValues();
        System.assertEquals(mortgageBankValues.isEmpty(), false);
        
        list<map<String,string>> getWinReasonPickList = OpportunityUnitSearchController.getWinReasonPickList();
        System.assertEquals(getWinReasonPickList.isEmpty(), false);
        
        list<map<String,string>> getAllProjects = OpportunityUnitSearchController.getAllProjects();
        System.assertEquals(getAllProjects.isEmpty(), false);
        
        Project__c project = [select id from Project__c limit 1];
        OpportunityUnitSearchController.getProjectToProjectBudget(project.id);
        OpportunityUnitSearchController.getProjectCurrency(project.id);// Added by Akash
        OpportunityUnitSearchController.getProjectCurrencyfromUnit(unitrecord.Id);// Added by Akash
        list<map<String,string>> getAllBuildings = OpportunityUnitSearchController.getAllBuildings(project.id);
        System.assertEquals(getAllBuildings.isEmpty(), false);
        
        BuildingSection__c buildingRecord = [select id from BuildingSection__c limit 1];
        OpportunityUnitSearchController.UnitWrapper unitList = OpportunityUnitSearchController.getUnitDetails(buildingRecord.id);
        System.assertEquals(unitList!=null, true);
        
        OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),'test',project.id);
        
        //OpportunityUnitSearchController.lockUnits(new list<String>{unitRecord.Id});
        unitrecord.Status__c = Constants.UNIT_STATUS_BOOKED;
        unitRecord.LockedBy__c = UserInfo.getUserId();
        update unitrecord;
        OpportunityUnitSearchController.lockUnits(new list<String>{unitRecord.Id});
    }
    //generate basic Sales Order
    @isTest static void basicSalesOrderTest() {
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        unitrecord.LockedBy__c=userInfo.getUserId();
        update unitrecord;
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        
        insert salesOrderRecord;
        OpportunityUnitSearchController.expiredReservation(new list<SalesOrder__c>{salesOrderRecord});
        salesOrderRecord = [select id,Status__c from SalesOrder__c where id = :salesOrderRecord.Id limit 1];
        System.assertEquals(salesOrderRecord.Status__c, Constants.SALES_STATUS_CANCELLED);
        OpportunityUnitSearchController.signatureTypes(salesOrderRecord.Id);// Added by Akash
        try{
            OpportunityUnitSearchController.convertReservation(salesOrderRecord.Id,Opportunity.WinReason__c.getDescribe().getPicklistValues()[0].getValue());
        }catch(Exception e){}
        String message =OpportunityUnitSearchController.validateRegistrationAllowed(optyRecord.Id);
        System.assertEquals(message!='',true);
        try{
        //For Deliveribility off
        OpportunityUnitSearchController.sendAssignRequestEmail(new list<String>{unitrecord.Id},optyRecord.Id);
        }Catch(Exception e){}
        
        map<String,Object> getsObjectType = OpportunityUnitSearchController.getsObjectType(salesOrderRecord.Id);
    }
    //Testing reservation flow
    @isTest static void salesOrderReservationTest() {
        
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        PaymentPlan__c ppRecord= [select id from PaymentPlan__c limit 1];
        OffersPromotions__c offerRecord= [select id from OffersPromotions__c limit 1];
        list<SalesOfferUtility.SaleOfferInputParam> soInputList = new list<SalesOfferUtility.SaleOfferInputParam>();
        SalesOfferUtility.SaleOfferInputParam inputObj = new SalesOfferUtility.SaleOfferInputParam();
        inputObj.unitId=unitrecord.Id;
        inputObj.offerId = offerRecord.Id;
        inputObj.multiPurposeAmountApplicable =true;
        inputObj.selectedPayments = new list<ID>{ppRecord.Id};
        soInputList.add(inputObj);
        
        
            map<id,SalesOfferUtility.SalesOfferDetails> result = OpportunityUnitSearchController.generateSalesOffer(soInputList,optyRecord.Id);
            OpportunityUnitSearchController.generateOfferPDF(soInputList,optyRecord.Id,'T1',null);
            System.assertEquals(result.isEmpty(),false);
        test.startTest();
            OpportunityUnitSearchController.performBudgetCheck(soInputList,optyRecord.Id);
            OpportunityUnitSearchController.reserveUnit(soInputList,optyRecord.Id,'RESERVE',Opportunity.WinReason__c.getDescribe().getPicklistValues()[0].getValue(),'');
        test.stopTest();
    }
    //testing booking flow
    @isTest static void salesOrderBookingTest() {
        Map<Id, Id> unitProjectMap = new Map<Id, Id>();
        Set<String> CorporateIBANSet = new Set<String>();
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id, Project__c, Project__r.IBANNoCorporate__c from Unit__c limit 1];
        unitProjectMap.put(unitrecord.Id, unitrecord.Project__c);
        PaymentPlan__c ppRecord= [select id from PaymentPlan__c limit 1];
        OffersPromotions__c offerRecord= [select id from OffersPromotions__c limit 1];
        list<SalesOfferUtility.SaleOfferInputParam> soInputList = new list<SalesOfferUtility.SaleOfferInputParam>();
        SalesOfferUtility.SaleOfferInputParam inputObj = new SalesOfferUtility.SaleOfferInputParam();
        inputObj.unitId=unitrecord.Id;
        inputObj.offerId = offerRecord.Id;
        inputObj.multiPurposeAmountApplicable =true;
        inputObj.selectedPayments = new list<ID>{ppRecord.Id};
        soInputList.add(inputObj);
        test.startTest();
        map<id,SalesOfferUtility.SalesOfferDetails> result = OpportunityUnitSearchController.generateSalesOffer(soInputList,optyRecord.Id);
        System.assertEquals(result.isEmpty(),false);
        OpportunityUnitSearchController.performBudgetCheck(soInputList,optyRecord.Id);
        CorporateIBANSet.add(unitrecord.Project__r.IBANNoCorporate__c);
        OpportunityUnitSearchController.updateVirtualAccountToUnit(unitProjectMap, CorporateIBANSet);
        OpportunityUnitSearchController.getUserStatus();
        OpportunityUnitSearchController.checkSMAuthorizationForBooking(optyRecord.Id);
        OpportunityUnitSearchController.getUnitToOfferMap(optyRecord.Id);
        test.stopTest();
        try{
        //For Deliveribility off
            OpportunityUnitSearchController.sendSalesOfferPDF(soInputList,optyRecord.Id,'Test',unitrecord.Id);
        }Catch(Exception e){}
        OpportunityUnitSearchController.reserveUnit(soInputList,optyRecord.Id,'BOOKING',Opportunity.WinReason__c.getDescribe().getPicklistValues()[0].getValue(),'');
        
    }
   
     @isTest static void getAssignedUnitsCountForBooking(){
     
             List<Unit__c> unitrecord = [select id from Unit__c];
            List<Id> unitIds = new List<Id>();
            for(Unit__c u : unitrecord ){
            unitIds.add(u.id);
            }
            OpportunityUnitSearchController.getAssignedUnitsCount(unitIds);
            
    } 
     @isTest static void releaseUnitsTest(){
             Opportunity opportunityId = [select id from opportunity limit 1];
              List<Unit__c> unitrecord = [select id from Unit__c];
            List<String> unitsSelected = new List<String>();
            for(Unit__c u : unitrecord ){
            	unitsSelected.add(u.id);
            }
         	test.startTest();
         	try{
                OpportunityUnitSearchController.releaseUnits(unitsSelected,opportunityId.id,'SFDC');
            }catch(exception e){

            }
            test.stopTest();
    }
    
      
}