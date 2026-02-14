@isTest
private class LEX_UploadDocumentsControllerTest {
    
    @isTest 
    static  void callMethods() {
        
        Test.startTest();
        
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Submitted';
        srStatus.Name = 'Submitted';
        insert srStatus;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Assignment of Broker Manager';
        ST.HexaBPM__Code__c = 'Assignment of Broker Manager';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Assignment of Broker Manager';
        SRStep.HexaBPM__Group_Name__c = 'Assignment of Broker Manager';
        insert SRStep;
        
        /*Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }*/

        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c();
        //sr.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        sr.SRType__c = 'Agency Registration';
        sr.HexaBPM__Submitted_DateTime__c = Datetime.now();
        sr.HexaBPM__SR_Template__c = SR_Template.Id;
        sr.CompanyEmail__c = 'test.test@test.com';
        insert sr;

        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.HexaBPM__Type__c = 'Start';
        status.HexaBPM__Reupload_Document__c = true;
        status.HexaBPM__Code__c = 'Start';
        insert status;
        

        
        AgencyTeam__c agencyAdmin = new AgencyTeam__c();
        agencyAdmin.Title__c = 'Mr';
		agencyAdmin.EmailAddress__c = 'test.test@test.com';
		agencyAdmin.name = 'Test Test Test';
        agencyAdmin.MobileNumber__c = '97156789';
        agencyAdmin.ServiceRequest__c = sr.Id;
        agencyAdmin.Type__c = Constants.AGENCY_ADMIN;
        insert agencyAdmin;
        
        sr.HexaBPM__External_SR_Status__c = srStatus.Id;
		sr.HexaBPM__Internal_SR_Status__c = srStatus.Id;
        update sr;
        
        HexaBPM__Service_Request__c sr1 = new HexaBPM__Service_Request__c();
        //SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        sr1.SRType__c = 'Agency Registration';
        sr1.HexaBPM__Submitted_DateTime__c = Datetime.now();
        sr1.HexaBPM__SR_Template__c = SR_Template.Id;
        sr1.CompanyEmail__c = 'test.test@test.com';
        sr1.HexaBPM__Parent_SR__c = sr.Id;
        insert sr1;

        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Test Code 1';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SR_Template.Id, ST.Id);
        insert objSRSteps;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(sr1.Id, objSRSteps.Id ,ST.Id);
        newStep.HexaBPM__Status__c = status.Id;
        insert newStep;
        
        LEX_UploadDocumentsController.getSRDocs(sr.Id);
        LEX_UploadDocumentsController.getAttachmentURL(sr.Id,'');
        LEX_UploadDocumentsController.getNextAttachment(sr.Id,'');

        LEX_UploadDocumentsController.getPreviousAttachment(sr.Id,'');

        String base64 = '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';

        HexaBPM__SR_Doc__c doc = new HexaBPM__SR_Doc__c();
        doc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        doc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        doc.HexaBPM__Service_Request__c = sr.id  ;
        insert doc;
        
        LEX_UploadDocumentsController.saveTheFile(sr.Id, doc.Id, 'fileName', base64, 'contentType', 'CustomerComments');
        LEX_UploadDocumentsController.getSRDocStatus();
        
        List<HexaBPM__SR_Doc__c> slist = new List<HexaBPM__SR_Doc__c>{doc};
        LEX_UploadDocumentsController.UpdateSRDocs(JSON.serialize(slist),sr.Id);

        LEX_UploadDocumentsController.AutoCloseReuploadDocStep(sr1.Id);
        LEX_UploadDocumentsController.EnableDisableButtons(sr.Id,'');
        LEX_UploadDocumentsController.CheckIfCommunityUser();

        Test.stopTest();
    }
}