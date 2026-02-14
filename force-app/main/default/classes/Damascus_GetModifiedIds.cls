@RestResource(urlMapping='/getModifiedIds')
global class Damascus_GetModifiedIds {
    @HttpGet
    global static void getModifiedIds() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, Object> responseData = new Map<String, Object>(); 
            
            RestRequest req = RestContext.request;
            Boolean validParams = true;
            List<String> missingParams = new List<String>();
            if(!req.params.containsKey('startDate')){
                validParams = false;
                missingParams.add('startDate');
            }
            if(!req.params.containsKey('endDate')){
                validParams = false;
                missingParams.add('endDate');
            }
            if(!validParams){
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Missing required parameters in request: '+String.join(missingParams, ', ');
            }else{
                String startDate    =   req.params.get('startDate');
                String endDate      =   req.params.get('endDate');
            
                responseData = Damascus_RestApiHandler.getModifiedIds(startDate, endDate);
                handler.response.success = true;
                handler.response.statusCode = 200;
                handler.response.message = 'Success';
                handler.response.data = responseData;
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