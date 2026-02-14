global class BookingDetailModel {
    
    public Set<Id> unitIds                                                  {get;set;}
    public Id opportunityId                                                 {get;set;}
    public List<SalesOfferUtility.SaleOfferInputParam>   inputWrapperList   {get;set;}
    public String winReason                                                 {get;set;}
    public Id accountId                                                     {get;set;}
    public Boolean affectionPlan                                            {get;set;}
    public Boolean marketingPlan                                            {get;set;}
    public String customerName                                              {get;set;}
    public Boolean sendEmail                                                {get;set;}
    public Id offerUnitId                                                   {get;set;}
    public String orderType                                                 {get;set;}
    public Id selectedEOI                                                   {get;set;}
    public String selectedSignatureType                                     {get;set;}
}