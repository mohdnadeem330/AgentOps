@isTest
private class DarnaServicesTest {
  
    //Create setupData
    @testSetup static void setupData() {


        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 1000;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;

        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;

        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        Case caseRecord = TestObjectsFactory.getCaseRecord(recordTypeId, '', unit.Id, 'Phone');
        caseRecord.subject = 'Test Case';
        insert caseRecord;
       
    }
    
    @isTest
    public static void addPointsAPITest (){
        Test.startTest();

        
        ReceiptAllocation__c receiptAllocation = [Select Id From ReceiptAllocation__c Limit 1];

        String responseBody = '{"message":"aa","http_response":"200","redemption_mode":"123","points":"200","success":"true","concept_id":"123","redemption_id":"123","redemption_reference_code":"123","burn_rate":"123","email":"aa","membership_number":"123","mobile_number":"123456","first_name":"123456","last_name":"123","is_active":"123","member_status":"123","registration_date":"123","available_points":"123","amount":"123","currency":"123","minimum_redeemable_points":"123","minimum_redeemable_amount":"123","data":{\"client_access_token\":\"123\","external_transaction_id":"'+receiptAllocation.Id+'"}}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

        //DarnaServices.getUserProfileAPI('','','');
        //DarnaServices.getUserPointsAPI('','');
        DarnaServices.getAccessTokenAPI();
        //DarnaServices.redeemPointsAPI('membershipNumber', 'token', 'trxId', 'otp', 'amount', 'mode','conceptId');
        //DarnaServices.otpRequest('membershipNumber', 'token');

        Test.stopTest();
    }

    @isTest
    public static void otherCalloutsTest (){
        Test.startTest();

        ReceiptAllocation__c receiptAllocation = [SELECT Id From ReceiptAllocation__c Limit 1];
        ReceiptAcknowledgement__c rcptAcknowledgement = [SELECT Id From ReceiptAcknowledgement__c Limit 1];
        InstallmentLines__c installmentLine = [SELECT Id from InstallmentLines__c LIMIT 1];
        string billnumberStr = receiptAllocation.Id+'_'+rcptAcknowledgement.Id+'_'+installmentLine.Id;

        String responseBody = '{"response":[{"loyaltyDetails":[],"warnings":[{"message":"warning"}],"errors":[{"message":"errors"}],"result":{"useDefaultUserGroup2":false,"returnType":"FULL","billingDate":"2023-01-01T04:00:00Z","isUseDefaultUserGroup2":false,"sideEffects":[{"type":"points","awardedPoints":500,"rawAwardedPoints":500,"entityType":"USER"}],"notInterestedReason":"","lineItemsV2":[{"splitDetails":[],"addOnDetails":[],"comboDetails":[],"returnableDays":-1,"returnable":true,"value":187065,"rate":187065,"qty":1,"itemCode":"IL-0069576","discount":0,"description":"Down Payment","amount":25000}],"discount":0,"billNumber":"'+billnumberStr+'","billAmount":25000,"type":"REGULAR","source":"INSTORE","identifierValue":"971545412082","identifierType":"mobile"},"entityId":109845178}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

        DarnaServices.addPointsAPI('','');

        Case caseRec = [Select Id From Case Limit 1];

        //DarnaServices.createReceiptAcknowledgementForRedemption(caseRec.Id, 'Cheque', 100, 'referenceNumber', 'receiptNumber');
 
        Test.stopTest();
    }

    @isTest
    public static void capillaryVerifyCustomerAndPointsBalanceSuccessTest (){
        Test.startTest();

        String responseBody = '{"totalAvailablePoints":"aa","message":"200","status":"MatchFound","loyaltyProgramDetails" : [{"totalAvailablePoints":100,"message":"can be redeemed","status":true}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

       // DarnaServices.capillaryVerifyCustomerAndPointsBalance('aa','123456','token');
        
        Test.stopTest();
    }

    @isTest
    public static void capillaryAddPointsResponseModelTest (){
        Test.startTest();
        CapillaryAddPointsResponseModel model = new CapillaryAddPointsResponseModel();
        model.entityId = 100;
        model.result = new CapillaryAddPointsResponseModel.cls_result();
        model.errors = new List<CapillaryAddPointsResponseModel.cls_errors>(); 
        model.warnings = new List<CapillaryAddPointsResponseModel.cls_warnings>();              
        Test.stopTest();
    }
}