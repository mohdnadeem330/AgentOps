@isTest
public class BatchToAddDarnaPointsTest {

    //Create setupData
    @testSetup static void setupData() {  
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
         Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.ConceptId__c = 'test';
         insert projectRecord;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord.id;
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 1000;
        salesOrder.Status__c = 'Sold';
        salesOrder.DARNAAmount__c = 5;
        salesOrder.BookingDate__c = Date.today();
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;
    }
   
    @isTest
    public static void testBatchToDarnaCallout() {
		    Test.startTest();

        ReceiptAllocation__c receiptAllocation1 = [Select Id From ReceiptAllocation__c Limit 1];
        String responseBody = '{"message":"aa","http_response":"200","redemption_mode":"123","points":"200","success":"true","concept_id":"123","redemption_id":"123","redemption_reference_code":"123","burn_rate":"123","email":"aa","membership_number":"123","mobile_number":"123456","first_name":"123456","last_name":"123","is_active":"123","member_status":"123","registration_date":"123","available_points":"123","amount":"123","currency":"123","minimum_redeemable_points":"123","minimum_redeemable_amount":"123","data":{"client_access_token":"123","external_transaction_id":"'+receiptAllocation1.Id+'"}}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.DarnaMembershipNumber__pc = '123456789';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
    
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        salesOrder.NetAmount__c = 1000;
        salesOrder.DARNAAmount__c = 5;
        salesOrder.BookingDate__c = Date.today();
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receiptAcknowledgement.ClearedDate__c = Date.today();
        insert receiptAcknowledgement;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        receiptAllocation.IsReceiptAllocationForDarna__c = false;
        insert receiptAllocation;
        
        
        

        try {
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'Test Darna Callout Batch')]) {
                System.abortJob(ct.Id);
            }
            System.schedule('Test Darna Callout Batch', '0 0 23 * * ?', new BatchToAddDarnaPoints(null));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.StopTest();
    }
}