/*******************************************************************************************
*  Class        : SmartHomeQuoteUtils
*  Developer    : Neelesh@ALdar-24/08/2025
*  Description  : This class is used for KIMBO save QuoteUTIlS. 
*********************************************************************************************
Version                 Modified by            Changes 
1.0                     Neelesh                 Initial Draft
*********************************************************************************************/
global with sharing class SmartHomeQuoteUtils {
    
    public static Pricebook2 getStandardPricebook() {
        return [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    }
    
    public static SBQQ__Quote__c getOrCreateQuote(SmartHomeQuoteWrappers.SaveQuoteRequest request, Id pbId) {
        if (!String.isBlank(request.quoteId)) {
            return [SELECT Id FROM SBQQ__Quote__c WHERE Id = :request.quoteId LIMIT 1];
        }
        
        Id vendorRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        Account vendorAccount = [SELECT Id FROM Account WHERE RecordTypeId = :vendorRecordTypeId AND name = 'KIMBO'  LIMIT 1];
        Id smarthomeQuoteRTId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Smarthome').getRecordTypeId();
        
        
        SBQQ__Quote__c newQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = request.opportunityId,
            SBQQ__Account__c = request.customerId,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = pbId,
            SBQQ__Primary__c = true,
            Vendor__c = vendorAccount.Id, 
            RecordTypeId = smarthomeQuoteRTId          // Set Record Type
        );
        
        insert newQuote;
        return newQuote;
    }
    public static Map<String, Product2> getProductMapBySKU(List<SmartHomeQuoteWrappers.SaveQuoteLine> quoteLines) {
        Set<String> skuSet = new Set<String>();
        for (SmartHomeQuoteWrappers.SaveQuoteLine line : quoteLines) {
            if (!String.isBlank(line.bundleSKU)) {
                skuSet.add(line.bundleSKU.trim());
            }
        }
        
        Map<String, Product2> productMap = new Map<String, Product2>();
        for (Product2 p : [
            SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN :skuSet
        ]) {
            productMap.put(p.ProductCode, p);
        }
        return productMap;
    }
    
    
    public static Map<Id, Id> getPricebookEntries(Set<Id> productIds, Id pricebookId) {
        Map<Id, Id> pbeMap = new Map<Id, Id>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId AND Product2Id IN :productIds
        ]) {
            pbeMap.put(pbe.Product2Id, pbe.Id);
        }
        return pbeMap;
    }
}