/**********************************************************************************************************************
* Name               : CPQQuoteTriggerHandler                                                         
* Description        : Trigger Handler for CPQ Quote Trigger
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           harohilla@aldar.com     14/01/2025      Initial Draft    
******************************************************************************************************************/
public with sharing class CPQQuoteTriggerHandler extends TriggerHandler{
    public static Boolean isProcessing = false;

    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        List<SBQQ__Quote__c> parkingQuotes = new List<SBQQ__Quote__c>();
        Id parkingRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();

        for (SObject sObj : newList) {
            SBQQ__Quote__c quote = (SBQQ__Quote__c)sObj;
            if (quote.RecordTypeId == parkingRecordTypeId) {
                parkingQuotes.add(quote);
            }
        }

        if (!parkingQuotes.isEmpty()) {
            QuoteService.updateQuoteFields(parkingQuotes);
        }
        //Added by Harsh@ALD 14/01/2025 - Generate Quote Document Placeholders on Quote Creation
        //QuoteService.generateDocumentPlaceholders((List<SBQQ__Quote__c>)newList);
    }

    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        List<SBQQ__Quote__c> parkingQuotes = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> furnitureQuotes = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> listOfCalculatedQuotes = new List<SBQQ__Quote__c>();
        Id parkingRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
        Id furnitureRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Furniture').getRecordTypeId();
        Id 	smarthomeRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Smarthome').getRecordTypeId();
        
        for (SObject sObj : newList) {
            SBQQ__Quote__c quote = (SBQQ__Quote__c)sObj;
            // Added via OB-3046
            /*if(quote.Quote_Calculation_Complete__c){
                listOfCalculatedQuotes.add(quote);
            }*/

            if (quote.RecordTypeId == parkingRecordTypeId) {
                parkingQuotes.add(quote);
            }
            else if (quote.RecordTypeId == furnitureRecordTypeId || quote.RecordTypeId == smarthomeRecordTypeId) {
                furnitureQuotes.add(quote);
            }
        }

        if (!parkingQuotes.isEmpty()) {
            QuoteService.updateQuoteFields(parkingQuotes);
        }

        if (!furnitureQuotes.isEmpty()) {
            generateFurnitureOrder(furnitureQuotes, oldMap);
        }

        /*if (!listOfCalculatedQuotes.isEmpty()) {
            triggerCalculationEvent(listOfCalculatedQuotes);
        }*/
    }
    
    
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {

        Id parkingRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();

        // Create a set to store all Ref Ids from the new quotes
        Set<String> refIds = new Set<String>();
    
        // Create a map to store the Account Ids for each Ref Id
        Map<String, Id> refIdToAccountMap = new Map<String, Id>();
    
        // Loop through the new Quotes and collect their Ref Ids and Account Ids
        for (SObject sObj : newList) {
            SBQQ__Quote__c quote = (SBQQ__Quote__c) sObj;
            if (quote.RecordTypeId == parkingRecordTypeId && quote.Parking_Ref_ID__c != null && quote.SBQQ__Account__c != null) {
                refIds.add(quote.Parking_Ref_ID__c);
                refIdToAccountMap.put(quote.Parking_Ref_ID__c, quote.SBQQ__Account__c);
            }
        }
    
        // If no Ref Ids were collected, exit early
        if (refIds.isEmpty()) {
            return;
        }
    
        // Query the Asset object to find any assets with matching Ref Ids and non-'Available' status
        // Also check that the LockedByUser__c field is not locked by another Account
        List<Asset> assets = [
            SELECT Id, Ref_Id__c, Status, LockedByUser__c 
            FROM Asset 
            WHERE Ref_Id__c IN :refIds AND Status != 'Available'
        ];
    
        // Create a map of Ref Ids to Assets that do not have an 'Available' status
        Map<String, Asset> refIdToAssetMap = new Map<String, Asset>();
        for (Asset asset : assets) {
            refIdToAssetMap.put(asset.Ref_Id__c, asset);
        }
    
        // Loop through the Quotes again and check if their Ref Id is in the invalidRefIds set
        for (SObject sObj : newList) {
            SBQQ__Quote__c quote = (SBQQ__Quote__c) sObj;
    
            if (quote.RecordTypeId == parkingRecordTypeId && refIdToAssetMap.containsKey(quote.Parking_Ref_ID__c)) {
                Asset relatedAsset = refIdToAssetMap.get(quote.Parking_Ref_ID__c);
                quote.parkingasset__c = relatedAsset.Id;
                // Check if the asset is locked by another Account
                if (relatedAsset.LockedByUser__c != null && relatedAsset.LockedByUser__c != quote.SBQQ__Account__c) {
                    // Add error if the AccountId does not match the LockedByUser__c field
                    quote.addError('Error: Duplicate Booking! Asset is locked by a different Account.');
                } 
            }
        }
    }
    
    public static void generateFurnitureOrder(List<SBQQ__Quote__c> newList, Map<Id, SObject> oldMap) {
        List<Id> quotesToUpdate = new List<Id>();
        

        for (SBQQ__Quote__c sObj : newList) {
            SBQQ__Quote__c newQuote = sObj;
            SBQQ__Quote__c oldQuote = (SBQQ__Quote__c) oldMap.get(newQuote.Id);

            // Skip nulls just to be safe
            if (newQuote == null || oldQuote == null) continue;
            
            // Debug old and new values
        System.debug('Quote Id: ' + newQuote.Id);
        System.debug('Old Total_Amount_Paid__c: ' + oldQuote.Total_Amount_Paid__c);
        System.debug('New Total_Amount_Paid__c: ' + newQuote.Total_Amount_Paid__c);
        System.debug('Old Total_Amount_Received__c: ' + oldQuote.Total_Amount_Received__c);
        System.debug('New Total_Amount_Received__c: ' + newQuote.Total_Amount_Received__c);

            Boolean isPaidNow = 
                (oldQuote.Total_Amount_Paid__c == null || oldQuote.Total_Amount_Paid__c == 0) &&
                (newQuote.Total_Amount_Paid__c != null && newQuote.Total_Amount_Paid__c > 0);

            Boolean isReceivedNow =
                (oldQuote.Total_Amount_Received__c == null || oldQuote.Total_Amount_Received__c == 0) &&
                (newQuote.Total_Amount_Received__c != null && newQuote.Total_Amount_Received__c > 0);
            
              // Debug evaluation results
        System.debug('isPaidNow: ' + isPaidNow);
        System.debug('isReceivedNow: ' + isReceivedNow);

            if (isPaidNow && isReceivedNow && newQuote.SBQQ__Ordered__c != true) {
                quotesToUpdate.add(newQuote.Id);
            }
        }

        if (!quotesToUpdate.isEmpty()) {
            generateFurnitureOrderFuture(quotesToUpdate);
        }
    }

    @future
    private static void generateFurnitureOrderFuture(List<Id> quoteIdList){
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        for(Id thisQuoteId : quoteIdList){
            SBQQ__Quote__c thisQuote = new SBQQ__Quote__c();
            thisQuote.Id = thisQuoteId;
            thisQuote.SBQQ__Ordered__c = true;
            quotesToUpdate.add(thisQuote);
        }

        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }

    /**
    * Publishes CPQQuoteCalculationEvent__e events for quotes where calculation is complete.
    * Includes logging in case of exceptions.
    * @param calculatedQuotes List of quotes marked as calculation complete.
    */
    @TestVisible
    private static void triggerCalculationEvent(List<SBQQ__Quote__c> calculatedQuotes) {
        List<CPQQuoteCalculationEvent__e> quoteEvents = new List<CPQQuoteCalculationEvent__e>();

        try {
            // Get record type names in bulk
            Map<Id, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosById();

            for (SBQQ__Quote__c quote : calculatedQuotes) {
                String recordTypeName = recordTypeInfoMap.containsKey(quote.RecordTypeId)
                    ? recordTypeInfoMap.get(quote.RecordTypeId).getName()
                    : 'Unknown';

                CPQQuoteCalculationEvent__e quoteEvent = new CPQQuoteCalculationEvent__e(
                    RecordId__c       = quote.Id,
                    ParentRecordId__c = quote.SBQQ__Account__c,
                    Type__c           = recordTypeName,
                    Action__c         = 'Calculation Complete'
                );
                quoteEvents.add(quoteEvent);
            }

            if (!quoteEvents.isEmpty()) {
                System.debug('quoteEvents -> ' + quoteEvents);
                Database.SaveResult[] results = EventBus.publish(quoteEvents);
            }
        } catch (Exception ex) {
            // Log the exception using LoggerService
            Logger__c log = LoggerService.addApexLog(ex,'CPQQuoteTriggerHandler - Error publishing CPQQuoteCalculationEvent','CPQQuoteTriggerHandler','triggerCalculationEvent');
            LoggerService.save(log);
        }
    }

}