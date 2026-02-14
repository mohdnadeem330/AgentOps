@istest
public with sharing class PIOpportunitySubmissionControllerTest {
   
    @TestSetup
    static void makeData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('P_and_I_Opportunity').getRecordTypeId();
        insert opp;
        Set<String> documents = new Set<String>();
        List<Document__c> docs = new List<Document__c>();
        documents.addall(Label.P_I_Validation_Stage_Document.split(','));
        documents.addall(Label.P_I_Execution_Stage_Document.split(','));
        documents.addall(Label.P_I_Investment_Monitoring_Stage_Document.split(','));
        documents.addall(Label.P_I_Exit_Stage_Document.split(','));
        FOR(String str :documents){
            Document__c docRecord= new Document__c(Opportunity__c=opp.Id,
                            DocumentType__c=str,Status__c = 'Uploaded');
                            docs.add(docRecord);
        }
        
        insert docs;
    }
    @IsTest
    static void testCommonDoctypes(){
        List<Document__c> docs = new List<Document__c>();
        docs =[SELECT Id , DocumentType__c FROM Document__c];
        Opportunity op = [select id,Approval_Status__c from Opportunity];
        
        Test.startTest();
            op.Approval_Status__c = 'None';
        	update op;
            PIOpportunitySubmissionController.submitOpportunity(op.id);
            op.Approval_Status__c = 'Validation approved';
            update op;
            PIOpportunitySubmissionController.submitOpportunity(op.id);
            op.Approval_Status__c = 'Execution approved';
            update op;
            PIOpportunitySubmissionController.submitOpportunity(op.id);
            op.Approval_Status__c = 'Investment Monitoring approved';
            update op;
            PIOpportunitySubmissionController.submitOpportunity(op.id);
        Test.stopTest();
    }
}