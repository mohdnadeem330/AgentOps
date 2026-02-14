@isTest(SeeAllData=false)
public class ViewPropertiesControllerTest {

    @IsTest
    public static void testViewPropertiesController() {
        List<Unit__c> units = new List<Unit__c>();

        Project__c p= TestObjectsFactory.getProjectRecord('45223452');
        insert p;
        BuildingSection__c b= TestObjectsFactory.getBuildingDetailRecord(p.id);
        insert b;
        units.add(TestObjectsFactory.getUnitDetail(p.id,b.id));
        units.add(TestObjectsFactory.getUnitDetail(p.id,b.id));
        insert units;

        list<ViewPropertiesController.projectDataWrapper> testParam1= ViewPropertiesController.brokerProjects('','','');
        list<ViewPropertiesController.projectDataWrapper> testParam2= ViewPropertiesController.brokerProjects(p.Name,'','');
        list<ViewPropertiesController.projectDataWrapper> testParam3= ViewPropertiesController.brokerProjects('',p.City__c,'');
        list<ViewPropertiesController.projectDataWrapper> testParam4= ViewPropertiesController.brokerProjects(p.Name,p.City__c,'');
        Project__c test= ViewPropertiesController.brokerProjectById(p.Id);
        ViewPropertiesController.brokerProjectGallery(p.id);
        System.assertNotEquals(null,testParam1); 
        System.assertNotEquals(null,testParam2); 
        System.assertNotEquals(null,testParam3); 
        System.assertNotEquals(null,testParam4); 
        System.assertNotEquals(null,test);

    }

    
}