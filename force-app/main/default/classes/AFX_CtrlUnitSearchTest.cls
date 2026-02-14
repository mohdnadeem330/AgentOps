/*
* Class Name:  AFX_CtrlUnitSearchTest
* Created By : R3-DLP implementation-Smaartt
* Description: Test AFX_CtrlUnitSearchclass used for Unit Search LWC Component
*/
@isTest
public class AFX_CtrlUnitSearchTest {
@testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc.Email__c = 'Ali.athamneh@pwc.com';
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        conRecord.Email = 'Ali.athamneh@pwc.com';
        update conRecord;
                
         
         Account acc = TestObjectsFactory.getPersonAccountRecord();
         insert acc;
         
         Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
         opp.BrokerAgentContact__c=conRecord.Id;
         opp.BrokerAgencyAccount__c =orgAcc.Id;
         opp.Contact__c=conRecord.Id;
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
    @isTest static void testingScenarios() {
                      
        Project__c projectRecord= [select id from Project__c limit 1]; 
        BuildingSection__c bsrecord = [select id from BuildingSection__c limit 1]; 
        AFX_CtrlUnitSearch.searchBuidingUnit(projectRecord.Id) ;
        AFX_CtrlUnitSearch.searchBuidingUnits(projectRecord.Id) ;
        AFX_CtrlUnitSearch.searchUnits(bsrecord.Id);
    }
}