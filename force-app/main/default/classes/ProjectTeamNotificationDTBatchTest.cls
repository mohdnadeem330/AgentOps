/**
* ProjectTeamNotificationDTBatchTest
*
* Test class for ProjectTeamNotificationDTBatch
*/
@isTest
private class ProjectTeamNotificationDTBatchTest{
    //Creating Setup data for testing
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
            BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
            insert buldingPaymentMapping;    
    }
    @isTest static void testACDNotification() {
        PaymentInstallments__c tempeRec = [select id from PaymentInstallments__c limit 1];
        tempeRec.InstallmentDate__c = System.today().addDays(Integer.valueOf(System.Label.ProjectTeamNotificationFrequencyDT.split(',')[0]));
        update tempeRec;
        
        Test.startTest();
        System.schedule('ProjectTeamNotificationDTBatch-Test', '0 0 * * * ?', new ProjectTeamNotificationDTBatch() );
        Test.stopTest();
    }
    @isTest static void testACDEscNotification() {
        PaymentInstallments__c tempeRec = [select id from PaymentInstallments__c limit 1];
        tempeRec.InstallmentDate__c = System.today().addDays(Integer.valueOf(System.Label.ProjectTeamEscalationNotificationFrequencyDT.split(',')[0]));
        update tempeRec;
        
        Test.startTest();
        System.schedule('ProjectTeamNotificationDTBatch-Test', '0 0 * * * ?', new ProjectTeamNotificationDTBatch() );
        Test.stopTest();
    }
    
}