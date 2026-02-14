@isTest(SeeAllData=false)
public class PropertyTransferCalloutHelperTest {
    @isTest static void setupMethod() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.ERPID__c = '87292';
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
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Rebate Reinstate');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_RT, 'PropertyTransfer');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id rebateReinstateId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_RT, rebateReinstateId, SRTemplateDetailRecord.Id);
        newSR.BuyerName__c = acc.Id;
        insert newSR;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;

        PropertyTransferCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE;
        otherCharges.ServiceRequest__c=newSR.Id;
        update otherCharges;
        
        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = acc.Id;
        agencyTeam.ServiceRequest__c = newSR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Spouse Of';
        insert agencyTeam;

        String requestBody = '{"prpTransRq":[{"appointmentDate":"","buyerName":"","buyerSFID":"abctest","srCase":"","chargeRule":"","chargeToBeCollected":"","chargeType":"","chargeWaivedOff":"","closedDateTime":"","closedStatus":"","createdDate":"","customer":"","customerSFID":"abctest1","exemptValidation":"Y","exemptionReason":"","nextAppover":"","parentSR":"","paymentType":"","recordTypeName":"","salesOrder":"","salesOrderSFID":"'+salesOrder.Id+'","srNumber":"123","srSFID":"'+newSR.Id+'","srTemplate":"","srType":"","status":"","transferSellingPrice":"1000000","unit":"YasParkGate-N2-V-498","documentPrintdate":"2022-12-16","thresholdAmount":"","transferType":"Property Transfer","jointOwner":[{"sfTransferId":"","customerName":"","customerSFID":"","shareHoldPerc":"","relationshipType":"","srSFID":""}],"othChg":[{"srSfid":"'+newSR.Id+'","sfId":"'+otherCharges.Id+'","name":"Test","currencyCode":"AED","sfSalesOrderId":"a2A8d000000LyglEAC","accountId":"0018d00000HNVpaAAH","amountReceived":"1000000","amount":"1000000","invoiceId":"","invoiceNumber":"","opportunity":"0068d000009Zo6UAAS","outAmountWords":"","typeOfCharge":"Transfer Fee Charge","salesSupportCost":"","installmentLine":"","amountWithoutVat":"1000000","vatAmount":""}]}]}';
        
        //String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "40b44b00-8695-11ed-b4ba-0210eed6bfe2", "results": { "prpTransRs": [ { "sfRequestId": "40b44b00-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "'+newSR.Id+'", "srERPId": "12345", "status": "'+Constants.MULESOFT_SUCCESS+'", "errorMsg": "" } ], "prpTransJORs": [], "othChgRes": [ { "sfRequestId": "40b44b00-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "", "sfId": "'+otherCharges.Id+'", "erpId": "12345", "recAcct": "", "expAcct": "", "taxAcct": "", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "," } ] } } ';
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "results": { "prpTransRs": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "srERPId": "2310073", "status": "'+Constants.MULESOFT_SUCCESS+'", "errorMsg": "", "othChgRes": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "sfId": "'+otherCharges.Id+'", "erpId": "9061916", "recAcct": "02.00.A340010.122101.02.00.000.000", "expAcct": "02.10.A340010.233167.02.00.000.000", "taxAcct": "02.10.A340010.233169.02.00.000.000", "status": "'+Constants.MULESOFT_SUCCESS+'", "errorMsg": "", "invoiceNo": "70083143" } ], "prpTransJORs": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "soSFId": "'+salesOrder.Id+'", "cusSFId": "'+acc.Id+'", "cusERPId": "22562", "sfTransferSFID": "'+acc.Id+'", "status": "'+Constants.MULESOFT_SUCCESS+'", "errorMsg": "" } ] } ] } }';
        //String responseBodyFailed = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "40b44b00-8695-11ed-b4ba-0210eed6bfe2", "results": { "prpTransRs": [ { "sfRequestId": "40b44b00-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "'+newSR.Id+'", "srERPId": "", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "" } ], "prpTransJORs": [], "othChgRes": [ { "sfRequestId": "40b44b00-8695-11ed-b4ba-0210eed6bfe2", "srSFId": "", "sfId": "'+otherCharges.Id+'", "erpId": "", "recAcct": "", "expAcct": "", "taxAcct": "", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "," } ] } } ';
        String responseBodyFailed = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "results": { "prpTransRs": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "srERPId": "", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "Already Exist", "othChgRes": [ ], "prpTransJORs": [ ] } ] } }';
        
        
        PropertyTransferCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.PROPERTY_TRANS_INTEGRATION, new List<Id>{newSR.Id}));
        
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.PROPERTY_TRANS_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    public static void doFailedTrx() {
        
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c from HexaBPM__Service_Request__c Limit 1];
        SalesOrderOtherCharges__c otherCharges = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.BUDGET_LINE_ADMFEE LIMIT 1];
        
        String responseBodyFailed = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "results": { "prpTransRs": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "srERPId": "", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "Already Exist", "othChgRes": [ ], "prpTransJORs": [ ] } ] } }';
        String requestBody = '{"prpTransRq":[{"appointmentDate":"","buyerName":"","buyerSFID":"abctest","srCase":"","chargeRule":"","chargeToBeCollected":"","chargeType":"","chargeWaivedOff":"","closedDateTime":"","closedStatus":"","createdDate":"","customer":"","customerSFID":"abctest1","exemptValidation":"Y","exemptionReason":"","nextAppover":"","parentSR":"","paymentType":"","recordTypeName":"","salesOrder":"","salesOrderSFID":"'+newSR.SalesOrder__c+'","srNumber":"123","srSFID":"'+newSR.Id+'","srTemplate":"","srType":"","status":"","transferSellingPrice":"1000000","unit":"YasParkGate-N2-V-498","documentPrintdate":"2022-12-16","thresholdAmount":"","transferType":"Property Transfer","jointOwner":[{"sfTransferId":"","customerName":"","customerSFID":"","shareHoldPerc":"","relationshipType":"","srSFID":""}],"othChg":[{"srSfid":"'+newSR.Id+'","sfId":"'+otherCharges.Id+'","name":"Test","currencyCode":"AED","sfSalesOrderId":"a2A8d000000LyglEAC","accountId":"0018d00000HNVpaAAH","amountReceived":"1000000","amount":"1000000","invoiceId":"","invoiceNumber":"","opportunity":"0068d000009Zo6UAAS","outAmountWords":"","typeOfCharge":"Transfer Fee Charge","salesSupportCost":"","installmentLine":"","amountWithoutVat":"1000000","vatAmount":""}]}]}';

        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFailed));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.PROPERTY_TRANS_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    public static void doNoOtherChargeTest() {
        
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c from HexaBPM__Service_Request__c Limit 1];
        delete [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.BUDGET_LINE_ADMFEE LIMIT 1];
        
        String responseBodyFailed = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "results": { "prpTransRs": [ { "sfRequestId": "e8b7fa90-2230-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "srERPId": "", "status": "'+Constants.MULESOFT_FAILURE+'", "errorMsg": "Already Exist", "othChgRes": [ ], "prpTransJORs": [ ] } ] } }';
        String requestBody = '{"prpTransRq":[{"appointmentDate":"","buyerName":"","buyerSFID":"abctest","srCase":"","chargeRule":"","chargeToBeCollected":"","chargeType":"","chargeWaivedOff":"","closedDateTime":"","closedStatus":"","createdDate":"","customer":"","customerSFID":"abctest1","exemptValidation":"Y","exemptionReason":"","nextAppover":"","parentSR":"","paymentType":"","recordTypeName":"","salesOrder":"","salesOrderSFID":"'+newSR.SalesOrder__c+'","srNumber":"123","srSFID":"'+newSR.Id+'","srTemplate":"","srType":"","status":"","transferSellingPrice":"1000000","unit":"YasParkGate-N2-V-498","documentPrintdate":"2022-12-16","thresholdAmount":"","transferType":"Property Transfer","jointOwner":[{"sfTransferId":"","customerName":"","customerSFID":"","shareHoldPerc":"","relationshipType":"","srSFID":""}],"othChg"[]}]}]}';

        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBodyFailed));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(requestBody, true, Constants.PROPERTY_TRANS_INTEGRATION, new List<Id>{newSR.Id}));
            
        } catch(Exception e){
            
        }
        Test.stopTest();
    }
}