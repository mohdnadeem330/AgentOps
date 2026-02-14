public with sharing class RETL_HandoverService {

    /* =========================================================
       PUBLIC ENTRY POINTS (INTENT BASED)
       ========================================================= */

    /**
     * Called from:
     * - Order Trigger
     * - Opportunity Trigger
     * - Flow / Workflow
     */
    public static void process(Set<Id> serviceRequestIds) {
        execute(serviceRequestIds, ExecutionMode.REAL_TIME);
    }

    /**
     * Called ONLY from Scheduler
     */
    public static void scheduleHandover() {
        execute(fetchServiceRequestsForSchedule(), ExecutionMode.SCHEDULED);
    }

    /* =========================================================
       INTERNAL EXECUTION MODE
       ========================================================= */
    private enum ExecutionMode {
        REAL_TIME,
        SCHEDULED
    }

    /* =========================================================
       CORE EXECUTION
       ========================================================= */
    private static void execute(Set<Id> srIds, ExecutionMode mode) {

        if (srIds == null || srIds.isEmpty()) return;

        // 1. Fetch Service Requests
        Map<Id, RETL_Service_Request__c> srMap = new Map<Id, RETL_Service_Request__c>(
            [
                SELECT Id,
                       RETL_Order__c,
                       RETL_Handover_15_Email__c,
                       RETL_Handover_7_Email__c,
                       RETL_Skip_Contractual_Validation__c
                FROM RETL_Service_Request__c
                WHERE Id IN :srIds
            ]
        );
        
        System.debug('srMap:::' + srMap);

        //2. Collect Order IDs
        Set<Id> orderIds = new Set<Id>();
        for (RETL_Service_Request__c sr : srMap.values()) {
            if (sr.RETL_Order__c != null) {
                orderIds.add(sr.RETL_Order__c);
            }
        }
		System.debug('orderIds:::' + orderIds);
        if (orderIds.isEmpty()) return;

        // 3 Fetch Orders
        Map<Id, Order> orderMap = new Map<Id, Order>(
            [
                SELECT Id,
                       RETL_MoveInDate__c,
                       RETL_FNTC_Released__c
                FROM Order
                WHERE Id IN :orderIds
                AND RecordType.DeveloperName = 'Retail_lease'
            ]
        );
		System.debug('orderMap:::' + orderMap);
        // 4️ Apply business rules
        applyRules(srMap, orderMap, mode);
    }

    /* =========================================================
       RULE ENGINE
       ========================================================= */
    private static void applyRules(
        Map<Id, RETL_Service_Request__c> srMap,
        Map<Id, Order> orderMap,
        ExecutionMode mode
    ) {

        Date today = Date.today();

        List<RETL_Service_Request__c> srUpdates = new List<RETL_Service_Request__c>();
        Set<Id> srToActivate = new Set<Id>();
		
        for (RETL_Service_Request__c sr : srMap.values()) {

            Order ord = orderMap.get(sr.RETL_Order__c);
            if (ord == null || ord.RETL_MoveInDate__c == null) continue;

            Integer daysBefore = today.daysBetween(ord.RETL_MoveInDate__c);
			
            /* -----------------------------------------
               REAL-TIME (Triggers / Flow / Workflow)
               ----------------------------------------- */
            if (mode == ExecutionMode.REAL_TIME) {

                if (ord.RETL_FNTC_Released__c &&
                    daysBefore >= 0 &&
                    daysBefore <= 7) {

                    srToActivate.add(sr.Id);
                }
                continue;
            }

            /* -----------------------------------------
               SCHEDULED (Daily job)
               ----------------------------------------- */
            if (mode == ExecutionMode.SCHEDULED) { 
                // --- 15 Days ---
                if (daysBefore == 15 &&
                    !ord.RETL_FNTC_Released__c &&
                    !sr.RETL_Handover_15_Email__c) {

                    sr.RETL_Handover_15_Email__c = true;
                    sr.RETL_Skip_Contractual_Validation__c = true;
                    srUpdates.add(sr);
                } 
                // --- 7 Days ---
                if (daysBefore == 7) {

                    if (ord.RETL_FNTC_Released__c) {
                        srToActivate.add(sr.Id);
                    }
                    else if (!sr.RETL_Handover_7_Email__c) {
                        sr.RETL_Handover_7_Email__c = true;
                        sr.RETL_Skip_Contractual_Validation__c = true;
                        srUpdates.add(sr);
                    }
                }
            }
        }

        if (!srUpdates.isEmpty()) {
            update srUpdates;
        }

        if (!srToActivate.isEmpty()) {
            activateHandoverStage(srToActivate);
        }
    }

    /* =========================================================
       STAGE ACTIVATION
       ========================================================= */
    private static void activateHandoverStage(Set<Id> serviceRequestIds) {

        List<RETL_Stage__c> stages = [
            SELECT Id,
                   Status__c,
                   Start_Date__c
            FROM RETL_Stage__c
            WHERE RETL_Service_RequestId__c IN :serviceRequestIds
            AND RETL_Stage_Developer_Name__c = 'Unit_Handover'
        ];

        if (stages.isEmpty()) return;

        Date today = Date.today();
        List<RETL_Stage__c> updates = new List<RETL_Stage__c>();

        for (RETL_Stage__c st : stages) {
            if (st.Status__c != 'In-Progress') {
                st.Status__c = 'In-Progress';
                st.Start_Date__c = today;
                updates.add(st);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    /* =========================================================
       SCHEDULE QUERY
       ========================================================= */
    private static Set<Id> fetchServiceRequestsForSchedule() {

        Date today = Date.today();
        Set<Date> dates = new Set<Date>{
            today.addDays(15),
            today.addDays(7)
        };
		
        Set<Id> srIds = new Set<Id>();
System.debug('fetchServiceRequestsForSchedule::');
        for (RETL_Service_Request__c sr : [
            SELECT Id
            FROM RETL_Service_Request__c
            WHERE RETL_Order__r.RETL_MoveInDate__c IN :dates
        ]) {
            srIds.add(sr.Id);
        } 
		 
        return srIds;
    }
    
    public static void handleWorkFlowRequestUnitHandoverStage(List<Order> newList, Map<Id, Sobject> oldMap) { 
        if (newList == null || newList.isEmpty()) return;
		System.debug('newListnewListnewList:::' + newList);
        // 1️. Collect Orders where FNTC Released changed → TRUE
        Set<Id> orderIds = new Set<Id>();
		Order oldOrder;
        Boolean newFlag;
         Boolean oldFlag;
        Set<Id> recordTypeIds = new Set<Id>();
        for (Order o : newList) {
            if (o.RecordTypeId != null) {
                recordTypeIds.add(o.RecordTypeId);
            }
        }

        Map<Id, RecordType> rtMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE Id IN :recordTypeIds]
        );
		 
        for (Order ord : newList) {
			System.debug('ord:::' + ord);
            // Only Retail Lease Orders

            // if (ord.RecordTypeId == null || ord.RecordType.DeveloperName != 'Retail_lease') { //Either query order again to fetch just recordType.Name or DeveloperName or use this map.
            //     continue;
            // } 
            if (!rtMap.containsKey(ord.RecordTypeId) && rtMap.get(ord.RecordTypeId).DeveloperName != 'Retail_lease'){
                continue;
            } 
			oldOrder = (Order) oldMap.get(ord.Id); 
            newFlag = ord.RETL_FNTC_Released__c;
            oldFlag = oldOrder != null &&
                              oldOrder.RETL_FNTC_Released__c;
			System.debug('newFlag:::' + newFlag + ' :: ' + oldFlag);             
            Boolean isMoveInDateChanged = oldOrder != null && ord.RETL_MoveInDate__c != oldOrder.RETL_MoveInDate__c;
            // Detect false → true
            if ((newFlag && !oldFlag) || isMoveInDateChanged) {
                orderIds.add(ord.Id);
            }
        }

        if (orderIds.isEmpty()) return;

        // 2️. Fetch related Service Requests
        Set<Id> serviceRequestIds = new Set<Id>();

        for (RETL_Service_Request__c sr : [
            SELECT Id
            FROM RETL_Service_Request__c
            WHERE RETL_Order__c IN :orderIds
        ]) {
            serviceRequestIds.add(sr.Id);
        }

        if (serviceRequestIds.isEmpty()) return;
		System.debug('serviceRequestIds:::' + serviceRequestIds);
        // 3️. Delegate to Handover Service
        RETL_HandoverService.process(serviceRequestIds);
    }
}