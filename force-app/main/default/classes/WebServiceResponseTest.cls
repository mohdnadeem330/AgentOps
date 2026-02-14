@isTest
private class WebServiceResponseTest {

    static testMethod void initTest() {
        
        WebServiceResponse webserResponse = new WebServiceResponse();
        webserResponse.message = 'I am a web-service';
        webserResponse.statusCode = 200;
        Object obj = webserResponse.data;
        webserResponse.requestId = null;

        String serialized = webserResponse.serialize();
        WebServiceResponse deserialized = (WebServiceResponse) JSON.deserialize(serialized, WebServiceResponse.class);

        System.assertEquals(deserialized.statusCode, webserResponse.statusCode, 'The status codes are different.');
    }
}