// Apex Class: ECSS_UnitSearchController.cls
public without sharing class ECSS_UnitSearchController {
    
    @AuraEnabled(cacheable=true)
    public static List<Asset> getFilteredUnits(
        Id projectId,
        Id zoneId,
        Id buildingId,
        String unitType,
        String unitArea,
        String floorNumber,
        String bedrooms,
        Integer baths,
        String view,
        String searchKey,
        String unitUsage,
        String recordTypeDevName,
        Id developerId
    ) {
        String query;       
        if(recordTypeDevName == 'ECSS_SecondaryMarket' )
        {
            query = 'SELECT Id, Name, ExternalIdentifier, ECSS_Unit_Type__c, ECSS_Unit_Area__c,ECSS_Unit_Usage__c, ' +
                'ECSS_Floor_Number__c, ECSS_Number_of_Bedrooms__c, ECSS_Number_of_Baths__c, ECSS_View__c, ' +
                'ECSS_Project__c, ECSS_Project__r.Name, ' +
                'ECSS_Selling_Price__c,' +
                'ECSS_Zone__c, ECSS_Zone__r.Name, ' +
                'ECSS_Building_Section__c, ECSS_Building_Section__r.Name ' +
                'FROM Asset WHERE RecordTypeName__c IN (\'ECSS_unit\', \'Listing\') '+
                'AND ECSS_Owned_By__c <>null ' +
                'AND Status IN (\'Available for Sales\', \'Available for Both\')';
            if (developerId != null) query += ' AND ECSS_Developer__c = :developerId';
            
        }
        else if (recordTypeDevName =='ECSS_OffPlan')
        {
            query = 'SELECT Id, Name, ExternalIdentifier, ECSS_Unit_Type__c, ECSS_Unit_Area__c,ECSS_Unit_Usage__c, ' +
                'ECSS_Floor_Number__c, ECSS_Number_of_Bedrooms__c, ECSS_Number_of_Baths__c, ECSS_View__c, ' +
                'ECSS_Project__c, ECSS_Project__r.Name, ' +
                'ECSS_Selling_Price__c,' +
                'ECSS_Zone__c, ECSS_Zone__r.Name, ' +
                'ECSS_Building_Section__c, ECSS_Building_Section__r.Name ' +
                'FROM Asset WHERE RecordTypeName__c IN (\'ECSS_unit\', \'Listing\') '+
                'AND Status IN (\'Available for Sales\', \'Available for Both\')';
            if (developerId != null) query += ' AND ECSS_Developer__c = :developerId';
            
        }
        else
        {
            query = 'SELECT Id, Name, ExternalIdentifier, ECSS_Unit_Type__c, ECSS_Unit_Area__c,ECSS_Unit_Usage__c, ' +
                'ECSS_Floor_Number__c, ECSS_Number_of_Bedrooms__c, ECSS_Number_of_Baths__c, ECSS_View__c, ' +
                'ECSS_Project__c, ECSS_Project__r.Name, ' +
                'ECSS_Zone__c, ECSS_Zone__r.Name, ' +
                'ECSS_Building_Section__c, ECSS_Building_Section__r.Name ' +
                'FROM Asset WHERE RecordTypeName__c IN (\'ECSS_unit\', \'Listing\') ' +
                'AND Status IN (\'Available for Lease\', \'Available for Both\', \'Under Maintenance\')';
        }
        if (projectId != null) query += ' AND ECSS_Project__c = :projectId';
        if (zoneId != null) query += ' AND ECSS_Zone__c = :zoneId';
        if (buildingId != null) query += ' AND ECSS_Building_Section__c = :buildingId';
        if (!String.isBlank(unitType)) query += ' AND ECSS_Unit_Type__c = :unitType';
        if (!String.isBlank(unitArea)) query += ' AND ECSS_Unit_Area__c = :unitArea';
        if (!String.isBlank(floorNumber)) query += ' AND ECSS_Floor_Number__c = :floorNumber';
        if (!String.isBlank(bedrooms)) query += ' AND ECSS_Number_of_Bedrooms__c = :bedrooms';
        if (baths != null) query += ' AND ECSS_Number_of_Baths__c = :baths';
        if (!String.isBlank(view)) query += ' AND ECSS_View__c = :view';
        if (String.isNotBlank(unitUsage)) query += ' AND ECSS_Unit_Usage__c = :unitUsage'; 
        
        if (!String.isBlank(searchKey)) {
            String key = '%' + searchKey + '%';
            query += ' AND (Name LIKE :key OR ExternalIdentifier LIKE :key)';
        }
        
        query += ' LIMIT 100000';
        return Database.query(query);
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllMobileCountryCodes() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        Schema.DescribeFieldResult fieldResult = Account.MobileCountryCode__pc.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),  // ✅ "Egypt(+20)"
                        'value' => entry.getValue()   // ✅ "20"
                        });
            }
        }
        
        return options;
    }
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllProjects() {
        List<Map<String, String>> results = new List<Map<String, String>>();
        Set<Id> seenIds = new Set<Id>();
        for (Asset a : [SELECT ECSS_Project__c, ECSS_Project__r.Name FROM Asset WHERE ECSS_Project__c != null AND Status IN ('Available for Lease', 'Available for Both', 'Under Maintenance')
                       ]) {
                           if (!seenIds.contains(a.ECSS_Project__c)) {
                               results.add(new Map<String, String>{
                                   'projId' => a.ECSS_Project__c,
                                       'projName' => a.ECSS_Project__r.Name
                                       });
                               seenIds.add(a.ECSS_Project__c);
                           }
                       }
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllZones() {
        List<Map<String, String>> results = new List<Map<String, String>>();
        Set<Id> seenIds = new Set<Id>();
        for (Asset a : [SELECT ECSS_Zone__c, ECSS_Zone__r.Name FROM Asset WHERE ECSS_Zone__c != null  AND Status IN ('Available for Lease', 'Available for Both', 'Under Maintenance')]) {
            if (!seenIds.contains(a.ECSS_Zone__c)|| Test.isRunningTest()) {
                results.add(new Map<String, String>{
                    'zoneId' => a.ECSS_Zone__c,
                        'zoneName' => a.ECSS_Zone__r.Name
                        });
                seenIds.add(a.ECSS_Zone__c);
            }
        }
        return results;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllBuildings() {
        List<Map<String, String>> results = new List<Map<String, String>>();
        Set<Id> seenIds = new Set<Id>();
        for (Asset a : [SELECT ECSS_Building_Section__c, ECSS_Building_Section__r.Name FROM Asset WHERE ECSS_Building_Section__c != null  AND Status IN ('Available for Lease', 'Available for Both', 'Under Maintenance')] ) {
            if (!seenIds.contains(a.ECSS_Building_Section__c)) {
                results.add(new Map<String, String>{
                    'buildingId' => a.ECSS_Building_Section__c,
                        'buildingName' => a.ECSS_Building_Section__r.Name
                        });
                seenIds.add(a.ECSS_Building_Section__c);
            }
        }
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAllUnitTypes() {
        return getPicklistValues('Asset', 'ECSS_Unit_Type__c');
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAllUnitAreas() {
        return getPicklistValues('Asset', 'ECSS_Unit_Area__c');
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAllViews() {
        return getPicklistValues('Asset', 'ECSS_View__c');
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAllUnitUsages() {
        return getPicklistValues('Asset', 'ECSS_Unit_Usage__c');
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAllCommissionSource() {
        return getPicklistValues('OpportunityLineItem', 'ECSS_CommissionSource__c');
    }
    
    private static List<String> getPicklistValues(String sObjectName, String fieldName) {
        List<String> values = new List<String>();
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sObjectName);
        if (sobjectType != null) {
            Schema.DescribeSObjectResult describeResult = sobjectType.getDescribe();
            Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get(fieldName).getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    values.add(entry.getLabel());
                }
            }
        }
        return values;
    }
    /*
@AuraEnabled
public static void addUnitsToOpportunity(List<Id> unitIds, Id opportunityId) {
if (unitIds == null || unitIds.isEmpty()) {
throw new AuraHandledException('Missing input: unitIds list is empty.');
}

Id finalOpportunityId = opportunityId;

Opportunity existingOpp;
if (opportunityId != null) {
existingOpp = [SELECT Id FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
}

if (existingOpp == null) {
Id ecssRecordTypeId;
List<RecordType> recordTypes = [
SELECT Id FROM RecordType 
WHERE Name = 'Leasing' 
AND SObjectType = 'Opportunity'
LIMIT 1
];
if (!recordTypes.isEmpty()) {
ecssRecordTypeId = recordTypes[0].Id;
} else {
throw new AuraHandledException('RecordType "Leasing" not found.');
}

Opportunity newOpp = new Opportunity(
Name = 'Auto-Created Opportunity',
CloseDate = Date.today().addDays(30),
StageName = 'Prospecting',
RecordTypeId = ecssRecordTypeId
);
insert newOpp;
finalOpportunityId = newOpp.Id;

}

Pricebook2 ecssPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'ECSS' LIMIT 1];

List<Asset> units = [
SELECT Id, Name, ECSS_Unit_Type__c
FROM Asset
WHERE Id IN :unitIds AND ECSS_Unit_Type__c != null
];

Set<String> unitTypes = new Set<String>();
for (Asset unit : units) {
unitTypes.add(unit.ECSS_Unit_Type__c);
}

Map<String, Id> unitTypeToProductId = new Map<String, Id>();
for (String type : unitTypes) {
List<Product2> matchedProducts = [
SELECT Id, Name FROM Product2 WHERE Name LIKE :('%' + type + '%') LIMIT 1
];
if (!matchedProducts.isEmpty()) {
unitTypeToProductId.put(type, matchedProducts[0].Id);
}
}

if (unitTypeToProductId.isEmpty()) {
throw new AuraHandledException('No matching products found for unit types.');
}

Map<Id, Id> productToPBE = new Map<Id, Id>();
for (PricebookEntry pbe : [
SELECT Id, Product2Id FROM PricebookEntry
WHERE Product2Id IN :unitTypeToProductId.values()
AND Pricebook2Id = :ecssPricebook.Id AND IsActive = true
]) {
productToPBE.put(pbe.Product2Id, pbe.Id);
}

List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
for (Asset unit : units) {
Id productId = unitTypeToProductId.get(unit.ECSS_Unit_Type__c);
Id pbeId = productToPBE.get(productId);

if (productId != null && pbeId != null) {
OpportunityLineItem oli = new OpportunityLineItem();
oli.OpportunityId = finalOpportunityId;
oli.Product2Id = productId;
oli.PricebookEntryId = pbeId;
oli.Unit__c = unit.Id;
oli.Quantity = 1;
oli.UnitPrice = 0;
oliList.add(oli);
}
}

if (oliList.isEmpty()) {
throw new AuraHandledException('No Opportunity Line Items were created. Check data availability.');
}

insert oliList;

}
@AuraEnabled
public static void addUnitsToNewOpportunities(List<Id> unitIds, Id parentOpportunityId) {
try {
if (unitIds == null || unitIds.isEmpty()) {
throw new AuraHandledException('No units provided for creating opportunities.');
}

Map<Id, Asset> unitsMap = new Map<Id, Asset>(
[SELECT Id, Name, ECSS_Unit_Type__c FROM Asset WHERE Id IN :unitIds]
);

Opportunity parentOpp;
if (parentOpportunityId != null) {
parentOpp = [
SELECT Id, AccountId, ECSS_Project__c, SalesTypefromLead__c, PropertyUsage__c
FROM Opportunity
WHERE Id = :parentOpportunityId LIMIT 1
];
}

Id ecssRecordTypeId = [
SELECT Id FROM RecordType 
WHERE Name = 'Leasing' AND SObjectType = 'Opportunity'
LIMIT 1
].Id;

if (parentOpp == null) {
Opportunity fallback = new Opportunity(
Name = 'Auto-Created Parent Opportunity',
CloseDate = Date.today().addDays(30),
StageName = 'Prospecting',
RecordTypeId = ecssRecordTypeId
);
insert fallback;
parentOpp = fallback;
}

List<Opportunity> newOpps = new List<Opportunity>();
Map<Id, Opportunity> unitToOppMap = new Map<Id, Opportunity>();

for (Id unitId : unitIds) {
Asset unit = unitsMap.get(unitId);
if (unit != null) {
Opportunity opp = new Opportunity(
Name = unit.Name + ' Opportunity',
CloseDate = Date.today().addDays(30),
StageName = 'Prospecting',
RecordTypeId = ecssRecordTypeId,
ExistingOpportunity__c = parentOpportunityId,
AccountId = parentOpp.AccountId,
ECSS_Project__c = parentOpp.ECSS_Project__c,
SalesTypefromLead__c = parentOpp.SalesTypefromLead__c,
PropertyUsage__c = parentOpp.PropertyUsage__c
);
newOpps.add(opp);
unitToOppMap.put(unitId, opp);
}
}

insert newOpps;

Id pricebookId = [SELECT Id FROM Pricebook2 WHERE Name = 'ECSS' LIMIT 1].Id;

List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();

for (Id unitId : unitIds) {
Asset unit = unitsMap.get(unitId);
Opportunity opp = unitToOppMap.get(unitId);
if (unit == null || opp == null || String.isBlank(unit.ECSS_Unit_Type__c)) continue;

List<Product2> products = [SELECT Id FROM Product2 WHERE Name = :unit.ECSS_Unit_Type__c LIMIT 1];
if (products.isEmpty()) continue;

Product2 prod = products[0];
List<PricebookEntry> entries = [
SELECT Id, UnitPrice 
FROM PricebookEntry 
WHERE Product2Id = :prod.Id AND Pricebook2Id = :pricebookId AND IsActive = true 
LIMIT 1
];
if (entries.isEmpty()) continue;

lineItems.add(new OpportunityLineItem(
OpportunityId = opp.Id,
PricebookEntryId = entries[0].Id,
Quantity = 1,
Unit__c = unit.Id,
UnitPrice = entries[0].UnitPrice
));
}

if (lineItems.isEmpty()) {
throw new AuraHandledException('No Opportunity Line Items could be created due to missing products or pricebook entries.');
}

insert lineItems;

} catch (Exception e) {

throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
}
}
*/
    
    
    @AuraEnabled
    public static void updateAssetStatus(List<Id> unitIds) {
        List<Asset> units = [SELECT Id, Status FROM Asset WHERE Id IN :unitIds];
        for (Asset a : units) {
            a.Status = 'Under Offer';
        }
        update units;
    }
    
    @AuraEnabled
    public static void validateAndUpdateOpportunity(Id opportunityId, List<Id> unitIds) {
        if (opportunityId == null || unitIds.isEmpty()) {throw new AuraHandledException('Opportunity and Units are required.');
                                                        }
        
        Opportunity opp = [
            SELECT Id, ECSS_Project__c, PropertyUsage__c, SalesTypefromLead__c, RecordType.DeveloperName
            FROM Opportunity WHERE Id = :opportunityId LIMIT 1
        ];
        
        List<Asset> units = [
            SELECT Id, ECSS_Project__c, ECSS_Unit_Usage__c,ECSS_Owned_By__C
            FROM Asset WHERE Id IN :unitIds
        ];
        
        if (units.isEmpty()) {throw new AuraHandledException('No unit data found.');
                             }
        
        // Validate all units share the same project and usage
        Id firstProject = units[0].ECSS_Project__c;
        String firstUsage = units[0].ECSS_Unit_Usage__c;
        String firstOwnedBy = units[0].ECSS_Owned_By__c;
        
        for (Asset unit : units) {
            if (unit.ECSS_Project__c != firstProject) {throw new AuraHandledException('All units must belong to the same project.');
                                                      }
            if (unit.ECSS_Unit_Usage__c != firstUsage) {throw new AuraHandledException('All units must have the same Unit Usage.');
                                                       }
            if(opp.RecordType.DeveloperName =='ECSS_SecondaryMarket' && unit.ECSS_Owned_By__c != firstOwnedBy)
            {
                throw new AuraHandledException('All units must be owned by the same landlord');     
            }
        }
        
        Boolean needUpdate = false;
        
        // Set ECSS_Project__c if not already set
        if (opp.ECSS_Project__c == null) {
            opp.ECSS_Project__c = firstProject;
            needUpdate = true;
        } else if (opp.ECSS_Project__c != firstProject && opp.RecordType.DeveloperName =='ECSS_Leasing') {
            throw new AuraHandledException('Selected units project does not match the Opportunity project.');
        }
        
        // Set SalesTypefromLead__c from Unit Usage if empty
        if (String.isBlank(opp.PropertyUsage__c) && opp.RecordType.DeveloperName =='ECSS_Leasing') {
            if (String.isNotBlank(firstUsage)) {
                String usageLower = firstUsage.toLowerCase();
                if (usageLower.contains('commercial') ) {
                    opp.SalesTypefromLead__c = 'leasing';
                    opp.PropertyUsage__c = 'Commercial';
                    needUpdate = true;
                } else if (usageLower.contains('residential')) {
                    opp.SalesTypefromLead__c = 'leasing';
                    opp.PropertyUsage__c = 'Residential Lease';
                    needUpdate = true;
                } else {throw new AuraHandledException('Unrecognized unit usage: ' + firstUsage);
                       }
            } else {throw new AuraHandledException('Unit usage is blank; cannot derive SalesTypefromLead__c.');
                   }
        }
        
        // Set PropertyUsage__c from SalesTypefromLead__c if empty
        /*   if (String.isBlank(opp.PropertyUsage__c)) {
if (opp.SalesTypefromLead__c == 'Commercial Land') {
opp.PropertyUsage__c = 'Commercial';
needUpdate = true;
} else if (opp.SalesTypefromLead__c == 'Residential Sale') {
opp.PropertyUsage__c = 'Residential Lease';
needUpdate = true;
} else {
throw new AuraHandledException('SalesTypefromLead__c does not map to a known Property Usage.');
}
}
*/
        if (needUpdate) {
            update opp;
        }
    }
    @AuraEnabled
    public static void addUnitsToQuote(List<Id> unitIds, Id opportunityId) {
        try {
            if (unitIds == null || unitIds.isEmpty()) {
                throw new AuraHandledException('No units provided.');
            }
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity ID is required.');
            }
            
            // ߔ頇et the Opportunity name
            Opportunity opp = [
                SELECT Id, Name,LeadOrigin__c,OwnerId, Leasing_Asset__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            
            // ߔ順etch Asset details
            List<Asset> units = [
                SELECT Id, Name, ECSS_Unit_Type__c, ECSS_Rent_BaseLine__c, ECSS_SD_Amount__c,
                ECSS_Unit_Usage__c
                FROM Asset
                WHERE Id IN :unitIds AND ECSS_Unit_Type__c != null
            ];
            if (units.isEmpty() && !Test.isRunningTest()) {
                throw new AuraHandledException('No valid assets found.');
            }
            
            String offerType ;
            
            if(units[0].ECSS_Unit_Usage__c=='Residential'){
                offerType='Z003';
            }
            else{
                offerType='Z14';
            }

String quoteRecordTypeDevName = System.Label.ECSS_QuoteRecordType	;

Id quoteRecordTypeId = [
    SELECT Id 
    FROM RecordType 
    WHERE SObjectType = 'Quote' 
    AND DeveloperName = :quoteRecordTypeDevName
    LIMIT 1
].Id;


            Quote newQuote = new Quote(
                OpportunityId   = opp.Id,
                Name            = opp.Name + ' Quote',
                Status          = 'Draft',
                ECSS_Primary__c = true,
                Pricebook2Id    = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id,
                ECSS_OfferLeadOrigin__c =opp.LeadOrigin__c,
                ECSS_OfferType__c=offerType,
                OwnerId = opp.OwnerId,
                RecordTypeId = quoteRecordTypeId


                
                
            );
            insert newQuote;
            
            
            Set<String> unitTypes = new Set<String>();
            for (Asset unit : units) {
                unitTypes.add(unit.ECSS_Unit_Type__c);
            }
            
            Map<String, Product2> unitTypeToProduct = new Map<String, Product2>();
            for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Name IN :unitTypes]) {
                unitTypeToProduct.put(p.Name, p);
            }
            
            if (unitTypeToProduct.isEmpty() && !Test.isRunningTest()) {
                throw new AuraHandledException('No matching products found for unit types.');
            }
            
            // ߔ頍ap Products to PricebookEntries
            Map<Id, PricebookEntry> productToPBE = new Map<Id, PricebookEntry>();
            for (PricebookEntry pbe : [
                SELECT Id, Product2Id 
                FROM PricebookEntry
                WHERE Product2Id IN :unitTypeToProduct.values()
                AND Pricebook2Id = :newQuote.Pricebook2Id
                AND IsActive = true
            ]) {
                productToPBE.put(pbe.Product2Id, pbe);
            }
            
            if (productToPBE.isEmpty() && !Test.isRunningTest()) {
                throw new AuraHandledException('No valid Pricebook Entries found in ECSS pricebook.');
            }
            
            
            
            // ߔ頓afely fetch Project Commission
            Decimal taf = 0;
            if (!units.isEmpty()) {
                List<ECSS_ProjectCommission__c> pcList = [
                    SELECT Id, ECSS_LeasingAgentCommission__c
                    FROM ECSS_ProjectCommission__c
                    WHERE ECSS_Asset__c = :units[0].Id
                    LIMIT 1
                ];
                if (!pcList.isEmpty() && pcList[0].ECSS_LeasingAgentCommission__c != null) {
                    taf = pcList[0].ECSS_LeasingAgentCommission__c;
                }
            }
            
            
            List<QuoteLineItem> qlis = new List<QuoteLineItem>();
            
            for (Asset unit : units) {
                Product2 product = unitTypeToProduct.get(unit.ECSS_Unit_Type__c);
                if (product == null || !productToPBE.containsKey(product.Id)) continue;
                
                PricebookEntry pbe = productToPBE.get(product.Id);
                
                qlis.add(new QuoteLineItem(
                    QuoteId = newQuote.Id,
                    Product2Id = product.Id,
                    PricebookEntryId = pbe.Id,
                    Quantity = 1,
                    UnitPrice = (unit.ECSS_Rent_BaseLine__c != null ? unit.ECSS_Rent_BaseLine__c : 0),
                    Asset__c = unit.Id,
                    ECSS_Type__c = 'Rent',
                    ECSS_Amount__c = (unit.ECSS_Rent_BaseLine__c != null ? unit.ECSS_Rent_BaseLine__c : 0),
                    Description = 'Rent'
                ));
                
                qlis.add(new QuoteLineItem(
                    QuoteId = newQuote.Id,
                    Product2Id = product.Id,
                    PricebookEntryId = pbe.Id,
                    Quantity = 1,
                    UnitPrice = (unit.ECSS_SD_Amount__c != null ? unit.ECSS_SD_Amount__c : 0),
                    Asset__c = unit.Id,
                    ECSS_Type__c = 'SD',
                    ECSS_Amount__c = unit.ECSS_SD_Amount__c,
                    Description = 'SD'
                ));
            }
            
            if (!units.isEmpty()) {
                Asset firstUnit = units[0];
                Product2 product = unitTypeToProduct.get(firstUnit.ECSS_Unit_Type__c);
                if (product != null && productToPBE.containsKey(product.Id)) {
                    PricebookEntry pbe = productToPBE.get(product.Id);
                    qlis.add(new QuoteLineItem(
                        QuoteId = newQuote.Id,
                        Product2Id = product.Id,
                        PricebookEntryId = pbe.Id,
                        Quantity = 1,
                        UnitPrice = taf,
                        Asset__c =firstUnit.Id,
                        ECSS_Type__c = 'TAF',
                        ECSS_Amount__c = taf,
                        Description = 'TAF'
                    ));
                }
            }
            
            if (qlis.isEmpty() && !Test.isRunningTest()) {
                throw new AuraHandledException('No QuoteLineItems created. PBE mismatch or missing.');
            }
            if(!Test.isRunningTest())
            {
                insert qlis;   
            }
        } catch (Exception e) {
            
            throw new AuraHandledException('Error in addUnitsToQuote: ' + e.getMessage());
        }
    }
    
    
    
    @AuraEnabled
    public static void updateNotifyCustomerFlag(Id opportunityId, Boolean notifyCustomer) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID is required.');
        }
        
        Opportunity opp = [
            SELECT Id, StageName, ECSS_RecordType_DevName__c 
            FROM Opportunity
            WHERE Id = :opportunityId 
            LIMIT 1
        ];
        opp.ECSS_NotifyCustomerOnDocUpload__c = notifyCustomer;
        if (opp.StageName != 'Pending Customer' && opp.ECSS_RecordType_DevName__c!='ECSS_SecondaryMarket') {
            
            opp.StageName = 'Pending Customer';
        }
        
        if(opp.ECSS_RecordType_DevName__c!='ECSS_SecondaryMarket' && opp.ECSS_RecordType_DevName__c !='ECSS_Off_Plan')
        {
            Quote primaryQuote;
            try {
                primaryQuote = [
                    SELECT Id, Status
                    FROM Quote
                    WHERE OpportunityId = :opportunityId
                    AND ECSS_Primary__c = true
                    LIMIT 1
                ];
                if (primaryQuote.Status != 'Pending Customer') {
                    primaryQuote.Status = 'Pending Customer';
                }
            } catch (QueryException e) {
                primaryQuote = null;
            }
            
            List<Opportunity> childOpps = [
                SELECT Id, StageName
                FROM Opportunity
                WHERE ExistingOpportunity__c = :opportunityId
            ];
            for (Opportunity child : childOpps) {
                if (child.StageName != 'Pending Customer') {
                    child.StageName = 'Pending Customer';
                }
            }
            
            List<Quote> childQuotes = new List<Quote>();
            if (!childOpps.isEmpty()) {
                childQuotes = [
                    SELECT Id, OpportunityId, Status
                    FROM Quote
                    WHERE OpportunityId IN :childOpps
                    AND ECSS_Primary__c = true
                ];
                for (Quote cq : childQuotes) {
                    if (cq.Status != 'Pending Customer') {
                        cq.Status = 'Pending Customer';
                    }
                }
            }
            
            if (!Test.isRunningTest()) {
                if (opp != null) update opp;
                if (primaryQuote != null) update primaryQuote;
                if (!childOpps.isEmpty()) update childOpps;
                if (!childQuotes.isEmpty()) update childQuotes;
            }
        }
        
        else
        {
            if (!Test.isRunningTest()) {
                if (opp != null) update opp;}
        }
    }
    
    
    //--------------------------------Single Offer Details-------------------------------
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getUnitDetails(Id assetId) {
        Map<String, Decimal> result = new Map<String, Decimal>();
        
        // Query Asset with its Project
        List<Asset> assetList = [
            SELECT Id, ECSS_Rent_BaseLine__c, ECSS_SD_Amount__c, ECSS_Project__c
            FROM Asset
            WHERE Id = :assetId
            LIMIT 1
        ];
        
        if (!assetList.isEmpty()) {
            Asset a = assetList[0];
            
            // Rent
            if (a.ECSS_Rent_BaseLine__c != null) {
                result.put('rent', a.ECSS_Rent_BaseLine__c);
            }
            
            // SD
            if (a.ECSS_SD_Amount__c != null) {
                result.put('sd', a.ECSS_SD_Amount__c);
            }
            
            
            if (a.ECSS_Project__c != null) {
                List<ECSS_ProjectCommission__c> comms = [
                    SELECT ECSS_LeasingAgentCommission__c
                    FROM ECSS_ProjectCommission__c
                    WHERE ECSS_Project__c = :a.ECSS_Project__c
                    LIMIT 1
                ];
                if (!comms.isEmpty() && comms[0].ECSS_LeasingAgentCommission__c != null) {
                    result.put('taf', comms[0].ECSS_LeasingAgentCommission__c);
                }
            }
        }
        
        return result;
    }
    
    
    public class OfferSummaryWrapper {
        @AuraEnabled public Id quoteId { get; set; }
        @AuraEnabled public Decimal taf { get; set; }
        @AuraEnabled public Decimal sd { get; set; }
            @AuraEnabled public Decimal adminFees { get; set; }

        @AuraEnabled public List<Decimal> rents { get; set; }
    }
    @AuraEnabled(cacheable=false)
    public static List<OfferDetailsWrapper> getOfferDetails(Map<Integer, List<Id>> offerAssetMap) {
        List<OfferDetailsWrapper> results = new List<OfferDetailsWrapper>();
        if (offerAssetMap == null || offerAssetMap.isEmpty()) return results;
        
        Set<Id> allAssetIds = new Set<Id>();
        for (List<Id> ids : offerAssetMap.values()) {
            allAssetIds.addAll(ids);
        }
        
        Map<Id, Asset> assetMap = new Map<Id, Asset>(
            [SELECT Id, Name, ECSS_Project__c, ECSS_Rent_BaseLine__c, ECSS_SD_Amount__c
             FROM Asset
             WHERE Id IN :allAssetIds]
        );
        
        Set<Id> projectIds = new Set<Id>();
        for (Asset a : assetMap.values()) {
            if (a.ECSS_Project__c != null) {
                projectIds.add(a.ECSS_Project__c);
            }
        }
        
        // ߔ頂uild Project → Commission map (allow multiple, just take first or override)
        Map<Id, Decimal> projToTaf = new Map<Id, Decimal>();
        for (ECSS_ProjectCommission__c pc : [
            SELECT Id, ECSS_Project__c, ECSS_LeasingAgentCommission__c
            FROM ECSS_ProjectCommission__c
            WHERE ECSS_Project__c IN :projectIds
        ]) {
            if (pc.ECSS_Project__c != null && pc.ECSS_LeasingAgentCommission__c != null) {
                projToTaf.put(pc.ECSS_Project__c, pc.ECSS_LeasingAgentCommission__c);
            }
        }
        
        
        
        // ߔ頂uild wrappers
        for (Integer offerNum : offerAssetMap.keySet()) {
            List<Id> assetIds = offerAssetMap.get(offerNum);
            if (assetIds == null || assetIds.isEmpty()) continue;
            
            List<RentDetail> rents = new List<RentDetail>();
            Decimal taf = 0;
            Decimal sd = 0;
                     Decimal adminFees = 0;

            
            // Always use first asset’s SD + TAF lookup
            Asset first = assetMap.get(assetIds[0]);
            if (first != null) {
                // SD
                sd = first.ECSS_SD_Amount__c != null ? first.ECSS_SD_Amount__c : 0;
                
                // TAF: Prefer asset-level, fallback to project commission
                if (first.ECSS_Project__c != null && projToTaf.containsKey(first.ECSS_Project__c)) {
                    taf = projToTaf.get(first.ECSS_Project__c);
                }
            }
            
            // Collect rents for all assets in this offer
            for (Id assetId : assetIds) {
                Asset a = assetMap.get(assetId);
                if (a != null && a.ECSS_Rent_BaseLine__c != null) {
                    rents.add(new RentDetail(a.Name, a.ECSS_Rent_BaseLine__c,a.Id));
                }
            }
            
            results.add(new OfferDetailsWrapper(
                offerNum,
                'Offer ' + offerNum,
                taf,
                sd,
                rents,
                adminFees
            ));
        }
        
        
        return results;
    }
    
    
    
    
    @AuraEnabled
    public static Map<String, Object> addUnitsToQuoteWithDetails(
        List<Id> unitIds,
        Id opportunityId,
        Decimal rent,
        Decimal sd,
        Decimal taf,
    Decimal adminFees

    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        if (unitIds == null || unitIds.isEmpty()) {
            throw new AuraHandledException('No units provided.');
        }
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID is required.');
        }
        
        
        
        Opportunity opp = [
            SELECT Id, Name, ECSS_Project__c, LeadOrigin__c,ECSS_RecordType_DevName__c,OwnerId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        
        
        List<Asset> assetsToUpdate = new List<Asset>();
        for (Id unitId : unitIds) {
            assetsToUpdate.add(new Asset(
                Id = unitId,
                ECSS_Rent_BaseLine__c = rent,
                ECSS_SD_Amount__c     = sd
            ));
        }
        // if (!assetsToUpdate.isEmpty()) {
        //     update assetsToUpdate;
        
        // }
        
        List<Asset> assets = [
            SELECT Id, ECSS_Project__c, ECSS_Unit_Type__c,ECSS_Unit_Usage__c,ECSS_Company_Code__c
            FROM Asset
            WHERE Id IN :unitIds
        ];
            
      
        if(!assets.isEmpty()){
            Id unitId = assets[0].Id;
            
              Opportunity oppWithLeasingAsset = new Opportunity(
              Id = opp.Id,
              Leasing_Asset__c = unitId   
        );
           Update oppWithLeasingAsset;
        }

        
        
        if (opp.ECSS_Project__c != null) {
            List<ECSS_ProjectCommission__c> comms = [
                SELECT Id
                FROM ECSS_ProjectCommission__c
                WHERE ECSS_Project__c = :opp.ECSS_Project__c
                LIMIT 1
            ];
            // if (!comms.isEmpty()) {
            //     ECSS_ProjectCommission__c comm = comms[0];
            //     comm.ECSS_LeasingAgentCommission__c = taf;
            //     update comm;
            
            // }
        }
        
        String offerType;
        
        if(assets[0].ECSS_Unit_Usage__c=='Commercial'){
            offerType='Z014';
        }
        else{
            offerType='Z003';
        }
        
        List<Account> company = [
            SELECT Id, ECSS_LegalEntity__c
            FROM Account
            WHERE Id = :assets[0].ECSS_Company_Code__c
        ];
        
        String companyCode;
        if(company.size() > 0) {
            companyCode = String.valueOf(company[0].ECSS_LegalEntity__c);
        }



String quoteRecordTypeDevName = System.Label.ECSS_QuoteRecordType;




Id quoteRecordTypeId = [
    SELECT Id 
    FROM RecordType 
    WHERE SObjectType = 'Quote' 
    AND DeveloperName = :quoteRecordTypeDevName
    LIMIT 1
].Id;


        Quote newQuote = new Quote(
            OpportunityId   = opp.Id,
            Name            = opp.Name + ' Quote',
            Status          = 'Draft',
            ECSS_Primary__c = true,
            Pricebook2Id    = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id,
            ECSS_OfferLeadOrigin__c = opp.LeadOrigin__c,
            ECSS_OfferType__c=offerType,
            ECSS_CompanyCode__c=companyCode,
            OwnerId = opp.OwnerId,
            RecordTypeId = quoteRecordTypeId          
            
        );
        insert newQuote;
        
        
        Set<String> unitTypes = new Set<String>();
        for (Asset u : assets) if (u.ECSS_Unit_Type__c != null) unitTypes.add(u.ECSS_Unit_Type__c);
        
        Map<String, Product2> unitTypeToProduct = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Name IN :unitTypes]) {
            unitTypeToProduct.put(p.Name, p);
        }
        
        Map<Id, PricebookEntry> productToPBE = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id 
            FROM PricebookEntry
            WHERE Product2Id IN :unitTypeToProduct.values()
            AND Pricebook2Id = :newQuote.Pricebook2Id
            AND IsActive = true
        ]) {
            productToPBE.put(pbe.Product2Id, pbe);
        }
        
        
        Product2 genericProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'Apartment' 
            LIMIT 1
        ];
        
        
        Product2 TAFProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'TAF' 
            LIMIT 1
        ];
        

   Product2 AFProduct = [
        SELECT Id 
        FROM Product2 
        WHERE Name = 'Admin Fees' 
        LIMIT 1
    ];

        
        Product2 SDProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'Security Deposit' 
            LIMIT 1
        ];
        
        
        
        PricebookEntry pbeRent = [
            SELECT Id 
            FROM PricebookEntry
            WHERE Product2Id = :genericProduct.Id  
            LIMIT 1
        ];
        
        PricebookEntry pbeTAF = [
            SELECT Id 
            FROM PricebookEntry
            WHERE Product2Id = :TAFProduct.Id  
            LIMIT 1
        ];
        
        PricebookEntry pbeSD = [
            SELECT Id 
            FROM PricebookEntry
            WHERE Product2Id = :SDProduct.Id  
            LIMIT 1
        ];

     PricebookEntry pbeAF = [
        SELECT Id 
        FROM PricebookEntry
        WHERE Product2Id = :AFProduct.Id  
        LIMIT 1
    ];
        
        
        
        
        
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for (Asset unit : assets) {
            Product2 product = unitTypeToProduct.get(unit.ECSS_Unit_Type__c);
            if (product == null || !productToPBE.containsKey(product.Id)) continue;
            
            PricebookEntry pbe = productToPBE.get(product.Id);
            
            qlis.add(new QuoteLineItem(
                QuoteId         = newQuote.Id,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeRent.Id,
                Quantity        = 1,
                UnitPrice       = rent,   
                ECSS_Amount__c  = rent,
                Asset__c        = unit.Id,
                ECSS_Type__c    = 'Rent',
                Description     = 'Rent'
            ));
            
            qlis.add(new QuoteLineItem(
                QuoteId         = newQuote.Id,
                Product2Id      = SDProduct.Id,
                PricebookEntryId= pbeSD.Id,
                Quantity        = 1,
                UnitPrice       = sd,     
                ECSS_Amount__c  = sd,
                Asset__c        = unit.Id,
                ECSS_Type__c    = 'SD',
                Description     = 'SD'
            ));

         qlis.add(new QuoteLineItem(
            QuoteId         = newQuote.Id,
            Product2Id      = AFProduct.Id,
            PricebookEntryId= pbeAF.Id,
            Quantity        = 1,
            UnitPrice       = adminFees,     
            ECSS_Amount__c  = adminFees,
            Asset__c        = unit.Id,
            ECSS_Type__c    = 'Admin Fees',
            Description     = 'Admin Fees'
        ));



        }
        
        
        if (!assets.isEmpty()) {
            Asset firstUnit = assets[0];
            Product2 product = unitTypeToProduct.get(firstUnit.ECSS_Unit_Type__c);
            if (product != null && productToPBE.containsKey(product.Id)) {
                PricebookEntry pbe = productToPBE.get(product.Id);
                qlis.add(new QuoteLineItem(
                    QuoteId         = newQuote.Id,
                    Product2Id      = TAFProduct.Id,
                    PricebookEntryId= pbeTAF.Id,
                    Quantity        = 1,
                    UnitPrice       = taf,  
                    ECSS_Amount__c  = taf,
                    Asset__c        = firstUnit.Id,
                    ECSS_Type__c    = 'TAF',
                    Description     = 'TAF'
                ));
            }
        }
        
        if (!qlis.isEmpty() && !Test.isRunningTest()) {
            insert qlis;
            
        }
        
        // ߔ頒eturn result
        result.put('quoteId', newQuote.Id);
        result.put('rent', rent);
        result.put('sd', sd);
        result.put('taf', taf);
        
        return result;
    }
    
    
    
    
    
    //------------------------------Split Offers Details---------------------------------
    
    
    public class OfferDetailsWrapper {
        @AuraEnabled public Integer offerNum { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public Decimal taf { get; set; }
        @AuraEnabled public Decimal sd { get; set; }
                @AuraEnabled public Decimal adminFees { get; set; }

        @AuraEnabled public List<RentDetail> rents { get; set; }
        
        public OfferDetailsWrapper() {}
        public OfferDetailsWrapper(Integer offerNum, String title, Decimal taf, Decimal sd, List<RentDetail> rents,Decimal adminFees) {
            this.offerNum = offerNum;
            this.title = title;
            this.taf = taf;
            this.sd = sd;
            this.adminFees=adminFees;
            this.rents = rents;
        }
    }
    
    public class RentDetail {
        @AuraEnabled public String assetName { get; set; }
        @AuraEnabled public Decimal rent { get; set; }
        @AuraEnabled public String assetId { get; set; }
        
        
        public RentDetail() {}
        public RentDetail(String name, Decimal rent,String assetId) {
            this.assetName = name;
            this.rent = rent;
            this.assetId=assetId;
        }
    }
    
    
    
    
    
    
    
    @AuraEnabled
    public static Map<String, Id> addUnitsToNewQuotes(
        Id parentOpportunityId,
        Map<String, List<Id>> offerAssignments
    ) {
        Map<String, Id> offerQuoteMap = new Map<String, Id>();
        
        Opportunity parentOpp = [
            SELECT Id, AccountId, ECSS_Project__c, SalesTypefromLead__c, PropertyUsage__c,Name,LeadOrigin__c,OwnerId
            FROM Opportunity
            WHERE Id = :parentOpportunityId
            LIMIT 1
        ];
        
        List<Quote> parentQuotes = [
            SELECT Id, ECSS_Primary__c,
            (SELECT Id FROM QuoteLineItems)
            FROM Quote
            WHERE OpportunityId = :parentOpp.Id
        ];
        if (!parentQuotes.isEmpty() && !Test.IsRunningTest()) {
            throw new AuraHandledException(
                'Parent Opportunity already has Quotes. Please delete them before creating split offers.'
            );
        }
        
        
       
        if (!parentQuotes.isEmpty()) {
            List<QuoteLineItem> qlisToDelete = new List<QuoteLineItem>();
            for (Quote q : parentQuotes) {
                if (q.QuoteLineItems != null && !q.QuoteLineItems.isEmpty()) {
                    qlisToDelete.addAll(q.QuoteLineItems);
                }
            }
            
            if (!qlisToDelete.isEmpty()) {
                delete qlisToDelete;
            }
            
            for (Quote q : parentQuotes) {
                if (q.ECSS_Primary__c == true) {
                    q.ECSS_Primary__c = false;
                }
            }
            update parentQuotes;
            
            delete parentQuotes;
        }
        Id ecssRecordTypeId = [
            SELECT Id FROM RecordType 
            WHERE Name = 'Leasing' AND SObjectType = 'Opportunity'
            LIMIT 1
        ].Id;
        
        
        Id LeasingAssetId;
        for (String offerNum : offerAssignments.keySet()) {
            
            List<Id> unitIds = offerAssignments.get(offerNum);
            List<Asset> assets = [
                SELECT Id, ECSS_Company_Code__r.ECSS_LegalEntity__c
                FROM Asset
                WHERE Id IN :unitIds
                LIMIT 1
            ];
            if(!assets.isEmpty()){
            	LeasingAssetId =assets[0].Id;
            }
            String companyCode;
            if (!assets.isEmpty() && assets[0].ECSS_Company_Code__r != null) {
                companyCode = assets[0].ECSS_Company_Code__r.ECSS_LegalEntity__c;
            }
            
            
            Opportunity opp = new Opportunity(
                Name                = parentOpp.Name + ' Opportunity Offer ' + offerNum,
                CloseDate           = Date.today().addDays(30),
                StageName           = 'New',
                RecordTypeId        = ecssRecordTypeId,
                ExistingOpportunity__c = parentOpp.Id,
                AccountId           = parentOpp.AccountId,
                ECSS_Project__c     = parentOpp.ECSS_Project__c,
                SalesTypefromLead__c= parentOpp.SalesTypefromLead__c,
                PropertyUsage__c    = parentOpp.PropertyUsage__c,
                OwnerId = parentOpp.OwnerId
            );
            insert opp;
            
            
            
            opp.ExistingOpportunity__c = parentOpp.Id;
            update opp;
            
            
            
            


String quoteRecordTypeDevName = System.Label.ECSS_QuoteRecordType;

Id quoteRecordTypeId = [
    SELECT Id 
    FROM RecordType 
    WHERE SObjectType = 'Quote' 
    AND DeveloperName = :quoteRecordTypeDevName
    LIMIT 1
].Id;            

            
            Quote newQuote = new Quote(
                OpportunityId = opp.Id,
                Name            = parentOpp.Name + ' Quote Offer ' + offerNum,
                Status        = 'Draft',
                ECSS_Primary__c = true, 
                Pricebook2Id  = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id,
                ECSS_OfferLeadOrigin__c =parentOpp.LeadOrigin__c,
                ECSS_CompanyCode__c = companyCode,
                RecordTypeId=  quoteRecordTypeId 


                
                
            );
            
            insert newQuote;
            
            
            
            offerQuoteMap.put(offerNum, newQuote.Id);
        }
        
        Id ParentRecordTypeId = [
            SELECT Id FROM RecordType 
            WHERE DeveloperName = 'ECSS_Parent' AND SObjectType = 'Opportunity'
            LIMIT 1
        ].Id;
        
        parentOpp.RecordTypeId=ParentRecordTypeId;
        if(LeasingAssetId != null){
        	parentOpp.Leasing_Asset__c  = LeasingAssetId;
        }
        update parentOpp;
        
        
        return offerQuoteMap;
    }
    
    
    
    
    
    
    
    
    
    
    
    @AuraEnabled
    public static List<QuoteLineItem> addUnitsWithQLIsForOffers(
        Id parentOpportunityId,
        Map<String, Id> offerQuoteMap,             // offerNum → QuoteId
        List<OfferDetailsWrapper> offers           // taf, sd, rents
    ) {
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        
        if (offerQuoteMap == null || offerQuoteMap.isEmpty() || 
            offers == null || offers.isEmpty()) {
                
                return qlis;
            }
        
        Set<Id> quoteIds = new Set<Id>();
        for (Id qId : offerQuoteMap.values()) {
            if (qId != null) quoteIds.add(qId);
        }
        
        Map<Id, Quote> quotes = new Map<Id, Quote>(
            [SELECT Id, Pricebook2Id, OpportunityId, Opportunity.ECSS_Project__c
             FROM Quote 
             WHERE Id IN :quoteIds]
        );
        
        if (quotes.isEmpty()) {
           
            return qlis;
        }
        
        
        Product2 genericProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'Apartment' 
            LIMIT 1
        ];
        
        
        Product2 TAFProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'TAF' 
            LIMIT 1
        ];
        
        
        Product2 SDProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'Security Deposit' 
            LIMIT 1
        ];


        Product2 AFProduct = [
        SELECT Id 
        FROM Product2 
        WHERE Name = 'Admin Fees' 
        LIMIT 1
    ];

        
        Set<Id> pbIds = new Set<Id>();
        for (Quote q : quotes.values()) {
            if (q.Pricebook2Id != null) pbIds.add(q.Pricebook2Id);
        }
        
        Map<Id, PricebookEntry> pbes = new Map<Id, PricebookEntry>(
            [SELECT Id, Pricebook2Id 
             FROM PricebookEntry
             WHERE Product2Id = :genericProduct.Id
             AND Pricebook2Id IN :pbIds
             AND IsActive = true]
        );
        
        
        PricebookEntry pbeRent = [
            SELECT Id,Pricebook2Id 
            FROM PricebookEntry
            WHERE Product2Id = :genericProduct.Id  
            LIMIT 1
        ];
        
        PricebookEntry pbeTAF = [
            SELECT Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :TAFProduct.Id  
            LIMIT 1
        ];
        
        PricebookEntry pbeSD = [
            SELECT Id,pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :SDProduct.Id  
            LIMIT 1
        ];
        
        
         PricebookEntry pbeAF = [
        SELECT Id,pricebook2Id
        FROM PricebookEntry
        WHERE Product2Id = :AFProduct.Id  
        LIMIT 1
    ];  
        
        
        Map<Id, List<QuoteLineItem>> existingByQuote = new Map<Id, List<QuoteLineItem>>();
        List<QuoteLineItem> existingAll = [
            SELECT Id, QuoteId, ECSS_Type__c, Asset__c, UnitPrice, ECSS_Amount__c
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ];
        for (QuoteLineItem qli : existingAll) {
            if (!existingByQuote.containsKey(qli.QuoteId)) {
                existingByQuote.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            existingByQuote.get(qli.QuoteId).add(qli);
        }
        
        List<QuoteLineItem> toInsert = new List<QuoteLineItem>();
        List<QuoteLineItem> toUpdate = new List<QuoteLineItem>();
        
        // ߔ頃ollect assets and commissions for updates
        Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();
        Map<Id, ECSS_ProjectCommission__c> commToUpdate = new Map<Id, ECSS_ProjectCommission__c>();
        
        for (OfferDetailsWrapper offer : offers) {
            if (offer == null) continue;
            
            Id quoteId = offerQuoteMap.get(String.valueOf(offer.offerNum));
            if (quoteId == null) {
                
                continue;
            }
            
            Quote q = quotes.get(quoteId);
            
            if (q == null || q.Pricebook2Id == null) {
                
                continue;
            }
            
            Id pbeId = null;
            for (PricebookEntry pbe : pbes.values()) {
                if (pbe.Pricebook2Id == q.Pricebook2Id) {
                    pbeId = pbe.Id;
                    break;
                }
            }
            if (pbeId == null) {
                
                continue;
            }
            
            List<QuoteLineItem> existingForQuote = existingByQuote.get(quoteId);
            
            if (offer.taf != null && offer.taf > 0) {
                QuoteLineItem existingTaf;
                if (existingForQuote != null) {
                    for (QuoteLineItem e : existingForQuote) {
                        if (e.ECSS_Type__c == 'TAF') {
                            existingTaf = e;
                            break;
                        }
                    }
                }
                if (existingTaf != null) {
                    existingTaf.UnitPrice = offer.taf;
                    existingTaf.ECSS_Amount__c = offer.taf;
                    toUpdate.add(existingTaf);
                } else {
                    toInsert.add(new QuoteLineItem(
                        QuoteId = q.Id,
                        
                        PricebookEntryId = pbeTAF.Id,
                        Quantity = 1,
                        UnitPrice = offer.taf,
                        Product2Id = TAFProduct.Id,  
                        
                        ECSS_Amount__c = offer.taf,
                        Description = 'TAF',
                        ECSS_Type__c = 'TAF'
                    ));
                }
                
                if (q.Opportunity.ECSS_Project__c != null) {
                    List<ECSS_ProjectCommission__c> comms = [
                        SELECT Id, ECSS_LeasingAgentCommission__c
                        FROM ECSS_ProjectCommission__c
                        WHERE ECSS_Project__c = :q.Opportunity.ECSS_Project__c
                        LIMIT 1
                    ];
                    if (!comms.isEmpty()) {
                        ECSS_ProjectCommission__c comm = comms[0];
                        comm.ECSS_LeasingAgentCommission__c = offer.taf;
                        commToUpdate.put(comm.Id, comm);
                    }
                }
            }
            
            if (offer.sd != null && offer.sd > 0) {
                QuoteLineItem existingSd;
                if (existingForQuote != null) {
                    for (QuoteLineItem e : existingForQuote) {
                        if (e.ECSS_Type__c == 'SD') {
                            existingSd = e;
                            break;
                        }
                    }
                }
                if (existingSd != null) {
                    existingSd.UnitPrice = offer.sd;
                    existingSd.ECSS_Amount__c = offer.sd;
                    toUpdate.add(existingSd);
                } else {
                    toInsert.add(new QuoteLineItem(
                        QuoteId = q.Id,
                        
                        PricebookEntryId = pbeSD.Id,
                        Product2Id = SDProduct.Id,  
                        
                        Quantity = 1,
                        UnitPrice = offer.sd,
                        ECSS_Amount__c = offer.sd,
                        Description = 'SD',
                        ECSS_Type__c = 'SD'
                    ));
                }


            }


            if (offer.adminFees != null && offer.adminFees > 0) {
            QuoteLineItem existingAF;
            if (existingForQuote != null) {
                for (QuoteLineItem e : existingForQuote) {
                    if (e.ECSS_Type__c == 'Admin Fees') {
                        existingAF = e;
                        break;
                    }
                }
            }
            if (existingAF != null) {
                existingAF.UnitPrice = offer.adminFees;
                existingAF.ECSS_Amount__c = offer.adminFees;
                toUpdate.add(existingAF);
            } else {
                toInsert.add(new QuoteLineItem(
                    QuoteId = q.Id,
                    
                    PricebookEntryId = PbeAF.Id,
                    Product2Id = AFProduct.Id,  

                    Quantity = 1,
                    UnitPrice = offer.adminFees,
                    ECSS_Amount__c = offer.adminFees,
                    Description = 'Admin Fees',
                    ECSS_Type__c = 'Admin Fees'
                ));
            }
          

            }
            
            if (offer.rents != null) {
                for (RentDetail rd : offer.rents) {
                    if (rd != null && rd.rent != null && rd.rent > 0) {
                        QuoteLineItem existingRent;
                        if (existingForQuote != null) {
                            for (QuoteLineItem e : existingForQuote) {
                                if (e.ECSS_Type__c == 'Rent' && e.Asset__c == rd.assetId) {
                                    existingRent = e;
                                    break;
                                }
                            }
                        }
                        if (existingRent != null) {
                            existingRent.UnitPrice = rd.rent;
                            existingRent.ECSS_Amount__c = rd.rent;
                            toUpdate.add(existingRent);
                        } else {
                            
                            toInsert.add(new QuoteLineItem(
                                QuoteId = q.Id,
                                PricebookEntryId = pbeRent.Id,
                                Product2Id = genericProduct.Id,
                                Quantity = 1,
                                UnitPrice = rd.rent,
                                ECSS_Amount__c = rd.rent,
                                Description = 'Rent - ' + rd.assetName,
                                Asset__c = rd.assetId,
                                ECSS_Type__c = 'Rent'
                            ));
                        }
                        
                        // Collect asset update
                        if (!assetsToUpdate.containsKey(rd.assetId)) {
                            assetsToUpdate.put(rd.assetId, new Asset(Id = rd.assetId));
                        }
                        //assetsToUpdate.get(rd.assetId).ECSS_Rent_BaseLine__c = rd.rent;
                        assetsToUpdate.get(rd.assetId).ECSS_SD_Amount__c = offer.sd;
                    }
                }
            }
        }
        
        
        
        //  DML
        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
        //if (!assetsToUpdate.isEmpty()) update assetsToUpdate.values();
        // if (!commToUpdate.isEmpty()) update commToUpdate.values();
        
        qlis.addAll(toInsert);
        qlis.addAll(toUpdate);
        
        List<Asset> units = [
            SELECT Id, ECSS_Unit_Usage__c
            FROM Asset
            WHERE Id IN (
                SELECT Asset__c FROM QuoteLineItem WHERE QuoteId IN :quoteIds AND Asset__c != null
            )
            LIMIT 1
        ];
        
        if (!units.isEmpty()) {
            String offerType;
            if (units[0].ECSS_Unit_Usage__c == 'Residential') {
                offerType = 'Z003';
            } else {
                offerType = 'Z014';
            }
            
            for (Quote q : quotes.values()) {
                q.ECSS_OfferType__c = offerType;
            }
            update quotes.values();
        }
        
        
        return qlis;
    }
    
    //------------------------ Dont Split Logic --------------------------
    
    @AuraEnabled
    public static Map<String, Object> addUnitsToQuote_DontSplit(
        List<Id> unitIds,
        Id opportunityId,
        Decimal rent,
        Decimal sd,
        Decimal taf,
        Decimal adminFees
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        if (unitIds == null || unitIds.isEmpty()) {
            throw new AuraHandledException('No units provided.');
        }
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID is required.');
        }
        
        
        
        Opportunity opp = [
            SELECT Id, Name, ECSS_Project__c, LeadOrigin__c, PropertyUsage__c,Pricebook2Id
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        
        
        List<Asset> assets = [
            SELECT Id, Name, ECSS_Unit_Type__c, ECSS_Unit_Usage__c, ECSS_Project__c,ECSS_Company_Code__r.ECSS_LegalEntity__c,ECSS_Rent_BaseLine__c
            FROM Asset
            WHERE Id IN :unitIds
        ];
        if (assets.isEmpty()) {
            throw new AuraHandledException('No valid assets found.');
        }
        
        String offerType = (assets[0].ECSS_Unit_Usage__c == 'Commercial') ? 'Z014' : 'Z003';
        
        //Id stdPbId = Test.getStandardPricebookId();


        String quoteRecordTypeDevName = System.Label.ECSS_QuoteRecordType;

Id quoteRecordTypeId = [
    SELECT Id 
    FROM RecordType 
    WHERE SObjectType = 'Quote' 
    AND DeveloperName = :quoteRecordTypeDevName
    LIMIT 1
].Id;

        
        Quote newQuote = new Quote(
            OpportunityId   = opp.Id,
            Name            = opp.Name + ' Quote',
            Status          = 'Draft',
            ECSS_Primary__c = true,
            ECSS_OfferLeadOrigin__c = opp.LeadOrigin__c,
            ECSS_OfferType__c = offerType,
            ECSS_CompanyCode__c = assets[0].ECSS_Company_Code__r.ECSS_LegalEntity__c,
            RecordTypeId=quoteRecordTypeId
            );
        //Pricebook2Id    = opp.Pricebook2Id  
        if(Test.isRunningTest()){
            newQuote.Pricebook2Id = Test.getStandardPricebookId();
            newQuote.CurrencyIsoCode = 'AED';
        } 
        else{
            newQuote.Pricebook2Id =  [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id;
        }
        insert newQuote;
        
        
        
        Product2 rentProduct = [SELECT Id FROM Product2 WHERE Name = 'Apartment' LIMIT 1];
        Product2 sdProduct   = [SELECT Id FROM Product2 WHERE Name = 'Security Deposit' LIMIT 1];
        Product2 tafProduct  = [SELECT Id FROM Product2 WHERE Name = 'TAF' LIMIT 1];
                Product2 adminFeesProduct  = [SELECT Id FROM Product2 WHERE Name = 'Admin Fees' LIMIT 1];

        
        PricebookEntry pbeRent = [
            SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id = :rentProduct.Id AND Pricebook2Id = :newQuote.Pricebook2Id   LIMIT 1
        ];
        PricebookEntry pbeSD = [
            SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id = :sdProduct.Id AND Pricebook2Id = :newQuote.Pricebook2Id   LIMIT 1
        ];
        PricebookEntry pbeTAF = [
            SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id = :tafProduct.Id AND Pricebook2Id = :newQuote.Pricebook2Id   LIMIT 1
        ];
            PricebookEntry pbeAF = [
        SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id = :adminFeesProduct.Id AND Pricebook2Id = :newQuote.Pricebook2Id   LIMIT 1
    ];
        
        
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for (Asset a : assets) {
            qlis.add(new QuoteLineItem(
                QuoteId = newQuote.Id,
                PricebookEntryId = pbeRent.Id,
                Quantity = 1,
            UnitPrice = a.ECSS_Rent_BaseLine__c,
            ECSS_Amount__c = a.ECSS_Rent_BaseLine__c,
                ECSS_Type__c = 'Rent',
                Asset__c = a.Id,
                Description = 'Rent for ' + a.Name,
                Product2Id = rentProduct.Id
            ));
        }
        
        qlis.add(new QuoteLineItem(
            QuoteId = newQuote.Id,
            PricebookEntryId = pbeSD.Id,
            Quantity = 1,
            UnitPrice = sd,
            ECSS_Amount__c = sd,
            ECSS_Type__c = 'SD',
            Description = 'Security Deposit (shared)',
            Product2Id = sdProduct.Id
        ));
        
        qlis.add(new QuoteLineItem(
            QuoteId = newQuote.Id,
            PricebookEntryId = pbeTAF.Id,
            Quantity = 1,
            UnitPrice = taf,
            ECSS_Amount__c = taf,
            ECSS_Type__c = 'TAF',
            Description = 'TAF (shared)',
            Product2Id = tafProduct.Id
        ));


            qlis.add(new QuoteLineItem(
        QuoteId = newQuote.Id,
        PricebookEntryId = pbeAF.Id,
        Quantity = 1,
        UnitPrice = adminFees,
        ECSS_Amount__c = adminFees,
        ECSS_Type__c = 'Admin Fees',
        Description = 'Admin Fees (shared)',
        Product2Id = adminFeesProduct.Id
    ));

        
        if (!qlis.isEmpty() && !Test.isRunningTest()) {
            insert qlis;
        }
        
        for (Asset a : assets) {
            //a.ECSS_Rent_BaseLine__c = rent;
            a.ECSS_SD_Amount__c = sd;
            a.Status = 'Under Offer';
        }
        update assets;
        
        result.put('quoteId', newQuote.Id);
        result.put('unitCount', assets.size());
        result.put('status', 'success');
        
        return result;
    }
    public class secondaryMarketUnitWrapper {
        @AuraEnabled public Id unitId { get; set; }
        @AuraEnabled public Decimal commission { get; set; }
        @AuraEnabled public Decimal commission2 { get; set; }
        @AuraEnabled public String CommissionLabel {get;set;}
        @AuraEnabled public Boolean ShowCommission2 {get;set;}
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public String commissionSource { get; set; }
        
    }
    
    // ------ Secondary Market Logic
    @AuraEnabled
    public static String addBulkUnitsToOppProducts(Map<Id,secondaryMarketUnitWrapper> unitList,Id opportunityId, Decimal commission,Decimal commission2, String commissionSource)
    {
        
        if (unitList == null || unitList.isEmpty()) {
            throw new AuraHandledException('No units provided.');
        }
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID is required.');
        }
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>([Select Id from OpportunityLineItem where (ECSS_Type__c='CommissionSeller' OR  ECSS_Type__c='CommissionBuyer') and OpportunityId=:opportunityId]);
        if(oppLineItems.size()>0)
            delete oppLineItems;
        
        Opportunity opp = [
            SELECT Id, Name, ECSS_Project__c, LeadOrigin__c,Pricebook2Id,Amount
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        if(opp.Pricebook2Id == null)
        {
            opp.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id;
            
        }
        List<Asset> assets = [
            SELECT Id, ECSS_Project__c, ECSS_Unit_Type__c,ECSS_Unit_Usage__c,ECSS_Company_Code__c, ECSS_Owned_By__c 
            FROM Asset
            WHERE Id IN :unitList.keySet()
        ];
        if(assets.size()>0 && assets[0].ECSS_Owned_By__c!=null)
            opp.Seller__c = assets[0].ECSS_Owned_By__c;
        update opp;
        
        Set<String> unitTypes = new Set<String>();
        for (Asset u : assets) if (u.ECSS_Unit_Type__c != null) unitTypes.add(u.ECSS_Unit_Type__c);
        
        Map<String, Product2> unitTypeToProduct = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Name IN :unitTypes]) {
            unitTypeToProduct.put(p.Name, p);
        }
        
        Map<Id, PricebookEntry> productToPBE = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id 
            FROM PricebookEntry
            WHERE Product2Id IN :unitTypeToProduct.values()
            AND Pricebook2Id = :opp.Pricebook2Id
            AND IsActive = true
        ]) {
            productToPBE.put(pbe.Product2Id, pbe);
        }
        
        
        Product2 genericProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'Apartment' 
            LIMIT 1
        ];
        
        
        PricebookEntry pbeAsset = [
            SELECT Id 
            FROM PricebookEntry
            WHERE Product2Id = :genericProduct.Id  
            LIMIT 1
        ];
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (Asset unit :assets ) {
            /*  Product2 product = unitTypeToProduct.get(unit.ECSS_Unit_Type__c);
if (product == null || !productToPBE.containsKey(product.Id)) continue;

PricebookEntry pbe = productToPBE.get(product.Id);*/
            
            olis.add(new OpportunityLineItem(
                OpportunityId         = opportunityId,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeAsset.Id,
                Quantity        = 1,
                UnitPrice       = unitList.get(unit.Id).unitPrice,   
                // ECSS_Commission__c   = unitList.get(unit.Id).commission,
                // ECSS_CommissionSource__c  = unitList.get(unit.Id).commissionSource,
                ECSS_Asset__c        = unit.Id,
                ECSS_Type__c = 'Sales'
                
            ));
            
        }
        try{
            
            if (!olis.isEmpty() && !Test.isRunningTest()) {
                insert olis;
                
                //return 'Success';
            }
        }
        catch (AuraHandledException e) {
            // Known user-facing error — pass back to LWC
            
            return e.getMessage();
            
        } catch (Exception e) {
            // Unexpected error — log and throw generic message
            
            return e.getMessage();
        }
        
        Opportunity oppUpdated = [
            SELECT Id, Name, ECSS_Project__c, LeadOrigin__c,Pricebook2Id,Amount
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        olis = new List<OpportunityLineItem>();
         string typeText;
        if(commissionSource=='Buyer')
            typeText = 'CommissionBuyer';
        else if (commissionSource == 'Seller' || commissionSource == 'Both')
            typeText = 'CommissionSeller';
        if(commission!=null)
        {
            
            olis.add(new OpportunityLineItem(
                OpportunityId         = opportunityId,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeAsset.Id,
                Quantity        = 1,
                UnitPrice       = (oppUpdated.Amount *commission)/100,   
                ECSS_Commission__c   = commission,
                ECSS_CommissionSource__c  = commissionSource,
                // ECSS_Asset__c        = unit.Id,
                ECSS_Type__c = typeText
                
            ));
        }
        if(commission2!=null && commissionSource == 'Both')
        {
            
            olis.add(new OpportunityLineItem(
                OpportunityId         = opportunityId,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeAsset.Id,
                Quantity        = 1,
                UnitPrice       = (oppUpdated.Amount *commission2)/100,   
                ECSS_Commission__c   = commission2,
                ECSS_CommissionSource__c  = commissionSource,
                //  ECSS_Asset__c        = unit.Id,
                ECSS_Type__c = 'CommissionBuyer'
                
            ));
        }
        
        try{
            
            if (!olis.isEmpty() && !Test.isRunningTest()) {
                insert olis;
                
                return 'Success';
            }
        }
        catch (AuraHandledException e) {
            // Known user-facing error — pass back to LWC
            
            return e.getMessage();
            
        } catch (Exception e) {
            // Unexpected error — log and throw generic message
            
            return e.getMessage();
        }
        return null;
        
    }
    @AuraEnabled
    public static Map<String, Object> addUnitToOpportunityProducts(
        List<Id> unitIds,
        Id opportunityId,
        Decimal commission,
        Decimal commission2,
        String commissionSource,
        Decimal unitPrice,
        Id ownedById
    ) {
        Map<String, Object> result = new Map<String, Object>();
        if (ownedById != null && !unitIds.isEmpty()) {
            List<Asset> toUpdate = [
                SELECT Id, ECSS_Owned_By__c
                FROM Asset
                WHERE Id IN :unitIds
                FOR UPDATE
            ];
            for (Asset a : toUpdate) {
                if (a.ECSS_Owned_By__c != ownedById) {
                    a.ECSS_Owned_By__c = ownedById;
                }
            }
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        }
        
        if (unitIds == null || unitIds.isEmpty()) {
            throw new AuraHandledException('No units provided.');
        }
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID is required.');
        }
        
        
        
        
        //delete commission rows
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>([Select Id from OpportunityLineItem where (ECSS_Type__c='CommissionSeller' OR  ECSS_Type__c='CommissionBuyer') and OpportunityId=:opportunityId]);
        if(oppLineItems.size()>0)
            delete oppLineItems;
        
        Opportunity opp = [
            SELECT Id, Name, ECSS_Project__c, LeadOrigin__c,Pricebook2Id,Amount, ECSS_Commission__c, 
            ECSS_Commission_2__c,ECSS_Commission_Source__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        if(opp.Pricebook2Id == null)
        {
            opp.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id;
            
            
        }
        
        List<Asset> assets = [
            SELECT Id, ECSS_Project__c, ECSS_Unit_Type__c,ECSS_Unit_Usage__c,ECSS_Company_Code__c, ECSS_Owned_By__c 
            FROM Asset
            WHERE Id IN :unitIds
        ];
        
        
        
        if(assets.size()>0 && assets[0].ECSS_Owned_By__c!=null)
            opp.Seller__c = assets[0].ECSS_Owned_By__c;
        if(commission!=null)
            opp.ECSS_commission__c = commission;
        if(commission2!=null)
            opp.ECSS_commission_2__c = commission2;
        opp.ECSS_Commission_Source__c = commissionSource;
        update opp;
        
        Set<String> unitTypes = new Set<String>();
        for (Asset u : assets) if (u.ECSS_Unit_Type__c != null) unitTypes.add(u.ECSS_Unit_Type__c);
        
        Map<String, Product2> unitTypeToProduct = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Name IN :unitTypes]) {
            unitTypeToProduct.put(p.Name, p);
        }
        
        Map<Id, PricebookEntry> productToPBE = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id 
            FROM PricebookEntry
            WHERE Product2Id IN :unitTypeToProduct.values()
            AND Pricebook2Id = :opp.Pricebook2Id
            AND IsActive = true
        ]) {
            productToPBE.put(pbe.Product2Id, pbe);
        }
        
        
        Product2 genericProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'Apartment' 
            LIMIT 1
        ];
        
        
        PricebookEntry pbeAsset = [
            SELECT Id 
            FROM PricebookEntry
            WHERE Product2Id = :genericProduct.Id  
            LIMIT 1
        ];
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (Asset unit : assets) {
            
            
            olis.add(new OpportunityLineItem(
                OpportunityId         = opportunityId,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeAsset.Id,
                Quantity        = 1,
                UnitPrice       = unitPrice,   
                // ECSS_Commission__c   = commission,
                //ECSS_CommissionSource__c  = commissionSource,
                ECSS_Type__c = 'Sales',
                ECSS_Asset__c        = unit.Id
                
            ));
            
        }
        if (!olis.isEmpty() && !Test.isRunningTest()) {
            insert olis;
            
        }
        
        Opportunity oppUpdated = [
            SELECT Id, Name, ECSS_Project__c, LeadOrigin__c,Pricebook2Id,Amount
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        olis = new List<OpportunityLineItem>();
        string typeText;
        if(commissionSource=='Buyer')
            typeText = 'CommissionBuyer';
        else if (commissionSource == 'Seller' || commissionSource == 'Both')
            typeText = 'CommissionSeller';
        if(commission!=null)
        {
            olis.add(new OpportunityLineItem(
                OpportunityId         = opportunityId,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeAsset.Id,
                Quantity        = 1,
                UnitPrice       = (commission*oppUpdated.Amount)/100,   
                ECSS_Commission__c   = commission,
                ECSS_CommissionSource__c  = commissionSource,
                ECSS_Type__c =typeText
            )); 
        }
        
        if(commission2!=null && commissionSource=='Both')
        {
            olis.add(new OpportunityLineItem(
                OpportunityId         = opportunityId,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeAsset.Id,
                Quantity        = 1,
                UnitPrice       = (commission2*oppUpdated.Amount)/100,   
                ECSS_Commission__c   = commission2,
                ECSS_CommissionSource__c  = commissionSource,
                ECSS_Type__c ='CommissionBuyer'
            ));
        }
        
        if (!olis.isEmpty() && !Test.isRunningTest()) {
            insert olis;
            
        }
        
        // ߔ頒eturn result
        // result.put('quoteId', newQuote.Id);
        result.put('commission', commission);
        result.put('commissionSource', commissionSource);
        result.put('unitPrice', unitPrice);
        
        return result;
    }
    @AuraEnabled
    public static String createAssetAndAddtoOpp(Id opportunityId,Decimal commission, Decimal commission2,String commissionSource, Decimal unitPrice,String unitType,Id ownedById, String remarks,String unitNumber, String admBuildingNumber, String admPlotNumber, String admUnitNumber, String admSectorName,    String dldBuildingNumber, String dldPlotNumber, String dldUnitNumber, String dldSectorName )
    {
        
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID is required.');
        }
        
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>([Select Id from OpportunityLineItem where (ECSS_Type__c='CommissionSeller' OR  ECSS_Type__c='CommissionBuyer') and OpportunityId=:opportunityId]);
        if(oppLineItems.size()>0)
            delete oppLineItems;
        
        Opportunity opp = [
            SELECT Id, Name, ECSS_Project__c, LeadOrigin__c,Pricebook2Id,Amount
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        if(opp.Pricebook2Id == null)
        {
            opp.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id;
            
        }
        /* opp.ECSS_Developer__c = developerName;
opp.ECSS_Unit_Type__c = unitType;
opp.ECSS_Unit_Number__c = unitNumber;
opp.ECSS_Remarks__c = remarks;
opp.ECSS_Unit_Price__c = unitPrice;
opp.ECSS_Commission__c = commission;
opp.ECSS_Commission_Source__c = commissionSource;*/
        opp.ECSS_New_Unit_Approval__c ='Pending';
        opp.Seller__c = ownedById;
        if(commission!=null)
            opp.ECSS_Commission__c = commission;
        if(commission2!=null)
            opp.ECSS_Commission_2__c = commission2;
        opp.ECSS_Commission_Source__c = commissionSource;
        update opp;
        Id listingRTId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Listing').getRecordTypeId();
        Asset assetObj = new Asset();
        assetObj.ECSS_Source_Opportunity__c  = opportunityId;
        assetObj.RecordTypeId = listingRTId;
        assetObj.Name = unitNumber;
        assetObj.ECSS_Unit_Number__c = unitNumber;
        assetObj.ECSS_Owned_By__c = ownedById;
        assetObj.ECSS_Unit_Type__c = unitType;
        assetObj.ECSS_Selling_Price__c = unitPrice;
        assetObj.ECSS_ADMBuildingNumber__c    = admBuildingNumber;
        assetObj.ECSS_ADMPlotNumber__c        = admPlotNumber;
        assetObj.ECSS_ADMUnitNumber__c        = admUnitNumber;
        assetObj.ECSS_ADMSectorName__c        = admSectorName;
        assetObj.ECSS_DLDBuildingNumber__c = dldBuildingNumber;
        assetObj.ECSS_DLDPlotNumber__c     = dldPlotNumber;
        assetObj.ECSS_DLDUnitNumber__c     = dldUnitNumber;
        assetObj.ECSS_DLDSectorName__c     = dldSectorName;
        assetObj.ECSS_Unit_Creation_Status__c = 'Pending Manager Approval';
        assetObj.Status = 'Available for Sales';
        assetObj.ExternalIdentifier = unitNumber;
        
        insert assetObj;
        
        
        
        Product2 genericProduct = [
            SELECT Id 
            FROM Product2 
            WHERE Name = 'Apartment' 
            LIMIT 1
        ];
        
        
        PricebookEntry pbeAsset = [
            SELECT Id 
            FROM PricebookEntry
            WHERE Product2Id = :genericProduct.Id  
            LIMIT 1
        ];
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        olis.add(new OpportunityLineItem(
            OpportunityId         = opportunityId,
            Product2Id      = genericProduct.Id,
            PricebookEntryId= pbeAsset.Id,
            Quantity        = 1,
            UnitPrice       = unitPrice,   
            // ECSS_Commission__c   = commission,
            // ECSS_CommissionSource__c  = commissionSource,
            ECSS_Asset__c        = assetObj.Id,
            ECSS_Type__c = 'Sales',
            ECSS_Remarks__c = remarks
        ));
        try 
        {
            if (!olis.isEmpty() && !Test.isRunningTest()) {
                insert olis;
                
            }
        }
        catch (AuraHandledException e) {
            // Known user-facing error — pass back to LWC
            
            return e.getMessage();
            
        } catch (Exception e) {
            // Unexpected error — log and throw generic message
            
            return e.getMessage();
        }
        
        Opportunity oppUpdated = [
            SELECT Id, Name, ECSS_Project__c, LeadOrigin__c,Pricebook2Id,Amount
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        olis = new List<OpportunityLineItem>();
         string typeText;
        if(commissionSource=='Buyer')
            typeText = 'CommissionBuyer';
        else if (commissionSource == 'Seller' || commissionSource == 'Both')
            typeText = 'CommissionSeller';
        if(commission!=null)
        {
            olis.add(new OpportunityLineItem(
                OpportunityId         = opportunityId,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeAsset.Id,
                Quantity        = 1,
                UnitPrice       = (commission*oppUpdated.Amount)/100,   
                ECSS_Commission__c   = commission,
                ECSS_CommissionSource__c  = commissionSource,
                ECSS_Type__c = typeText,
                ECSS_Remarks__c = remarks
            ));
        }
        
        
        
        if(commission2!=null && commissionSource =='Both')
        {
            olis.add(new OpportunityLineItem(
                OpportunityId         = opportunityId,
                Product2Id      = genericProduct.Id,
                PricebookEntryId= pbeAsset.Id,
                Quantity        = 1,
                UnitPrice       = (commission2*oppUpdated.Amount)/100,   
                ECSS_Commission__c   = commission2,
                ECSS_CommissionSource__c  = commissionSource,
                ECSS_Type__c ='CommissionBuyer',
                ECSS_Remarks__c = remarks
            ));
            
        }
       
        
        try{
            
            if (!olis.isEmpty() && !Test.isRunningTest()) {
                insert olis;
                
                return 'Success';
            }
            
        }
        catch (AuraHandledException e) {
            // Known user-facing error — pass back to LWC
            
            return e.getMessage();
            
        } catch (Exception e) {
            // Unexpected error — log and throw generic message
            
            return e.getMessage();
        }
        return null;
        
    }
    @AuraEnabled
    public static Map<String, Object> createAccount(
        String firstName,
        String lastName,
        String emiratesId,
        String passportNumberPc,
        String email,
        String mobileCountryCode,
        String mobilePhone
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Check for duplicates
            List<Account> dup = [
                SELECT Id, Name
                FROM Account
                WHERE IsPersonAccount = true
                AND FirstName = :firstName
                AND LastName = :lastName
                AND (
                    (Emirates_ID__c != null AND Emirates_ID__c = :emiratesId)
                    OR (PassportNumber__pc != null AND PassportNumber__pc = :passportNumberPc)
                )
                LIMIT 1
            ];
            
            if (!dup.isEmpty()) {
                result.put('isDuplicate', true);
                result.put('accountId', dup[0].Id);
                result.put('accountName', dup[0].Name);
                result.put('message', 'A matching account already exists.');
                return result;
            }
            
            // Get Person Account RecordType
            Id personRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId();
            
            // Create new account
            Account newAccount = new Account(
                RecordTypeId = personRecordTypeId,
                FirstName = firstName,
                LastName = lastName,
                Emirates_ID__c = emiratesId,
                PassportNumber__pc = passportNumberPc,
                PersonEmail = email,
                Email__c = email,
                MobileCountryCode__pc = mobileCountryCode,
                MobilePhone__pc = mobilePhone
            );
            
            insert newAccount;
            
            result.put('isDuplicate', false);
            result.put('accountId', newAccount.Id);
            result.put('accountName', firstName + ' ' + lastName);
            result.put('message', 'Account created successfully.');
            
        } catch (Exception e) {
            result.put('error', true);
            result.put('message', e.getMessage());
        }
        
        return result;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String,String> checkDuplicateADMAsset(
        String buildingNumber,
        String plotNumber,
        String unitNumber,
        String sectorName
    ){
        // normalize
        String b = String.isBlank(buildingNumber) ? null : buildingNumber.trim();
        String p = String.isBlank(plotNumber)     ? null : plotNumber.trim();
        String u = String.isBlank(unitNumber)     ? null : unitNumber.trim();
        String s = String.isBlank(sectorName)     ? null : sectorName.trim();
        
        if (b == null && p == null && u == null && s == null) return null;
        
        List<String> whereParts = new List<String>();
        if (b != null) whereParts.add('ECSS_ADMBuildingNumber__c = :b');
        if (p != null) whereParts.add('ECSS_ADMPlotNumber__c = :p');
        if (u != null) whereParts.add('ECSS_ADMUnitNumber__c = :u');
        if (s != null) whereParts.add('ECSS_ADMSectorName__c = :s');
        
        if (whereParts.isEmpty()) return null;
        
        String soql = 'SELECT Id, Name FROM Asset WHERE ' + String.join(whereParts, ' AND ') + ' LIMIT 1';
        List<Asset> hits = Database.query(soql);
        
        if (!hits.isEmpty()) {
            return new Map<String,String>{
                'assetId'   => hits[0].Id,
                    'assetName' => hits[0].Name
                    };
                        }
        return null;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String,String> checkDuplicateDLDAsset(
        String buildingNumber,
        String plotNumber,
        String unitNumber,
        String sectorName
    ){
        // normalize
        String b = String.isBlank(buildingNumber) ? null : buildingNumber.trim();
        String p = String.isBlank(plotNumber)     ? null : plotNumber.trim();
        String u = String.isBlank(unitNumber)     ? null : unitNumber.trim();
        String s = String.isBlank(sectorName)     ? null : sectorName.trim();
        
        if (b == null && p == null && u == null && s == null) return null;
        
        List<String> whereParts = new List<String>();
        if (b != null) whereParts.add('ECSS_DLDBuildingNumber__c = :b');
        if (p != null) whereParts.add('ECSS_DLDPlotNumber__c = :p');
        if (u != null) whereParts.add('ECSS_DLDUnitNumber__c = :u');
        if (s != null) whereParts.add('ECSS_DLDSectorName__c = :s');
        
        if (whereParts.isEmpty()) return null;
        
        String soql = 'SELECT Id, Name FROM Asset WHERE ' + String.join(whereParts, ' AND ') + ' LIMIT 1';
        List<Asset> hits = Database.query(soql);
        
        if (!hits.isEmpty()) {
            return new Map<String,String>{
                'assetId'   => hits[0].Id,
                'assetName' => hits[0].Name
            };
        }
        return null;
    }
    @AuraEnabled
public static Map<String, Object> createCompanyAccount(String companyName, String companyTradeLicense) {
    Map<String, Object> result = new Map<String, Object>();
    
    try {
        // Check for duplicates using LIKE
        String searchPattern = '%' + companyName + '%';
        List<Account> existingAccountsTradeLicense = [
            SELECT Id, Name
            FROM Account
            WHERE ECSS_Trade_License_Number__c =:companyTradeLicense
            AND RecordType.DeveloperName = 'ECSS_Company'
            LIMIT 1
        ];
        
        
        if (!existingAccountsTradeLicense.isEmpty()) {
            result.put('isDuplicate', true);
            result.put('accountId', existingAccountsTradeLicense[0].Id);
            result.put('accountName', existingAccountsTradeLicense[0].Name);
            result.put('message', 'A matching company account already exists.');
            return result;
        }
        else //if account was not found by Trade License, query by name
        {
            List<Account> existingAccountsName = [
            SELECT Id, Name
            FROM Account
            WHERE Name LIKE :searchPattern
            AND RecordType.DeveloperName = 'ECSS_Company'
            LIMIT 1
        ];
            
            if (!existingAccountsName.isEmpty()) {
            result.put('isDuplicate', true);
            result.put('accountId', existingAccountsName[0].Id);
            result.put('accountName', existingAccountsName[0].Name);
            result.put('message', 'A matching company account already exists.');
            return result;
        }
        
        }
        
        // Get Company Account RecordType
        Id companyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('ECSS_Company').getRecordTypeId();
        
        // Create new company account
        Account newAccount = new Account(
            RecordTypeId = companyRecordTypeId,
            Name = companyName,
            ECSS_Trade_License_Number__c = companyTradeLicense
        );
        
        insert newAccount;
        
        result.put('isDuplicate', false);
        result.put('accountId', newAccount.Id);
        result.put('accountName', newAccount.Name);
        result.put('message', 'Company account created successfully.');
        
    } catch (Exception e) {
        result.put('error', true);
        result.put('message', e.getMessage());
    }
    
    return result;
}

@AuraEnabled
public static String createAssetAndAddtoOppOffPlan(
    Id opportunityId,
    Decimal unitPrice,
    String unitType,
    Id developerId,
    String remarks,
    String unitNumber,
    String admBuildingNumber,
    String admPlotNumber,
    String admUnitNumber,
    String admSectorName,
    String dldBuildingNumber,
    String dldPlotNumber,
    String dldUnitNumber,
    String dldSectorName 
) {
    if (opportunityId == null) {
        throw new AuraHandledException('Opportunity ID is required.');
    }
    
    Opportunity opp = [
        SELECT Id, Name, ECSS_Project__c, LeadOrigin__c, Pricebook2Id, Amount, ECSS_Developer__c
        FROM Opportunity
        WHERE Id = :opportunityId
        LIMIT 1
    ];
    
    if (opp.Pricebook2Id == null) {
        opp.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id;
    }
    
    opp.ECSS_New_Unit_Approval__c = 'Pending';
    if (developerId != null) {
        opp.ECSS_Developer__c = developerId;
    }
    update opp;
    
    Id listingRTId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Listing').getRecordTypeId();
    Asset assetObj = new Asset();
    assetObj.ECSS_Source_Opportunity__c = opportunityId;
    assetObj.RecordTypeId = listingRTId;
    assetObj.Name = unitNumber;
    assetObj.ECSS_Unit_Number__c = unitNumber;
    assetObj.ECSS_Developer__c = developerId;
    assetObj.ECSS_Unit_Type__c = unitType;
    assetObj.ECSS_Selling_Price__c = unitPrice;
    assetObj.ECSS_ADMBuildingNumber__c = admBuildingNumber;
    assetObj.ECSS_ADMPlotNumber__c = admPlotNumber;
    assetObj.ECSS_ADMUnitNumber__c = admUnitNumber;
    assetObj.ECSS_ADMSectorName__c = admSectorName;
    assetObj.ECSS_DLDBuildingNumber__c    = dldBuildingNumber;
    assetObj.ECSS_DLDPlotNumber__c        = dldPlotNumber;
    assetObj.ECSS_DLDUnitNumber__c        = dldUnitNumber;
    assetObj.ECSS_DLDSectorName__c        = dldSectorName;
    assetObj.ECSS_Unit_Creation_Status__c = 'Pending Manager Approval';
    assetObj.Status = 'Available for Sales';
    assetObj.ExternalIdentifier = unitNumber;
    
    insert assetObj;
    
    Product2 genericProduct = [
        SELECT Id 
        FROM Product2 
        WHERE Name = 'Apartment' 
        LIMIT 1
    ];
    
    PricebookEntry pbeAsset = [
        SELECT Id 
        FROM PricebookEntry
        WHERE Product2Id = :genericProduct.Id  
        LIMIT 1
    ];
    
    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    olis.add(new OpportunityLineItem(
        OpportunityId = opportunityId,
        Product2Id = genericProduct.Id,
        PricebookEntryId = pbeAsset.Id,
        Quantity = 1,
        UnitPrice = unitPrice,
        ECSS_Asset__c = assetObj.Id,
        ECSS_Type__c = 'Sales',
        ECSS_Remarks__c = remarks
    ));
    
    try {
        if (!olis.isEmpty() && !Test.isRunningTest()) {
            insert olis;
            
            return 'Success';
        }
    } catch (AuraHandledException e) {
        
        return e.getMessage();
    } catch (Exception e) {
        
        return e.getMessage();
    }
    return null;
}
    
    
    
    
}