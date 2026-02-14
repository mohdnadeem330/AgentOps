public class ECSS_AssetTriggerHelper {
    
    private static String listingRTName = System.Label.ECSS_Listing_RT;
    private static String UnitRTName = System.Label.ECSS_Unit;
    
    private static Id listingRecordTypeId =  Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get(listingRTName).getRecordTypeId();
    private static Id unitRecordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get(UnitRTName).getRecordTypeId();
    
    public static void linkInventoryReqToAssets(List<Asset> newList){
        System.debug('in the after inventory');
        //Link the Asset Record using the external Id
        Map<String,Asset> externalAssetMap = new Map<String,Asset>();
        Set<String> externalIds = new Set<String>();
        
        for(Asset currAsset : newList){
            if(currAsset.RecordTypeId == listingRecordTypeId || currAsset.RecordTypeId == unitRecordTypeId ){
                externalAssetMap.put(currAsset.ExternalIdentifier,currAsset); externalIds.add(currAsset.ExternalIdentifier);
            }
        }
        List<Inventory_Request_Details__c> relatedInvReqDet = [SELECT Id,Related_Asset__c,ECSS_Related_Asset_ExternalId__c,Status__c 
                                                               FROM Inventory_Request_Details__c
                                                               where Related_Asset__c = null
                                                               AND ECSS_Related_Asset_ExternalId__c in:externalIds AND Status__c != 'Approved' and Status__c !='Rejected'];
        
        for(Inventory_Request_Details__c currInvReqDetail : relatedInvReqDet){
            currInvReqDetail.Related_Asset__c = externalAssetMap.get(currInvReqDetail.ECSS_Related_Asset_ExternalId__c).Id; 
        }
        if(relatedInvReqDet.size()>0) update relatedInvReqDet;
        
    }
    
    public static void externalIdRecords(List<Asset> assetList){
        // Step 1: Collect all external identifiers from Asset records
        System.debug('70..');
        Set<String> companyExternalIds = new Set<String>();
        Set<String> projectExternalIds = new Set<String>();
        Set<String> LandlordSAPExternalIds = new Set<String>();
        Set<String> buildingSectionExternalIds = new Set<String>();
        Set<String> zoneExternalIds = new Set<String>();
        Set<String> ownerEmails = new Set<String>();
        Set<String> unitTypeNames = new Set<String>();
        
        for (Asset a : assetList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId)
            {
                if (String.isNotBlank(a.ECSS_Company_Code_External_Id__c)) {
                    companyExternalIds.add(a.ECSS_Company_Code_External_Id__c);
                }
                if (String.isNotBlank(a.ECSS_Project_External_Id__c)) {
                    projectExternalIds.add(a.ECSS_Project_External_Id__c);
                }
                if (String.isNotBlank(a.ECSS_LandlordSAPExternalId__c)) {
                    LandlordSAPExternalIds.add(a.ECSS_LandlordSAPExternalId__c);
                }
                if (String.isNotBlank(a.ECSS_Building_Section_External_Id__c)) {
                    buildingSectionExternalIds.add(a.ECSS_Building_Section_External_Id__c);
                }
                if (String.isNotBlank(a.ECSS_Zone_External_Id__c)) {
                    zoneExternalIds.add(a.ECSS_Zone_External_Id__c);
                }
                if (String.isNotBlank(a.ECSS_Owner_Email__c)) {
                    ownerEmails.add(a.ECSS_Owner_Email__c.trim().toLowerCase());
                }
                if (String.isNotBlank(a.ECSS_Unit_Type__c)) {
                    unitTypeNames.add(a.ECSS_Unit_Type__c.trim());
                }
            }
        }
        
        // Step 2: Query Accounts
        Map<String, Account> externalIdToAccountMap = new Map<String, Account>();
        if (!companyExternalIds.isEmpty()) {
            for (Account acc : [
                SELECT Id, ECSS_Company_External_Id__c, ECSS_Availability__c
                FROM Account
                WHERE ECSS_Company_External_Id__c IN :companyExternalIds
            ]) {
                if (acc.ECSS_Company_External_Id__c != null) {
                    externalIdToAccountMap.put(acc.ECSS_Company_External_Id__c, acc);
                }
            }
        }
        
        // Step 4: Query Account
        Map<String, Account> externalIdToLandlordSAPMap = new Map<String, Account>();
        System.debug('LandlordSAPExternalIds ' + LandlordSAPExternalIds);
        if (!LandlordSAPExternalIds.isEmpty()) {
            for (Account bs : [
                SELECT Id, SapAccountID__c 
                FROM Account
                WHERE SapAccountID__c IN :LandlordSAPExternalIds
            ]) {
                if (bs.SapAccountID__c != null) {
                    externalIdToLandlordSAPMap.put(bs.SapAccountID__c, bs);
                }
            }
            System.debug('externalIdToLandlordSAPMap ' + externalIdToLandlordSAPMap);
        }
        
        // Step 3: Query Projects
        Map<String, Project__c> externalIdToProjectMap = new Map<String, Project__c>();
        if (!projectExternalIds.isEmpty()) {
            for (Project__c proj : [
                SELECT Id, ECSS_SAPExternalId__c,ECSS_ProjectCode__c
                FROM Project__c
                WHERE ECSS_ProjectCode__c IN :projectExternalIds
            ]) {
                if (proj.ProjectCode__c != null) {
                    externalIdToProjectMap.put(proj.ECSS_ProjectCode__c, proj);
                }
            }
        }
        
        // Step 4: Query Building Sections
        Map<String, BuildingSection__c> externalIdToBuildingSectionMap = new Map<String, BuildingSection__c>();
        if (!buildingSectionExternalIds.isEmpty()) {
            for (BuildingSection__c bs : [
                SELECT Id, ECSS_Building_External_Id__c
                FROM BuildingSection__c
                WHERE ECSS_Building_External_Id__c IN :buildingSectionExternalIds
            ]) {
                if (bs.ECSS_Building_External_Id__c != null) {
                    externalIdToBuildingSectionMap.put(bs.ECSS_Building_External_Id__c, bs);
                }
            }
        }
        
        
        
        // Step 5: Query Zones
        Map<String, Zone__c> externalIdToZoneMap = new Map<String, Zone__c>();
        if (!zoneExternalIds.isEmpty()) {
            for (Zone__c zone : [
                SELECT Id, Zone_External_Id__c
                FROM Zone__c
                WHERE Zone_External_Id__c IN :zoneExternalIds
            ]) {
                if (zone.Zone_External_Id__c != null) {
                    externalIdToZoneMap.put(zone.Zone_External_Id__c, zone);
                }
            }
        }
        
        // Step 6: Query Users
        Map<String, User> emailToUserMap = new Map<String, User>();
        if (!ownerEmails.isEmpty()) {
            for (User u : [
                SELECT Id, Username
                FROM User
                WHERE Username IN :ownerEmails
            ]) {
                if (String.isNotBlank(u.Username)) {
                    emailToUserMap.put(u.Username.trim().toLowerCase(), u);
                }
            }
        }
        
        // Step 7: Query Products
        Map<String, Product2> nameToProductMap = new Map<String, Product2>();
        if (!unitTypeNames.isEmpty()) {
            for (Product2 p : [ SELECT Id, Name FROM Product2 WHERE Name IN :unitTypeNames ]) { if (String.isNotBlank(p.Name)) { nameToProductMap.put(p.Name.trim(), p);
                                                                                                                               }
                                                                                              }
        }
        
        // Step 8: Assign matched values to Assets
        for (Asset a : assetList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId){
                // Account
                if (String.isNotBlank(a.ECSS_Company_Code_External_Id__c)) {
                    Account matchedAcc = externalIdToAccountMap.get(a.ECSS_Company_Code_External_Id__c);
                    if (matchedAcc != null) {
                        a.ECSS_Company_Code__c = matchedAcc.Id;
                        a.ECSS_Available_For__c = matchedAcc.ECSS_Availability__c;
                        if(a.RecordTypeName__c == 'Ecss_unit'){
                            if (a.ECSS_Available_For__c == 'Available for Lease') { a.Status = 'Available for Lease';
                                                                                   
                                                                                  } else if(a.ECSS_Available_For__c == 'Available for Sale') { a.Status = 'Available for Sales';
                                                                                                                                             }else{ a.Status = 'Available for Both';
                                                                                                                                                  }
                        }
                    }
                }
                
                // Project
                if (String.isNotBlank(a.ECSS_Project_External_Id__c)) {
                    Project__c matchedProj = externalIdToProjectMap.get(a.ECSS_Project_External_Id__c);
                    if (matchedProj != null) {
                        a.ECSS_Project__c = matchedProj.Id;
                    }
                }
                
                // Account
                if (String.isNotBlank(a.ECSS_LandlordSAPExternalId__c)) {
                    Account matchedAccount = externalIdToLandlordSAPMap.get(a.ECSS_LandlordSAPExternalId__c);
                    System.debug('matchedAccount ' + matchedAccount);
                    if (matchedAccount != null) {
                        a.AccountId = matchedAccount.Id;
                    }
                }
                
                // Building Section
                if (String.isNotBlank(a.ECSS_Building_Section_External_Id__c)) {
                    BuildingSection__c matchedBS = externalIdToBuildingSectionMap.get(a.ECSS_Building_Section_External_Id__c);
                    if (matchedBS != null) {
                        a.ECSS_Building_Section__c = matchedBS.Id;
                    }
                }
                
                // Zone
                if (String.isNotBlank(a.ECSS_Zone_External_Id__c)) {
                    Zone__c matchedZone = externalIdToZoneMap.get(a.ECSS_Zone_External_Id__c);
                    if (matchedZone != null) {
                        a.ECSS_Zone__c = matchedZone.Id;
                    }
                }
                
                // Owner
                if (String.isNotBlank(a.ECSS_Owner_Email__c)) {
                    User matchedUser = emailToUserMap.get(a.ECSS_Owner_Email__c.trim().toLowerCase());
                    if (matchedUser != null) {
                        a.OwnerId = matchedUser.Id;
                    }
                }
                
                // Product
                if (String.isNotBlank(a.ECSS_Unit_Type__c)) {   Product2 matchedProduct = nameToProductMap.get(a.ECSS_Unit_Type__c.trim()); if (matchedProduct != null) { a.Product2Id = matchedProduct.Id;
                                                                                                                                                                        }
                                                            }
            }
        }
    }
    
    /*  public static void handleAssetInsert(List<Asset> newAssets) {
List<AssetShare> sharesToInsert = new List<AssetShare>();

Map<Id, String> assetIdToArea = new Map<Id, String>();
for (Asset a : newAssets) {
Boolean isRelevantType = a.RecordTypeName__c == 'Ecss_unit' || a.RecordTypeName__c == 'Listing';
Boolean hasArea = String.isNotBlank(a.ECSS_Unit_Area__c);
if (isRelevantType && hasArea) {
assetIdToArea.put(a.Id, a.ECSS_Unit_Area__c);
}
}

Set<String> allAreas = new Set<String>(assetIdToArea.values());
Set<Id> assetOwnerIds = new Set<Id>();
for (Asset a : newAssets) assetOwnerIds.add(a.OwnerId);

List<User> matchingUsers = [
SELECT Id, ECSS_Covering_Area__c
FROM User
WHERE ECSS_Covering_Area__c != null
AND Id NOT IN :assetOwnerIds
];

for (Asset asset : newAssets) {
String assetArea = assetIdToArea.get(asset.Id);
if (assetArea == null) continue;

for (User u : matchingUsers) {
Boolean coversArea = u.ECSS_Covering_Area__c != null &&
u.ECSS_Covering_Area__c.contains(assetArea);
if (coversArea) {
sharesToInsert.add(new AssetShare(
AssetId = asset.Id,
UserOrGroupId = u.Id,
AssetAccessLevel = 'Read'
));
}
}
}

if (!sharesToInsert.isEmpty()) {
insert sharesToInsert;
}
}


public static void handleAssetUpdate(List<Asset> updatedAssets, Map<Id, Asset> oldMap) {
List<AssetShare> toInsert = new List<AssetShare>();
List<AssetShare> toDelete = new List<AssetShare>();

Set<Id> assetIdsToUpdate = new Set<Id>();
Map<Id, String> assetIdToNewArea = new Map<Id, String>();
Map<Id, Id> assetIdToOwnerId = new Map<Id, Id>();

for (Asset asset : updatedAssets) {
Boolean isRelevantType = asset.RecordTypeName__c == 'Ecss_unit' || asset.RecordTypeName__c == 'Listing';
if (!isRelevantType) continue;

Asset oldAsset = oldMap.get(asset.Id);
Boolean areaChanged = asset.ECSS_Unit_Area__c != oldAsset.ECSS_Unit_Area__c;
if (areaChanged) {
assetIdsToUpdate.add(asset.Id);
assetIdToNewArea.put(asset.Id, asset.ECSS_Unit_Area__c);
assetIdToOwnerId.put(asset.Id, asset.OwnerId);
}
}

if (assetIdsToUpdate.isEmpty()) return;

List<AssetShare> allShares = [
SELECT Id, AssetId, UserOrGroupId, RowCause
FROM AssetShare
WHERE AssetId IN :assetIdsToUpdate
AND RowCause NOT IN ('Owner', 'Rule', 'ImplicitChild')
];

List<User> allUsers = [
SELECT Id, ECSS_Covering_Area__c
FROM User
WHERE ECSS_Covering_Area__c != null
];

Map<Id, List<AssetShare>> assetToShares = new Map<Id, List<AssetShare>>();
for (AssetShare s : allShares) {
if (!assetToShares.containsKey(s.AssetId)) {
assetToShares.put(s.AssetId, new List<AssetShare>());
}
assetToShares.get(s.AssetId).add(s);
}

for (Id assetId : assetIdsToUpdate) {
String newArea = assetIdToNewArea.get(assetId);
Id ownerId = assetIdToOwnerId.get(assetId);
List<AssetShare> existingShares = assetToShares.get(assetId) != null ? assetToShares.get(assetId) : new List<AssetShare>();
Map<Id, AssetShare> userIdToShare = new Map<Id, AssetShare>();

for (AssetShare s : existingShares) {
userIdToShare.put(s.UserOrGroupId, s);
}

Set<Id> validUserIds = new Set<Id>();
for (User u : allUsers) {
if (u.Id != ownerId && u.ECSS_Covering_Area__c.contains(newArea)) {
validUserIds.add(u.Id);
}
}

for (Id userId : userIdToShare.keySet()) {
if (!validUserIds.contains(userId)) {
toDelete.add(userIdToShare.get(userId));
}
}

for (Id userId : validUserIds) {
if (!userIdToShare.containsKey(userId)) {
toInsert.add(new AssetShare(
AssetId = assetId,
UserOrGroupId = userId,
AssetAccessLevel = 'Read'
));
}
}
}

if (!toDelete.isEmpty()) delete toDelete;
if (!toInsert.isEmpty()) insert toInsert;
}*/
    
    /*public static void removeQuoteLineItemsForUnderOfferAssets(List<Asset> newAssets, Map<Id, Asset> oldMap) {
Set<Id> underOfferAssetIds = new Set<Id>();

for (Asset asset : newAssets) {
Asset oldAsset = oldMap != null ? oldMap.get(asset.Id) : null;
if (asset.Status == 'Under Offer' && (oldAsset == null || oldAsset.Status != 'Under Offer')) {
underOfferAssetIds.add(asset.Id);
}
}

if (underOfferAssetIds.isEmpty()) return;

List<QuoteLineItem> qlisToDelete = [
SELECT Id, Asset__c, Asset__r.Name, QuoteId, Quote.OpportunityId, Quote.Opportunity.OwnerId, Quote.Opportunity.Owner.Email
FROM QuoteLineItem
WHERE Asset__c IN :underOfferAssetIds
AND Quote.Opportunity.StageName != 'Under Offer'
];

Map<Id, String> oppIdToAssetNameMap = new Map<Id, String>();
Map<Id, String> oppIdToEmail = new Map<Id, String>();        
Map<Id, Id> oppIdToOwnerId = new Map<Id, Id>();              

for (QuoteLineItem qli : qlisToDelete) {
oppIdToAssetNameMap.put(qli.Quote.OpportunityId, qli.Asset__r.Name);
oppIdToEmail.put(qli.Quote.OpportunityId, qli.Quote.Opportunity.Owner.Email);
oppIdToOwnerId.put(qli.Quote.OpportunityId, qli.Quote.Opportunity.OwnerId);
}

if (!qlisToDelete.isEmpty()) {
delete qlisToDelete;
}

List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

Id notifTypeId = [
SELECT Id FROM CustomNotificationType
WHERE DeveloperName = 'ECSS_Case_Owner_Notification'
LIMIT 1
].Id;

for (Id oppId : oppIdToAssetNameMap.keySet()) {
String assetName = oppIdToAssetNameMap.get(oppId);
String ownerEmail = oppIdToEmail.get(oppId);
Id ownerId = oppIdToOwnerId.get(oppId);

if (String.isBlank(assetName) || String.isBlank(ownerEmail)) continue;

// Email
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setToAddresses(new List<String>{ ownerEmail });
email.setSubject('Asset Unassigned from Your Opportunity');
email.setPlainTextBody('The asset "' + assetName + '" has been reserved by another opportunity.');
email.setSaveAsActivity(false);
emailsToSend.add(email);

// Notification
Messaging.CustomNotification notification = new Messaging.CustomNotification();
notification.setNotificationTypeId(notifTypeId);
notification.setTitle('Asset Reserved by Another Opportunity');
notification.setBody('The asset "' + assetName + '" has been reserved by another opportunity.');
notification.setSenderId(UserInfo.getUserId());
notification.setTargetId(oppId);
notification.send(new Set<String>{ ownerId });
}

if (!emailsToSend.isEmpty()) {
Messaging.sendEmail(emailsToSend);
}
}*/
    
    public static void handleProjectAllocationGroupShare(List<Asset> newList, Map<Id, Asset> oldMap) {
        List<AssetShare> sharesToInsert = new List<AssetShare>();
        List<AssetShare> sharesToDelete = new List<AssetShare>();
        
        for (Asset a : newList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId){
                Asset old = oldMap.get(a.Id);
                Id oldGroupId = old != null ? old.ECSS_Project_Allocation_Group__c : null;
                Id newGroupId = a.ECSS_Project_Allocation_Group__c;
                
                if (newGroupId != null && newGroupId != oldGroupId) {
                    if (oldGroupId != null) {
                        List<AllocationGroup__c> oldAgList = [
                            SELECT PublicGroupAssociated__c FROM AllocationGroup__c
                            WHERE Id = :oldGroupId AND PublicGroupAssociated__c != null
                            LIMIT 1
                        ];
                        if (!oldAgList.isEmpty()) {
                            sharesToDelete.addAll([
                                SELECT Id FROM AssetShare
                                WHERE AssetId = :a.Id AND UserOrGroupId = :oldAgList[0].PublicGroupAssociated__c
                            ]);
                        }
                    }
                    
                    List<AllocationGroup__c> newAgList = [
                        SELECT PublicGroupAssociated__c FROM AllocationGroup__c
                        WHERE Id = :newGroupId AND PublicGroupAssociated__c != null
                        LIMIT 1
                    ];
                    if (!newAgList.isEmpty()) {
                        sharesToInsert.add(new AssetShare(
                            AssetId = a.Id,
                            UserOrGroupId = newAgList[0].PublicGroupAssociated__c,
                            AssetAccessLevel = 'Read'
                        ));
                    }
                }
            }
        }
        
        if (!sharesToDelete.isEmpty()) delete sharesToDelete;
        if (!sharesToInsert.isEmpty()) insert sharesToInsert;
    }
    
    
    public static void handleAreaAllocationGroupShare(List<Asset> newList, Map<Id, Asset> oldMap) {
        List<AssetShare> sharesToInsert = new List<AssetShare>();
        List<AssetShare> sharesToDelete = new List<AssetShare>();
        
        for (Asset a : newList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId){
                Asset old = oldMap.get(a.Id);
                Id oldGroupId = old != null ? old.ECSS_Area_Allocation_Group__c : null;
                Id newGroupId = a.ECSS_Area_Allocation_Group__c;
                
                if (newGroupId != null && newGroupId != oldGroupId) {
                    if (oldGroupId != null) {
                        List<AllocationGroup__c> oldAgList = [
                            SELECT PublicGroupAssociated__c FROM AllocationGroup__c
                            WHERE Id = :oldGroupId AND PublicGroupAssociated__c != null
                            LIMIT 1
                        ];
                        if (!oldAgList.isEmpty()) {
                            sharesToDelete.addAll([
                                SELECT Id FROM AssetShare
                                WHERE AssetId = :a.Id AND UserOrGroupId = :oldAgList[0].PublicGroupAssociated__c
                            ]);
                        }
                    }
                    
                    List<AllocationGroup__c> newAgList = [
                        SELECT PublicGroupAssociated__c FROM AllocationGroup__c
                        WHERE Id = :newGroupId AND PublicGroupAssociated__c != null
                        LIMIT 1
                    ];
                    if (!newAgList.isEmpty()) {
                        sharesToInsert.add(new AssetShare(
                            AssetId = a.Id,
                            UserOrGroupId = newAgList[0].PublicGroupAssociated__c,
                            AssetAccessLevel = 'Read'
                        ));
                    }
                }
            }
        }
        
        if (!sharesToDelete.isEmpty()) delete sharesToDelete;
        if (!sharesToInsert.isEmpty()) insert sharesToInsert;
    }
    
    
    
    public static void ECSS_handleAreaChange(List<Asset> newList, Map<Id, Asset> oldMap) {
        Set<String> areaCodes = new Set<String>();
        Set<Id> assetIdsToUpdate = new Set<Id>();
        
        for (Asset a : newList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId){
                Asset old = oldMap != null ? oldMap.get(a.Id) : null;
                if (old == null || a.ECSS_Unit_Area__c != old.ECSS_Unit_Area__c) {
                    if (String.isNotBlank(a.ECSS_Unit_Area__c)) {
                        areaCodes.add(a.ECSS_Unit_Area__c);
                        assetIdsToUpdate.add(a.Id);
                    }
                }
            }
        }
        
        if (areaCodes.isEmpty() || assetIdsToUpdate.isEmpty()) return;
        
        Map<String, Id> codeToGroupId = new Map<String, Id>();
        for (AllocationGroup__c ag : [
            SELECT Id, AllocationGroupCode__c
            FROM AllocationGroup__c
            WHERE AllocationGroupCode__c IN :areaCodes
        ]) {
            codeToGroupId.put(ag.AllocationGroupCode__c, ag.Id);
        }
        
        List<AllocationGroup__c> groupsToInsert = new List<AllocationGroup__c>();
        for (String code : areaCodes) {
            if (!codeToGroupId.containsKey(code)) {
                groupsToInsert.add(new AllocationGroup__c(
                    Name = code,
                    AllocationGroupCode__c = code,
                    StartDate__c = Date.today(),
                    EndDate__c = Date.today().addYears(5),
                    ECSS_Type__c='Area'
                ));
            }
        }
        
        if (!groupsToInsert.isEmpty()) {
            insert groupsToInsert;
            for (AllocationGroup__c ag : groupsToInsert) {
                codeToGroupId.put(ag.AllocationGroupCode__c, ag.Id);
            }
        }
        
        List<Asset> assetsToUpdate = [
            SELECT Id, ECSS_Unit_Area__c, ECSS_Area_Allocation_Group__c
            FROM Asset
            WHERE Id IN :assetIdsToUpdate AND (RecordTypeId =: unitRecordTypeId OR RecordTypeId =:listingRecordTypeId)
        ];
        
        for (Asset a : assetsToUpdate) {
            Id newGroupId = codeToGroupId.get(a.ECSS_Unit_Area__c);
            if (newGroupId != null && newGroupId != a.ECSS_Area_Allocation_Group__c) {
                a.ECSS_Area_Allocation_Group__c = newGroupId;
            }
        }
        
        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
    }
    
    
    public static void ECSS_handleProjectChange(List<Asset> newList, Map<Id, Asset> oldMap) {
        Set<String> projectExternalIds = new Set<String>();
        Set<Id> assetIdsToUpdate = new Set<Id>();
        
        for (Asset a : newList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId){
                Asset old = oldMap != null ? oldMap.get(a.Id) : null;
                if (old == null || a.ECSS_Project_External_Id__c != old.ECSS_Project_External_Id__c) {
                    if (String.isNotBlank(a.ECSS_Project_External_Id__c)) {
                        projectExternalIds.add(a.ECSS_Project_External_Id__c);
                        assetIdsToUpdate.add(a.Id);
                    }
                }
            }
        }
        
        if (projectExternalIds.isEmpty() || assetIdsToUpdate.isEmpty()) return;
        
        Map<String, Project__c> nameToProject = new Map<String, Project__c>();
        for (Project__c p : [
            SELECT Id, Name, ECSS_ProjectCode__c, ProjectCode__c
            FROM Project__c
            WHERE Name IN :projectExternalIds
        ]) {
            nameToProject.put(p.Name, p);
        }
        
        Map<String, Id> codeToGroupId = new Map<String, Id>();
        for (AllocationGroup__c ag : [
            SELECT Id, AllocationGroupCode__c
            FROM AllocationGroup__c
            WHERE AllocationGroupCode__c IN :projectExternalIds
        ]) {
            codeToGroupId.put(ag.AllocationGroupCode__c, ag.Id);
        }
        
        List<AllocationGroup__c> groupsToInsert = new List<AllocationGroup__c>();
        for (String externalId : projectExternalIds) {
            if (!codeToGroupId.containsKey(externalId)) {
                Project__c proj = nameToProject.get(externalId);
                if (proj != null) {
                    String groupName = String.isNotBlank(proj.ECSS_ProjectCode__c)
                        ? proj.ECSS_ProjectCode__c
                        : proj.ProjectCode__c;
                    if (groupName != null && groupName.length() > 10) {
                        groupName = groupName.substring(0, 10);
                    }
                    
                    groupsToInsert.add(new AllocationGroup__c(
                        Name = groupName,
                        AllocationGroupCode__c = groupName,
                        StartDate__c = Date.today(),
                        EndDate__c = Date.today().addYears(5),
                        ECSS_Type__c = 'Project'
                    ));
                }
            }
        }
        
        if (!groupsToInsert.isEmpty()) {
            insert groupsToInsert;
            for (AllocationGroup__c ag : groupsToInsert) {
                codeToGroupId.put(ag.AllocationGroupCode__c, ag.Id);
            }
        }
        
        List<Asset> assetsToUpdate = [
            SELECT Id, ECSS_Project_External_Id__c, ECSS_Project_Allocation_Group__c
            FROM Asset
            WHERE Id IN :assetIdsToUpdate AND (RecordTypeId =:unitRecordTypeId OR RecordTypeId =:listingRecordTypeId)
        ];
        
        for (Asset a : assetsToUpdate) {
            Id newGroupId = codeToGroupId.get(a.ECSS_Project_External_Id__c);
            if (newGroupId != null && newGroupId != a.ECSS_Project_Allocation_Group__c) {
                a.ECSS_Project_Allocation_Group__c = newGroupId;
            }
        }
        
        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
    }
    
    public static void ECSS_handleProjectExernalIdChange(List<Asset> newList, Map<Id, Asset> oldMap) {
        Set<Id> projectIds = new Set<Id>();
        Map<Id, Id> assetIdToProjectId = new Map<Id, Id>();
        
        for (Asset a : newList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId){
                Id newProjectId = a.ECSS_Project__c;
                Id oldProjectId = oldMap != null && oldMap.containsKey(a.Id) ? oldMap.get(a.Id).ECSS_Project__c : null;
                
                Boolean isInsert = oldMap == null || !oldMap.containsKey(a.Id);
                
                if (newProjectId != null && (isInsert || newProjectId != oldProjectId)) {
                    projectIds.add(newProjectId);
                    assetIdToProjectId.put(a.Id, newProjectId);
                }
            }
        }
        
        if (projectIds.isEmpty()) return;
        
        Map<Id, String> projectIdToName = new Map<Id, String>();
        for (Project__c p : [SELECT Id, Name,ECSS_ProjectCode__c FROM Project__c WHERE Id IN :projectIds]) {
            projectIdToName.put(p.Id, p.ECSS_ProjectCode__c);
        }
        
        List<Asset> assetsToUpdate = new List<Asset>();
        
        for (Asset a : newList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId){
                if (assetIdToProjectId.containsKey(a.Id)) {
                    Id projectId = assetIdToProjectId.get(a.Id);
                    String projectName = projectIdToName.get(projectId);
                    
                    if (String.isNotBlank(projectName)) {
                        assetsToUpdate.add(new Asset(
                            Id = a.Id,
                            ECSS_Project_External_Id__c = projectName
                        ));
                    }
                }
            }
        }
        
        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
    }
    private static Boolean isRunningSD  = false;
    private static Boolean isRunningTAF = false;
    
    
    public static void ECSS_CalculateSecurityDepositFields(List<Asset> newList, Map<Id, Asset> oldMap) {
        if (isRunningSD) return;
        isRunningSD = true;
        
        List<Asset> assetsToUpdate = new List<Asset>();
        
        for (Asset a : newList) {
            if(a.RecordTypeId == unitRecordTypeId || a.RecordTypeId == listingRecordTypeId){
                
                Asset oldA = (oldMap != null && oldMap.containsKey(a.Id)) ? oldMap.get(a.Id) : null;
                
                if (oldA != null && a.ECSS_Rent_BaseLine__c != oldA.ECSS_Rent_BaseLine__c 
                    && a.ECSS_SD__c == oldA.ECSS_SD__c 
                    && a.ECSS_SD_Amount__c == oldA.ECSS_SD_Amount__c) {
                        continue;
                    }
                
                if (a.ECSS_Rent_BaseLine__c == null || a.ECSS_Rent_BaseLine__c == 0) {
                    assetsToUpdate.add(new Asset(
                        Id = a.Id,
                        ECSS_SD__c = null,
                        ECSS_SD_Amount__c = null
                    ));
                    continue;
                }
                
                Boolean sdPercentChanged = (oldA == null || a.ECSS_SD__c != oldA.ECSS_SD__c);
                Boolean sdAmountChanged  = (oldA == null || a.ECSS_SD_Amount__c != oldA.ECSS_SD_Amount__c);
                
                if (sdPercentChanged && a.ECSS_SD__c != null) {
                    Decimal amount = (a.ECSS_SD__c / 100) * a.ECSS_Rent_BaseLine__c;
                    assetsToUpdate.add(new Asset(
                        Id = a.Id,
                        ECSS_SD_Amount__c = amount.setScale(2)
                    ));
                } 
                else if (sdAmountChanged && a.ECSS_SD_Amount__c != null) {
                    Decimal percent = (a.ECSS_SD_Amount__c / a.ECSS_Rent_BaseLine__c) * 100;
                    assetsToUpdate.add(new Asset(
                        Id = a.Id,
                        ECSS_SD__c = percent.setScale(2)
                    ));
                }
            }
        }
        
        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
        
        isRunningSD = false;
    }
    
    public static void populateUniqueKey(List<Asset> triggerNew) {
        try{
            for(Asset objA : triggerNew) {
                String recName = objA.RecordTypeId!=null?Schema.SObjectType.Asset.getRecordTypeInfosById().get(objA.RecordTypeId).getDeveloperName():'';
                objA.External_Id__c = String.valueOf(objA.Name+'_'+recName).toLowerCase();
            }
        }
        catch(Exception e) {
            System.debug('Exception during unique key '+e.getMessage());
        }
    }
    
    
    
    
}