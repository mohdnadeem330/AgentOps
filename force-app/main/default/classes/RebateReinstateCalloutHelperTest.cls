@isTest(SeeAllData=false)
public class RebateReinstateCalloutHelperTest {
    @isTest static void setupMethod() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

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
        salesorder.RebateForfeitureLetterSent__c = TRUE;
        salesorder.OtherRebateAmount__c = 10000;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Rebate Reinstate');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Rebate Reinstate', 'RebateReinstate');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id rebateReinstateId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Rebate Reinstate');

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, 'Rebate Reinstate', rebateReinstateId, SRTemplateDetailRecord.Id);
        newSR.salesOrder__c = salesOrder.Id;
        insert newSR;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;

        newSR.HexaBPM__External_SR_Status__c = verificationByFinance.Id;
        newSR.HexaBPM__Internal_SR_Status__c = verificationByFinance.Id;
        update newSR;

        String requestBody = '{"rebateReq":[{"sfServiceReqId":"'+newSR.Id+'","sfSalesOrderId":"'+salesOrder.Id+'","releaseDate":"'+Date.Today()+'","releaseComments":"Testing Record","releaseBy":"Ajay Thakur"}]}';
        
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+newSR.Id+'","status": "Success","errorMsg": "","erpId": "185506"}]}';
        String responseBodyFailed = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+newSR.Id+'","status": "Failed","errorMsg": "EXCEPTION IN RECORD INSERT.Invalid Sales Order.","erpId": "185506"}]}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        RebateReinstateCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.REBATE_REINSTATE_INTEGRATION, new List<Id>{newSR.Id}));
        
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFailed));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(responseBodyFailed, true, Constants.REBATE_REINSTATE_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            
        }
        Test.stopTest();
        
        
    }
    
    
    
    
    @isTest static void setupMethod1() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

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
        salesorder.RebateForfeitureLetterSent__c = TRUE;
        salesorder.OtherRebateAmount__c = 10000;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Rebate Reinstate');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Rebate Reinstate', 'RebateReinstate');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id rebateReinstateId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Rebate Reinstate');

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, 'Rebate Reinstate', rebateReinstateId, SRTemplateDetailRecord.Id);
        newSR.salesOrder__c = salesOrder.Id;
        insert newSR;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;

        newSR.HexaBPM__External_SR_Status__c = verificationByFinance.Id;
        newSR.HexaBPM__Internal_SR_Status__c = verificationByFinance.Id;
        update newSR;

        String requestBody = '{"rebateReq":[{"sfServiceReqId":"'+newSR.Id+'","sfSalesOrderId":"'+salesOrder.Id+'","releaseDate":"'+Date.Today()+'","releaseComments":"Testing Record","releaseBy":"Ajay Thakur"}]}';
        
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+newSR.Id+'","status": "Success","errorMsg": "","erpId": "185506"}]}';
       // String responseBodyFailed = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+newSR.Id+'","status": "Failed","errorMsg": "EXCEPTION IN RECORD INSERT.Invalid Sales Order.","erpId": "185506"}]}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        RebateReinstateCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.REBATE_REINSTATE_INTEGRATION, new List<Id>{newSR.Id}));
        
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(responseBody, true, Constants.REBATE_REINSTATE_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            
        }
        Test.stopTest();
        
        
    }
    
    
}