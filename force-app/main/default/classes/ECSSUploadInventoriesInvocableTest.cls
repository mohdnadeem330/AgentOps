@isTest
public class ECSSUploadInventoriesInvocableTest {
    @isTest
    static void calculateBusinessHours() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Villa'),
            new Product2(Name = 'Apartment')
        };
        insert products;
        
        Id listingRecordTypeId =  Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get('Listing').getRecordTypeId();
           
        List<Asset> assets = new List<Asset>{
            new Asset(Name = 'Test Asset 1', Product2Id = products[0].Id, ECSS_Available_For__c = 'Lease',ExternalIdentifier = '2',ECSS_Unit_Type__c = 'Villa',recordtypeId = listingRecordTypeId),
            new Asset(Name = 'Test Asset 2', Product2Id = products[1].Id, ECSS_Available_For__c = 'Sell',ExternalIdentifier = '1' ,ECSS_Unit_Type__c = 'Villa'),
            new Asset(Name = 'Test Asset 3', Product2Id = products[0].Id, ECSS_Available_For__c = 'Both', ExternalIdentifier = '3' ,ECSS_Unit_Type__c = 'Villa')
        };
        insert assets;
        
        Trigger_Enabler__c trg = TestObjectsFactory.getTriggerEnablerInventoryReq();
        insert trg;
        Inventory_Request__c inventoryRequest1 = new Inventory_Request__c(Request_Type__c = 'Price Update');
        Inventory_Request__c inventoryRequest2 = new Inventory_Request__c(Request_Type__c = 'Upload Listing');
        insert new List<Inventory_Request__c>{inventoryRequest1, inventoryRequest2};

        List<Inventory_Request_Details__c> requests = new List<Inventory_Request_Details__c>{
            new Inventory_Request_Details__c(
                Status__c = 'Pending Approval',
                Leasing_Price__c = true,
                New_Price__c = 1000,
                Related_Asset__c = assets[0].Id,
                Inventory_Request__c = inventoryRequest1.Id
            ),
            new Inventory_Request_Details__c(
                Status__c = 'Pending Approval',
                Related_Asset__c = assets[1].Id,
                Inventory_Request__c = inventoryRequest2.Id
            ),
            new Inventory_Request_Details__c(
                Status__c = 'Pending Approval',
                Related_Asset__c = assets[2].Id,
                Inventory_Request__c = inventoryRequest2.Id
            )
        };
        insert requests;
        
        
        uploadInventoriesInvocable.InventoriesWrapper wrapper = new uploadInventoriesInvocable.InventoriesWrapper();
        wrapper.inventoryList = assets;
        wrapper.uploadType = 'Listing';
        wrapper.inventoryRequest = inventoryRequest1.Id;
        List<uploadInventoriesInvocable.InventoriesWrapper> wrapperList = new List<uploadInventoriesInvocable.InventoriesWrapper>();
        wrapperList.add(wrapper);
        uploadInventoriesInvocable.createInventories(wrapperList);
        
    }
}