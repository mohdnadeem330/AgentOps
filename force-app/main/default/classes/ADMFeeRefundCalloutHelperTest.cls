@isTest(SeeAllData=false)
public class ADMFeeRefundCalloutHelperTest {
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
        salesOrder.ADMFeeAmount__c = 20000;
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
        otherCharges.SubType__c = Constants.OTHER_CHARGES_Charge_TYPE_ADM_Fee_REFUND;
        update otherCharges;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.ADM_Fee_Refund_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('ADM Fee Refund', 'ADMFeeRefund');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c Closed = TestObjectsFactory.getSRStatus('Closed');       
        insert Closed;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
        
        Id admFeeRefundId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.ADM_Fee_Refund_RT);
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(Closed.Id, unit.Id, Constants.ADM_Fee_Refund_RT, admFeeRefundId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BankAccountNumber__c = '987654321';
        newSR.BranchName__c = 'test';
        newSR.BankName__c = 'test';
        newSR.IBANNumber__c = '1234567890123456789';
        newSR.SwiftCode__c = '1234567890';
        insert newSR;
        String requestBody = '{"admRefRq":[{"sfServiceReqId":"'+newSR.Id+'","sfSalesOrderId":"'+salesOrder.Id+'","unitSfId":"'+unit.Id+'","admRefundAmount":"2000","admFeeAmount":"2000","admWaivedAmount":"300","soOtherChargeSfId":"'+otherCharges.Id+'"}]}';
        
        String responseBodyFailed = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+newSR.Id+'","status": "'+Constants.MULESOFT_FAILED+'","errorMsg": "","erpId": "185506", "soOtherChargeSfId" : "'+otherCharges.Id+'"}]}';
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+newSR.Id+'","status": "'+Constants.MULESOFT_SUCCESS+'","errorMsg": "EXCEPTION IN RECORD INSERT.Invalid Sales Order.","erpId": "185506", "soOtherChargeSfId" : "'+otherCharges.Id+'"}]}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFailed));
        
        ADMFeeRefundCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        System.enqueueJob(new CalloutToMuleSoftForSRQueueable(responseBodyFailed, true, Constants.ADM_FEE_REFUND_INTEGRATION, new List<Id>{newSR.Id}));
        
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(responseBody, true, Constants.ADM_FEE_REFUND_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            
        }
        Test.stopTest();
        
        
    }
}