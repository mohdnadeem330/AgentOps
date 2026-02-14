@isTest
private class BP_SubmitBrokerRequestTest {

    @testSetup
    static void setupTestData() {
        // Create test BrokerRequest__c record
        Id RecordTypeId = Schema.SObjectType.BrokerRequest__c.getRecordTypeInfosByName().get('Marketing Reimbursement').getRecordTypeId();
        BrokerRequest__c brokerRequest = new BrokerRequest__c(
            InvoiceStatus__c = 'Draft',
            RecordTypeId = RecordTypeId
        );
        insert brokerRequest;
    }

    @isTest
    static void testProcessRequest_ValidData() {
        BrokerRequest__c existingBrokerRequest = [SELECT Id, InvoiceStatus__c FROM BrokerRequest__c LIMIT 1];
        String newStatus = 'Pending Invoice Verification';

        Map<String, String> params = new Map<String, String>();
        String requestBody = JSON.serialize(new Map<String, Object>{
            'brokerRequestId' => existingBrokerRequest.Id,
            'invoiceStatus' => newStatus,
            'type' => 'Marketing Reimbursement',
            'documentExtension' => 'pdf',
            'documentBase64' => 'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAIAAADTED8xAAADMElEQVR4nOzVwQnAIBQFQYXff81RUkQCOyDj1YOPnbXWPmeTRef+/3O/OyBjzh3CD95BfqICMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMO0TAAD//2Anhf4QtqobAAAAAElFTkSuQmCC'
        });

        Test.startTest();
        BP_SubmitBrokerRequest service = new BP_SubmitBrokerRequest();
        service.processRequest(params, requestBody);
        Test.stopTest();
    }

    @isTest
    static void testProcessRequest_InvalidBrokerRequestId() {
        Map<String, String> params = new Map<String, String>();
        String requestBody = JSON.serialize(new Map<String, Object>{
            'brokerRequestId' => 'invalidId',
            'invoiceStatus' => 'Pending Invoice Verification'
        });

        BP_SubmitBrokerRequest service = new BP_SubmitBrokerRequest();
        service.processRequest(params, requestBody);
    }

    @isTest
    static void testProcessRequest_MissingFields() {
        Map<String, String> params = new Map<String, String>();
        String requestBody = JSON.serialize(new Map<String, Object>{
            'brokerRequestId' => '',
            'invoiceStatus' => ''
        });

        BP_SubmitBrokerRequest service = new BP_SubmitBrokerRequest();
        service.processRequest(params, requestBody);
    }

    @isTest
    static void testExecuteMethod() {
        BrokerRequest__c existingBrokerRequest = [SELECT Id FROM BrokerRequest__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/submitBrokerRequest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'brokerRequestId' => existingBrokerRequest.Id,
            'invoiceStatus' => 'Paid'
        }));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_SubmitBrokerRequest.execute();
        Test.stopTest();

        // BrokerRequest__c updated = [SELECT InvoiceStatus__c FROM BrokerRequest__c WHERE Id = :existingBrokerRequest.Id];
        // System.assertEquals('Paid', updated.InvoiceStatus__c);
    }

    @isTest
    static void testProcessRequest_InvalidStatusData() {
        BrokerRequest__c existingBrokerRequest = [SELECT Id, InvoiceStatus__c FROM BrokerRequest__c LIMIT 1];
        
        Map<String, String> params = new Map<String, String>();
        String requestBody = JSON.serialize(new Map<String, Object>{
            'brokerRequestId' => existingBrokerRequest.Id,
            'invoiceStatus' => ''
        });

        Test.startTest();
        BP_SubmitBrokerRequest service = new BP_SubmitBrokerRequest();
        service.processRequest(params, requestBody);
        Test.stopTest();
    }
}