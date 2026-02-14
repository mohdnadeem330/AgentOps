//ECSS//
public class uploadInventoriesInvocable {
    
    @InvocableMethod
    public static List<returnWrapper> createInventories(List<InventoriesWrapper> inventoriesWrapper){
        List<Asset> inventories = inventoriesWrapper[0].inventoryList;
        String invRequestId = inventoriesWrapper[0].inventoryRequest;
        String uploadType = inventoriesWrapper[0].uploadType;
        Id listingRecordTypeId =  Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get('Listing').getRecordTypeId();
        Id unitRecordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Ecss_unit').getRecordTypeId();
        List<returnWrapper> returnList = new List<returnWrapper>();
        returnWrapper ret = new returnWrapper();
        boolean saleFlag = false;
        boolean leaseFlag = false;
        Map<String,Id> userEmailToIdMap = new Map<String,Id>();
        
        for (User user : [SELECT Id, Email FROM User WHERE Email != null]) {
            userEmailToIdMap.put(user.Email.toLowerCase(), user.Id);
        }
        
        List<Asset> listingProductsToCreate = new List<Asset>();
        List<Asset> inventoriesToCreate = new List<Asset>();
        if(uploadType.contains('Listing'))
            Inventory_Request__c invReq = [SELECT Id, Name From Inventory_Request__c where Id =: invRequestId];
        List<Inventory_Request_Details__c> invReqDetailsToCreate = new List<Inventory_Request_Details__c>();
        List<String> duplicateUnits = new List<String>();
        List<String> existingUnits = new List<String>();
        Map<String,Asset> existingProductMap = new Map<String,Asset>() ;
        Map<String,Product2> existingProducts = new Map<String,Product2>();
        for (Product2 prod : [SELECT Id,Name From Product2]) {
            existingProducts.put(prod.Name, prod);
        }
        
        if(uploadType.contains('Listing')){
            for (Asset asset : [SELECT Id,Name,ExternalIdentifier From Asset where RecordTypeId =: listingRecordTypeId]) {
                existingProductMap.put(asset.ExternalIdentifier, asset);
            }
        }else{
            for (Asset asset : [SELECT Id,Name,ExternalIdentifier From Asset]) {
                existingProductMap.put(asset.ExternalIdentifier, asset);
            }
        }
        Set<String> processedExternalIds = new Set<String>();
        
        
        
        for(Asset inv: inventories){
            
            if(inv.ECSS_Available_For__c == 'Sell')
                saleFlag = true;
            
            if(inv.ECSS_Available_For__c == 'Lease')
                leaseFlag = true;
            
            if(((leaseFlag && saleFlag) || inv.ECSS_Available_For__c  == 'Both') && uploadType.contains('Listing') ) {
                ret.errorMessage = 'Products of Different Types';
                returnList.add(ret);
                break;
            }else{
                if(inv.ExternalIdentifier != null){
                    if(!processedExternalIds.contains(inv.ExternalIdentifier)){
                        processedExternalIds.add(inv.ExternalIdentifier);
                    }else{
                        
                        if(inv.Name != null){
                            duplicateUnits.add(inv.Name);
                        }else{
                            duplicateUnits.add(inv.ExternalIdentifier);
                        }
                    }
                    
                    if (existingProductMap.containsKey(inv.ExternalIdentifier)){
                        existingUnits.add(inv.ExternalIdentifier);
                        if(uploadType.contains('Listing')){
                            Inventory_Request_Details__c invRequestDetails = new Inventory_Request_Details__c();
                            invRequestDetails.Inventory_Request__c = invRequestId;
                            invRequestDetails.Related_Asset__c = existingProductMap.get(inv.ExternalIdentifier).Id;
                            invReqDetailsToCreate.add(invRequestDetails);
                            
                        }
                    }
                    
                    
                    if (inv.OwnerId != null) {
                        Id newOwnerId = userEmailToIdMap.get(inv.OwnerId);
                        
                        if (newOwnerId != null) {
                            inv.OwnerId = newOwnerId;
                        } 
                    }
                    inv.Product2Id = existingProducts.get(inv.ECSS_Unit_Type__c ).Id;
                    system.debug(existingProducts.get(inv.ECSS_Unit_Type__c).Id);
                    if(uploadType.contains('Listing')){
                        
                        inv.RecordTypeId = listingRecordTypeId;
                        
                        if(!existingProductMap.containsKey(inv.ExternalIdentifier)){
                            inv.Status = 'Draft';
                            listingProductsToCreate.add(inv);
                            
                        }
                        
                    }else{
                        inv.RecordTypeId = unitRecordTypeId;
                        
                        if(!existingProductMap.containsKey(inv.ExternalIdentifier))
                            inventoriesToCreate.add(inv);
                    }
                    
                    
                }
            }
        }
        if(!returnList.isEmpty())
            return returnList;
        /*
        if(duplicateUnits.isEmpty()){
            
            if(!listingProductsToCreate.isEmpty()){
                insert listingProductsToCreate;
                
                
                List<Asset> createdUnits = new list<Asset>();
                createdUnits.addAll(listingProductsToCreate);
                system.debug(listingProductsToCreate);
                
                for(Asset inv: createdUnits){
                    Inventory_Request_Details__c invRequestDetails = new Inventory_Request_Details__c();
                    invRequestDetails.Inventory_Request__c = invRequestId;
                    invRequestDetails.Related_Asset__c = inv.ID;
                    
                    System.debug(invRequestDetails);
                    
                    if(uploadType.contains('Listing'))
                        invReqDetailsToCreate.add(invRequestDetails);
                    
                }
            }
            
            if(!inventoriesToCreate.isEmpty())
                insert inventoriesToCreate;
			*/
            /*
            if(!invReqDetailsToCreate.isEmpty()){
                insert invReqDetailsToCreate;
                
                User leasingDirector = [SELECT Id, Name, UserRole.Name FROM User WHERE UserRole.Name = 'Leasing Director' Limit 1];
                User salesDirector = [SELECT Id, Name, UserRole.Name FROM User WHERE UserRole.Name = 'Director of Sales' Limit 1];
                Inventory_Request__c invReq = [SELECT Id,OwnerId FROM Inventory_Request__c WHERE Id=:invRequestId ];
                if(leaseFlag)
                    invReq.OwnerId = leasingDirector.Id;
                if(saleFlag)
                    invReq.OwnerId = salesDirector.Id;
                update invReq;
                
                CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Assignment_Notifications'];
                
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId(notificationType.Id); // Set the notification type ID
                notification.setTitle('New Listing Upload Request'); // Title of the notification
                notification.setBody('A new Listing Request has been uploaded'); // Notification body message
                notification.setTargetId(invRequestId); // The target record (e.g., an Asset record)
                notification.send(new Set<String>{invReq.OwnerId});
                
            }
            
            
        } */
        /*
        if(!existingUnits.isEmpty())
            ret.existingUnits = existingUnits;
        
        if(!duplicateUnits.isEmpty())
            ret.duplicateUnits = duplicateUnits;
        
        if(ret != null){
            returnList.add(ret);
            return returnList;
        }else{
            return null;
        }*/
        return null;
    }
    
    
    public class InventoriesWrapper{
        @InvocableVariable
        public List<Asset> inventoryList;
        @InvocableVariable
        public String inventoryRequest;
        @InvocableVariable
        public String uploadType;
        
    }
    
    public class returnWrapper{
        @InvocableVariable
        public List<String> duplicateUnits;
        @InvocableVariable
        public List<String> existingUnits;
        @InvocableVariable
        public String errorMessage;
    }
    
}