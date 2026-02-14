/**
 * RETL_RenewalOppLineService
 * ---------------------------
 * Apex REST service responsible for generating Opportunity Line Items (OLIs)
 * for renewal opportunities. The service accepts a structured JSON payload
 * containing Retail Unit details and performs the following:
 *
 * Key Responsibilities:
 *   • Validates incoming request structure and unit data
 *   • Ensures Retail Units exist (creates missing units using external IDs)
 *   • Ensures corresponding Product2 records exist (upsert via external Yardi ID)
 *   • Ensures both Standard and Retail Pricebook Entries exist for those products
 *   • Creates new Opportunity Line Items tied to the Retail Pricebook
 *   • Returns structured success/error responses for API clients
 *
 * Design Notes:
 *   • Idempotent creation using external IDs for Units, Products, and PBEs
 *   • Consolidated error/success handlers for consistent API responses
 *   • Intended for system-to-system integration (e.g., MuleSoft/Yardi renewal sync)
 *
 * @author  vkotaprolu@aldar.com
 * @date    2025-11-18
 */
@RestResource(urlMapping = '/Retail/OpportunityLineItems')
global with sharing class RETL_RenewalOppLineService {

    /**
     * Wrapper for incoming JSON request body.
     */
    global class RequestWrapper {
        public Id opportunityId;            // Target Opportunity
        public String propertyCode;         // Property code for Retail Units
        public List<UnitWrapper> units;     // List of unit payloads
    }

    /**
     * Wrapper for a single retail unit entry.
     */
    global class UnitWrapper {
        public String unitId;               // External ID (Retail_Unit__c.UnitID_External_ID__c)
        public Decimal baseRent;            // UnitPrice for OLI
        public Decimal marketingAmount;     // Custom OLI field
        public Decimal serviceCharge;       // Custom OLI field

        public string unitCode;
        public string unitType;
        public string floor;
        public string location;
        public string area;

    }

    /**
     * Sends structured error JSON response.
     */
    private static void sendError(Integer code, String msg) {
        RestContext.response.statusCode = code;
        RestContext.response.addHeader('Content-Type', 'application/json');

        RestContext.response.responseBody =
            Blob.valueOf('{"status":"ERROR","message":"' + msg + '"}');
    }

    /**
     * Sends structured success JSON response.
     */
    private static void sendSuccess(Integer count) {
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');

        RestContext.response.responseBody =
            Blob.valueOf('{"status":"SUCCESS","recordsCreated":' + count + '}');
    }

    /**
     * REST POST — creates Opportunity Line Items for renewal opportunity.
     */
    @HttpPost
    global static void createOLIs() {
        try {
            // Deserialize input request JSON
            RequestWrapper input = (RequestWrapper) JSON.deserialize(
                RestContext.request.requestBody.toString(),
                RequestWrapper.class
            );

            // Validate request-level fields
            if (input == null ||
                String.isBlank(input.opportunityId) ||
                String.isBlank(input.propertyCode) ||
                input.units == null ||
                input.units.isEmpty()
            ) {
                sendError(400,
                    'Invalid request. Missing or empty opportunityId, propertyCode, or units.'
                );
                return;
            }

            // Validate unit entries
            /* for (UnitWrapper uw : input.units) {
                if (uw == null || String.isBlank(uw.unitId)) {
                    sendError(400,
                        'Invalid request. All units must contain a non-empty unitId.'
                    );
                    return;
                }
            } */

            for (UnitWrapper uw : input.units) {

                if (uw == null) {
                    sendError(400, 'Invalid request. Unit object cannot be null.');
                    return;
                }

                Map<String, String> requiredFields = new Map<String, String>{
                    'unitId'    => uw.unitId,
                    'unitCode'  => uw.unitCode,
                    'unitType'  => uw.unitType
                    //'floor'     => uw.floor,
                    //'location'  => uw.location,
                    //'area'      => uw.area
                };
                
                for (String fieldName : requiredFields.keySet()) {
                    if (String.isBlank(requiredFields.get(fieldName))) {
                        sendError(
                            400,
                            'Invalid request. All units must contain a non-empty ' + fieldName + '.'
                        );
                        return;
                    }
                }
            }

            // --------------------------------------
            // PRICEBOOKS
            // --------------------------------------
            Pricebook2 retailPB = [
                SELECT Id
                FROM Pricebook2
                WHERE Name = 'Retail Price Book' AND IsActive = true
                LIMIT 1
            ];
            Pricebook2 standardPB = new Pricebook2();
            //List<Pricebook2> standardPBList = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            if (Test.isRunningTest()) {
                // Fallback in test mode: use the Id guaranteed by the testing framework
                standardPB = new Pricebook2(Id = Test.getStandardPricebookId());
            } 
            else {
                standardPB = [
                    SELECT Id
                    FROM Pricebook2
                    WHERE IsStandard = true
                    LIMIT 1
                ];
            }

            
            // --------------------------------------
            // RETAIL UNITS
            // --------------------------------------
            Set<String> externalIds = new Set<String>();
            for (UnitWrapper uw : input.units) {
                externalIds.add(uw.unitId);
            }

            // Query existing units
            Map<String, Retail_Unit__c> retailUnitMap = new Map<String, Retail_Unit__c>();
            for (Retail_Unit__c ru : [
                SELECT Id, Property_Code__c, Unit_Code__c, UnitID_External_ID__c, Unit_Name_Formula__c
                FROM Retail_Unit__c
                WHERE UnitID_External_ID__c IN :externalIds
            ]) {
                retailUnitMap.put(ru.UnitID_External_ID__c, ru);
            }

            // Create missing units
            List<Retail_Unit__c> newUnits = new List<Retail_Unit__c>();
            for (UnitWrapper uw : input.units) {
                if (!retailUnitMap.containsKey(uw.unitId)) {
                    newUnits.add(new Retail_Unit__c(
                        UnitID_External_ID__c = uw.unitId,
                        Unit_Code__c = uw.unitId,
                        Property_Code__c = input.propertyCode
                    ));
                }
            }

            if (!newUnits.isEmpty()) {
                insert newUnits;

                // Requery to populate formula fields & IDs
                for (Retail_Unit__c ru : [
                    SELECT Id, Property_Code__c, Unit_Code__c, UnitID_External_ID__c, Unit_Name_Formula__c
                    FROM Retail_Unit__c
                    WHERE Id IN :newUnits
                ]) {
                    retailUnitMap.put(ru.UnitID_External_ID__c, ru);
                }
            }

            // --------------------------------------
            // PRODUCTS
            // --------------------------------------
            Set<String> unitCodes = new Set<String>();
            for (Retail_Unit__c ru : retailUnitMap.values()) {
                unitCodes.add(ru.Unit_Code__c);
            }

            Map<String, Product2> productMapByCode = new Map<String, Product2>();
            for (Product2 p : [
                SELECT Id, Name, ProductCode, RETL_Yardi_Id__c
                FROM Product2
                WHERE ProductCode IN :unitCodes
            ]) {
                productMapByCode.put(p.ProductCode, p);
            }

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

                for (Product2 p : [
                    SELECT Id, ProductCode, RETL_Yardi_Id__c
                    FROM Product2
                    WHERE ProductCode IN :unitCodes
                ]) {
                    productMapByCode.put(p.ProductCode, p);
                }
            }

            // --------------------------------------
            // PRICEBOOK ENTRIES (PBE)
            // --------------------------------------
            Set<Id> productIds = new Set<Id>();
            for (Product2 p : productMapByCode.values()) {
                productIds.add(p.Id);
            }

            // 1) Standard PBEs
            Set<Id> existingStd = new Map<Id, PricebookEntry>([
                SELECT Product2Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :standardPB.Id AND Product2Id IN :productIds
            ]).keySet();

            List<PricebookEntry> stdPBEs = new List<PricebookEntry>();
            for (Product2 p : productMapByCode.values()) {
                if (!existingStd.contains(p.Id)) {
                    stdPBEs.add(new PricebookEntry(
                        Pricebook2Id = standardPB.Id,
                        Product2Id = p.Id,
                        UnitPrice = 0,
                        IsActive = true,
                        RETL_External_ID__c = standardPB.Id + '-' + p.RETL_Yardi_Id__c
                    ));
                }
            }

            if (!stdPBEs.isEmpty()) {
                upsert stdPBEs RETL_External_ID__c;
            }

            // 2) Retail PBEs
            Map<String, PricebookEntry> retailKeyMap = new Map<String, PricebookEntry>();
            for (PricebookEntry pbe : [
                SELECT Id, Product2Id, RETL_External_ID__c
                FROM PricebookEntry
                WHERE Pricebook2Id = :retailPB.Id AND Product2Id IN :productIds
            ]) {
                retailKeyMap.put(pbe.RETL_External_ID__c, pbe);
            }

            List<PricebookEntry> retailPBEsToCreate = new List<PricebookEntry>();
            for (Product2 p : productMapByCode.values()) {
                String key = retailPB.Id + '-' + p.Id;
                if (!retailKeyMap.containsKey(key)) {
                    retailPBEsToCreate.add(new PricebookEntry(
                        Pricebook2Id = retailPB.Id,
                        Product2Id = p.Id,
                        UnitPrice = 0,
                        IsActive = true,
                        RETL_External_ID__c = key
                    ));
                }
            }

            if (!retailPBEsToCreate.isEmpty()) {
                insert retailPBEsToCreate;
            }

            // Re-query Retail PBEs for OLI creation
            Map<Id, PricebookEntry> retailPBEMap = new Map<Id, PricebookEntry>();
            for (PricebookEntry pbe : [
                SELECT Id, Product2Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :retailPB.Id AND Product2Id IN :productIds
            ]) {
                retailPBEMap.put(pbe.Product2Id, pbe);
            }

            // Get exisiting OLIs to prevent duplicates (if any)
            Map<String, OpportunityLineItem> existingOLIs = new Map<String, OpportunityLineItem>();
            for (OpportunityLineItem oli : [
                SELECT Id, OpportunityId, Product2Id, PricebookEntryId, RETL_Unit_Code__c, Quantity, UnitPrice, RETL_Selected_Unit__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :input.opportunityId
            ]) {
                // existingUnitIds.add(oli.RETL_Selected_Unit__c);
                existingOLIs.put(oli.OpportunityId + '-' + oli.RETL_Unit_Code__c, oli);
            }

            // --------------------------------------
            // OLI CREATION
            // --------------------------------------
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();

            for (UnitWrapper uw : input.units) {
                Retail_Unit__c ru = retailUnitMap.get(uw.unitId);
                if (ru == null) continue;

                Product2 prod = productMapByCode.get(ru.Unit_Code__c);
                if (prod == null) continue;

                PricebookEntry pbe = retailPBEMap.get(prod.Id);
                if (pbe == null) continue;

                OpportunityLineItem oli = new OpportunityLineItem();
                // Prevent duplicate OLIs for same Opportunity + Product
                if (existingOLIs.containsKey(input.opportunityId + '-' + uw.unitCode)) {
                    oli = existingOLIs.get(input.opportunityId + '-' + uw.unitCode);
                }
                else {
                    oli = new OpportunityLineItem();
                    oli.OpportunityId          = input.opportunityId;
                    oli.PricebookEntryId       = pbe.Id;
                    oli.Quantity               = 1;
                }
                
                oli.UnitPrice              = uw.baseRent;
                oli.RETL_Marketing_Amount__c = uw.marketingAmount;
                oli.RETL_Service_Charge__c   = uw.serviceCharge;
                oli.RETL_Selected_Unit__c    = ru.Id;

                // Additoional Deal View Field Mapping.
                oli.RETL_Floor__c = uw.floor;
                oli.RETL_Unit_Area__c = uw.area;
                oli.RETL_Unit_Code__c = uw.unitCode;
                oli.RETL_Unit_Id__c = uw.unitId;
                oli.RETL_Unit_Location__c =  uw.location;
                oli.RETL_Unit_Type__c = uw.unitType;
                oliList.add(oli);
            }

            // insert oliList;
            upsert oliList;

            sendSuccess(oliList.size());

        } catch (Exception ex) {
            sendError(500, ex.getMessage());
        }
    }
}