@RestResource(urlMapping='/ParkingService/*')
global with sharing class ParkingService {
    
    global static string documentId;
    global static Id PARKING_RECORDTYPE_ID;
    global static Id PREMPARKING_RECORDTYPE_ID;
    global static Id PREMPARKING_QUOTE_RECORDTYPE_ID;
    
    
    static {
        try {
            PARKING_RECORDTYPE_ID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Parking').getRecordTypeId();
            PREMPARKING_RECORDTYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Premium_Parking').getRecordTypeId();
            PREMPARKING_QUOTE_RECORDTYPE_ID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Parking').getRecordTypeId();
        } catch (Exception e) {
            
        }
    }
    
    @HttpGet
    global static void getRequest() {
        RestResponse res = RestContext.response;
        res.headers.put('Content-Type', 'application/json');
        
        try {
            
            RestRequest restReq = RestContext.request;
            // Reading parametrs from URL
            String operation = restReq.params.get('operation');
            String customerId = restReq.params.get('customerId');
            String community = restReq.params.get('community');
            String projectName = restReq.params.get('projectName');
            String building = restReq.params.get('building');
            string RefId = restReq.params.get('RefId');
            String recordType = restReq.params.get('recordType');
            String quoteId = restReq.params.get('quoteId');
            //Added by Harsh@ALD 25/02/2025
            String salesOrderId = restReq.params.get('salesOrderId');
            
            if (operation == 'getPropertiesList') {
                res.responseBody = blob.valueOf(Json.serialize(getPropertiesList()));
            } else if (operation == 'getPremiumInvList') {
                //res.responseBody = blob.valueOf(Json.serialize(getPremiumInvList(customerId, community, projectName, building)));
                List<PremiumInvList> premiumInvList = getPremiumInvList(customerId, community, projectName, building);
                String jsonResponse = generateOrderedJsonResponse(premiumInvList);
                res.responseBody = Blob.valueOf(jsonResponse);
            } else if (operation == 'getAddOns') {
                res.responseBody = blob.valueOf(Json.serialize(getAddOns(customerId,RefId)));
            } else if (operation == 'getQuoteandLineItems') {
                //updated by Harsh@ALD 25/02/2025 - added salesOrder level filtering
                res.responseBody = blob.valueOf(Json.serialize(getQuoteandLineItems(customerId,quoteId, salesOrderId)));
            } else if (operation == 'getOpportunities') {
                res.responseBody = blob.valueOf(Json.serialize(getOpportunities(customerId,recordType)));
            } 
            //Added by Harsh@ALD 15/02/2025 - Get Order API
            else if (operation == 'getOrderDetails') {
                res.responseBody = blob.valueOf(Json.serialize(getOrderDetails(quoteId)));
            }
            //Added by Harsh@ALD 27/02/2025 - Get details about call to action
            else if (operation == 'getCTA') {
                res.responseBody = blob.valueOf(Json.serialize(getCTADetails(customerId, salesOrderId)));
            }else {
                res.responseBody = blob.valueOf(Json.serialize('Invalid operation specified. Use Correct operation and try again.'));
            }
        } catch (Exception e) {
            res.responseBody = blob.valueOf(Json.serialize('Error 1: ' + e.getMessage()));
        }
        
    }
    
    @HttpPost
    global static void handleRequest(String operation, String community, String building, String parkingType, String parkingTier, String quoteId, string projectName,
                                     LeadInput leadInfo,string customerId, SaveQuoteRequest saveQuoteRequest, QuoteProposalModel quoteProposalData, PaymentDetails paymentDetails, String isPolling) {
                                         //ResponseWrapper response = new ResponseWrapper();
                                        
                                         RestResponse res = RestContext.response;
                                         
                                         res.headers.put('Content-Type', 'application/json');
                                         
                                         Logger__c log = LoggerService.logSuccessResponse('#### Premium Parking API Call', 'ParkingService', 'handleRequest', '#### IS POLLING FROM API -- '+isPolling+' -- QuoteId -- '+quoteId, null, quoteId);
                                         log.StatusCode__c = 201;
                                         insert log;
                                         
                                         try {
                                             if (operation == 'createLeadAndConvert') {
                                                 res.statusCode = 201;
                                                 res.responseBody = blob.valueOf(Json.serialize(createLeadAndConvert(leadInfo)));
                                             } else if (operation == 'saveQuote') {
                                                 res.statusCode = 201;
                                                 res.responseBody = blob.valueOf(Json.serialize(saveQuote(saveQuoteRequest)));
                                             } else if (operation == 'generateDocument') {
                                                 //Added by Harsh@ALD 15/01/2025 - generate document through nintex
                                                 res.responseBody = blob.valueOf(Json.serialize(generateDocument_Nintex(customerId, quoteId, isPolling)));
                                             } 
                                             //Added by Harsh@Aldar 28/11/2024 - Payments API
                                             else if (operation == 'createPayment') {
                                                 res.responseBody = blob.valueOf(Json.serialize(createReceiptAcknowledgment(paymentDetails)));
                                             } else {
                                                 res.responseBody = blob.valueOf(Json.serialize('Invalid operation specified.'));
                                             }
                                         } catch (Exception e) {
                                             //response.errorMessage = 'Error: ' + e.getMessage();
                                             res.responseBody = blob.valueOf(Json.serialize('Error: ' + e.getMessage()));
                                         }
                                     }
    
    global static CTAResponseWrapper getCTADetails(String customerId, String salesOrderId) {
        if (String.isBlank(salesOrderId)) {
            return null;
        }
        
        CTAResponseWrapper responseWrapper = new CTAResponseWrapper();
        responseWrapper.parkingOrder = new List<ParkingOrder>();
        
        // Fetch the related order details based on the salesOrderId
        // Id premiumParkingRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND Name = 'Parking' LIMIT 1].Id;
        List<Order> OrderRecordsList = [SELECT Id, TotalAmount, Amount_In_Progress__c, Amount_Received__c, Amount_Outstanding__c, 
                                        AccountId, Account.CustomerClass__c, 
                                        SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c, 
                                        ParkingAsset__c, ParkingAsset__r.Ref_ID__c, ParkingAsset__r.Parking_Bay__c, 
                                        Sales_Order__c, Sales_Order__r.OwnerSharePercentage__c,
                                        Sales_Order__r.Unit__c, Sales_Order__r.Unit__r.Project__c, Sales_Order__r.Unit__r.BuildingSectionName__c,
                                        Sales_Order__r.Unit__r.Project__r.Name, Sales_Order__r.Unit__r.BuildingSectionName__r.Name
                                        FROM Order 
                                        WHERE Sales_Order__c =: salesOrderId
                                        AND RecordTypeId = :PARKING_RECORDTYPE_ID
                                        
                                       ];
        if(OrderRecordsList.size() <= 0){
            return handleCtaNoOrderFound(customerId, salesOrderId);
        }
        // Collect the project, building section, and customer class data for bulk queries
        Set<Id> projectIds = new Set<Id>();
        Set<String> buildingIds = new Set<String>();
        Set<String> customerClasses = new Set<String>();
        
        for (Order thisOrder : OrderRecordsList) {
            if (thisOrder.SBQQ__Quote__c == null || thisOrder.ParkingAsset__c == null) {
                continue;
            }
            
            projectIds.add(thisOrder.Sales_Order__r.Unit__r.Project__c);
            buildingIds.add(thisOrder.Sales_Order__r.Unit__r.BuildingSectionName__c);
            customerClasses.add(thisOrder.Account.CustomerClass__c);
        }
        
        // Bulk query for the max parking configuration
        Map<String, Integer> maxParkingMap = new Map<String, Integer>();
        List<Product_Configuraton__c> maxParkingRecords = [SELECT Id, Project__c, Building__c, Customer_Class__c, Max_Parking__c 
                                                           FROM Product_Configuraton__c 
                                                           WHERE RecordTypeName__c = 'Max Parking'
                                                           //AND RecordTypeName__c = 'Premium Parking' 
                                                           AND Project__c IN :projectIds
                                                           AND Building__c IN :buildingIds
                                                           AND Customer_Class__c IN :customerClasses];
        
        // Populate the map with the Max Parking data
        for (Product_Configuraton__c config : maxParkingRecords) {
            String key = config.Project__c + '-' + config.Building__c + '-' + config.Customer_Class__c;
            maxParkingMap.put(key, (Integer)config.Max_Parking__c);
        }
        
        // Bulk query for SBQQ__Quote__c records for max parking limit status check
        Map<String, Integer> quoteCountMap = new Map<String, Integer>();
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Project__c, Building_Section__c, SBQQ__Account__c 
                                          FROM SBQQ__Quote__c 
                                          WHERE Project__c IN :projectIds 
                                          AND Building_Section__c IN :buildingIds 
                                          AND SBQQ__Account__c =: customerId
                                          AND SBQQ__Status__c IN ('Accepted', 'Approved')
                                          AND RecordTypeId = :PREMPARKING_QUOTE_RECORDTYPE_ID];
        
        // Populate the map with the count of valid quotes per project and building section
        for (SBQQ__Quote__c quote : quoteList) {
            String key = quote.Project__c + '-' + quote.Building_Section__c;
            if (!quoteCountMap.containsKey(key)) {
                quoteCountMap.put(key, 0);
            }
            quoteCountMap.put(key, quoteCountMap.get(key) + 1);
        }
        Integer maxParkingForCustomer = 0;
        Integer quoteCount = 0;
        // Process each order and populate the response wrapper
        for (Order thisOrder : OrderRecordsList) {
            ParkingOrder parkingOrder = new ParkingOrder();
            parkingOrder.parkingRefId = thisOrder.ParkingAsset__r.Ref_ID__c; 
            parkingOrder.customerId = customerId;
            parkingOrder.quoteId = thisOrder.SBQQ__Quote__c;
            parkingOrder.parkingBayNumber = String.valueOf(thisOrder.ParkingAsset__r.Parking_Bay__c);
            parkingOrder.orderId = thisOrder.Id;
            parkingOrder.opportunityId = thisOrder.SBQQ__Quote__r.SBQQ__Opportunity2__c;
            parkingOrder.amountInProgress = String.valueOf(thisOrder.Amount_In_Progress__c);
            parkingOrder.salesOrderId = salesOrderId;
            parkingOrder.amountReceived = String.valueOf(thisOrder.Amount_Received__c);
            
            // Get max parking for the customer using a composite key for Project, Building, and Customer Class
            String key = thisOrder.Sales_Order__r.Unit__r.Project__c + '-' + thisOrder.Sales_Order__r.Unit__r.BuildingSectionName__c + '-' + thisOrder.Account.CustomerClass__c;
            maxParkingForCustomer = maxParkingMap.containsKey(key) ? maxParkingMap.get(key) : 0;
            
            parkingOrder.amountOutstanding = String.valueOf(thisOrder.Amount_Outstanding__c);
            
            // Get max parking limit status based on the map of quotes
            quoteCount = quoteCountMap.containsKey(thisOrder.Sales_Order__r.Unit__r.Project__c + '-' + thisOrder.Sales_Order__r.Unit__r.BuildingSectionName__c) ? quoteCountMap.get(thisOrder.Sales_Order__r.Unit__r.Project__c + '-' + thisOrder.Sales_Order__r.Unit__r.BuildingSectionName__c) : 0;
            
            parkingOrder.amountTotal = String.valueOf(thisOrder.TotalAmount);
            parkingOrder.orderStatus = getOrderStatus(thisOrder);
            parkingOrder.dueDate = getCTAPaymentDueDate(salesOrderId);
            
            // Add the populated ParkingOrder object to the list
            responseWrapper.parkingOrder.add(parkingOrder);
        }
        responseWrapper.maxParkingForCustomer = String.valueOf(maxParkingForCustomer);
        responseWrapper.maxParkingLimitHit = quoteCount >= maxParkingForCustomer ? true : false;
        responseWrapper.isEligible = isEligible(projectIds, buildingIds);
        List<SalesOrder__c> soList = [SELECT Id, Unit__r.Project__r.Name, Unit__r.BuildingSectionName__r.Name from SalesOrder__c WHERE Id =: salesOrderId];
        if(soList != null && soList.size() > 0){
            responseWrapper.projectName = soList[0].Unit__r.Project__r.Name;
            responseWrapper.buildingName = soList[0].Unit__r.BuildingSectionName__r.Name;
        }
        
        return responseWrapper;
    }
    
    @testVisible
    private static CTAResponseWrapper handleCtaNoQuoteFound(String customerId, String salesOrderId){
        List<SalesOrder__c> salesOrderList = [SELECT Id, Unit__r.BuildingSectionName__c, Unit__r.BuildingSectionName__r.Name, 
                                              Unit__r.Project__c, Unit__r.Project__r.Name, Account__r.CustomerClass__c, OwnerSharePercentage__c 
                                              FROM SalesOrder__c
                                              WHERE Id = :salesOrderId];
        
        List<Product_Configuraton__c> maxParkingRecords = [SELECT Id, Project__c, Building__c, Customer_Class__c, Max_Parking__c 
                                                           FROM Product_Configuraton__c 
                                                           WHERE RecordTypeName__c = 'Max Parking'
                                                           //AND RecordTypeName__c = 'Premium Parking' 
                                                           AND Project__c = :salesOrderList[0].Unit__r.Project__c
                                                           AND Building__c = :salesOrderList[0].Unit__r.BuildingSectionName__c
                                                           AND Customer_Class__c = :salesOrderList[0].Account__r.CustomerClass__c];
        CTAResponseWrapper responseWrapper = new CTAResponseWrapper();
        responseWrapper.parkingOrder = new List<ParkingOrder>();
        if(maxParkingRecords != null && maxParkingRecords.size() > 0){
            responseWrapper.maxParkingForCustomer = String.valueOf(maxParkingRecords[0].Max_Parking__c);
        }
        
        Set<Id> projectIds = new Set<Id>();
        projectIds.add(salesOrderList[0].Unit__r.Project__c);
        Set<String> buildingIds = new Set<String>();
        buildingIds.add(salesOrderList[0].Unit__r.BuildingSectionName__c);
        
        responseWrapper.maxParkingLimitHit = false;
        responseWrapper.isEligible = isEligible(projectIds, buildingIds);
        //Only complete owners are eligible - check added by Harsh@aldar 18/03/2025
        //this override to be remove later
        if(salesOrderList[0].OwnerSharePercentage__c != 100){
            responseWrapper.isEligible = false;
        }
        responseWrapper.projectName = salesOrderList[0].Unit__r.Project__r.Name;
        responseWrapper.buildingName = salesOrderList[0].Unit__r.BuildingSectionName__r.Name;
        
        return responseWrapper;
    }
    
    @testVisible
    private static CTAResponseWrapper handleCtaNoOrderFound(String customerId, String salesOrderId){
        CTAResponseWrapper responseWrapper = new CTAResponseWrapper();
        responseWrapper.parkingOrder = new List<ParkingOrder>();
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Project__c, Project__r.Name, Building_Section__r.Name, SBQQ__Account__c,SBQQ__Opportunity2__c,
                                          ParkingAsset__c, ParkingAsset__r.Ref_ID__c, ParkingAsset__r.Parking_Bay__c, 
                                          Sales_Order__c, SBQQ__Account__r.CustomerClass__c,SBQQ__NetAmount__c, Sales_Order__r.OwnerSharePercentage__c,
                                          Sales_Order__r.Unit__c, Sales_Order__r.Unit__r.Project__c, Sales_Order__r.Unit__r.BuildingSectionName__c
                                          FROM SBQQ__Quote__c 
                                          WHERE Sales_Order__c = :salesOrderId
                                          AND SBQQ__Status__c IN ('Approved')
                                          AND RecordTypeId = :PREMPARKING_QUOTE_RECORDTYPE_ID];
        if(quoteList.size() <= 0){
            return handleCtaNoQuoteFound(customerId, salesOrderId);
        }
        
        // Collect the project, building section, and customer class data for bulk queries
        Set<Id> projectIds = new Set<Id>();
        Set<String> buildingIds = new Set<String>();
        Set<String> customerClasses = new Set<String>();
        
        for(SBQQ__Quote__c thisQuote : quoteList){
            if (thisQuote.ParkingAsset__c == null) {
                continue;
            }
            
            projectIds.add(thisQuote.Sales_Order__r.Unit__r.Project__c);
            buildingIds.add(thisQuote.Sales_Order__r.Unit__r.BuildingSectionName__c);
            customerClasses.add(thisQuote.SBQQ__Account__r.CustomerClass__c);
        }
        
        // Bulk query for the max parking configuration
        Map<String, Integer> maxParkingMap = new Map<String, Integer>();
        List<Product_Configuraton__c> maxParkingRecords = [SELECT Id, Project__c, Building__c, Customer_Class__c, Max_Parking__c 
                                                           FROM Product_Configuraton__c 
                                                           WHERE RecordTypeName__c = 'Max Parking'
                                                           // AND RecordTypeName__c = 'Premium Parking' 
                                                           AND Project__c IN :projectIds
                                                           AND Building__c IN :buildingIds
                                                           AND Customer_Class__c IN :customerClasses];
        
        // Populate the map with the Max Parking data
        for (Product_Configuraton__c config : maxParkingRecords) {
            String key = config.Project__c + '-' + config.Building__c + '-' + config.Customer_Class__c;
            maxParkingMap.put(key, (Integer)config.Max_Parking__c);
        }
        
        
        
        // Bulk query for SBQQ__Quote__c records for max parking limit status check
        Map<String, Integer> quoteCountMap = new Map<String, Integer>();
        List<SBQQ__Quote__c> quoteListAll = [SELECT Id, Project__c, Building_Section__c, SBQQ__Account__c 
                                             FROM SBQQ__Quote__c 
                                             WHERE Project__c IN :projectIds 
                                             AND Building_Section__c IN :buildingIds 
                                             AND SBQQ__Account__c =: customerId
                                             AND SBQQ__Status__c IN ('Accepted', 'Approved')
                                             AND RecordTypeId = :PREMPARKING_QUOTE_RECORDTYPE_ID];
        
        // Populate the map with the count of valid quotes per project and building section
        for (SBQQ__Quote__c quote : quoteListAll) {
            String key = quote.Project__c + '-' + quote.Building_Section__c;
            if (!quoteCountMap.containsKey(key)) {
                quoteCountMap.put(key, 0);
            }
            quoteCountMap.put(key, quoteCountMap.get(key) + 1);
        }
        Integer maxParkingForCustomer = 0;
        Integer quoteCount = 0;
        // Process each order and populate the response wrapper
        for (SBQQ__Quote__c thisQuote : quoteList) {
            ParkingOrder parkingOrder = new ParkingOrder();
            parkingOrder.parkingRefId = thisQuote.ParkingAsset__r.Ref_ID__c; 
            parkingOrder.customerId = customerId;
            parkingOrder.quoteId = thisQuote.Id;
            parkingOrder.parkingBayNumber = String.valueOf(thisQuote.ParkingAsset__r.Parking_Bay__c);
            parkingOrder.orderId = '';
            parkingOrder.opportunityId = thisQuote.SBQQ__Opportunity2__c;
            parkingOrder.amountInProgress = '';
            parkingOrder.salesOrderId = salesOrderId;
            parkingOrder.amountReceived = '';
            
            // Get max parking for the customer using a composite key for Project, Building, and Customer Class
            String key = thisQuote.Sales_Order__r.Unit__r.Project__c + '-' + thisQuote.Sales_Order__r.Unit__r.BuildingSectionName__c + '-' + thisQuote.SBQQ__Account__r.CustomerClass__c;
            maxParkingForCustomer = maxParkingMap.containsKey(key) ? maxParkingMap.get(key) : 0;
            
            parkingOrder.amountOutstanding = '';
            
            // Get max parking limit status based on the map of quotes
            quoteCount = quoteCountMap.containsKey(thisQuote.Sales_Order__r.Unit__r.Project__c + '-' + thisQuote.Sales_Order__r.Unit__r.BuildingSectionName__c) ? quoteCountMap.get(thisQuote.Sales_Order__r.Unit__r.Project__c + '-' + thisQuote.Sales_Order__r.Unit__r.BuildingSectionName__c) : 0;
            
            parkingOrder.amountTotal = String.valueOf(thisQuote.SBQQ__NetAmount__c);
            parkingOrder.orderStatus = 'Unpaid';
            parkingOrder.dueDate = getCTAPaymentDueDate(salesOrderId);
            
            // Add the populated ParkingOrder object to the list
            responseWrapper.parkingOrder.add(parkingOrder);
        }
        responseWrapper.maxParkingForCustomer = String.valueOf(maxParkingForCustomer);
        responseWrapper.maxParkingLimitHit = quoteCount >= maxParkingForCustomer ? true : false;
        responseWrapper.isEligible = isEligible(projectIds, buildingIds);
        List<SalesOrder__c> soList = [SELECT Id, Unit__r.Project__r.Name, Unit__r.BuildingSectionName__r.Name from SalesOrder__c WHERE Id =: salesOrderId];
        if(soList != null && soList.size() > 0){
            responseWrapper.projectName = soList[0].Unit__r.Project__r.Name;
            responseWrapper.buildingName = soList[0].Unit__r.BuildingSectionName__r.Name;
        }
        
        return responseWrapper;
    }
    
    @testVisible
    private static String getOrderStatus(Order thisOrder) {
        Decimal bufferAmount = Decimal.valueOf(System.Label.PremiumParkingPaymentBuffer);
        thisOrder.Amount_In_Progress__c = thisOrder.Amount_In_Progress__c == null ? 0 : thisOrder.Amount_In_Progress__c;
        thisOrder.Amount_Received__c = thisOrder.Amount_Received__c == null ? 0 : thisOrder.Amount_Received__c;
        thisOrder.Amount_Outstanding__c = thisOrder.Amount_Outstanding__c == null ? 0 : thisOrder.Amount_Outstanding__c;
        
        if (thisOrder.Amount_In_Progress__c + thisOrder.Amount_Received__c == 0) {
            return 'Unpaid';
        }
        // If the amount outstanding is 0 and the amount received is >= the total amount (including the buffer)
        else if (thisOrder.Amount_Outstanding__c == 0 && 
                 thisOrder.Amount_Received__c >= (thisOrder.TotalAmount - bufferAmount)) {
                     return 'Paid';
                 }
        else if ((thisOrder.Amount_In_Progress__c + thisOrder.Amount_Received__c) > 0 
                 && (thisOrder.Amount_In_Progress__c + thisOrder.Amount_Received__c ) <= (thisOrder.TotalAmount)) {
                     return 'Payment In Progress';
                 }
        
        // Default case: if none of the conditions match, the status is unknown
        return 'Payment Status Unknown';
    }
    
    @TestVisible
    private static String getCTAPaymentDueDate(Id salesOrderId) {
        List<SalesOrder__c> salesOrderList = [
            SELECT Id, Unit__r.ExpectedCustomerHandoverDate__c 
            FROM SalesOrder__c 
            WHERE Id = :salesOrderId
            LIMIT 1
        ];
        
        if (salesOrderList.isEmpty()) {
            return String.valueOf(System.today());
        }
        
        SalesOrder__c salesOrder = salesOrderList[0];
        
        if (salesOrder.Unit__r == null || salesOrder.Unit__r.ExpectedCustomerHandoverDate__c == null) {
            return String.valueOf(System.today());
        }
        
        Date handoverDate = salesOrder.Unit__r.ExpectedCustomerHandoverDate__c;
       
        
        Integer daysToSubtract = 0; 
        
        // Fetch related Asset records for this SalesOrder
        List<Asset> assetList = [
            SELECT Project_Name__c, Building_Name__c, Parking_Type__c, Parking_Tier__c, 
            Parking_Group__c, Parking_Category__c, Parking_Segment__c 
            FROM Asset 
            WHERE Sales_Order__c = :salesOrderId
            LIMIT 1
        ];
        
        if (!assetList.isEmpty()) {
            Asset asset = assetList[0]; // Taking the first asset (modify if needed)
            
            // Fetch metadata configuration
            List<ParkingPaymentDueDateConfig__mdt> configList = [
                SELECT NoOfDaysDue__c 
                FROM ParkingPaymentDueDateConfig__mdt 
                WHERE Project__c = :asset.Project_Name__c
                AND Building__c = :asset.Building_Name__c
                AND Parking_Type__c = :asset.Parking_Type__c
                AND Parking_Tier__c = :asset.Parking_Tier__c
                AND Parking_Group__c = :asset.Parking_Group__c
                AND Parking_Category__c = :asset.Parking_Category__c
                //AND Parking_Segment__c = :asset.Parking_Segment__c
                LIMIT 1
            ];
            
          
            
            // Use metadata value if found
            if (!configList.isEmpty() && configList[0].NoOfDaysDue__c != null) {
                daysToSubtract = Integer.valueOf(configList[0].NoOfDaysDue__c);
            }
        }
        
        Date dueDate = handoverDate.addDays(-daysToSubtract);
        
        
        // If due date is in the past, use today's date
        if (dueDate < System.today()) {
            dueDate = System.today();
        }
        
        return String.valueOf(dueDate);
    }
    
    @testVisible
    private static Boolean isEligible(Set<Id> projectIds, Set<String> buildingIds){
        List<Product_Configuraton__c> configList = [SELECT Id 
                                                    FROM Product_Configuraton__c 
                                                    WHERE RecordType.Name = 'Lead' 
                                                    AND Project__c IN :projectIds
                                                    AND Building__c IN :buildingIds];
        if(configList != null && configList.size() > 0){
            return true;
        }else{
            return false;
        }
    }
    
    public static PaymentResponse createReceiptAcknowledgment(PaymentDetails paymentDetails) {
        
        PaymentResponse resp = new PaymentResponse();
        
       
        
        try{
            // Create the ReceiptAcknowledgment record
            ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c();
            receipt.PaymentType__c = 'Online';  // Payment Type
            receipt.Amount__c = paymentDetails.amount;  // Paid Amount
            receipt.SalesOrder__c = paymentDetails.salesOrder;  // Sales Order
            receipt.Opportunity__c = paymentDetails.opportunityId;  // Opportunity
            receipt.Remarks__c = paymentDetails.remarks;  // Remarks
            receipt.ReferenceNumber__c = paymentDetails.referenceNumber;  // Reference Number
            receipt.ReceiptDate__c = paymentDetails.paymentDate;  // Payment Date
            receipt.MaturityDate__c = paymentDetails.paymentDate;
            receipt.CurrencyIsoCode = paymentDetails.currencyIsoCode;  // Currency ISO Code
            receipt.Receipt_Type__c = 'Charge Fee';  // Receipt Type
            receipt.Status__c = 'Link Sent';  // Initial Status
            receipt.IsCreatedFromLink__c = true;
            receipt.DoNotSendPaymentURL__c = true;
            receipt.BankName__c = String.isNotBlank(paymentDetails.bankName) ? paymentDetails.bankName : null;
            receipt.CustomerBankAccount__c = paymentDetails.bankAccountNumber;
            
            if((String.isBlank(paymentDetails.orderId) || paymentDetails.orderId == null) && paymentDetails.quoteId != null){
                //Modified by harsh@Aldar 24/02/2025 - adjusted the logic to take quoteid
                List<Order> thisOrderList = [SELECT Id, AccountId FROM Order WHERE SBQQ__Quote__c =: paymentDetails.quoteId AND RecordTypeId = :PARKING_RECORDTYPE_ID ];
                if(thisOrderList != null && thisOrderList.size() > 0){
                    Order thisOrder = thisOrderList[0];
                    receipt.Order__c = thisOrder?.Id;
                    receipt.Account__c = thisOrder?.AccountId;
                    receipt.CPQQuote__c = paymentDetails?.quoteId;
                }else{
                    receipt.Account__c = paymentDetails?.accountId;
                    receipt.CPQQuote__c = paymentDetails?.quoteId;
                }
                
            }else{
                receipt.Order__c = paymentDetails?.orderId;
                receipt.Account__c = paymentDetails?.accountId; 
                receipt.CPQQuote__c = paymentDetails?.quoteId;
            }
            
            insert receipt;
            
            List<ReceiptAcknowledgement__c> thisReceipt = [SELECT Id, Name FROM ReceiptAcknowledgement__c WHERE Id =: receipt.Id];
            resp.amountPaid = paymentDetails.amount;
            resp.message = 'success';
            resp.receiptId = receipt.Id;
            resp.receiptNumber = thisReceipt[0].Name;
            resp = getMerchantDetails(resp);
            resp.success = true;
            
        }catch(Exception e){
            resp.amountPaid = 0;
            resp.message = e.getMessage();
            resp.receiptId = null;
            resp.success = false;
        }
        
        // Return the created record
        return resp;
    }
    @testVisible
    private static PaymentResponse getMerchantDetails(PaymentResponse paymentResponse) {
        
        // Fetch the payment details from custom metadata type
        List<APISetting__mdt> paymentDetails = [SELECT APIKey__c, SecretKey__c, APIId__c FROM APISetting__mdt WHERE MasterLabel = 'Payment'];
        
        // Check if the query returns any data
        if (paymentDetails.isEmpty()) {
            // Handle error or return null
            paymentResponse.success = false;
            paymentResponse.message = 'Payment details not found';
            return paymentResponse;
        }
        
        // Instantiate MerchantDetails object
        MerchantDetails merchDetails = new MerchantDetails();
        
        // Assign values from the metadata record to the MerchantDetails object
        merchDetails.apiKey = paymentDetails[0].APIKey__c;
        merchDetails.secretKey = paymentDetails[0].SecretKey__c;
        merchDetails.profileId = paymentDetails[0].APIId__c;
        
        // Set the transaction reference number
        merchDetails.referenceNumber = paymentResponse.receiptId + '-' + Datetime.now().getTime();
        
        // Assign the MerchantDetails to the paymentResponse object
        paymentResponse.MerchantDetails = merchDetails;
        
        return paymentResponse;
    }
    
    global static List<PropertiesList> getPropertiesList() {
        // Define the SOQL query with GROUP BY clause
        String query = 'SELECT Project__r.CommunityName__c communityName, Project__r.Name projectName, Project__c projectId, Building__r.Name  buildingName, Building__c buildingId ' +
            'FROM Product_Configuraton__c ' +
            'WHERE RecordType.Name = \'Lead\' ' +
            'GROUP BY Project__r.CommunityName__c, Project__r.Name, Project__c, Building__r.Name, Building__c order by Project__r.CommunityName__c';
        
        // Execute the query and store the results
        List<AggregateResult> results = Database.query(query);
        
        // Map to group communities by project names
        Map<String, String> projectMap = new Map<String, String>();
        
        // Loop through the results to populate the map
        for (AggregateResult result : results) {
            String projectName = (String) result.get('projectName');
            String projectId = (String) result.get('projectId');
            String communityName = (String) result.get('communityName');
            String buildingName = (String) result.get('buildingName');
            String buildingId = (String) result.get('buildingId');
            projectMap.put(communityName+'projName:'+projectName+'projId:'+projectId+'buildingName:'+buildingName+'buildingId:'+buildingId,communityName+':'+projectName+':'+buildingName);
        }
        
        // Create the list of project wrappers to return
        List<PropertiesList> responseList = new List<PropertiesList>();
        
        // Format the response
        for (String projectKey : projectMap.keySet()) {
            PropertiesList project = new PropertiesList();
            project.community = projectKey.subStringBefore('projName:');
            project.projectName = projectKey.subStringAfter('projName:').subStringBefore('buildingName:').subStringBefore('projId:');
            project.buildingName = projectKey.subStringAfter('buildingName:').subStringBefore('buildingId:');
            project.projectId = projectKey.subStringAfter('projName:').subStringBefore('buildingName:').subStringAfter('projId:');
            project.buildingId = projectKey.subStringAfter('buildingName:').subStringAfter('buildingId:');
            responseList.add(project);
        }
        
        return responseList;
    }
    
    global static List<PremiumInvList> getPremiumInvList(string customerId, string community, String projectName, string building) {
        if (String.isEmpty(projectName)) {
            throw new IllegalArgumentException('Project Name cannot be null or empty.');
        }
        
        
        // Construct the SOQL query with filtering criteria
        String query = 'SELECT Product2Id,Project__r.CommunityName__c, Project__r.Name, Parking_Ref_ID__c,Ref_Id__c, ' +
            'id, Distance_From_Lobby_in_m__c, Capacity__c, Parking_Type__c, ' +
            'Parking_Tier__c, Base_Cost__c,List_Price__c,Parking_Group__c, Parking_Segment__c, Parking_Category__c,Status,Parent_Asset__c   ' +
            'FROM Asset ' +
            'WHERE '+     'Status = \'Available\'' + ' AND ' +
            'Project__r.Name = :projectName ' +
            'AND Building_Name__c = :building ' +
            'AND RecordTypeName__c = \'Premium_Parking\' ' ;
        
        // Execute the query
        List<Asset> assets = Database.query(query);
        
        // Map to group parking reference details by community name and project name
        Map<String, Map<String, List<ParkingDetail>>> communityProjectMap = new Map<String, Map<String, List<ParkingDetail>>>();
        
        // Populate the map with query results
        for (Asset asset : assets) {
            String communityName = asset.Project__r.CommunityName__c;
            String projName = asset.Project__r.Name;
            
            // Initialize the nested map if not already present
            if (!communityProjectMap.containsKey(communityName)) {
                communityProjectMap.put(communityName, new Map<String, List<ParkingDetail>>());
            }
            
            Map<String, List<ParkingDetail>> projectMap = communityProjectMap.get(communityName);
            
            if (!projectMap.containsKey(projName)) {
                projectMap.put(projName, new List<ParkingDetail>());
            }
            
            // Create and populate the parking detail object
            ParkingDetail parkingDetail = new ParkingDetail();
            parkingDetail.id = asset.id;
            parkingDetail.distanceFromLobby = asset.Distance_From_Lobby_in_m__c;
            parkingDetail.capacity = asset.Capacity__c;
            parkingDetail.parkingType = asset.Parking_Type__c;
            parkingDetail.parkingTier = asset.Parking_Tier__c;
            parkingDetail.parkingGroup = asset.Parking_Group__c;
            parkingDetail.parkingSegment = asset.Parking_Segment__c;
            parkingDetail.parkingCategory = asset.Parking_Category__c;
            parkingDetail.listprice = asset.List_Price__c;
            parkingDetail.parkingRefId = String.valueOf(asset.Parking_Ref_ID__c);
            parkingDetail.RefId = String.valueOf(asset.Ref_Id__c); 
            parkingDetail.productId = asset.Product2Id;
            parkingDetail.status = asset.status;
            parkingDetail.parentassetid = asset.Parent_Asset__c;
            
            // Add the parking detail to the project list
            projectMap.get(projName).add(parkingDetail);
        }
        
        // Convert the map to the desired response format
        List<PremiumInvList> responseList = new List<PremiumInvList>();
        
        for (String communityName : communityProjectMap.keySet()) {
            Map<String, List<ParkingDetail>> projectMap = communityProjectMap.get(communityName);
            
            for (String projName : projectMap.keySet()) {
                PremiumInvList project = new PremiumInvList(communityName,projName,building,projectMap.get(projName));
                responseList.add(project);
            }
        }
        
        return responseList;
    }
    
    private static String generateOrderedJsonResponse(List<PremiumInvList> premiumInvList) {
        JSONGenerator gen = JSON.createGenerator(false);
        
        gen.writeStartArray();
        for (PremiumInvList item : premiumInvList) {
            gen.writeStartObject();
            gen.writeStringField('communityName', item.communityName);
            gen.writeStringField('projectName', item.projectName);
            gen.writeStringField('building', item.building);
            
            // Writing parking slots as an array
            gen.writeFieldName('parkingSlots');
            gen.writeStartArray();
            for (ParkingDetail slot : item.parkingSlots) {
                gen.writeStartObject();
                gen.writeStringField('productId', slot.productId != null ? slot.productId : '');
                gen.writeStringField('parkingType', slot.parkingType);
                gen.writeStringField('parkingTier', slot.parkingTier);
                gen.writeStringField('parkingRefId', slot.parkingRefId);
                gen.writeStringField('RefId', slot.RefId);
                gen.writeStringField('parkingGroup', slot.parkingGroup != null ? string.valueOf(slot.parkingGroup) : '');
                gen.writeStringField('parkingSegment', slot.parkingSegment != null ? string.valueOf(slot.parkingSegment) : '');
                gen.writeStringField('parkingCategory', slot.parkingCategory!= null ? string.valueOf(slot.parkingCategory) : '');
                gen.writeStringField('id', slot.id);
                gen.writeStringField('distanceFromLobby', slot.distanceFromLobby != null ? string.valueOf(slot.distanceFromLobby) : '');
                gen.writeStringField('capacity', slot.capacity != null ? string.valueOf(slot.capacity) : '');
                gen.writeNumberField('listprice', slot.listprice);
                gen.writeStringField('status', slot.status);
                gen.writeStringField('parentassetid', slot.parentassetid != null ? string.valueOf(slot.parentassetid) : '');
                
                gen.writeEndObject();
            }
            gen.writeEndArray();
            
            gen.writeEndObject();
        }
        gen.writeEndArray();
        
        return gen.getAsString();
    }
    
    global static LeadResponse createLeadAndConvert(LeadInput requestBody) {
        LeadResponse response = new LeadResponse();
        Group leadOptionsUpgradeQueue = Utilities.getQueueInformation(Constants.LEAD_OU_QUEUE);
        
        try {
            // Step 1: Create a new Lead record and populate fields with request data
            Lead newLead = new Lead();
            newLead.FirstName = requestBody.FirstName;
            newLead.LastName = requestBody.LastName;
            newLead.Email = requestBody.Email;
            newLead.MobileNumber1__c = requestBody.MobileNumber1;
            newLead.MobileCountryCode__c = requestBody.MobileCountryCode;
            newLead.CountryOfResidence__c = requestBody.CountryOfResidence;
            newLead.Nationality__c = requestBody.Nationality;
            newLead.LeadOrigin__c = requestBody.LeadOrigin;
            newLead.Project__c = requestBody.Project;
            newLead.State = requestBody.State;
            newLead.Country = requestBody.Country;
            newLead.PropertyUsage__c = requestBody.PropertyUsage;
            newLead.CustomerLocation__c = requestBody.CustomerLocation;
            newLead.SalesType__c = requestBody.SalesType;
            newLead.LeadSource = requestBody.LeadSource;
            newLead.EnquiryCategory__c = requestBody.EnquiryCategory;
            newLead.EnquiryTrigger__c = requestBody.EnquiryTrigger;
            newLead.SalesOrigin__c = requestBody.SalesOrigin;
            newLead.ResidentStatus__c = requestBody.ResidentStatus;
            newLead.Lead_Type__c = requestBody.Lead_Type;
            newLead.LeadSubType__c = requestBody.LeadSubType;
            newLead.Sales_Order__c = requestBody.SalesOrderId; // Assuming the field API name is Sales_Order__c
            newLead.CustomerType__c = 'Existing Customer';
            //newLead.ownerid = UserInfo.getUserId();
            //newLead.owner__c = UserInfo.getUserId();
            //added by harsh 07/01/2025
            newLead.Financing__c = 'No';
            newLead.BuyRent__c = 'Buy';
            
            // Insert the Lead record
            if(requestBody.SalesOrderId <> null){
                List<SalesOrder__c> thisSOList = [SELECT Id, Account__c FROM SalesOrder__c WHERE Id =: requestBody.SalesOrderId];
                if(thisSOList.size() > 0 && thisSOList[0].Account__c <> null){
                    newLead.ExistingAccount__c = thisSOList[0].Account__c;
                }
            }
            
            LeadFirstMethodOfContactService.skipLeadTrigger = true;
            //Added by Harsh@Aldar 26/03 - Since Lead trigger is being skipped, unique key has to be populated
            List<String> existingAccountUniqueKey = Utilities.getUniqueKeyMapping(Constants.LEAD_ACCOUNT_UNIQUE_KEYS).Values__c.split(';');
            newLead.UniqueKey1__c = UniqueKeyUtility.getUniqueKey(newLead,existingAccountUniqueKey);
            insert newLead;
            
            Set<Id> leadSet = new Set<Id>();
            leadSet.add(newLead.id);
            
            List<Database.LeadConvertResult> leadConvertResults = UtilitiesWithoutSharing.convertLeads(leadSet);
            
            // Create a Set to store the Opportunity IDs
            Set<Id> opportunityIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            // Iterate over the list of LeadConvertResult objects
            for (Database.LeadConvertResult result : leadConvertResults) {
                // Check if the result was successful and an Opportunity was created
                if (result.isSuccess() && result.getOpportunityId() != null) {
                    // Add the Opportunity ID to the Set
                    opportunityIds.add(result.getOpportunityId());
                    accountIds.add(result.getaccountId());
                }
            }
            
            response.message = 'Lead created and Converted Successfully';
            response.success = true;
            response.leadId = newLead.Id;
            response.opportunityId = opportunityIds.iterator().next();
            response.accountId = accountIds.iterator().next();
            
            Pricebook2 pb = [select id from Pricebook2 where name='Standard Price Book'];
            //   RecordType rc = [select id from RecordType where SobjectType='Opportunity' and name='Premium Parking'];
            Opportunity opp = new Opportunity();
            opp.id = response.opportunityId;
            opp.Pricebook2Id = pb.id;
            opp.RecordTypeId = PREMPARKING_RECORDTYPE_ID;
            update opp;
            
        } catch (Exception e) {
            //Handle exceptions and set error details in response
            response.message = 'Error: ' + e.getMessage();
            response.success = false;
        }
        
        // Return the response
        return response;
    }
    
    global static QuoteResponse saveQuote(SaveQuoteRequest request) {
        
        QuoteResponse response = new QuoteResponse();
        try {
            // Step 1: Create a new Quote record
            String RefId =  String.valueOf(request.RefId);
            List<Asset> assetList = [select id, Product2.name,Project__r.Name,
                                     Parking_Type__c,Parking_Tier__c, Status,
                                     Parking_Group__c, Parking_Segment__c, Parking_Category__c,list_price__c from Asset where Ref_ID__c = :RefId and RecordTypeName__c='Premium_Parking' ];
            Pricebook2 pb = new Pricebook2();
            if(!Test.isRunningTest()){    
                pb = [select id from Pricebook2 where name='Standard Price Book'];
                //In case of Quote Create - Handle Asset
                if(request != null && request.quoteId == ''){
                    updateAssetStatus(assetList[0].Id, request.customerId);     
                }         
                
                //HARSH@ALD - OPP ID NULL CHECK ADDED 
                if(!String.isBlank(request.opportunityId) && request.opportunityId != null){
                    Opportunity opp = new Opportunity();
                    opp.id = request?.opportunityId;
                    opp.Pricebook2Id = pb.id;
                    update opp;
                }
            }
            
            
            List<SBQQ__Quote__c> quoteList = [select id from SBQQ__Quote__c where id = :request.quoteId];
            Id quoteRecId;
            if(quoteList.size()<=0)
            {
                SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
                newQuote.SBQQ__Opportunity2__c = request.opportunityId;
                newQuote.SBQQ__Account__c = request.customerId;
                newQuote.SBQQ__Status__c = 'Draft'; // Or any other default status
                newQuote.Parking_Type__c = assetList[0].Parking_Type__c;
                newQuote.Parking_Tier__c = assetList[0].Parking_Tier__c;
                newQuote.Parking_Group__c = assetList[0].Parking_Group__c;
                newQuote.Parking_Segment__c = assetList[0].Parking_Segment__c;
                newQuote.Parking_Category__c = assetList[0].Parking_Category__c;
                newQuote.Parking_Ref_ID__c = request.RefId;
                newQuote.ParkingAsset__c = assetList[0].Id;
                newQuote.RecordTypeId = PREMPARKING_QUOTE_RECORDTYPE_ID;

                //if(!Test.isRunningTest()){
                newQuote.SBQQ__PriceBook__c = pb.id;
                // }
                
                newQuote.SBQQ__Primary__c = true;
                insert newQuote;
                quoteRecId = newQuote.id;
            }
            
            else
            {
                quoteRecId = quoteList[0].id;
            }
            
            // Define the map to hold the Name as the key and Id as the value
            Map<String, Id> productMap = new Map<String, Id>();
            Map<String, Id> productlevelMap = new Map<String, Id>();
            
            // Populate the map with Name as the key and Id as the value
            for (Product2 product : [SELECT Name,Productcode,Id FROM Product2]) {
                productMap.put(product.Name, product.Id);
                productlevelMap.put(product.Productcode, product.Id);
            }
            
            // Step 2: Create Quote Line records
            List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
            
            Map<String, String> fieldNumberMap = new Map<String, String>();
            
            if(assetList.size()>0)
            {
                fieldNumberMap.put('0',assetList[0].Product2.Name+':0');
                
                if (request.quoteLines != null && !request.quoteLines.isEmpty())
                {
                    fieldNumberMap.put('00',assetList[0].Project__r.Name+':00');
                    fieldNumberMap.put('1',assetList[0].Parking_Type__c+':1');
                    fieldNumberMap.put('2',assetList[0].Parking_Tier__c+':2');
                    fieldNumberMap.put('3',assetList[0].Parking_Group__c+':3');
                    fieldNumberMap.put('4',assetList[0].Parking_Category__c+':4');
                    if(assetList[0].Parking_Segment__c!=null)
                    {
                        fieldNumberMap.put('5',assetList[0].Parking_Segment__c+':5');
                    }
                }   
                
            }
            
            Map<id,id> productPriceBookMap = new Map<id,id>();
            for(PricebookEntry pbe : [select Product2.Name, List_Price_Incl_VAT__c,Product2Id,Id from PricebookEntry  where Pricebook2.name='Standard Price Book'])
            {
                productPriceBookMap.put(pbe.Product2Id,pbe.Id);
            }
            
            
            // Create a new map to store the SKU name as the key and the ProductOption Id as the value
            Map<String, Id> productOptionMap = new Map<String, Id>();
            Map<String, Id> productOptionassetMap = new Map<String, Id>();
            
            // Query to fetch SBQQ__ProductOption__c records based on asset
            List<SBQQ__ProductOption__c> assetproductOptions = [SELECT Id, SBQQ__OptionalSKU__r.Name,SBQQ__ConfiguredSKU__r.name,SBQQ__ConfiguredSKU__c 
                                                                FROM SBQQ__ProductOption__c 
                                                                WHERE (SBQQ__OptionalSKU__c IN :productMap.values() OR SBQQ__OptionalSKU__c IN :productlevelMap.values()) 
                                                                AND (SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Type__c OR
                                                                     SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Tier__c OR
                                                                     SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Group__c OR
                                                                     SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Category__c OR
                                                                     SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Segment__c OR
                                                                     SBQQ__ConfiguredSKU__r.name =  :assetList[0].Project__r.Name)];
            
           
            // Iterate over the queried records
            for(SBQQ__ProductOption__c po : assetproductOptions) {
                String skuName = po.SBQQ__OptionalSKU__c;
                
                // Store the OptionalSKU name as the key and the ProductOption Id as the value
                productOptionassetMap.put(skuName, po.Id);
            }
            
            
            
            // Query to fetch SBQQ__ProductOption__c records
            List<SBQQ__ProductOption__c> productOptions = [SELECT Id, SBQQ__OptionalSKU__r.Name 
                                                           FROM SBQQ__ProductOption__c 
                                                           WHERE SBQQ__OptionalSKU__c IN :productMap.values() and (SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Type__c OR
                                                                                                                   SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Tier__c OR
                                                                                                                   SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Group__c OR
                                                                                                                   SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Category__c OR
                                                                                                                   SBQQ__ConfiguredSKU__r.name =  :assetList[0].Parking_Segment__c OR
                                                                                                                   SBQQ__ConfiguredSKU__r.name =  :assetList[0].Project__r.Name) ];
            
            // Iterate over the queried records
            for(SBQQ__ProductOption__c productOption : productOptions) {
                String skuName = productOption.SBQQ__OptionalSKU__c;
                
                // Store the OptionalSKU name as the key and the ProductOption Id as the value
                productOptionMap.put(skuName, productOption.Id);
            }
            
            
            List<SBQQ__QuoteLine__c> quoteLineList = [select id from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteRecId];
            delete quoteLineList;
            
            set<Id> quoteProducts = new Set<Id>();
            
            
            for(String str : fieldNumberMap.values())
            {
                SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
                quoteLine.CurrencyIsoCode='AED';
                quoteLine.SBQQ__Quote__c = quoteRecId;
                quoteLine.SBQQ__Quantity__c = 1;
                quoteLine.VAT__c = 0;
                
                String level = str.substringAfter(':');
                if(level=='1' && productlevelMap.containsKey(str.substringBefore(':').replace(' ', '')+'Type'))
                {
                    quoteLine.SBQQ__Product__c = productlevelMap.get(str.substringBefore(':').replace(' ', '')+'Type');
                }
                else if (level=='2' && productlevelMap.containsKey(str.substringBefore(':').replace(' ', '')+'Tier'))
                {
                    quoteLine.SBQQ__Product__c = productlevelMap.get(str.substringBefore(':').replace(' ', '')+'Tier');   
                }
                else 
                {
                    quoteLine.SBQQ__Product__c = productMap.get(str.substringBefore(':'));    
                } 
                quoteLine.SBQQ__PricebookEntryId__c = productPriceBookMap.get(productMap.get(str.substringBefore(':')));
                
                
                
                quoteProducts.add(productMap.get(str.substringBefore(':')));
                if(str.substringAfter(':')=='0' && str!='')
                {
                    quoteLine.Parking_Ref_ID__c = String.valueOf(request.RefId);
                    quoteLine.Record_Category__c='Inventory';
                    quoteLine.SBQQ__ListPrice__c=assetList[0].list_price__c;
                    quoteLine.SBQQ__NetPrice__c=assetList[0].list_price__c;
                    quoteLine.Asset__c=assetList[0].id;
                }
                if(str.substringAfter(':')!='0' && str.substringAfter(':')!='00' && str.substringBefore(':')!='')
                {
                    quoteLine.SBQQ__OptionLevel__c = Decimal.valueOf(str.substringAfter(':'));
                    quoteLine.SBQQ__OptionType__c = 'Component';
                    
                    if(level=='1' && productlevelMap.containsKey(str.substringBefore(':').replace(' ', '')+'Type'))
                    {
                        quoteLine.SBQQ__ProductOption__c = productOptionassetMap.get(productlevelMap.get(str.substringBefore(':').replace(' ', '')+'Type'));
                    }
                    else if (level=='2' && productlevelMap.containsKey(str.substringBefore(':').replace(' ', '')+'Tier'))
                    {
                        quoteLine.SBQQ__ProductOption__c = productOptionassetMap.get(productlevelMap.get(str.substringBefore(':').replace(' ', '')+'Tier'));   
                    }
                    else 
                    {
                        quoteLine.SBQQ__ProductOption__c=productOptionassetMap.get(productMap.get(str.substringBefore(':')));
                    }   
                    quoteLine.SBQQ__BundledQuantity__c=1;
                    quoteLine.SBQQ__Bundled__c=true;
                }
                
                quoteLines.add(quoteLine);
            }
            // added by neelesh 
            List<SBQQ__QuoteLine__c> quoteLineListforProduct = [select id, SBQQ__ProductCode__c 
                                                                from SBQQ__QuoteLine__c 
                                                                where SBQQ__Quote__c = :quoteRecId
                                                                AND SBQQ__ProductCode__c = 'ADM Registration Fees'
                                                                Limit 1 ];
            if (quoteLineListforProduct.isEmpty()) {
                // Query the Product2 record for 'ADM Registration Fees'
                Product2 admProduct = [SELECT Id FROM Product2 WHERE Name = 'ADM Registration Fees' LIMIT 1];
                
                PricebookEntry admPriceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :admProduct.Id AND Pricebook2.Name = 'Standard Price Book' LIMIT 1];
                Decimal admPrice = assetList[0].list_price__c * 0.02;
                
                // Create a new Quote Line and add it to the quoteLines list
                SBQQ__QuoteLine__c admQuoteLine = new SBQQ__QuoteLine__c();
                admQuoteLine.CurrencyIsoCode = 'AED';
                admQuoteLine.SBQQ__Quote__c = quoteRecId;
                admQuoteLine.SBQQ__Product__c = admProduct.Id;
                admQuoteLine.SBQQ__PricebookEntryId__c = admPriceBookEntry.Id;
                admQuoteLine.SBQQ__Quantity__c = 1;
                admQuoteLine.SBQQ__ListPrice__c= admPrice;
                admQuoteLine.SBQQ__NetPrice__c=admPrice;
                admQuoteLine.Asset__c=assetList[0].id;
                
                // Add to the existing list of quoteLines instead of inserting immediately
                quoteLines.add(admQuoteLine);
            }
            
            for (SaveQuoteLine line : request.quoteLines) {
                SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
                quoteLine.CurrencyIsoCode='AED';
                quoteLine.SBQQ__Quote__c = quoteRecId;
                quoteLine.SBQQ__Product__c = line.productId;
                if(line.color != null)
                {
                    quoteLine.color__c = line.color;     
                }
                quoteLine.SBQQ__ProductOption__c=productOptionMap.get(line.productId);
                quoteLine.SBQQ__PricebookEntryId__c = productPriceBookMap.get(line.productId);
                
                quoteProducts.add(line.productId);
                quoteLine.SBQQ__OptionLevel__c = 5;
                quoteLine.SBQQ__BundledQuantity__c=1;
                
                quoteLines.add(quoteLine);
                
            }
            //if(!Test.isRunningTest()){
            insert quoteLines;
            //   }                        
            
            Map<string,decimal> productPrice = new Map<string,decimal>();
            decimal netAmount=0;
            
            // Step 3: Query and populate the response
            SBQQ__Quote__c savedQuote = [SELECT Id, SBQQ__NetAmount__c, VAT_Value__c, SBQQ__Status__c,SBQQ__CustomerDiscount__c,Quote_Calculation_Complete__c, 
                                  
                                         Parking_Type__c, Parking_Tier__c, Project__r.name, Total_Original_List_Price__c, SBQQ__Opportunity2__c,
                                         Parking_Ref_ID__c,Parking_Group__c, Parking_Segment__c, Parking_Category__c FROM SBQQ__Quote__c WHERE Id = :quoteRecId];
            
            QuoteSaver quoteSaver = new QuoteSaver();
            QuoteModel quoteModel = new QuoteModel(); // Populate this with relevant data from newQuote
            quoteModel.record = savedQuote; // Set the ID of the newly created quote
            //  Add other properties as needed...
            QuoteModel savedQuote1 = quoteSaver.save(quoteModel);
            
            savedQuote.SBQQ__Status__c='Draft';
            savedQuote.SBQQ__Primary__c=true;
            savedQuote.Quote_Calculation_Complete__c=false;
            savedQuote.SBQQ__CustomerDiscount__c=savedQuote.SBQQ__CustomerDiscount__c;
            update savedQuote;
            
            response.id = savedQuote.id;
            response.totalQuotePrice = savedQuote.SBQQ__NetAmount__c.format();
            response.quoteStatus = savedQuote.SBQQ__Status__c;
            response.QuoteCalculationComplete=savedQuote.Quote_Calculation_Complete__c;
            response.quoteLineItems= new List<QuoteLineResponse>();
            response.RefId = savedQuote.Parking_Ref_ID__c;
            response.parkingType = savedQuote.Parking_Type__c;
            response.parkingTier = savedQuote.Parking_Tier__c;
            response.parkingGroup = savedQuote.Parking_Group__c;
            response.parkingSegment = savedQuote.Parking_Segment__c;
            response.parkingCategory = savedQuote.Parking_Category__c;
            response.originalQuotePrice = savedQuote.Total_Original_List_Price__c; 
            response.opportunityid = savedQuote.SBQQ__Opportunity2__c;
            response.listPrice = (savedQuote.SBQQ__NetAmount__c - savedQuote.VAT_Value__c);  



            
            Map<Integer, Id> optionLevelToIdMap = new Map<Integer, Id>();
            List<SBQQ__QuoteLine__c> savedQuoteLines = [SELECT Id,SBQQ__Quote__r.Project__r.name, SBQQ__Product__r.Name, SBQQ__NetPrice__c, SBQQ__ListPrice__c, SBQQ__NetTotal__c,SBQQ__OptionLevel__c,SBQQ__PricebookEntryId__c,SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteRecId];
            
            for (SBQQ__QuoteLine__c savedLine : savedQuoteLines) {
                QuoteLineResponse lineResponse = new QuoteLineResponse();
                lineResponse.id = savedLine.Id;
                lineResponse.productName = savedLine.SBQQ__Product__r.Name;
                Decimal price = productPrice.get(savedLine.SBQQ__Product__r.Name);
                lineResponse.netPrice = string.valueof(savedLine.SBQQ__NetPrice__c);
                lineResponse.listPrice = string.valueof(savedLine.SBQQ__ListPrice__c);
                lineResponse.totalPrice = string.valueof(savedLine.SBQQ__NetPrice__c);
                response.quoteLineItems.add(lineResponse);
                
                if (savedLine.SBQQ__Product__r.Name == savedLine.SBQQ__Quote__r.Project__r.name) {
                    optionLevelToIdMap.put(0, savedLine.Id);
                } else if (savedLine.SBQQ__OptionLevel__c == 1) {
                    optionLevelToIdMap.put(1, savedLine.Id);
                } else if (savedLine.SBQQ__OptionLevel__c == 2) {
                    optionLevelToIdMap.put(2, savedLine.Id);
                } else if (savedLine.SBQQ__OptionLevel__c == 3) {
                    optionLevelToIdMap.put(3, savedLine.Id);
                }   else if (savedLine.SBQQ__OptionLevel__c == 4) {
                    optionLevelToIdMap.put(4, savedLine.Id);
                }  else if (savedLine.SBQQ__OptionLevel__c == 5) {
                    optionLevelToIdMap.put(5, savedLine.Id);
                } 
                
            }
            
            for (SBQQ__QuoteLine__c ql : savedQuoteLines) {
                if (ql.SBQQ__OptionLevel__c == 5 && optionLevelToIdMap.containsKey(4)) {
                    // Update Option Level 5 with ID of Option Level 4
                    ql.SBQQ__RequiredBy__c = optionLevelToIdMap.get(4);
                }
                else if (ql.SBQQ__OptionLevel__c == 4 && optionLevelToIdMap.containsKey(3)) {
                    // Update Option Level 4 with ID of Option Level 3
                    ql.SBQQ__RequiredBy__c = optionLevelToIdMap.get(3);
                }
                else if (ql.SBQQ__OptionLevel__c == 3 && optionLevelToIdMap.containsKey(2)) {
                    // Update Option Level 3 with ID of Option Level 2
                    ql.SBQQ__RequiredBy__c = optionLevelToIdMap.get(2);
                } else if (ql.SBQQ__OptionLevel__c == 2 && optionLevelToIdMap.containsKey(1)) {
                    // Update Option Level 2 with ID of Option Level 1
                    ql.SBQQ__RequiredBy__c = optionLevelToIdMap.get(1);
                } else if (ql.SBQQ__OptionLevel__c == 1 ) {
                    // If Option Level 1 and Product is Parking, update with its own ID
                    ql.SBQQ__RequiredBy__c = optionLevelToIdMap.get(0);
                }
            }
            
            // Update the modified Quote Lines
            update savedQuoteLines;
            
        } catch (Exception e) {
            if(e.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                response.errorMessage = 'Error: The parking bay selected is not available due to a duplicate booking error. Please select another parking bay.';
            }else{
                response.errorMessage = 'Error: An error occurred. Please try again later.';
            }
        }
        DateTime start = System.Now();
        while(System.Now().getTime()< start.getTime()+10000){ }//Delay
        
        return response;
        
    }
    
    @testVisible
    private static void updateAssetStatus(String assetId, String lockedByCustomerId) {
        // Retrieve the Asset and Parent Asset in a single query
        List<Asset> assetsToUpdate = [SELECT Id, Status, In_Progress_Timestamp__c, Parent_Asset__c, LockedByUser__c, Parking_Group__c, Parent_Asset__r.Parking_Group__c 
                                      FROM Asset 
                                      WHERE Id = :assetId 
                                      LIMIT 1];
        
        // Check if the Asset exists and if the Parent Asset exists
        if (!assetsToUpdate.isEmpty()) {
            Asset assetToUpdate = assetsToUpdate[0];
            if(assetToUpdate.LockedByUser__c != null){
                return;
            }
            // List to collect assets for update
            List<Asset> updateAssets = new List<Asset>();
            
            // Always update the current Asset
            assetToUpdate.Status = 'In Progress';
            assetToUpdate.In_Progress_Timestamp__c = System.now();
            assetToUpdate.LockedByUser__c = lockedByCustomerId;
            updateAssets.add(assetToUpdate);
            
            // If Parent Asset exists, update the Parent Asset as well
            // Modified by Harsh@Aldar 12/03/2025 - Dont update Parent Assets for Singles and Tandem Singles have Parent Asset Populated
            // //removed  && assetToUpdate.Parking_Group__c == 'Double' && assetToUpdate.Parent_Asset__r.Parking_Group__c == 'Double'
            if (assetToUpdate.Parent_Asset__c != null) {
                updateAssets.add(new Asset(
                    Id = assetToUpdate.Parent_Asset__c, 
                    Status = 'In Progress', 
                    In_Progress_Timestamp__c = System.now(),
                    LockedByUser__c = lockedByCustomerId
                ));
            }
            
            // Perform the update if there are assets to update
            if (!updateAssets.isEmpty()) {
                update updateAssets;
            }
        }
    }
    
    
    global static ParkingDetails getAddOns(string customerid,string RefId) {
        
        // Fetch Quotes and their corresponding Quote Lines based on the Account ID
        String Ref= String.valueOf(RefId);
        
        List<Asset> asset = [
            SELECT id,Project__r.name,Building__r.name,Parking_Ref_ID__c,Ref_ID__c,
            Parking_Type__c,Parking_Tier__c,
            Base_Cost__c,List_Price__c,Parking_Group__c, Parking_Segment__c, Parking_Category__c from asset
            WHERE Ref_ID__c = :Ref and RecordTypeName__c='Premium_Parking'
        ];
        
        // Prepare the response with Parking and their features
        ParkingDetails parkingDetails = new ParkingDetails();
        parkingDetails.parkingId = asset[0].Id;
        parkingDetails.RefId = asset[0].Ref_ID__c;
        parkingDetails.parkingType = asset[0].Parking_Type__c;
        parkingDetails.parkingTier = asset[0].Parking_Tier__c;
        parkingDetails.parkingGroup = asset[0].Parking_Group__c;
        parkingDetails.parkingSegment = asset[0].Parking_Segment__c;
        parkingDetails.parkingCategory = asset[0].Parking_Category__c;
        if(asset[0].Parking_Category__c!=null)
        {
            parkingDetails.products = getParkingTierProducts(asset[0].Parking_Category__c,asset);    
        }    
        else if (asset[0].Parking_Segment__c!=null)
        {
            parkingDetails.products = getParkingTierProducts(asset[0].Parking_Segment__c,asset);   
        }    
        else if (asset[0].Parking_Group__c!=null)
        {
            parkingDetails.products = getParkingTierProducts(asset[0].Parking_Group__c,asset);    
        }
        else
        {   
            parkingDetails.products = getParkingTierProducts(asset[0].Parking_Tier__c,asset);
        }    
        return parkingDetails;
    }
    
    private static Map<String, List<Map<String, Object>>> getParkingTierProducts(String parkinglevel,List<Asset> asset) {
        Map<String, List<Map<String, Object>>> featureSKUs = new Map<String, List<Map<String, Object>>>();
        
        // Query to get SKUs from ProductOption based on ParkingTier
        String query = 'SELECT SBQQ__Feature__r.Name, SBQQ__OptionalSKU__r.Name, color__c ' +
            'FROM SBQQ__ProductOption__c ' +
            'WHERE SBQQ__ConfiguredSKU__r.Name = :parkinglevel';
        List<SBQQ__ProductOption__c> productOptions = Database.query(query);
        
        Map<string,Id> productNameId = new Map<string,Id>();
        for(Product2 prd : [select name,id from Product2])
        {
            productNameId.put(prd.Name,prd.Id);
        }
        
        Map<string,string> productListPriceMap = new Map<string,string>();
        for(Product_Configuraton__c  pc: [select Project__r.name,Building__r.name,
                                          Parking_Type__c,Parking_Tier__c,Parking_Group__c, Parking_Segment__c, Parking_Category__c,
                                          Product__c,List_Price__c from Product_Configuraton__c ])
        {
            productListPriceMap.put(pc.Project__r.name+':'+pc.Building__r.name+':'+pc.Parking_Type__c+':'+pc.Parking_Tier__c+':'+pc.Parking_Group__c+':'+pc.Parking_Category__c+':'+pc.Parking_Segment__c+':'+pc.Product__c,string.valueOf(pc.List_Price__c));
        }
        
        // Populate the map with feature names and corresponding SKUs and Ids
        for (SBQQ__ProductOption__c option : productOptions) {
            String featureName = option.SBQQ__Feature__r.Name;
            String aliasName = option.SBQQ__OptionalSKU__r.Name;
            String color='';
            String productId = productNameId.get(option.SBQQ__OptionalSKU__r.Name);
            
            // Initialize the feature list if not already present
            if (!featureSKUs.containsKey(featureName)) {
                featureSKUs.put(featureName, new List<Map<String, Object>>());
            }
            
            // Create a map to hold aliasName and Id
            Map<String, Object> skuDetails = new Map<String, Object>();
            
            if(featureName=='Roller Shutter Paint' && asset[0].Project__r.Name.contains('Grove'))
            {
                if (aliasName.toLowerCase().contains(asset[0].Parking_Group__c.toLowerCase()))
                {
                    
                    // Retrieve picklist values for the color__c field
                    List<String> picklistValues = new List<String>();
                    Schema.DescribeFieldResult fieldResult = SBQQ__ProductOption__c.color__c.getDescribe();
                    for (Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues()) 
                    {
                        picklistValues.add(pickListVal.getLabel());
                    }
                    
                    
                    skuDetails.put('aliasName', aliasName);
                    skuDetails.put('Id', productId);
                    skuDetails.put('listPrice', productListPriceMap.get(asset[0].Project__r.name+':'+asset[0].Building__r.name+':'+asset[0].Parking_Type__c+':'+asset[0].Parking_Tier__c+':'+asset[0].Parking_Group__c+':'+asset[0].Parking_Category__c+':'+asset[0].Parking_Segment__c+':'+productId));
                    // Add the SKU details to the corresponding feature list
                    skuDetails.put('color', picklistValues);
                }
            }
            else {
                
                
                skuDetails.put('aliasName', aliasName);
                skuDetails.put('Id', productId);
                skuDetails.put('listPrice', productListPriceMap.get(asset[0].Project__r.name+':'+asset[0].Building__r.name+':'+asset[0].Parking_Type__c+':'+asset[0].Parking_Tier__c+':'+asset[0].Parking_Group__c+':'+asset[0].Parking_Category__c+':'+asset[0].Parking_Segment__c+':'+productId));
                // Add the SKU details to the corresponding feature list
                
            }
            if (!skuDetails.isEmpty() && skuDetails.get('Id') != null) 
            {
                featureSKUs.get(featureName).add(skuDetails);
            }
        }
        
        return featureSKUs;
    }
    
    
    global static List<QuoteResponse> getQuoteandLineItems(string customerid, string quoteId, String salesOrderId) {
        
        List<SBQQ__Quote__c> quotes=new list<SBQQ__Quote__c>();
        
        if(quoteId != null){
            // Fetch Quotes and their corresponding Quote Lines based on the Account ID
            quotes = [
                SELECT Id, Name, SBQQ__NetAmount__c, SBQQ__Status__c,SBQQ__Opportunity2__c , 
                Parking_Tier__c,Parking_Type__c,Quote_Calculation_Complete__c,
                Quote_Total_Discount_Percentage__c, Total_Discount_Amount__c,Total_Original_List_Price__c,
                Parking_Ref_ID__c,Parking_Group__c, Parking_Segment__c, Parking_Category__c,VAT_Value__c, Total_Tax__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Account__c = :customerid and id=:quoteid AND RecordTypeId = :PREMPARKING_QUOTE_RECORDTYPE_ID
            ];
            //Added by Harsh@ALD 25/02/2025 - Get Quotes on basis of sales order id
        } else if(salesOrderId != null){
            // Fetch Quotes and their corresponding Quote Lines based on the Account ID
            quotes = [
                SELECT Id, Name, SBQQ__NetAmount__c, SBQQ__Status__c,SBQQ__Opportunity2__c , 
                Parking_Tier__c,Parking_Type__c,Quote_Calculation_Complete__c,
                Quote_Total_Discount_Percentage__c, Total_Discount_Amount__c,Total_Original_List_Price__c,
                Parking_Ref_ID__c,Parking_Group__c, Parking_Segment__c, Parking_Category__c,VAT_Value__c, Total_Tax__c
                FROM SBQQ__Quote__c
                WHERE Sales_Order__c =: salesOrderId AND RecordTypeId = :PREMPARKING_QUOTE_RECORDTYPE_ID
            ];
        }else{
            quotes = [
                SELECT Id, Name, SBQQ__NetAmount__c, SBQQ__Status__c,SBQQ__Opportunity2__c, 
                Parking_Tier__c,Parking_Type__c,Quote_Calculation_Complete__c,
                Quote_Total_Discount_Percentage__c, Total_Discount_Amount__c, Total_Original_List_Price__c,
                Parking_Ref_ID__c,Parking_Group__c, Parking_Segment__c, Parking_Category__c,VAT_Value__c, Total_Tax__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Account__c = :customerid AND RecordTypeId = :PREMPARKING_QUOTE_RECORDTYPE_ID
            ];
            
        }
        
        // Fetch corresponding Quote Lines for the retrieved Quotes
        Map<Id, List<QuoteLineResponse>> quoteLineMap = new Map<Id, List<QuoteLineResponse>>();
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__Quote__c, SBQQ__Product__r.Name, SBQQ__NetPrice__c, SBQQ__ListPrice__c, SBQQ__NetTotal__c, VAT__c, VAT_Value__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quotes
        ];
        
        // Group the Quote Lines by their parent Quote ID
        for (SBQQ__QuoteLine__c line : quoteLines) {
            if (!quoteLineMap.containsKey(line.SBQQ__Quote__c)) {
                quoteLineMap.put(line.SBQQ__Quote__c, new List<QuoteLineResponse>());
            }
            
            QuoteLineResponse lineResponse = new QuoteLineResponse();
            lineResponse.id = line.Id;
            lineResponse.productName = line.SBQQ__Product__r.Name;
            lineResponse.netPrice = (line.SBQQ__NetPrice__c != null) ? line.SBQQ__NetPrice__c.format() : '';
            lineResponse.listPrice = (line.SBQQ__ListPrice__c != null) ? line.SBQQ__ListPrice__c.format() : '';
            lineResponse.totalPrice = (line.SBQQ__NetTotal__c != null) ? line.SBQQ__NetTotal__c.format() : '';
            lineResponse.TaxAmount = (line.VAT_Value__c != null) ? line.VAT_Value__c : 0.0;  
            lineResponse.TaxPercent = (line.VAT__c != null) ? line.VAT__c : 0.0;  
            quoteLineMap.get(line.SBQQ__Quote__c).add(lineResponse);
        }
        
        // Prepare the response with Quotes and their Quote Lines
        List<QuoteResponse> responseList = new List<QuoteResponse>();
        for (SBQQ__Quote__c quote : quotes) {
            QuoteResponse quoteResponse = new QuoteResponse();
            quoteResponse.id = quote.Id;
            quoteResponse.opportunityid = quote.SBQQ__Opportunity2__c;
            quoteResponse.totalQuotePrice = (quote.SBQQ__NetAmount__c != null) ? quote.SBQQ__NetAmount__c.format() : '';
            quoteResponse.quoteStatus = quote.SBQQ__Status__c;
            quoteResponse.taxPercentage = quote.Total_Tax__c;
            quoteResponse.totalTaxAmount = quote.VAT_Value__c;
            quoteResponse.RefId = quote.Parking_Ref_ID__c;
            quoteResponse.totalDiscountPercent = (quote.Quote_Total_Discount_Percentage__c != null && quote.Quote_Total_Discount_Percentage__c < 0)? 0 
                : quote.Quote_Total_Discount_Percentage__c;                       
            quoteResponse.totalDiscountAmount = (quote.Total_Discount_Amount__c != null && quote.Total_Discount_Amount__c < 0)? 0 
                : quote.Total_Discount_Amount__c;
            quoteResponse.originalQuotePrice = quote.Total_Original_List_Price__c;                          //Added by Neeles End
            quoteResponse.QuoteCalculationComplete = quote.Quote_Calculation_Complete__c;
            quoteResponse.parkingType = quote.Parking_Type__c;
            quoteResponse.parkingTier = quote.Parking_Tier__c;
            quoteResponse.parkingGroup = quote.Parking_Group__c;
            quoteResponse.parkingSegment = quote.Parking_Segment__c;
            quoteResponse.parkingCategory = quote.Parking_Category__c;
            quoteResponse.listPrice = (quote.SBQQ__NetAmount__c - quote.VAT_Value__c);  
            quoteResponse.quoteLineItems = quoteLineMap.containsKey(quote.Id) ? quoteLineMap.get(quote.Id) : new List<QuoteLineResponse>();
            responseList.add(quoteResponse);
        }
        
        return responseList;
    }
    
    global static Map<String,List<Map<String,string>>> getOpportunities(string customerid,string recordType) {
        List<Opportunity> oppList = [select id from Opportunity where AccountId=:customerid and RecordType.Name=:recordType];
        
        Map<String,List<Map<String,string>>> opportunitiesList = new Map<String,List<Map<String,string>>>();
        opportunitiesList.put('opportunities', new List<Map<String,string>>());
        for(Opportunity opp : oppList)
        {
            Map<String, String> oppMap = new Map<String, String>();
            oppMap.put('Id', opp.Id);
            
            // Add the SKU details to the corresponding feature list
            opportunitiesList.get('opportunities').add(oppMap);
        }
        
        return opportunitiesList;
    }
    
    //Added by Harsh@Aldar 14/01/2025 Get document generated through nintex
    global static List<DocumentsList> generateDocument_Nintex(String customerId, String quoteId, String isPolling) {
        if(!String.isBlank(quoteId)){
            List<Document__c> documentPlaceholder = [SELECT Id FROM Document__c WHERE Quote__c =: quoteId AND DocumentType__c =: 'Premium Parking Quote Doc'];
            List<DocumentsList> returnList = new List<DocumentsList>();
            DocumentsList thisReturnDocument = new DocumentsList();
            if(documentPlaceholder.size() > 0){ 
                Document__c thisQuoteDocument = documentPlaceholder[0];
                
                // keep polling until document is generated
                if(isPolling != null && isPolling.toLowerCase() == 'true'){
                    ContentVersion content = CustomerServiceUtility.getContentVersion(thisQuoteDocument.Id);
                    
                    if (content != null && content.Id != null) {
                        thisReturnDocument.documentId = thisQuoteDocument.Id;
                        thisReturnDocument.documentName = content.Title;
                        returnList.add(thisReturnDocument);
                        return returnList;
                    } else {
                        thisReturnDocument.documentId = '';
                        thisReturnDocument.documentName = 'IN PROGRESS';
                        returnList.add(thisReturnDocument);
                        return returnList;
                    }
                }
                //If Not Polling - Generate the document
                //commented by Harsh@aldar 20/02/2025 for Static Document Check
                else if( isPolling != null && isPolling.toLowerCase() == 'false'){
                    //commented by Harsh@aldar 20/02/2025 for Static Document Check
                    /*thisQuoteDocument.GenerateDocument__c = true;
update thisQuoteDocument;

thisReturnDocument.documentId = '';
thisReturnDocument.documentName = 'IN PROGRESS';
returnList.add(thisReturnDocument);
return returnList;*/
                    //Added by Harsh@aldar 20/02/2025 for Static Document Check
                    ContentVersion content = CustomerServiceUtility.getContentVersion(thisQuoteDocument.Id);
                    
                    if (content != null && content.Id != null) {
                        thisReturnDocument.documentId = thisQuoteDocument.Id;
                        thisReturnDocument.documentName = content.Title;
                        returnList.add(thisReturnDocument);
                        return returnList;
                    }else{
                        return null;
                    }
                }else{
                    return null;
                }
            }else{
                return null;
            }
        }else{
            return null;
        }
    }
    
    //Old method used to generate document through CPQ Docgen - Remove Later - Harsh@ALD 15/01/2025
    // global static List<DocumentsList> generateDocument(string customerId, string quoteId) {
    //     List<SBQQ__Quote__c> quote = [select id,name from SBQQ__Quote__c where id=:quoteId];
    //     List<DocumentsList> responsedocList = new List<DocumentsList>();
    //     if(quote.size()>0)
    //     {
    //         QuoteProposalModel quoteProposalModel = new QuoteProposalModel();
    //         //quoteProposalModel.customerId = ;
    //         quoteProposalModel.quoteId = quoteId;
    //         quoteProposalModel.templateId = [select Id from SBQQ__QuoteTemplate__c Where Name='Aldar' LIMIT 1].id;
    //         Date currentDate = System.today();
    //         // Format the date as YYYYMMDD
    //         String formattedDate = System.Now().format('yyyyMMdd-HHmmss');
    //         string fileName = quote[0].Name+'-'+formattedDate;
    //         quoteProposalModel.name = fileName;
    //         
    //          // Simulate saving the quote proposal in tests
    //     String jobId = '';
    //     if (!Test.isRunningTest()) 
    //     {
    //         jobId = save(quoteProposalModel);  // Actual save logic only when not running tests
    //     } else 
    //     {
    //         jobId = 'mockJobId';  // Simulate job ID during tests
    //     }
    //     
    //         //AsyncDocumentProcessor asyncTask = new AsyncDocumentProcessor(fileName+'.pdf');
    //         //System.enqueueJob(asyncTask);
    //         //DocumentLog__c log = [SELECT DocumentId__c FROM DocumentLog__c limit 1];
    //         //string documentIdLogged = log.DocumentId__c;
    //         //delete log;
    //         //return documentIdLogged;
    //         //performAsyncTask(fileName+'.pdf');
    //         //return documentId;    
    
    //         //added by harsh@ALD 26/12/2024 - Logic to create Document placeholders
    //         List<Document__c> docPlaceholderList = new List<Document__c>();
    //         Id signedQuoterecordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByName().get('Activity').getRecordTypeId();
    
    
    //      //  List<DocumentsList> responsedocList = new List<DocumentsList>();
    //         //Setting a static Quote document to continue testing harsh@ALD 23/12/24 midnght - removed 26/12/2024
    //         List<SBQQ__QuoteDocument__c> quotedoc = [select id,name from SBQQ__QuoteDocument__c where SBQQ__Quote__c=:quoteId order by createddate limit 1];
    //         //List<SBQQ__QuoteDocument__c> quotedoc = [select id,name from SBQQ__QuoteDocument__c where Id = 'a6SFV0000000Jyj2AE' limit 1];
    //        for (SBQQ__QuoteDocument__c qd : quotedoc) {
    //             DocumentsList doc = new DocumentsList();
    //             doc.Quotedocid=qd.id;
    //             doc.filename=fileName+'.pdf';
    //             responsedocList.add(doc);
    //              
    
    //             docPlaceholderList.add(new Document__c(RecordTypeId = signedQuoterecordTypeId, DocumentType__c = 'Premium Parking Quote Doc Signed', Quote_Document__c = qd.id));
    //         }
    
    //         if(docPlaceholderList.size() > 0){
    //             insert docPlaceholderList;
    //         }
    
    //         //return fileName+'.pdf';
    //     }
    //      return responsedocList;
    //    // else
    //    // {
    //    //     return 'Quote Doesn\'t exist';
    //    // }
    // }
    
    public static String save(QuoteProposalModel context) {
        return SBQQ.ServiceRouter.save('SBQQ.QuoteDocumentAPI.Save', JSON.serialize(context));
    }
    
    @future
    public static void performAsyncTask(string documentName) {
        // Logic to execute asynchronously based on the document name
        // Add business logic here
        //Document doc = [select id from Document where name = :documentName ];
        //documentId = doc.id;
        //AsyncDocumentProcessor asyncTask = new AsyncDocumentProcessor(documentName);
        //System.enqueueJob(asyncTask);
        
    }
    
    //Added by Harsh@ALD 15/01/2025 getOrderDetails
    global static Map<String,List<Map<String,string>>> getOrderDetails(String quoteId) {
        List<Order> thisOrderList = [SELECT Id,Amount_In_Progress__c, Amount_Outstanding__c, Amount_Received__c, TotalAmount
                                     FROM Order
                                     WHERE SBQQ__Quote__c =: quoteId
                                     AND RecordTypeId = :PARKING_RECORDTYPE_ID];
        
        Map<String,List<Map<String,string>>> orderList = new Map<String,List<Map<String,string>>>();
        orderList.put('Order', new List<Map<String,string>>());
        for(Order thisOrder : thisOrderList){
            Map<String, String> orderMap = new Map<String, String>();
            orderMap.put('Id', thisOrder.Id);
            orderMap.put('AmountTotal', String.valueOf(thisOrder.TotalAmount));
            orderMap.put('AmountOutstanding', String.valueOf(thisOrder.Amount_Outstanding__c));
            orderMap.put('AmountReceived', String.valueOf(thisOrder.Amount_Received__c));
            orderMap.put('AmountInProgress', String.valueOf(thisOrder.Amount_In_Progress__c));
            
            // Add the SKU details to the corresponding feature list
            orderList.get('Order').add(orderMap);
        }
        return orderList;
    }
    
    global class QuoteProposalModel {
        //public string customerId;
        public string quoteId;
        public string templateId = '';
        public string name ='';
    }
    
    global class ResponseWrapper {
        public Map<String, List<String>> featureSKUs;
        public QuoteDetails quoteDetails;
        public String errorMessage;
        public List<PropertiesList> propertiesList;
        public List<PremiumInvList> premiumInvList;
        public LeadResponse leadResponse;
    }
    
    global class QuoteDetails {
        public List<SBQQ__QuoteLine__c> quoteLineItems;
        public Decimal grandTotal;
    }
    
    global class PropertiesList {
        public string community;
        public string projectName;
        public string projectId;
        public string buildingName;
        public string buildingId;
        
    }
    
    global class DocumentsList {
        public string documentId;
        public string documentName;
        
    }
    
    global class PremiumInvList {
        public String communityName;
        public String projectName;
        public string building;
        public List<ParkingDetail> parkingSlots; // List of ParkingDetail
        
        public PremiumInvList(String communityName, String projectName, String building, List<ParkingDetail> parkingSlots) {
            this.communityName = communityName;
            this.projectName = projectName;
            this.building = building;
            this.parkingSlots = parkingSlots;
        }
    }
    
    global class ParkingDetail {
        public String parkingRefId;
        public String RefId;
        public String id;
        public String distanceFromLobby;
        public Decimal capacity;
        public String parkingType;
        public String parkingTier;
        public String parkingGroup;
        public String parkingSegment;
        public String parkingCategory;
        public Decimal listprice;
        public string productId;
        public string status;
        public string parentassetid;
    }
    
    global Class LeadInput {
        public String FirstName;
        public String LastName;
        public String Email;
        public String MobileNumber1;
        public String MobileCountryCode;
        public String CountryOfResidence;
        public String Nationality;
        public String LeadOrigin;
        public String Project;
        public String State;
        public String Country;
        public String PropertyUsage;
        public String CustomerLocation;
        public String SalesType;
        public String LeadSource;
        public String EnquiryCategory;
        public String EnquiryTrigger;
        public String SalesOrigin;
        public String ResidentStatus;
        public String Lead_Type;
        public String LeadSubType;
        public String SalesOrderId;
        
        
    }
    global class LeadResponse {
        public String message;
        public Boolean success;
        public Id leadId;
        public Id opportunityId;
        public Id accountId;
    }
    
    global class SaveQuoteRequest {
        public String opportunityId;
        public string quoteId;
        public String customerId;
        public string RefId;
        public List<SaveQuoteLine> quoteLines;
    }
    
    global class SaveQuoteLine {
        //public String quotelineid;
        public String productId;
        public String color;
    }
    
    global class QuoteWrapper {
        public SBQQ__Quote__c quoteDetails;
        public List<SBQQ__QuoteLine__c> quoteLineItems;
        public String errorMessage;
    }
    
    global class QuoteResponse {
        public string id;
        public string opportunityid;
        public string totalQuotePrice;
        public string quoteStatus;
        public Decimal totalTaxAmount;
        public Decimal taxPercentage;
        public Decimal listPrice;
        public boolean QuoteCalculationComplete;
        public string RefId;
        public Decimal totalDiscountPercent;                                                         //Added By Neelesh start
        public Decimal totalDiscountAmount;
        public Decimal originalQuotePrice;                                                          //Added By Neelesh End
        public string parkingType;
        public string parkingTier;
        public String parkingGroup;
        public String parkingSegment;
        public String parkingCategory;
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
    }
    
    global class ParkingDetails {
        public Id parkingId;
        public String RefId; 
        public string parkingtype;
        public string parkingtier;
        public string parkingGroup;
        public string parkingSegment;
        public string parkingCategory;
        //public string listPrice;
        public Map<String, List<Map<String, Object>>> products;
    }
    
    global class ProductFeatures {
        public Id productId;
        public string aliasName;
        
    }
    //Added by Harsh@Aldar 28/11/2024 Payments API
    global class PaymentDetails {
        public Decimal amount;  // Paid Amount (Full Amount)
        public String salesOrder;  // Sales Order ID
        public String opportunityId;  // Opportunity ID related to the quote
        public String accountId;  // Account ID
        public String remarks;  // Any remarks for the payment
        public String referenceNumber;  // Generated from CyberSource
        public Date paymentDate;  // Date of payment
        public String currencyIsoCode;  // Currency used for payment
        public String bankAccountNumber;
        public String bankName;
        public String orderId;
        //Added by Harsh@Aldar 24/02/2025
        public String quoteId;
    }
    //Added by Harsh@Aldar 28/11/2024 Payments API
    global class PaymentResponse {
        public String message;
        public Boolean success;
        public Decimal amountPaid;
        public Id receiptId;
        public String receiptNumber;
        public MerchantDetails merchantDetails;
        
    }
    
    global class MerchantDetails{
        public String apiKey;
        public String secretKey;
        public String profileId;
        public String transactionId;
        public String referenceNumber;
    }
    
    //Added by Harsh@Adar 27/02/2025 - Get CTA API Response Wrapper
    global class CTAResponseWrapper{
        public List<ParkingOrder> parkingOrder{get;set;}
        public Boolean isEligible{get;set;}
        public String maxParkingForCustomer{get;set;}
        public Boolean maxParkingLimitHit{get;set;}
        public String projectName{get;set;}
        public String buildingName{get;set;}
    }
    global class ParkingOrder{
        public String parkingRefId{get;set;}
        public String customerId{get;set;}
        public String quoteId{get;set;}
        public String parkingBayNumber{get;set;}
        public String orderId{get;set;}
        public String opportunityId{get;set;}
        public String amountInProgress{get;set;}
        public String salesOrderId{get;set;}
        public String amountReceived{get;set;}
        public String amountOutstanding{get;set;}
        public String amountTotal{get;set;}
        public String orderStatus{get;set;}
        public String dueDate{get;set;}
    }
}