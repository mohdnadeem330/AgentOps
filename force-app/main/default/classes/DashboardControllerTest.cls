/**
* DashboardControllerTest
*
* Test class for DashboardController
*/
@isTest
private class DashboardControllerTest{
    //Creating support data for dashboard
     @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
         
         Account acc = TestObjectsFactory.getPersonAccountRecord();
         insert acc;
         
         Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
         opp.BrokerAgentContact__c=conRecord.Id;
         opp.BrokerAgencyAccount__c =orgAcc.Id;
         opp.EnquiryTrigger__c=null;
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
         
         OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
         insert offerRecord;
         OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
         insert offerLine;
    }
    //Fetching dashboard data
    @isTest static void testDashBoardData() {
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        //salesOrderRecord.Project__c=projectRecord.Id;
        salesOrderRecord.SellingPrice__c=1000000;
        salesOrderRecord.ExternalCommissionAmount__c=10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c=optyRecord.AccountId;
        insert salesOrderRecord;
        
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,AccountId from User where contactId = :conRecord.Id limit 1];
        System.runAs(userRecord) {
            list<Communication__c> communicationRecords = DashboardController.getMyCommunication();
            System.assertEquals(communicationRecords.isEmpty(),true);
            DashboardController.getAgentDashboardDetails(System.today(), System.today().addDays(5));
            DashboardController.getAgencyDashboardDetails(userRecord.AccountId, System.today().addDays(-5),System.today().addDays(5));
        }
        
    }
}