public class SendGridMockHTTPResponseGenerator implements HttpCalloutMock {
    protected String bodyAsString;
	protected Integer code;
	/**
	 * VG_MockHttpResponseGenerator initialize response code and body for testing callouts
	 * @param                        code
	 * @param                        body
	 * @return                       return null
	 */
	public SendGridMockHTTPResponseGenerator(Integer code, String bodyAsString){
		this.code = code;
		this.bodyAsString = bodyAsString;
	}
	/**
	 * respond     get HTTP response based on request
	 * @param      request
	 * @return     return mock response
	 */
	public HTTPResponse respond(HTTPRequest req) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(bodyAsString);
		response.setStatusCode(code);
		return response;
	}
}