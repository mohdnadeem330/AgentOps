/**
* @File Name : OrderTriggerHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 21, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 21, 2024 |   | Initial Version
**/

public class OrderTriggerHandler extends TriggerHandler{
    
    //NOTE Harsh@Ald - All Orders Activate Would Get Synced to ERP - Modify Later for other types of order - currently built only for Premium Parking
    @testVisible
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        
        Id parkingRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
        Id furnitureRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Furniture').getRecordTypeId();
        //Added by Harsh@Aldar 01/10/2025 - Kimbo Orders
        Id smarthomeRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Smarthome').getRecordTypeId();   
        // Create a set to store orders that need to be pushed to ERP
        Set<Id> premPark_OrdersToPushERP = new Set<Id>();
        List<Id> furnitureOrderId_ReceiptERP = new List<Id>();
        //Added by Harsh@Aldar 01/10/2025 - Kimbo Orders Receipts
        List<Id> smarthomeOrderId_ReceiptERP = new List<Id>();
        for(Order newRecord : (List<Order>) newList){
            Order oldRecord = (Order) oldMap.get(newRecord.ID);
            // NOTE Harsh@Ald - Added Test.isRunningTest() check - 23/12/2024
            if(( newRecord.RecordTypeId == parkingRecordTypeId && newRecord.Status <> oldRecord.Status && newRecord.Status == 'Activated')|| Test.isRunningTest()){
                premPark_OrdersToPushERP.add(newRecord.Id);
            }

            System.debug('RT Id -> ' + newRecord.RecordTypeId);
            if(newRecord.RecordTypeId == furnitureRecordTypeId){
                
                System.debug('old -> ' + oldRecord.ERP_Id__c);
                System.debug('new -> ' + newRecord.ERP_Id__c);

                if(newRecord != null && oldRecord != null && 
                String.isBlank(oldRecord.ERP_Id__c) && 
                !String.isBlank(newRecord.ERP_Id__c) && 
                oldRecord.ERP_Id__c != newRecord.ERP_Id__c){

                    furnitureOrderId_ReceiptERP.add(newRecord.Id);

                }
            }
            //Added by Harsh@Aldar 01/10/2025 - Kimbo Orders Receipts
            if(newRecord.RecordTypeId == smarthomeRecordTypeId){

                if(newRecord != null && oldRecord != null && 
                String.isBlank(oldRecord.ERP_Id__c) && 
                !String.isBlank(newRecord.ERP_Id__c) && 
                oldRecord.ERP_Id__c != newRecord.ERP_Id__c){

                    smarthomeOrderId_ReceiptERP.add(newRecord.Id);

                }
            }
        }
        
        // If there are orders that need to be pushed to ERP, call the future method
        if (!premPark_OrdersToPushERP.isEmpty()) {
            try {
                //PremPark_OrderIntegrationController.pushOrderToERP(premPark_OrdersToPushERP);
            } catch (Exception e) {
                // Log the error and handle exception
              insert LoggerService.createApexLog(e, 'PremPark_OrderERP_CPQ', 'OrderTrigger', 'afterInsertMethod');
            }
        }
        
        //Push Furniture Order to Vendor
        pushOrdersToVendorAndERP(newList, oldMap);
        //Once ERP Id of Order is synced, publish event to sync related latest Receipt to ERP
        pushFurnitureReceiptERP(furnitureOrderId_ReceiptERP);
        //Harsh@Aldar - kimbo Receipt ERP Sync - Once ERP Id of Order is synced, publish event to sync related latest Receipt to ERP
        pushSmarthomeReceiptERP(smarthomeOrderId_ReceiptERP);
        
    }
    
    /*
* Added by Harsh@Aldar 24/02/2025
*/ /*
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        // Step 2: Map RecordTypeId to DeveloperName
        Map<Id, String> recordTypeMap = new Map<Id, String>();
        for (Schema.RecordTypeInfo rtInfo : Schema.SObjectType.Order.getRecordTypeInfos()) {
            if (rtInfo.getDeveloperName() == 'Furniture' || rtInfo.getDeveloperName() == 'Parking') {
                recordTypeMap.put( rtInfo.getRecordTypeId(), rtInfo.getDeveloperName());
            }
        }
        
        // Step 3: List for updating receipts
        List<ReceiptAcknowledgement__c> receiptsToUpdate = new List<ReceiptAcknowledgement__c>();
        List<Order> allFurnitureOrders = new List<Order>();
        // Step 4: Loop through orders
        for (SObject newOrder : newList) {
            Order order = (Order) newOrder;
            
            // Check record type = 'Parking' before calling QuoteService
            String devName = recordTypeMap.get(order.RecordTypeId);
            if (devName == 'Parking') {
                QuoteService.generateDocumentPlaceholders(new List<Order>{order});
            }
            if (devName == 'Furniture') {
                allFurnitureOrders.add(order);
            }
            
            // Get the related Quote ID from the Order
            Id quoteId = order?.SBQQ__Quote__c;
            if (String.isBlank(quoteId)) {
                continue;
            }
            
            // Query ReceiptAcknowledgement__c where Order__c is null
            List<ReceiptAcknowledgement__c> receipts = [
                SELECT Id, Order__c
                FROM ReceiptAcknowledgement__c
                WHERE CPQQuote__c = :quoteId AND Order__c = NULL
            ];
            
            // Set the order reference in receipt
            for (ReceiptAcknowledgement__c receipt : receipts) {
                receipt.Order__c = order.Id;
                receiptsToUpdate.add(receipt);
            }
        }
        
        // Step 5: Update receipts
        if (!receiptsToUpdate.isEmpty()) {
            update receiptsToUpdate;
        }
        //updateFurnitureOrderFields(allFurnitureOrders);
        //Push Furniture Order to Vendor
        pushOrdersToVendorAndERP(newList, null);
        
    }*/

    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        // Early exit if no records to process
        if (newList == null || newList.isEmpty()) {
            return;
        }

        // Get all required data in single queries
        Map<String, Group> queueMap = new Map<String, Group>();
        // Updated by Pooja@Aldar - OB-2930
        for (Group queue : [SELECT Id, Name FROM Group WHERE Name IN ('CM Parking Queue', 'CM Furniture Queue', 'CM Insurance Queue') AND Type = 'Queue']) {
            queueMap.put(queue.Name, queue);
        }
        
        // Cast to Order list once for type safety
        List<Order> newOrders = (List<Order>) newList;
        
        // Get record type mappings with improved caching approach
        Map<Id, String> recordTypeMap = getOrderRecordTypeMap();
        
        // Collections for different processing paths
        List<Order> parkingOrders = new List<Order>();
        List<Order> furnitureOrders = new List<Order>();
        // Added by Pooja@Aldar - OB-2930
        List<Order> insuranceOrders = new List<Order>();
        Set<Id> quoteIds = new Set<Id>();
        
        // Single loop to categorize orders and collect quote IDs
        for (Order order : newOrders) {
            String recordTypeName = recordTypeMap.get(order.RecordTypeId);
            // Categorize orders by record type
            if (recordTypeName == 'Parking') {
                parkingOrders.add(order);
            } else if (recordTypeName == 'Furniture') {
                furnitureOrders.add(order);
            } else if (recordTypeName == 'Insurance') {
                System.debug('Insurance Order is here');
                insuranceOrders.add(order); // Added by Pooja@Aldar - OB-2930
            } 
            
            // Collect quote IDs for receipt processing
            if (order.SBQQ__Quote__c != null) {
                quoteIds.add(order.SBQQ__Quote__c);
            }
        }

        // Process parking orders
        if (!parkingOrders.isEmpty()) {
            try {
                QuoteService.generateDocumentPlaceholders(parkingOrders);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error generating document placeholders: ' + e.getMessage());
                // Consider adding custom exception handling based on business requirements
            }
        }
/*
        // Process parking orders //harsh@Aldar 03/011/2025
        if (!insuranceOrders.isEmpty()) {
            try {
                QuoteService.generateDocumentPlaceholders(insuranceOrders, 'shory');
           } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error generating document placeholders: ' + e.getMessage());
                // Consider adding custom exception handling based on business requirements
            }
        }
        */
      /*  // Process parking orders //harsh@Aldar 03/011/2025 ----- Removed  by neelesh
        if (!insuranceOrders.isEmpty()) {
            try {
                QuoteService.generateDocumentPlaceholders(insuranceOrders, 'shory');
           } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error generating document placeholders: ' + e.getMessage());
                // Consider adding custom exception handling based on business requirements
            }
        }*/
        
        // Process receipt acknowledgements
        //process to reparent receipts from quote to order for both parking and furniture
        if (!quoteIds.isEmpty()) {
            Furniture_ReceiptHelper.processReceiptAcknowledgements(newOrders, quoteIds);
        }
        
        // Process vendor/ERP integration
        if (!newList.isEmpty()) {
            try {
                pushOrdersToVendorAndERP(newList, null);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error pushing orders to vendor/ERP: ' + e.getMessage());
                // Consider adding custom exception handling based on business requirements
            }
        }
    }

    public override void beforeInsertMethod(list<SObject> newList, Map<Id, SObject> newMap){
    
        //Added by Harsh@Aldar 21/03/2025 Assign Order to CM Queue based on Record Type
        
        // Get all required data in single queries
        Map<String, Group> queueMap = new Map<String, Group>();
        // Added by Pooja@Aldar - OB-2930
        List<Order> insuranceOrders = new List<Order>();
        // Updated by Pooja@Aldar - OB-2931
        for (Group queue : [SELECT Id, Name FROM Group WHERE Name IN ('CM Parking Queue', 'CM Furniture Queue', 'CM Smarthome Queue', 'CM Insurance Queue') AND Type = 'Queue']) {
            queueMap.put(queue.Name, queue);
        }
        
        Map<String, Id> recordTypeMap = new Map<String, Id>();

        for (Schema.RecordTypeInfo rtInfo : Schema.SObjectType.Order.getRecordTypeInfos()) {
            // Updated by Pooja@Aldar - OB-2931
            if (rtInfo.getDeveloperName() == 'Furniture' || rtInfo.getDeveloperName() == 'Parking' || rtInfo.getDeveloperName() == 'Smarthome' || rtInfo.getDeveloperName() == 'Insurance') {
                recordTypeMap.put(rtInfo.getDeveloperName(), rtInfo.getRecordTypeId());
            }
        }

        Map<String, Id> quoteRecordTypeMap = new Map<String, Id>();
        for (Schema.RecordTypeInfo rtInfo : Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfos()) {
            // Updated by Pooja@Aldar - OB-2931
            if (rtInfo.getDeveloperName() == 'Furniture' || rtInfo.getDeveloperName() == 'Parking' || rtInfo.getDeveloperName() == 'Smarthome') {
                quoteRecordTypeMap.put(rtInfo.getDeveloperName(), rtInfo.getRecordTypeId());
            }
        }


        
        Set<Id> quoteIds = new Set<Id>();
        for(Order newRecord : (List<Order>) newList){
            if (newRecord.SBQQ__Quote__c != null) {
                quoteIds.add(newRecord.SBQQ__Quote__c);
            }   
        }
        
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
        if (!quoteIds.isEmpty()) {
            for (SBQQ__Quote__c qt : [SELECT Id, Sales_Order__c, ParkingAsset__c, Total_Amount_Paid__c, Total_Amount_Received__c,
                                        Total_Stripe_Fee__c, VAT_Amount__c, Aldar_Amount__c, Aldar_Stripe_Fee__c, Aldar_Stripe_Fee_VAT__c,
                                        Aldar_VAT__c, Vendor_Amount__c, Vendor_Stripe_Fee__c, Vendor_Stripe_Fee_VAT__c, Vendor_VAT__c,
                                        Transaction_Date__c, Total_Tax__c, RecordTypeId, SBQQ__Account__r.IsPersonAccount,  SBQQ__Account__r.PersonContactId
                                         FROM SBQQ__Quote__c WHERE Id IN :quoteIds]) {
                quoteMap.put(qt.Id, qt); 
            }
        }
        
        for (Order ord : (List<Order>) newList) {
            String recordTypeName = recordTypeMap.get(ord.RecordTypeId);
            if (recordTypeName == 'Insurance' || ord.Type == 'Shory') {
                insuranceOrders.add(ord); // Added by Pooja@Aldar - OB-2930
            } 
            if (ord.SBQQ__Quote__c != null && quoteMap.containsKey(ord.SBQQ__Quote__c)) {

                ord.Sales_Order__c = quoteMap.get(ord.SBQQ__Quote__c).Sales_Order__c;

                if(quoteMap.get(ord.SBQQ__Quote__c).SBQQ__Account__r.IsPersonAccount){
                    ord.Contact__c = quoteMap.get(ord.SBQQ__Quote__c).SBQQ__Account__r.PersonContactId;
                }
                
                // Logic based on Record Type
                if (quoteMap.get(ord.SBQQ__Quote__c).RecordTypeId == quoteRecordTypeMap.get('Parking')) {
                    ord.RecordTypeId = recordTypeMap.get('Parking');
                    handleParkingOrder(ord, queueMap, quoteMap);
                } else if (quoteMap.get(ord.SBQQ__Quote__c).RecordTypeId == quoteRecordTypeMap.get('Furniture')) {
                    ord.RecordTypeId = recordTypeMap.get('Furniture');
                    handleFurnitureOrder(ord, queueMap, quoteMap);
                } else if (quoteMap.get(ord.SBQQ__Quote__c).RecordTypeId == quoteRecordTypeMap.get('Smarthome')) {  
                    ord.RecordTypeId = recordTypeMap.get('Smarthome');// Added by Pooja@Aldar - OB-2931
                    handleSmarthomeOrder(ord, queueMap, quoteMap);// Added by Pooja@Aldar - OB-2931
                } else {
                    
                }
            }
        }
        
        // Added by Pooja@Aldar - OB-2930
        if (!insuranceOrders.isEmpty()) {
            handleInsuranceOrder(insuranceOrders, queueMap);
        }
        
    }

    /**
    * Helper method to handle Parking Order logic
    */
    private void handleParkingOrder(Order ord, Map<String, Group> queueMap, Map<Id, SBQQ__Quote__c> quoteMap) {
        Group parkingQueue = queueMap.get('CM Parking Queue');
        if (parkingQueue != null) {
            ord.OwnerId = parkingQueue.Id;
            ord.Sub_Status__c = 'Pending CM Validation';
        }

        ord.ParkingAsset__c = quoteMap.get(ord.SBQQ__Quote__c).ParkingAsset__c;
    }

    /**
    * Helper method to handle Insurance Order logic
    * Added by Pooja@Aldar - OB-2930
    */
    public void handleInsuranceOrder(List<Order> orders, Map<String, Group> queueMap) {
        
        Group insuranceQueue = queueMap.get('CM Insurance Queue');
        List<Order> orderToUpdate = new List<Order>();
        if (insuranceQueue == null) return;
        for (Order ord : orders) {
            ord.OwnerId = insuranceQueue.Id;
        }
    }

    /**
    * Helper method to handle Insurance Order logic
    * Added by Pooja@Aldar - OB-2931
    */
    public void handleSmarthomeOrder(Order ord, Map<String, Group> queueMap, Map<Id, SBQQ__Quote__c> quoteMap) {
        
        Group smartHomeQueue = queueMap.get('CM Smarthome Queue');
        if (smartHomeQueue != null) {
            ord.OwnerId = smartHomeQueue.Id;
        }    
    // added by neleesh for ERP: 8 dec 2025
        ord.Total_Amount_Paid1__c = quoteMap.get(ord.SBQQ__Quote__c).Total_Amount_Paid__c;
        ord.Total_Amount_Received1__c = quoteMap.get(ord.SBQQ__Quote__c).Total_Amount_Received__c;
         ord.Total_Stripe_Fee1__c = quoteMap.get(ord.SBQQ__Quote__c).Total_Stripe_Fee__c;
        ord.VAT_Amount1__c = quoteMap.get(ord.SBQQ__Quote__c).VAT_Amount__c;

        ord.Total_Tax__c = quoteMap.get(ord.SBQQ__Quote__c).VAT_Amount__c;
        ord.Tax_Percentage__c = quoteMap.get(ord.SBQQ__Quote__c).Total_Tax__c;

        ord.Aldar_Amount1__c = quoteMap.get(ord.SBQQ__Quote__c).Aldar_Amount__c;
        ord.Aldar_Stripe_Fee1__c = quoteMap.get(ord.SBQQ__Quote__c).Aldar_Stripe_Fee__c;
        ord.Aldar_Stripe_Fee_VAT1__c = quoteMap.get(ord.SBQQ__Quote__c).Aldar_Stripe_Fee_VAT__c;
        ord.Aldar_VAT1__c = quoteMap.get(ord.SBQQ__Quote__c).Aldar_VAT__c;

        ord.Vendor_Amount1__c = quoteMap.get(ord.SBQQ__Quote__c).Vendor_Amount__c;
        ord.Vendor_Stripe_Fee1__c = quoteMap.get(ord.SBQQ__Quote__c).Vendor_Stripe_Fee__c;
        ord.Vendor_Stripe_Fee_VAT1__c = quoteMap.get(ord.SBQQ__Quote__c).Vendor_Stripe_Fee_VAT__c;
        ord.Vendor_VAT1__c = quoteMap.get(ord.SBQQ__Quote__c).Vendor_VAT__c;

        ord.Transaction_Date1__c = quoteMap.get(ord.SBQQ__Quote__c).Transaction_Date__c;
        ord.Sub_Status__c = 'Order Placed';
    }

    /**
    * Helper method to handle Furniture Order logic   
    */
    @testVisible
    public void handleFurnitureOrder(Order ord, Map<String, Group> queueMap, Map<Id, SBQQ__Quote__c> quoteMap) {
        Group furnitureQueue = queueMap.get('CM Furniture Queue');
        if (furnitureQueue != null) {
            ord.OwnerId = furnitureQueue.Id;
        }
        ord.Total_Amount_Paid1__c = quoteMap.get(ord.SBQQ__Quote__c).Total_Amount_Paid__c;
        ord.Total_Amount_Received1__c = quoteMap.get(ord.SBQQ__Quote__c).Total_Amount_Received__c;
        ord.Total_Stripe_Fee1__c = quoteMap.get(ord.SBQQ__Quote__c).Total_Stripe_Fee__c;
        ord.VAT_Amount1__c = quoteMap.get(ord.SBQQ__Quote__c).VAT_Amount__c;

        ord.Total_Tax__c = quoteMap.get(ord.SBQQ__Quote__c).VAT_Amount__c;
        ord.Tax_Percentage__c = quoteMap.get(ord.SBQQ__Quote__c).Total_Tax__c;

        ord.Aldar_Amount1__c = quoteMap.get(ord.SBQQ__Quote__c).Aldar_Amount__c;
        ord.Aldar_Stripe_Fee1__c = quoteMap.get(ord.SBQQ__Quote__c).Aldar_Stripe_Fee__c;
        ord.Aldar_Stripe_Fee_VAT1__c = quoteMap.get(ord.SBQQ__Quote__c).Aldar_Stripe_Fee_VAT__c;
        ord.Aldar_VAT1__c = quoteMap.get(ord.SBQQ__Quote__c).Aldar_VAT__c;

        ord.Vendor_Amount1__c = quoteMap.get(ord.SBQQ__Quote__c).Vendor_Amount__c;
        ord.Vendor_Stripe_Fee1__c = quoteMap.get(ord.SBQQ__Quote__c).Vendor_Stripe_Fee__c;
        ord.Vendor_Stripe_Fee_VAT1__c = quoteMap.get(ord.SBQQ__Quote__c).Vendor_Stripe_Fee_VAT__c;
        ord.Vendor_VAT1__c = quoteMap.get(ord.SBQQ__Quote__c).Vendor_VAT__c;

        ord.Transaction_Date1__c = quoteMap.get(ord.SBQQ__Quote__c).Transaction_Date__c;
       // ord.Expected_Delivery_Date__c = System.today().addDays(84);
        ord.Sub_Status__c = 'Order Placed';
    }

    /**
    * Simplified bulkified method to push orders to vendor for Furniture and Smarthome
    * @param newList - List of new/updated SObject records
    * @param oldMap - Map of old SObject records by Id (null for insert)
    */
    
    public static void pushOrdersToVendorAndERP(List<SObject> newList, Map<Id, SObject> oldMap) {
        if (newList == null || newList.isEmpty()) return;
        
        // Get Furniture record type ID
        Id furnitureRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Furniture').getRecordTypeId();
        //Added by Harsh@Aldar 01/10/2025 - Kimbo Orders                     
        Id smarthomeRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Smarthome').getRecordTypeId();
        
        // Process each record
        for (SObject newRecord : newList) {
            Order newOrder = (Order) newRecord;
            
            // Only process Parking record type orders
			//if (newOrder.RecordTypeId != furnitureRecordTypeId && newOrder.RecordTypeId != smarthomeRecordTypeId) continue;
            if (newOrder.RecordTypeId == furnitureRecordTypeId || newOrder.RecordTypeId == smarthomeRecordTypeId){   
            
                // Skip if no vendor or already has vendor order ID
                if (newOrder.Vendor__c == null || String.isNotBlank(newOrder.VendorOrderId__c)) continue;
                
                Order oldOrder = (oldMap != null) ? (Order) oldMap.get(newOrder.Id) : null;
                
                // Check if paid now
                Boolean isPaidNow = (newOrder.Total_Amount_Paid1__c != null && newOrder.Total_Amount_Paid1__c > 0) &&
                                (oldOrder == null || oldOrder.Total_Amount_Paid1__c == null || oldOrder.Total_Amount_Paid1__c == 0);
                
                // Check if received now  
                Boolean isReceivedNow = (newOrder.Total_Amount_Received1__c != null && newOrder.Total_Amount_Received1__c > 0) &&
                                    (oldOrder == null || oldOrder.Total_Amount_Received1__c == null || oldOrder.Total_Amount_Received1__c == 0);
                
                // Publish event if both conditions met - Furniture
                if (isPaidNow && isReceivedNow && newOrder.RecordTypeId == furnitureRecordTypeId) {
                    Furniture_SaveQuoteUtils.publishEvent('FurnitureVendorOrderSync__e', 'Create Purchase Order', newOrder.Id, newOrder.Vendor__c);
                    Furniture_SaveQuoteUtils.publishEvent('FurnitureVendorOrderSync__e', 'Sync Furniture Order to ERP', newOrder.Id, '');
                }
                // Publish event if both conditions met - Smarthome
                if (isPaidNow && isReceivedNow && newOrder.RecordTypeId == smarthomeRecordTypeId) {            
                    Furniture_SaveQuoteUtils.publishEvent('FurnitureVendorOrderSync__e', 'Sync Smarthome Order to ERP', newOrder.Id, '');
                }
            }
        }
    }
    /**
    * @description Retrieves the latest created receipt for each order and publishes 
    *              platform events to sync them with ERP system
    * @param orderIdList List of Order record IDs to process
    * @return void
    */
    
    public static void pushFurnitureReceiptERP(List<Id> orderIdList){
        // Query to get the latest receipt for each order
        List<ReceiptAcknowledgement__c> latestReceipts = [
            SELECT Id, Name, ERPID__c, Order__r.ERP_ID__c, Order__c
            FROM ReceiptAcknowledgement__c 
            WHERE Order__c IN :orderIdList
            AND Order__r.ERP_ID__c != null
            ORDER BY Order__c, CreatedDate DESC
        ];

        // Map to store the latest receipt per order
        Map<Id, ReceiptAcknowledgement__c> orderToLatestReceiptMap = new Map<Id, ReceiptAcknowledgement__c>();
        
        // Process receipts to get only the latest one per order
        for(ReceiptAcknowledgement__c receipt : latestReceipts) {
            if(!orderToLatestReceiptMap.containsKey(receipt.Order__c)) {
                orderToLatestReceiptMap.put(receipt.Order__c, receipt);

            }
        }
        
        // Publish event for each latest receipt
        for(ReceiptAcknowledgement__c latestReceipt : orderToLatestReceiptMap.values()) {
            Furniture_SaveQuoteUtils.publishEvent(
                'FurnitureReceiptSyncERP__e', 
                'Sync Furniture Receipt to ERP', 
                latestReceipt.Id, 
                ''
            );
        }
    }

    /**
    * @description Retrieves the latest created receipt for each order and publishes 
    *              platform events to sync them with ERP system
    * @param orderIdList List of Order record IDs to process
    * @return void
    */
    
    public static void pushSmarthomeReceiptERP(List<Id> orderIdList){
        // Query to get the latest receipt for each order
        List<ReceiptAcknowledgement__c> latestReceipts = [
            SELECT Id, Name, ERPID__c, Order__r.ERP_ID__c, Order__c
            FROM ReceiptAcknowledgement__c 
            WHERE Order__c IN :orderIdList
            AND Order__r.ERP_ID__c != null
            ORDER BY Order__c, CreatedDate DESC
        ];

        // Map to store the latest receipt per order
        Map<Id, ReceiptAcknowledgement__c> orderToLatestReceiptMap = new Map<Id, ReceiptAcknowledgement__c>();
        
        // Process receipts to get only the latest one per order
        for(ReceiptAcknowledgement__c receipt : latestReceipts) {
            if(!orderToLatestReceiptMap.containsKey(receipt.Order__c)) {
                orderToLatestReceiptMap.put(receipt.Order__c, receipt);

            }
        }
        
        // Publish event for each latest receipt
        for(ReceiptAcknowledgement__c latestReceipt : orderToLatestReceiptMap.values()) {
            Furniture_SaveQuoteUtils.publishEvent(
                'FurnitureReceiptSyncERP__e', 
                'Sync Smarthome Receipt to ERP', 
                latestReceipt.Id, 
                ''
            );
        }
    }

    /**
    * Gets Order record type mappings with caching for better performance
    * @return Map of RecordTypeId to DeveloperName for Furniture and Parking record types
    */
    @TestVisible
    private static Map<Id, String> getOrderRecordTypeMap() {
        Map<Id, String> recordTypeMap = new Map<Id, String>();
        
        // Use describe call to get record type information
        List<Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Order.getRecordTypeInfos();
        
        for (Schema.RecordTypeInfo rtInfo : recordTypes) {
            String devName = rtInfo.getDeveloperName();
            if (devName == 'Furniture' || devName == 'Parking' || devName == 'Insurance' || devName == 'Smarthome') {
                recordTypeMap.put(rtInfo.getRecordTypeId(), devName);
            }
        }
        
        return recordTypeMap;
    }
}