@isTest(SeeAllData=false)
public class ProjectServiceTest {
    @isTest static void setupMethod() {

        Project__c projectRecord= TestObjectsFactory.getProjectRecord('25083');

        Test.startTest();
        insert projectRecord;
        ProjectService.getAllActiveProjects();
        // ProjectService.getActiveProjects();
        Test.stopTest();
    }
}