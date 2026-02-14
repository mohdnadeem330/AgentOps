@isTest(SeeAllData=false)
public class EOIRangeServiceTest {

    //Test class ro test EOIRangeService and EOIRangeTriggerHandler
    @IsTest
    public static void testEOIRangeService() {

        Project__c p= TestObjectsFactory.getProjectRecord('45223452');
        insert p;
        BuildingSection__c b= TestObjectsFactory.getBuildingDetailRecord(p.id);
        b.EOIFee__c = 100;
        insert b;
        EOIRange__c eoi= TestObjectsFactory.getEOIRangeRecord(p.id,b.id);
        eoi.UnitType__c = 'Pent House';
        insert eoi;

        String query = 'SELECT ProjectName__c FROM EOIRange__c where Id = \'' + eoi.id + '\'';

    	list<EOIRange__c> test= EOIRangeService.getEOIRangeQuery(query);
        System.assertNotEquals(null,test);

    }

    
}