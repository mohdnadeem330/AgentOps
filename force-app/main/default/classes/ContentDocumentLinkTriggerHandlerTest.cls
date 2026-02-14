/*
*Created By     : Hardik Vitthani
*Description    : ContentDocumentLinkTriggerHandler
*/
@isTest
public class ContentDocumentLinkTriggerHandlerTest {
    @isTest
    public static void testContentDocumentLinkTriggerHandlerDocument() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        p.EligibleforResale__c = true;
        insert p;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup(p.Id);
        unit.Status__c = 'Sold';
        unit.Project__c = p.Id;
        insert unit;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.Status__c  = 'Sold';
        salesOrder.MortgageApplicationNumber__c = '1234';
        insert salesOrder;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');       
        insert closed;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
        
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c=Constants.HO_STATUS_READY,
                                                                        Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder.Id,
                                                                        isRTOHandover__c =  false,
                                                                        UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY ,
                                                                        HandoverAgent__c = UserInfo.getUserId() ,
                                                             			kar__c = UserInfo.getUserId()
                                                                        );                                        
        insert hodetail;
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.HandoverDetail__c = hodetail.Id;
        insert newSR;
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'SPACustomerCopy';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        objDocMaster.TemplateID__c = '477c4ec8-9f6e-4f43-8376-5b172243a798';
        insert objDocMaster;
        
        HexaBPM__Document_Master__c objSignedDocMaster = new HexaBPM__Document_Master__c();
        objSignedDocMaster.HexaBPM__Code__c = 'Signed_SPACustomerCopy';
        objSignedDocMaster.HexaBPM__Available_to_client__c = true;
        objSignedDocMaster.TemplateID__c = '477c4ec8-9f6e-4f43-8376-5b172243a798';
        insert objSignedDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        docTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        insert docTemp;
        
        HexaBPM__SR_Template_Docs__c docSignedTemp = new HexaBPM__SR_Template_Docs__c();
        docSignedTemp.HexaBPM__Document_Master__c = objSignedDocMaster.id ;
        docSignedTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        insert docSignedTemp;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.Name =Constants.DOCUMENT_SIGNED_UNIFIED_HANDOVER_DOCUMENTS;
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        insert objSRDoc;
        Test.startTest();
        
        Map<String, String> newMap = new Map<String, String>();
        newMap.put(objSRDoc.Id, '');
        
        ContentDocumentLinkTriggerHandler.UpdateSRDoc(newMap);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testContentDocumentLinkTriggerHandlerCse() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        acc.Emirates_ID__c ='784123123123123';
        insert acc;
        
        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;
        
        Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
        //insert cs;
        
        //TestObjectsFactory.createContentDocumentLink(cs.Id);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testContentDocumentLinkForContact() 
    {
        Id brokerConRecTypeId = Schema.SobjectType.Contact.getRecordTypeInfosByDeveloperName()
                                        .get('BrokerAgent')
                                        .getRecordTypeID();
        Test.startTest();
        Account acc = TestObjectsFactory.getAgencyAccountRecord('TestAgencyAccount', 'TestRegistrationNo');
        acc.AgencyStatus__c = 'Active';
        acc.Emirates_ID__c ='784123123123123';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'TestingName';
        con.RecordTypeId = brokerConRecTypeId;
        con.AccountId = acc.Id;
        insert con;
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
		List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = con.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
    	Test.stopTest();
    }
             
    @isTest
    static void testTriggerLogic() {               
        Test.startTest();
        Account accA = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        accA.MobileNumber__c = '123456789';
        accA.Emirates_ID__c ='784123123123123';
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
    public static testmethod void dmtestLogic() {
        case ca = new Case();
        ca.Subject = 'Test Case';
        ca.Type = 'NOC';               
        ca.Development_Name__c='Yas Island';
        ca.status = 'New';           
        ca.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management_TLA').getRecordTypeId();
        insert ca;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='TLA'; 
        content.PathOnClient='TLA'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob;
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId= ca.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;      
            
    }  
    
    @isTest
    public static void testContentDocumentForInvoiceClaim() 
    {
        Test.startTest();
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c();
        invoiceBundle.BundleName__c = 'brokerAgencyId';
        invoiceBundle.Status__c = 'Ready for Submission';
        invoiceBundle.BundleNumber__c = 1;
        insert invoiceBundle;
        
        Document__c document = new Document__c();
        document.DocumentType__c = 'Invoice Claim Form';
        document.AvailableForExternalUsers__c = true;
        document.InvoiceBundle__c = invoiceBundle.id;
        insert document;
        
        ContentDocumentLink contentlink = TestObjectsFactory.createContentDocumentLink(document.Id);
        Test.stopTest();
    }

    @isTest
    static void testAttachfiletoOppDocuments() {
        Id leasingRecordType = Schema.SobjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                                        .get('ECSS_Leasing')
                                        .getRecordTypeID();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Emirates_ID__c ='784123123123127';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
      Quote newQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.id,
            Status = 'Draft',
            ExpirationDate = System.today().addDays(15)
            
        );
        insert newQuote;
        Document__c doc = new Document__c(
            Opportunity__c = opp.Id,
            DocumentType__c = 'Leasing Offer Letter'
        );
        insert doc;
        
        //ContentDocumentLink contentlink = TestObjectsFactory.createContentDocumentLink(doc.Id);

       
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test file content')
           
        );
        insert cv;
        
       

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [select contentdocumentid from contentversion where id =: cv.id].contentdocumentid,
            LinkedEntityId = newQuote.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>{cdl};
             
           Map<string, string> srDocMap = new Map<string, string>();
           srDocMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);

        Test.startTest();
        ContentDocumentLinkTriggerHandler.AttachfiletoOppDocuments(new Set<Id>{newQuote.Id}, cdls);
        ContentDocumentLinkTriggerHandler.updateHandoverDetails(srDocMap);
        Test.stopTest();

     
        //List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE Id IN : cdls.Id];
        System.assertNotEquals(2, cdls.size(), 'There should be two links: one to Quote and one to Document__c');
    }
    @isTest
    public static void testUpdateSOs(){
        
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
        salesorder.IntentionToBookSigned__c = false;
        insert salesOrder;  
        
        
        List<SalesOrder__c> lstso = new List<SalesOrder__c>{ salesOrder };
            
        Test.startTest();
        
        update lstso;
        Test.stopTest();
        
    }
    
    @isTest
    public static void testUpdateSRDoc(){
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        p.EligibleforResale__c = true;
        insert p;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup(p.Id);
        unit.Status__c = 'Sold';
        unit.Project__c = p.Id;
        insert unit;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.Status__c  = 'Sold';
        salesOrder.MortgageApplicationNumber__c = '1234';
        insert salesOrder;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');       
        insert closed;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
        
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c=Constants.HO_STATUS_READY,
                                                                        Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder.Id,
                                                                        isRTOHandover__c =  false,
                                                                        UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY ,
                                                                        HandoverAgent__c = UserInfo.getUserId() ,
                                                             			kar__c = UserInfo.getUserId()
                                                                        );                                        
        insert hodetail;
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.HandoverDetail__c = hodetail.Id;
        insert newSR;
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'SPACustomerCopy';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        objDocMaster.TemplateID__c = '477c4ec8-9f6e-4f43-8376-5b172243a798';
        insert objDocMaster;
        
        HexaBPM__Document_Master__c objSignedDocMaster = new HexaBPM__Document_Master__c();
        objSignedDocMaster.HexaBPM__Code__c = 'Signed_SPACustomerCopy';
        objSignedDocMaster.HexaBPM__Available_to_client__c = true;
        objSignedDocMaster.TemplateID__c = '477c4ec8-9f6e-4f43-8376-5b172243a798';
        insert objSignedDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        docTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        insert docTemp;
        
        HexaBPM__SR_Template_Docs__c docSignedTemp = new HexaBPM__SR_Template_Docs__c();
        docSignedTemp.HexaBPM__Document_Master__c = objSignedDocMaster.id ;
        docSignedTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        insert docSignedTemp;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.Name =Constants.DOCUMENT_SIGNED_UNIFIED_HANDOVER_DOCUMENTS;
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        insert objSRDoc;
        
        ContentDocumentLink documentLink = TestObjectsFactory.createContentDocumentLink(objSRDoc.Id);
        
        Test.startTest();
        ContentDocumentLinkTriggerHandler.UpdateSRDoc(new map<String,String>{documentLink.Id => documentLink.Id});
        ContentDocumentLinkTriggerHandler.updateHandoverDetails(new map<String, String>{objSRDoc.Id => objSRDoc.Id});
        Test.stopTest();
        
    }
    
    @isTest
    public static void testUpdateSRDoc2(){
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        p.Name = System.Label.DubaiProject;
        p.EligibleforResale__c = true;
        insert p;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup(p.Id);
        unit.Status__c = 'Sold';
        unit.Project__c = p.Id;
        insert unit;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.Status__c  = 'Sold';
        salesOrder.MortgageApplicationNumber__c = '1234';
        insert salesOrder;
        
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        Case caseObj = TestObjectsFactory.getCaseRecord(ResaleConstants.Resale_Case_RecordTypeId, '', salesOrder.Unit__c, '800-Aldar');
        //caseObj.Project__c = p.Id;
        insert caseObj;
        
        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id, null);
        document.Account__c = acc.Id;
        document.AvailableForExternalUsers__c = true;
        document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get(ResaleConstants.CASE_DOCUMENT_RECORDTYPE_DNAME).getRecordTypeId();
        document.DocumentType__c = ResaleConstants.CASE_LISTING_AGREEMENT_DOCUMENT_TYPE;
        document.Case__c = caseObj.Id;
        document.SalesOrder__c = salesOrder.Id;
        document.DocumentType__c = System.Label.SignedIntentionToBook;
        insert document;
        
        Test.startTest();
        ContentDocumentLinkTriggerHandler.UpdateDocStatus(new set<Id>{document.Id});
        Test.stopTest();
        
    }
    
    @isTest
    public static void setupImageOnExceptionRequestTest() {
        Account accA = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        accA.MobileNumber__c = '123456789';
        accA.Emirates_ID__c ='784123123123123';
        insert accA; 
        
        Exception_Request__c exp = new Exception_Request__c();
        exp.Request_End_Date__c = system.today().addDays(6);
        exp.Request_Type__c = 'Duplicate Email';
        exp.Request_Reason__c = 'Request For Same Email';
        exp.Request_Status__c = 'Submitted';
        exp.Duplicate_Email__c = 'test@g.com';
        exp.Account__c = accA.Id;
        exp.Requester_Comments__c = 'test';
        insert exp;
        
        Test.startTest();
        ContentDocumentLink documentLink = TestObjectsFactory.createContentDocumentLink(exp.Id);
        Test.stopTest();
    }
}