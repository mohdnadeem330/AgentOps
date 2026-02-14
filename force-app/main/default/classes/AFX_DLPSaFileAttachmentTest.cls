/*
* Class Name:  AFX_DLPSaFileAttachmentTest
* Created By : R3-DLP implementation-Smaartt
* Description: test class used for AFX_DLPSaFileAttachmentTest
*/
@isTest
public class AFX_DLPSaFileAttachmentTest {
    
    @isTest
    static void testTriggerLogic() {               
        Test.startTest();
        Account accA = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        accA.MobileNumber__c = '123456789';
        insert accA; 
         User salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
        salesManager.IsActive = TRUE;
        insert salesManager;

        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        project.CommunityName__c = 'Noya';
        insert project;
        
         Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Project__c = project.id;
        unit2.Status__c = 'New';
        unit2.AssignedToUser__c = salesManager.Id;
        unit2.LatitudeLongitude__Latitude__s=32.987650;
        unit2.LatitudeLongitude__Longitude__s=72.345678;
        insert unit2;
        
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        Case caseObj = new Case();
        caseObj.AccountId = accA.id;
        caseObj.RecordtypeId = recordTypeId;
        caseObj.Status = 'New';
        caseObj.Subject = 'Test Case';
        caseObj.Unit__c=unit2.id;
        insert caseObj;
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        WorkType wt = new WorkType();
        wt.Name = 'Technician';        
        wt.EstimatedDuration = 1;
        insert wt;
        
        WorkOrder woObj = new WorkOrder();
        woObj.CaseId = caseObj.Id;
        woObj.AccountId = accA.Id;
        woObj.WorkTypeId =  wt.Id;
        woObj.Status = 'New';
        insert woObj;
        WorkOrderLineItem testWOL = new WorkOrderLineItem(WorkOrder = woObj,WorkTypeId = wt.Id);
        //Insert testWOL;
        Id assessmentRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Assessment').getRecordTypeId();
        ServiceAppointment testSA = new ServiceAppointment();
        //testSA.ParentRecordType= 'WorkOrderLineItem';
        testSA.ParentRecordId =  woObj.Id;       
        testSA.Case__c = caseObj.Id; 
        testSA.RecordTypeId = assessmentRecordTypeId ; 
        
        testSA.EarliestStartTime = system.today(); 
        Insert testSA;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId= caseObj.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;               
        Test.stopTest();
    }
}