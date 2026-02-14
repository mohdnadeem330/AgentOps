global abstract class BP_BaseRestResource {
    
    global class ApiResponse {
        public Boolean success;
        public Integer statusCode;
        public String message;
        public Object data;
        
        
        public ApiResponse(Boolean success,Integer statusCode, String message, Object data) {
            this.success = success;
            this.statusCode = statusCode;
            this.message = message;
            this.data = data;
        }
    }
    global abstract ApiResponse processRequest(Map<String, String> params, String requestBody);
    
    public static ApiResponse handleException(Exception e, Integer statusCode) {
        return new ApiResponse(false, statusCode ,'Error: ' + e.getMessage(), null);
    }
    
    public static Map<String, Object> parseRequestBody(String body) {
        if (String.isBlank(body)) {
            return new Map<String, Object>();
        }
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }
}