@istest
public class ALD_CreateHomeFinanceCaseWebServiceTest 
{
    public static String jsonString = '';
    @testSetup 
    static void setupMethod()
    {
        jsonString	=	'{'+
		'  "firstName": "tharun",'+
		'  "lastName": "kumar HF",'+
		'  "mobileCountryCode": "971",'+
		'  "mobileNumber": "0988665",'+
		'  "email": "tharun@gmail.com",'+
		'  "nationality": "India",'+
		'  "residency": "India",'+
		'  "city": "Hyd",'+
		'  "employmentStatus": "Salaried/Employed",'+
		'  "propertyType": "Off-Plan by Aldar",'+
		'  "approxPropertyValue": "20000",'+
		'  "approxLoanAmountRequired": "5000",'+
		'  "anyOtherInfo": "A sample HF case"'+
		'}';
	
        /*
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/create/homefinance/case'; 
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json'); 
        req.requestBody = Blob.valueOf(jsonString);
        RestContext.request = req;
        RestContext.response = res; 
        
        
        Test.startTest();
            ALD_CreateHomeFinanceCaseWebService.doPost();
        Test.stopTest();  
        */
    }
    
    @isTest
    static void testCreateCase1()
    {
        Test.startTest();
        setupMethod();
        TestObjectsFactory.initializeRestContext(null, '/create/homefinance/case');
        RestContextHandler handler = new RestContextHandler(false);
        RestContext.request.requestBody = Blob.valueOf(jsonString);
        ALD_CreateHomeFinanceCaseWebService.doPost();
        Test.stopTest();
        
    }
    
     @isTest
    static void testCreateCaseException()
    {
        Test.startTest();
        setupMethod();
        TestObjectsFactory.initializeRestContext(null, '/create/homefinance/case');
        RestContextHandler handler = new RestContextHandler(false);
        RestContext.request.requestBody = Blob.valueOf('');
        ALD_CreateHomeFinanceCaseWebService.doPost();
        Test.stopTest();
        
    }

}