/**********************************************************************************************************************
* Name              : DocuSignHelperTest                                                        
* Description       : Test class for DocuSignHelper
* Method			: testESign & docuSignTestMethod 
* Created By & Date : 
* Last Modified By	: tdontha@aldar.com - Tharun [26-Aug-2023]
* Test Coverage		: 82% along with SendSRDocsControllerTest
******************************************************************************************************************/
@isTest
public class DocuSignHelperTest 
{
    
	@testSetup 
    public static void setupData()
    {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        //Hexa Objects
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;

        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        sr.HexaBPM__Customer__c = orgAcc.Id;
        SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        sr.HexaBPM__SR_Template__c = SR_Template.Id;
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Step 1';
        ST.HexaBPM__Code__c = 'Digital Signature by Head of Broker Management';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'Require More Information';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Test';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        SRStep.DocusignExpiryinDays__c=2;
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'AgencyRegistration';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        
        insert step; 
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Agency_Agreement_Document';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        //docTemp.Stage__c = 'Licensed';
        insert docTemp;
        
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc.HexaBPM__Step__c=step.Id;
        objSRDoc.Send_For_E_Signature__c=true;
        //objSRDoc.person__c = personObj.id  ;
        insert objSRDoc;
        Test.startTest();
		OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),'DOC',objSRDoc.id);
        Test.stopTest();
    }
    
    @isTest
    public static void testESign() 
    {
        Test.startTest();
        list<HexaBPM__SR_Doc__c> objSRDoc = [SELECT id from HexaBPM__SR_Doc__c limit 1];
        DocuSignHelper.docusignBulktFilter(new set<String>{objSRDoc[0].Id});
        
        objSRDoc[0].Send_For_E_Signature__c=false;
        objSRDoc[0].Docusign_Envelope_Id__c='123-123-123';
        update objSRDoc;
        
        HexaBPM__Step__c step = [select id from HexaBPM__Step__c];
        HexaBPM__Service_Request__c sr = [select id from HexaBPM__Service_Request__c];
        insert new dfsle__Envelope__c(dfsle__DocuSignId__c='123-123-123',Step__c=step.Id,Service_Request__c=sr.id);
        DocuSignHelper.docusignBulktFilter(new set<String>{objSRDoc[0].Id});
        DocuSignHelper.hasSObjectField('Send_For_E_Signature__c',objSRDoc[0]);
        Test.stopTest();
    }

    @isTest
    public static void docuSignTestMethod()
    {
         Test.startTest();
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
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BuyerName__c = acc.Id;	
        insert newSR;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = TRUE;

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
        docTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        insert docTemp;

        HexaBPM__SR_Template_Docs__c docSignedTemp = new HexaBPM__SR_Template_Docs__c();
        docSignedTemp.HexaBPM__Document_Master__c = objSignedDocMaster.id ;
        insert docSignedTemp;

        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        insert objSRDoc;

        List<HexaBPM__SR_Doc__c> objSignedSRDocllst = new List<HexaBPM__SR_Doc__c>();
        HexaBPM__SR_Doc__c objSignedSRDoc = new HexaBPM__SR_Doc__c();
        objSignedSRDoc.HexaBPM__Document_Master__c = objSignedDocMaster.id;
        objSignedSRDoc.HexaBPM__SR_Template_Doc__c = docSignedTemp.id;
        objSignedSRDoc.HexaBPM__Service_Request__c = newSR.id ;
        objSignedSRDocllst.add(objSignedSRDoc);
        insert objSignedSRDocllst;


        
      List<String> eSignedGroupList = new List<String>{'Customer','Buyer','Authorised Signatory','Customer with Joint Owner','Buyer with Joint Owner'};
      System.debug('@@@eSignedGroupList'+eSignedGroupList);
          DocuSignHelper.sendSRDocForESign(objSRDoc,objSignedSRDocllst,eSignedGroupList,'aldar@aldar.com');
        
       

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
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objSRDoc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;

        HexaBPM__SR_Doc__c srDoc = [SELECT Id, HexaBPM__Document_Master__c, HexaBPM__SR_Template_Doc__c, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId  From ContentDocumentLinks)  From HexaBPM__SR_Doc__c Where Id =: objSRDoc.Id];
		SendSRDocsController.sendForESign(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com');
        SendSRDocsController.getRecordDetails(srDoc.Id);
        
        docTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        update docTemp;
         
       
        
        Test.stopTest();
    }
    
    
     @isTest
    public static void docuSignTestMethod2()
    {
         
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
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        
        
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
		ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = TRUE;
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
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
        docTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        insert docTemp;

        HexaBPM__SR_Template_Docs__c docSignedTemp = new HexaBPM__SR_Template_Docs__c();
        docSignedTemp.HexaBPM__Document_Master__c = objSignedDocMaster.id ;
        insert docSignedTemp;
		DocuSignHelper.isSkipSrDocTrigger = true;
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id;
        objSRDoc.HexaBPM__Doc_ID__c = documents[0].Id;
        insert objSRDoc;
       List<HexaBPM__SR_Doc__c> objSignedSRDoclst2 = new List<HexaBPM__SR_Doc__c>();
        HexaBPM__SR_Doc__c objSignedSRDoc1 = new HexaBPM__SR_Doc__c();
        objSignedSRDoc1.HexaBPM__Document_Master__c = objSignedDocMaster.id;
        objSignedSRDoc1.HexaBPM__SR_Template_Doc__c = docSignedTemp.id;
        objSignedSRDoc1.HexaBPM__Service_Request__c = newSR.id ;
        objSignedSRDoclst2.add(objSignedSRDoc1);
        insert objSignedSRDoclst2;
Test.startTest();
                
        AgencyTeam__c at =new AgencyTeam__c();
        at.Account__c = acc.Id;
        at.ServiceRequest__c = newSR.Id;
        insert at;
        
       	JointOwner__c jO= new JointOwner__c();
        jO.Account__c = acc.Id;
        jO.salesorder__c = salesOrder.Id;
        insert jO;
		
       
      List<String> eSignedGroupList = new List<String>{'Customer','Buyer','Authorised Signatory','Customer with Joint Owner','Buyer with Joint Owner'};
      System.debug('@@@eSignedGroupList'+eSignedGroupList);
          DocuSignHelper.sendSRDocForESign(objSRDoc,objSignedSRDoclst2,eSignedGroupList,'aldar@aldar.com');
        
       

        /*ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        objSRDoc.HexaBPM__Doc_ID__c = documents[0].Id; */
        
       
         //DocuSignHelper.isSkipSrDocTrigger = true;
        //update objSRDoc;
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objSRDoc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;

        HexaBPM__SR_Doc__c srDoc = [SELECT Id, HexaBPM__Document_Master__c, HexaBPM__SR_Template_Doc__c, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId  From ContentDocumentLinks)  From HexaBPM__SR_Doc__c Where Id =: objSRDoc.Id];
		SendSRDocsController.sendForESign(srDoc.Id, 'hardikkumar.vitthani.tpr@pwc.com');
        SendSRDocsController.getRecordDetails(srDoc.Id);
        
        //docTemp.ESignGroup__c = 'Customer;Buyer;Authorised Signatory;Customer with Joint Owner;Buyer with Joint Owner' ;
        //update docTemp;
        
        Test.stopTest();
    }
    
}