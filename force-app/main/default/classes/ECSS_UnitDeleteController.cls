public with sharing class ECSS_UnitDeleteController {
    
    
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
        Id opportunityId 
    ) {
        // 1. Collect parent + child opportunity IDs
        List<Id> opportunityIds = new List<Id>{opportunityId};
            for (Opportunity childOpp : [
                SELECT Id FROM Opportunity WHERE ExistingOpportunity__c = :opportunityId
            ]) {
                opportunityIds.add(childOpp.Id);
            }
        
        Set<Id> QuotesIds = new Set<Id>();
        
        List<Quote> Quotes = [SELECT Id From Quote WHERE OpportunityId IN :opportunityIds];
        
        for(Quote Q: Quotes){
            QuotesIds.add(Q.Id);
        }        
        
        Set<Id> QuoteLineItemIds = new set<Id>();
        
        List<QuoteLineItem> QuoteLineItems = [SELECT Id ,Asset__c From QuoteLineItem Where QuoteId IN :QuotesIds ];
        
        Set<Id> AssetIds= new Set<Id>();
        
        
        for(QuoteLineItem qli : QuoteLineItems){
            QuoteLineItemIds.add(qli.Id);
            AssetIds.add(qli.Asset__c);
            
        }
        
        System.debug('KADY QuotesIds: '+ QuotesIds);
        
        
        Set<Id> unitIds = new Set<Id>();
        
        List<Asset> Assets = [SELECT Id ,Unit__c From Asset Where Id IN :AssetIds ];
        
        System.debug('KADY Assets: '+ Assets);
        
        For (Asset a : Assets){
            
            unitIds.add(a.Id);
        } 
        
        System.debug('KADY unitIds: '+ unitIds);
        
        
        
        
        
        
        
        
        
        
        
        
        /*
// 2. Collect Unit__c from OpportunityLineItems
Set<Id> unitIds = new Set<Id>();
for (OpportunityLineItem oli : [
SELECT Unit__c FROM OpportunityLineItem
WHERE OpportunityId IN :opportunityIds AND Unit__c != null
]) {
unitIds.add(oli.Unit__c);
}


if (unitIds.isEmpty()) {
return new List<Asset>(); // return early if no units found
}
*/
        
        // 3. Build SOQL to fetch those units with filters
        String query = 'SELECT Id, Name, ExternalIdentifier, ECSS_Unit_Type__c, ECSS_Unit_Area__c, ECSS_Unit_Usage__c, ' +
            'ECSS_Floor_Number__c, ECSS_Number_of_Bedrooms__c, ECSS_Number_of_Baths__c, ECSS_View__c, ' +
            'ECSS_Project__c, ECSS_Project__r.Name, ECSS_Zone__c, ECSS_Zone__r.Name, ' +
            'ECSS_Building_Section__c, ECSS_Building_Section__r.Name ' +
            'FROM Asset WHERE Id IN :unitIds';
        
        if (projectId != null) query += ' AND ECSS_Project__c = :projectId';
        if (zoneId != null) query += ' AND ECSS_Zone__c = :zoneId';
        if (buildingId != null) query += ' AND ECSS_Building_Section__c = :buildingId';
        if (!String.isBlank(unitType)) query += ' AND ECSS_Unit_Type__c = :unitType';
        if (!String.isBlank(unitArea)) query += ' AND ECSS_Unit_Area__c = :unitArea';
        if (!String.isBlank(floorNumber)) query += ' AND ECSS_Floor_Number__c = :floorNumber';
        if (!String.isBlank(bedrooms)) query += ' AND ECSS_Number_of_Bedrooms__c = :bedrooms';
        if (baths != null) query += ' AND ECSS_Number_of_Baths__c = :baths';
        if (!String.isBlank(view)) query += ' AND ECSS_View__c = :view';
        if (!String.isBlank(unitUsage)) query += ' AND ECSS_Unit_Usage__c = :unitUsage';
        
        if (!String.isBlank(searchKey)) {
            String key = '%' + searchKey + '%';
            query += ' AND (Name LIKE :key OR ExternalIdentifier LIKE :key)';
        }
        
        query += ' LIMIT 100000';
        
        return Database.query(query);
    }
    
    
    // Picklist and filter option fetchers
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllProjects() {
        List<Map<String, String>> results = new List<Map<String, String>>();
        Set<Id> seenIds = new Set<Id>();
        for (Asset a : [SELECT ECSS_Project__c, ECSS_Project__r.Name FROM Asset WHERE ECSS_Project__c != null AND Status IN ('Available for Lease', 'Available for Both', 'Under Maintenance')]) {
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
        for (Asset a : [SELECT ECSS_Zone__c, ECSS_Zone__r.Name FROM Asset WHERE ECSS_Zone__c != null AND Status IN ('Available for Lease', 'Available for Both', 'Under Maintenance')]) {
            if (!seenIds.contains(a.ECSS_Zone__c)) {
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
        for (Asset a : [SELECT ECSS_Building_Section__c, ECSS_Building_Section__r.Name FROM Asset WHERE ECSS_Building_Section__c != null AND Status IN ('Available for Lease', 'Available for Both', 'Under Maintenance')]) {
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
@AuraEnabled
public static void markUnitsForDeletion(List<Id> unitIds, Id opportunityId) {
    if (unitIds == null || unitIds.isEmpty()) {
        throw new AuraHandledException('No units selected.');
    }

    if (opportunityId == null) {
        throw new AuraHandledException('No opportunity specified.');
    }

    User currentUser = [
        SELECT Id, ManagerId 
        FROM User 
        WHERE Id = :UserInfo.getUserId() 
        LIMIT 1
    ];

    // ✅ Get only Quotes for the current Opportunity
    Set<Id> quoteIds = new Set<Id>();
    for (Quote q : [
        SELECT Id 
        FROM Quote 
        WHERE OpportunityId = :opportunityId
    ]) {
        quoteIds.add(q.Id);
    }

    if (quoteIds.isEmpty()) {
        return; // nothing to update
    }

    // ✅ Get QLIs for the selected units, but ONLY under those Quotes
    List<QuoteLineItem> qlis = [
        SELECT Id, Asset__c, QuoteId 
        FROM QuoteLineItem 
        WHERE Asset__c IN :unitIds
        AND QuoteId IN :quoteIds
    ];

    for (QuoteLineItem qli : qlis) {
        qli.ECSS_Under_Approval__c = true;
        qli.ECSS_Approved_By__c = currentUser.ManagerId;
    }
    if (!qlis.isEmpty()) {
        update qlis;
    }

    // Get asset names for the notification body
    List<Asset> assets = [
        SELECT Id, Name 
        FROM Asset 
        WHERE Id IN :unitIds
    ];
    Set<String> unitNames = new Set<String>();
    for (Asset a : assets) {
        unitNames.add(a.Name);
    }

    if (currentUser.ManagerId != null && !unitNames.isEmpty()) {
        Id notifTypeId = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'ECSS_Case_Owner_Notification' 
            LIMIT 1
        ].Id;

        String body = 'The following units are pending deletion approval:\n';
        for (String name : unitNames) {
            body += '- ' + name + '\n';
        }

        if (!Test.isRunningTest()) {
            Messaging.CustomNotification notify = new Messaging.CustomNotification();
            notify.setTitle('Unit Deletion Request');
            notify.setBody(body);
            notify.setNotificationTypeId(notifTypeId);

            // ✅ Always target the current Opportunity
            notify.setTargetId(opportunityId);

            notify.send(new Set<String>{ currentUser.ManagerId });
        }
    }
}

    
}