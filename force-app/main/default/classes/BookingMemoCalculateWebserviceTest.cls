@isTest(SeeAllData=false)
public class BookingMemoCalculateWebserviceTest {
    @isTest static void setupMethod() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.LockedBy__c=userInfo.getUserId();
        insert unitrecord;
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(unitRecord.BuildingSectionName__c,unitRecord.Project__c);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;

        BookingMemoCalculateWebservice.MemoCalculationWrapper calculationWrapper = new BookingMemoCalculateWebservice.MemoCalculationWrapper();
        calculationWrapper.discountPercentage = 1;
        calculationWrapper.rebatePercentage = 0.00;
        calculationWrapper.scWaiverYears = 0;
        calculationWrapper.pmFeeYear = 0;
        calculationWrapper.homeMaintenanceYears = 0;
        calculationWrapper.ADMFeePercentage = 0.00;
        calculationWrapper.subsidyPercentage = 0.00;
        calculationWrapper.internalCommissionPercentage = 0.00;
        calculationWrapper.brokerCommissionPercentage = 0.00;
        calculationWrapper.selectedVoucher = '';
        calculationWrapper.selectedMembership = '';
        //MemoCalculationWrapper.isValid = true;
        
        String offerID;
        String paymentPlanId;
        String unitId = unitrecord.Id;
        
		BookingMemoCalculateWebservice.MemoCalculationInput memoCalculationInput = new BookingMemoCalculateWebservice.MemoCalculationInput();
        memoCalculationInput.unitId = unitId;
        memoCalculationInput.offerID = offerID;
        memoCalculationInput.paymentPlanId = paymentPlanId;
        memoCalculationInput.calculationWrapper = calculationWrapper;
        memoCalculationInput.offerChanged = false;
        
        BookingMemoCalculateWebservice.MemoCalculationInput memoCalculationInput1 = new BookingMemoCalculateWebservice.MemoCalculationInput();
        memoCalculationInput1.unitId = unitId;
        memoCalculationInput1.offerID = offerLine.Id;
        memoCalculationInput1.paymentPlanId = paymentPlanId;
        memoCalculationInput1.calculationWrapper = calculationWrapper;
        memoCalculationInput1.offerChanged = true;
        
        List<BookingMemoCalculateWebservice.MemoCalculationInput> memoCalculationInputList = new List<BookingMemoCalculateWebservice.MemoCalculationInput>();
        memoCalculationInputList.add(memoCalculationInput);
        memoCalculationInputList.add(memoCalculationInput1);
        

    TestObjectsFactory.initializeRestContext(null, '/query/bookingmemocalculate');        
    TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
    RestContextHandler handler = new RestContextHandler(false);

    

    Test.startTest();

    BookingMemoCalculateWebservice.doPost(memoCalculationInputList, opp.Id);

    Test.stopTest();

    }
}