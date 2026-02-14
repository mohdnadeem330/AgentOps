/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for verify the booking, budget etc.
*/
@isTest
private class BookingVerificationWebserviceTest {    

    /*
    * Scenario 1 : Verify Booking Details
    */
    static testmethod void testBookingVerificationService() {
        Test.startTest();
        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);
        TestObjectsFactory.initializeRestContext(null, '/booking/verification');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        BookingVerificationWebservice.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 2 : Unit Unassigned
    */
    static testmethod void testUnavailableUnit() {

        Test.startTest();
        User userRec = TestObjectsFactory.getUserRecord('Sales Manager','book.assignSM');
        insert userRec ; 

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences-R1');
        unitRecord.Name = 'Lourve Residences-R21';
        insert unitRecord;

        Unit__c unitRecordOther = TestObjectsFactory.unitDataSetup('Lourve Residences-R2');
        unitRecordOther.Name = 'Lourve Residences-R22';
        insert unitRecordOther;

        unitRecordOther.AssignedToUser__c = userRec.Id ;
        update unitRecordOther ;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);

        System.runAs(userRec){    
            TestObjectsFactory.initializeRestContext(null, '/booking/verification');
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
            BookingVerificationWebservice.doPost();
        }
        Test.stopTest();
    }

    /*
    * Scenario 3 : Locked by other user
    */
    static testmethod void unitBookedAlready() {
        Test.startTest();
        User userRec = TestObjectsFactory.getUserRecord('Sales Manager','book.assignSM');
        insert userRec ; 

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        TriggerHandler.processedIds = new Set<Id>();
        unitRecord.AssignedToUser__c = userRec.Id ;
        update unitRecord ;

        unitRecord.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS ;
        unitRecord.LockedBy__c = UserInfo.getUserId();
        update unitRecord ;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);
        System.runAs(userRec){    
            TestObjectsFactory.initializeRestContext(null, '/booking/verification');
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
            BookingVerificationWebservice.doPost();
        }
        Test.stopTest();
    }

    /*
    * Scenario 4 : Unit Timer Expired
    */
    static testmethod void unitTimerExpired() {
        Test.startTest();

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        unitRecord.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS ;
        unitRecord.LockedBy__c = UserInfo.getUserId();
        unitRecord.LockExpiryTime__c = system.now().addMinutes(-30);
        update unitRecord ;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);  
        TestObjectsFactory.initializeRestContext(null, '/booking/verification');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        BookingVerificationWebservice.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 5 : Budget Verification Check
    */
    static testmethod void budgetCheckVerification() {
        Test.startTest();

        ProjectBudget__c budgetRecord = TestObjectsFactory.getProjectBudget();
        insert budgetRecord ;

        List<BudgetLines__c> budgetLinesList = new  List<BudgetLines__c>();
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Mortgage Subsidy','7.73.770',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('ADM Fee','7.73.735',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Darna Loyalty','7.73.751',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Other Sales Support','7.73.739',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Home Maintenance','7.73.741',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('SC Waiver','7.73.736',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Sales Comm.-Internal','7.73.731',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Forfeited Cash','7.73.761',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines('Sales Comm.-External','7.73.732',budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines(CONSTANTS.BUDGET_TASK_PAYMENT_PROVISION,CONSTANTS.BUDGET_TASK_PAYMENT_PROVISION,budgetRecord.Id,Constants.BUDGET_SALES_SUPPORT_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines(CONSTANTS.BUDGET_LINE_DISCOUNT,'7.73.737',budgetRecord.Id,Constants.BUDGET_DISCOUNT_REBATE_BUCKET));
        budgetLinesList.add(TestObjectsFactory.getProjectBudgetLines(CONSTANTS.BUDGET_LINE_REBATE,'7.73.738',budgetRecord.Id,Constants.BUDGET_DISCOUNT_REBATE_BUCKET));
        insert budgetLinesList ;

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        Project__c projectRec = new Project__c();
        projectRec.Id = unitRecord.Project__c ;
        projectRec.ProjectBudget__c = budgetRecord.Id ; 
        update projectRec ; 

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);  
        SalesOfferUtility.SaleOfferInputParam salesOfferInput = bookingdetail.inputWrapperList[0] ;

        PaymentPlan__c paymentPlanRecord = new PaymentPlan__c();
        paymentPlanRecord.Id = salesOfferInput.selectedPayments[0];
        paymentPlanRecord.PaymentPlanDiscount__c = 75 ;
        update paymentPlanRecord;
        
        TestObjectsFactory.initializeRestContext(null, '/booking/verification');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        BookingVerificationWebservice.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 6 : Multiple Units Booked
    */
    static testmethod void multipleUnitsBooked() {
        Test.startTest();

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        unitRecord.Name = 'Lourve Residences-R13';
        insert unitRecord;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);  
        SalesOfferUtility.SaleOfferInputParam salesOfferInput = bookingdetail.inputWrapperList[0] ;

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        List<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;
        
        salesOfferInput.selectedPayments.add(paymentPlanRecord.Id);

        TestObjectsFactory.initializeRestContext(null, '/booking/verification');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        BookingVerificationWebservice.doPost();
        Test.stopTest();
    }

    /*
    * Scenario 7 : Unit is booked
    */
    static testmethod void unitBooked() {
        Test.startTest();

        Unit__c unitRecord = TestObjectsFactory.unitDataSetup('Lourve Residences');
        insert unitRecord;

        unitRecord.Status__c = Constants.UNIT_STATUS_BOOKED ;
        unitRecord.LockedBy__c = UserInfo.getUserId();
        update unitRecord ;

        BookingDetailModel bookingdetail = TestObjectsFactory.getBookingModel(unitRecord);  
        TestObjectsFactory.initializeRestContext(null, '/booking/verification');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(bookingdetail));
        BookingVerificationWebservice.doPost();
        Test.stopTest();
    }

    


}