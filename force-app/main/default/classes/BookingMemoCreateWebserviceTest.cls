@isTest(SeeAllData=false)
public class BookingMemoCreateWebserviceTest {
    @isTest static void setupMethod() {

        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id);  
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;

        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.LockedBy__c=userInfo.getUserId();
        insert unitrecord;

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;

        List<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;

        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;

        BookingMemo__c memoDetails = new BookingMemo__c();
        memoDetails.RelatedOpportunity__c = opportunityRecord.Id;
        memoDetails.MemoType__c = 'New Sale';
        memoDetails.MemoSubject__c = 'New Sale';
        memoDetails.MemoHeader__c = 'Header';
        memoDetails.SpecialNote__c = 'Note';   

        list<InstallmentLineChanges__c> installmentLinesList = new list<InstallmentLineChanges__c>();

        InstallmentLineChanges__c installmentLineChanges = new InstallmentLineChanges__c();
        installmentLineChanges.Unit__c = unitrecord.Id;
        installmentLineChanges.PaymentPlan__c = paymentPlanRecord.Id;
        installmentLineChanges.ProposedInstallmentDate__c = Date.Today().addDays(-3);
        installmentLineChanges.Description__c = 'Description';
        installmentLineChanges.ProposedInstallmentPercentage__c = 40;
        installmentLineChanges.BrokerPayoutPercentage__c = 40;

        InstallmentLineChanges__c installmentLineChanges1 = new InstallmentLineChanges__c();
        installmentLineChanges1.Unit__c = unitrecord.Id;
        installmentLineChanges1.PaymentPlan__c = paymentPlanRecord.Id;
        installmentLineChanges1.ProposedInstallmentDate__c = Date.Today().addDays(-3);
        installmentLineChanges1.Description__c = 'Description';
        installmentLineChanges1.ProposedInstallmentPercentage__c = 40;
        installmentLineChanges1.BrokerPayoutPercentage__c = 40;

        installmentLinesList.add(installmentLineChanges);
        installmentLinesList.add(installmentLineChanges1);

        BookingMemoCalculateWebservice.MemoCalculationWrapper MemoCalculationWrapper = new BookingMemoCalculateWebservice.MemoCalculationWrapper();
        MemoCalculationWrapper.discountPercentage = 1;
        MemoCalculationWrapper.rebatePercentage = 0.00;
        MemoCalculationWrapper.scWaiverYears = 0;
        MemoCalculationWrapper.pmFeeYear = 0;
        MemoCalculationWrapper.homeMaintenanceYears = 0;
        MemoCalculationWrapper.ADMFeePercentage = 0.00;
        MemoCalculationWrapper.subsidyPercentage = 0.00;
        MemoCalculationWrapper.internalCommissionPercentage = 0.00;
        MemoCalculationWrapper.brokerCommissionPercentage = 0.00;
        MemoCalculationWrapper.selectedVoucher = '';
        MemoCalculationWrapper.selectedMembership = '';
        MemoCalculationWrapper.isValid = true;
    

    BookingMemoCreateWebservice.UnitDetails UnitDetail = new  BookingMemoCreateWebservice.UnitDetails();
    UnitDetail.unitId = unitrecord.Id;
    UnitDetail.installmentLines = installmentLinesList;
    UnitDetail.calculationWrapper = MemoCalculationWrapper;

    List<BookingMemoCreateWebservice.UnitDetails> unitDetails = new List<BookingMemoCreateWebservice.UnitDetails>();
    unitDetails.add(UnitDetail);
    //System.debug('unitDetails '+unitDetails);

    TestObjectsFactory.initializeRestContext(null, '/insert/bookingmemo');        
    TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
    RestContextHandler handler = new RestContextHandler(false);

    Test.startTest();

    BookingMemoCreateWebservice.doPost(memoDetails, unitDetails);

    Test.stopTest();



    }
}