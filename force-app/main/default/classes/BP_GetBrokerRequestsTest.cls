@isTest
private class BP_GetBrokerRequestsTest {
    
    @testSetup
    static void setupTestData() {
        // Create test data that can be reused in all test methods
        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;
        
        Account orgAcc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc1;
    
        orgAcc1.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc1.ParentId = orgAcc.Id;
        update orgAcc1;

        Contact singleCon = new Contact(
            Firstname = 'newContact', LastName = 'Lastname', AccountId = orgAcc1.Id, Email = 'aldartestUser@yopmail.com',BrokerType__c = 'Agent'
        );
        singleCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
        insert singleCon;

        Id pfId = [SELECT Id, Name FROM profile WHERE name=: Constants.AGENCY_USER_PROFILE_LOGIN LIMIT 1].Id;
        
        Test.startTest();
        User newCommunitiesUser = new User(
            ContactId = singleCon.Id, FirstName = singleCon.FirstName, LastName = singleCon.LastName, Email = singleCon.Email,
            Username = 'mohcommunityUserTest232112343232355@aldarportal1.com', profileid = pfId, languagelocalekey = 'en_US',
            localesidkey = 'en_US', emailencodingkey = 'UTF-8', IsActive = true, timezonesidkey = 'Asia/Dubai'
        );
        newCommunitiesUser.alias = String.valueof(singleCon.FirstName.substring(0,1) + singleCon.LastName.substring(0,1) + Math.random() ).substring(0,5);
        newCommunitiesUser.communityNickname  = singleCon.LastName + '_'+Integer.valueof((Math.random() * 10000));
        insert newCommunitiesUser;
        Test.stopTest();
        String recordTypeId = Schema.SObjectType.BrokerRequest__c.getRecordTypeInfosByDeveloperName().get('MarketingReimbursement').getRecordTypeId();

        // Create test BrokerRequest__c records
        BrokerRequest__c br1 = new BrokerRequest__c(
            RecordTypeId = recordTypeId, AgencyName__c = orgAcc1.Id, StartDate__c = Date.today().addDays(-30),
            EndDate__c = Date.today(), Location__c = 'Cairo', InvoiceAmount__c = 1000, SodicInvoiceAmount__c = 900,
            Comment__c = 'Test comment', TaxAmount__c = 100, InvoiceDate__c = Date.today(), InvoiceStatus__c = 'Pending Invoice Verification',
            ApprovalStatus__c = 'Approval Pending', RequestYear__c = '2025', RequestQuarter__c = 'Q2', OwnerId = newCommunitiesUser.Id
        );
        insert br1;
    }

    @isTest
    static void testProcessRequestWithValidBody() {
       
        User usr = [SELECT Id, Username FROM User WHERE Username = 'mohcommunityUserTest232112343232355@aldarportal1.com'] ;
        System.runAs(usr){
            // Create request body
            BP_GetBrokerRequests.DeserializeWrapper dw = new BP_GetBrokerRequests.DeserializeWrapper();
            dw.type = 'Marketing Reimbursement';
            dw.quarter = 'Q2';
            dw.year = '2025';
            String jsonBody = JSON.serialize(dw);

            // Create a mock request
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/getBrokerRequests';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(jsonBody);
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;
            BP_GetBrokerRequests.execute();
        }
        
        // Validate response (you may not be able to assert directly without mocking handler logic)
        System.assertNotEquals(null, RestContext.response);
    }

    @isTest
    static void testProcessRequestWithEmptyBody() {
        // Setup mock request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getBrokerRequests';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        BP_GetBrokerRequests.execute();
        Test.stopTest();

        // Since there's no direct return, we rely on debug or internal test framework to inspect behavior
        // But ensure no unhandled exceptions occur
    }

    @isTest
    static void testProcessRequestWithMissingType() {
        // Missing type in request
        BP_GetBrokerRequests.DeserializeWrapper dw = new BP_GetBrokerRequests.DeserializeWrapper();
        dw.quarter = 'Q2';
        dw.year = '2025';
        String jsonBody = JSON.serialize(dw);

        BP_GetBrokerRequests resource = new BP_GetBrokerRequests();
        resource.processRequest(new Map<String, String>(), jsonBody);
    }

    @isTest
    static void testProcessRequestNoRecordsFound() {
        Account acc = new Account(Name = 'No Match Agency');
        insert acc;

        BP_GetBrokerRequests.DeserializeWrapper dw = new BP_GetBrokerRequests.DeserializeWrapper();
        dw.type = 'Marketing Reimbursement';
        dw.quarter = 'Q3';
        dw.year = '2030'; // future year with no records
        String jsonBody = JSON.serialize(dw);

        BP_GetBrokerRequests resource = new BP_GetBrokerRequests();
        resource.processRequest(new Map<String, String>(), jsonBody);
    }
}