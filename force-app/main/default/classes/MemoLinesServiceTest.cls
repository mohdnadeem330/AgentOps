@isTest(SeeAllData=false)
public class MemoLinesServiceTest {
    @isTest static void setupMethod() {

        Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
        insert orgAccount;

        Contact contactRecord = TestObjectsFactory.contactDataSetup(orgAccount.id);
        //insert contactRecord;

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAccount.Id);
        insert opportunityRecord;

        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(opportunityRecord.Id);
        insert bookingMemo;

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.Id, buildingSection.Id);
        insert unit;

        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAccount.Id);
        salesOrderRecord.unit__c = unit.Id;
        salesOrderRecord.Contact__c = contactRecord.Id;
        insert salesOrderRecord;

        PaymentPlan__c existingPaymentPlan = TestObjectsFactory.getPaymentPlanRecord();
        insert existingPaymentPlan;

        OffersPromotions__c existingOffer = TestObjectsFactory.getOfferPromotion(buildingSection.Id, projectRecord.Id);
        insert existingOffer;


        String sCWaiverYears = '12';
        String pMFeeYears = '1';
        String homeMaintenanceYears = '1';
        String subsidyPercentage = '1';
        String discountPercentage = '1';
        String rebatePercentage = '1';
        String intCommissionPercentage = '1';
        String aDMFeePercentage = '1';
        String brokerCommissionPercentage = '1';
        String additionalDiscountPercentage = '1';
        String voucherName = 'Voucher';
        String voucherAmount = '1';
        String membershipType = 'Membership';
        String membershipAmount = '1';

        Test.startTest();

        MemoLines__c memoLine = MemoLinesService.createMemoLines(existingOffer.Id, existingPaymentPlan.Id, unit.Id, bookingMemo.Id, sCWaiverYears, pMFeeYears, homeMaintenanceYears, '100', '100', subsidyPercentage, discountPercentage, rebatePercentage, aDMFeePercentage, intCommissionPercentage, brokerCommissionPercentage, additionalDiscountPercentage, voucherAmount, voucherName, membershipType, membershipAmount);
        List<MemoLines__c> memoList = new List<MemoLines__c>();
        memoList.add(memoLine);
        
        MemoLinesService.insertMemoLines(memoList,new List<InstallmentLineChanges__c>());

        List<MemoLines__c> MemoLinesByBookinMemoId= MemoLinesService.getMemoLinesByBookinMemoId(bookingMemo.Id);

        Test.stopTest();

    }
}