@IsTest
private class BP_ShowSurveyTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
    }

    @IsTest
    static void testStart_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getSurveyDetails';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"accountId": "' + acc.Id + '"}'
        );

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ShowSurvey.start();
        Test.stopTest();

        
        System.assert(
            res.responseBody.toString().contains('Survey data has been fetched Successfully'),
            'Expected success message'
        );
    }


    @IsTest
    static void testStart_BlankAccountId() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getSurveyDetails';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(
            '{"accountId": ""}'
        );

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ShowSurvey.start();
        Test.stopTest();

        
        System.assert(
            res.responseBody.toString().contains('Account Id should not be blank')
        );
    }

    @IsTest
    static void testStart_EmptyRequestBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getSurveyDetails';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ShowSurvey.start();
        Test.stopTest();

       
        System.assert(
            res.responseBody.toString().contains('Invalid Request Body')
        );
    }

    @IsTest
    static void testStart_InvalidJson() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/getSurveyDetails';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{invalid json}');

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BP_ShowSurvey.start();
        Test.stopTest();

       
        System.assert(
            res.responseBody.toString().contains('Survey data fetched failed')
        );
    }
}