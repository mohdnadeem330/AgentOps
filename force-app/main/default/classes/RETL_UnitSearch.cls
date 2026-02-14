/**
 * RETL_UnitSearch
 * -------------------
 * Contains server-side logic for retrieving retail units, creating products & OLIs,
 * syncing with Yardi API, and providing Utility endpoints for LWC.
 *
 * Key functions:
 *  • searchRetailUnits — supports filtered & paginated unit search
 *  • createProductsForUnits — creates Product2, PBEs, and OLIs dynamically
 *  • refreshUnitAvailability — calls MuleSoft/Yardi API to refresh unit availability
 *  • getOpportunitiesForUnits — returns opportunities tied to given Yardi unit IDs
 *  • getPicklistValues & getAllProperties — support dropdowns in LWC
 * 
 * 
 * @author vkotaprolu@aldar.com
 * @date 2025-10-24
 */
public with sharing class RETL_UnitSearch {


    // ================================
    //      SIMPLE UTILITY METHODS
    // ================================

    /**
     * Returns the number of Opportunity Line Items related to the given Opportunity.
     * Used by LWC to know how many rows have been added.
     */
    @AuraEnabled(cacheable=true)
    public static Integer getLineItemCount(Id opportunityId) {
        return [
            SELECT Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ].size();
    }

    // =====================================================
    //                 UNIT SEARCH LOGIC
    // =====================================================

    /**
     * Searches Retail_Unit__c records based on filters (building, property, type, status, area)
     * and returns a List<Map<String,Object>> formatted for LWC table display.
     *
     * Features:
     *   • Dynamic SOQL query building
     *   • Pagination (LIMIT/OFFSET)
     *   • Calculates rent / service charge based on amount type
     *   • Determines if a unit is already added to an Opportunity
     */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> searchRetailUnits(
        String building, 
        String property,
        List<String> statuses,
        List<String> types,
        Integer pageSize,
        Integer offsetValue,
        Decimal minArea,
        Decimal maxArea,
        Id currentOpportunityId
    ) {
       String baseQuery =
                        'SELECT Id, Name, Unit_Name_Formula__c, Building__c, Property_Name__c, Unit_Area__c, ' +
                        'Expiry_Date__c, Expires_In_Days__c, Unit_Code__c, Unit_Location__c, Unit_Status__c, ' +
                        'Unit_Type__c, UnitID_External_ID__c, Tenant_Name__c, Floor__c, ' +
                        'Amount_Type__c, Effective_Date__c, Net_Marketing_Budget__c, Net_Service_Charge_Budget__c, ' +
                        'Fitout_Contribution_Amount__c, Rent_Budget__c, Rent_Free_Amount__c,Unit_Nature__c,Actual_Rent__c,Actual_Marketing_Budget__c,Actual_Service_Charge__c,Actual_FOC_Amount__c ' +
                        'FROM Retail_Unit__c';


        List<String> conditions = new List<String>();
        if (String.isNotBlank(building)) {
            conditions.add('Building__c LIKE \'%' + String.escapeSingleQuotes(building) + '%\'');
        }
        if (String.isNotBlank(property)) {
            conditions.add('Property_Name__c = \'' + String.escapeSingleQuotes(property) + '\'');
        }
        if (statuses != null && !statuses.isEmpty()) {
            List<String> escaped = new List<String>();
            for (String s : statuses) escaped.add('\'' + String.escapeSingleQuotes(s) + '\'');
            conditions.add('Unit_Status__c IN (' + String.join(escaped, ',') + ')');
        }
        if (types != null && !types.isEmpty()) {
            List<String> escaped = new List<String>();
            for (String t : types) escaped.add('\'' + String.escapeSingleQuotes(t) + '\'');
            conditions.add('Unit_Type__c IN (' + String.join(escaped, ',') + ')');
        }
        if (minArea != null) {
            conditions.add('Unit_Area__c >= ' + minArea);
        }
        if (maxArea != null) {
            conditions.add('Unit_Area__c <= ' + maxArea);
        }

        String query = baseQuery;
        if (!conditions.isEmpty()) query += ' WHERE ' + String.join(conditions, ' AND ');
        query += ' ORDER BY Expires_In_Days__c ASC, Property_Name__c ASC, Name ASC ';
        if (pageSize != null) query += ' LIMIT ' + pageSize;

        List<Retail_Unit__c> units = Database.query(query);

        // Prepare the set of yardiIds from returned units
        Set<String> yardiIds = new Set<String>();
        for (Retail_Unit__c u : units) {
            if (u.UnitID_External_ID__c != null) yardiIds.add(u.UnitID_External_ID__c);
        }

        // Map to indicate which yardiId is already present on the current opportunity
        Set<String> alreadyOnOpp = new Set<String>();
        if (currentOpportunityId != null && !yardiIds.isEmpty()) {
            // Find Product2 records with these Yardi IDs
            Map<Id, String> prodIdToYardi = new Map<Id, String>();
            for (Product2 p : [SELECT Id, RETL_Yardi_Id__c FROM Product2 WHERE RETL_Yardi_Id__c IN :yardiIds]) {
                prodIdToYardi.put(p.Id, p.RETL_Yardi_Id__c);
            }

            if (!prodIdToYardi.isEmpty()) {
                // Check OLI for this opportunity only
                for (OpportunityLineItem oli : [
                    SELECT Id, Product2Id 
                    FROM OpportunityLineItem
                    WHERE OpportunityId = :currentOpportunityId
                    AND Product2Id IN :prodIdToYardi.keySet()
                ]) {
                    String yid = prodIdToYardi.get(oli.Product2Id);
                    if (yid != null) alreadyOnOpp.add(yid);
                }
            }
        }

        // Build List<Map<String,Object>> to return to LWC (each map is a row)
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Retail_Unit__c u : units) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', u.Id);
            row.put('Name', u.Name);
            row.put('Unit_Name_Formula__c', u.Unit_Name_Formula__c);
            row.put('UnitID_External_ID__c', u.UnitID_External_ID__c);
            row.put('Building__c', u.Building__c);
            row.put('Property_Name__c', u.Property_Name__c);
            row.put('Unit_Area__c', u.Unit_Area__c);
            row.put('Unit_Type__c', u.Unit_Type__c);
            row.put('Unit_Status__c', u.Unit_Status__c);
            row.put('Expiry_Date__c', u.Expiry_Date__c);
            row.put('Unit_Location__c', u.Unit_Location__c);
            row.put('Unit_Code__c', u.Unit_Code__c);
            row.put('Expires_In_Days__c', u.Expires_In_Days__c);
            row.put('Tenant_Name__c', u.Tenant_Name__c);
            row.put('Floor__c', u.Floor__c);
            row.put('Amount_Type__c',u.Amount_Type__c);
            row.put('Effective_Date__c',u.Effective_Date__c);
            row.put('Net_Marketing_Budget__c' ,u.Net_Marketing_Budget__c);
            row.put('Rent_Free_Amount__c',u.Rent_Free_Amount__c);
            row.put('Fitout_Contribution_Amount__c',u.Fitout_Contribution_Amount__c);
            row.put('Unit_Nature__c',u.Unit_Nature__c);
            row.put('Actual_Rent__c',u.Actual_Rent__c);
            row.put('Actual_Service_Charge__c',u.Actual_Service_Charge__c);
            row.put('Actual_Marketing_Budget__c',u.Actual_Marketing_Budget__c);
            row.put('Actual_FOC_Amount__c', u.Actual_FOC_Amount__c);
            
            
            Decimal rentBudget = u.Rent_Budget__c != null ? u.Rent_Budget__c : 0;
            Decimal unitArea = u.Unit_Area__c != null ? u.Unit_Area__c : 0;
            Decimal serviceCharge = u.Net_Service_Charge_Budget__c != null ? u.Net_Service_Charge_Budget__c : 0;

            // Perform the calculation safely
            if (u.Amount_Type__c == 'Flat Amount') {
                row.put('Rent_Budget__c', rentBudget);
                row.put('Net_Service_Charge_Budget__c' ,serviceCharge);
            } else {
                row.put('Rent_Budget__c', rentBudget * unitArea);
                row.put('Net_Service_Charge_Budget__c' ,serviceCharge * unitArea);
            }

            // boolean flag
            Boolean already = (u.UnitID_External_ID__c != null && alreadyOnOpp.contains(u.UnitID_External_ID__c));
            row.put('alreadyAdded', already);
            // small label to show in table
            row.put('alreadyAddedLabel', already ? 'Already added' : '');
            rows.add(row);
        }

        return rows;
    }

     // ============================================
    //           WRAPPERS AND DATA MODELS
    // ============================================

    /**
     * Wrapper used by LWC when adding multiple units to an Opportunity.
     * Holds pricing, service charge, rent free amount, etc.
     */
    public class UnitWrapper {
        @AuraEnabled public Id unitId { get; set; }
        @AuraEnabled public Decimal price { get; set; }
        @AuraEnabled public Decimal quantity { get; set; } 
        @AuraEnabled public Decimal marketingAmount {get;set;}
        @AuraEnabled public Decimal serviceCharge {get;set;}
        @AuraEnabled public Decimal rentFreeAmount {get;set;}
        @AuraEnabled public Decimal fitoutContributionAmount {get;set;}
    }


     // ==================================================================================
    //            PRODUCT / PRICEBOOK / Opportunity Line CREATION LOGIC
    // ==================================================================================

    /**
     * Creates Product2, PricebookEntry, and OpportunityLineItem records
     * based on selected retail units and user-provided pricing values.
     *
     * Steps:
     *   1. Update Opportunity fields
     *   2. Ensure Product2 records exist (one per retail unit)
     *   3. Ensure PricebookEntry exists in Standard & Retail PB
     *   4. Add OLI for each selected unit
     *   5. Return Product2 Ids for UI refresh
     */

    @AuraEnabled
    public static List<Id> createProductsForUnits(List<UnitWrapper> unitWrappers, Map<String, Object> opportunityFields,Id opportunityId) {
        System.debug('Received wrappers: ' + unitWrappers);
        
        if(unitWrappers == null || unitWrappers.isEmpty() || opportunityId == null) {
            throw new AuraHandledException('Units and Opportunity Id must be provided.');
        }

        // 1. UPDATE OPPORTUNITY RECORD
        Opportunity oppToUpdate = new Opportunity(Id = opportunityId);
            if (opportunityFields != null) {
            if (opportunityFields.containsKey('RETL_Handover_Conditions__c')) {
                oppToUpdate.RETL_Handover_Conditions__c = (String)opportunityFields.get('RETL_Handover_Conditions__c');
            }

            // Assuming RETL_Fitout_Days__c is a Number field
            if (opportunityFields.containsKey('RETL_Fitout_Days__c')) {                
                oppToUpdate.RETL_Fitout_Days__c = integer.valueof(opportunityFields.get('RETL_Fitout_Days__c'));               
            }
            // Assuming Description is a Text field
            if (opportunityFields.containsKey('Description')) {
                oppToUpdate.Description = (String)opportunityFields.get('Description');
            }

            /* if (opportunityFields.containsKey('RETL_Desired_Rent__c')) {
                oppToUpdate.RETL_Desired_Rent__c = Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Desired_Rent__c')));
            }

            if (opportunityFields.containsKey('RETL_Desired_Area__c')) {
                oppToUpdate.RETL_Desired_Area__c = Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Desired_Area__c')));
            } */

            if (opportunityFields.containsKey('RETL_Deposit_Amount__c')) {
                oppToUpdate.RETL_Deposit_Amount__c = Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Deposit_Amount__c')));
            }

            if (opportunityFields.containsKey('RETL_TOR__c')) {
                oppToUpdate.RETL_TOR__c = Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_TOR__c')));
            }

            if (opportunityFields.containsKey('RETL_Escalation__c')) {
                oppToUpdate.RETL_Escalation__c = Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Escalation__c')));
            }

            if (opportunityFields.containsKey('RETL_Configure_By__c')) {
                oppToUpdate.RETL_Configure_By__c = (String)opportunityFields.get('RETL_Configure_By__c');
            }
            

            if (opportunityFields.containsKey('Start_date__c')) {
                Object moveInDateValue = opportunityFields.get('Start_date__c');
                if (moveInDateValue != null && String.valueOf(moveInDateValue) != '') {
                    oppToUpdate.Start_date__c = Date.valueOf(String.valueOf(moveInDateValue));
                }
            }

            // ---------------- New Fields ----------------
            if (opportunityFields.containsKey('RETL_Deposit_Notes__c')) {
                oppToUpdate.RETL_Deposit_Notes__c = (String)opportunityFields.get('RETL_Deposit_Notes__c');
            }

            if (opportunityFields.containsKey('RETL_TOR_Notes__c')) {
                oppToUpdate.RETL_TOR_Notes__c = (String)opportunityFields.get('RETL_TOR_Notes__c');
            }

            if (opportunityFields.containsKey('RETL_Special_Conditions__c')) {
                oppToUpdate.RETL_Special_Conditions__c = (String)opportunityFields.get('RETL_Special_Conditions__c');
            }

            if (opportunityFields.containsKey('RETL_FOC_Information__c')) {
                oppToUpdate.RETL_FOC_Information__c = (String)opportunityFields.get('RETL_FOC_Information__c');
            }

            if (opportunityFields.containsKey('RETL_Term_Start_Date__c')) {
                Object termStart = opportunityFields.get('RETL_Term_Start_Date__c');
                if (termStart != null && String.valueOf(termStart) != '') {
                    oppToUpdate.RETL_Term_Start_Date__c = Date.valueOf(String.valueOf(termStart));
                }
            }

            if (opportunityFields.containsKey('RETL_Term_End_Date__c')) {
                Object termEnd = opportunityFields.get('RETL_Term_End_Date__c');
                if (termEnd != null && String.valueOf(termEnd) != '') {
                    oppToUpdate.RETL_Term_End_Date__c = Date.valueOf(String.valueOf(termEnd));
                }
            }

            if (opportunityFields.containsKey('RETL_Fitout_Type__c')) {
                oppToUpdate.RETL_Fitout_Type__c = (String)opportunityFields.get('RETL_Fitout_Type__c');
            }

            if (opportunityFields.containsKey('RETL_Month_Month__c')) {
                Object monthToMonthVal = opportunityFields.get('RETL_Month_Month__c');
                if (monthToMonthVal != null) {
                    oppToUpdate.RETL_Month_Month__c = (Boolean)monthToMonthVal;
                }
            }

            if (opportunityFields.containsKey('RETL_Term__c')) {
                Object termValue = opportunityFields.get('RETL_Term__c');
                if (termValue != null && String.valueOf(termValue) != '') {
                    oppToUpdate.RETL_Term__c = Integer.valueOf(String.valueOf(termValue));
                }
            }

            if (opportunityFields.containsKey('RETL_General_Notes__c')) {
                oppToUpdate.RETL_General_Notes__c = (String)opportunityFields.get('RETL_General_Notes__c');
            }

            if (opportunityFields.containsKey('RETL_Permitted_Usage__c')) {
                oppToUpdate.RETL_Permitted_Usage__c = (String)opportunityFields.get('RETL_Permitted_Usage__c');
            }            

            if (opportunityFields.containsKey('RETL_Lease_Nature__c')) {
                oppToUpdate.RETL_Lease_Nature__c = (String)opportunityFields.get('RETL_Lease_Nature__c');
            }

            if (opportunityFields.containsKey('RETL_Total_Base_Rent__c')) {
                oppToUpdate.RETL_Total_Base_Rent__c =
                    Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Total_Base_Rent__c')));
            }

            if (opportunityFields.containsKey('RETL_Total_Rent_Free_Amount__c')) {
                oppToUpdate.RETL_Total_Rent_Free_Amount__c =
                    Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Total_Rent_Free_Amount__c')));
            }

            if (opportunityFields.containsKey('RETL_Total_FOC_Amount__c')) {
                oppToUpdate.RETL_Total_FOC_Amount__c =
                    Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Total_FOC_Amount__c')));
            }

            

            if (opportunityFields.containsKey('RETL_Total_Marketing_Amount__c')) {
                oppToUpdate.RETL_Total_Marketing_Amount__c =
                    Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Total_Marketing_Amount__c')));
            }

            if (opportunityFields.containsKey('RETL_Total_Service_Charge__c')) {
                oppToUpdate.RETL_Total_Service_Charge__c =
                    Decimal.valueOf(String.valueOf(opportunityFields.get('RETL_Total_Service_Charge__c')));
            }
            /* if (opportunityFields.containsKey('RETL_AM_PreApproval__c')) {
                oppToUpdate.RETL_AM_PreApproval__c = 
                String.valueOf(opportunityFields.get('RETL_AM_PreApproval__c'));
                if( String.valueOf(opportunityFields.get('RETL_AM_PreApproval__c')) =='Pending Approval' ){
                    oppToUpdate.StageName = 'Pending AM Approval';
                }
            } */

            if (opportunityFields.containsKey('RETL_Billing_Frequency__c')) {
                oppToUpdate.RETL_Billing_Frequency__c = (String)opportunityFields.get('RETL_Billing_Frequency__c');
            }

            if (opportunityFields.containsKey('RETL_AM_PreApproval_Notes__c')) {
                oppToUpdate.RETL_AM_PreApproval_Notes__c = (String)opportunityFields.get('RETL_AM_PreApproval_Notes__c');
            }            

        }
        
        // Perform the DML on the Opportunity record
        if (oppToUpdate.getPopulatedFieldsAsMap().size() > 1) { // Check if any fields other than Id were set
            update oppToUpdate;
        }

       // Extract Ids from wrappers
        Set<Id> unitIds = new Set<Id>();
        for (UnitWrapper uw : unitWrappers) {
            unitIds.add(uw.unitId);
        }

        // Query Retail Units
        Map<Id, Retail_Unit__c> retailUnitMap = new Map<Id, Retail_Unit__c>(
            [SELECT Id, Unit_Code__c, Unit_Name_Formula__c, UnitID_External_ID__c,Property_Code__c
            FROM Retail_Unit__c
            WHERE Id IN :unitIds]
        );

        // Collect all Unit Codes from the queried Retail_Unit__c records
        Set<String> unitCodes = new Set<String>();
        for (Retail_Unit__c ru : retailUnitMap.values()) {
            if (String.isNotBlank(ru.Unit_Code__c)) {
                unitCodes.add(ru.Unit_Code__c.trim());
            }
        }
        
        for (Retail_Unit__c ru : retailUnitMap.values()) {
            if (String.isNotBlank(ru.Unit_Code__c)) unitCodes.add(ru.Unit_Code__c.trim());
        }

        // Fetch existing products by ProductCode (Unit_Code__c)
        Map<String, Product2> productMapByCode = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, Name, ProductCode, RETL_Yardi_Id__c 
                        FROM Product2 
                        WHERE ProductCode IN :unitCodes]) {
            productMapByCode.put(p.ProductCode.trim(), p);
        }

        // Create missing Products
        List<Product2> productsToUpsert = new List<Product2>();
        for (Retail_Unit__c ru : retailUnitMap.values()) {
            if (!productMapByCode.containsKey(ru.Unit_Code__c)) {
                productsToUpsert.add(new Product2(
                    RETL_Yardi_Id__c = ru.UnitID_External_ID__c,
                    Name = ru.Unit_Name_Formula__c,
                    ProductCode = ru.Unit_Code__c,
                    IsActive = true
                ));
            }
        }
        if (!productsToUpsert.isEmpty()) {
            upsert productsToUpsert RETL_Yardi_Id__c;
        }

        // Refresh product map
        productMapByCode.clear();
        for (Product2 p : [SELECT Id, Name, ProductCode, RETL_Yardi_Id__c 
                        FROM Product2 
                        WHERE ProductCode IN :unitCodes]) {
            productMapByCode.put(p.ProductCode.trim(), p);
        }

        // Get Retail Pricebook
        Pricebook2 retailPB = [SELECT Id FROM Pricebook2 WHERE Name = 'Retail Price Book' AND IsActive = true LIMIT 1];
        if (retailPB == null) {
            throw new AuraHandledException('Retail Price Book not found or inactive.');
        }

        /* // Get Standard Pricebook
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (standardPB == null) {
            throw new AuraHandledException('Standard Price Book not found or inactive.');
        } */

        // Original: Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        List<Pricebook2> standardPBList = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        Pricebook2 standardPB;
        if (standardPBList.isEmpty()) {
            // Since the Standard Pricebook should ALWAYS exist in non-test orgs, 
            // we throw an error if it's missing (unless it's test context where we can forgive the query and use the known ID).
            if (Test.isRunningTest()) {
                // Fallback in test mode: use the Id guaranteed by the testing framework
                standardPB = new Pricebook2(Id = Test.getStandardPricebookId());
            } else {
                throw new AuraHandledException('Standard Price Book not found or inactive.');
            }
        } else {
            standardPB = standardPBList[0];
        }

        // Ensure Standard Pricebook Entries exist
        Set<Id> productIds = new Set<Id>();
        for (Product2 p : productMapByCode.values()) productIds.add(p.Id);

        Set<Id> existingStdPBEProductIds = new Map<Id, PricebookEntry>([
            SELECT Product2Id FROM PricebookEntry
            WHERE Pricebook2Id = :standardPB.Id
            AND Product2Id IN :productIds
        ]).keySet();

        List<PricebookEntry> stdPBEsToInsert = new List<PricebookEntry>();
        for (Product2 p : productMapByCode.values()) {
            if (!existingStdPBEProductIds.contains(p.Id)) {
                stdPBEsToInsert.add(new PricebookEntry(
                    Pricebook2Id = standardPB.Id,
                    Product2Id = p.Id,
                    UnitPrice = 0,
                    IsActive = true,
                    RETL_External_ID__c = standardPB.Id + '-' + p.RETL_Yardi_Id__c
                ));
            }
        }
        if (!stdPBEsToInsert.isEmpty()) upsert stdPBEsToInsert RETL_External_ID__c;

        // Ensure Retail Pricebook Entries exist
        Map<String, PricebookEntry> existingRetailPBEs = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : [SELECT Id, Product2Id, RETL_External_ID__c 
                                FROM PricebookEntry 
                                WHERE Pricebook2Id = :retailPB.Id
                                AND Product2Id IN :productIds]) {
            existingRetailPBEs.put(pbe.RETL_External_ID__c, pbe);
        }

        List<PricebookEntry> retailPBEsToInsert = new List<PricebookEntry>();
        for (Product2 p : productMapByCode.values()) {
            String key = retailPB.Id + '-' + p.Id;
            if (!existingRetailPBEs.containsKey(key)) {
                retailPBEsToInsert.add(new PricebookEntry(
                    Pricebook2Id = retailPB.Id,
                    Product2Id = p.Id,
                    UnitPrice = 0,
                    IsActive = true,
                    RETL_External_ID__c = key
                ));
            }
        }
        if (!retailPBEsToInsert.isEmpty()) insert retailPBEsToInsert;

        // Build Retail PBE map
        Map<Id, PricebookEntry> retailPBEMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [SELECT Id, Product2Id 
                                FROM PricebookEntry 
                                WHERE Pricebook2Id = :retailPB.Id 
                                AND Product2Id IN :productIds]) {
            retailPBEMap.put(pbe.Product2Id, pbe);
        }
        System.debug('unitWrappers received: ' + JSON.serialize(unitWrappers));

        // Create Opportunity Line Items using wrapper fields
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for (UnitWrapper uw : unitWrappers) {
            Retail_Unit__c ru = retailUnitMap.get(uw.unitId);
            if (ru != null) {
                Product2 prod = productMapByCode.get(ru.Unit_Code__c);
                if (prod != null) {
                    PricebookEntry pbe = retailPBEMap.get(prod.Id);
                    if (pbe != null) {
                        oliList.add(new OpportunityLineItem(
                            OpportunityId = opportunityId,
                            PricebookEntryId = pbe.Id,
                            Quantity = uw.quantity != null ? uw.quantity : 1,
                            UnitPrice = uw.price,
                            RETL_Marketing_Amount__c = uw.marketingAmount,
                            RETL_Service_Charge__c = uw.serviceCharge,
                            RETL_Rent_Free_Amount__c = uw.rentFreeAmount,                            
                            RETL_Fitout_Contribution_Amount__c = uw.fitoutContributionAmount,                            
                            RETL_Selected_Unit__c = ru.id,
                            RETL_Unit_Id__c = uw.unitId,
                            RETL_Unit_Code__c = ru.Unit_Code__c                
                        ));
                    }
                }
            }
        }

        if (!oliList.isEmpty()) {
            insert oliList;
            //RETL_LeadSyncToYardi.pushToYardiAsync(opportunityId,TRUE);
        }

        // Update the AM Approval status, which will trigger the the approval process and lock the Opportunity record
        if (opportunityFields.containsKey('RETL_AM_PreApproval__c')) {
            oppToUpdate.RETL_AM_PreApproval__c = String.valueOf(opportunityFields.get('RETL_AM_PreApproval__c'));
            if( String.valueOf(opportunityFields.get('RETL_AM_PreApproval__c')) =='Pending Approval' ){
                oppToUpdate.StageName = 'Pending AM Approval';
            }
            update oppToUpdate;
        }
        
        // Return Product2 Ids
        List<Id> productIdsToReturn = new List<Id>();
        for (Product2 p : productMapByCode.values()) productIdsToReturn.add(p.Id);
        return productIdsToReturn;
    }


    // ===========================================================
    //       GET LINKED OPPORTUNITIES FOR GIVEN UNIT (YARDI)
    // ===========================================================

    /**
     * Given a list of Yardi Unit IDs, returns all related Opportunities
     * by traversing Product2 → OpportunityLineItem → Opportunity.
     */
   @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getOpportunitiesForUnits(List<String> yardiIds) {
        Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>>();
        system.debug('-->'+yardiIds);
        if (yardiIds == null || yardiIds.isEmpty()) {
            return result;
        }

        // Get all Product2s linked to these Yardi Ids
        Map<Id, String> productIdToYardiMap = new Map<Id, String>();
        for (Product2 p : [
            SELECT Id, RETL_Yardi_Id__c
            FROM Product2
            WHERE RETL_Yardi_Id__c IN :yardiIds
        ]) {
            if (p.RETL_Yardi_Id__c != null)
                productIdToYardiMap.put(p.Id, p.RETL_Yardi_Id__c);
        }

        if (productIdToYardiMap.isEmpty()) {
            return result;
        }

        // Get all Opportunities linked via OpportunityLineItem
        for (OpportunityLineItem oli : [
            SELECT Opportunity.Id,
                Opportunity.Name,
                Opportunity.StageName,
                Opportunity.Owner.Name,
                Product2Id
            FROM OpportunityLineItem
            WHERE Product2Id IN :productIdToYardiMap.keySet()
        ]) {
            String yardiId = productIdToYardiMap.get(oli.Product2Id);

            if (!result.containsKey(yardiId)) {
                result.put(yardiId, new List<Map<String, String>>());
            }

            // Prepare a simple map for each Opportunity
            Map<String, String> oppData = new Map<String, String>{
                'Id' => oli.Opportunity.Id,
                'Name' => oli.Opportunity.Name,
                'StageName' => oli.Opportunity.StageName,
                'OwnerName' => oli.Opportunity.Owner.Name
            };

            // Avoid duplicates
            Boolean exists = false;
            for (Map<String, String> existing : result.get(yardiId)) {
                if (existing.get('Id') == oppData.get('Id')) {
                    exists = true;
                    break;
                }
            }

            if (!exists) {
                result.get(yardiId).add(oppData);
            }
        }

        return result;
    }
    
    
    // ===========================================================
    //                   PICKLIST VALUE UTILITY
    // ===========================================================

    /**
     * Returns picklist values for multiple fields from a given object.
     * Used by LWC to populate dropdowns dynamically.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistValues(String objectApiName, List<String> fieldApiNames) {
        Map<String, List<String>> results = new Map<String, List<String>>();

        if (String.isBlank(objectApiName) || fieldApiNames == null || fieldApiNames.isEmpty()) {
            return results;
        }

        // Get the sObject type dynamically
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        if (!globalDescribe.containsKey(objectApiName)) {
            return results;
        }

        Schema.SObjectType sObjType = globalDescribe.get(objectApiName);
        Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

        for (String fieldApiName : fieldApiNames) {
            if (fieldMap.containsKey(fieldApiName)) {
                List<String> values = new List<String>();
                for (Schema.PicklistEntry pe : fieldMap.get(fieldApiName).getDescribe().getPicklistValues()) {
                    if (pe.isActive()) {
                        values.add(pe.getValue());
                    }
                }
                results.put(fieldApiName, values);
            }
        }

        return results;
    }


    // ===========================================================
    //            UNIT UI SUPPORT: PROPERTY PICKLIST
    // ===========================================================

    /**
     * Returns all distinct property names from Retail_Unit__c
     * Used to populate LWC filters.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAllProperties() {
        List<String> propertyNames = new List<String>();
        // Query all distinct property names
        for (AggregateResult ar : [
            SELECT Property_Name__c name 
            FROM Retail_Unit__c 
            WHERE Property_Name__c != null
            GROUP BY Property_Name__c
            ORDER BY Property_Name__c
        ]) {
            propertyNames.add((String) ar.get('name'));
        }
        return propertyNames;
    }


    //  Wrapper for Yardi Unit Response
    public class YardiUnitWrapper {
        public String UnitID;
        public String UnitCode;
        public String PropertyCode;
        public String PropertyName;
        public String Building;
        public String Floor;
        public Decimal UnitArea;
        public String UnitType;
        public String UnitNature;
        public String UnitLocation;
        public String UnitStatus;
        public String ExpiryDate;
        public String TenantID;
        public String TenantCode;
        public String TenantName;

        public String EffectiveDate;
        public String AmountType;
        public Decimal RentBudget;
        public Decimal NetServiceChargeBudget;
        public Decimal NetMarketingBudget;
        public Decimal FitOutContributionAmount;
        public Decimal RentFreeAmount;
    }

    //  Response holder for LWC
    public class RefreshResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }


    // ===========================================================
    //             YARDI / MULESOFT REFRESH LOGIC
    // ===========================================================

    /**
     * Calls MuleSoft → Yardi endpoint to refresh real-time unit availability.
     * Upserts Retail_Unit__c based on returned JSON payload.
     */
    
    @AuraEnabled
    public static RefreshResponse refreshUnitAvailability(String propertyName,Boolean fullRefresh) {
        RefreshResponse output = new RefreshResponse();
        output.status = 'Failed';
        Organization org = Utilities.getOrganizationDetails();
        
        

        try {
            if (String.isBlank(propertyName) && !fullRefresh) {
                output.message = 'Property Name is required.';
                return output;
            }
            string typeOfRefresh = 'RETL_RefreshUnitAvailability';            
            if(fullRefresh){
                typeOfRefresh = 'RETL_RefreshUnitAvailabilityFull';
                
            }
            // Get MuleSoft endpoint configuration
            MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails(typeOfRefresh);
            if (api == null) {
                output.message = 'Yardi API configuration not found in MuleSoftSetting__mdt.';
                return output;
            }
            String endpoint = '';
            String endPointURL = api.SandboxURL__c ;        
            if(!org.IsSandbox){
                endPointURL = api.ProductionURL__c ; 
            }
            // Build callout URL with propertyName param
            if(!fullRefresh){
                endpoint = endPointURL + '?propertyName=' + EncodingUtil.urlEncode(propertyName, 'UTF-8');
            }
            if(fullRefresh){
                endpoint = endPointURL;
            }
            
            System.debug(' Refresh Unit Availability callout → ' + endpoint);
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod(api.Method__c);
            req.setHeader('client_id', api.APIId__c);
            req.setHeader('client_secret', api.APIKey__c);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res == null) {
                output.message = 'No response received from Yardi endpoint.';
                return output;
            }

            Integer code = res.getStatusCode();
            String body = res.getBody();
            System.debug(' Response Code: ' + code);
            System.debug(' Response Body: ' + body);

            if (code >= 200 && code < 300 && !String.isBlank(body)) {
                List<YardiUnitWrapper> units = 
                    (List<YardiUnitWrapper>) JSON.deserialize(body, List<YardiUnitWrapper>.class);

                if (!units.isEmpty()) {
                    List<Retail_Unit__c> toUpsert = new List<Retail_Unit__c>();

                    for (YardiUnitWrapper u : units) {
                        Retail_Unit__c unit = new Retail_Unit__c();
                        unit.UnitID_External_ID__c = String.valueOf(u.UnitID);
                        unit.Unit_Code__c = u.UnitCode;
                        unit.Property_Code__c = u.PropertyCode;
                        unit.Property_Name__c = u.PropertyName;
                        unit.Building__c = u.Building;
                        unit.Floor__c = u.Floor;
                        unit.Unit_Area__c = u.UnitArea;
                        unit.Unit_Type__c = u.UnitType;
                        unit.Unit_Nature__c = u.UnitNature;
                        unit.Unit_Location__c = u.UnitLocation;
                        unit.Unit_Status__c = u.UnitStatus;
                        unit.Tenant_ID__c = u.TenantID;
                        unit.Tenant_Code__c = u.TenantCode;
                        unit.Tenant_Name__c = u.TenantName;
                        unit.Amount_Type__c = u.AmountType;                                         
                        unit.Fitout_Contribution_Amount__c = u.FitoutContributionAmount;                        
                        unit.Net_Marketing_Budget__c = u.NetMarketingBudget;
                        unit.Net_Service_Charge_Budget__c = u.NetServiceChargeBudget;                        
                        unit.Rent_Budget__c = u.RentBudget;                        
                        unit.Rent_Free_Amount__c = u.RentFreeAmount;
                        // Convert date string like "31/12/2025" to Date safely
                        unit.Expiry_Date__c = parseDate(u.ExpiryDate, u.UnitID, 'ExpiryDate');
                        unit.Effective_Date__c = parseDate(u.EffectiveDate, u.UnitID, 'EffectiveDate');
                        toUpsert.add(unit);
                    }
                    if (!toUpsert.isEmpty()) {
                        upsert toUpsert UnitID_External_ID__c;
                        output.status = 'Success';
                        output.message = 'Fetched & updated ' + toUpsert.size() + ' units successfully.';
                    } else {
                        output.message = 'No valid units returned from Yardi.';
                    }
                } else {
                    output.message = 'No units found for selected property.';
                }
            } else {
                output.message = 'HTTP ' + code + ': ' + body;
            }

        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e, 'Refresh Unit Availability', 'RETL_RefreshUnitAvailability', 'refreshUnitAvailability'));
            output.message = 'Exception: ' + e.getMessage();
        }
        return output;
    }

    /**
     * Parses a date string in dd/MM/yyyy format and returns a Date.
     * Returns null if parsing fails or the string is blank.
     */
    public static Date parseDate(String dateString, String unitId, String label) {
        if (String.isBlank(dateString)) {
            return null;
        }
        try {
            List<String> parts = dateString.split('/');
            if (parts.size() == 3) {
                Integer day = Integer.valueOf(parts[0]);
                Integer month = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);
                return Date.newInstance(year, month, day);
            } else {
                System.debug(' Unexpected format for ' + label + ' on UnitID ' + unitId + ': ' + dateString);
            }
        } catch (Exception e) {
            System.debug(' Invalid ' + label + ' for UnitID ' + unitId + ': ' + dateString);
        }
        return null;
    }

    @AuraEnabled(cacheable=false)
    public static List<OpportunityLineItem> getLineItems(Id opportunityId) {
        return [
            SELECT Id, Quantity, UnitPrice, TotalPrice, Name,
                OpportunityId, Opportunity.Name,
                RETL_Selected_Unit__c,
                RETL_Selected_Unit__r.Name,
                RETL_Selected_Unit__r.Building__c,
                RETL_Selected_Unit__r.Unit_Name_Formula__c,
                RETL_Selected_Unit__r.Unit_Area__c,
                RETL_Service_Charge__c, 
                RETL_Marketing_Amount__c,
                RETL_Rent_Free_Amount__c,
                RETL_Fitout_Contribution_Amount__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];
    }

    @AuraEnabled
    public static void updateProposal(Opportunity opportunityFields, List<OpportunityLineItem> lineItems) {
        try{            
            Id oppId = opportunityFields.Id;
            string approvalRequired = opportunityFields.RETL_AM_PreApproval__c;            
            update opportunityFields;
            update lineItems;
            if(approvalRequired == 'Not Required'){
                System.enqueueJob(new RETL_WorkOrderForDealUpdateQueueable(oppId));
            }
        }catch (DmlException e) {
        
        }
    }


    @AuraEnabled
    public static void syncProposalToYardi (string oppId) {
        try{
            System.enqueueJob(new RETL_WorkOrderForDealUpdateQueueable(oppId));
        }catch (DmlException e) {
        
        }
    }


}