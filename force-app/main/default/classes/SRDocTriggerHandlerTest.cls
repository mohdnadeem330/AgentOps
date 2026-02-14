@isTest(SeeAllData=false)
public class SRDocTriggerHandlerTest {
    @testSetup static void testData(){
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus(Constants.SR_STATUS_CLOSED);     
        Submitted.HexaBPM__Type__c = 'End';
        insert Submitted; 
    }
 
    @isTest static void setupMethod() {
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.PENDING_STATUS;
        status.HexaBPM__Code__c = Constants.PENDING_STATUS;
        insert status;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
       
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Project__c project = new Project__c();
        project.Id = unit.Project__c;
        project.Name = 'Mayan';
        update project;
        
        Document__c documentMCD = TestObjectsFactory.getProjectDocument(project.Id);
        documentMCD.DocumentType__c = Constants.DOCUMENT_TYPE_MCD;
        insert documentMCD;
        
        Document__c documentScheduleA = TestObjectsFactory.getProjectDocument(project.Id);
        documentScheduleA.DocumentType__c = Constants.DOCUMENT_TYPE_SCHEDULE_A;
        insert documentScheduleA;
        
        Document__c documentTradeLic = TestObjectsFactory.getProjectDocument(project.Id);
        documentTradeLic.DocumentType__c = Constants.DOCUMENT_TYPE_Commercial_Trade_License;
        insert documentTradeLic;
        
        Document__c documentBankLetter = TestObjectsFactory.getProjectDocument(project.Id);
        documentBankLetter.DocumentType__c = Constants.DOCUMENT_TYPE_Bank_Letter;
        insert documentBankLetter;
        
        ContentDocumentLink documentLink = TestObjectsFactory.createContentDocumentLink(documentMCD.Id);
 
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.MortgageApplicable__c = 'Yes';
        insert salesOrder;        
                
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE);        
        insert SRTemplateDetailRecord;
 
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, 'InternalMortgageDischarge');
        insert objStepTemplate;
 
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
 
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       
        Id mortgageDischargeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE);
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
 
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;
 
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Agency_Agreement_Document';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        //docTemp.Stage__c = 'Licensed';
        insert docTemp;
 
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SRTemplateDetailRecord.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = objStepTemplate.Id;
        SRStep.HexaBPM__Summary__c = 'Test';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        SRStep.DocusignExpiryinDays__c=2;
        insert SRStep;
 
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'AgencyRegistration';
        step.HexaBPM__SR__c = newSR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        
        Test.startTest();
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id  ;
        objSRDoc.HexaBPM__Step__c=step.Id;
        objSRDoc.Name = Constants.DOCUMENT_TYPE_MCD;
        insert objSRDoc;
        
        TriggerHandler.processedIds = new Set<Id>();
        objSRDoc.HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        objSRDoc.Name = Constants.DOCUMENT_TYPE_MCD;
        update objSRDoc;
        
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSR1.SalesOrder__c = salesOrder.Id;
        newSR1.SPACounterSignedDate__c=Date.today();
        insert newSR1;
        
        TriggerHandler.processedIds = new Set<Id>();
        List<HexaBPM__SR_Doc__c> srDocList = new List<HexaBPM__SR_Doc__c>();
        HexaBPM__SR_Doc__c objSRDoc22 = new HexaBPM__SR_Doc__c();
        objSRDoc22.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc22.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc22.HexaBPM__Service_Request__c = newSR1.id  ;
        objSRDoc22.HexaBPM__Step__c=step.Id;
        objSRDoc22.Name = Constants.ADM_RECEIPT_SRDOC;
        srDocList.add(objSRDoc22);
        
        HexaBPM__SR_Doc__c objSRDo33 = new HexaBPM__SR_Doc__c();
        objSRDo33.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDo33.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDo33.HexaBPM__Service_Request__c = newSR1.id  ;
        objSRDo33.HexaBPM__Step__c = step.Id;
        objSRDo33.Name = 'Move In Permit';
        objSRDo33.HexaBPM__Status__c = 'Generated';
        srDocList.add(objSRDo33);
        insert srDocList;
        
        TriggerHandler.processedIds = new Set<Id>();
        objSRDoc22.HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        update objSRDoc22;
        SRDocTriggerHandler.sendSnagComms(new map<ID,String>());
        
        SRDocTriggerHandler.mapLpcDetilsToHandoverSR(new List<Id>{newSR1.Id});
        
        Test.stopTest();
        
        
        /*TriggerHandler.processedIds = new Set<Id>();
        objSRDoc.HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        objSRDoc.Name = Constants.DOCUMENT_TYPE_MCD;
        update objSRDoc;
        
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSR1.SalesOrder__c = salesOrder.Id;
        newSR1.SPACounterSignedDate__c=Date.today();
        insert newSR1;*/
        
        /*TriggerHandler.processedIds = new Set<Id>();
        List<HexaBPM__SR_Doc__c> srDocList = new List<HexaBPM__SR_Doc__c>();
        Test.startTest();
        HexaBPM__SR_Doc__c objSRDoc22 = new HexaBPM__SR_Doc__c();
        objSRDoc22.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc22.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc22.HexaBPM__Service_Request__c = newSR1.id  ;
        objSRDoc22.HexaBPM__Step__c=step.Id;
        objSRDoc22.Name = Constants.ADM_RECEIPT_SRDOC;
        //srDocList.add(objSRDoc22);
        insert objSRDoc22;
        
        /*HexaBPM__SR_Doc__c objSRDo33 = new HexaBPM__SR_Doc__c();
        objSRDo33.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDo33.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDo33.HexaBPM__Service_Request__c = newSR1.id  ;
        objSRDo33.HexaBPM__Step__c = step.Id;
        objSRDo33.Name = Constants.ADM_RECEIPT_SRDOC;
        srDocList.add(objSRDo33);*/
        
        //insert srDocList;
        
        /*TriggerHandler.processedIds = new Set<Id>();
        objSRDoc22.HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        update objSRDoc22;
        SRDocTriggerHandler.sendSnagComms(new map<ID,String>());
        
        SRDocTriggerHandler.mapLpcDetilsToHandoverSR(new List<Id>{newSR1.Id});
        Test.stopTest();*/
        
 
    }
    
    /*@isTest static void unitTest1() {
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.PENDING_STATUS;
        status.HexaBPM__Code__c = Constants.PENDING_STATUS;
        insert status;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
       
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Project__c project = new Project__c();
        project.Id = unit.Project__c;
        project.Name = 'Mayan';
        update project;
        
        Document__c documentMCD = TestObjectsFactory.getProjectDocument(project.Id);
        documentMCD.DocumentType__c = Constants.DOCUMENT_TYPE_MCD;
        insert documentMCD;
        
        Document__c documentScheduleA = TestObjectsFactory.getProjectDocument(project.Id);
        documentScheduleA.DocumentType__c = Constants.DOCUMENT_TYPE_SCHEDULE_A;
        insert documentScheduleA;
        
        Document__c documentTradeLic = TestObjectsFactory.getProjectDocument(project.Id);
        documentTradeLic.DocumentType__c = Constants.DOCUMENT_TYPE_Commercial_Trade_License;
        insert documentTradeLic;
        
        Document__c documentBankLetter = TestObjectsFactory.getAccountDocument(acc.Id);
        documentBankLetter.DocumentType__c = 'Passport Copy';
        insert documentBankLetter;
        
        ContentDocumentLink documentLink = TestObjectsFactory.createContentDocumentLink(documentBankLetter.Id);
 
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.MortgageApplicable__c = 'Yes';
        insert salesOrder;
 
        HexaBPM__SR_Template__c template = new HexaBPM__SR_Template__c();
        template.HexaBPM__SR_RecordType_API_Name__c = 'PropertyTransfer';
        template.Name = 'Property Transfer NOC';
        insert template;
 
 
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, 'InternalMortgageDischarge');
        insert objStepTemplate;
 
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(template.Id, objStepTemplate.Id);
        insert objSRSteps;
 
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       Test.startTest();
        Id recordTypeIdOfPT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_TYPE);
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
 
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, '', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Agency Registration'), template.Id);
        newSR.SalesOrder__c = salesOrder.Id;        
        newSR.Unit__c = unit.Id;  
        newSR.IsComplianceReturned__c = false;
        newSR.Compliance_Status__c = '';
        newSR.TransferSellingPrice__c= 1000000;
        newSR.Origin__c ='Customer Portal';
        newSR.SRType__c ='Property Transfer NOC';
        newSR.HexaBPM__SR_Template__c = template.id;
        insert newSR;
 
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Agency_Agreement_Document';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        //docTemp.Stage__c = 'Licensed';
        insert docTemp;
 
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = objStepTemplate.Id;
        SRStep.HexaBPM__Summary__c = 'Test';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        SRStep.DocusignExpiryinDays__c=2;
        insert SRStep;
 
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'AgencyRegistration';
        step.HexaBPM__SR__c = newSR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        
        //Test.startTest();
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id  ;
        objSRDoc.HexaBPM__Step__c = step.Id;
        objSRDoc.Name = 'Signed Owner Association Letter';
        objSRDoc.HexaBPM__Status__c = 'Uploaded';
        insert objSRDoc;
        
        HexaBPM__SR_Doc__c objSRDoc2 = new HexaBPM__SR_Doc__c();
        objSRDoc2.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc2.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc2.HexaBPM__Service_Request__c = newSR.id  ;
        objSRDoc2.HexaBPM__Step__c = step.Id;
        objSRDoc2.Name = 'Signed Assignment of Service Charge';
        objSRDoc2.HexaBPM__Status__c = 'Uploaded';
        insert objSRDoc2;
        
        HexaBPM__SR_Doc__c objSRDoc3 = new HexaBPM__SR_Doc__c();
        objSRDoc3.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc3.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc3.HexaBPM__Service_Request__c = newSR.id  ;
        objSRDoc3.HexaBPM__Step__c = step.Id;
        objSRDoc3.Name = 'Seller Passport Copy';
        insert objSRDoc3;
        
        Map<String,HexaBPM__Status__c> statusMap= new Map<String,HexaBPM__Status__c>();
        statusMap.put(status.name,status);
        SRDocTriggerHandler.handleSRStepAutomation(objSRDoc,statusMap);
        Test.stopTest();
    }*/
    
     @isTest static void unitTest1() {
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.PENDING_STATUS;
        status.HexaBPM__Code__c = Constants.PENDING_STATUS;
        insert status;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
       
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Project__c project = new Project__c();
        project.Id = unit.Project__c;
        project.Name = 'Mayan';
        update project;
        
        Document__c documentMCD = TestObjectsFactory.getProjectDocument(project.Id);
        documentMCD.DocumentType__c = Constants.DOCUMENT_TYPE_MCD;
        insert documentMCD;
        
        Document__c documentScheduleA = TestObjectsFactory.getProjectDocument(project.Id);
        documentScheduleA.DocumentType__c = Constants.DOCUMENT_TYPE_SCHEDULE_A;
        insert documentScheduleA;
        
        Document__c documentTradeLic = TestObjectsFactory.getProjectDocument(project.Id);
        documentTradeLic.DocumentType__c = Constants.DOCUMENT_TYPE_Commercial_Trade_License;
        insert documentTradeLic;
        
        Document__c documentBankLetter = TestObjectsFactory.getAccountDocument(acc.Id);
        documentBankLetter.DocumentType__c = 'Passport Copy';
        insert documentBankLetter;
        
        ContentDocumentLink documentLink = TestObjectsFactory.createContentDocumentLink(documentBankLetter.Id);
 
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.MortgageApplicable__c = 'Yes';
        insert salesOrder;
 
        HexaBPM__SR_Template__c template = new HexaBPM__SR_Template__c();
        template.HexaBPM__SR_RecordType_API_Name__c = 'PropertyTransfer';
        insert template;
 
 
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, 'InternalMortgageDischarge');
        insert objStepTemplate;
 
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(template.Id, objStepTemplate.Id);
        insert objSRSteps;
 
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       Test.startTest();
        Id recordTypeIdOfPT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_TYPE);
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
 
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, '', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Agency Registration'), template.Id);
        newSR.SalesOrder__c = salesOrder.Id;        
        newSR.Unit__c = unit.Id;  
        newSR.IsComplianceReturned__c = false;
        newSR.Compliance_Status__c = '';
        newSR.TransferSellingPrice__c= 1000000;
        insert newSR;
 
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Agency_Agreement_Document';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        //docTemp.Stage__c = 'Licensed';
        insert docTemp;
 
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = objStepTemplate.Id;
        SRStep.HexaBPM__Summary__c = 'Test';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        SRStep.DocusignExpiryinDays__c=2;
        insert SRStep;
 
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'AgencyRegistration';
        step.HexaBPM__SR__c = newSR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        
        //Test.startTest();
         HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id  ;
        objSRDoc.HexaBPM__Step__c = step.Id;
        objSRDoc.Name = 'Signed Owner Association Letter';
        objSRDoc.HexaBPM__Status__c = 'Uploaded';
        insert objSRDoc;
        
        HexaBPM__SR_Doc__c objSRDoc2 = new HexaBPM__SR_Doc__c();
        objSRDoc2.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc2.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc2.HexaBPM__Service_Request__c = newSR.id  ;
        objSRDoc2.HexaBPM__Step__c = step.Id;
        objSRDoc2.Name = 'Signed Assignment of Service Charge';
        objSRDoc2.HexaBPM__Status__c = 'Uploaded';
        insert objSRDoc2;
        
        HexaBPM__SR_Doc__c objSRDoc3 = new HexaBPM__SR_Doc__c();
        objSRDoc3.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc3.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc3.HexaBPM__Service_Request__c = newSR.id  ;
        objSRDoc3.HexaBPM__Step__c = step.Id;
        objSRDoc3.Name = 'Seller Passport Copy';
        insert objSRDoc3;

        
        
        Map<String,HexaBPM__Status__c> statusMap= new Map<String,HexaBPM__Status__c>();
        statusMap.put(status.name,status);
        SRDocTriggerHandler.handleSRStepAutomation(objSRDoc,statusMap);
          SRDocTriggerHandler.closeDubaRAKDocStep();

        Test.stopTest();
    }
    
    @isTest
static void test_GenericDocumentLinking_NoDuplicate() {
   
    Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
    insert acc;

    Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
    con.Email = 'ajay.thakur.tpr@pwc.com';
    update con;

    Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
    insert opp;

    Project__c project = TestObjectsFactory.getProjectRecord('Mayan');
    insert project;

    BuildingSection__c building =
        TestObjectsFactory.getBuildingDetailRecord(project.Id);
    insert building;

    Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
    unit.Status__c = 'Sold';
    unit.Project__c = project.Id;
    insert unit;

    HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
    insert draft;

    SalesOrder__c salesOrder =
        TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
    salesOrder.Unit__c = unit.Id;
    salesOrder.Contact__c = con.Id;
    salesOrder.MortgageApplicable__c = 'Yes';
    insert salesOrder;

    HexaBPM__SR_Template__c template = new HexaBPM__SR_Template__c(
        HexaBPM__SR_RecordType_API_Name__c = 'PropertyTransfer'
    );
    insert template;

    HexaBPM__Service_Request__c sr =
        TestObjectsFactory.getServiceRequest(
            draft.Id,
            unit.Id,
            '',
            Utilities.getRecordTypeId(
                'HexaBPM__Service_Request__c',
                'Agency Registration'
            ),
            template.Id
        );
    sr.SalesOrder__c = salesOrder.Id;
    sr.Unit__c = unit.Id;
    insert sr;



    Document__c genericDoc = new Document__c(
      //  Name = 'Generic CTL',
        DocumentType__c = Constants.DOCUMENT_TYPE_Commercial_Trade_License,
        Project__c = null
    );
    insert genericDoc;

  
    ContentVersion cv = new ContentVersion(
        Title = 'GenericCTL',
        PathOnClient = 'GenericCTL.pdf',
        VersionData = Blob.valueOf('Test Content'),
        Origin = 'H',
        FirstPublishLocationId = genericDoc.Id
    );
    insert cv;

  

    HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c(
        Name = Constants.DOCUMENT_TYPE_Commercial_Trade_License,
        HexaBPM__Service_Request__c = sr.Id
    );
    insert srDoc;
}
   
}