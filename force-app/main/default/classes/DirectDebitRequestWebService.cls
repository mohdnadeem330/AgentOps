@RestResource(urlMapping='/LiveAldar/DirectDebitRequest')
global with sharing class DirectDebitRequestWebService {
    
    // Standard response wrapper
    global class StandardResponse {
        public Boolean success;
        public Integer statusCode;
        public String requestId;
        public String message;
        public Object data;
        
        public StandardResponse(Boolean success, Integer statusCode, String message, Object data) {
            this.success = success;
            this.statusCode = statusCode;
            this.message = message;
            this.data = data;
        }
    }
    
    global class DirectDebitRequestDTO {
        public String CustomerIdType;
        public String CustomerBankAccountType;
        public String CustomerBankName;
        public String CustomerIDNumber;
        public String CustomerAccountName;
        public String CustomerIBANNumber;
        public Id customerId;
        public Id SalesOrderId;
    }
    
    @HttpGet
    global static void getPicklistValues() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        try {
            Map<String, List<String>> picklistMap = new Map<String, List<String>>();
            Schema.DescribeSObjectResult objDescribe = DirectDebitRequest__c.SObjectType.getDescribe();
            Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();
            
            Map<String, String> fieldKeyMap = new Map<String, String>{
                'CustomerIdType__c' => 'customerType',
                    'CustomerBankAccountType__c' => 'customerBankAccountType',
                    'CustomerBankName__c' => 'customerBankName'
                    };
                        
                        for (String fieldName : fieldKeyMap.keySet()) {
                            List<String> values = new List<String>();
                            for (Schema.PicklistEntry val : fields.get(fieldName).getDescribe().getPicklistValues()) {
                                values.add(val.getLabel());
                            }
                            picklistMap.put(fieldKeyMap.get(fieldName), values);
                        }
            sendResponse(true, 200, 'Picklist values fetched successfully', picklistMap);
            
        } catch (Exception e) {
            sendResponse(false, 500, 'Error at line ' + e.getLineNumber() + ': ' + e.getMessage(), null);
        }
    }
    
    @HttpPost
    global static void createDirectDebitRequest() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String requestId = null;
        try {
            RestRequest req = RestContext.request;
            String reqBody = req.requestBody.toString();
            DirectDebitRequestDTO input = 
                (DirectDebitRequestDTO) JSON.deserialize(reqBody, DirectDebitRequestDTO.class);
            
            requestId = input.SalesOrderId != null ? String.valueOf(input.SalesOrderId) : null;
            
            DirectDebitRequest__c newRequest = new DirectDebitRequest__c(
                CustomerIdType__c          		= input.CustomerIdType,
                CustomerBankAccountType__c 		= input.CustomerBankAccountType,
                CustomerBankName__c        		= input.CustomerBankName,
                CustomerIDNumber__c        		= input.CustomerIDNumber,
                CustomerAccountName__c     		= input.CustomerAccountName,
                CustomerIBANNumber__c      		= input.CustomerIBANNumber,
                SalesOrder__c              		= input.SalesOrderId,
                PayerAccount__c                 = input.customerId,
                Skip_off_plan_ddr_validation__c = true
                //Status__c                  = 'DDS Generated'
            );
            insert newRequest;
            
            Map<String, Object> responseData = new Map<String, Object>{
                'recordId' => newRequest.Id
                    };
                        sendResponse(true, 200, 'Record created successfully', responseData);
        } catch (Exception e) {
            sendResponse(false, 500, 'Error at line ' + e.getLineNumber() + ': ' + e.getMessage(), null);
        }
    }
    
    private static void sendResponse(Boolean success, Integer code, String msg, Object data) {
        RestResponse res = RestContext.response;
        res.statusCode = code;
        StandardResponse sr = new StandardResponse(success, code, msg, data);
        res.responseBody = Blob.valueOf(JSON.serialize(sr));
    }
}