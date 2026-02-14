/*******************************************************************************************
*  Class        : SmartHomeQuoteWrappers
*  Developer    : Neelesh@ALdar-24/08/2025
*  Description  : This class is used for KIMBO save Quote  Wrapper. 
*********************************************************************************************
Version                 Modified by            Changes 
1.0                     Neelesh                 Initial Draft
*********************************************************************************************/
global class SmartHomeQuoteWrappers {
    
    global class SaveQuoteRequest {
        public String opportunityId;
        public String quoteId;
        public String customerId;
        public List<SaveQuoteLine> quoteLines;
    }
    
    global class SaveQuoteLine {
        public String bundleSKU;  // Used in request
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
        public String quoteLineId;
        public String bundleSKU;
        public String productName;
        public String netPrice;
        public String listPrice;
 		public Decimal NestedLevel;
      //  public String grossPrice;
        public Integer taxPercentage;
        public Decimal taxAmount;
        public Boolean isParentBundle;
        public Boolean isChildProduct;
        public Integer optionLevel;   
    }
    
    
    
    
}