/* 
* SalesOrderSubStatusControllerTest
*
* Test class for SalesOrderSubStatusController
*/
@isTest
public class SalesOrderSubStatusControllerTest {
    //Create test data
     @testSetup static void setupData() {
         Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
    
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
           
            OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
            insert offerRecord;
            OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
            insert offerLine;
     }
     //Check the substatus utility
     @isTest static void subStatus() {
         Account accRecord = [select id from Account limit 1];
         Opportunity optyRecord = [select id from opportunity limit 1];
         Unit__c unitrecord = [select id from Unit__c limit 1];
         SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
         salesOrderRecord.Unit__c=unitrecord.Id;
         salesOrderRecord.SubStatus__c=Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING;
         insert salesOrderRecord;
         
         list<map<String,string>> getApplicableSubStatus = SalesOrderSubStatusController.getApplicableSubStatus(salesOrderRecord.Id);
         System.assertEquals(getApplicableSubStatus.isEmpty(), false);
         
         list<map<String,string>> getSARejectionReason = SalesOrderSubStatusController.getSARejectionReason();
         System.assertEquals(getSARejectionReason.isEmpty(), false);
         
         list<map<String,string>> getLegalSubmissionReason = SalesOrderSubStatusController.getLegalSubmissionReason();
         System.assertEquals(getLegalSubmissionReason.isEmpty(), false);
         
         SalesOrderSubStatusController.saveSubStatus(salesOrderRecord.Id, Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING, SalesOrder__c.LegalSubmissionReason__c.getDescribe().getPicklistValues()[0].getValue(),SalesOrder__c.SalesAdminRejectionReason__c.getDescribe().getPicklistValues()[0].getValue(),'Test');
         
         salesOrderRecord.SubStatus__c=Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING;
         salesOrderRecord.Status__c=Constants.SALES_STATUS;
         update salesOrderRecord;
         
         SalesOrderSubStatusController.saveSubStatus(salesOrderRecord.Id, Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING, SalesOrder__c.LegalSubmissionReason__c.getDescribe().getPicklistValues()[0].getValue(),SalesOrder__c.SalesAdminRejectionReason__c.getDescribe().getPicklistValues()[0].getValue(),'Test');
         SalesOrderSubStatusController.saveSubStatus(salesOrderRecord.Id, Constants.SUB_STATUS_CM_VALIDATED, SalesOrder__c.LegalSubmissionReason__c.getDescribe().getPicklistValues()[0].getValue(),SalesOrder__c.SalesAdminRejectionReason__c.getDescribe().getPicklistValues()[0].getValue(),'Test');
         SalesOrderSubStatusController.saveSubStatus(salesOrderRecord.Id, Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING, SalesOrder__c.LegalSubmissionReason__c.getDescribe().getPicklistValues()[0].getValue(),SalesOrder__c.SalesAdminRejectionReason__c.getDescribe().getPicklistValues()[0].getValue(),'Test');
     }
}