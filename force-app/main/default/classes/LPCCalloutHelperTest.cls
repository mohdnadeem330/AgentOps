@isTest
private class LPCCalloutHelperTest {
  
    //Create setupData
    @testSetup static void setupData() {
       
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
        salesOrder.MortgageApplicationNumber__c = '1234';
        salesOrder.MortgageApplicable__c = 'No';
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);
        TriggerHandler.processedIds = new Set<Id>();
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        installmentLines[0].InvoiceNumber__c = '342345';
        installmentLines[0].LPCFreezeDate__c =System.today();
        installmentLines[0].LPCFreezeUntilDate__c =System.today()+30;
        update installmentLines[0];
        
        

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        receiptAllocation.DateOfApplication__c = null;
        receiptAllocation.Unapply__c = false;
        insert receiptAllocation;
		 Test.startTest();
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

        SalesOrderOtherCharges__c soOther = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id,acc.Id);
        soOther.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES;
        update soOther;
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(Closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;
        Test.stopTest();
    }
    
    @isTest
    public static void callMethod (){
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c from HexaBPM__Service_Request__c Limit 1];
		
		SalesOrderOtherCharges__c soOther = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES LIMIT 1];


        //String requestBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","results": {"lpcRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfSalesorderId": "'+salesOrder.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Success","errorMsg": ""}],"othChgRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Failure","errorMsg": "Manual other charges creation processORA-0000: normal, successful completion"}]}}';
        String requestBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "results": [ { "lpcRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSfid": "'+newSR.Id+'", "sfSalesorderId": "'+newSR.SalesOrder__c+'", "sfId": "'+soOther.Id+'", "erpId": "", "status": "Success", "errorMsg": "cusERPId", "othChgRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "sfId": "a29250000023A31AAE", "erpId": "9061890", "recAcct": "02.10.A439017.123119.02.00.000.000", "expAcct": "02.10.A439017.421102.02.00.000.000", "taxAcct": "02.10.A439017.233169.02.00.000.000", "status": "Failed", "errorMsg": "ErrorMesss", "invoiceNo": "70083133" } ] } ] } ] }';
        Test.startTest();

        MulePOSResponeWrapper responseBody = CalloutToMuleSoftForSRQueueable.lpcParse(requestBody);
        MulePOSResponeWrapper.Results results = responseBody.results[0];

        LPCCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        LPCCalloutHelper.processLPCResponse(results, Constants.LPC_INTEGRATION, requestBody, requestBody);

        requestBody = '{ "applicationName": "x-ald-sferp-api", "success": false, "statusCode": "504", "correlationId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "results": [ { "lpcRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSfid": "'+newSR.Id+'", "sfSalesorderId": "'+newSR.SalesOrder__c+'", "sfId": "'+soOther.Id+'", "erpId": "", "status": "Success", "errorMsg": "", "othChgRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "sfId": "'+soOther.Id+'", "erpId": "9061890", "recAcct": "02.10.A439017.123119.02.00.000.000", "expAcct": "02.10.A439017.421102.02.00.000.000", "taxAcct": "02.10.A439017.233169.02.00.000.000", "status": "Success", "errorMsg": "", "invoiceNo": "70083133" } ] } ] } ] }';

        MulePOSResponeWrapper responseBody1 = CalloutToMuleSoftForSRQueueable.lpcParse(requestBody);
        MulePOSResponeWrapper.Results results1 = responseBody1.results[0];

		requestBody = '{  "applicationName": "x-ald-sferp-api",  "success": true,  "statusCode": "201",  "correlationId": "3424f270-a875-11ed-a086-06ea4c11b14a",  "results": [    {      "sfRequestId": "3424f270-a875-11ed-a086-06ea4c11b14a",      "srSfid": "'+newSR.Id+'",      "sfSalesorderId": "'+newSR.SalesOrder__c+'",      "instNum": "1",      "status": "Failure",      "errorMsg": "Invalid sales order :'+newSR.SalesOrder__c+'"    },    {      "sfRequestId": "3424f270-a875-11ed-a086-06ea4c11b14a",      "srSfid": "'+newSR.Id+'",      "sfSalesorderId": "'+newSR.SalesOrder__c+'",      "instNum": "2",      "status": "Failure",      "errorMsg": "Invalid sales order :'+newSR.SalesOrder__c+'"    },    {      "sfRequestId": "3424f270-a875-11ed-a086-06ea4c11b14a",      "srSfid": "'+newSR.Id+'",      "sfSalesorderId": "'+newSR.SalesOrder__c+'",      "instNum": "3",      "status": "Failure",      "errorMsg": "Invalid sales order :'+newSR.SalesOrder__c+'"    },    {      "sfRequestId": "3424f270-a875-11ed-a086-06ea4c11b14a",      "srSfid": "'+newSR.Id+'",      "sfSalesorderId": "'+newSR.SalesOrder__c+'",      "instNum": "4",      "status": "Failure",      "errorMsg": "Invalid sales order :'+newSR.SalesOrder__c+'"    }  ]}';      
		MuleResponeWrapper responseBody2 = (MuleResponeWrapper)System.JSON.deserialize(requestBody, MuleResponeWrapper.class);
        List<MuleResponeWrapper.MuleResponse> results2 = responseBody2.results; 
        
        LPCCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        LPCCalloutHelper.processLPCResponse(results1, Constants.LPC_INTEGRATION, requestBody, requestBody);
        LPCCalloutHelper.processLPCFreezeResponse(results2, Constants.FREEZE_LPC_INTEGRATION, requestBody, requestBody);

        LPCCalloutHelper.getDataForFreezeCallout(new List<Id>{newSR.Id}, true);
        LPCCalloutHelper.getDataForFreezeCallout(new List<Id>{newSR.Id}, false);

        Test.stopTest();
    }

    @isTest
    public static void callMethod2(){
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c  from HexaBPM__Service_Request__c Limit 1];
        SalesOrderOtherCharges__c soOther = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES LIMIT 1];

        //String requestBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","results": {"lpcRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfSalesorderId": "'+salesOrder.Id+'","sfId": "yguihkzx55457b","erpId": "","status": "Success","errorMsg": ""}],"othChgRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Failure","errorMsg": "Manual other charges creation processORA-0000: normal, successful completion"}]}}';
        String requestBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "results": [ { "lpcRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSfid": "'+newSR.Id+'", "sfSalesorderId": "'+newSR.SalesOrder__c+'", "sfId": "'+soOther.Id+'", "erpId": "", "status": "Success", "errorMsg": "", "othChgRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "sfId": "'+soOther.Id+'", "erpId": "9061890", "recAcct": "02.10.A439017.123119.02.00.000.000", "expAcct": "02.10.A439017.421102.02.00.000.000", "taxAcct": "02.10.A439017.233169.02.00.000.000", "status": "Success", "errorMsg": "", "invoiceNo": "70083133" } ] } ] } ] }';
        Test.startTest();
        soOther.TypeOfCharge__c = 'Legal Fee';
        update soOther;
        LPCCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        Test.stopTest();
    }
    
    @isTest
    public static void callMethod3(){
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c  from HexaBPM__Service_Request__c Limit 1];
        SalesOrderOtherCharges__c soOther = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES LIMIT 1];

        //String requestBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","results": {"lpcRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfSalesorderId": "'+salesOrder.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Success","errorMsg": ""}],"othChgRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Failure","errorMsg": "Manual other charges creation processORA-0000: normal, successful completion"}]}}';
        String requestBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "results": [ { "lpcRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSfid": "'+newSR.Id+'", "sfSalesorderId": "'+newSR.SalesOrder__c+'", "sfId": "'+soOther.Id+'", "erpId": "", "status": "Success", "errorMsg": "", "othChgRes": [] } ] } ] }}';
        Test.startTest();
        soOther.TypeOfCharge__c = 'Legal Fee';
        update soOther;
        LPCCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        Test.stopTest();
    }
    
    @isTest
    public static void callMethod4(){
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c  from HexaBPM__Service_Request__c Limit 1];
        SalesOrderOtherCharges__c soOther = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES LIMIT 1];

        //String requestBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","results": {"lpcRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfSalesorderId": "'+salesOrder.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Success","errorMsg": ""}],"othChgRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Failure","errorMsg": "Manual other charges creation processORA-0000: normal, successful completion"}]}}';
        String requestBody = '{ "applicationName": "x-ald-sferp-api", "success": false, "statusCode": "504", "correlationId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "results": [ { "lpcRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSfid": "'+newSR.Id+'", "sfSalesorderId": "'+newSR.SalesOrder__c+'", "sfId": "'+soOther.Id+'", "erpId": "", "status": "Failed", "errorMsg": "TEST", "othChgRes": [{ "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSFId": "'+newSR.Id+'", "sfId": "'+soOther.Id+'", "erpId": "", "recAcct": "", "expAcct": "", "taxAcct":"", "status": "Failed", "errorMsg": "status", "invoiceNo": "" }] } ] } ] }';
        Test.startTest();
        soOther.TypeOfCharge__c = 'Legal Fee';
        update soOther;
        LPCCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        Test.stopTest();
    }
    
    @isTest
    public static void callMethod5(){
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c  from HexaBPM__Service_Request__c Limit 1];
        SalesOrderOtherCharges__c soOther = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES LIMIT 1];

        //String requestBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","results": {"lpcRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfSalesorderId": "'+salesOrder.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Success","errorMsg": ""}],"othChgRes": [{"sfRequestId": "23ed3fd0-7a1b-11ed-b041-06f6f65433a0","srSfid": "'+newSR.Id+'","sfId": "'+soOther.Id+'","erpId": "","status": "Failure","errorMsg": "Manual other charges creation processORA-0000: normal, successful completion"}]}}';
        String requestBody = '{ "applicationName": "x-ald-sferp-api", "success": false, "statusCode": "504", "correlationId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "results": [ { "lpcRes": [ { "sfRequestId": "025c1650-1fc2-11ee-ba35-06b067bb389c", "srSfid": "'+newSR.Id+'", "sfSalesorderId": "'+newSR.SalesOrder__c+'", "sfId": "'+soOther.Id+'", "erpId": "", "status": "Failed", "errorMsg": "TEST", "othChgRes": [] } ] } ] }';
        Test.startTest();
        soOther.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES;
        update soOther;
        LPCCalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        Test.stopTest();
    }
    
    @isTest
    public static void callMethod6 (){
        HexaBPM__Service_Request__c newSR = [SELECT Id,SalesOrder__c from HexaBPM__Service_Request__c Limit 1];
        SalesOrderOtherCharges__c soOther = [SELECT Id FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:newSR.SalesOrder__c and TypeOfCharge__c=:Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES LIMIT 1];

        String requestBody = '';
        Test.startTest();

		requestBody = '{  "applicationName": "x-ald-sferp-apisara",  "success": true,  "statusCode": "201",  "correlationId": "3424f270-a875-11ed-a086-06ea4c11b14a",  "results": [    {      "sfRequestId": "3424f270-a875-11ed-a086-06ea4c11b14a",      "srSfid": "'+newSR.Id+'",      "sfSalesorderId": "'+newSR.SalesOrder__c+'",      "instNum": "1",      "status": "Failure",      "errorMsg": "Invalid sales order :'+newSR.SalesOrder__c+'"    },    {      "sfRequestId": "3424f270-a875-11ed-a086-06ea4c11b14a",      "srSfid": "'+newSR.Id+'",      "sfSalesorderId": "'+newSR.SalesOrder__c+'",      "instNum": "2",      "status": "Failure",      "errorMsg": "Invalid sales order :'+newSR.SalesOrder__c+'"    },    {      "sfRequestId": "3424f270-a875-11ed-a086-06ea4c11b14a",      "srSfid": "'+newSR.Id+'",      "sfSalesorderId": "'+newSR.SalesOrder__c+'",      "instNum": "3",      "status": "Failure",      "errorMsg": "Invalid sales order :'+newSR.SalesOrder__c+'"    },    {      "sfRequestId": "3424f270-a875-11ed-a086-06ea4c11b14a",      "srSfid": "'+newSR.Id+'",      "sfSalesorderId": "'+newSR.SalesOrder__c+'",      "instNum": "4",      "status": "Failure",      "errorMsg": "Invalid sales order :'+newSR.SalesOrder__c+'"    }  ]}';      
		MuleResponeWrapper responseBody2 = (MuleResponeWrapper)System.JSON.deserialize(requestBody, MuleResponeWrapper.class);
        List<MuleResponeWrapper.MuleResponse> results2 = responseBody2.results; 
        
        LPCCalloutHelper.processLPCFreezeResponse(results2, Constants.FREEZE_LPC_INTEGRATION, requestBody, requestBody);

        LPCCalloutHelper.getDataForFreezeCallout(new List<Id>{newSR.Id}, true);
        LPCCalloutHelper.getDataForFreezeCallout(new List<Id>{newSR.Id}, false);

        Test.stopTest();
    }
}