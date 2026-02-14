/**
 * CustomRulesHelper
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CustomRulesHelperTest {

    @testSetup static void setupData() {

        Test.startTest();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
    
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
    
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
    
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.HoldReasonCode__c = 'test123';
        salesOrder.RebateForfeitureLetterSent__c = false;
        salesOrder.AdditionalRebate__c = 50;
        salesOrder.AdditionalRebate2__c = 50;
        salesOrder.LastInstallmentRebate__c = 50;
        salesOrder.OtherRebateAmount__c = 50;
        insert salesOrder;

        system.debug('salesOrder' + salesOrder.OutstandingAmount__c + salesOrder.TotalOutstanding__c);
    
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c(
            Name = 'Additional Rebate Request',
            HexaBPM__SR_RecordType_API_Name__c = 'Rebate_Request'
        );
        insert SR_Template;
    
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c(
            RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Rebate Request'),
            SRType__c =  'Rebate Request',
            HexaBPM__Customer__c = acc.Id,
            HexaBPM__Contact__c = acc.PersonContactId,
            HexaBPM__SR_Template__c = SR_Template.Id,
            Unit__c = unit.Id,
            SalesOrder__c = salesOrder.Id,
            StepClosureDate__c = Date.today(),
            Rebate_to_be_Offered__c = 0.00,
            Additional_Rebate_Offered__c = 0.00
        );
        insert SR;
    
        SRUnitSelected__c srUnit = new SRUnitSelected__c(
            
            Name = salesOrder.UnitNumber__c,
            OutstandingAmount__c = 900000.00,
            Previous_Rebate_Offered__c = 70005.00,
            ServiceRequest__c = SR.Id,
            Unit__c = unit.Id,
            SalesOrder__c = salesOrder.Id,
            Rebate_Percentage__c = 20
        );
        insert srUnit;
    
        SRUnitSelected__c srUnit2 = new SRUnitSelected__c(
            Name = salesOrder.UnitNumber__c,
            OutstandingAmount__c = 900000.00,
            Previous_Rebate_Offered__c = 70005.00,
            ServiceRequest__c = SR.Id,
            Unit__c = unit.Id,
            SalesOrder__c = salesOrder.Id,
            Rebate_Percentage__c = 90
        );
        insert srUnit2;
    
        HexaBPM__Step_Template__c[] stepTemplates = new HexaBPM__Step_Template__c[]{
            
            new HexaBPM__Step_Template__c(Name = 'Approval of the Request By D&T', HexaBPM__Code__c = 'Approval of the Request By D&T', HexaBPM__Step_RecordType_API_Name__c = 'General'),
            new HexaBPM__Step_Template__c(Name = 'Verification by Finance', HexaBPM__Code__c = 'Verification by Finance', HexaBPM__Step_RecordType_API_Name__c = 'General'),
            new HexaBPM__Step_Template__c(Name = 'Payment Step', HexaBPM__Code__c = 'Payment Step', HexaBPM__Step_RecordType_API_Name__c = 'General')
        };
        insert stepTemplates;
    
        HexaBPM__Status__c[] statusList = new HexaBPM__Status__c[]{
            new HexaBPM__Status__c(Name = Constants.PENDING_STATUS, HexaBPM__Code__c = Constants.PENDING_STATUS),
            new HexaBPM__Status__c(Name = Constants.STATUS_APPROVED, HexaBPM__Code__c = Constants.STATUS_APPROVED),
            new HexaBPM__Status__c(Name = Constants.COMPLETED_STATUS, HexaBPM__Code__c = Constants.COMPLETED_STATUS)
        };
        insert statusList;
    
        HexaBPM__SR_Steps__c[] SRstepsList = new HexaBPM__SR_Steps__c[]{
            new HexaBPM__SR_Steps__c(
                HexaBPM__SR_Template__c = SR_Template.id,
                HexaBPM__Step_No__c = 2,
                HexaBPM__Step_Template__c = stepTemplates[1].Id,
                HexaBPM__Summary__c = 'Verification by Finance',
                HexaBPM__Step_RecordType_API_Name__c = 'General'
            ),
            new HexaBPM__SR_Steps__c(
                HexaBPM__SR_Template__c = SR_Template.id,
                HexaBPM__Step_No__c = 1,
                HexaBPM__Step_Template__c = stepTemplates[2].Id,
                HexaBPM__Summary__c = 'Payment Verification',
                HexaBPM__Step_RecordType_API_Name__c = 'General'
            ),
            new HexaBPM__SR_Steps__c(
                HexaBPM__SR_Template__c = SR_Template.id,
                HexaBPM__Step_No__c = 1,
                HexaBPM__Step_Template__c = stepTemplates[0].Id,
                HexaBPM__Summary__c = 'Approval of the Request By D&T',
                HexaBPM__Step_RecordType_API_Name__c = 'General'
            )
        };
        insert SRstepsList;
    
        HexaBPM__Step__c[] stepList = new HexaBPM__Step__c[]{
            new HexaBPM__Step__c(
                HexaBPM__Summary__c = 'Verification by Finance',
                HexaBPM__SR__c = SR.Id,
                HexaBPM__SR_Step__c = SRstepsList[0].Id,
                HexaBPM__Start_Date__c = Date.today(),
                HexaBPM__Status__c = statusList[0].id
            ),
            new HexaBPM__Step__c(
                HexaBPM__Summary__c = 'Payment Verification',
                HexaBPM__SR__c = SR.Id,
                HexaBPM__SR_Step__c = SRstepsList[1].Id,
                HexaBPM__Start_Date__c = Date.today(),
                HexaBPM__Status__c = statusList[2].id
            ),
            new HexaBPM__Step__c(
                HexaBPM__Summary__c = 'Approval of the Request By D&T',
                HexaBPM__SR__c = SR.Id,
                HexaBPM__SR_Step__c = SRstepsList[2].Id,
                HexaBPM__Start_Date__c = Date.today(),
                HexaBPM__Status__c = statusList[1].id
            )
        };
        insert stepList;
    
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Note');
        insert receiptAcknowledgement;
        ReceiptAcknowledgement__c ra = new ReceiptAcknowledgement__c(
            Account__c = sr.HexaBPM__Customer__c,
            ServiceRequest__c = sr.Id,
            PaymentType__c = CONSTANTS.OTHER_CHARGES_TYPE_CREDIT_NOTE,
            PaymentSubType__c = Constants.PAYMENT_SUB_TYPE_REBATE,
            Remarks__c = Constants.BUDGET_LINE_REBATE,
            IsStopSyncingWithERP__c = true,
            Amount__c = 2000,
            SalesOrder__c = salesOrder.Id,
            Opportunity__c = opp.Id
        );
          
          ReceiptAcknowledgementService.queryAllFieldsWithExtraFields(new List<Id>{receiptAcknowledgement.Id});
          ReceiptAcknowledgementService.getReceiptAcknowledgementById(receiptAcknowledgement.Id); 
          

          Test.stopTest();
      }
    

    
    static testMethod void testGetSOandUnitDetails() {

        HexaBPM__Service_Request__c sr = [Select id, HexaBPM__Customer__c, HexaBPM__External_Status_Name__c, Rebate_to_be_Offered__c, Additional_Rebate_Offered__c FROM HexaBPM__Service_Request__c];
        List<SalesOrder__c> salesOrders =[Select id,Account__c,Status__c,OutstandingAmount__c,UnitNumber__c,Unit__c FROM SalesOrder__c];
        List<SRUnitSelected__c> selectedUnitList=[select Id,Name,ServiceRequest__c,OutstandingAmount__c,Unit_Selling_Price__c,SellingPrice__c,SalesOrder__c, Unit__c,Rebate_Percentage__c,Previous_Rebate_Offered__c from SRUnitSelected__c];
               
        Test.startTest();
        // Call the method being tested
        CustomRulesHelper.OnloadUnitWrapper result = CustomRulesHelper.getSOandUnitDetails(sr.Id);
        List<SRUnitSelected__c> Unitresult = CustomRulesHelper.getSelectedUnits(sr.Id, salesOrders);
        CustomRulesHelper.createSelectedUnits(selectedUnitList,sr.id, 20, 8000);
        CustomRulesHelper.RemoveSelectedUnits(new List<String>{selectedUnitList[0].id}, sr.Id);
        Test.stopTest();
        
    }

    static testMethod void testGetSOandUnitDetails1() {

        HexaBPM__Service_Request__c sr = [Select id, HexaBPM__Customer__c, HexaBPM__External_Status_Name__c, Rebate_to_be_Offered__c, Additional_Rebate_Offered__c FROM HexaBPM__Service_Request__c];
        List<SalesOrder__c> salesOrders =[Select id,Account__c,UnitSellingPrice__c,RebateForfeitureLetterSent__c, TotalOutstanding__c,LastInstallmentRebate__c,OtherRebateAmount__c,AdditionalRebate__c,AdditionalRebate2__c,Status__c,OutstandingAmount__c,UnitNumber__c,Unit__c FROM SalesOrder__c];
        List<SRUnitSelected__c> selectedUnitList=[select Id,Name,ServiceRequest__c,OutstandingAmount__c,Unit_Selling_Price__c,SellingPrice__c,SalesOrder__c, Unit__c,Rebate_Percentage__c,Previous_Rebate_Offered__c from SRUnitSelected__c];
               delete selectedUnitList;
        Test.startTest();
        List<SRUnitSelected__c> Unitresult = CustomRulesHelper.getSelectedUnits(sr.Id, salesOrders);
        Test.stopTest();
        
    }
    static testMethod void testgetSelectedUnits() {

        HexaBPM__Service_Request__c sr = [Select id, HexaBPM__Customer__c,ReceiptAcknowledgement__c, HexaBPM__External_Status_Name__c, Rebate_to_be_Offered__c, Additional_Rebate_Offered__c FROM HexaBPM__Service_Request__c];
        sr.Additional_Rebate_Offered__c = 10000;
        update sr;
        List<SalesOrder__c> salesOrders =[Select id,Account__c,Status__c,OutstandingAmount__c,UnitNumber__c,Unit__c FROM SalesOrder__c];
        List<SRUnitSelected__c> selectedUnitList=[select Id, Name,ServiceRequest__c,Unit__c,Rebate_Percentage__c,SalesOrder__c,SalesOrder__r.Opportunity__c
        FROM SRUnitSelected__c];
        HexaBPM__Step__c stp = [Select Id ,HexaBPM__Step_Status__c, Step_Template_Code__c, HexaBPM__Status__c,OwnerId, OwnerName__c, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Payment Verification'];
         
        Test.startTest();
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+sr.Id+'","status": "Success","errorMsg": "","erpId": "185506"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        CustomRulesHelper.createSOA(sr.Id);
        CustomRulesHelper.handleAdditionalRebateReceipt(sr.Id);
        CustomRulesHelper.getDataForCallout(new List<Id>{sr.Id});
       
        Test.stopTest();
    }

    static testMethod void testFailedResponse() {

        HexaBPM__Service_Request__c sr = [Select id, HexaBPM__Customer__c,ReceiptAcknowledgement__c, HexaBPM__External_Status_Name__c, Rebate_to_be_Offered__c, Additional_Rebate_Offered__c FROM HexaBPM__Service_Request__c];
        sr.Additional_Rebate_Offered__c = 10000;
        update sr;
        List<SalesOrder__c> salesOrders =[Select id,Account__c,Status__c,OutstandingAmount__c,UnitNumber__c,Unit__c FROM SalesOrder__c];
        List<SRUnitSelected__c> selectedUnitList=[select Id, Name,ServiceRequest__c,Unit__c,Rebate_Percentage__c,SalesOrder__c,SalesOrder__r.Opportunity__c
        FROM SRUnitSelected__c];
        HexaBPM__Step__c stp = [Select Id ,HexaBPM__Step_Status__c, Step_Template_Code__c, HexaBPM__Status__c,OwnerId, OwnerName__c, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Payment Verification'];
        HexaBPM__SR_Status__c srStatus2 = new HexaBPM__SR_Status__c();   
        Test.startTest();
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+sr.Id+'","status": "Failed","errorMsg": "Failed","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            CustomRulesHelper.createSOA(sr.Id);
        CustomRulesHelper.handleAdditionalRebateReceipt(sr.Id);
        CustomRulesHelper.getDataForCallout(new List<Id>{sr.Id});
       
        Test.stopTest();
    }

    
}