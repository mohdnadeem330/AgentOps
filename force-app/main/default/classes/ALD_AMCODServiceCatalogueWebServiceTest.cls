@isTest
public class ALD_AMCODServiceCatalogueWebServiceTest {
	 @testSetup
    static void setup() {
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount;
        Account ac = [SELECT PersonContactId  FROM Account LIMIT 1];
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Account__c =newAccount.Id; 
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        salesOrder.AMCStartDate__c = Date.Today().addDays(-1);
        salesOrder.AMCEndDate__c = Date.Today().addDays(365);
        insert salesOrder;
         
        
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Handyman', IsActive = true,Type__c='On Demand',Family='Apartments- Basic Packages'),
            new Product2(Name = 'Duct Cleaning', IsActive = true,Type__c='On Demand',Family='Apartments- Basic Packages'),
            new Product2(Name = 'Pest Control', IsActive = true,Type__c='On Demand',Family='Apartments- Basic Packages')
        };
        insert products; 
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location'; 
        //loc.Longitude = '28.635308';
		loc.IsInventoryLocation = true;
        insert loc;
         // Name is required
        
        
        
        list<ProductItem> lstPI = new list<ProductItem>();
        for(Product2 p:products){
        	lstPI.add (new ProductItem(Product2Id = p.Id, QuantityOnHand=5,locationId=loc.Id));    
        }
        INSERT lstPI;
        
        OpportunityOfferLine__c oppOff = new OpportunityOfferLine__c();
        oppOff.Name = 'test';
        oppOff.Product_Item__c = lstPI[0].Id;
        oppOff.SalesOrder__c = salesOrder.Id;
        INSERT oppOff;
    }
    
    @isTest
    public static void testODServices1() {
		 test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/LiveAldar/AMCOnDemandServiceCatalogue');
        RestContextHandler handler = new RestContextHandler(true);
        
        String reqBody = '{}';
        RestRequest req = RestContext.request;
        req.requestBody = Blob.valueOf(reqBody);
        ALD_AMCODServiceCatalogueWebService.doPost();
		test.stopTest();        
    }
        @isTest
    public static void testODServices2() {
		 test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/LiveAldar/AMCOnDemandServiceCatalogue');
        RestContextHandler handler = new RestContextHandler(true);
        Account newAccount = [SELECT Id FROM Account LIMIT 1];
        String reqBody = '{"customerId": "' + newAccount.Id + '"}';//
        RestRequest req = RestContext.request;
        req.requestBody = Blob.valueOf(reqBody);
        ALD_AMCODServiceCatalogueWebService.doPost();
		test.stopTest();        
    }
    
}