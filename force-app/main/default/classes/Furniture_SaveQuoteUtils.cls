/*******************************************************************************************
*  Class 		: Furniture_SaveQuoteUtils
*  Developer 	: Neelesh@ALdar-2/04/2025
*  Description 	: Options - Furniture Save Quote API utilities. 
*********************************************************************************************/
global with sharing class Furniture_SaveQuoteUtils {
    
    global static Pricebook2 getStandardPricebook() {
        return [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1];
    }
    
    global static SBQQ__Quote__c getOrCreateQuote(Furniture_SaveQuoteWrappers.SaveQuoteRequest request, Id pbId) {
        if (!String.isBlank(request.quoteId)) {
            return [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :request.quoteId LIMIT 1];
        }

        Id vendorRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        Account vendorAccount = [SELECT Id FROM Account WHERE RecordTypeId = :vendorRecordTypeId LIMIT 1];
        Id furnitureQuoteRTId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Furniture').getRecordTypeId();

        /*Id vendorRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Vendor' LIMIT 1].Id;
        Account vendorAccount = [SELECT Id FROM Account WHERE RecordTypeId = :vendorRecordTypeId LIMIT 1];
        Id furnitureQuoteRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'SBQQ__Quote__c' AND Name = 'Furniture' LIMIT 1].Id;
        */
        
        //Get Salesorder Id from opportunity
        List<Opportunity> thisOppList = [SELECT Id, SalesOrder__c FROM Opportunity WHERE Id =: request?.opportunityId LIMIT 10];
        // Id salesOrderId = '';
        Id salesOrderId = null;
        if(thisOppList.size() > 0){
            salesOrderId = thisOppList[0].SalesOrder__c;
        }

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = request.opportunityId,
            SBQQ__Account__c = request.customerId,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = pbId,
            SBQQ__Primary__c = true,
            Vendor__c = vendorAccount.Id, 
            FurnitureBundle__c = request.bundleId,
            RecordTypeId = furnitureQuoteRTId          // Set Record Type
        );
        if(salesOrderId != null){
            newQuote = populateQuoteAddressFields(newQuote, salesOrderId);
        }
        
        insert newQuote;
        return newQuote;
    }
    
   
    global static Map<Id, Product2> getProductMap(List<Furniture_SaveQuoteWrappers.SaveQuoteLine> quoteLines) {
        Set<Id> ids = new Set<Id>();
        for (Furniture_SaveQuoteWrappers.SaveQuoteLine line : quoteLines) {
            if (String.isNotBlank(line.productId)) {
                ids.add(line.productId);
            }
        }
        return new Map<Id, Product2>([SELECT Id, Name, ProductCode FROM Product2 WHERE Id IN :ids]);
    }
    
    global static Map<Id, Id> getPricebookEntries(Set<Id> productIds, Id pricebookId) {
        Map<Id, Id> pbeMap = new Map<Id, Id>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId AND Product2Id IN :productIds
        ]) {
            pbeMap.put(pbe.Product2Id, pbe.Id);
        }
        return pbeMap;
    }
    global static Map<Id, Product2> getProductMap(Set<Id> productIds) {
        return new Map<Id, Product2>(
            [SELECT Id, Name, ProductCode FROM Product2 WHERE Id IN :productIds]
        );
    }
    
    
    global static List<SBQQ__ProductOption__c> getProductOptionsByBundleId(String bundleId) {
        return [
            SELECT Id, SBQQ__OptionalSKU__c
            FROM SBQQ__ProductOption__c
            WHERE SBQQ__ConfiguredSKU__c = :bundleId
        ];
    }
    
    global static Map<Id, Id> getOptionPricebookEntries(List<SBQQ__ProductOption__c> options, Id pricebookId) {
        Set<Id> optionProductIds = new Set<Id>();
        for (SBQQ__ProductOption__c o : options) {
            if (o.SBQQ__OptionalSKU__c != null) {
                optionProductIds.add(o.SBQQ__OptionalSKU__c);
            }
        }
        
        Map<Id, Id> pbeMap = new Map<Id, Id>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId AND Product2Id IN :optionProductIds
        ]) {
            pbeMap.put(pbe.Product2Id, pbe.Id);
        }
        return pbeMap;
    }

    /**
     * Publishes a platform event with dynamic event type
     * @param eventTypeName - The API name of the platform event (e.g., 'FurnitureVendorOrderSync__e')
     * @param action - The action to be performed
     * @param recordId - The record ID associated with the event
     * @param vendorId - The vendor ID associated with the event
     * @return Boolean - Returns true if event was published successfully, false otherwise
     */
    public static Boolean publishEvent(String eventTypeName, String action, String recordId, String vendorId) {
        try {
            // Input validation
            if (String.isBlank(eventTypeName)) {
                System.debug(LoggingLevel.ERROR, 'Furniture_SaveQuoteUtils.publishEvent: EventTypeName cannot be null or empty');
                return false;
            }
            
            if (String.isBlank(action)) {
                System.debug(LoggingLevel.ERROR, 'Furniture_SaveQuoteUtils.publishEvent: Action cannot be null or empty');
                return false;
            }
            
            if (String.isBlank(recordId)) {
                System.debug(LoggingLevel.ERROR, 'Furniture_SaveQuoteUtils.publishEvent: RecordId cannot be null or empty');
                return false;
            }

            if (String.isBlank(vendorId)) {
                vendorId = '';
            }
            
            // Validate that the event type exists
            if (!isValidEventType(eventTypeName)) {
                System.debug(LoggingLevel.ERROR, 'Furniture_SaveQuoteUtils.publishEvent: Invalid event type: ' + eventTypeName);
                // Log exception
                
                Logger__c errorLog = LoggerService.addApexServiceCalls(
                    'Furniture Platform Event Publishing - ' + action,
                    'Furniture_SaveQuoteUtils',
                    'publishEvent',
                    'Invalid event type: ' + eventTypeName,
                    'Furniture_SaveQuoteUtils.publishEvent: Invalid event type: ' + eventTypeName,
                    recordId
                );
                LoggerService.save(errorLog);
                throw new CustomException('Invalid event type: ' + eventTypeName);  // This will now trigger the catch block

                //return false;
            }
            
            // Create the platform event dynamically
            SObject event = Schema.getGlobalDescribe().get(eventTypeName).newSObject();
            event.put('Action__c', action);
            event.put('RecordId__c', recordId);
            event.put('VendorId__c', vendorId);
            
            System.debug(LoggingLevel.INFO, 'Furniture_SaveQuoteUtils.publishEvent: Creating event of type ' + eventTypeName + 
                        ' with Action: ' + action + ', RecordId: ' + recordId + ', VendorId: ' + vendorId);
            
            // Publish the event
            Database.SaveResult result = EventBus.publish(event);
            
            // Check if the event was published successfully
            if (result.isSuccess()) {
                System.debug(LoggingLevel.INFO, 'Furniture_SaveQuoteUtils.publishEvent: Event published successfully');
                
                // Log successful platform event publishing
                String requestData = JSON.serialize(event);
                Logger__c successLog = LoggerService.logSuccessResponse(
                    'Platform Event Publishing - ' + action,
                    'PlatformEventPublisher - ' + action,
                    'publishEvent - ' + action,
                    'Event Data: ' + requestData,
                    'Platform event published successfully - ' + eventTypeName,
                    recordId
                );
                LoggerService.save(successLog);
                return true;
            } else {
                System.debug(LoggingLevel.ERROR, 'Furniture_SaveQuoteUtils.publishEvent: Failed to publish event. Errors: ' + result.getErrors());
                
                // Log platform event publishing failure
                String errorMessage = 'Failed to publish Furniture platform event (' + eventTypeName + '): ' + result.getErrors()[0].getMessage();
                Logger__c errorLog = LoggerService.addApexServiceCalls(
                    'Furniture Platform Event Publishing - ' + action,
                    'Furniture_SaveQuoteUtils',
                    'publishEvent',
                    JSON.serialize(event),
                    errorMessage,
                    recordId
                );
                LoggerService.save(errorLog);
                return false;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Furniture_SaveQuoteUtils.publishEvent: Exception occurred - ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Furniture_SaveQuoteUtils.publishEvent: Stack trace - ' + e.getStackTraceString());
            String exceptionDetails = '{"exceptionType":"' + e.getTypeName() + '","message":"' + e.getMessage() + '","lineNumber":"' + e.getLineNumber() + '"}';

            // Log exception
            Logger__c errorLog = LoggerService.addApexServiceCalls(
                'Furniture Platform Event Publishing - ' + action,
                'Furniture_SaveQuoteUtils',
                'publishEvent',
                exceptionDetails,
                // JSON.serialize(e),
                'Furniture_SaveQuoteUtils.publishEvent: Exception occurred - ' + e.getMessage() + ' Stack trace - ' + e.getStackTraceString(),
                recordId
            );
            LoggerService.save(errorLog);
            return false;
        }
    }
    
    /**
     * Validates if the given event type name exists in the org
     * @param eventTypeName - The API name of the platform event
     * @return Boolean - Returns true if the event type exists, false otherwise
     */
    @testVisible
    private static Boolean isValidEventType(String eventTypeName) {
        try {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            return globalDescribe.containsKey(eventTypeName);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Furniture_SaveQuoteUtils.isValidEventType: Exception - ' + e.getMessage());
            // Log exception
            Logger__c errorLog = LoggerService.addApexServiceCallsLog(
                e,
                'Furniture_SaveQuoteUtils - ' + eventTypeName,
                'publishEvent - ' + eventTypeName,
                'Platform Event Publishing - ' + eventTypeName,
                'EventType: ' + eventTypeName + ', isValidEventType: ' + eventTypeName + ', Event: ' + eventTypeName,
                'Exception during platform event publishing. Incorrect Event type: ' + e.getMessage()
            );
            LoggerService.save(errorLog);
            return false;
        }
    }

    /**
    * Method to populate Quote billing and shipping address fields from Sales Order data
    * @param quoteRecord - The SBQQ__Quote__c record to populate
    * @param salesOrderId - The Id of the SalesOrder__c record to get data from
    * @return SBQQ__Quote__c - The populated quote record (no DML performed)
    */
    public static SBQQ__Quote__c populateQuoteAddressFields(SBQQ__Quote__c quoteRecord, Id salesOrderId) {
        
        if(String.isBlank(salesOrderId)){
            return quoteRecord;
        }
        // Query Sales Order with related data
        List<SalesOrder__c> salesOrders = [
            SELECT Id, 
                Account__r.Name,
                AccountCity__c,
                AccountCountry__c,
                Unit__r.UnitNumber__c,
                Unit__r.Project__r.Name,
                Unit__r.Project__r.City__c,
                Unit__r.Project__r.ProjectLocation__c,
                Unit__r.Project__c,
                Unit__r.Name,
                Unit__r.Id
            FROM SalesOrder__c 
            WHERE Id = :salesOrderId
            LIMIT 10
        ];
        
        // Check if Sales Order exists
        if (salesOrders.isEmpty()) {
            System.debug('No Sales Order found with Id: ' + salesOrderId);
            return quoteRecord;
        }
        
        SalesOrder__c salesOrder = salesOrders[0];
        
        // Build project location string
        String projectLocation = salesOrder.Unit__r.Project__r.Name + 
            (String.isNotBlank(salesOrder.Unit__r.Project__c) && String.isNotBlank(salesOrder.Unit__r.Project__r.City__c) ? 
            ', ' + salesOrder.Unit__r.Project__r.City__c : '');
        
        // Extract address components
        String line1 = salesOrder?.Unit__r?.Name + ', '+salesOrder?.Unit__r?.UnitNumber__c;
        String line2 = projectLocation;
        String city = salesOrder?.AccountCity__c;
        String state = '';
        String postalCode = salesOrder?.Unit__r?.Project__r?.ProjectLocation__c;
        String country = salesOrder?.AccountCountry__c;
        String accountName = salesOrder?.Account__r?.Name;
        
        // Build street address (combining line1 and line2)
        String streetAddress = '';
        if (String.isNotBlank(line1) && String.isNotBlank(line2)) {
            streetAddress = line1 + '\n' + line2;
        } else if (String.isNotBlank(line1)) {
            streetAddress = line1;
        } else if (String.isNotBlank(line2)) {
            streetAddress = line2;
        }
        
        // Populate Billing Address fields
        quoteRecord.SBQQ__BillingCity__c = city;
        quoteRecord.SBQQ__BillingCountry__c = country;
        quoteRecord.SBQQ__BillingName__c = accountName;
        quoteRecord.SBQQ__BillingPostalCode__c = postalCode;
        quoteRecord.SBQQ__BillingState__c = state;
        quoteRecord.SBQQ__BillingStreet__c = streetAddress;
        
        // Populate Shipping Address fields (same as billing)
        quoteRecord.SBQQ__ShippingCity__c = city;
        quoteRecord.SBQQ__ShippingCountry__c = country;
        quoteRecord.SBQQ__ShippingName__c = accountName;
        quoteRecord.SBQQ__ShippingPostalCode__c = postalCode;
        quoteRecord.SBQQ__ShippingState__c = state;
        quoteRecord.SBQQ__ShippingStreet__c = streetAddress;
        
        return quoteRecord;
    }
}