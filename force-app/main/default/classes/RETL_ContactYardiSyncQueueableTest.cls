@IsTest
private class RETL_ContactYardiSyncQueueableTest {

    /*
     =========================================================================
        MOCK CALLOUT
     =========================================================================
    */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private Boolean isError;

        public MockHttpResponseGenerator() {
            this.statusCode = 200;
            this.responseBody = '{"Yardi_Contact_Code":"Y12345"}';
            this.isError = false;
        }

        public MockHttpResponseGenerator(Integer status, String body, Boolean error) {
            this.statusCode = status;
            this.responseBody = body;
            this.isError = error;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            res.setStatus(isError ? 'ERROR' : 'OK');
            return res;
        }
    }


    /*
     =========================================================================
        TEST DATA
     =========================================================================
    */
    @TestSetup
    static void setupTestData() {

        // Contact
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Phone = '123456789',
            //MailingCountry = 'USA',
            Description = 'Test Contact'
        );
        insert c;

        // Role record
       /*  RETL_Contact_role__c role = new RETL_Contact_role__c(
            Name = 'Primary',
            RETL_Contact__c = c.Id
        );
        insert role; */
    }


    /*
     =========================================================================
        SUCCESS TEST
     =========================================================================
    */
    @isTest
    static void testSuccessScenario() {
        
		Account acc = new Account(Name = 'Test Account');
		insert acc;
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MockHttpResponseGenerator(200, '{"Yardi_Contact_Code":"Y12345"}', false)
        );

        Test.startTest();
       // System.enqueueJob(new RETL_ContactYardiSyncQueueable(c.Id));
              System.enqueueJob(
                new RETL_ContactYardiSyncQueueable(
                    new List<Id>{ c.Id },
                    acc.Id
                )
		);
        Test.stopTest();     // <-- Queueable actually runs here

        Contact updated = [SELECT RETL_Yardi_Id__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals('Y12345', updated.RETL_Yardi_Id__c, 'Contact should be updated with Yardi code.');
    }



    /*
     =========================================================================
        MISSING METADATA CONFIG
     =========================================================================
    
    @IsTest
    static void testMissingMetadata() {
        

        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        try {
            Test.startTest();
            System.enqueueJob(new RETL_ContactYardiSyncQueueable(c.Id));
            Test.stopTest();
            System.assert(false, 'Expected exception due to missing metadata');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('MuleSoft'), 'Should fail because of missing metadata.');
        }
    }
    */

    /*
     =========================================================================
        NULL RESPONSE TEST
     =========================================================================
    */
    @IsTest
    static void testNullResponse() {
      
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        // Mock returns NULL response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, null, false));

        try {
            Test.startTest();
            //Commented and Added by Lokesh Gupta
            //System.enqueueJob(new RETL_ContactYardiSyncQueueable(c.Id));
            System.enqueueJob(
                new RETL_ContactYardiSyncQueueable(
                    new List<Id>{ c.Id }, null
                )
            );
            Test.stopTest();
            System.assert(false, 'Exception expected due to null response');
        } catch (Exception e) {
           
        }
    }


    /*
     =========================================================================
        CALLOUT FAILURE TEST
     =========================================================================
    */
    @IsTest
    static void testCalloutFailure() {
        
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.setMock(
            HttpCalloutMock.class,
            new MockHttpResponseGenerator(500, '{"Error":"Server error"}', true)
        );

        try {
            Test.startTest();
            
             //Commented and Added by Lokesh Gupta
            //System.enqueueJob(new RETL_ContactYardiSyncQueueable(c.Id));
            System.enqueueJob(
                new RETL_ContactYardiSyncQueueable(
                    new List<Id>{ c.Id },null
                )
            );
            Test.stopTest();
            System.assert(false, 'Should throw CustomException on failed callout.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Contact Sync Failed'), 'Failure expected.');
        }
    }


    /*
     =========================================================================
        NULL CONTACT ID TEST
     =========================================================================
    */
    @IsTest
    static void testNullContactId() {
        try {
            Test.startTest();
            //System.enqueueJob(new RETL_ContactYardiSyncQueueable(null));
            System.enqueueJob(new RETL_ContactYardiSyncQueueable(null, null));
            Test.stopTest();
            System.assert(false, 'Should throw exception for null ID.');
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('cannot be null'),
                'Null Contact Id should throw exception.'
            );
        }
    }
}