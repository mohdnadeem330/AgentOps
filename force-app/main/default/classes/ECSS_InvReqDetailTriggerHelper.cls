public class ECSS_InvReqDetailTriggerHelper { 
    
    public static void requestTypeHandler(List<Inventory_Request_Details__c> newList, Map<Id, Inventory_Request_Details__c> oldMap){
        
        List<Product2> unitsToUpdate = new List<Product2>();
        List<Asset> assetsToUpdate = new List<Asset>();
        List<Inventory_Request_Details__c> requestsToUpdate = new List<Inventory_Request_Details__c>();
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id FROM Product2]);
        Map<Id, Asset> assetMap = new Map<Id,Asset>([SELECT Id, ECSS_Available_For__c FROM Asset]);
        
        
        for (Inventory_Request_Details__c newRec : newList) {
            
            ///////////PriceUpdateRequest//////////////////////
            if(newRec.Inventory_Request_Type__c == 'Price Update' && newRec.Status__c == 'Approved' && oldMap.get(newRec.Id).Status__c != 'Approved'){
                Asset tempAsset = assetMap.get(newRec.Related_Asset__c);
                if(newRec.Leasing_Price__c){
                    tempAsset.ECSS_Leasing_Price__c = newRec.New_Price__c;
                }
                else{
                    tempAsset.ECSS_Selling_Price__c = newRec.New_Price__c;
                    
                }
                assetsToUpdate.add(tempAsset);                    
            }
            
            ///////////UploadRequest//////////////////////
            if(newRec.Inventory_Request_Type__c == 'Upload Listing' && newRec.Status__c != oldMap.get(newRec.Id).Status__c){
                Asset asset = assetMap.get(newRec.Related_Asset__c);
                
                if (asset != null) {
                    if (newRec.Status__c == 'Rejected') {
                        asset.Status= 'Listing Rejected';
                        assetsToUpdate.add(asset);
                    }else if(newRec.Status__c == 'Approved'){
                        if (asset.ECSS_Available_For__c == 'Lease') {
                            asset.Status = 'Available for Leasing';
                            
                        } else if(asset.ECSS_Available_For__c == 'Sell') {
                            asset.Status = 'Available for Sales';
                        }else{
                            asset.Status = 'Available for Both';
                        }
                        assetsToUpdate.add(asset);                    
                    }
                }
            }
        }
        
        
        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
        if (!requestsToUpdate.isEmpty()) {
            update requestsToUpdate;
        }
    }
    
    
 
    
}