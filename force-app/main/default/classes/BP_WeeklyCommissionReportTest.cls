/**
     * Author: Upendra
     * Created Date: 2025-01-21
     */

@IsTest
private class BP_WeeklyCommissionReportTest {

    @testSetup
    static void setupTestData() {
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        accountRecord.UAEVATRegisterNumber__c='889766405212345';
        insert accountRecord;

        Contact con = new Contact();
        con.LastName = 'Alice';
        con.AccountId = accountRecord.Id;
        con.Email = 'test13@aldar.com';
        con.Phone = '527583669';
        con.OwnerId = UserInfo.getUserId();
        con.MobilePhone = '527583669';
        insert con;

        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c();
        invoiceBundle.BrokerAgency__c = accountRecord.Id;
        invoiceBundle.Status__c = 'Ready for Submission';
        insert invoiceBundle;
        
         Id brokerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Broker_Agency')
            .getRecordTypeId();
        Account brokerAcc1 = new Account(Name='broker1',recordTypeId=brokerRecordTypeId,UAEVATRegisterNumber__c='889766405212345');
        Insert brokerAcc1;
        
        
                Opportunity opp = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        Id managerId = [SELECT Id,ManagerId FROM User WHERE Id!=:userInfo.getUserId() AND Profile.Name = 'System Administrator' AND isActive = true LIMIT 1].Id;
        opp.BrokerAgencyAccount__c = brokerAcc1.Id;
        opp.OwnerManger__c = managerId;
        insert opp;
         Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, accountRecord.Id);
        salesOrder.Unit__c = unitrecord.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        salesOrder.NetAmount__c = 100;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        CommissionLineItem__c commissionLineItem = new CommissionLineItem__c();
        commissionLineItem.InvoiceBundle__c = invoiceBundle.Id;
        commissionLineItem.BrokerAgency__c = accountRecord.Id;
        commissionLineItem.BrokerAgent__c = con.Id;
        commissionLineItem.CommissionAmount__c = 1000.00;
        commissionLineItem.CommissionType__c = 'External';
        commissionLineItem.CommissionPercentage__c = 10;
        commissionLineItem.SalesOrder__c = salesOrder.Id;
        insert commissionLineItem;
    }

    @IsTest
    static void testExecuteWithValidRequestBody() {
        Account accountRecord = [Select id from Account where name = 'Test Account'];
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getWeeklyCommissionReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object> {
            'startDate' => '2025-01-01',
                'endDate' => '2025-12-31',
                'agencyId'=>accountRecord.id
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_WeeklyCommissionReport.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'));
      //  System.assertEquals('Weekly Commission Report is fetched', response.get('message'));
       // System.assertNotEquals(null, response.get('data'));
    }

    @IsTest
    static void testExecuteWithInvalidRequestBody() {
        Account accountRecord = [Select id from Account where name = 'Test Account'];
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getWeeklyCommissionReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = null;
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_WeeklyCommissionReport.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'));
       
    }

    @IsTest
    static void testProcessRequestFailure() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getWeeklyCommissionReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = Blob.valueOf('Invalid JSON');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_WeeklyCommissionReport.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'));
       
    }

    @IsTest
    static void testExecute_invalidRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getWeeklyCommissionReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_WeeklyCommissionReport.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(false, response.get('success'));
        System.assertEquals('Invalid Request Body', response.get('message'));
    }

    @IsTest
    static void testExecuteWithInvalidDateFormat() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getWeeklyCommissionReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object> {
            'startDate' => 'invalid-date-format',
            'endDate' => '2025-01-07'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_WeeklyCommissionReport.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'));
     
    }

    @IsTest
    static void testExecuteWithEmptyDateRange() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getWeeklyCommissionReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object> {
            'startDate' => '',
            'endDate' => ''
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_WeeklyCommissionReport.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        System.assertEquals(true, response.get('success'));
       
    }
    
    
}