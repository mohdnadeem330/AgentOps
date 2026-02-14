@isTest
public class ECSS_CustomerUnitControllerTest {
    
    @testSetup static void setup()
    {
       	Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
		List<Asset> assetList = new List<Asset>();
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        assetList.add(ecssUnit);
        Asset functionalUnit = TestObjectsFactory.getFunctionalLocationUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        assetList.add(functionalUnit);
        insert assetList;
        
        newUnit.ECSS_Unit__c = ecssUnit.Id;
   		insert newUnit;
       
    }
     @isTest
    public static void testGetCustomerUnits() {
        Test.startTest();
         Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
        insert newAccount;
        
        Opportunity newOpportunity = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        newOpportunity.SaleType__c = 'New Sale';
        insert newOpportunity;
        
        Asset ecssUnit = [Select Id from Asset Limit 1];
        Customer_Unit__c customerUnitRec = TestObjectsFactory.getCustomerUnit(newAccount.Id,ecssUnit.Id);
        //insert customerUnitRec;
       	
        ECSS_CustomerUnitController.getCustomerUnits(newAccount.Id);
        ECSS_CustomerUnitController.getRelatedUnits(newAccount.Id);
        Test.stopTest();
    }
    @isTest
    public static void testGetRelatedUnits() {
        Test.startTest();
       
         ECSS_CustomerUnitController.getRelatedUnits('');
        Test.stopTest();
    
    }

}