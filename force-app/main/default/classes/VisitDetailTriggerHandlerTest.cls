/**
* VisitDetailTriggerHandlerTest
*
* Test class for VisitDetailTriggerHandler
*/
@isTest
private class VisitDetailTriggerHandlerTest{

     // create setup data
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
         opp.Contact__c=conRecord.Id;
         insert opp;
         Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
         insert projectRecord;
         
         //Add GTC under project
         Document__c docRecord= new Document__c(Project__c=projectRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
         insert docRecord;
         OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),docRecord.DocumentType__c,docRecord.id);
         
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
         OfferLines__c offerLinesRecord = new OfferLines__c();
         offerLinesRecord.OfferName__c = offerRecord.Id;
         offerLinesRecord.OfferType__c = 'Waiver';
         offerLinesRecord.DiscountType__c = '';
         offerLinesRecord.OfferOn__c = Constants.BUDGET_LINE_AMC;
         offerLinesRecord.OfferValue__c = 3;
         offerLinesRecord.OfferValueType__c = 'Years';
         offerLinesRecord.Nationality__c=null;
         offerLinesRecord.BudgetTaskName__c = Constants.BUDGET_LINE_AMC;
         insert offerLinesRecord;
    }
     @isTest static void validateVisitCreation() {
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
        salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
        salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
        salesOrderRecord.SubStatus__c = Constants.STATUS_APPROVED;
        insert salesOrderRecord;
        VisitDetail__c tempVisit =  new VisitDetail__c(Salesorder__c = salesOrderRecord.id, PlannedDate__C= system.Today());
        insert tempVisit;
        tempVisit.CompletionDate__c =  system.today();
        tempVisit.Completion_Reason__c='Customer not available';
         try{
             update tempVisit;
         }catch(exception e){}
        
     }
}