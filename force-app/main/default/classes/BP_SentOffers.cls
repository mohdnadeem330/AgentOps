@RestResource (urlMapping = '/sentSalesOffer')
global with sharing  class BP_SentOffers extends BP_BaseRestResource{

    @HttpGet
    global static void excute(){ 
         RestContextHandler handler = new RestContextHandler(false);
       
            Map<String, String> params = RestContext.request.params;
            BP_SentOffers service = new BP_SentOffers();
            ApiResponse response = service.processRequest(params, null);
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
            
        
        handler.finalize();
    }
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            return new ApiResponse(true, 200,'Sent Offers Fetched',  SentOffersListingController.getActivityHistory());
        } catch (Exception e) {
            return new ApiResponse(false, 500,'Failed to load SentOffer List: ' + e.getMessage(), null);
        } 
    }
}