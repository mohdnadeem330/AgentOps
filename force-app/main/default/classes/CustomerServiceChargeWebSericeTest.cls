@isTest
public class CustomerServiceChargeWebSericeTest {
   
    @testSetUp
    public static void testdata(){
        //ChargeRule__c CR = TestObjectsFactory.getChargeRuleRecord('Cheque Replacement',Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);
        ChargeRule__c cr = new ChargeRule__c();
        cr.ChargeAmount__c = 2000;
        cr.SRType__c = 'Property Transfer';
        cr.EndDate__c = Date.Today().addDays(100);
        cr.IsActive__c = TRUE;
        cr.ChargeType__c = 'Transfer Normal';
        cr.StartDate__c = Date.Today().addDays(-100);
        //CR.SRType__c = 'Cheque Replacement';
		//CR.ChargeType__c = 'Service charge';
		//CR.ChargePercentage__c = 10;
        //CR.ChargeAmount__c = 13000;
        CR.VATChanges__c = 20;
        system.debug(CR);
        Insert CR;
    }
    @isTest
    public static void getCalculatedServiceChargeTest(){
        Test.startTest();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getServiceCharge';
        //req.params.put('unitName',unitName.Id);
        //req.params.put('customerId',Acc.Id);
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('Key', 'Value');
        bodyMap.put('SRType', 'Property Transfer'); 
         bodyMap.put('ChargeType', 'Transfer Normal'); 
        String jsonBody = JSON.serialize(bodyMap);
        
        TestObjectsFactory.initializeRestContext(jsonBody, '/some/path', '1.0', 'ios', '12.1', 'iphone x');
        
        RestContextHandler handler = new RestContextHandler(false);

        handler.getRequestBodyMap();
        handler.setResponseBody(Blob.valueOf(jsonBody));
        handler.addResponseHeader('X-Custom-Header', 'Value');
        handler.setResponseStatusCode(200);
        handler.finalize();

        try {
            Integer i = 1/0;
        }
        catch(Exception exc) {
            handler.finalize(exc);
        }
        CustomerServiceChargeWebSerice.getCalculatedServiceCharge();
        
        Test.stopTest(); 
    }
}