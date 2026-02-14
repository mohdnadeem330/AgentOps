/*******************************************************************************************
*  Class        : SmartHomeService
*  Developer    : Neelesh@ALdar-24/08/2025
*  Description  : This class is used for KIMBO services. 
*********************************************************************************************
Version                 Modified by            Changes 
1.0                     Neelesh                 Initial Draft
*********************************************************************************************/
@RestResource(urlMapping='/SmartHomeService/*')
global with sharing class SmartHomeService {
    
    @HttpPost
    global static void handleRequest() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.headers.put('Content-Type', 'application/json');    
        
        SmartHomeQuoteWrappers.QuoteResponse quoteResponse;
        try {
            // Parse body into request object
            SmartHomeQuoteWrappers.SaveQuoteRequest request =
                (SmartHomeQuoteWrappers.SaveQuoteRequest) JSON.deserialize(
                    req.requestBody.toString(), SmartHomeQuoteWrappers.SaveQuoteRequest.class
                );
            
            // Basic validation
            if (String.isBlank(request.opportunityId) || 
                String.isBlank(request.customerId) || 
                request.quoteLines == null || request.quoteLines.isEmpty()) {
                    
                    CalloutException ex = new CalloutException('Missing opportunityId, customerId or quoteLines.');
                    Logger__c log = LoggerService.addApexLog(
                        ex,
                        'SmartHome - SaveQuote API - Validation Error',
                        'SmartHomeService',
                        'handleRequest'
                    );
                    LoggerService.save(log);
                    
                    res.statusCode = 400;
                    res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                        'status' => 400,
                            'error' => new Map<String, Object>{
                                'code' => 'MALFORMED_REQUEST',
                                    'message' => 'Request body is malformed or missing required fields',
                                    'details' => ex.getMessage(),
                                    'timestamp' => String.valueOf(System.now()),
                                    'path' => '/services/apexrest/SmartHomeService',
                                    'requestId' => 'req_' + String.valueOf(Crypto.getRandomInteger()).left(8)
                                    }
                    }));
                    return;
                }
            
            // Call quote processor
            quoteResponse = SmartHomeQuoteHelper.processSaveQuote(request);
            
            if (quoteResponse != null && String.isBlank(quoteResponse.errorMessage)) {
                res.statusCode = 201;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new Map<String, Object>{ 'quotes' => new List<Object>{ quoteResponse } }
                ));
            } else {
                CalloutException ex = new CalloutException(
                    quoteResponse != null ? quoteResponse.errorMessage : 'Unknown error'
                );
                Logger__c log = LoggerService.addApexLog(
                    ex,
                    'SmartHome - SaveQuote API - Processing Error',
                    'SmartHomeService',
                    'handleRequest'
                );
                LoggerService.save(log);
                
                res.statusCode = 500;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'status' => 500,
                        'error' => new Map<String, Object>{
                            'code' => 'INTERNAL_SERVER_ERROR',
                                'message' => 'Internal server error occurred',
                                'details' => ex.getMessage(),
                                'timestamp' => String.valueOf(System.now()),
                                'path' => '/services/apexrest/SmartHomeService',
                                'requestId' => 'req_' + String.valueOf(Crypto.getRandomInteger()).left(8)
                                }
                }));
            }
            
        } catch (Exception ex) {
            Logger__c log = LoggerService.addApexLog(
                ex,
                'SmartHome - SaveQuote API - Unhandled Exception',
                'SmartHomeService',
                'handleRequest'
            );
            LoggerService.save(log);
            
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => 500,
                    'error' => new Map<String, Object>{
                        'code' => 'INTERNAL_SERVER_ERROR',
                            'message' => 'Unexpected error during processing',
                            'details' => ex.getMessage(),
                            'timestamp' => String.valueOf(System.now()),
                            'path' => '/services/apexrest/SmartHomeService',
                            'requestId' => 'req_' + String.valueOf(Crypto.getRandomInteger()).left(8)
                            }
            }));
        }
    }
}