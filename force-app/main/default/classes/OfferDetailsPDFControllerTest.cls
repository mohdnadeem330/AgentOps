/**
* OfferDetailsPDFControllerTest
*
* Test class for OfferDetailsPDFController
*/
@isTest
public class OfferDetailsPDFControllerTest {
    @testSetup static void setupData() {
           //offer
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
          	Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
            insert projectRecord;
            BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
            insert buildingRecord;
            Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        	unitrecord.WebFloorPlan__c ='https://test123.com';
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
    //test Offer PDF
    @isTest static void offerDetailsTest() {
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        PaymentPlan__c ppRecord= [select id from PaymentPlan__c limit 1];
        OffersPromotions__c offerRecord= [select id from OffersPromotions__c limit 1];
        
        //Document placeholder should be created
        Document__c docRecord = [select id,DarcomURL__c from Document__c where unit__c = :unitrecord.Id ];
        docRecord.DocumentAttached__c=true;
        update docRecord;
        System.assertEquals(docRecord.DarcomURL__c,'https://test123.com');
        OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),'test',docRecord.id);
        
        PageReference pageRef = Page.OfferDetailsPDF;
        Test.setCurrentPage(pageRef);   
        // Put Id into the current page Parameters
		ApexPages.currentPage().getParameters().put('id',optyRecord.Id);
        ApexPages.currentPage().getParameters().put('currentUnit',unitrecord.Id);
        ApexPages.currentPage().getParameters().put('currentOffer',offerRecord.Id);
        ApexPages.currentPage().getParameters().put('otherUnits',unitrecord.Id);
        ApexPages.currentPage().getParameters().put('selectedPayments',ppRecord.Id);
        ApexPages.currentPage().getParameters().put('multiPurposeAmount','false');
        ApexPages.currentPage().getParameters().put('marketingPlan','false');
        ApexPages.currentPage().getParameters().put('customerName','Test');
        
        OfferDetailsPDFController obj= new OfferDetailsPDFController();
        obj.createPublickLink();
        //fetch Created Link
        obj.createPublickLink();
    }
}