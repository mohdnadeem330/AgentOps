@isTest(SeeAllData=false)
public class UnitDesignTriggerHandlerTest {
    @isTest static void setupMethod() {
        
        User userRecord = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        insert userRecord;
              
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('25083');
        insert projectRecord;
        
        BuildingSection__c  buildingSectionRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingSectionRecord;

        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingSectionRecord.id);
        

        Test.startTest();

            unit.AssignedToUser__c =  userRecord.id;  
            unit.status__c = Constants.UNIT_STATUS_NEW;  
            unit.SellingPrice__c = 1000;
            unit.SellingPriceComments__c = 'Comments';
            insert unit;
            
            TriggerHandler.processedIds = new Set<Id>();
            unit.status__c = Constants.UNIT_STATUS_AVAILABLE;  
            unit.WebFloorPlan__c = 'www.google.com';
            unit.SellingPrice__c = 10000;
            unit.SellingPriceComments__c = 'Commentss';
            update unit;
        
            UnitDesign__c ud = new UnitDesign__c(DesignType__c=UnitDesign__c.DesignType__c.getDescribe().getPicklistValues()[0].getValue(),
                                                GFAArea__c=1,
                                                PremiumAmount__c=1,
                                                SaleableArea__c=1,
                                                SellingPrice__c=1,
                                                TerraceArea__c=1,
                                                Unit__c=unit.id,
                                                WebFloorPlan__c='https://test.com');
            
            insert ud;
            
            ud.WebFloorPlan__c='https://test2.com';
            update ud;
        Test.stopTest();


    }
}