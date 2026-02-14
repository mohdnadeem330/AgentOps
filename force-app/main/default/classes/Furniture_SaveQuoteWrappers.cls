global class Furniture_SaveQuoteWrappers {
    
    global class SaveQuoteRequest {
        public String opportunityId;
        public String quoteId;
        public String customerId;
        public String bundleId; 
        public List<SaveQuoteLine> quoteLines;
    }
    
    global class SaveQuoteLine {
        public String productId;
    }
    
    global class QuoteResponse {
        public string id;
        public string opportunityid;
        public string totalQuotePrice;
        public string quoteStatus;
        public string taxPercentage;
        public string totalTaxAmount;
        public string totalDiscountPercent;
        public string vatValue;
     //   public string totalDiscountAmount;      
        public string originalQuotePrice;
        public boolean QuoteCalculationComplete;
        public string bundleSKU; 
        public string vendorName; 
        public string vendorId;        
        public List<QuoteLineResponse> quoteLineItems;
        public String errorMessage;
    }
    
    global class QuoteLineResponse {
        public string id;
        public string productName;
        public string netPrice;
        public string listPrice;
        public string totalPrice;
        public Decimal TaxPercent;  
        public Decimal TaxAmount;
        public boolean isParentBundle;
        public boolean isChildProduct;
        
        public QuoteLineResponse() {}
        public QuoteLineResponse(String id, String productName, String netPrice, String listPrice, String totalPrice, Decimal TaxPercent, Decimal TaxAmount , boolean isParentBundle, boolean isChildProduct ) {
            this.id = id;
            this.productName = productName;
            this.netPrice = netPrice;
            this.listPrice = listPrice;
            this.totalPrice = totalPrice;
            this.TaxPercent = TaxPercent;
            this.TaxAmount = TaxAmount;
            this.isParentBundle = isParentBundle;
            this.isChildProduct = isChildProduct;
            
        }
    }
}