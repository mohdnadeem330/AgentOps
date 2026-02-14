@isTest
public class SendGridMultiRequestMockTest {
    static testmethod void coverMultiMock(){
		Map<String, HttpCalloutMock> httpMapMock = new Map<String, HttpCalloutMock>();
		String mock = '';
		HttpCalloutMock httpMock = null;
		SendGridMultiRequestMock multi = new SendGridMultiRequestMock(httpMapMock);
		multi.addRequestMock(mock,httpMock);
	}
}