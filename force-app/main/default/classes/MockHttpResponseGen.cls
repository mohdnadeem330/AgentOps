/**
Class       : MockHttpResponseGen
Author      : Smaartt
Description : This is common mock generator with response
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              25/07/24           Initial Version 
****************************************************************************************************************/
@isTest
global class MockHttpResponseGen implements HttpCalloutMock{
	global HTTPResponse respond(HTTPRequest req) {
       
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        String endpoint = req.getEndpoint();
        if(endpoint.contains('/api/v1/blob/filesasurl')){                
               res.setBody('{"data": {"fileSasUrl": "https://lfudevasset.aldar.com/blob-container/aldar/liveAldar/a1dKH000000Co3AYAS/1721388730882.png"},"status": "success"}');
           }
        res.setStatusCode(200);
        return res;
    }
}