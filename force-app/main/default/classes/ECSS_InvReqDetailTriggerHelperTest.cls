@isTest
public class ECSS_InvReqDetailTriggerHelperTest {

    @testSetup
    static void setupTestData() {
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Test Product 1'),
            new Product2(Name = 'Test Product 2')
        };
        insert products;

        List<Asset> assets = new List<Asset>{
            new Asset(Name = 'Test Asset 1', Product2Id = products[0].Id, ECSS_Available_For__c = 'Lease'),
            new Asset(Name = 'Test Asset 2', Product2Id = products[1].Id, ECSS_Available_For__c = 'Sell'),
            new Asset(Name = 'Test Asset 3', Product2Id = products[0].Id, ECSS_Available_For__c = 'Both')
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
    }

    @isTest
    static void testRequestTypeHandler() {
        Inventory_Request_Details__c request = [
            SELECT Id, Status__c, Leasing_Price__c, New_Price__c, Related_Asset__c, 
                   Inventory_Request__r.Request_Type__c, Inventory_Request_Type__c
            FROM Inventory_Request_Details__c 
            WHERE Inventory_Request_Type__c = 'Price Update'
            LIMIT 1
        ];

        System.debug('Before Update - Request: ' + request);

        Map<Id, Inventory_Request_Details__c> oldMap = new Map<Id, Inventory_Request_Details__c>{
            request.Id => request.clone()
        };

        // Update the record to simulate the change
        request.Status__c = 'Approved';

        Test.startTest();
        update request;
       /* ECSS_InvReqDetailTriggerHelper.requestTypeHandler(
            new List<Inventory_Request_Details__c>{request},
            oldMap
        );*/
        Test.stopTest();

        Asset updatedAsset = [
            SELECT ECSS_Leasing_Price__c 
            FROM Asset 
            WHERE Id = :request.Related_Asset__c
        ];

        System.debug('Updated Asset: ' + updatedAsset);
      //  System.assertEquals(1000, updatedAsset.ECSS_Leasing_Price__c, 'Leasing price should be updated.');
    }
  @isTest
    static void testUploadListingHandlerDelete() {
        Inventory_Request_Details__c request = [
            SELECT Id, Status__c, Related_Asset__c, 
                   Inventory_Request__r.Request_Type__c, Inventory_Request_Type__c
            FROM Inventory_Request_Details__c 
            WHERE Inventory_Request_Type__c = 'Upload Listing'
            AND Related_Asset__r.ECSS_Available_For__c = 'Sell'
            LIMIT 1
        ];
        Delete request;
    }
    @isTest
    static void testUploadListingHandler() {
        Inventory_Request_Details__c request = [
            SELECT Id, Status__c, Related_Asset__c, 
                   Inventory_Request__r.Request_Type__c, Inventory_Request_Type__c
            FROM Inventory_Request_Details__c 
            WHERE Inventory_Request_Type__c = 'Upload Listing'
            AND Related_Asset__r.ECSS_Available_For__c = 'Sell'
            LIMIT 1
        ];

        System.debug('Before Update - Request: ' + request);

        Map<Id, Inventory_Request_Details__c> oldMap = new Map<Id, Inventory_Request_Details__c>{
            request.Id => request.clone()
        };

        request.Status__c = 'Approved';

        Test.startTest();
        ECSS_InvReqDetailTriggerHelper.requestTypeHandler(
            new List<Inventory_Request_Details__c>{request},
            oldMap
        );
        Test.stopTest();

        Asset updatedAsset = [
            SELECT Status, ECSS_Available_For__c 
            FROM Asset 
            WHERE Id = :request.Related_Asset__c
        ];

        System.debug('Updated Asset: ' + updatedAsset);
        System.assertEquals('Available for Sales', updatedAsset.Status, 'Asset status should be updated to "Available for Sales".');
    }
}