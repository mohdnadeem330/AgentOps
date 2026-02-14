/*
***********************************************************************************
Apex Class Name    : DownloadDocumentsControllerTest
Created Date       : Aug 14, 2023
@description       : this Class is using to cover this DownloadDocumentsController
@author            : Moh Sarfaraj
Modification Log:
Ver       Date              Author                               Modification
1.0    14-08-2023        Moh Sarfaraj                          Initial Version
************************************************************************************
*/
@isTest
private class DownloadDocumentsControllerTest{
    @testSetup 
    private static void setUpMethod() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c p = TestObjectsFactory.getProjectRecord('25083');
        insert p;
        
        Project__c p2 = TestObjectsFactory.getProjectRecord('250899');
        insert p2;
        
        Project__c p3 = TestObjectsFactory.getProjectRecord('250899');
        insert p3;
        
        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id); 
        u.Project__c = p.Id;
        insert u;
        
        Unit__c u3 = TestObjectsFactory.unitDataSetup(p3.Id); 
        u3.Project__c = p3.Id;
        insert u3;

        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        sa.Unit__c = u.Id;
        insert sa;
        
        Document__c docRecord = new Document__c(SalesOrder__c = sa.Id, Account__c = acc.Id, DocumentType__c = 'Reservation Agreement');
        insert docRecord;
        
        TestObjectsFactory.createContentDocumentLink(docRecord.Id);
    }
    
    @isTest 
    private static void unitTest(){
        List<Project__c> listProject = [SELECT Id,Name,(SELECT Id,Name FROM UnitsProject__r) FROM Project__c Order BY CreatedDate];
        
        Test.startTest();
        // All Positive Scenarios
        DownloadDocumentsController.getAllActiveProjects();
        DownloadDocumentsController.getDocumentTypes();
        DownloadDocumentsController.DocumentWrapper wrap = DownloadDocumentsController.getAllDocuments(listProject[0].Id, 'Reservation Agreement', String.valueOf(System.today().addDays(-2)), String.valueOf(System.today().addDays(2)));
        System.assertEquals(wrap != null && wrap.success, true, 'It should be Success');
        
        // All Negative Scenarios
        DownloadDocumentsController.getAllDocuments(listProject[1].Id, 'Reservation Agreement', String.valueOf(System.today().addDays(2)), String.valueOf(System.today().addDays(-2)));
        DownloadDocumentsController.getAllDocuments(listProject[2].Id, 'Reservation Agreement', String.valueOf(System.today().addDays(2)), String.valueOf(System.today().addDays(-2)));
        DownloadDocumentsController.getAllDocuments('', 'Reservation Agreement', String.valueOf(System.today().addDays(2)), String.valueOf(System.today().addDays(-2)));
        Test.stopTest();
    }
}