@RestResource(urlMapping='/getNewsAndAnnouncements')
global with sharing class BP_NewsAndAnnouncements extends BP_BaseRestResource {
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            String requestBody = RestContext.request.requestBody.toString();

            if (!String.isEmpty(requestBody)) {
                BP_NewsAndAnnouncements service = new BP_NewsAndAnnouncements();
                Map<String, String> params = RestContext.request.params;
                ApiResponse apiResponse = service.processRequest(params, requestBody);

                handler.response.success = apiResponse.success;
                handler.response.statusCode = apiResponse.statusCode;
                handler.response.message = apiResponse.message;
                handler.response.data = apiResponse.data;
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
            }
        } catch (Exception ex) {
            ApiResponse errorResponse = handleException(ex, 500);
            handler.response.success = errorResponse.success;
            handler.response.statusCode = errorResponse.statusCode;
            handler.response.message = errorResponse.message;
            handler.response.data = errorResponse.data;
        }

        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);

            Integer page = (Integer) requestBodyData.get('page');
            Integer pageSize = (Integer) requestBodyData.get('pageSize');
            String language = (String) requestBodyData.get('language');
            String filterby = (String) requestBodyData.get('filterby');
            String year = (String) requestBodyData.get('year'); 
            String month = (String) requestBodyData.get('month'); 
            String searchKey = (String) requestBodyData.get('searchKey');

            Map<String, Object> contentData = getContentByType(page, pageSize, language, filterby, year, month, searchKey);

            return new ApiResponse(true, 200, 'News and announcements are fetched successfully', contentData);
        } catch (Exception e) {
            return handleException(e, 400);
        }
    }
    global static Map<String, Object> getContentByType(Integer page, Integer pageSize, String language, String filterby, String year, String month, String searchKey) {  
    List<ConnectApi.ManagedContentVersion> filteredContent = new List<ConnectApi.ManagedContentVersion>();
    Integer totalFilteredCount = 0; 
    List<ConnectApi.ManagedContentVersion> allFilteredContent = new List<ConnectApi.ManagedContentVersion>();

    try {
        Network network = [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        String networkId = network.Id;

        
        Integer tempPage = 0;
        ConnectApi.ManagedContentVersionCollection contentCollection;
        do {
            contentCollection = ConnectApi.ManagedContent.getAllManagedContent(networkId, tempPage, pageSize, language, filterby);
            for (ConnectApi.ManagedContentVersion content : contentCollection.items) {
                Boolean matchesSearchKey = String.isEmpty(searchKey) || content.title.containsIgnoreCase(searchKey);
                Boolean matchesYear = String.isEmpty(year) || (content.publishedDate != null && String.valueOf(content.publishedDate.year()) == year);
                Boolean matchesMonth = String.isEmpty(month) || (content.publishedDate != null && String.valueOf(content.publishedDate.month()) == month);

                if (matchesSearchKey && matchesYear && matchesMonth) {
                    allFilteredContent.add(content);
                }
            }
            tempPage++;
        } while (contentCollection.items.size() == pageSize); 

        totalFilteredCount = allFilteredContent.size();

       
        Integer startIdx = page * pageSize;
        Integer endIdx = Math.min(startIdx + pageSize, totalFilteredCount);

        for (Integer i = startIdx; i < endIdx; i++) {
            filteredContent.add(allFilteredContent[i]);
        }

    } catch (ConnectApi.ConnectApiException e) {
        System.debug('Error Message : ' + e);
    }

    return new Map<String, Object>{
        'totalRecordCount' => totalFilteredCount, 
        'contentList' => filteredContent 
    };
}


}