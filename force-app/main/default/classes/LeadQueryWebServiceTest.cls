/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for LeadQueryWebService which provides lead details to the app
*/
@istest
public class LeadQueryWebServiceTest {

    static Lead leadRec ;

    static void init(){
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
    }
    
    static testmethod void testAllLeads(){

        init();

		TestObjectsFactory.initializeRestContext(null, '/query/lead');
        LeadQueryWebService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        LeadQueryWebService.doPost();
    }

    static testmethod void testLeadbyId(){

        init();
        TestObjectsFactory.initializeRestContext(null, '/query/lead');
        
        Map<String, String> searchMap = new Map<String, String>();
		searchMap.put('Id', leadRec.Id);
		RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));

        LeadQueryWebService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        LeadQueryWebService.doPost();
    }


}