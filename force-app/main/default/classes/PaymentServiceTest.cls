@isTest
private class PaymentServiceTest {
    
    @isTest(seeAllData = true)
    static  void callMethods() {

        Account acc = TestObjectsFactory.getAccountRecord('Person Account',true,'1232344');
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        SalesOrder__c sales = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);

        Unit__c unit = TestObjectsFactory.unitDataSetup('');
        insert unit;

        sales.Unit__c = unit.Id;
        insert sales;

        ReceiptAcknowledgement__c paymentRecords = new ReceiptAcknowledgement__c();
        paymentRecords.Opportunity__c = opp.Id;
        paymentRecords.Account__c = acc.Id;
        paymentRecords.Amount__c = 1000;
        paymentRecords.PaymentType__c = Constants.ONLINE;
        
        insert paymentRecords;

        PaymentService.validateSFPaymentLink(paymentRecords.Id);
        PaymentService.validateSFPaymentLink('Invalid recordId');

        paymentRecords.ReasonCode__c = '100';
        update paymentRecords;
        PaymentService.validateSFPaymentLink(paymentRecords.Id);

        paymentRecords.ReasonCode__c = '';
        paymentRecords.SalesOrder__c = sales.Id;
        update paymentRecords;
        PaymentService.validateSFPaymentLink(paymentRecords.Id);

        ReceiptAcknowledgement__c insertRecord = new ReceiptAcknowledgement__c();
        insertRecord.Opportunity__c = opp.Id;
        insertRecord.Account__c = acc.Id;
        insertRecord.Amount__c = 1000;
        insertRecord.PaymentType__c = Constants.ONLINE;

        PaymentService.insertReceiptAcknowledgementRecords(new List<ReceiptAcknowledgement__c>{insertRecord});

        OpportunityEOI__c opportunityEOI = TestObjectsFactory.getOpportunityEOIRecord(opp.Id, Constants.ONLINE);
        opportunityEOI.ProjectName__c = unit.Project__c;
        opportunityEOI.Account__c = acc.Id;
        opportunityEOI.Opportunity__c = opp.Id;
        opportunityEOI.BuildingSectionName__c = unit.BuildingSectionName__c;
        opportunityEOI.UnitModel__c = '1BHK';
        opportunityEOI.PriceRangeFrom__c = 0;
        opportunityEOI.PriceRangeTo__c = 10000;
        opportunityEOI.UnitFeatures__c = 'Saadiyat';
        opportunityEOI.ComplianceStatus__c = Constants.CLEARED;
        insert opportunityEOI;

        Test.startTest();
        try{
            PaymentService.createPaymentRecords(new List<OpportunityEOI__c>{opportunityEOI});
        } catch(Exception e){
            
        }
        Test.stopTest();

    }
}