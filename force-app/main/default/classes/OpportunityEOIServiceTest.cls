/**
* OpportunityEOIServiceTest
*
* Test class for OpportunityEOIService
*/
@isTest
private class OpportunityEOIServiceTest{
    //Create test data
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
         OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
         insert offerLine;
    }
    //Creat updateand cancel EOI Record
    @isTest static void testEOI() {
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        BuildingSection__c buildingRecord= [select id from BuildingSection__c limit 1];
        
        boolean eoiFlag= OpportunityEOIService.createOpportunityEOI(optyRecord.Id,accRecord.Id,projectRecord.Id,buildingRecord.Id,OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue(),
                                                  	'',OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue(),
                                                  'Online','','','1000','100000','1','4');
        try{
            eoiFlag= OpportunityEOIService.createOpportunityEOI(optyRecord.Id,accRecord.Id,projectRecord.Id,buildingRecord.Id,OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue(),
                                                  	'',OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue(),
                                                  'Online','','','10qw00','10q0000','1','4');
        }catch(Exception e){
            
        }
        list<OpportunityEOI__c> eoiList =[select id from OpportunityEOI__c];
        List<Id> eoiIdList = new List<Id>{eoiList[0].id};
        System.assertEquals(eoiList.isEmpty(), false);
        OpportunityEOIService.checkOpportunityEOI(optyRecord.Id);
        OpportunityEOIService.checkOpportunityEOI(null);
        OpportunityEOIService.cancelledOpportunityEOI(eoiList);
        OpportunityEOIService.queryAllFieldsWithExtraFields(eoiIdList);
        eoiList = OpportunityEOIService.getOpportunityEOIQuery('select id from OpportunityEOI__c');
    }
}