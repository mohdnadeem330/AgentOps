/*******************************************************************************************
*  Class 		: Furniture_SaveQuoteMappingHandler
*  Developer 	: Neelesh@ALdar-2/04/2025
*  Description 	: Options - Furniture - Save Quote API Mappings. 
*********************************************************************************************/
global class Furniture_SaveQuoteMappingHandler {
    
    global static Furniture_SaveQuoteWrappers.QuoteResponse buildResponse(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> quoteLines, String bundleSKU) {
        Furniture_SaveQuoteWrappers.QuoteResponse res = new Furniture_SaveQuoteWrappers.QuoteResponse();
        res.id = quote.Id;
        res.opportunityid = quote.SBQQ__Opportunity2__c;
        res.quoteStatus = quote.SBQQ__Status__c;
        res.totalQuotePrice = String.valueOf(quote.SBQQ__NetAmount__c) + ' AED';
        res.originalQuotePrice = String.valueOf(quote.Total_Original_List_Price__c)+ ' AED';
        res.vatValue = String.valueOf(quote.VAT_Value__c)+ ' AED';
        // res.totalDiscountAmount = String.valueOf(quote.Total_Discount_Amount__c)+ ' AED'; 
        res.totalDiscountPercent = String.valueOf(quote.Quote_Total_Discount_Percentage__c)+ ' AED'; 
        // res.taxPercentage = String.valueOf(quote.Total_Tax__c);
        Decimal taxPercentage = quote.Total_Tax__c != null ? quote.Total_Tax__c : 0;
        Decimal quoteNetAmount = quote.SBQQ__NetAmount__c != null ? quote.SBQQ__NetAmount__c : 0;
        Decimal totalTaxAmount = (quoteNetAmount * taxPercentage) / 100;
        
        res.taxPercentage = String.valueOf(taxPercentage) + ' %';
        res.totalTaxAmount = String.valueOf(totalTaxAmount) + ' AED';
        
        
        res.QuoteCalculationComplete = quote.Quote_Calculation_Complete__c;
        res.vendorId = quote.Vendor__c;
        res.vendorName = quote.Vendor__r != null ? quote.Vendor__r.Name : null;
        res.bundleSKU = bundleSKU;
        res.quoteLineItems = new List<Furniture_SaveQuoteWrappers.QuoteLineResponse>();
        
        Decimal total = 0, taxTotal = 0;
        
        List<SBQQ__QuoteLine__c> fullLines = [
            SELECT Id, SBQQ__NetPrice__c, SBQQ__ListPrice__c, SBQQ__ProductName__c,SBQQ__RequiredBy__c, SBQQ__Bundle__c
            FROM SBQQ__QuoteLine__c
            WHERE Id IN :new Map<Id, SBQQ__QuoteLine__c>(quoteLines).keySet()
        ];
        
        for (SBQQ__QuoteLine__c line : fullLines) {
            Decimal netPrice = line.SBQQ__NetPrice__c != null ? line.SBQQ__NetPrice__c : 0;
            Decimal listPrice = line.SBQQ__ListPrice__c != null ? line.SBQQ__ListPrice__c : 0;
            Decimal tax = netPrice * 0.05;  
            Boolean isParentBundle = line.SBQQ__RequiredBy__c == null;
            System.debug('isParentBundle ' + isParentBundle);
            Boolean isChildProduct = line.SBQQ__RequiredBy__c != null;
            res.quoteLineItems.add(new Furniture_SaveQuoteWrappers.QuoteLineResponse(
                line.Id,
                line.SBQQ__ProductName__c,
                String.valueOf(netPrice) + ' AED',
                String.valueOf(listPrice) + ' AED',
                String.valueOf(netPrice + tax) + ' AED',
                5,
                tax,
                isParentBundle,
                isChildProduct
            ));
        }
        return res;
    }
}