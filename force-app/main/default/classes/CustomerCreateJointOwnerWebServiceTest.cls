@isTest
public  class CustomerCreateJointOwnerWebServiceTest {
    
    @testSetUp
    public static void testData(){
        
        Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        Account acc = new Account();
        acc.FirstName='Test';
        acc.LastName= 'Agni';
        acc.PersonEmail='agni@gmail.com';
        acc.RecordTypeId = personAccountRecordTypeId;
        insert acc;
        
        Account nonExistingAcc = new Account();
        nonExistingAcc.FirstName='Test';
        nonExistingAcc.LastName= 'Drogo';
        nonExistingAcc.PersonEmail='drogo@gmail.com';
        nonExistingAcc.RecordTypeId = personAccountRecordTypeId;
        insert nonExistingAcc;
        
    }
    @isTest
    static void validScenario(){
        list<Account> accountList =[SELECT Id FROM Account WHERE personemail=:'agni@gmail.com'];
        
        String inputPayload = '{' + 
            '"customerId": "' + accountList[0].Id + '",' +  // Accessing the Id property of the Account
            '"JointOwnerList": [' +
            '{' + 
            '"firstname": "' + 'Chiarg' + '",' +
            '"lastname": "' + 'Raiyani' + '",' +
            '"email": "' + 'drogo@gmail.com' + '",' +
            '"phone": "' + '971507453099' + '",' +
            '"relationship": "' + 'Child' + '"' +
            '},' +
            '{' + 
            '"firstname": "' + 'Chiarg' + '",' +
            '"lastname": "' + 'Raiyani' + '",' +
            '"email": "' + 'drogo@gmail.com' + '",' +
            '"phone": "' + '971507453099' + '",' +
            '"relationship": "' + 'Child' + '"' +
            '}' +
            ']' +
            '}';
        
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/createJointOwner';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        CustomerCreateJointOwnerWebService.createAccount();
        Test.stopTest();
        
        
    }
    
    @isTest
    static void catchException(){
         list<Account> accountListinvalid =[SELECT Id FROM Account WHERE personemail=:'agni@gmail.com'];
		String inputPayload = 'customerId+ accountListinvalid[0].Id';     
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/createJointOwner';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        CustomerCreateJointOwnerWebService.createAccount();
        Test.stopTest();
        
    }
    
}