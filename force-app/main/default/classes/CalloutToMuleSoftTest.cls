/*
*Created By     : Hardik Vitthani
*Description    : Test class for CalloutToMuleSoft
*last Modified By: Anuroop
*/
@isTest
public class CalloutToMuleSoftTest { 
    @isTest
    public static void testFutureService() {
        //FIN-140 Dummit comment
        Test.startTest(); 
        //String responseBody = '';
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"5d667sd4cs56dd","results":{"supplBrokerRes":[{"sfRequestId":"84543e50-0e41-11ed-894c-02449a9e937a","sfSupplierId":"' + acc.Id + '","sfResourceId":"","sfSiteId":"","sfContactId":"' + con.Id + '","oracleResourceId":"","oracleSupplierId":"12346","oracleSiteId":"","oracleContactId":"12345","status":"Success","errorMessage":""}],"brkrAgentDtls":[{"sfRequestId":"","sfSupplierId":"","sfResourceId":"","sfAgentId":"' + con.Id + '","oracleAgentId":"12345","status":"","errorMessage":""}]}}';
        
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
			
            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.AGENCY_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testUnitPrice() {
        Test.startTest();
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"9d5db2a0","results":[{"sfRequestId":"df06b0f0","sfId":"' + unit.Id + '","status":"Success","errorMessage":"","locationCode":"ALG-SW1_C451_A-2-06"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.PRICE_UPDATE, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testUnitStatus() {
        Test.startTest();
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"9d5db2a0","results":[{"sfRequestId":"9d5db2a0","sfId":"' + unit.Id + '","locationCode":"Mayan-B1-03-10","errorMessage":"Unit Mayan-B1-03-10 is not available to block/reserve","status":"Failure"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.STATUS_UPDATE, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testAgencySuccess() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"5d667sd4cs56dd","results":{"supplBrokerRes":[{"sfRequestId":"84543e50-0e41-11ed-894c-02449a9e937a","sfSupplierId":"' + acc.Id + '","sfResourceId":"","sfSiteId":"","sfContactId":"' + con.Id + '","oracleResourceId":"","oracleSupplierId":"12346","oracleSiteId":"","oracleContactId":"12345","status":"Success","errorMessage":""}],"brkrAgentDtls":[{"sfRequestId":"","sfSupplierId":"","sfResourceId":"","sfAgentId":"' + con.Id + '","oracleAgentId":"12345","status":"","errorMessage":""}]}}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
			MuleSOResponeWrapper muleWrap = new MuleSOResponeWrapper();
            muleWrap.parse(responseBody);
            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.AGENCY_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testAgencyFailure() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"5d667sd4cs56dd","results":{"supplBrokerRes":[{"sfRequestId":"84543e50-0e41-11ed-894c-02449a9e937a","sfSupplierId":"' + acc.Id + '","sfResourceId":"","sfSiteId":"","sfContactId":"' + con.Id + '","oracleResourceId":"","oracleSupplierId":"12346","oracleSiteId":"","oracleContactId":"12345","status":"Failure","errorMessage":"Error Message"}],"brkrAgentDtls":[{"sfRequestId":"","sfSupplierId":"","sfResourceId":"","sfAgentId":"' + con.Id + '","oracleAgentId":"12345","status":"Failure","errorMessage":"Error Message"}]}}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.AGENCY_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerSuccess() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"c482bd70","results":[{"sfRequestId":"c482bd70","sfId":"' + acc.Id + '","partyId":"123456","partyNumber":"12345","partySiteIdP":"12345","partySiteUseIdP":"12345","partySiteIdS":"12345","partySiteUseIdS":"12345","contactPointIdPhoneP":"12345","contactPointIdEmailP":"12345","locationIdP":"12345","contactPointIdPhoneS":"","contactPointIdEmailS":"","locationIdS":"12345","status":"Success","errorMsg":""}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.CUSTOMER_INTEGRATION, new List<Id>());
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

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.CUSTOMER_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerManual() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"c482bd70","results":[{"sfRequestId":"c482bd70","sfId":"' + acc.Id + '","partyId":"123456","partyNumber":"12345","partySiteIdP":"12345","partySiteUseIdP":"12345","partySiteIdS":"12345","partySiteUseIdS":"12345","contactPointIdPhoneP":"12345","contactPointIdEmailP":"12345","locationIdP":"12345","contactPointIdPhoneS":"","contactPointIdEmailS":"","locationIdS":"12345","status":"Failed","errorMsg":"Error Message"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            //SalesOrderCalloutHelper.EXECUTE_ACCOUNT_FIRST = true;
            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.CUSTOMER_INTEGRATION, new List<Id>());
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

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.JOINTOWNER_INTEGRATION, new List<Id>());
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

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.JOINTOWNER_INTEGRATION, new List<Id>());
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

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.JOINTOWNER_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testMarketingReimbursementSuccess() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"d9b69c80","results":[{"sfRequestId":"d9b69c80","sfId":"' + brokerRequest.Id + '","status":"Success","errorMessage":"","erpId":"75433"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.MARKETING_REIMBURSEMENT_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testMarketingReimbursementFailure() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'TESTAGENCY');
        acc.ERPId__c = '12345';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"d9b69c80","results":[{"sfRequestId":"d9b69c80","sfId":"' + brokerRequest.Id + '","status":"Failed","errorMessage":"Error Message","erpId":"75433"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.MARKETING_REIMBURSEMENT_INTEGRATION, new List<Id>());
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

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.SALESORDER_INTEGRATION, new List<Id>());
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

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.SALESORDER_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testReceiptSuccess() {
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

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;

//        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"acbbfff0","results":{"paymentRes":[{"recordId":"' + receiptAcknowledgement.Id + '","sfRequestId":"acbbfff0","erpCheckId":"8296059","status":"Success","errorMsg":""}],"receiptApplRes":[{"recAckRecordId":"' + receiptAcknowledgement.Id + '","recordId":"' + receiptAllocation.Id + '","sfRequestId":"acbbfff0","erpCheckId":"8296059","erpCheckApplId":"3221722","status":"Success","errorMsg":""}]}}';
        String responseBody = '{  "applicationName": "x-ald-sferp-api","success": true,  "statusCode": "201",  "correlationId": "acbbfff0",  "results": {    "paymentRes": [      {        "recordId": "' + receiptAcknowledgement.Id + '",        "sfRequestId": "acbbfff0",        "erpCheckId": "8296059",        "status": "Success",        "errorMsg": "",		"receiptApplRes": [		  {			"recAckRecordId": "' + receiptAcknowledgement.Id + '",			"recordId": "' + receiptAllocation.Id + '",			"sfRequestId": "acbbfff0",			"erpCheckId": "8296059",			"erpCheckApplId": "3221722",			"status": "Success",			"errorMsg": ""		  }		]      }    ]  }}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.PAYMENT_CHQ_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testReceiptFailure() {
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

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;

        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"acbbfff0","results":{"paymentRes":[{"recordId":"' + receiptAcknowledgement.Id + '","sfRequestId":"acbbfff0","erpCheckId":"8296059","status":"Failure","errorMsg":"Error Message","receiptApplRes":[{"recAckRecordId":"' + receiptAcknowledgement.Id + '","recordId":"' + receiptAllocation.Id + '","sfRequestId":"acbbfff0","erpCheckId":"8296059","erpCheckApplId":"3221722","status":"Failure","errorMsg":"Error Message"}]}]}}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.PAYMENT_CHQ_INTEGRATION, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }
    
    /*@isTest
    public static void testProcessResponse() {
        Test.startTest();
        String responseBody = '{"test":"test"}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            CalloutToMuleSoft.processSO500MuleErrorResponse(null, 'test', null, null);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            
        }
        Test.stopTest();
        
    }*/

    @isTest
    public static void testProcessSO500MuleErrorResponse() {
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;

        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, accountRecord.Id);
        so.Unit__c = unit.id;
        insert so;

        String requestBody = '{"salesOrderDetails":[{"sfSalesOrderNum":"' + so.Id + '"}]}';

        MuleSOResponeWrapper mockWrapper = new MuleSOResponeWrapper();
        mockWrapper.statusCode = '500';
        mockWrapper.success = false;

        String muleRes = '{"error":"Internal Server Error"}';

        Test.startTest();
        CalloutToMuleSoft.processSO500MuleErrorResponse(mockWrapper, 'testProcess', requestBody, muleRes);
        Test.stopTest();

        SalesOrder__c updatedSO = [SELECT Id, SyncStatus__c, RetryCount__c, ErrorReason__c FROM SalesOrder__c WHERE Id = :so.Id];
        System.assertEquals(Constants.STATUS_FAILED, updatedSO.SyncStatus__c, 'SyncStatus__c should be set to FAILED');
        System.assertEquals('500', updatedSO.ErrorReason__c, 'ErrorReason__c should be set to statusCode');
        System.assertEquals(1, updatedSO.RetryCount__c, 'RetryCount should be incremented');
    }
    
    @isTest
    public static void tesProject() {
        Test.startTest();
        
        Project__c p1= TestObjectsFactory.getProjectRecord('45223452');
        insert p1;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"9d5db2a0","results":[{"sfRequestId":"df06b0f0","sfId":"' + p1.Id + '","status":"Success","errorMessage":"","locationCode":"ALG-SW1_C451_A-2-06"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.Damascus_Callback_Project, new List<Id>());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }
    
    @isTest
    public static void tesProperty() {
        Test.startTest();
        
         Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"9d5db2a0","results":[{"sfRequestId":"df06b0f0","sfId":"' + unit.Id + '","status":"Success","errorMessage":"","locationCode":"ALG-SW1_C451_A-2-06"}]}';
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

            CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, Constants.Damascus_Callback_Property, new List<Id>());
        	CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, 'BankIntegrationVA', new List<Id>());
        	CalloutToMuleSoft.calloutFutureService('{"test":"test"}', true, 'InvoiceBundle', new List<Id>());
        
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
            Test.stopTest();
        }
        Test.stopTest();
    }

    @isTest
    public static void testMakeCallout() {
        Project__c p1 = TestObjectsFactory.getProjectRecord('12345678');
        insert p1;

        String responseBody = '{"success":true,"status":"Success","sfId":"' + p1.Id + '"}';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

        Test.startTest();

        String dummyRequest = '{"test":"value"}';
        String processName = Constants.Damascus_Callback_Project;

        HttpResponse res = CalloutToMuleSoft.makeCallout(processName, dummyRequest);

        Test.stopTest();

        System.assertEquals(200, res.getStatusCode(), 'Status should be 200');
        System.assert(res.getBody().contains('"Success"'), 'Response should contain "Success"');
    }
}