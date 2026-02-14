public class InvoiceBundleWrapper {
    public String success;
    public String applicationName;
    public String statusCode;
    public String correlationId;
    public cls_results[] results;
    public class cls_results{
        public String sfRequestId;
        public String sfBundleId;
        public String status;
        public String errorMsg;
    }
    Public static InvoiceBundleWrapper parseResponse(String json){
        return (InvoiceBundleWrapper)System.JSON.deserialize(json, InvoiceBundleWrapper.class);
    }
}