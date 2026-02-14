@RestResource(urlMapping='/getModifiedPaymentPlan')
global class Damascus_GetModifiedPaymentPlan {
 @HttpGet
    global static void getModifiedPaymentPlans() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> responseData = new Map<String, Object>(); 
            if(req.params.containsKey('paymentPlanIds')){
                String paymentPlanIdsString = req.params.get('paymentPlanIds');
                List<String> paymentPlanIdList = paymentPlanIdsString.split(',');
                String queryLimitStr = System.Label.DamascusGetModifiedRecordsLimit.trim();
                Integer queryLimit = !queryLimitStr.equalsIgnoreCase('OFF') ? Integer.valueOf(queryLimitStr) : null;
                if(queryLimit == null || paymentPlanIdList.size() <= queryLimit){
                    responseData.put('paymentPlans', Damascus_RestApiHandler.getModifiedPaymentPlans(paymentPlanIdList));
                    handler.response.success = true;
                    handler.response.statusCode = 200;
                    handler.response.message = 'Success';
                    handler.response.data = responseData;
                }else{
                    handler.response.success = false;handler.response.statusCode = 500;handler.response.message = 'Invalid request parameter. paymentPlanIds: Cannot have more than '+queryLimit+' Ids.';    
                }
            }else{
                handler.response.success = false; handler.response.statusCode = 500;handler.response.message = 'Missing required parameters in request: paymentPlanIds';
            }
        }catch(Exception e){
            System.debug(e.getStackTraceString());
            handler.response.success = false; handler.response.statusCode = 500;handler.response.message = e.getMessage();
        }
        handler.finalize();
    }
}