@isTest
private class BP_SentOffersTest {

  
    @isTest
    static void testExecute_validRequest() {
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/sentSalesOffer?someParam=value';  
        req.httpMethod = 'GET';  
        req.addHeader('Content-Type', 'application/json');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        BP_SentOffers.excute();
        Test.stopTest();

       
        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

       
        System.assertEquals(true, response.get('success'), 'The response should indicate success');
        System.assertEquals('Sent Offers Fetched', response.get('message'), 'The success message should match');
    }

}