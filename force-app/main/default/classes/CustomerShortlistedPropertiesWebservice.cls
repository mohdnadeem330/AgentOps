/*
* Name               : CustomerShortlistedPropertiesWebservice
* Description        : This class is used to Show the Shortlisted Properties for the Customer through Different Sourcetypes in Live Aldar App
*/

@RestResource (urlMapping = '/customer/shortlistedProperty')
global class CustomerShortlistedPropertiesWebservice {
    
    @HTTPPost
    global static void doPost(String customerId, Boolean digitalSales) {
        
        RestContextHandler handler = new RestContextHandler(true);
        Savepoint sp;
        try {
            sp = Database.setSavepoint();
            RestRequest req = RestContext.request;
            handler.response.data = verifyUnit(customerId,digitalSales);
            handler.response.message = Constants.SUCCESS_MESSAGE;
            handler.response.statusCode = Constants.SUCCESS_CODE_200;
            handler.response.success = true;
            handler.finalize();
            
        } catch (Exception ex) {
            Database.rollback(sp);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage() + ex.getStackTraceString() + ex.getLineNumber();
            handler.finalize(ex);
        }
    }
    
    public static List<ShortlistedPropertyWrapper> verifyUnit(String customerId, Boolean digitalSales) {
        
        Set<Id> unitIds = new Set<Id>();
        Map<Id,Unit__c> getUnitDetails = new Map<Id,Unit__c>();
        Map<Id,Boolean> getUnitAvailabilityStatus = new Map<Id,Boolean>();
        Map<Id,SalesOrder__c> getRelatedSalesorders = new Map<Id,SalesOrder__c>();
        Map<Id,List<ReceiptAcknowledgement__c>> getRelatedReceiptAcknowledgements = new Map<Id,List<ReceiptAcknowledgement__c>>();
        Map<Id,InstallmentLines__c> getRelatedInstallments = new Map<Id,InstallmentLines__c>();
        
        if(String.isBlank(customerId) || digitalSales == null || digitalSales == false){ 
            throw new customException('Missing or invalid input parameters: customerId, digitalSales are required fields');
        }
        
        String accWhrClause = ' (Id = \'' + customerId + '\') ';
        List<Account> accountList = CustomerServiceUtility.getAccountDetail(accWhrClause);
        
        if(accountList.isEmpty()) {
            throw new customException('Account Id not found with provided customerId.');
        }
        
        List<ShortlistedPropertyWrapper> shortListedWrapperList = new List<ShortlistedPropertyWrapper>();
        Account account = accountList[0];
        if(account.Communication_Preferences__r != null) {
            for(Communication_Preference__c cp : account.Communication_Preferences__r) {
                if(cp.Active__c && cp.Category__c == 'Booking' && cp.Unit__c != null) {
                    unitIds.add(cp.Unit__c);
                }
            }
            
            for(Unit__c unit : [Select Id, Name, ProjectName__c,Project__c, CurrencyIsoCode, SellingPrice__c, NumberOfBedrooms__c, NumberOfCarParks__c, NumberOfBathrooms__c, SaleableArea__c, UnitType__c, Status__c, LockedBy__c, LockedByCustomer__c, LockExpiryTime__c, LockTime__c, AssignedTo__c, AssignedToUser__c, RelatedOpportunity__c, RelatedSalesOrder__c From Unit__c Where Id In : unitIds And DigitalSales__c = true]){
                Boolean isAvailable = false;
                
                if(unit.Status__c == 'Available' && unit.LockedByCustomer__c == null && unit.LockedBy__c == null && unit.LockExpiryTime__c == null && unit.LockTime__c == null && unit.RelatedOpportunity__c == null && unit.RelatedSalesOrder__c == null){
                    isAvailable = true;
                }
                else if((unit.Status__c == 'In-Progress' || unit.Status__c == 'Reserved') && unit.LockedByCustomer__c == customerId){
                    isAvailable = true;
                }	
                else if((unit.Status__c == 'In-Progress' || unit.Status__c == 'Reserved' || unit.Status__c == 'Sold' || unit.Status__c == 'Booked') && unit.LockedByCustomer__c != customerId){
                    isAvailable = false;
                }
                getUnitDetails.put(unit.Id,unit);
                getUnitAvailabilityStatus.put(unit.Id,isAvailable);
            }
            
            for(SalesOrder__c so : [SELECT Id, Status__c, Unit__c,SubStatus__c,
                                    (SELECT Id,SalesOrder__c, OutstandingAmount__c, Amount__c, AmountApplied__c, Status__c, UnitNumber__c FROM Payments__r WHERE Status__c = 'Received'),
                                    (Select Id,AmountReceived__c,PendingAmount__c,InstallmentNumber__c,Salesorder__r.Unit__c,InstallmentAmount__c,OutstandingAmount__c From InstallmentLines__r Where InstallmentNumber__c = 1 Limit 1)
                                    FROM SalesOrder__c WHERE Unit__c IN : unitIds AND Account__c = : customerId AND Is_Digital_Sales__c = TRUE AND Status__c NOT IN ('Cancelled', 'Cancelled by User') ORDER BY CreatedDate DESC]) { 
                                        
                                        if(!getRelatedSalesorders.containsKey(so.Unit__c)) {
                                            getRelatedSalesorders.put(so.Unit__c,so);
                                            
                                            if(so.Payments__r != null && so.Payments__r.size() > 0){
                                                getRelatedReceiptAcknowledgements.put(so.Unit__c,so.Payments__r);
                                            }
                                            if(so.InstallmentLines__r != null && so.InstallmentLines__r.size() > 0){
                                                getRelatedInstallments.put(so.Unit__c,so.InstallmentLines__r[0]);
                                            }
                                        }
                                    }
        }  
        
        if(account.Communication_Preferences__r != null) {
            for(Communication_Preference__c cp : account.Communication_Preferences__r) {
                if(cp.Active__c && cp.Category__c == 'Booking' && cp.Unit__c != null) {
                    ShortlistedPropertyWrapper shortListedWrap = new ShortlistedPropertyWrapper();
                    
                    DigitalSalesWrapper digiSaleswrap = new DigitalSalesWrapper();
                    digiSaleswrap.id = cp.Id; 
                    digiSaleswrap.category = cp.Category__c;
                    digiSaleswrap.sourceType = cp.Source_Type__c;
                    digiSaleswrap.accountId = cp.Account__c;
                    digiSaleswrap.unitId = cp.Unit__c;
                    digiSaleswrap.leadId = cp.Lead__c;
                    digiSaleswrap.opportunityId = cp.Opportunity__c;
                    digiSaleswrap.projectName = cp.Project__c;
                    digiSaleswrap.active = cp.Active__c;
                    shortListedWrap.digitalSales = digiSaleswrap;
                    
                    if(cp.Opportunity__c != null && (cp.Source_Type__c == 'Sales Manager' || cp.Source_Type__c == 'Broker Portal')) {
                        shortListedWrap.managerOrBrokerId = cp.OwnerId;
                        shortListedWrap.managerOrBrokerName = cp.OwnerId != null ? cp.Owner.Name : null;
                        
                    }
                    Unit__c unit = getUnitDetails.get(cp.Unit__c); 
                    if(unit != null) {
                        shortListedWrap.unitId = unit.Id;
                        UnitWrapper unitWrap = new UnitWrapper();
                        unitWrap.id = unit.Id;
                        unitWrap.numberOfBedrooms = unit.NumberOfBedrooms__c;
                        unitWrap.numberOfCarParks = unit.NumberOfCarParks__c;
                        unitWrap.numberOfBathrooms = unit.NumberOfBathrooms__c;
                        unitWrap.saleableArea = unit.SaleableArea__c;
                        unitWrap.unitType = unit.UnitType__c;
                        unitWrap.unitCode = unit.Name; 
                        unitWrap.status = unit.Status__c;
                        unitWrap.project = unit.ProjectName__c;
                        unitWrap.projectId = unit.Project__c;
                        unitWrap.currencyIsoCode = unit.CurrencyIsoCode;
                        unitwrap.sellingPrice = unit.SellingPrice__c;
                        shortListedWrap.unitDetails.add(unitWrap);
                        shortListedWrap.unitAvailable = getUnitAvailabilityStatus.get(unit.Id);
                    }
                    
                    SalesOrder__c so = getRelatedSalesorders.get(cp.Unit__c);
                    if(so != null) {
                        SalesorderWrapper salesOrdWrap = new SalesorderWrapper();
                        salesOrdWrap.id = so.Id;
                        salesOrdWrap.status = so.Status__c;
                        salesOrdWrap.unitId = so.Unit__c;
                        salesOrdWrap.subStatus = so.SubStatus__c;
                        shortListedWrap.salesorderDetails.add(salesOrdWrap);
                    }
                    
                    List<ReceiptAcknowledgement__c> receipts = getRelatedReceiptAcknowledgements.get(cp.Unit__c);
                    if(receipts != null && receipts.size() > 0) {
                        for(ReceiptAcknowledgement__c receipt : receipts) {
                            PaymentWrapper paymentWrap = new PaymentWrapper();
                            paymentWrap.id = receipt.Id;
                            paymentWrap.status = receipt.Status__c;
                            paymentWrap.outstandingAmount = receipt.OutstandingAmount__c;
                            paymentWrap.amount = receipt.Amount__c;
                            paymentWrap.amountApplied = receipt.AmountApplied__c;
                            paymentWrap.unitNumber = receipt.UnitNumber__c;
                            paymentWrap.salesOrderId = receipt.SalesOrder__c;
                            shortListedWrap.paymentDetails.add(paymentWrap);
                        }
                    }
                    
                    InstallmentLines__c install = getRelatedInstallments.get(cp.Unit__c);
                    if(install != null) {
                        DownPaymentWrapper downWrap = new DownPaymentWrapper();
                        downWrap.id = install.Id;
                        downWrap.salesOrderId = install.SalesOrder__c;
                        downWrap.unitId = install.SalesOrder__r.Unit__c;
                        downWrap.amountReceived = install.AmountReceived__c;
                        downWrap.installmentAmount = install.InstallmentAmount__c;
                        downWrap.outstandingAmount = install.OutstandingAmount__c;
                        downWrap.pendingAmount = install.PendingAmount__c;
                        shortListedWrap.downpayment = downWrap;
                    }
                    shortListedWrapperList.add(shortListedWrap);
                }
            }
        }
        return shortListedWrapperList;
    }
    
    public class ShortlistedPropertyWrapper {
        public Id unitId {get;set;}
        public Boolean unitAvailable {get;set;}
        public List<PaymentWrapper> paymentDetails {get;set;}
        public DownPaymentWrapper downpayment {get;set;}
        public List<UnitWrapper> unitDetails {get;set;}
        public List<SalesorderWrapper> salesorderDetails {get;set;}
        public String managerOrBrokerName {get;set;}
        public String managerOrBrokerId {get;set;}
        public String defaultDigitalSalesManagerId {get;set;}
        public DigitalSalesWrapper digitalSales {get; set;}
        
        public ShortlistedPropertyWrapper() {
            this.paymentDetails = new List<PaymentWrapper>();
            this.unitDetails = new List<UnitWrapper> ();
            this.salesorderDetails = new List<SalesorderWrapper>();
            this.defaultDigitalSalesManagerId = System.Label.Digital_SalesManager;
            this.digitalSales = new DigitalSalesWrapper();
        }
    }
    
    public Class UnitWrapper {
        public Id id {get;set;}
        public String numberOfBedrooms {get;set;}
        public Decimal numberOfBathrooms {get;set;}
        public Decimal numberOfCarParks {get;set;}
        public Decimal saleableArea {get;set;}
        public String unitType {get;set;}
        public String unitCode {get;set;}
        public String status {get;set;}
        public String project {get;set;}
        public String projectId {get;set;}
        public String currencyIsoCode {get;set;}
        public Decimal sellingPrice {get;set;}
    }
    
    public Class SalesorderWrapper {
        public Id id {get;set;} 
        public String status {get;set;}
        public String unitId {get;set;}
        public String subStatus{get;set;}
    }
    
    public class PaymentWrapper {
        public Id id {get; set;}
        public Id salesOrderId {get; set;}
        public Decimal outstandingAmount {get; set;}
        public Decimal amount {get; set;}
        public Decimal amountApplied {get; set;}
        public String status {get; set;}
        public String unitNumber {get; set;}
    }
    
    public class DownPaymentWrapper {
        public Id unitId {get;set;}
        public Id id {get;set;}
        public Id salesOrderId {get;set;}
        public Decimal amountReceived {get;set;}
        public Decimal installmentAmount {get;set;}
        public Decimal outstandingAmount {get;set;}
        public Decimal pendingAmount {get;set;}
    } 
    
    public class DigitalSalesWrapper {
        public Id id {get;set;}
        public Boolean active {get;set;}
        public String category {get;set;}
        public String sourceType {get; set;}
        public String accountId {get;set;}
        public Id unitId {get;set;}
        public Id leadId {get;set;}
        public Id opportunityId {get;set;}
        public String projectName {get;set;}
    }
}