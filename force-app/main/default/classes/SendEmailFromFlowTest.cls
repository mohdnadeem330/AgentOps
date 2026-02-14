@isTest(SeeAllData=false)
public with sharing class SendEmailFromFlowTest {
    
    @testSetup 
    static void setupMethod() 
    {

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'test.aldar@aldar.com.invalid';
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
        objDocMaster.HexaBPM__Code__c = 'NOC_Copy';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;

        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;

        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        objSRDoc.Name = Constants.DOCUMENT_TYPE_NOC_COPY;
        insert objSRDoc;

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

    }
    
    @isTest
    static void testMethod1()
    {
        HexaBPM__Service_Request__c newSR = [SELECT Id FROM HexaBPM__Service_Request__c];
        
        try 
        {
            Test.startTest();
            SendEmailFromFlow.FlowInput flowInput = new SendEmailFromFlow.FlowInput();
            flowInput.whatId = newSR.Id;
            flowInput.templateName = 'Service Request Creation Property Transfer';
            flowInput.toAddress = 'test@aldar.com.invalid';
            flowInput.ccAddress = 'test@aldar.com.invalid';
            flowInput.bccAddress = 'test@aldar.com.invalid';
            flowInput.replyTo = 'test@aldar.com.invalid';
            flowInput.addSRAmendment = true;
            
            SendEmailFromFlow.sendEmail(new List<SendEmailFromFlow.FlowInput>{flowInput});
            
            Test.StopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    
    @isTest static void testMethodAldSendEmail() 
    {
        HexaBPM__Service_Request__c newSRreq = [SELECT Id FROM HexaBPM__Service_Request__c];
        
        Test.startTest();
        ALD_SendEmail.FlowInputParamsWrapper flowInput = new ALD_SendEmail.FlowInputParamsWrapper();
        flowInput.recordID = newSRreq.Id;
        flowInput.objectName = 'HexaBPM__Service_Request__c';
        flowInput.emailTemplateName = 'ServiceRequestCreationPropertyTransfer';
        flowInput.fromEmailAddress = 'customercare@aldar.com';
        flowInput.recRelatedToEmailAddress = 'test@aldar.com.invalid';
        flowInput.recToEmailAddress = 'test@aldar.com.invalid';
        flowInput.recRecCreatorId = UserInfo.getUserId();
        flowInput.recOwnerId = UserInfo.getUserId();
        flowInput.recAccountOwnerId = UserInfo.getUserId();
        flowInput.recUserId = UserInfo.getUserId();
        flowInput.recEmailFields = 'HexaBPM__Email__c';
        flowInput.ccEmailAddress = 'test@aldar.com.invalid';
        flowInput.bccEmailAddress = 'test@aldar.com.invalid';
        flowInput.replyToEmailAddress = 'test@aldar.com.invalid';
        
        ALD_SendEmail.sendMailLikeEmailAlert(new List<ALD_SendEmail.FlowInputParamsWrapper>{flowInput});
        
        Test.StopTest();
        
    }
	
    
}