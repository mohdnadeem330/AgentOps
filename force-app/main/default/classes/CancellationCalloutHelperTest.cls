@isTest(SeeAllData=false)
public class CancellationCalloutHelperTest {
    @isTest static void setupMethod() {
        Test.startTest();
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        //Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        //bankAccount.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        //bankAccount.Name = 'Abu Dhabi Commercial Bank';
        //insert bankAccount;

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
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        InstallmentLines__c installment = installmentLines[0];
        installment.InvoiceNumber__c = '12345';
        update installment;

        //ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        //insert receiptAcknowledgementRec;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE;
        update otherCharges;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Rebate Reinstate');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.CANCELLATION_SR_TYPE, Constants.CANCELLATION_SR_TYPE);
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id rebateReinstateId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.CANCELLATION_SR_TYPE);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.CANCELLATION_SR_TYPE, rebateReinstateId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        
        newSR.EquityAmount__c = 100000;
        newSR.ReallocationAmount__c = 10000;
        newSR.Refund_Amount__c = 2000;
        newSR.ChargeCollected__c =10000;
        newSR.ForfeitAmount__c = 10000;
        newSR.Provision_Fund__c =10000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BankAccountNumber__c = '123456789';
		newSR.BranchName__c='Branch';
		newSR.BankName__c ='Bank Name';
		newSR.IBANNumber__c='IBAN123456734567892';
		newSR.SwiftCode__c='NOC Test';
        newSR.CancellationReason__c ='Mutual Cancellation - Refund';
        newSR.SocialReason__c ='Death & Incurable Disease';
        newSR.AgreementType__c ='T1 - Cancellation without Refund';
        insert newSR;

        //ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        //srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        //insert srReceiptAcknowledgementRec;

        //ReceiptAllocation__c rall = TestObjectsFactory.getReceiptAllocationRecord(srReceiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installment.Id);//new ReceiptAllocation__c();
        //insert rall;
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;

        newSR.HexaBPM__External_SR_Status__c = verificationByFinance.Id;
        newSR.HexaBPM__Internal_SR_Status__c = verificationByFinance.Id;
        //update newSR;

        String requestBody = '{ "cancelRq": [ { "srSfid": "'+newSR.Id+'", "sfSalesOrderId": "'+salesorder.Id+'", "cancelReqDate": "2022-12-16", "cancellationStatus": "Cancelled", "cancelReason": "Testing cancellation", "otherReason": "", "refundApplicable": "Yes", "refundReason": "Testing", "refundAmount": "1000", "forfeitureAmount": "0", "reallocatedAmount": "0", "othChg": [ { "srSfid": "'+newSR.Id+'", "sfId": "'+otherCharges.Id+'", "name": "Refund", "currencyCode": "AED", "sfSalesOrderId": "'+salesorder.Id+'", "accountId": "'+otherCharges.Account__c+'", "amountReceived": "1000", "amount": "1000", "invoiceId": "", "invoiceNumber": "", "opportunity": "0068d000009Zo6UAAS", "outAmountWords": "", "typeOfCharge": "Refund", "salesSupportCost": "", "installmentLine": "", "amountWithoutVat": "1000", "vatAmount": "0", "subType": "" } ] } ] }';
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "c2e8a4d0-26fa-11ee-a9bd-062faa15885a", "results": { "cancellationRes": [ { "sfRequestId": "c2e8a4d0-26fa-11ee-a9bd-062faa15885a", "srSFId": "'+newSR.Id+'", "sfSalesOrderId": "'+salesorder.Id+'", "status": "'+Constants.MULESOFT_SUCCESS+'", "errorMsg": "", "othChgRes": [ { "sfRequestId": "c2e8a4d0-26fa-11ee-a9bd-062faa15885a", "srSFId": "'+newSR.Id+'", "sfId": "'+otherCharges.Id+'", "erpId": "9061959", "recAcct": "02.10.A439017.122101.02.00.000.000", "expAcct": "02.10.A439017.921108.02.00.000.000", "taxAcct": "02.10.A439017.233169.02.00.000.000", "status": "Success", "errorMsg": "", "IsInvoiceReversal": "", "invoiceNo": "1025363" } ], "creditNoteRes": [ { "sfRequestId": "c2e8a4d0-26fa-11ee-a9bd-062faa15885a", "srSFId": "'+newSR.Id+'", "sfSalesOrderId": "a2A8d000000LeuZEAS", "type": "Credit Note", "instNum": "5", "invoiceId": "' + installment.InvoiceNumber__c +' ", "cnErpId": "9061957", "status": "Success", "errorMsg": "" } ] } ] } }';
        //String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "200", "correlationId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "results": { "cancellationRes": [ { "sfRequestId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "'+newSR.Id+'", "sfSalesOrderId": "'+salesorder.Id+'", "status": "'+Constants.MULESOFT_SUCCESS+'", "errorMsg": "" } ], "othChgRes": [ { "sfRequestId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "'+otherCharges.Id+'", "sfId": "'+otherCharges.Id+'", "erpId": "", "recAcct": "", "expAcct": "", "taxAcct": "", "status": "'+Constants.MULESOFT_SUCCESS+'", "errorMsg": "" } ],"creditNoteRes": [{"sfRequestId": "","srSFId": "","sfSalesOrderId": "","type": "","instNum": "","invoiceId": "' + installment.InvoiceNumber__c + '","cnErpId": "123456","status": "Success","errorMsg": ""}]} }';

        String responseBodyFailed = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "results": { "cancellationRes": [ { "sfRequestId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "'+newSR.Id+'", "sfSalesOrderId": "'+salesorder.Id+'", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "" } ], "othChgRes": [ { "sfRequestId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "'+otherCharges.Id+'", "sfId": "'+otherCharges.Id+'", "erpId": "", "recAcct": "", "expAcct": "", "taxAcct": "", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "Error while fetching the order details." } ] } }';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        CancellationCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.CANCELLATION_INTEGRATION, new List<Id>{newSR.Id}));
        
        
        try{
            //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFailed));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.CANCELLATION_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    /*public static void doFailedTrx() {
        
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c from HexaBPM__Service_Request__c Limit 1];
        SalesOrderOtherCharges__c otherCharges = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.BUDGET_LINE_ADMFEE LIMIT 1];
        
        String requestBody = '{ "cancelRq": [ { "srSfid": "'+newSR.Id+'", "sfSalesOrderId": "'+newSR.SalesOrder__c+'", "cancelReqDate": "2022-12-16", "cancellationStatus": "Cancelled", "cancelReason": "Testing cancellation", "otherReason": "", "refundApplicable": "Yes", "refundReason": "Testing", "refundAmount": "1000", "forfeitureAmount": "0", "reallocatedAmount": "0", "othChg": [ { "srSfid": "'+newSR.Id+'", "sfId": "'+otherCharges.Id+'", "name": "Refund", "currencyCode": "AED", "sfSalesOrderId": "'+newSR.SalesOrder__c+'", "accountId": "'+otherCharges.Account__c+'", "amountReceived": "1000", "amount": "1000", "invoiceId": "", "invoiceNumber": "", "opportunity": "0068d000009Zo6UAAS", "outAmountWords": "", "typeOfCharge": "Refund", "salesSupportCost": "", "installmentLine": "", "amountWithoutVat": "1000", "vatAmount": "0", "subType": "" } ] } ] }';
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "c2e8a4d0-26fa-11ee-a9bd-062faa15885a", "results": { "cancellationRes": [ { "sfRequestId": "c2e8a4d0-26fa-11ee-a9bd-062faa15885a", "srSFId": "'+newSR.Id+'", "sfSalesOrderId": "'+newSR.SalesOrder__c+'", "status": "'+Constants.MULESOFT_SUCCESS+'", "errorMsg": "", "othChgRes": [ { "sfRequestId": "c2e8a4d0-26fa-11ee-a9bd-062faa15885a", "srSFId": "'+newSR.Id+'", "sfId": "'+otherCharges.Id+'", "erpId": "9061959", "recAcct": "02.10.A439017.122101.02.00.000.000", "expAcct": "02.10.A439017.921108.02.00.000.000", "taxAcct": "02.10.A439017.233169.02.00.000.000", "status": "Success", "errorMsg": "", "IsInvoiceReversal": "", "invoiceNo": "1025363" } ], "creditNoteRes": [ { "sfRequestId": "c2e8a4d0-26fa-11ee-a9bd-062faa15885a", "srSFId": "'+newSR.Id+'", "sfSalesOrderId": "'+newSR.SalesOrder__c+'", "type": "Credit Note", "instNum": "5", "invoiceId": "12345", "cnErpId": "9061957", "status": "Success", "errorMsg": "" } ] } ] } }';
        String responseBodyFailed = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "results": { "cancellationRes": [ { "sfRequestId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "'+newSR.Id+'", "sfSalesOrderId": "'+newSR.SalesOrder__c+'", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "" } ], "othChgRes": [ { "sfRequestId": "2242ddd0-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "'+otherCharges.Id+'", "sfId": "'+otherCharges.Id+'", "erpId": "", "recAcct": "", "expAcct": "", "taxAcct": "", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "Error while fetching the order details." } ] } }';
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFailed));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.CANCELLATION_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            System.debug('TEST CLASS EXCEPTION > '+e.getLineNumber()+' >> '+e.getMessage());
        }
        Test.stopTest();        
    }*/
}