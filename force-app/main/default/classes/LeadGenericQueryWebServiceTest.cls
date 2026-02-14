/*
*Created By     : Rohit
*Created Date   : 10/07/2023
*Description    : Test class for LeadQueryWebService which provides lead details to the app
*/
@istest
public class LeadGenericQueryWebServiceTest {

    static Lead leadRec ;

    static void init(){
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.LeadSource = 'Walk-In' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
    }
    
    static testmethod void testAllLeads(){
         // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        init();
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        LeadGenericQueryWebService.doPost();
        
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        LeadGenericQueryWebService.doPost();
        
         Test.stopTest();
    }

    static testmethod void testLeadbyId(){
         // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        init();
         Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        
        Map<String, String> searchMap = new Map<String, String>();
        searchMap.put('Id', leadRec.Id);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));

        LeadGenericQueryWebService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        LeadGenericQueryWebService.doPost();

        Test.stopTest();
    }


}