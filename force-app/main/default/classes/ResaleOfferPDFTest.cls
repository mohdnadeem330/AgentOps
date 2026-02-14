/**
* ResaleOfferPDFTest
*
* Test class for ResaleOfferPDFController
*/
@isTest
public class ResaleOfferPDFTest {
    @testSetup 
    static void setupData() {
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.EligibleforResale__c = true;
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitRecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitRecord.ResaleListed__c = false;
        unitRecord.ResaleStatus__c = '';
        unitRecord.PropertyId__c = '10000000';
        unitRecord.CompletionDate__c = System.today().addDays(7);
        insert unitRecord;

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> paymentInstallments = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert paymentInstallments;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitrecord.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 10000000;
        salesOrder.Account__c = acc.Id;
        salesOrder.Status__c = 'Sold';
        salesOrder.SellingPrice__c = 10000000;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = new List<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrder.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0].InvoicedAmount__c=installmentLines[0].InstallmentAmount__c;
            insert installmentLines;
        }

        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', unitRecord.Id, '800-Aldar');
        insert resaleCase;
        TriggerHandler.processedIds = new Set<Id>();

        unitRecord.ListedCase__c = resaleCase.Id;
        unitRecord.Listing_Price__c = 1000000;
        unitRecord.ResaleStatus__c = 'Property Listed';
        update unitRecord;
    }

    @isTest 
    static void resaleOfferControllerTest() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id, PropertyId__c FROM Unit__c LIMIT 1];System.debug(unit);
        
        PageReference pageRef = Page.ResaleOfferPDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('currentUnit', unit.Id);
        ApexPages.currentPage().getParameters().put('customerName', opp.Name);
        ApexPages.currentPage().getParameters().put('opportunityId', opp.Id);

        Test.startTest();
        ResaleOfferPDFController ctrl= new ResaleOfferPDFController();
        ctrl.createPublickLink();

        ContentVersion cv = new ContentVersion(
            VersionData = EncodingUtil.base64Decode(Blob.valueOf('Test').toString()),
            Title = 'test', PathOnClient = 'test'
        );
        insert cv;

        ContentDistribution cd = ResaleOfferPDFController.createContentDistribution(cv.Id, unit.Id, 'Test');
        Test.stopTest();
    }

    @IsTest
    static void sendSalesOfferPDFTest(){
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Test.startTest();
            ResaleOfferPDFUtility.sendSalesOfferPDF(unit.Id, opp.Name, opp.Id);
        Test.stopTest();
    }
}