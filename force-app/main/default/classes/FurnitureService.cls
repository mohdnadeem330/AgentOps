/*******************************************************************************************
*  Class 		: FunitureService
*  Developer 	: Neelesh@ALdar-2/04/2025
*  Description 	: This class is used for the main Class for all the operations only. 
*********************************************************************************************/
@RestResource(urlMapping='/FurnitureService/*')
global with sharing class FurnitureService {
    
  /*  @HttpGet
    global static void getRequest() {
        RestResponse res = RestContext.response;
        res.headers.put('Content-Type', 'application/json');
        
        try {
            RestRequest restReq = RestContext.request;           
            // Read query params
            String operation = restReq.params.get('operation');
            String customerId = restReq.params.get('customerId');
            String salesOrderId = restReq.params.get('salesOrderId');            
            
            // Validate required query parameters
           if (String.isBlank(customerId) || String.isBlank(salesOrderId)) {
                res.statusCode = 400; // Bad Request
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new Map<String, String>{ 'error' => 'Missing required query parameters: salesOrderId, customerId' }
                ));
                return;
            }
            
            // Validate operation type
            /*if (String.isBlank(operation) || operation != 'getEligible') {
                res.statusCode = 400; // Bad Request
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new Map<String, String>{ 'error' => 'Invalid or missing operation type. Supported value: getEligible' }
                ));
                return;
            }*/
            
            // Process and return result
            /*Furniture_EligibilityAPIWrapper responseWrapper = Furniture_EligibilityAPIHelper.getEligibility(customerId, salesOrderId);         
            if (responseWrapper == null || responseWrapper.furnitureOrder == null || responseWrapper.furnitureOrder.isEmpty()) {
                res.statusCode = 404; // Not Found
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new Map<String, String>{ 'error' => 'No matching records found for the given salesOrderId and customerId.' }
                ));
                return;
            }  */
            
            //res.statusCode = 200;
            //res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
            
            // Test Class :    Furniture_EligibilityAPIHelperTest
            // Related Class : Furniture_EligibilityAPIHelper
            //                 Furniture_EligibilityAPIWrapper               
            
     /*   } catch (Exception e) {
            res.statusCode = 500; // Internal Server Error
            res.responseBody = Blob.valueOf(JSON.serialize(
                new Map<String, String>{ 'error' => 'An unexpected error occurred while processing the request.' }
            ));
            System.debug('Error in FurnitureService.getRequest: ' + e.getMessage());
        }
    }*/
    
    @HttpPost
    global static void handleRequest(String operation, Furniture_SaveQuoteWrappers.SaveQuoteRequest saveQuoteRequest) {
        RestResponse res = RestContext.response;
        res.headers.put('Content-Type', 'application/json');    
        
        try {
            if (operation == 'getSaveQuote') {     
                
                // Use the passed `saveQuoteRequest` directly (no need to deserialize again)
                Furniture_SaveQuoteWrappers.QuoteResponse responseObj = 
                    Furniture_SaveQuoteHelper.processSaveQuote((Furniture_SaveQuoteWrappers.SaveQuoteRequest)saveQuoteRequest);           
                res.statusCode = 201;
                res.responseBody = Blob.valueOf(JSON.serialize(responseObj));
                
                // Test Class : Test_Furniture_SaveQuoteHelper
                // Related Class : Furniture_SaveQuoteUtils
                //                 Furniture_SaveQuoteWrappers
                //                 Furniture_SaveQuoteHelper                
                //                 Furniture_SaveQuoteMappingHandler
                
                
            } else {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize('Invalid operation specified.'));

                Logger__c errorLog = LoggerService.addApexLog(
                    new CalloutException('Invalid operation specified - '+operation),
                    'Furniture Save Quote - SaveQuote API - Invalid operation',
                    'FurnitureService',
                    'handleRequest'
                );
                LoggerService.save(errorLog);
                throw new CalloutException('Invalid operation specified: ' + operation);
            }
                   //         throw new CalloutException('Invalid operation specified: ' + operation);


        } catch (Exception e) {
            Logger__c errorLog = LoggerService.addApexLog(
                e,
                'Furniture Save Quote - SaveQuote API - Exception Block',
                'FurnitureService',
                'handleRequest'
            );
            LoggerService.save(errorLog);
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize('Unhandled Error: ' + e.getMessage()));
        }
    }
}