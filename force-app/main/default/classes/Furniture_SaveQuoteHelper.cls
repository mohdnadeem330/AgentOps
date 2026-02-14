/*******************************************************************************************
*  Class        : Furniture_SaveQuoteHelper
*  Developer    : Neelesh@ALdar-2/04/2025
*  Description  : This class is used for save Quote helpers. 
*********************************************************************************************/
public with sharing class Furniture_SaveQuoteHelper {
    
    public static Furniture_SaveQuoteWrappers.QuoteResponse processSaveQuote(Furniture_SaveQuoteWrappers.SaveQuoteRequest request) {
        Furniture_SaveQuoteWrappers.QuoteResponse response = new Furniture_SaveQuoteWrappers.QuoteResponse();
        
        try {
            // Get Standard Pricebook
            Pricebook2 pb = Furniture_SaveQuoteUtils.getStandardPricebook();
            
            // Update Opportunity with Pricebook if required
            if (!String.isBlank(request.opportunityId)) {
                Opportunity opp = new Opportunity(
                    Id = request.opportunityId,
                    Pricebook2Id = pb.Id
                );
                update opp;
            }
            
            // Get or Create Quote
            SBQQ__Quote__c quote = Furniture_SaveQuoteUtils.getOrCreateQuote(request, pb.Id);
            
            // Delete any old QuoteLines not in the new request
            Map<Id, SBQQ__QuoteLine__c> existingLines = new Map<Id, SBQQ__QuoteLine__c>(
                [SELECT Id, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id]
            );
            
            Set<Id> incomingProductIds = new Set<Id>();
            if (request.quoteLines != null) {
                for (Furniture_SaveQuoteWrappers.SaveQuoteLine line : request.quoteLines) {
                    incomingProductIds.add(line.productId);
                }
            }
            
            List<SBQQ__QuoteLine__c> linesToDelete = new List<SBQQ__QuoteLine__c>();
            for (SBQQ__QuoteLine__c line : existingLines.values()) {
                if (!incomingProductIds.contains(line.SBQQ__Product__c)) {
                    linesToDelete.add(line);
                }
            }
            if (!linesToDelete.isEmpty()) {
                delete linesToDelete;
            }
            
            //  Ensure all product IDs include the bundle
            Set<Id> allProductIds = new Set<Id>(incomingProductIds);
            allProductIds.add(request.bundleId);
            
            // Prepare Products, PBE & Options
            Map<Id, Product2> productMap = Furniture_SaveQuoteUtils.getProductMap(allProductIds);
            String bundleSKU = productMap.containsKey(request.bundleId)?productMap.get(request.bundleId).ProductCode:null;
            Map<Id, Id> productPBEMap = Furniture_SaveQuoteUtils.getPricebookEntries(productMap.keySet(), pb.Id);
            List<SBQQ__ProductOption__c> options = Furniture_SaveQuoteUtils.getProductOptionsByBundleId(request.bundleId);
            Map<Id, Id> optionPBEMap = Furniture_SaveQuoteUtils.getOptionPricebookEntries(options, pb.Id);
            
            // Build QuoteLines
            List<SBQQ__QuoteLine__c> quoteLinesToInsert = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> childLinesToUpdate = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c bundleLine;
            
            // Add bundle line from request (if present)
            for (Furniture_SaveQuoteWrappers.SaveQuoteLine inputLine : request.quoteLines) {
                if (inputLine.productId == request.bundleId && productPBEMap.containsKey(inputLine.productId)) {
                    bundleLine = new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = quote.Id,
                        SBQQ__Product__c = inputLine.productId,
                        SBQQ__Quantity__c = 1,
                        SBQQ__PricebookEntryId__c = productPBEMap.get(inputLine.productId)
                    );
                    quoteLinesToInsert.add(bundleLine);
                    break;
                }
            }
            
            // Ensure bundle is always added
            if (bundleLine == null && productPBEMap.containsKey(request.bundleId)) {
                bundleLine = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = request.bundleId,
                    SBQQ__Quantity__c = 1,
                    SBQQ__PricebookEntryId__c = productPBEMap.get(request.bundleId)
                );
                quoteLinesToInsert.add(bundleLine);
            }
            
            // Add child product quote lines
            for (Furniture_SaveQuoteWrappers.SaveQuoteLine inputLine : request.quoteLines) {
                if (inputLine.productId == request.bundleId || !productPBEMap.containsKey(inputLine.productId)) continue;
                
                SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = inputLine.productId,
                    SBQQ__Quantity__c = 1,
                    SBQQ__Bundled__c = true,
                    SBQQ__PricebookEntryId__c = productPBEMap.get(inputLine.productId)
                );
                quoteLinesToInsert.add(quoteLine);
                childLinesToUpdate.add(quoteLine);
            }
            
            // Add optional quote lines
            for (SBQQ__ProductOption__c option : options) {
                if (option.SBQQ__OptionalSKU__c != null && optionPBEMap.containsKey(option.SBQQ__OptionalSKU__c)) {
                    SBQQ__QuoteLine__c optLine = new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = quote.Id,
                        SBQQ__Product__c = option.SBQQ__OptionalSKU__c,
                        SBQQ__Quantity__c = 1,
                        SBQQ__PricebookEntryId__c = optionPBEMap.get(option.SBQQ__OptionalSKU__c)
                    );
                    quoteLinesToInsert.add(optLine);
                    childLinesToUpdate.add(optLine);
                }
            }
            
            // Insert all quote lines
            insert quoteLinesToInsert;
            
            // CPQ Calculation
            QuoteSaver quoteSaver = new QuoteSaver();
            QuoteModel quoteModel = new QuoteModel();
            quoteModel.record = quote;
            QuoteModel savedQuote1 = quoteSaver.save(quoteModel);
            
            
            // Code for adding 5% vat on budle product
            // Re-fetch the bundle quote line after CPQ calculation to get updated pricing info
          /*  SBQQ__QuoteLine__c bundleQuoteLine = [
                SELECT Id, SBQQ__ListPrice__c, VAT__c, VAT_Value__c, SBQQ__PricebookEntryId__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Product__c = :request.bundleId
                AND SBQQ__Quote__c = :quote.Id
                LIMIT 1
            ];
            
            // VAT percentage
            Decimal vatPercent = 5;
            
            // Try to get List Price from quote line
            Decimal listPrice = bundleQuoteLine.SBQQ__ListPrice__c != null ? bundleQuoteLine.SBQQ__ListPrice__c : 0;
            
            // If List Price is null or zero, fetch it from PricebookEntry
            if (listPrice == 0 && bundleQuoteLine.SBQQ__PricebookEntryId__c != null) {
                PricebookEntry pbe = [
                    SELECT UnitPrice 
                    FROM PricebookEntry
                    WHERE Id = :bundleQuoteLine.SBQQ__PricebookEntryId__c
                    LIMIT 1
                ];
                listPrice = pbe.UnitPrice != null ? pbe.UnitPrice : 0;
            }
            
            if (listPrice > 0) {
                Decimal vatValue = (listPrice * vatPercent) / 100;
                
                bundleQuoteLine.VAT__c = vatPercent;
                bundleQuoteLine.VAT_Value__c = vatValue;
                
                update bundleQuoteLine;
            }*/
            
            
            // After insert, update child product lines net price to 0
            List<SBQQ__QuoteLine__c> childLinesToUpdateNetPrice = new List<SBQQ__QuoteLine__c>();
            for (SBQQ__QuoteLine__c ql : quoteLinesToInsert) {
                if (ql.SBQQ__Product__c != request.bundleId) {  // Child product line
                    ql.SBQQ__ListPrice__c = 0;
                    childLinesToUpdateNetPrice.add(ql);
                }
                
            }
            
            
            if (!childLinesToUpdateNetPrice.isEmpty()) {
                update childLinesToUpdateNetPrice;
            }
            
            // Debug inserted lines
            System.debug('--- Inserted Quote Lines ---');
            for (SBQQ__QuoteLine__c ql : quoteLinesToInsert) {
                System.debug('Inserted QuoteLine -> ProductId: ' + ql.SBQQ__Product__c +
                             ' | IsBundle: ' + (ql.SBQQ__Product__c == request.bundleId));
            }
            
            // Get bundle line Id
            Id bundleLineId = null;
            for (SBQQ__QuoteLine__c ql : quoteLinesToInsert) {
                if (ql.SBQQ__Product__c == request.bundleId) {
                    bundleLineId = ql.Id;
                    break;
                }
            }
            
            // Set RequiredBy__c for child lines
            for (SBQQ__QuoteLine__c childLine : childLinesToUpdate) {
                childLine.SBQQ__RequiredBy__c = bundleLineId;
            }
            
            if (!childLinesToUpdate.isEmpty()) {
                update childLinesToUpdate;
            }
            
            
            
            // Re-fetch saved quote and lines
            SBQQ__Quote__c savedQuote = [
                SELECT Id, SBQQ__NetAmount__c, SBQQ__Status__c, SBQQ__CustomerDiscount__c, Total_Original_List_Price__c, 
                Total_Discount_Amount__c,Quote_Total_Discount_Percentage__c, Total_Tax__c,VAT_Value__c,
                Quote_Calculation_Complete__c, SBQQ__Opportunity2__c,
                Vendor__c, Vendor__r.Name
                FROM SBQQ__Quote__c
                WHERE Id = :quote.Id
            ];
            
            List<SBQQ__QuoteLine__c> savedQuoteLines = [
                SELECT Id, SBQQ__Product__c, SBQQ__Bundled__c, SBQQ__NetPrice__c, SBQQ__ListPrice__c, SBQQ__ProductName__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quote.Id
            ];
            
            // Debug final lines
            System.debug('--- Saved Quote Lines (Final) ---');
            for (SBQQ__QuoteLine__c ql : savedQuoteLines) {
                System.debug('Saved Line ProductId: ' + ql.SBQQ__Product__c +
                             ' | Name: ' + ql.SBQQ__ProductName__c +
                             ' | IsBundle: ' + (ql.SBQQ__Product__c == request.bundleId));
            }
            
            // Build and return response
            response = Furniture_SaveQuoteMappingHandler.buildResponse(savedQuote, savedQuoteLines,bundleSKU);
            
        } catch (Exception ex) {
            Logger__c errorLog = LoggerService.addApexLog(
                ex,
                'Furniture Save Quote - SaveQuote API Helper - Exception Block',
                'Furniture_SaveQuoteHelper',
                'processSaveQuote'
            );
            LoggerService.save(errorLog);
            response.errorMessage = ex.getMessage();
        }
        return response;
    }
}