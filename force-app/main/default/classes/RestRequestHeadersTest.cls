@isTest
private class RestRequestHeadersTest {
	
	@isTest static void initWithRequest() {
		
		RestRequest r = TestObjectsFactory.initializeRestRequest('a', '/path', '1', 'ios', 'iphone', 'x');
		RestRequestHeaders headersModel = new RestRequestHeaders(r);
	}
	
	@isTest static void initWithMap() {
		
		RestRequest r = TestObjectsFactory.initializeRestRequest('a', '/path', '1', 'ios', 'iphone', 'x');
		Map<String, String> requestHeaders = r.headers;
		RestRequestHeaders headersModel = new RestRequestHeaders(requestHeaders);
	}

	@isTest static void init() {
		
		RestRequestHeaders headersModel = new RestRequestHeaders();
	}

	@isTest static void validateHeadersTest() {
		
		RestRequest r = TestObjectsFactory.initializeRestRequest('a', '/path', '1', 'ios', 'iphone', 'x');
		Map<String, String> requestHeaders = r.headers;
		RestRequestHeaders headersModel = new RestRequestHeaders(requestHeaders);
		headersModel.validateHeaders();
	}

	@isTest static void validateHeadersExceptionTest() {
		
		try {
			RestRequestHeaders headersModel = new RestRequestHeaders();
			headersModel.appVersion = 'a';
			headersModel.validateHeaders();	
		}
		catch(Exception e) {
			
		}
	}
	
}