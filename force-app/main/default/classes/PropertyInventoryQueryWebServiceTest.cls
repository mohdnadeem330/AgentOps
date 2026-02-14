@istest
public class PropertyInventoryQueryWebServiceTest {

    static testmethod void testcase1(){
            
        Unit__c unit = TestObjectsFactory.unitDataSetup('10101');
        insert unit;
        
		TestObjectsFactory.initializeRestContext(null, '/query/propertyinventory');

        PropertyInventoryQueryWebService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        PropertyInventoryQueryWebService.doPost();
    }
}