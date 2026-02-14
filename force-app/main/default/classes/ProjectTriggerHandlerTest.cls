@isTest
public class ProjectTriggerHandlerTest {
    
    @isTest
    public static void testProjectInsertTrigger() {
        Test.startTest();
        Project__c p1= TestObjectsFactory.getProjectRecord('45223452');
        insert p1;
        Project__c p2= TestObjectsFactory.getProjectRecord('45234452');
        insert p2;
        Test.stopTest();
    }
    @isTest
    public static void testProjectUpdateTrigger() {
        ProjectTriggerHandler handler = new ProjectTriggerHandler();
        Test.startTest();
        List<Project__c> newList = new List<Project__c>();
        Project__c p1= TestObjectsFactory.getProjectRecord('45223452');
        insert p1;
        List<Project__c> oldList = [SELECT Id,Name,CommunityName__c,Description__c,ProjectLocation__c,Amenities__c,City__c,FeaturedProject__c,VirtualTour__c,EnableforDamascus__c FROM Project__c];
        Map<Id,Project__c> oldMap = new Map<Id,Project__c>(oldList);
        
        for(Project__c p : oldList){
            p.CommunityName__c = 'YasGolfCollection';
            newList.add(p);
        }
        update newList;
        Map<Id,Project__c> newMap = new Map<Id,Project__c>(newList);
        handler.afterUpdateMethod(newList,newMap,oldList,oldMap);
        ProjectTriggerHandler.sendUnitsToDamascus(new Set<Id>{p1.Id});
        Test.stopTest();
    }
    
}