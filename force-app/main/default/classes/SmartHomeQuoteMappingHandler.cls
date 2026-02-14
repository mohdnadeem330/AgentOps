/*******************************************************************************************
*  Class        : SmartHomeQuoteMappingHandler
*  Developer    : Neelesh@ALdar-24/08/2025
*  Description  : This class is used for KIMBO save Quote Handler. 
*********************************************************************************************
Version                 Modified by            Changes 
1.0                     Neelesh                 Initial Draft
*********************************************************************************************/
public with sharing class SmartHomeQuoteMappingHandler {
    
    public static SmartHomeQuoteWrappers.QuoteResponse buildResponse(
        SBQQ__Quote__c quote,
        List<SBQQ__QuoteLine__c> quoteLines,
        SmartHomeQuoteWrappers.SaveQuoteRequest request
        
    ) {
        SmartHomeQuoteWrappers.QuoteResponse response = new SmartHomeQuoteWrappers.QuoteResponse();
        
        response.id = quote.Id;
        response.opportunityId = quote.SBQQ__Opportunity2__c;
        response.quoteStatus = quote.SBQQ__Status__c;
        response.totalQuotePrice = quote.SBQQ__NetAmount__c != null ? String.valueOf(quote.SBQQ__NetAmount__c) : '0.00' + ' AED';
        response.originalQuotePrice = quote.Total_Original_List_Price__c != null ? String.valueOf(quote.Total_Original_List_Price__c) : '0.00';
        response.totalDiscountPercent = quote.Quote_Total_Discount_Percentage__c != null ? String.valueOf(quote.Quote_Total_Discount_Percentage__c) : '0.00';
        
        Decimal totalTaxAmount = 0;
        Decimal totalTaxPercentage = quote.Total_Tax__c != null ? quote.Total_Tax__c : 0;
        if (quote.Total_Tax__c != null && quote.SBQQ__NetAmount__c != null) {
            totalTaxAmount = (quote.SBQQ__NetAmount__c * quote.Total_Tax__c) / 100;
        }
        
        response.taxPercentage = String.valueOf(totalTaxPercentage);
        response.totalTaxAmount = String.valueOf(totalTaxAmount);
        response.vatValue = String.valueOf(quote.VAT_Value__c) + ' AED';
        response.quoteCalculationComplete = quote.Quote_Calculation_Complete__c;
        response.vendorId = quote.Vendor__c;
        response.vendorName = quote.Vendor__r != null ? quote.Vendor__r.Name : null;
        
        response.quoteLineItems = new List<SmartHomeQuoteWrappers.QuoteLineResponse>();
        for (SBQQ__QuoteLine__c line : quoteLines) {
            Decimal netPrice = line.SBQQ__NetPrice__c != null ? line.SBQQ__NetPrice__c : 0;
            Decimal listPrice = line.SBQQ__ListPrice__c != null ? line.SBQQ__ListPrice__c : 0;
            Integer taxPercentage = 5; // Static or configurable
            Decimal taxAmount = (netPrice * taxPercentage) / 100;
            Decimal grossPrice = netPrice + taxAmount;

            String productCode = line.SBQQ__ProductCode__c;
            Boolean isParentBundle = false;
            Boolean isChildProduct = false;
            
            // ✅ Step: Extract parent bundle SKUs from request
            Set<String> parentBundleSKUs = new Set<String>();
            if (request != null && request.quoteLines != null) {
                for (SmartHomeQuoteWrappers.SaveQuoteLine ql : request.quoteLines) {
                    if (!String.isBlank(ql.bundleSKU)) {
                        parentBundleSKUs.add(ql.bundleSKU.trim());
                    }
                }
            }
            
            // ✅ Step: Check if productCode is a parent bundle or child
            if (!String.isBlank(productCode)) {
                if (parentBundleSKUs.contains(productCode)) {
                    isParentBundle = true;
                } else {
                    isChildProduct = true;
                }
            }

            SmartHomeQuoteWrappers.QuoteLineResponse lineResp = new SmartHomeQuoteWrappers.QuoteLineResponse();
            lineResp.quoteLineId = line.Id;
            lineResp.NestedLevel = line.SBQQ__OptionLevel__c;
            lineResp.bundleSKU = line.SBQQ__Product__r != null ? line.SBQQ__Product__r.ProductCode : null;
            lineResp.productName = line.SBQQ__ProductName__c != null ? line.SBQQ__ProductName__c : null;
            lineResp.netPrice = String.valueOf(netPrice) + ' AED';
            lineResp.listPrice = String.valueOf(listPrice) + ' AED';
            lineResp.taxPercentage = taxPercentage;
            lineResp.taxAmount = taxAmount;
            lineResp.isParentBundle = isParentBundle;
            lineResp.isChildProduct = isChildProduct;

            response.quoteLineItems.add(lineResp);
        }
        
        
        return response;
    }
}