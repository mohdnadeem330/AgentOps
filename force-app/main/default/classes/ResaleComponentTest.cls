/**
* ResaleComponentControllerTest
*
* Test class for ResaleComponentController
*/
@isTest
public class ResaleComponentTest {
    //Create setupData
    @testSetup 
    static void setupData() {
        //offer
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.ResaleListed__c = true;
        unitRecord.Listing_Price__c = 10000000;
        // unitRecord.Offer_Accepted__c = false;
        unitRecord.ResaleStatus__c = '';
        insert unitrecord;

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c=null;
        insert opp;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitrecord.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 10000000;
        salesOrder.Account__c = acc.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
    }

    @IsTest
    static void getResaleUnitInfoTest(){
        Id unitId = [SELECT Id FROM Unit__c LIMIT 1][0].Id;
        Test.startTest();
            ResaleComponentController.ResaleUnitInfoWrap unitInfo = ResaleComponentController.getResaleUnitInfo(unitId);
        Test.stopTest();
    }
    
    @IsTest
    static void getsObjectTypeTest(){
        Id recordId = [SELECT Id FROM Opportunity LIMIT 1][0].Id;
        Test.startTest();
            Map<String,object> objectInfo = ResaleComponentController.getsObjectType(recordID);
        Test.stopTest();   
    }
    
    @IsTest
    static void getResaleUnitDetailsTest(){
        Id buildingsId = [SELECT Id FROM BuildingSection__c LIMIT 1][0].Id;
        Test.startTest();
        ResaleComponentController.UnitWrapper unitWrapper = ResaleComponentController.getResaleUnitDetails(buildingsId);
        Test.stopTest();
    }
    
    @IsTest
    static void getAllBuildingsTest(){
        String projectId = [SELECT Id FROM Project__c LIMIT 1][0].Id;
        Test.startTest();
            List<Map<String, String>> buildings = ResaleComponentController.getAllBuildings(projectId);
        Test.stopTest();
    }

    @IsTest
    static void getAllProjectsTest(){
        Test.startTest();
            List<Map<String, String>> projects = ResaleComponentController.getAllProjects();
        Test.stopTest();
    }

    @IsTest
    static void fetchSalesOrderIdTest(){
        String unitId = [SELECT Id FROM Unit__c LIMIT 1][0].Id;
        Test.startTest();
            SObject sobj = ResaleComponentController.fetchSalesOrderId(unitId);
        Test.stopTest();
    }

    @IsTest
    static void updateSobjectTest(){
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        SalesOrder__c so = [SELECT Id, Account__c, Unit__c FROM SalesOrder__c LIMIT 1];

        Map<String, Object> sObjMap = new Map<String, Object>{
            'Opportunity__c' => opp.Id,
            'Buyer_Account__c' => opp.AccountId,
            'Sales_Order__c' => so.Id,
            'Unit__c' => so.Unit__c,
            'Seller_Account__c' => so.Account__c,
            'Comments__c' => 'Please Accept',
            'Offer_Price__c' => 10000000
        };
        Test.startTest();
            SObject sobj = ResaleComponentController.updateSobject(sObjMap);
        Test.stopTest();        
    }

    @IsTest
    static void fetchResaleDataTest(){
        String unitId = [SELECT Id FROM Unit__c LIMIT 1][0].Id;
        Test.startTest();
            List<Resale_Offers__c> resaleOffers = ResaleComponentController.fetchResaleData(unitId);
        Test.stopTest();
    }
}