@istest
public class UserInfoWebServiceTest {
    
    static testmethod void testUserInformation(){
            
		TestObjectsFactory.initializeRestContext(null, '/userinformation');
        UserInfoWebService.doGet();
    }

    static testmethod void testUserInformationWithHeaders(){
            
		TestObjectsFactory.initializeRestContext(null, '/userinformation');
        UserInfoWebService.doGet();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        UserInfoWebService.doGet();
    }
}