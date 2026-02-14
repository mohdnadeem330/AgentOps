@RestResource(urlMapping='/LiveAldar/ServiceRequestDetail')
global with sharing class ServiceRequestDetailWebservice {
    
    // Standard response structure 
    global class StandardResponse {
        public Boolean success;
        public Integer statusCode;
        public String requestId;
        public String message;
        public Object data;
        
        public StandardResponse(Boolean success, Integer statusCode, String message, Object data, String requestId) {
            this.success = success;
            this.statusCode = statusCode;
            this.message = message;
            this.data = data;
            this.requestId = requestId;
        }
    }
    
    global class ReceiptAcknowledgementWrapper {
        public String receiptNumber { get; set; }  
        public Id paymentId { get; set; }
        public String status { get; set; }
        public Decimal amount { get; set; }
        public String paymentType { get; set; }
        public String currencyType { get; set; }
        public ReceiptAcknowledgementWrapper(ReceiptAcknowledgement__c ra) {
            this.receiptNumber = ra.Name;  
            this.paymentId = ra.Id;
            this.status = ra.Status__c;
            this.amount = ra.Amount__c;
            this.paymentType = ra.PaymentType__c;
            this.currencyType = ra.CurrencyIsoCode;
        }
    }
    
    global class LocationInfo {
        public Id id { get; set; }
        public String name { get; set; }
        public String workingDays { get; set; }
        public String workingHours { get; set; }
        public String address { get; set; }
        public String mapLink { get; set; }
    }
    
    global class SellerWrapper {
        public Id sellerId { get; set; }
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String name { get; set; }
    }
    
    global class BuyerWrapper {
        public Id buyerId { get; set; }
        public String buyerName { get; set; }
    }
    
    global class CorporateAccountDetailWrapper {
        public String accountNumberCorporate { get; set; }
        public String bankNameCorporate { get; set; }
        public String beneficiaryNameCorporate { get; set; }
        public String branchCorporate { get; set; }
        public String ibanNoCorporate { get; set; }
        public String swiftCodeCorporate { get; set; }
    }
    
    global class EscrowAccountDetailWrapper {
        public String accountNumberEscrow { get; set; }
        public String bankNameEscrow { get; set; }
        public String beneficiaryNameEscrow { get; set; }
        public String branchEscrow { get; set; }
        public String ibanNoEscrow { get; set; }
        public String swiftCodeEscrow { get; set; }
    }
    
    global class SRDocDetailWrapper {
        public Id id { get; set; }
        public String name { get; set; }
        public String status { get; set; }
        public String rejectedComments { get; set; }
        public SRDocDetailWrapper(HexaBPM__SR_Doc__c doc) {
            this.id = doc.Id;
            this.name = doc.Name;
            this.status = doc.HexaBPM__Status__c;
            this.rejectedComments = doc.HexaBPM__Rejection_Reason__c;
        }
    }
    
    global class UserSelectedLocationWrapper {
        public Id id { get; set; }
        public String name { get; set; }
        public String workingDays { get; set; }
        public String workingHours { get; set; }
        public String address { get; set; }
        public String mapLink { get; set; }
        public UserSelectedLocationWrapper(ServiceTerritory st) {
            this.id = st.Id;
            this.name = st.Name;
            this.workingDays = 'Monday to Friday';
            this.workingHours = '9:15 AM to 5:30 PM';
            List<String> addressParts = new List<String>();
            if (st.Street != null) addressParts.add(st.Street);
            if (st.City != null) addressParts.add(st.City);
            if (st.State != null) addressParts.add(st.State);
            if (st.Country != null) addressParts.add(st.Country);
            if (st.PostalCode != null) addressParts.add(st.PostalCode);
            this.address = String.join(addressParts, ', ');
            this.mapLink = 'https://maps.google.com?q=' + EncodingUtil.urlEncode(this.address, 'UTF-8');
        }
    }
    
    global class StepStatusDetailWrapper {
        public String stepName { get; set; }
        public String status { get; set; }
        public StepStatusDetailWrapper(HexaBPM__Step__c step) {
            this.stepName = step.HexaBPM__Summary__c;
            this.status = step.HexaBPM__Status__r != null ? step.HexaBPM__Status__r.Name : null;
        }
    }
    
    global class DirectDebitRequestWrapper {
        public String CustomerIdType;
        public String CustomerBankAccountType;
        public String CustomerBankName;
        public String CustomerIDNumber;
        public String CustomerAccountName;
        public String CustomerIBANNumber;
        public Id SalesOrderId;
        public String Status;
        public String CustomerId;
        public String RejectionReason;
        public Datetime RejectedDate;
        public Datetime ApprovedDate;
		public Boolean IsVerified;
        
        public DirectDebitRequestWrapper(DirectDebitRequest__c ddr) {
            this.CustomerIdType = ddr.CustomerIdType__c;
            this.CustomerBankAccountType = ddr.CustomerBankAccountType__c;
            this.CustomerBankName = ddr.CustomerBankName__c;
            this.CustomerIDNumber = ddr.CustomerIDNumber__c;
            this.CustomerAccountName = ddr.CustomerAccountName__c;
            this.CustomerIBANNumber = ddr.CustomerIBANNumber__c;
            this.SalesOrderId = ddr.SalesOrder__c;
            this.Status = ddr.Status__c;
            this.CustomerId = ddr.Account__c;
            this.RejectionReason = ddr.Rejection_Reason__c;
            this.RejectedDate = ddr.RejectedDate__c;
            this.ApprovedDate = ddr.ApprovedDate__c;
            this.IsVerified = ddr.isVerified__c;
        }
    }
    
    global class ServiceRequestResponseWrapper {
        public String payBy { get; set; }
        public String SalesorderId { get; set; }
        public String srStatus { get; set; }
        public String pdcCollectionLocation { get; set; }
        public Date pdcCollectionDate { get;Set; }
        public List<LocationInfo> locationInfo { get; set; }
        public ReceiptAcknowledgementWrapper transferFee { get; set; }
        public SellerWrapper seller { get; set; }
        public BuyerWrapper buyer { get; set; }
        public List<SRDocDetailWrapper> srDocumentDetails { get; set; }
        public CorporateAccountDetailWrapper aldarBankDetailsCorporate { get; set; }
        public EscrowAccountDetailWrapper aldarBankDetailsEscrow { get; set; }
        public UserSelectedLocationWrapper userSelectedLocation { get; set; }
        public List<StepStatusDetailWrapper> stepStatusDetails { get; set; }
        public List<DirectDebitRequestWrapper> directDebitRequestDetails { get; set; }
        
        public ServiceRequestResponseWrapper(HexaBPM__Service_Request__c req) {
            this.payBy = req.Pay_By__c;
            this.SalesorderId = req.SalesOrder__c;
            this.srStatus = req.HexaBPM__External_SR_Status__r != null ? req.HexaBPM__External_SR_Status__r.Name : null;
            this.pdcCollectionLocation = req.PDC_Collection_Location__c;
            this.pdcCollectionDate = req.PDC_Collection_date__c;
            
            this.seller = new SellerWrapper();
            this.seller.sellerId = req.HexaBPM__Customer__c;
            this.seller.firstName = req.HexaBPM__Customer__r != null ? req.HexaBPM__Customer__r.FirstName : null;
            this.seller.lastName = req.HexaBPM__Customer__r != null ? req.HexaBPM__Customer__r.LastName : null;
            this.seller.name = req.HexaBPM__Customer__r != null ? req.HexaBPM__Customer__r.Name : null;
            
            this.buyer = new BuyerWrapper();
            this.buyer.buyerId = req.BuyerName__c;
            this.buyer.buyerName = req.BuyerName__r != null ? req.BuyerName__r.Name : null;
            
            this.locationInfo = new List<LocationInfo>();
            for (ServiceTerritory st : [SELECT Id, Name, Type__c, Street, City, State, Country, PostalCode FROM ServiceTerritory WHERE Type__c = 'Property Transfer']) {
                LocationInfo loc = new LocationInfo();
                loc.id = st.Id;
                loc.name = st.Name;
                loc.workingDays = Label.WorkingDays;
                loc.workingHours = Label.WorkingHours;
                List<String> addressParts = new List<String>();
                if (st.Street != null) addressParts.add(st.Street);
                if (st.City != null) addressParts.add(st.City);
                if (st.State != null) addressParts.add(st.State);
                if (st.Country != null) addressParts.add(st.Country);
                if (st.PostalCode != null) addressParts.add(st.PostalCode);
                loc.address = String.join(addressParts, ', ');
                loc.mapLink = 'https://maps.google.com?q=' + EncodingUtil.urlEncode(loc.address, 'UTF-8');
                this.locationInfo.add(loc);
            }
            
            if (req.Service_Territory__r != null) {
                this.userSelectedLocation = new UserSelectedLocationWrapper(req.Service_Territory__r);
            }
            
            List<ReceiptAcknowledgement__c> raList = [SELECT Id, Name, Status__c, Amount__c, PaymentType__c, CurrencyIsoCode FROM ReceiptAcknowledgement__c WHERE ServiceRequest__c = :req.Id LIMIT 1];
            if (!raList.isEmpty()) this.transferFee = new ReceiptAcknowledgementWrapper(raList[0]);
            
            if (req.Unit__r != null && req.Unit__r.Project__r != null) {
                this.aldarBankDetailsCorporate = new CorporateAccountDetailWrapper();
                this.aldarBankDetailsCorporate.accountNumberCorporate = req.Unit__r.Project__r.AccountNumberCorporate__c;
                this.aldarBankDetailsCorporate.bankNameCorporate = req.Unit__r.Project__r.BankNameCorporate__c;
                this.aldarBankDetailsCorporate.beneficiaryNameCorporate = req.Unit__r.Project__r.BeneficiaryNameCorporate__c;
                this.aldarBankDetailsCorporate.branchCorporate = req.Unit__r.Project__r.BranchCorporate__c;
                this.aldarBankDetailsCorporate.ibanNoCorporate = req.Unit__r.Project__r.IBANNoCorporate__c;
                this.aldarBankDetailsCorporate.swiftCodeCorporate = req.Unit__r.Project__r.SwiftCodeCorporate__c;
                
                this.aldarBankDetailsEscrow = new EscrowAccountDetailWrapper();
                this.aldarBankDetailsEscrow.accountNumberEscrow = req.Unit__r.Project__r.AccountNumberEscrow__c;
                this.aldarBankDetailsEscrow.bankNameEscrow = req.Unit__r.Project__r.BankNameEscrow__c;
                this.aldarBankDetailsEscrow.beneficiaryNameEscrow = req.Unit__r.Project__r.BeneficiaryNameEscrow__c;
                this.aldarBankDetailsEscrow.branchEscrow = req.Unit__r.Project__r.BranchEscrow__c;
                this.aldarBankDetailsEscrow.ibanNoEscrow = req.Unit__r.Project__r.IBANNoEscrow__c;
                this.aldarBankDetailsEscrow.swiftCodeEscrow = req.Unit__r.Project__r.SwiftCodeEscrow__c;
            }
            
            this.srDocumentDetails = new List<SRDocDetailWrapper>();
            for (HexaBPM__SR_Doc__c doc : [SELECT Id, Name, HexaBPM__Status__c, HexaBPM__Rejection_Reason__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :req.Id]) {
                this.srDocumentDetails.add(new SRDocDetailWrapper(doc));
            }
            
            this.stepStatusDetails = new List<StepStatusDetailWrapper>();
            for (HexaBPM__Step__c step : [SELECT Id, HexaBPM__Summary__c, HexaBPM__Status__r.Name FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :req.Id]) {
                this.stepStatusDetails.add(new StepStatusDetailWrapper(step));
            }
            
            List<DirectDebitRequest__c> ddrList = [SELECT Id, CustomerIdType__c, CustomerBankAccountType__c, CustomerBankName__c, CustomerIDNumber__c, CustomerAccountName__c,Account__c, Rejection_Reason__c, 
                                                   RejectedDate__c, Approveddate__c,isVerified__c, CustomerIBANNumber__c, SalesOrder__c, Status__c 
                                                   FROM DirectDebitRequest__c WHERE SalesOrder__c = :req.SalesOrder__c AND isActive__c = true AND Account__c =: req.BuyerName__c ];
            if (!ddrList.isEmpty()){
                this.directDebitRequestDetails = new List<DirectDebitRequestWrapper>();
                for(DirectDebitRequest__c ddr: ddrList){
                    this.directDebitRequestDetails.add(new DirectDebitRequestWrapper(ddr));
                }
            } 
        }
    }
    
    @HttpGet
    global static void doGet() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String srId = RestContext.request.params.get('serviceRequestId');
        
        try {
            if (String.isBlank(srId)) {
                sendResponse(false, 400, 'Missing parameter: serviceRequestId', null, null);
                return;
            }
            
            List<HexaBPM__Service_Request__c> srList = [
                SELECT Id, Pay_By__c, HexaBPM__Customer__c, HexaBPM__Customer__r.FirstName, HexaBPM__Customer__r.LastName, HexaBPM__Customer__r.Name, SalesOrder__c,
                HexaBPM__External_SR_Status__r.Name, BuyerName__c, BuyerName__r.Name, Unit__c, Unit__r.Project__r.AccountNumberCorporate__c,
                Unit__r.Project__r.BankNameCorporate__c, Unit__r.Project__r.BeneficiaryNameCorporate__c, Unit__r.Project__r.BranchCorporate__c,
                Unit__r.Project__r.IBANNoCorporate__c, Unit__r.Project__r.SwiftCodeCorporate__c, Service_Territory__r.Name, Service_Territory__r.Street,
                Service_Territory__r.City, Service_Territory__r.State, Service_Territory__r.Country, Service_Territory__r.PostalCode,
                Unit__r.Project__r.AccountNumberEscrow__c, Unit__r.Project__r.BankNameEscrow__c, Unit__r.Project__r.BeneficiaryNameEscrow__c, 
                Unit__r.Project__r.BranchEscrow__c, Unit__r.Project__r.IBANNoEscrow__c, Unit__r.Project__r.SwiftCodeEscrow__c,PDC_Collection_Location__c,PDC_Collection_date__c
                FROM HexaBPM__Service_Request__c
                WHERE Id = :srId
                LIMIT 1
            ];
            
            if (srList.isEmpty()) {
                sendResponse(false, 404, 'Service Request not found', null, srId);
                return;
            }
            
            ServiceRequestResponseWrapper data = new ServiceRequestResponseWrapper(srList[0]);
            sendResponse(true, 200, 'Record fetched successfully', data, srId);
            
        } catch (Exception ex) {
            sendResponse(false, 500, 'Error at line ' + ex.getLineNumber() + ': ' + ex.getMessage(), null, srId);
        }
    }
    
    private static void sendResponse(Boolean success, Integer code, String msg, Object data, String requestId) {
        RestResponse res = RestContext.response;
        res.statusCode = code;
        StandardResponse sr = new StandardResponse(success, code, msg, data, requestId);
        res.responseBody = Blob.valueOf(JSON.serialize(sr));
    }
}