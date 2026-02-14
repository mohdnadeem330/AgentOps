@isTest(SeeAllData=false)
public class MortgageCalloutHelperTest {
    @isTest static void setupMethod() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc1;
        
        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        salesOrder.MortgageApplicable__c = 'No';
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        update installmentLines[0];
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        receiptAllocation.DateOfApplication__c = null;
        receiptAllocation.Unapply__c = false;
        insert receiptAllocation;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c Closed = TestObjectsFactory.getSRStatus('Closed');       
        insert Closed;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
        
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        
        
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(Closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;
        String requestBody = '{"mortgageReq":[{"sfServiceReqId":"'+newSR.Id+'","sfSalesOrderId":"'+salesOrder.Id+'","mortgageType":"REGISTRATION","financerName":"Abu Dhabi Commercial Bank","partyId":"4122949","financedAmount":"232132.00","startDate":"2022-12-15","endDate":"","mortgageApplicationNo":"2322321","banksEmail":"ajay.thakur.tpr@pwc.com","bankRepresentative":"Ajay Thakur","bankRepresentativeEmail":"ajay.thakur.tpr@pwc.com"}]}';
        
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+newSR.Id+'","status": "Success","errorMsg": "","erpId": "185506"}]}';
        String responseBodyFailed = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+newSR.Id+'","status": "Failed","errorMsg": "EXCEPTION IN RECORD INSERT.Invalid Sales Order.","erpId": "185506"}]}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        MortgageCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.MORTGAGE_INTEGRATION, new List<Id>{newSR.Id}));
        
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFailed));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(responseBodyFailed, true, Constants.MORTGAGE_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            
        }
        Test.stopTest();
        
        
    }
}