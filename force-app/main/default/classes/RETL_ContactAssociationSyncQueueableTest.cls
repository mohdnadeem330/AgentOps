@IsTest
private class RETL_ContactAssociationSyncQueueableTest {

    /*
     =========================================================================
        MOCK CALLOUT
     =========================================================================
    */
    private class MockAssociationCallout implements HttpCalloutMock {
        Integer status;
        String body;
        Boolean isError;
        
        public MockAssociationCallout(Integer status, String body, Boolean isError) {
            this.status = status;
            this.body = body;
            this.isError = isError;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(status);
            res.setStatus(isError ? 'ERROR' : 'OK');
            res.setBody(body);
            return res;
        }
    }


    /*
     =========================================================================
        TEST DATA
     =========================================================================
    */
    @TestSetup
    static void setupData() {

        // Account with Yardi Code
        Account acc = new Account(
            Name = 'Test Account',
            RETL_Yardi_Id__c = 'ACCT001'
        );
        insert acc;

        // Opportunity with Yardi Code
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            RETL_Yardi_Id__c = 'OPP001'
        );
        insert opp;

        // Contact
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@test.com'
        );
        insert c;

        // Contact Role
        RETL_Contact_role__c role = new RETL_Contact_role__c(
            RETL_Contact__c = c.Id,
            RETL_Account_Name__c = acc.Id,
            RETL_Opportunity__c = opp.Id,
            RETL_Primary__c = true,
            RETL_Role_Type__c = '478',
            RETL_Contact_role__c = 'Leasing Manager'
        );
        insert role;

       
    }


    /*
     =========================================================================
        SUCCESS SCENARIO
     =========================================================================
    */
    @IsTest
    static void testSuccessScenario() {
        RETL_Contact_role__c role = [SELECT Id FROM RETL_Contact_role__c LIMIT 1];

        Test.setMock(
            HttpCalloutMock.class,
            new MockAssociationCallout(
                200,
                '{"Y_ContactAssociation_Id":"YASSOC123"}',
                false
            )
        );

        Test.startTest();
        System.enqueueJob(
            new RETL_ContactAssociationSyncQueueable(
                new List<Id>{ role.Id } )
        );
        Test.stopTest();

        RETL_Contact_role__c updated =
            [SELECT RETL_Yardi_Id__c FROM RETL_Contact_role__c WHERE Id = :role.Id];

        System.assertEquals('YASSOC123', updated.RETL_Yardi_Id__c, 
            'Association ID should be updated.');
    }


    /*
     =========================================================================
        FAILURE (500 ERROR)
     =========================================================================
    */
    @IsTest
    static void testCalloutFailure() {

        RETL_Contact_role__c role = [SELECT Id FROM RETL_Contact_role__c LIMIT 1];

        Test.setMock(
            HttpCalloutMock.class,
            new MockAssociationCallout(
                500,
                '{"Error":"Server error"}',
                true
            )
        );

        try {
            Test.startTest();
            System.enqueueJob(
                new RETL_ContactAssociationSyncQueueable(
                    new List<Id>{ role.Id }
                )
            );
            Test.stopTest();
            
            System.assert(false, 'Expected failure due to callout error.');

        } catch (Exception e) {
            System.assert(e.getMessage().contains('Association Sync Failed'), 
                'Exception should be thrown for failed callout.');
        }
    }


    /*
     =========================================================================
        NULL RESPONSE TEST
     =========================================================================
    */
    @IsTest
    static void testNullResponse() {

        RETL_Contact_role__c role = [SELECT Id FROM RETL_Contact_role__c LIMIT 1];

        Test.setMock(
            HttpCalloutMock.class,
            new MockAssociationCallout(
                200,
                null,
                false
            )
        );

        try {
            Test.startTest();
            System.enqueueJob(
                new RETL_ContactAssociationSyncQueueable(
                    new List<Id>{ role.Id }
                )
            );
            Test.stopTest();
            System.assert(false, 'Expected error due to null response.');

        } catch (Exception e) {
            System.assert(true, 'Null response should throw exception.');
        }
    }


    /*
     =========================================================================
        NULL ROLE LIST TEST
     =========================================================================
    */
    @IsTest
    static void testNullRoleList() {
        try {
            Test.startTest();
            System.enqueueJob(
                new RETL_ContactAssociationSyncQueueable(
                    null
                )
            );
            Test.stopTest();

            System.assert(false, 'Null list should throw an exception');

        } catch (Exception e) {
            System.assert(true);
        }
    }

}