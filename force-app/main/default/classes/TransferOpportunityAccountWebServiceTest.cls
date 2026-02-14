@isTest
public class TransferOpportunityAccountWebServiceTest {
    
    @isTest
    static void testTransferOpportunitySuccess() {
        
        Account acc1 = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc1.MobileNumber__c = '123456789';
        insert acc1;  
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc2.MobileNumber__c = '321456789';
        insert acc2;  
        
        // Create a mock HTTP request
        String body = '{"newId": "' + acc1.Id + '", "existingId": "' + acc2.Id + '"}';
        
        // Set up the request context
        RestRequest req = new RestRequest();
        req.requestURI = '/query/useExistingAccount/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(body);
        RestContext.request = req;
        
        // Set up the response context
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Run the method under test
        Test.startTest();
        TransferOpportunityAccountWebService.transferOpportunity();
        body = '{"newId": , "existingId": "' + acc2.Id + '"}';
        req.requestBody = Blob.valueof(body);
        TransferOpportunityAccountWebService.transferOpportunity();
        Test.stopTest();
        
        }
}