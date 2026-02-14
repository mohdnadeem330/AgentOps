public class QuoteAssetManagerController {
    @AuraEnabled
    public static void createQuoteLineitems(String quoteId, List<String> assetIds) {
            processRequest(quoteId, assetIds);
    }

    private static void processRequest(String quoteId, List<String> assetIds) {
        // Convert list of assetIds to a comma-separated string for SOQL
        String assetIdsString = String.join(assetIds, ',');
        
        // Get all products associated with the assets
        List<Asset> assetsWithProducts = [SELECT Id, Product2Id, Area__c FROM Asset WHERE Id IN :assetIds and Product2Id != null];
        
        if (assetsWithProducts.isEmpty()) {
            throw new AuraHandledException('No assets found for the provided asset IDs.');
        }
        // Create a set to store unique Product2Id values
        Set<Id> productIds = new Set<Id>();
        
        // Populate the set with Product2Id values from the assets
        for (Asset asset : assetsWithProducts) {
                productIds.add(asset.Product2Id);
        }
        // Query for the standard price book
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        // Query PricebookEntry records for the standard price book and the products
        List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, Pricebook2Id, UnitPrice 
                                                 FROM PricebookEntry 
                                                 WHERE Pricebook2Id = :standardPricebook.Id 
                                                 AND Product2Id IN :productIds];
        
        // Build a map with Product2Id as key and standard PricebookEntry as value
        Map<Id, PricebookEntry> productToPricebookEntryMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry entry : pricebookEntries) {
            productToPricebookEntryMap.put(entry.Product2Id, entry);
        }
        
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();

        // Loop through assets and create QuoteLineItem for each
        for (Asset asset : assetsWithProducts) {
            if (asset.Product2Id != null && productToPricebookEntryMap.containsKey(asset.Product2Id)) {
                PricebookEntry pbe = productToPricebookEntryMap.get(asset.Product2Id);
                QuoteLineItem qli = new QuoteLineItem(
                    QuoteId = quoteId,
                    Product2Id = asset.Product2Id,
                    UnitPrice = pbe.UnitPrice,
                    Asset__c = asset.Id,
                    PricebookEntryId = pbe.Id,
                    Quantity = 1,
                    Area__c = asset.Area__c
                );
                quoteLineItems.add(qli);
            }
        }

        if (!quoteLineItems.isEmpty()) {
            try {
                insert quoteLineItems;
            } catch (DmlException e) {
                throw new AuraHandledException('Failed to insert QuoteLineItems: ' + e.getMessage());
            }
        }
    }

    @AuraEnabled
    public static void deleteQuoteLineItems(String quoteLineItemIds) {
        List<String> errors = new List<String>();
        try {
            List<Id> quoteLineItemIdList = quoteLineItemIds.split(',');
            List<QuoteLineItem> quoteLineItemsToDelete = [SELECT Id FROM QuoteLineItem WHERE Id IN :quoteLineItemIdList];
            
            if (!quoteLineItemsToDelete.isEmpty()) {
                delete quoteLineItemsToDelete;
            } else {
                throw new AuraHandledException('No QuoteLineItems found for the provided IDs.');
            }
        } catch (DmlException e) {
            throw new AuraHandledException('DML Exception: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('General Exception: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects() {
        return [SELECT Id, Name FROM Project__c where Name = 'Aldar Logistics Centers' ORDER BY Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<BuildingSection__c> getBuildings(Id projectId) {
        return [SELECT Id, Name FROM BuildingSection__c  WHERE Project__c = :projectId ORDER BY Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<Asset> getAssets(Id buildingId, Id quoteId) {
        // First, get all the Asset IDs that are already part of QuoteLineItems for this Quote
        Set<Id> existingAssetIds = new Set<Id>();
        for (QuoteLineItem qli : [SELECT Asset__c FROM QuoteLineItem WHERE QuoteId = :quoteId AND Asset__c != null]) {
            existingAssetIds.add(qli.Asset__c);
        }

        // Now, query for Assets that are not in the existingAssetIds set
        return [SELECT Id, Name, Product2Id, Product2.Name, Status, Area__c 
                FROM Asset 
                WHERE Building__c = :buildingId 
                AND Status = 'Available' 
                AND Product2Id != null 
                AND Id NOT IN :existingAssetIds
                ORDER BY Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> getQuoteLineItems(Id quoteId) {
        return [SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice, Asset__r.status,Asset__r.Name,Asset__c
                FROM QuoteLineItem 
                WHERE QuoteId = :quoteId 
                ORDER BY CreatedDate];
    }
}