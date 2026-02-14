/**
* MilestoneConfirmationControllerTest
*
* Test class for MilestoneConfirmationController
*/
@isTest
private class MilestoneConfirmationControllerTest{
        @testSetup static void setupData() {
            //offer
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
            Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
            insert orgAcc;
            Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id); 
        
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
            insert projectRecord;
            BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
            insert buildingRecord;
            Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
            insert unitrecord;
    
            PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
            insert paymentPlanRecord;
            list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
            insert installmentLines;
            paymentPlanRecord.IsActive__c =Constants.YES;
            update paymentPlanRecord;
    }
    //Test Installment records, It should create Commission placeholder
    @isTest static void testMilestoneRecords() {
        PaymentInstallments__c piRecord = [select id from PaymentInstallments__c limit 1];
        MilestoneConfirmationController.updateMilestoneDetails(piRecord.id,System.today(),true,'Test');
    }
}