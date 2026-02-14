@RestResource(urlMapping='/upsert/SalesOrderRelationship/*')
global with sharing class SalesOrderRelationshipAPI {
    
    @HttpPost
    global static void upsertSalesOrderRelationship() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            // Parse the request body
            Map<String, String> requestBodyMap = handler.getRequestBodyMap();
            
            Sales_Order_Relationship__c sor;
            if (String.isNotBlank(requestBodyMap.get('id'))) {
                // If ID is provided, query for existing Sales Order Relationship
                List<Sales_Order_Relationship__c> existingSOR = [SELECT Id, SalesOrder__c, Account__c, Relationship_Sub_Type__c, Expected_amount__c, CM_Sales_Comments__c, Total_amount_paid_as_of_today__c 
                                                                 FROM Sales_Order_Relationship__c 
                                                                 WHERE Id = :requestBodyMap.get('id') LIMIT 1];
                if (!existingSOR.isEmpty()) {
                    sor = existingSOR[0];
                } else {
                    handler.response.success = false;
                    handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                    handler.response.message = 'No Sales Order Relationship found with the provided ID.';
                    handler.finalize();
                    return;
                }
            } else {
                // If no ID is provided, create a new Sales Order Relationship
                sor = new Sales_Order_Relationship__c();
                
                // Validate required fields for new records
                if (String.isBlank(requestBodyMap.get('salesOrderId')) || String.isBlank(requestBodyMap.get('accountId')) || 
                    String.isBlank(requestBodyMap.get('relationshipSubType')) || String.isBlank(requestBodyMap.get('expectedAmount'))) {
                    handler.response.success = false;
                    handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                    handler.response.message = 'SalesOrderId, AccountId, RelationshipSubType, and ExpectedAmount are required fields for new records.';
                    handler.finalize();
                    return;
                }
            }
            
            // Update fields only if they are provided in the request
            if (String.isBlank(requestBodyMap.get('id')) && String.isNotBlank(requestBodyMap.get('salesOrderId'))) {
                sor.SalesOrder__c = requestBodyMap.get('salesOrderId');
            }
            if (String.isNotBlank(requestBodyMap.get('accountId'))) {
                sor.Account__c = requestBodyMap.get('accountId');
            }
            if (String.isNotBlank(requestBodyMap.get('relationshipSubType'))) {
                sor.Relationship_Sub_Type__c = requestBodyMap.get('relationshipSubType');
            }
            if (String.isNotBlank(requestBodyMap.get('expectedAmount'))) {
                sor.Expected_amount__c = Decimal.valueOf(requestBodyMap.get('expectedAmount'));
            }
            if (String.isNotBlank(requestBodyMap.get('cmSalesComments'))) {
                sor.CM_Sales_Comments__c = requestBodyMap.get('cmSalesComments');
            }
           /* if (String.isNotBlank(requestBodyMap.get('totalAmountPaidAsOfToday'))) {
                sor.Total_amount_paid_as_of_today__c = Decimal.valueOf(requestBodyMap.get('totalAmountPaidAsOfToday'));
            }*/
            
            // Perform upsert
            upsert sor;
            
            handler.response.success = true;
            handler.response.statusCode = Constants.STATUS_CODE_SUCCESS;
            handler.response.message = 'Sales Order Relationship upserted successfully. Id: ' + sor.Id;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            String validationError = Constants.MESSAGE_GENERIC_ERROR;
            if(e.getMessage().indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') != -1)
                 validationError = e.getMessage().substring(e.getMessage().indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION'),e.getMessage().length()-1);
            handler.response.message = validationError;
            handler.finalize(e);
        }
    }
}