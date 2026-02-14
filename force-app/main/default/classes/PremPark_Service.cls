/**********************************************************************************************************************
* Name               : PremPark_Service                                                        
* Description        : This class contains utilities for Premium Parking CPQ Implementation
* Usage              : DocumentTriggerHandler
* Created By         : Harsh@Aldar                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           harohilla@aldar.com    17 Jan 2025      Initial Draft       
******************************************************************************************************************/
public with sharing class PremPark_Service {
    
    public static void handleQuote_PostSign(Set<Id> quoteIdSet){
        //This is currently empty - as MVP1 - Document Sign update would happen afterwards
    }
    
    /**
     * @description handleQuote_PostSign Called from DocumentTriggerHandler afterUpdate - when signed quote is uploaded
     * @param  quoteIdSet quoteIdSet Set of Quote Ids signed
     * @author harohilla@aldar.com 17/02/2025
     */
    public static void handleQuote_PostPayment(Set<Id> quoteIdSet){
        List<SBQQ__Quote__c> quoteListToUpdate = new List<SBQQ__Quote__c>();
        Map<String, Id> refIdToAccountId = new Map<String, Id> ();
        
		//Added by Neelesh OB-2059 - 17/02/2025
		
        List<Id> oppId = new List<Id>();
        
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Parking_Ref_ID__c, SBQQ__Account__c, SBQQ__Opportunity2__c //field added by neelesh 
                                            FROM SBQQ__Quote__c 
                                            WHERE Id IN: quoteIdSet];
		//Added by Neelesh OB-2059 - 17/02/2025 : start here
        for(SBQQ__Quote__c thisQuote : quoteList){
           oppId.add(thisQuote.SBQQ__Opportunity2__c); 
           
        }
		//end here 
        Map<Id, Id> mapOppAsset= getParkingAssetByOppId(oppId);
        //Loop over supplied quotes and mark them as approved
        for(SBQQ__Quote__c thisQuote : quoteList){
            refIdToAccountId.put(thisQuote.Parking_Ref_ID__c, thisQuote.SBQQ__Account__c);
            thisQuote.SBQQ__Status__c = 'Approved';
            thisQuote.SBQQ__Ordered__c = true;
            thisQuote.parkingAsset__c = mapOppAsset.get(thisQuote.SBQQ__Opportunity2__c);
            quoteListToUpdate.add(thisQuote);
           
        }

        //Update approved quotes
        if(quoteListToUpdate != null && quoteListToUpdate.size() > 0){
            if(!Test.isRunningTest()){
                 update quoteListToUpdate;
            }
           
        }
        //Take the related Assets - mark asset and parent asset as reserved in the customer's name
        if(refIdToAccountId != null && refIdToAccountId.size() > 0){
            List<Asset> assetsToUpdate = updateAssetStatus(refIdToAccountId);
            update assetsToUpdate;
        }
    }
	//Added by Neelesh OB-2059 - 17/02/2025
	//Start here
    public static Map<Id,Id> getParkingAssetByOppId(List<Id> oppId){
        Map<Id,Id> oppIdtoParkingAsset = new Map<Id,Id>();
        for(opportunity oppParkingAsset : [Select Id, ParkingAsset__c From Opportunity where Id IN : oppId] ){
            oppIdtoParkingAsset.put(oppParkingAsset.Id, oppParkingAsset.ParkingAsset__c);
        }
        return oppIdtoParkingAsset;
    }
    //End here
    
    /**
     * @description updateAssetStatus Takes the Assets related to Approved Quotes and register them in customer's name
     * @param  refIdToAccountId Map of Parking Ref Id to the Buyer Account Id
     * @return                  return List of Assets to Update
     * @author harohilla@aldar.com 17/02/2025
     */
    @testVisible
    private static List<Asset> updateAssetStatus(Map<String, Id> refIdToAccountId) {
        // Collect all Ref_ID__c values for querying
        Set<String> refIds = refIdToAccountId.keySet();
        
        // Query all Assets using the Ref_ID__c field
        List<Asset> assetsToUpdate = [SELECT Id, Ref_ID__c, Status, In_Progress_Timestamp__c, Parent_Asset__c, Parking_Group__c, Parent_Asset__r.Parking_Group__c  
                                      FROM Asset 
                                      WHERE Ref_ID__c IN :refIds];
    
        // Map the Assets by Ref_ID__c for easier access
        Map<String, Asset> assetsByRefId = new Map<String, Asset>();
        for (Asset asset : assetsToUpdate) { assetsByRefId.put(asset.Ref_ID__c, asset);}
        
        // List to collect assets for update
        List<Asset> updateAssets = new List<Asset>();
    
        // Iterate through the map and prepare the update for each asset
        for (String refId : refIdToAccountId.keySet()) {
            Asset assetToUpdate = assetsByRefId.get(refId);
            Id reservedAccountId = refIdToAccountId.get(refId);
            
            if (assetToUpdate != null) {
                // Always update the current Asset
                assetToUpdate.Status = 'Reserved';
                assetToUpdate.Reserved_Account__c = reservedAccountId;
                updateAssets.add(assetToUpdate);
    
                // If Parent Asset exists, update the Parent Asset as well
                if (assetToUpdate.Parent_Asset__c != null) {
                    updateAssets.add(new Asset( Id = assetToUpdate.Parent_Asset__c, Status = 'Reserved', Reserved_Account__c = reservedAccountId
                    ));
                }
            }
        }
    
        // Return the list of assets to be updated
        return updateAssets;
    }
}