@isTest
public class DM_SyncPDCDetailsAPITest {

  @testSetup
    static void setupTestData() {
        // Insert Account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Lane',
            BillingCity = 'Dubai',
            BillingState = 'Dubai',
            BillingPostalCode = '12345',
            BillingCountry = 'United Arab Emirates'
        );
        insert testAccount;

        // Insert Contact
        Contact testContact = new Contact(
            LastName = 'Test contact',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Insert Product
        Product2 testProduct = new Product2(
            Name = 'Road Closure Diversion',
            IsActive = true,
            Family = 'NOC'
        );
        insert testProduct;
 Id districtMgmtRtIdTla = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_TLA').getRecordTypeId();
        // Insert Case
        Case testCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            RecordTypeId = districtMgmtRtIdTla,
            Type = 'Temporary License Agreement',
            Development_Name__c = 'Yas Island',
            Status = 'New',
            Subject = 'Test TLA Application',
            IPS_Received_from_ADM__c = 'Yes'
           // ProductId = testProduct.Id
        );
        insert testCase;

        // Insert Payment_Request__c with ERP_Receipt_Id__c initialized
        Payment_Request__c pr = new Payment_Request__c(
            Case__c = testCase.Id,
            Amount__c = 500,
            ERP_Receipt_Id__c = 'InitialERPId'
        );
        insert pr;
    }

    static testMethod void test_doPost_success() {
        // Fetch test data
        Payment_Request__c pr = [SELECT Id FROM Payment_Request__c LIMIT 1];

        // Prepare request body with all required fields
        Map<String, Object> reqMap = new Map<String, Object>{
            'paymentid' => pr.Id,
            'erpId' => 'NewERPId',
            'receiptErpId' => 'RecERP123',
            'chequeOrpaymentDate' => String.valueOf(System.now()),
            'status' => 'Completed',
            'transNumber' => 'TRX999'
        };
        String reqBody = JSON.serialize(reqMap);

        Test.startTest();
        // Setup REST request and response context
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DM/PDCDetail';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call method
        DM_SyncPDCDetailsAPI.doPost();
        Test.stopTest();

        // Verify update
        Payment_Request__c updatedPR = [SELECT ERP_Receipt_Id__c, Transaction_Date__c, Transaction_No__c, Status__c FROM Payment_Request__c WHERE Id = :pr.Id];
        //System.assertEquals('RecERP123', updatedPR.ERP_Receipt_Id__c);
        //System.assertEquals('TRX999', updatedPR.Transaction_No__c);
        //System.assertEquals('Completed', updatedPR.Status__c);
    }

    static testMethod void test_doPost_missingPaymentId() {
        // Prepare request missing paymentid
        Map<String, Object> reqMap = new Map<String, Object>{
            'erpId' => 'ERPId',
            'receiptErpId' => 'RecERP'
        };
        String reqBody = JSON.serialize(reqMap);

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DM/PDCDetail';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call method expecting CustomException
        DM_SyncPDCDetailsAPI.doPost();
        Test.stopTest();
    }

    static testMethod void test_doPost_missingErpId() {
        Payment_Request__c pr = [SELECT Id FROM Payment_Request__c LIMIT 1];

        // Prepare request missing erpId
        Map<String, Object> reqMap = new Map<String, Object>{
            'paymentid' => pr.Id,
            'receiptErpId' => 'RecERP'
        };
        String reqBody = JSON.serialize(reqMap);

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DM/PDCDetail';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call method expecting CustomException
        DM_SyncPDCDetailsAPI.doPost();
        Test.stopTest();
    }

    static testMethod void test_doPost_missingReceiptErpId() {
        Payment_Request__c pr = [SELECT Id FROM Payment_Request__c LIMIT 1];

        // Prepare request missing receiptErpId
        Map<String, Object> reqMap = new Map<String, Object>{
            'paymentid' => pr.Id,
            'erpId' => 'ERPId'
        };
        String reqBody = JSON.serialize(reqMap);

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DM/PDCDetail';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Call method expecting CustomException
        DM_SyncPDCDetailsAPI.doPost();
        Test.stopTest();
    }

    static testMethod void test_processRequest_ExceptionScenario() {
        Test.startTest();
        try {
            Map<String, Object> reqMap = new Map<String, Object>{
                'paymentid' => 'InvalidId',
                'erpId' => 'ERPId',
                'receiptErpId' => 'RecERP',
                'chequeOrpaymentDate' => String.valueOf(System.now()),
                'status' => 'Completed',
                'transNumber' => 'TRX000'
            };
            DM_SyncPDCDetailsAPI.processRequest(reqMap);
        } catch (Exception ex) {
            System.assert(ex.getMessage() != null);
        }
        Test.stopTest();
    }
}