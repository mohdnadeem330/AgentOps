public class ECSS_AssetTriggerHandler {
    
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