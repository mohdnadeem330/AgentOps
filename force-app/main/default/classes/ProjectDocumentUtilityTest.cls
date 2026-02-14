// Test class to test ProjectDocumentUtility and ProjectTriggerHandler
@isTest(SeeAllData=false)
public class ProjectDocumentUtilityTest {
    
    @isTest
    public static void testProjectDocumentUtility() {

        List<Id> projectIds = new List<Id>();
        List<Unit__c> units = new List<Unit__c>();

        Project__c p1= TestObjectsFactory.getProjectRecord('45223452');
        insert p1;
        Project__c p2= TestObjectsFactory.getProjectRecord('45234452');
        insert p2;
		Document__c documentRec = new Document__c();
        documentRec.DocumentType__c = 'Project Gallery';
        documentRec.Project__c = p2.Id;
        insert documentRec;
        ContentDocumentLink cdl = TestObjectsFactory.createContentDocumentLink(documentRec.Id);
 
        projectIds.add(p1.id);
        projectIds.add(p2.id);


    	list<ProjectDocumentUtility.ProjectDetails> test= ProjectDocumentUtility.getProjectDetailsRecords(projectIds,false);
        System.assertNotEquals(null,test); 
        list<ProjectDocumentUtility.ProjectDetails> test2= ProjectDocumentUtility.getProjectDetailsRecords(projectIds,true);
        
        ProjectDocumentUtility.PublicLinkDetails pld = new ProjectDocumentUtility.PublicLinkDetails(cdl);
    }
}