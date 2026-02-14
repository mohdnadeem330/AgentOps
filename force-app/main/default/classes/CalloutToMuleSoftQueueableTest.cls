/*
*Created By     : Hardik Vitthani
*Description    : Test class for CalloutToMuleSoftQueueable
*/
@isTest
public class CalloutToMuleSoftQueueableTest {
    @isTest
    public static void testCustomerSalesOrderSuccess() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"c482bd70","results":[{"sfRequestId":"c482bd70","sfId":"' + acc.Id + '","partyId":"123456","partyNumber":"12345","partySiteIdP":"12345","partySiteUseIdP":"12345","partySiteIdS":"12345","partySiteUseIdS":"12345","contactPointIdPhoneP":"12345","contactPointIdEmailP":"12345","locationIdP":"12345","contactPointIdPhoneS":"","contactPointIdEmailS":"","locationIdS":"12345","status":"Success","errorMsg":""}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            System.enqueueJob(new CalloutToMuleSoftQueueable('{"test":"test"}', true, Constants.CUSTOMER_INTEGRATION, new List<Id>(), 'SalesOrder__c'));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerJointOwnerSuccess() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"c482bd70","results":[{"sfRequestId":"c482bd70","sfId":"' + acc.Id + '","partyId":"123456","partyNumber":"12345","partySiteIdP":"12345","partySiteUseIdP":"12345","partySiteIdS":"12345","partySiteUseIdS":"12345","contactPointIdPhoneP":"12345","contactPointIdEmailP":"12345","locationIdP":"12345","contactPointIdPhoneS":"","contactPointIdEmailS":"","locationIdS":"12345","status":"Success","errorMsg":""}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            System.enqueueJob(new CalloutToMuleSoftQueueable('{"test":"test"}', true, Constants.CUSTOMER_INTEGRATION, new List<Id>(), 'JointOwner__c'));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerFailure() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"c482bd70","results":[{"sfRequestId":"c482bd70","sfId":"' + acc.Id + '","partyId":"123456","partyNumber":"12345","partySiteIdP":"12345","partySiteUseIdP":"12345","partySiteIdS":"12345","partySiteUseIdS":"12345","contactPointIdPhoneP":"12345","contactPointIdEmailP":"12345","locationIdP":"12345","contactPointIdPhoneS":"","contactPointIdEmailS":"","locationIdS":"12345","status":"Failed","errorMsg":"Error Message"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            System.enqueueJob(new CalloutToMuleSoftQueueable('{"test":"test"}', true, Constants.CUSTOMER_INTEGRATION, new List<Id>(), ''));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testJointOwnerSuccess() {
        Test.startTest();
        
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAcc.Id, 'Friend Of');
        insert jointOwner;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"acd8b5e0","results":[{"jointOwnerId":"19805","salesOrderId":"96413","partyId":"4035405","mode":"CREATE","sfId":"' + jointOwner.Id + '","sfRequestId":"acd8b5e0","status":"Success","errorMsg":""}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            System.enqueueJob(new CalloutToMuleSoftQueueable('{"test":"test"}', true, Constants.JOINTOWNER_INTEGRATION, new List<Id>(), ''));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testJointOwnerDeleteSuccess() {
        Test.startTest();
        
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAcc.Id, 'Friend Of');
        insert jointOwner;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"acd8b5e0","results":[{"jointOwnerId":"19805","salesOrderId":"96413","partyId":"4035405","mode":"DELETE","sfId":"' + jointOwner.Id + '","sfRequestId":"acd8b5e0","status":"Success","errorMsg":""}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            System.enqueueJob(new CalloutToMuleSoftQueueable('{"test":"test"}', true, Constants.JOINTOWNER_INTEGRATION, new List<Id>(), ''));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testJointOwnerFailure() {
        Test.startTest();
        
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAcc.Id, 'Friend Of');
        insert jointOwner;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"acd8b5e0","results":[{"jointOwnerId":"19805","salesOrderId":"96413","partyId":"4035405","mode":"CREATE","sfId":"' + jointOwner.Id + '","sfRequestId":"acd8b5e0","status":"Failure","errorMsg":"Error Messgae"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            System.enqueueJob(new CalloutToMuleSoftQueueable('{"test":"test"}', true, Constants.JOINTOWNER_INTEGRATION, new List<Id>(), ''));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testSalesOrderSuccess() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        SalesOrderOtherCharges__c salesOrderOtherCharge = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        List<OpportunityOfferLine__c> opportunityOfferLineList = TestObjectsFactory.createOpportunityOfferLines(salesOrder.Id, 5);
        CommissionLineItem__c commissionLineItem = TestObjectsFactory.createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);
        String responseBody = '{  "applicationName": "x-ald-sferp-api",  "success": true,  "statusCode": "201",  "correlationId": "4bc9d380",  "results": {    "salesOrderRes": [      {        "sfRequestId": "4bc9d380",        "sfSalesOrderNum": "' + salesOrder.Id + '",        "erpSalesOrderId": "97348",        "erpPayPlanId": "",        "erpCustAcctId": "",        "status": "Success",        "errorMsg": "",		"salesConsultantRes": [		  {			"sfRequestId": "4bc9d380",			"sfSalesOrderNum": "' + salesOrder.Id + '",			"sfRecId": "' + commissionLineItem.Id + '",		"commInstNum": "1",			"brokerAgent": "Test Agent",			"salesManager": "",			"saleConsulRecId": "44345",			"status": "Success",			"errorMsg": ""		  }],		  "salesOrderlineRes": [			  {				"sfRequestId": "4bc9d380",				"sfSalesOrderNum": "' + salesOrder.Id + '",				"sfInstId": "' + installmentLineList[0].Id + '",				"erpInstId": "376237",				"status": "Success",				"errorMsg": ""			  }			]      }    ]     }}';
//        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"4bc9d380","results":{"salesOrderRes":[{"sfRequestId":"4bc9d380","sfSalesOrderNum":"' + salesOrder.Id + '","erpSalesOrderId":"97348","erpPayPlanId":"","erpCustAcctId":"","status":"Success","errorMsg":""}],"salesConsultantRes":[{"sfRequestId":"4bc9d380","sfSalesOrderNum":"' + salesOrder.Id + '","sfRecId":"' + commissionLineItem.Id + '","commInstNum":"1","brokerAgent":"Test Agent","salesManager":"","saleConsulRecId":"44345","status":"Success","errorMsg":""}],"salesOrderlineRes":[{"sfRequestId":"4bc9d380","sfSalesOrderNum":"' + salesOrder.Id + '","sfInstId":"' + installmentLineList[0].Id + '","erpInstId":"376237","status":"Success","errorMsg":""}]}}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            System.enqueueJob(new CalloutToMuleSoftQueueable('{"test":"test"}', true, Constants.SALESORDER_INTEGRATION, new List<Id>(), ''));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testSalesOrderFailure() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        SalesOrderOtherCharges__c salesOrderOtherCharge = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        List<OpportunityOfferLine__c> opportunityOfferLineList = TestObjectsFactory.createOpportunityOfferLines(salesOrder.Id, 5);
        CommissionLineItem__c commissionLineItem = TestObjectsFactory.createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);
        String responseBody = '{  "applicationName": "x-ald-sferp-api",  "success": true,  "statusCode": "201",  "correlationId": "4bc9d380",  "results": {    "salesOrderRes": [      {        "sfRequestId": "4bc9d380",        "sfSalesOrderNum": "' + salesOrder.Id + '",        "erpSalesOrderId": "97348",        "erpPayPlanId": "",        "erpCustAcctId": "",        "status": "Failure",        "errorMsg": "",		"salesConsultantRes": [		  {			"sfRequestId": "4bc9d380",			"sfSalesOrderNum": "' + salesOrder.Id + '",			"sfRecId": "' + commissionLineItem.Id + '",		"commInstNum": "1",			"brokerAgent": "Test Agent",			"salesManager": "",			"saleConsulRecId": "44345",			"status": "Success",			"errorMsg": ""		  }],		  "salesOrderlineRes": [			  {				"sfRequestId": "4bc9d380",				"sfSalesOrderNum": "' + salesOrder.Id + '",				"sfInstId": "' + installmentLineList[0].Id + '",				"erpInstId": "376237",				"status": "Success",				"errorMsg": ""			  }			]      }    ]     }}';
//        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"4bc9d380","results":{"salesOrderRes":[{"sfRequestId":"4bc9d380","sfSalesOrderNum":"' + salesOrder.Id + '","erpSalesOrderId":"97348","erpPayPlanId":"","erpCustAcctId":"","status":"Failure","errorMsg":"Error Message"}],"salesConsultantRes":[{"sfRequestId":"4bc9d380","sfSalesOrderNum":"' + salesOrder.Id + '","sfRecId":"' + commissionLineItem.Id + '","commInstNum":"1","brokerAgent":"Test Agent","salesManager":"","saleConsulRecId":"44345","status":"Failure","errorMsg":"Error Message"}],"salesOrderlineRes":[{"sfRequestId":"4bc9d380","sfSalesOrderNum":"' + salesOrder.Id + '","sfInstId":"' + installmentLineList[0].Id + '","erpInstId":"376237","status":"Failure","errorMsg":"Error Message"}]}}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            System.enqueueJob(new CalloutToMuleSoftQueueable('{"test":"test"}', true, Constants.SALESORDER_INTEGRATION, new List<Id>(), ''));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        CalloutToMuleSoftQueueable.updateStatusAsFailed(new list<ID>{salesOrder.id});
        
        Test.stopTest();
    }
    @isTest
    public static void testSalesOrderFailure2() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        CalloutToMuleSoftQueueable.prepareRequestBodyforRetry(new Map<Id, MuleResponeWrapper.MuleResponse>{acc.id => new MuleResponeWrapper.MuleResponse()});
    }
    
}