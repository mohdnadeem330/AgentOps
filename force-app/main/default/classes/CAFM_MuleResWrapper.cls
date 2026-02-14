public class CAFM_MuleResWrapper {
    public String applicationName;	//x-ald-sferp-api
    public boolean success;
    public String statusCode;	//200
    public String correlationId;	//c9c1be70-70d4-11ef-8d9c-0249d7a827d7
    public cls_results results;
    
    public static CAFM_MuleResWrapper parse(String json) {
        return (CAFM_MuleResWrapper) System.JSON.deserialize(json, CAFM_MuleResWrapper.class);
    }
    
    public class cls_results{
        public cls_CreateBreakdownTaskResponse CreateBreakdownTaskResponse;
    }
    public class cls_CreateBreakdownTaskResponse{
        public cls_CreateBreakdownTaskResult CreateBreakdownTaskResult;
    }
    public class cls_CreateBreakdownTaskResult{
        public String PrimaryKeyId;	//7931640
        public String TaskId;
        public String Code;
        public String TaskPerfSLAAttendDate;
        public String TaskPerfSLAFixDate;     
        
    } 
}