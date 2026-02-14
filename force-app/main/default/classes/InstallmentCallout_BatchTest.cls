@isTest
private class InstallmentCallout_BatchTest{
        @testSetup static void setupData() {
            //offer
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
           
           
    }
    //Test Installment records, It should create Commission placeholder
    @isTest static void testInstallmentRecords() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        list<CommissionLineItem__c> externalCommission= new list<CommissionLineItem__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0]. SyncStatus__c =Constants.STATUS_FAILED;
            insert installmentLines;
        }
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1());
        test.startTest();
        System.schedule('InstallmentCallout_Batch-Test', '0 0 * * * ?', new InstallmentCallout_Batch() );
        InstallmentCallout_Batch batchJob = new InstallmentCallout_Batch();
        database.executeBatch(batchJob, 1);
        test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"statusCode": 200, "results": [{"intgType": "SO_INST_REVDATE","sfRequestId": "be6cfa60-cd9c-11ef-8cbc-023d03de8f95","sfServiceReqId": "","sfInstallmentId": "a1g8d000000cfXJAAY","sfSalesOrderId": "a2A8d000000LVyREAW","instNum": "17","status": "Success","errorMsg": "Test Message"}]}'); // Mock response
            return res;
        }
    }
    
    public class MockHttpResponseGenerator1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
             res.setBody('{"statusCode": 201, "results": [{"intgType": "SO_INST_REVDATE","sfRequestId": "be6cfa60-cd9c-11ef-8cbc-023d03de8f95","sfServiceReqId": "","sfInstallmentId": "a1g8d000000cfXJAAY","sfSalesOrderId": "a2A8d000000LVyREAW","instNum": "17","status": "Success","errorMsg": "Test Message"},{"intgType": "SO_INST_REVDATE","sfRequestId": "be6cfa60-cd9c-11ef-8cbc-023d03de8f95","sfServiceReqId": "","sfInstallmentId": "a1g8d000000cfXJAAY","sfSalesOrderId": "a2A8d000000LVyREAW","instNum": "17","status": "Failed","errorMsg": "Test Error"}]}'); // Mock response
            // Mock response
            return res;
        }
    }
}