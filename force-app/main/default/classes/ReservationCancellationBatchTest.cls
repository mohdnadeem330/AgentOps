/**
* @File Name         : ReservationCancellationBatchTest.cls
* @Description       : Test class of ReservationCancellationBatch
* @Author            : Rijwan Mohmmed
* @Last Modified On  : September 18, 2025
* @Modification Log  :
*============================================================================== 
* Ver | Date             | Author         | Modification 
*============================================================================== 
* 1.0 | September 18, 2025 | Rijwan Mohmmed | Initial Version 
**/
@isTest(SeeAllData=false)
public class ReservationCancellationBatchTest {
	@testSetup
    static void setupTestData() {
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        account.Sync_with_SFMC__c = false;
        insert account;

        Account relatedAccount = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        relatedAccount.Sync_with_SFMC__c = false;
        insert relatedAccount;
        
        Account relatedAccount1 = TestObjectsFactory.getOrganisationAccountRecord('companyName1', 'registrationNo1');
        relatedAccount1.Sync_with_SFMC__c = false;
        insert relatedAccount1;

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        opp.EmployeeId__c = '123456789';
        opp.EmployeeEmail__c = 'test@aldar.com';
        opp.SaleType__c = 'New Sale';
        insert opp;

        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;

        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        
        BuildingSection__c BuildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        BuildingSection.LaunchStartDate__c = date.today().adddays(-10);
        BuildingSection.LaunchEndDate__c = date.today().adddays(10);
        Insert BuildingSection;

        Document__c gtc = TestObjectsFactory.getProjectDocument(project.Id);
        insert gtc;

        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        unit.BuildingSectionName__c =BuildingSection.Id;
        unit.Name = 'MAYAN-B1-101095';
        unit.AffectionPlan__c = 'www.google.com';
        insert unit;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('Mayan');
        unit1.Project__c = project.Id;
        unit1.BuildingSectionName__c =BuildingSection.Id;
        unit1.Name = 'MAYAN-B1-101096';
        unit1.AffectionPlan__c = 'www.google.com';
        insert unit1;
        
        Document__c doc = TestObjectsFactory.getProjectDocument(project.Id);
        doc.Unit__c = unit.Id;
        doc.DocumentType__c = 'Affection Plan';
        insert doc;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.Classification__c ='30-70';
        insert paymentPlanRecord;
        
        Communication_Preference__c cp = new Communication_Preference__c();
        cp.Account__c=account.Id;
        cp.Status__c = 'Fasttrack Completed';
        cp.FastTrack_Completion_Date_Time__c= System.now();
        insert cp;
        
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(project.id);
        insert buildingRecord;
        
        List<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;
        
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id, buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id, project.Id);
        insert offerRecord;
        
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;

        TestObjectsFactory.createContentDocumentLink(doc.Id);
        Test.startTest();
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit1.Id;
        salesOrder.PaymentPlan__c=paymentPlanRecord.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        salesOrder.NetAmount__c = 100;
        salesOrder.Status__c = 'Reservation in Progress';
        salesOrder.Cancellation_Deadline__c = System.today();
        salesOrder.SalesManager__c = UserInfo.getUserId();
        salesOrder.LineManager__c = UserInfo.getUserId();
        salesOrder.RAcknowledgementReservationAmount__c = 100000;
        salesOrder.Reservation_Agreement_Signed__c = true;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines2 = new List<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines2.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InvoiceNumber__c = '23456',
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrder.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            ));
        }
        
        insert installmentLines2;
        Test.stopTest();
    }
    
    @isTest
    static void unitTest1() {
        Test.startTest();
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        salesOrder.Cancellation_Deadline__c = System.today();
        update salesOrder;
        Database.executeBatch(new ReservationCancellationBatch());
        Test.stopTest();
    }
    
    @isTest
    static void unitTest2() {
        Test.startTest();
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        salesOrder.Cancellation_Deadline__c = System.today();
        salesOrder.Approval_Status__c = 'SO Approved';
        update salesOrder;
        
        salesOrder.Cancellation_Deadline__c = System.today();
        update salesOrder;
        Database.executeBatch(new ReservationCancellationBatch());
        Test.stopTest();
    }
    
    @isTest
    static void unitTest3() {
        Test.startTest();
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        salesOrder.Cancellation_Deadline__c = System.today().addDays(1);
        salesOrder.Approval_Status__c = 'SO Approved';
        update salesOrder;
        
        salesOrder.Cancellation_Deadline__c = System.today().addDays(1);
        update salesOrder;
        Database.executeBatch(new ReservationCancellationBatch());
        Test.stopTest();
    }
    
    @isTest
    static void unitTest4() {
        Test.startTest();
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        salesOrder.Cancellation_Deadline__c = System.today();
        salesOrder.Approval_Status__c = 'LM Approved';
        update salesOrder;
        
        salesOrder.Cancellation_Deadline__c = System.today();
        update salesOrder;
        Database.executeBatch(new ReservationCancellationBatch());
        Test.stopTest();
    }
    
    @isTest
    static void unitTest5() {
        Test.startTest();
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        salesOrder.Cancellation_Deadline__c = System.today();
        salesOrder.Approval_Status__c = 'LM Approved';
        salesOrder.Reservation_Cancellation_Stage__c = 'Extension Granted by LM';
        update salesOrder; 
        ReservationCancellationBatch.submitApprovalToSalesOps(salesOrder);
        ReservationCancellationBatch.unlockRecord(salesOrder.Id);
        Test.stopTest();
    }
    
    @isTest
    static void unitTest6() {
        Test.startTest();
        SalesOrder__c salesOrder = [SELECT Id, SalesManager__c, OwnerId FROM SalesOrder__c LIMIT 1];
        salesOrder.Cancellation_Deadline__c = System.today();
        update salesOrder;     
        User u1 = [SELECT id from User WHERE Id =:salesOrder.OwnerId LIMIT 1];
        System.runas(u1) {
        
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(salesOrder.Id);
            req.setProcessDefinitionNameOrId('Reservation_Cancellation_Line_Manager');
            req.setComments('Auto-submitted for Reservation_Cancellation_Line_Manager');        
            Approval.ProcessResult result = Approval.process(req);
            ReservationCancellationBatch.unlockRecord(salesOrder.Id);
        }

		salesOrder.Approval_Status__c = 'Pending LM';
        salesOrder.Cancellation_Deadline__c = System.today().addDays(-1);
        update salesOrder;
        
        Database.executeBatch(new ReservationCancellationBatch());
        Test.stopTest();
    }
}