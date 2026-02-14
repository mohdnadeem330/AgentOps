@RestResource(urlMapping='/VirtualAccountNotification/*')
global with sharing class VirtualAccountNotificationAPI {
    
    @HttpPost
    global static void processNotification() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            // Parse the request body
            String requestBodyStr = handler.getRequestBody();
            Map<String, Object> requestBody = (Map<String, Object>)JSON.deserializeUntyped(requestBodyStr);
            
            // Extract message object
            Map<String, Object> message = (Map<String, Object>)requestBody.get('message');
            
            // Combine main request and message fields
            Map<String, String> requestBodyMap = new Map<String, String>{
                'requestId' => (String)requestBody.get('requestId'),
                'requestDateTime' => (String)requestBody.get('requesteDateTime'),
                'serviceName' => (String)requestBody.get('serviceName'), 
                'serviceCode' => (String)requestBody.get('serviceCode'),
                'customerCode' => (String)requestBody.get('custCode'),
                'language' => (String)requestBody.get('langCode'),
                'virtualAccountNo' => (String)message.get('virtualAccountID'),
                'virtualAccountIBAN' => (String)message.get('vaIban'),
                'realAccountNumber' => (String)message.get('realAccNo'),
                'transferType' => (String)message.get('transferType'),
                'transactionType' => (String)message.get('txnType'),
                'amount' => (String)message.get('amount'),
                'currency' => (String)message.get('currency'),
                'paymentDetails' => (String)message.get('pymntDtls'),
                'transactionReference' => (String)message.get('transactionRef'),
                'customerReference' => (String)message.get('customerRefNo'),
                'paymentStatus' => (String)message.get('txnStatus'),
                'paymentStatusDescription' => (String)message.get('txnStatusDesc')
            };

            // Validate mandatory fields
            List<String> missingFields = getMissingMandatoryFields(requestBodyMap);
            if (!missingFields.isEmpty()) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = 'Missing mandatory fields in request: ' + String.join(missingFields, ', ');
                handler.finalize();
                return;
            }

            // Create new Inward Remittance record
            Inward_Remittance__c remittance = new Inward_Remittance__c();
            
            // Map request fields to Inward Remittance fields
            remittance.Request_ID__c = requestBodyMap.get('requestId');
            remittance.Request_DateTime__c = parseDateTime(requestBodyMap.get('requestDateTime'));
            remittance.Service_Name__c = requestBodyMap.get('serviceName');
            remittance.Service_Code__c = requestBodyMap.get('serviceCode');
            remittance.Customer_Code__c = requestBodyMap.get('customerCode');
            remittance.Language__c = requestBodyMap.get('language');
            remittance.Virtual_Account_Number__c = requestBodyMap.get('virtualAccountNo');
            remittance.Virtual_Account_IBAN__c = requestBodyMap.get('virtualAccountIBAN');
            remittance.Real_Account_Number__c = requestBodyMap.get('realAccountNumber');
            remittance.Transfer_Type__c = requestBodyMap.get('transferType');
            remittance.Transaction_Type__c = requestBodyMap.get('transactionType');
            remittance.Amount__c = Decimal.valueOf(requestBodyMap.get('amount'));
            remittance.Currency__c = requestBodyMap.get('currency');
            remittance.Payment_Details_Long__c = requestBodyMap.get('paymentDetails');
            remittance.Transaction_Reference__c = requestBodyMap.get('transactionReference');
            remittance.Customer_Reference__c = requestBodyMap.get('customerReference');
            remittance.Payment_Status__c = requestBodyMap.get('paymentStatus');
            remittance.Payment_Status_Description__c = requestBodyMap.get('paymentStatusDescription');
            remittance.Status__c = 'Unprocessed';
            
            // Insert record
            insert remittance;
            
            // Prepare response
            Map<String, String> responseMap = new Map<String, String>();
            responseMap.put('requestId', requestBodyMap.get('requestId'));
            responseMap.put('responseDateTime', System.now().format('yyyyMMddHHmmss'));
            responseMap.put('serviceName', requestBodyMap.get('serviceName'));
            responseMap.put('serviceCode', requestBodyMap.get('serviceCode')); 
            responseMap.put('custCode', requestBodyMap.get('customerCode'));
            responseMap.put('langCode', requestBodyMap.get('language'));
            responseMap.put('serviceStatusCode', 'S');
            responseMap.put('serviceStatusDesc', 'Successfully Received the Transaction Notification');
            
            handler.response.success = true;
            handler.response.statusCode = Constants.STATUS_CODE_SUCCESS;
            handler.response.data = responseMap;
            handler.finalize();
            
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'Error processing notification: ' + e.getMessage();
            handler.finalize(e);
        }
    }
    
    private static List<String> getMissingMandatoryFields(Map<String, String> requestMap) {
        String[] mandatoryFields = new String[]{
            'requestId', 'requestDateTime', 'serviceName', 'serviceCode',
            'customerCode', 'language', 'virtualAccountNo', 'virtualAccountIBAN',
            'realAccountNumber', 'amount', 'currency',
            'transactionReference', 'paymentStatus', 'paymentStatusDescription'
        };
        
        List<String> missingFields = new List<String>();
        for(String field : mandatoryFields) {
            if(String.isBlank(requestMap.get(field))) {
                missingFields.add(field);
            }
        }
        return missingFields;
    }
    
    private static DateTime parseDateTime(String dateTimeStr) {
        // Parse YYYYMMDDHH24MMSS format
        if(String.isBlank(dateTimeStr) || dateTimeStr.length() != 14) return null;
        
        Integer year = Integer.valueOf(dateTimeStr.substring(0,4));
        Integer month = Integer.valueOf(dateTimeStr.substring(4,6));
        Integer day = Integer.valueOf(dateTimeStr.substring(6,8));
        Integer hour = Integer.valueOf(dateTimeStr.substring(8,10));
        Integer minute = Integer.valueOf(dateTimeStr.substring(10,12));
        Integer second = Integer.valueOf(dateTimeStr.substring(12,14));
        
        return DateTime.newInstance(year, month, day, hour, minute, second);
    }
}

/*
/services/apexrest/VirtualAccountNotification
Sample Request Body:
{
    "requestId":"07cf70d0-7a36-11ea-bb18-ac1c89250010",
    "requesteDateTime":"20200409110460",
    "serviceName":"notifyVATransactions",
    "serviceCode":"SVC0124", 
    "custCode":"10000088",
    "langCode":"EN",
    "message":{
        "vaIban":"AE760357412010000000009",
        "virtualAccountID":"1200000000",
        "realAccNo":"12786555456",
        "transferType":"D",
        "amount":"100.00",
        "currency":"AED",
        "pymntDtls":"Test Debit Transaction on VA",
        "transactionRef":"121212331221212",
        "customerRefNo":"testVV112",
        "txnStatus":"S",
        "txnStatusDesc":"Succesfully posted in VAM"
    }
}
*/