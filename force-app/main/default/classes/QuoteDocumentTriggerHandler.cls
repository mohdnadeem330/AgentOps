public class QuoteDocumentTriggerHandler {
    public static void handleAfterInsert(List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Set<Id> quoteIds = new Set<Id>();
        Set<String> parkingReferenceIds = new Set<String>();

        // Collect Quote and ParkingReference IDs
        for (SBQQ__QuoteDocument__c doc : quoteDocuments) {
            parkingReferenceIds.add(String.valueOf(doc.Quote_ParkingReferenceID__c));
            quoteIds.add(doc.SBQQ__Quote__c);
        }
        
        // Query related quotes
        List<SBQQ__Quote__c> quotesToUpdate = [SELECT Id, SBQQ__Primary__c, SBQQ__Status__c, SBQQ__Account__c,Parking_Ref_ID__c FROM SBQQ__Quote__c 
                                               WHERE Id IN :quoteIds AND SBQQ__Primary__c = true];
        
        Map<string,string> assetAccount = new Map<string,string>();
        if (quotesToUpdate.size() > 0) {
            /*
            SBQQ__Quote__c primaryQuote = quotesToUpdate[0];
            
            // Update the quote status and ordered flag
            primaryQuote.SBQQ__Status__c = 'Approved';
            primaryQuote.SBQQ__Ordered__c = true;
            update primaryQuote;
			*/
            
            for(SBQQ__Quote__c quote : quotesToUpdate)
            {
            	// Update the quote status and ordered flag
               // quote.SBQQ__Status__c = 'Approved';
                quote.SBQQ__Ordered__c = true;
                assetAccount.put(quote.Parking_Ref_ID__c,quote.SBQQ__Account__c);
            }
            update quotesToUpdate;
        }
            
            // Query assets based on parking reference IDs
            List<Asset> assetsToUpdate = [SELECT Id, Status, Reserved_Account__c,Parking_Ref_ID__c FROM Asset 
                                          WHERE Ref_ID__c IN :parkingReferenceIds and RecordTypeName__c='Premium_Parking'];
            
            if (assetsToUpdate.size() > 0) {
                for (Asset asset : assetsToUpdate) {
                    asset.Status = 'Reserved';
                    //asset.Reserved_Account__c = primaryQuote.SBQQ__Account__c; // Update Reserved_Account__c from Quote.SBQQ__Account__c
                	asset.Reserved_Account__c = assetAccount.get(string.valueOf(asset.Parking_Ref_ID__c));
                }
                update assetsToUpdate;
            }
    }
}