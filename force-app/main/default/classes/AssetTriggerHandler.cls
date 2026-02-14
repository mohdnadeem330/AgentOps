public without sharing class AssetTriggerHandler extends TriggerHandler {
	
     public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap)
    {
        List<Asset> newListAssets = (List<Asset>) newList;
        handleBeforeInsert(newListAssets);
    }
    // Called by the trigger after insert
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        handleAfterInsertOrUpdate((List<Asset>) newList, null);
        List<Asset> newListAssets = (List<Asset>) newList;
        Map<Id, Asset> newMapAssets = New Map<Id, Asset>((List<Asset>) newMap.values());
        handleAfterInsert(newListAssets,newMapAssets);
    }

    // Called by the trigger after update
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        List<Asset> newListAssets = (List<Asset>) newList;
        Map<Id, Asset> oldMapAssets = new Map<Id, Asset>();
        
        for (Id assetId : oldMap.keySet()) {
            oldMapAssets.put(assetId, (Asset) oldMap.get(assetId));
        }
        
        handleAfterInsertOrUpdate(newListAssets, oldMapAssets);
        
        
        List<Asset> newUpdatedListAssets = (List<Asset>)newList;
        System.debug('newUpdatedListAssets: '+newUpdatedListAssets);
        Map<Id,Asset> newAssetsMap = New Map<Id, Asset>((List<Asset>)newMap.values());
        List<Asset> oldListAssets = (List<Asset>) oldList;
        Map<Id,Asset> oldAssetsMap = New Map<Id, Asset>((List<Asset>)oldMap.values());
        handleAfterUpdate(newUpdatedListAssets,oldAssetsMap,newAssetsMap);
    }
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
    }

    public static void handleAfterInsertOrUpdate(List<Asset> newAssets, Map<Id, Asset> oldAssetMap) {
        if (newAssets == null || newAssets.isEmpty()) return;

        // Get RecordType Ids
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Asset.getRecordTypeInfosByName();
        Id ecssUnitRtId = rtMap.get('Ecss Unit')?.getRecordTypeId();
        Id funcLocRtId = rtMap.get('Functional Location')?.getRecordTypeId();
        if (ecssUnitRtId == null || funcLocRtId == null) return;

        List<String> sfUnitCodes = new List<String>();
        List<Asset> updatedAssets = new List<Asset>();
        Map<String, Asset> unitNameToAssetMap = new Map<String, Asset>();

        // Identify Functional_Location assets whose SF_Unit_Code__c was changed
        for (Asset assetRecord : newAssets) {
           if (assetRecord.RecordTypeId == funcLocRtId) {
                Boolean isChanged = oldAssetMap == null || (oldAssetMap.get(assetRecord.Id) != null &&
                    assetRecord.SF_Unit_Code__c != oldAssetMap.get(assetRecord.Id).SF_Unit_Code__c);

                if (isChanged && assetRecord.SF_Unit_Code__c != null) {
                    sfUnitCodes.add(assetRecord.SF_Unit_Code__c);
                    updatedAssets.add(assetRecord);
                }
            }
        }

        if (sfUnitCodes.isEmpty()) return;

        // Find corresponding Ecss_unit assets whose Unit__r.Name matches SF_Unit_Code__c
        for (Asset ecssAsset : [
            SELECT Id, Unit__r.Name
            FROM Asset
            WHERE RecordTypeId = :ecssUnitRtId
            AND Unit__r.Name IN :sfUnitCodes
        ]) {
            if (ecssAsset.Unit__r?.Name != null) {
                unitNameToAssetMap.put(ecssAsset.Unit__r.Name, ecssAsset);
            }
        }

        if(unitNameToAssetMap.isEmpty()) return;

        List<Asset> assetsToUpdate = new List<Asset>();

        // Update ParentId of matching Functional_Location assets
        for (Asset asset : updatedAssets) {
            Asset ecssAsset = unitNameToAssetMap.get(asset.SF_Unit_Code__c);
            if (ecssAsset != null) {
                assetsToUpdate.add(new Asset(
                    Id = asset.Id,
                    ParentId = ecssAsset.Id
                ));
            }
        }

        if (!assetsToUpdate.isEmpty()) {
            try {
                update assetsToUpdate;
            } catch (DmlException e) {
                System.debug('Failed to update Assets: ' + e.getMessage());
                // Optional: Replace with custom logging
            }
        }
    }
    
    public static void handleAfterInsert(List<Asset> newList , map<Id,Asset> newMap){
        //ECSS_AssetTriggerHelper.handleAfterInsertAsync(newMap.keySet());
        // ECSS_AssetTriggerHelper.handleAssetInsert(newList);
        ECSS_AssetTriggerHelper.linkInventoryReqToAssets(newList);
        ECSS_AssetTriggerHelper.ECSS_handleProjectExernalIdChange(newList, null);
        ECSS_AssetTriggerHelper.ECSS_handleAreaChange(newList, null); 
        ECSS_AssetTriggerHelper.ECSS_handleProjectChange(newList, null);
        //ECSS_AssetTriggerHelper.ECSS_CalculateSecurityDepositFields(newList, null);
        //ECSS_AssetTriggerHelper.ECSS_CalculateTAFFields(newList, null);
        
    }
    
    public static void handleBeforeInsert(List<Asset> newList) {
        ECSS_AssetTriggerHelper.externalIdRecords(newList);
        
        
    }
    public static void handleAfterUpdate(List<Asset> newList, Map<Id, Asset> oldMap, Map<Id, Asset> newMap) {
        //  ECSS_AssetTriggerHelper.handleAssetUpdate(newList, oldMap);
        ECSS_AssetTriggerHelper.linkInventoryReqToAssets(newList);
        //ECSS_AssetTriggerHelper.removeQuoteLineItemsForUnderOfferAssets(newList, oldMap);
        ECSS_AssetTriggerHelper.handleProjectAllocationGroupShare(newList, oldMap);
        ECSS_AssetTriggerHelper.handleAreaAllocationGroupShare(newList, oldMap);
        ECSS_AssetTriggerHelper.ECSS_handleAreaChange(newList, oldMap);
        ECSS_AssetTriggerHelper.ECSS_handleProjectChange(newList, oldMap);
        ECSS_AssetTriggerHelper.ECSS_handleProjectExernalIdChange(newList, oldMap);
        //ECSS_AssetTriggerHelper.ECSS_CalculateSecurityDepositFields(newList, oldMap);
        //ECSS_AssetTriggerHelper.ECSS_CalculateTAFFields(newList, oldMap);
        
        
    }
}