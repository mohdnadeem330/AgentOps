/**********************************************************************************************************************
* Name               : RecaptchaControllerMockTest                                                       
* Description        : Success mock class for  RecaptchaController.
* Usage              :                                                           
* Created By         : Muzammil                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Muzammil     		14 Mar 2022      Initial Draft       
******************************************************************************************************************/
@isTest
global class RecaptchaControllerMockTest implements HttpCalloutMock{

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"success":true,"score":2,"action":"1"}');
        res.setStatusCode(200);
        return res;
    }
}