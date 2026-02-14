@RestResource(urlMapping='/getModifiedProjects')
global class Damascus_GetModifiedProjects {
    @HttpGet
    global static void getModifiedProjects() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> responseData = new Map<String, Object>(); 
            if(req.params.containsKey('projectIds')){
                String projectIdsString = req.params.get('projectIds');
                List<String> projectIdList = projectIdsString.split(',');
                String queryLimitStr = System.Label.DamascusGetModifiedRecordsLimit.trim();
                Integer queryLimit = !queryLimitStr.equalsIgnoreCase('OFF') ? Integer.valueOf(queryLimitStr) : null;
                if(queryLimit == null || projectIdList.size() <= queryLimit){
                    responseData.put('projects', Damascus_RestApiHandler.getModifiedProjects(projectIdList));
                    handler.response.success = true;
                    handler.response.statusCode = 200;
                    handler.response.message = 'Success';
                    handler.response.data = responseData;
                }else{
                    handler.response.success = false;
                    handler.response.statusCode = 500;
                    handler.response.message = 'Invalid request parameter. projectIds: Cannot have more than '+queryLimit+' Ids.';    
                }
            }else{
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Missing required parameters in request: projectIds';
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