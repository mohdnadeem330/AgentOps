/********************************************************************************
* Description       : Test class for ALD_DLPCatalogueWebService & ALD_DLPCatalogueHelper REST API Classes
* Created By        : nborse@aldar.com 
*********************************************************************************/
@IsTest
private class ALD_DLPCatalogueWebServiceTest {
    @IsTest
    static void testDoPost() {
        // Set up the mock HTTP request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/LiveAldar/DLPCatalogue';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        ALD_DLPCatalogueWebService.doPost();
        Test.stopTest();
        
        // Validate the response
        ALD_DLPCatalogueWebService.ConfigurationsModel response = (ALD_DLPCatalogueWebService.ConfigurationsModel) JSON.deserialize(RestContext.response.responseBody.toString(), ALD_DLPCatalogueWebService.ConfigurationsModel.class);
    }
    
    @IsTest
    static void testGetConfigurations() {
        // Call the method
        ALD_DLPCatalogueWebService.ConfigurationsModel configurations = ALD_DLPCatalogueWebService.getConfigurations();
    }
    
    @IsTest
    static void testGetUniqueVals() {
        // Create a sample map of dependent picklist values
        Map<String, List<String>> mapPicklstDepVals = new Map<String, List<String>>();
        mapPicklstDepVals.put('Category1', new List<String>{'SubCat1', 'SubCat2'});
        mapPicklstDepVals.put('Category2', new List<String>{'SubCat3', 'SubCat4'});
        
        // Call the method
        Set<String> uniqueVals = ALD_DLPCatalogueWebService.getUniqueVals(mapPicklstDepVals);
        
        
    }
    
    @IsTest
    static void testFilterPickVal() {
        // Create sample maps
        Map<String, List<String>> mapContrlDepFldMap = new Map<String, List<String>>();
        mapContrlDepFldMap.put('Cat1', new List<String>{'SubCat1', 'SubCat2'});
        mapContrlDepFldMap.put('Cat2', new List<String>{'SubCat3', 'SubCat4'});
        Set<String> setVals = new Set<String>{'Cat1'};
        // Call the method
        Map<String, List<String>> filteredMap = ALD_DLPCatalogueWebService.filterPickVal(mapContrlDepFldMap, setVals);
    }
}