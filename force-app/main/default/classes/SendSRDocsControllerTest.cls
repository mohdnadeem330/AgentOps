@isTest(SeeAllData=false)
public class SendSRDocsControllerTest {
    @isTest static void setupMethod() {
        
        
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
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
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
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BuyerName__c = acc.Id;
        insert newSR;
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'General_Information_for_Regulated_Activities';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__Document_Master__c objSignedDocMaster = new HexaBPM__Document_Master__c();
        objSignedDocMaster.HexaBPM__Code__c = 'Signed_General_Information_for_Regulated_Activities';
        objSignedDocMaster.HexaBPM__Available_to_client__c = true;
        insert objSignedDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        docTemp.ESignGroup__c = 'Authorised Signatory' ;
        insert docTemp;
        
        HexaBPM__SR_Template_Docs__c docSignedTemp = new HexaBPM__SR_Template_Docs__c();
        docSignedTemp.HexaBPM__Document_Master__c = objSignedDocMaster.id ;
        insert docSignedTemp;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        insert objSRDoc;
        
        HexaBPM__SR_Doc__c objSignedSRDoc = new HexaBPM__SR_Doc__c();
        objSignedSRDoc.HexaBPM__Document_Master__c = objSignedDocMaster.id;
        objSignedSRDoc.HexaBPM__SR_Template_Doc__c = docSignedTemp.id;
        objSignedSRDoc.HexaBPM__Service_Request__c = newSR.id ;
        insert objSignedSRDoc;
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        objSRDoc.HexaBPM__Doc_ID__c = documents[0].Id;
        update objSRDoc;
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objSRDoc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        Test.startTest();
        HexaBPM__SR_Doc__c srDoc = [SELECT Id, HexaBPM__Document_Master__c, HexaBPM__SR_Template_Doc__c, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId  From ContentDocumentLinks)  From HexaBPM__SR_Doc__c Where Id =: objSRDoc.Id];
        SendSRDocsController.sendForESign(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com');
        SendSRDocsController.getRecordDetails(srDoc.Id);
        
        docTemp.ESignGroup__c = 'Customer' ;
        update docTemp; 
        
        try {
            //Test.startTest();
            
            SendSRDocsController.getRecordDetails(srDoc.Id);
            SendSRDocsController.sendForESign(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com');
            SendSRDocsController.sendForESign(null, 'hardikkumar.vitthani.tpr@pwc.com');
            
            
            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.StopTest();
    }
    
    @isTest static void setupMethod2() {
        
        
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
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
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
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BuyerName__c = acc.Id;
        insert newSR;
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = Constants.DOCUMENT_TYPE_PREFIX_SIGNED;
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__Document_Master__c objSignedDocMaster = new HexaBPM__Document_Master__c();
        objSignedDocMaster.HexaBPM__Code__c = 'ali test';
        objSignedDocMaster.HexaBPM__Available_to_client__c = true;
        insert objSignedDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        docTemp.ESignGroup__c = 'Authorised Signatory' ;
        insert docTemp;
        
        HexaBPM__SR_Template_Docs__c docSignedTemp = new HexaBPM__SR_Template_Docs__c();
        docSignedTemp.HexaBPM__Document_Master__c = objSignedDocMaster.id ;
        insert docSignedTemp;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        insert objSRDoc;
        
        HexaBPM__SR_Doc__c objSignedSRDoc = new HexaBPM__SR_Doc__c();
        objSignedSRDoc.HexaBPM__Document_Master__c = objSignedDocMaster.id;
        objSignedSRDoc.HexaBPM__SR_Template_Doc__c = docSignedTemp.id;
        objSignedSRDoc.HexaBPM__Service_Request__c = newSR.id ;
        insert objSignedSRDoc;
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        objSRDoc.HexaBPM__Doc_ID__c = documents[0].Id;
        update objSRDoc;
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objSRDoc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        Test.startTest();
        HexaBPM__SR_Doc__c srDoc = [SELECT Id, HexaBPM__Document_Master__c, HexaBPM__SR_Template_Doc__c, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId  From ContentDocumentLinks)  From HexaBPM__SR_Doc__c Where Id =: objSRDoc.Id];
        SendSRDocsController.sendForESign(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com');
        SendSRDocsController.getRecordDetails(srDoc.Id);
        
        docTemp.ESignGroup__c = 'Customer' ;
        update docTemp; 
        
        try {
            
            
            SendSRDocsController.getRecordDetails(srDoc.Id);
            SendSRDocsController.sendForESign(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com');
            SendSRDocsController.sendForESign(null, null);
            

            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.StopTest();
    }
    
    @isTest static void setupMethod3() {
        
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org2', 'G123456');
        insert acc1;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
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
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BuyerName__c = acc.Id;
        insert newSR;
        
        AgencyTeam__c jointOwner = new AgencyTeam__c();
        jointOwner.ServiceRequest__c = newSR.Id;
        jointOwner.Account__c = acc1.Id;
        jointOwner.ShareHoldingPercentage__c = 10;
        jointOwner.RelationshipType__c = 'Third Party';
        insert jointOwner;
        
        JointOwner__c jointOwner1 = new JointOwner__c();
        jointOwner1.Account__c = acc1.Id;
        jointOwner1.SharePercentage__c = 10;
        jointOwner1.SalesOrder__c = salesOrder.Id;
        Test.startTest();
        insert jointOwner1;
        
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
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        insert objSRDoc;
        
        HexaBPM__SR_Doc__c objSignedSRDoc = new HexaBPM__SR_Doc__c();
        objSignedSRDoc.HexaBPM__Document_Master__c = objSignedDocMaster.id;
        objSignedSRDoc.HexaBPM__SR_Template_Doc__c = docSignedTemp.id;
        objSignedSRDoc.HexaBPM__Service_Request__c = newSR.id ;
        insert objSignedSRDoc;

        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        objSRDoc.HexaBPM__Doc_ID__c = documents[0].Id;
        update objSRDoc;
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objSRDoc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        HexaBPM__SR_Doc__c srDoc = [SELECT Id, HexaBPM__Document_Master__c, HexaBPM__SR_Template_Doc__c, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId  From ContentDocumentLinks)  From HexaBPM__SR_Doc__c Where Id =: objSRDoc.Id];
        SendSRDocsController.sendDocumentForESignQES(srDoc.Id, '', false);
        SendSRDocsController.getRecordDetails(srDoc.Id);
        
        docTemp.ESignGroup__c = 'Customer' ;
        update docTemp; 
        
        try {
            
            
            SendSRDocsController.getRecordDetails(srDoc.Id);
            SendSRDocsController.sendDocumentForESignQES(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com', false);
            //SendSRDocsController.sendDocumentForESignNew2(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com', false);
            SendSRDocsController.sendForESign(null, 'hardikkumar.vitthani.tpr@pwc.com');
            
            
            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.StopTest();
    }
    
    @isTest static void setupMethod4() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'Handover']){
            recordTypeSR.put(rtype.DeveloperName, rtype.Id);
        }
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org2', 'G123456');
        insert acc1;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
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
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.HOKAR__c = Userinfo.getUserId();
        newSR.RecordTypeId = recordTypeSR.get('Handover');
        newSR.SRType__c = 'Handover';
        insert newSR;
        
        AgencyTeam__c jointOwner = new AgencyTeam__c();
        jointOwner.ServiceRequest__c = newSR.Id;
        jointOwner.Account__c = acc1.Id;
        jointOwner.ShareHoldingPercentage__c = 10;
        jointOwner.RelationshipType__c = 'Third Party';
        insert jointOwner;
        
        JointOwner__c jointOwner1 = new JointOwner__c();
        jointOwner1.Account__c = acc1.Id;
        jointOwner1.SharePercentage__c = 10;
        jointOwner1.SalesOrder__c = salesOrder.Id;
        Test.startTest();
        insert jointOwner1;
        
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
        docSignedTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner';
        insert docSignedTemp;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        insert objSRDoc;
        
        HexaBPM__SR_Doc__c objSignedSRDoc = new HexaBPM__SR_Doc__c();
        objSignedSRDoc.HexaBPM__Document_Master__c = objSignedDocMaster.id;
        objSignedSRDoc.HexaBPM__SR_Template_Doc__c = docSignedTemp.id;
        objSignedSRDoc.HexaBPM__Service_Request__c = newSR.id ;
        insert objSignedSRDoc;
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        objSRDoc.HexaBPM__Doc_ID__c = documents[0].Id;
        update objSRDoc;

        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objSRDoc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        HexaBPM__SR_Doc__c srDoc = [SELECT Id, HexaBPM__Document_Master__c, HexaBPM__SR_Template_Doc__c, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId  From ContentDocumentLinks)  From HexaBPM__SR_Doc__c Where Id =: objSRDoc.Id];
        SendSRDocsController.sendDocumentForESignQES(srDoc.Id, '', false);
        SendSRDocsController.getRecordDetails(srDoc.Id);
        
        docTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        update docTemp; 
        
        try {
            
            
            SendSRDocsController.getRecordDetails(srDoc.Id);
            //SendSRDocsController.sendDocumentForESignNew(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com', false);
            SendSRDocsController.sendDocumentForESignQES(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com', false);
            SendSRDocsController.sendForESign(null, 'hardikkumar.vitthani.tpr@pwc.com');
            
            
            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.StopTest();
    }
    
    @isTest 
    static void setupMethod5() {
        DocuSignWrapper.Signer sign = new DocuSignWrapper.Signer('0012500002BLrdE', '0012500002BLrdE', 'test');
    }
}