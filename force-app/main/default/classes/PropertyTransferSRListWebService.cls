@RestResource(urlMapping='/LiveAldar/PropertyTransferSRList')
global with sharing class PropertyTransferSRListWebService {   
    
    // Standard response wrapper class
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
    
    global class ServiceRequestWrapper {
        public Id accountId { get; set; }
        public String name { get; set; }
        public Id serviceRequestId { get; set; }
        public Id unitId { get; set; }
        public String unitName { get; set; }
        public String projectCity { get; set; }
        public String projectLocation { get; set; }
        public String projectName { get; set; }
        public Id projectId { get; set; }
        public Decimal unitTotalArea { get; set; }
        public String salesType { get; set; }
        public String externalStatusName { get; set; }
        public String unitStatus { get; set; }
        public String unitBedrooms { get; set; }
        public String unitCategory { get; set; }
        public String unitType { get; set; }
        public Id customerId { get; set; }
        public String customerFirstName { get; set; }
        public String customerLastName { get; set; }
        public String customerFullName { get; set; }
        
        public ServiceRequestWrapper(HexaBPM__Service_Request__c req) {
            this.accountId = req.HexaBPM__Customer__c;
            this.name = req.Name;
            this.serviceRequestId = req.Id;
            this.unitId = req.Unit__c;
            this.unitName = req.Unit__r != null ? req.Unit__r.Name : null;
            this.projectCity = req.Project_City__c;
            this.projectName = req.ProjectName__c;
            this.projectId = req.Unit__r != null ? req.Unit__r.Project__c : null;
            this.unitTotalArea = req.Unit__r != null ? req.Unit__r.TotalArea__c : null;
            this.salesType = req.SalesOrder__r != null ? req.SalesOrder__r.Sales_Type__c : null;
            this.externalStatusName = req.HexaBPM__External_SR_Status__r != null ? req.HexaBPM__External_SR_Status__r.Name : null;
            this.unitStatus = req.Unit__r != null ? req.Unit__r.Status__c : null;
            this.unitBedrooms = req.Unit__r != null ? req.Unit__r.NumberOfBedrooms__c : null;
            this.unitCategory = req.Unit__r != null ? req.Unit__r.UnitCategory__c : null;
            this.customerId = req.HexaBPM__Customer__c;
            this.customerFirstName = req.HexaBPM__Customer__r != null ? req.HexaBPM__Customer__r.FirstName : null;
            this.customerLastName = req.HexaBPM__Customer__r != null ? req.HexaBPM__Customer__r.LastName : null;
            this.customerFullName = req.HexaBPM__Customer__r != null ? req.HexaBPM__Customer__r.Name : null;
            this.unitType = req.Unit__r != null ? req.Unit__r.UnitType__c : null;
            this.projectLocation = req.Unit__r != null && req.Unit__r.Project__r != null ? req.Unit__r.Project__r.ProjectLocation__c : null;
        }
    }
    
    @HttpGet
    global static void doGet() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String accountId = RestContext.request.params.get('accountId');
        String requestId = accountId;
        if (String.isBlank(accountId)) {
            sendResponse(false, 400, 'Missing required parameter: accountId', null, requestId);
            return;
        }
        try {
            List<HexaBPM__Service_Request__c> serviceRequests = getServiceRequestDetail(accountId);
            List<ServiceRequestWrapper> wrappedResults = new List<ServiceRequestWrapper>();
            for (HexaBPM__Service_Request__c request : serviceRequests) {
                wrappedResults.add(new ServiceRequestWrapper(request));
            }
            if (wrappedResults.isEmpty()) {
                sendResponse(false, 200, 'No service requests found for this accountId', null, requestId);
                return;
            }
            sendResponse(true, 200, 'Service requests fetched successfully', wrappedResults, requestId);
        } catch (Exception e) {
            sendResponse(false, 500, 'Error at line ' + e.getLineNumber() + ': ' + e.getMessage(), null, requestId);
        }
    }
    
    public static List<HexaBPM__Service_Request__c> getServiceRequestDetail(String accountId) {  
        String srType = Constants.PROPERTY_TRANSFER_OffPlan;
        String query = 'SELECT Id, Name, Unit__c, Unit__r.Name, Project_City__c, ProjectName__c, ' +
            'Unit__r.Project__c, Unit__r.TotalArea__c, SalesOrder__r.Sales_Type__c, ' +
            'HexaBPM__External_SR_Status__r.Name, Unit__r.Status__c, Unit__r.UnitType__c, Unit__r.Project__r.ProjectLocation__c, Unit__r.NumberOfBedrooms__c, ' +
            'Unit__r.UnitCategory__c, HexaBPM__Customer__c, HexaBPM__Customer__r.FirstName, ' +
            'HexaBPM__Customer__r.LastName, HexaBPM__Customer__r.Name ' +
            'FROM HexaBPM__Service_Request__c ' +
            'WHERE SRType__c =:srType AND (HexaBPM__Customer__c = :accountId OR BuyerName__c = :accountId)';
        return Database.query(query);
    }
    
    private static void sendResponse(Boolean success, Integer statusCode, String message, Object data, String requestId) {
        RestResponse res = RestContext.response;
        res.statusCode = statusCode;
        StandardResponse sr = new StandardResponse(success, statusCode, message, data, requestId);
        res.responseBody = Blob.valueOf(JSON.serialize(sr));
    }
}