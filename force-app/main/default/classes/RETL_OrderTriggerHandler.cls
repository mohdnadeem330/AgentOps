public with sharing class RETL_OrderTriggerHandler {

    public static void handleAfter(List<Order> newOrders, Map<Id, Order> oldMap) {
        if (newOrders == null || newOrders.isEmpty()) return;

        // 1. Orders where FNTC changed from false → true
        Set<Id> releasedOrderIds = new Set<Id>();

        for (Order o : newOrders) {
            Boolean newFlag = o.RETL_FNTC_Released__c == true;
            Boolean oldFlag = (oldMap != null && oldMap.containsKey(o.Id) && oldMap.get(o.Id).RETL_FNTC_Released__c == true);

            if (newFlag && !oldFlag) {
                releasedOrderIds.add(o.Id);
            }
        }

        if (releasedOrderIds.isEmpty()) return;

        // 2. Fetch Orders with Opportunity__c
        List<Order> orders = [
            SELECT Id, OpportunityId 
            FROM Order
            WHERE Id IN :releasedOrderIds
        ];

        Set<Id> oppIds = new Set<Id>();
        for (Order o : orders) {
            if (o.OpportunityId  != null) oppIds.add(o.OpportunityId );
        }

        if (oppIds.isEmpty()) return;

        // 3. Fetch Opportunities
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [
                SELECT Id, RETL_Handover_Date__c
                FROM Opportunity
                WHERE Id IN :oppIds
            ]
        );

        // 4. Fetch Service Requests linked by Order__c OR Opportunity__c
        List<RETL_Service_Request__c> srs = [
            SELECT Id, RETL_Order__c, RETL_Opportunity_Id__c
            FROM RETL_Service_Request__c
            WHERE RETL_Order__c IN :releasedOrderIds OR RETL_Opportunity_Id__c IN :oppIds
        ];

        Map<Id, RETL_Service_Request__c> srByOrder = new Map<Id, RETL_Service_Request__c>();
        Map<Id, RETL_Service_Request__c> srByOpp = new Map<Id, RETL_Service_Request__c>();

        for (RETL_Service_Request__c sr : srs) {
            if (sr.RETL_Order__c != null) srByOrder.put(sr.RETL_Order__c, sr);
            if (sr.RETL_Opportunity_Id__c != null) srByOpp.put(sr.RETL_Opportunity_Id__c, sr);
        }

        // 5. Determine which SRs to activate (handover <= 7 days)
        Set<Id> srIdsToActivate = new Set<Id>();
        Date today = Date.today();
        Date sevenDaysFromNow = today.addDays(7);

        for (Order o : orders) {
            Opportunity opp = oppMap.get(o.OpportunityId);

            if (opp == null || opp.RETL_Handover_Date__c == null) continue;

            // If handover is today or within next 7 days
            if (opp.RETL_Handover_Date__c <= sevenDaysFromNow && opp.RETL_Handover_Date__c >= today) {

                RETL_Service_Request__c sr = srByOrder.get(o.Id);
                if (sr == null) sr = srByOpp.get(o.OpportunityId);

                if (sr != null) srIdsToActivate.add(sr.Id);
            }
        }

        
    }
}