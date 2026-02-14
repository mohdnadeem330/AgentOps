/**
* PaymentPlanServiceTest
*
* Test class for PaymentPlanService
*/
@isTest
private class PaymentPlanServiceTest {
 @testSetup static void setupData() {
            //Create Test Data
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
           
            OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        	insert offerRecord;
        	OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        	insert offerLine;
    }
    //Create update payment plan records
    @isTest static void testPaymentPlans() {
        Project__c projectRecord= [select id from Project__c limit 1];
        BuildingSection__c buildingRecord= [select id from BuildingSection__c limit 1];
        Unit__c unitrecord =[select id,BuildingSectionName__c, Unit_Feature_for_Payment_Plan__c from  Unit__c limit 1];
        Opportunity opty = [select id from Opportunity limit 1];     
        Map<Id,PaymentPlan__c> paymentPlanMap=PaymentPlanService.getPaymentPlanByProjectIds(new set<ID>{projectRecord.Id});
        System.assertEquals(paymentPlanMap.isEmpty(),false);
        PaymentPlanService.getPaymentPlanByBuidlingIds(new set<ID>{buildingRecord.id});
        Map<Id,Set<Id>> tempRec =  new Map<Id,Set<Id>>();
        tempRec.put(buildingRecord.id,new set<ID>());
        PaymentPlanService.getPaymentPlanIdsByBuidlingIds(tempRec,new set<ID>{buildingRecord.id});
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        PaymentPlanService.insertPaymentPlan(new list<PaymentPlan__c>{paymentPlanRecord});
        
        PaymentPlanService.lastCreatedIdPaymentPlan(null,unitrecord.Id);
        PaymentPlanService.lastCreatedPaymentPlanDetails(null);
        
        user userRecord =[select id from User where id=:userInfo.getUserId() limit 1];
        system.debug('UnitRecord:'+ unitRecord);
        PaymentPlanService.getListOfPaymentPlans(opty,new list<Unit__c>{unitrecord},userRecord);
        PaymentPlanService.getListOfPaymentPlansPostSales(opty,new List<Unit__c>{unitrecord},userRecord);
        
        
    }
}