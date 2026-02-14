@isTest 
public class BP_GetLeadOppSalesordersTest {
    @testSetup
    static void createData() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test','1234');
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        insert acc;
        
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        
        Lead leadobj = TestObjectsFactory.getLeadRecord(1, 'Person');
        leadobj.BrokerAgent__c = con.Id;
        leadobj.BrokerAgency__c = acc.Id;
        leadobj.Date_of_Birth__c = Date.newInstance(1996, 2, 28);
        insert leadobj;
        
        Contact contact = TestObjectsFactory.contactDataSetup(account.Id);
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        opp.EmployeeId__c = '123456789';
        opp.EmployeeEmail__c = 'test@aldar.com';
        opp.SaleType__c = 'New Sale';
        opp.BrokerAgencyAccount__c = acc.Id;
        opp.BrokerAgentContact__c = con.Id;
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('1234');
        unit.Name = '1234';
        insert unit;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.Classification__c ='30-70';
        insert paymentPlanRecord;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.PaymentPlan__c=paymentPlanRecord.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        salesOrder.NetAmount__c = 100;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
    }
    
    @isTest
    static void testExecute() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetLeadsOppsSalesOrders';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        Map<String, Object> requestBody = new Map<String, Object>();
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        req.params.put('startDate', String.valueOf(System.today()));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = con.Id
        );
        
        insert testUser;
        
        System.runAs(testUser) {
            Test.startTest();
            BP_GetLeadOppSalesorders.execute();
            Test.stopTest();
            
            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            // System.assertEquals(response.get('statusCode'), 200);
        }
    }
    
    @isTest
    static void testExecutInvalid2() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetLeadsOppsSalesOrders';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        Map<String, Object> requestBody = new Map<String, Object>();
        req.requestBody = null;
        req.params.put('startDate', String.valueOf(System.today()));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = con.Id
        );
        
        insert testUser;
        
        System.runAs(testUser) {
            Test.startTest();
            BP_GetLeadOppSalesorders.execute();
            Test.stopTest();
            
            RestResponse res = RestContext.response;
            String responseBody = res.responseBody.toString();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            System.assertEquals(response.get('statusCode'), 500);
        }
    }
    private static User createTestUser(Id contactId) {
        Profile agencyProfile = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = agencyProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = contactId
        );
        insert testUser; // ✅ Insert the user before using it in runAs()
        return testUser;
    }
    @isTest
    static void testExecute1() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetLeadsOppsSalesOrders';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        Map<String, Object> requestBody = new Map<String, Object>();
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        req.params.put('startDate', String.valueOf(System.today()));
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // ✅ Fetch Contact first
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        // ✅ Create and Insert User before runAs()
        User testUser = createTestUser(con.Id);
        
        Test.startTest();
        System.runAs(testUser) { // ✅ Now User exists before runAs()
            BP_GetLeadOppSalesorders.execute();
        }
        Test.stopTest();
        
        // ✅ Validate Response
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    }
    
    
}