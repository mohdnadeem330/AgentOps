/**********************************************************************************************************************
* Name               : RecaptchaControllerMockFailureTest                                                       
* Description        : Failure mock class for  RecaptchaController.
* Usage              :                                                           
* Created By         : Muzammil                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Muzammil     		14 Mar 2022      Initial Draft       
******************************************************************************************************************/
global class RecaptchaControllerMockFailureTest  implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        res.setStatusCode(400);
        return res;
    }
}