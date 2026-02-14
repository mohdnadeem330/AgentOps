@RestResource(urlMapping='/getModifiedUnits')
global class Damascus_GetModifiedUnits {
    @HttpGet
    global static void getModifiedUnits() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> responseData = new Map<String, Object>(); 
            if(req.params.containsKey('unitIds')){
                String unitIdsString = req.params.get('unitIds');
                List<String> unitIdList = unitIdsString.split(',');
                String queryLimitStr = System.Label.DamascusGetModifiedRecordsLimit.trim();
                Integer queryLimit = !queryLimitStr.equalsIgnoreCase('OFF') ? Integer.valueOf(queryLimitStr) : null;
                if(queryLimit == null || unitIdList.size() <= queryLimit){
                    responseData.put('units', Damascus_RestApiHandler.getModifiedUnits(unitIdList));
                    handler.response.success = true;
                    handler.response.statusCode = 200;
                    handler.response.message = 'Success';
                    handler.response.data = responseData;
                }else{
                    handler.response.success = false;
                    handler.response.statusCode = 500;
                    handler.response.message = 'Invalid request parameter. unitIds: Cannot have more than '+queryLimit+' Ids.';    
                }
            }else{
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Missing required parameters in request: unitIds';
            }
        }catch(Exception e){
            System.debug(e.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = e.getMessage();
        }
        handler.finalize();
    }
}