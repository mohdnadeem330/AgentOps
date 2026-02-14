/*******************************************************************************************
*  Class        : SmartHomeQuoteHelper
*  Developer    : Neelesh@ALdar-24/08/2025
*  Description  : This class is used for KIMBO save Quote helpers. 
*********************************************************************************************
Version                 Modified by            Changes 
1.0                     Neelesh                 Initial Draft
1.1                     Neelesh   Added logic to calculate ParkingService price as 5% of total quote line prices
*********************************************************************************************/

public with sharing class SmartHomeQuoteHelper {
    
    public static SmartHomeQuoteWrappers.QuoteResponse processSaveQuote(SmartHomeQuoteWrappers.SaveQuoteRequest request) {
        SmartHomeQuoteWrappers.QuoteResponse response = new SmartHomeQuoteWrappers.QuoteResponse();
        
        try {
            // Step 1: Get standard Pricebook
            Pricebook2 pb = SmartHomeQuoteUtils.getStandardPricebook();
            
            // Step 2: Set Pricebook on Opportunity
            if (!String.isBlank(request.opportunityId)) {
                Opportunity opp = new Opportunity(Id = request.opportunityId, Pricebook2Id = pb.Id);
                update opp;
            }
            
            // Step 3: Get or Create Quote
            SBQQ__Quote__c quote = SmartHomeQuoteUtils.getOrCreateQuote(request, pb.Id);
            
            // Delete existing quote lines if any
            List<SBQQ__QuoteLine__c> existingQuoteLines = [
                SELECT Id FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quote.Id
            ];
            if (!existingQuoteLines.isEmpty()) {
                delete existingQuoteLines;
            }
            
            // Step 4: Fetch Product2 records using bundleSKU (ProductCode)
            Map<String, Product2> productCodeToProductMap = SmartHomeQuoteUtils.getProductMapBySKU(request.quoteLines);
            
            // Step 5: Get Pricebook Entries for main products
            Set<Id> productIds = new Set<Id>();
            for (Product2 p : productCodeToProductMap.values()) {
                productIds.add(p.Id);
            }
            Map<Id, Id> productPBEMap = SmartHomeQuoteUtils.getPricebookEntries(productIds, pb.Id);
            
            // Step 6: Fetch Option Products for Bundles (include quantity)
            Map<Id, List<SBQQ__ProductOption__c>> bundleIdToOptionsMap = new Map<Id, List<SBQQ__ProductOption__c>>();
            List<SBQQ__ProductOption__c> options = [
                SELECT SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__r.Id, SBQQ__Quantity__c,
                SBQQ__OptionalSKU__r.Name, SBQQ__OptionalSKU__r.ProductCode
                FROM SBQQ__ProductOption__c
                WHERE SBQQ__ConfiguredSKU__c IN :productIds
            ];
            
            Set<Id> optionProductIds = new Set<Id>();
            for (SBQQ__ProductOption__c opt : options) {
                optionProductIds.add(opt.SBQQ__OptionalSKU__r.Id);
                
                if (!bundleIdToOptionsMap.containsKey(opt.SBQQ__ConfiguredSKU__c)) {
                    bundleIdToOptionsMap.put(opt.SBQQ__ConfiguredSKU__c, new List<SBQQ__ProductOption__c>());
                }
                bundleIdToOptionsMap.get(opt.SBQQ__ConfiguredSKU__c).add(opt);
            }
            
            // Step 7: Get Pricebook Entries for Option Products
            Map<Id, Id> optionProductPBEMap = SmartHomeQuoteUtils.getPricebookEntries(optionProductIds, pb.Id);
            
            // Fetch Unit Prices for all main and option products
            Set<Id> allProductIds = new Set<Id>();
            allProductIds.addAll(productIds);
            allProductIds.addAll(optionProductIds);

            Map<Id, Decimal> productIdToUnitPriceMap = new Map<Id, Decimal>();
            for (PricebookEntry pbe : [
                SELECT Product2Id, UnitPrice
                FROM PricebookEntry
                WHERE Pricebook2Id = :pb.Id AND Product2Id IN :allProductIds
            ]) {
                productIdToUnitPriceMap.put(pbe.Product2Id, pbe.UnitPrice);
            }

            // Step 8: Build and insert Quote Lines
            List<SBQQ__QuoteLine__c> quoteLinesToInsert = new List<SBQQ__QuoteLine__c>();
            
            for (SmartHomeQuoteWrappers.SaveQuoteLine line : request.quoteLines) {
                Product2 bundleProduct = productCodeToProductMap.get(line.bundleSKU);
                
                if (bundleProduct != null && productPBEMap.containsKey(bundleProduct.Id)) {
                    // Add main bundle product
                    quoteLinesToInsert.add(new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = quote.Id,
                        SBQQ__Product__c = bundleProduct.Id,
                        SBQQ__Quantity__c = 1,
                        SBQQ__PricebookEntryId__c = productPBEMap.get(bundleProduct.Id),
                        SBQQ__OptionLevel__c = 1
                    ));
                    
                    // Add its option products with correct quantity
                    List<SBQQ__ProductOption__c> optionRecords = bundleIdToOptionsMap.get(bundleProduct.Id);
                    if (optionRecords != null) {
                        for (SBQQ__ProductOption__c opt : optionRecords) {
                            Product2 option = opt.SBQQ__OptionalSKU__r;
                            Decimal qty = opt.SBQQ__Quantity__c != null ? opt.SBQQ__Quantity__c : 1;

                            if (optionProductPBEMap.containsKey(option.Id)) {
                                quoteLinesToInsert.add(new SBQQ__QuoteLine__c(
                                    SBQQ__Quote__c = quote.Id,
                                    SBQQ__Product__c = option.Id,
                                    SBQQ__Quantity__c = qty,
                                    SBQQ__PricebookEntryId__c = optionProductPBEMap.get(option.Id),
                                    SBQQ__OptionLevel__c = 2
                                ));
                            }
                        }
                    }
                }
            }
            
            // Insert all quote lines
            if (!quoteLinesToInsert.isEmpty()) {
                insert quoteLinesToInsert;
            }
            
            // Step 9: Trigger CPQ Calculation
            QuoteSaver quoteSaver = new QuoteSaver();
            QuoteModel model = new QuoteModel();
            model.record = quote;
            quoteSaver.save(model);
            
            // Step 10: Re-fetch Quote and Lines
            SBQQ__Quote__c savedQuote = [
                SELECT Id, SBQQ__NetAmount__c, SBQQ__Status__c, VAT_Value__c, SBQQ__Opportunity2__c,
                Vendor__c, Vendor__r.Name, Total_Original_List_Price__c,
                Total_Discount_Amount__c, Quote_Total_Discount_Percentage__c,
                Total_Tax__c, Quote_Calculation_Complete__c
                FROM SBQQ__Quote__c WHERE Id = :quote.Id
            ];
            
            List<SBQQ__QuoteLine__c> savedLines = [
                SELECT Id, SBQQ__Product__c, SBQQ__Bundled__c, SBQQ__OptionLevel__c, SBQQ__ProductCode__c,
                       SBQQ__NetPrice__c, SBQQ__ListPrice__c, SBQQ__ProductName__c, SBQQ__RequiredBy__c,
                SBQQ__Product__r.ProductCode
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quote.Id
            ];
            
            response = SmartHomeQuoteMappingHandler.buildResponse(savedQuote, savedLines, request);
            
        } catch (Exception e) {
            response.errorMessage = e.getMessage();
        }
        
        return response;
    }
}