@isTest
private class ADMRegistrationUtilityTest {
  
    //Create setupData
    @testSetup static void setupData() {
       Map<String, Id> recordTypeSR = new Map<String, Id>();
        for (RecordType rtype : [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'HexaBPM__Service_Request__c' 
            AND DeveloperName = 'SPARegistrationForOffPlan'
        ]) {
            recordTypeSR.put(rtype.DeveloperName, rtype.Id);
        }

        Test.startTest();

        // Create base records
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.NationalIdNumber__pc = '';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Account__c = acc.Id;
        salesOrder.Opportunity__c = opp.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);

        // === SR Status records ===
        List<HexaBPM__SR_Status__c> srStatuses = new List<HexaBPM__SR_Status__c>{
            TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
            TestObjectsFactory.getSRStatus(Constants.PENDING_STATUS),
            TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS),
            TestObjectsFactory.getSRStatus(Constants.STEP_APPROVED_STATUS),
            TestObjectsFactory.getSRStatus(Constants.STEP_ACCEPTED_STATUS),
            TestObjectsFactory.getSRStatus(Constants.STEP_REJECTED_STATUS)
        };
        insert srStatuses;

        // === SR Template ===
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c(
            Name = 'SPA Registration For Off Plan',
            HexaBPM__SR_RecordType_API_Name__c = 'SPARegistrationForOffPlan'
        );
        insert SR_Template;

        // === Service Request ===
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c(
            RecordTypeId = recordTypeSR.get('SPARegistrationForOffPlan'),
            HexaBPM__Customer__c = acc.Id,
            HexaBPM__Contact__c = acc.PersonContactId,
            OwnerId = UserInfo.getUserId(),
            HexaBPM__SR_Template__c = SR_Template.Id,
            Unit__c = unit.Id,
            SalesOrder__c = salesOrder.Id,
            SPACounterSignedDate__c = Date.today(),
            HexaBPM__External_SR_Status__c = srStatuses[0].Id
        );
        insert SR;

        // === Steps setup (Template + SR_Steps + Step) ===
        List<String> stepNames = new List<String>{
            'Verify Details',
            'Submit Registration',
            'Salesforce - Approval',
            'Payment Step',
            'ADM Team Approval'
        };

        List<HexaBPM__Step_Template__c> stepTemplates = new List<HexaBPM__Step_Template__c>();
        for (String name : stepNames) {
            stepTemplates.add(new HexaBPM__Step_Template__c(
                Name = name,
                HexaBPM__Code__c = name,
                HexaBPM__Step_RecordType_API_Name__c = 'General'
            ));
        }
        insert stepTemplates;

        List<HexaBPM__SR_Steps__c> srSteps = new List<HexaBPM__SR_Steps__c>();
        for (HexaBPM__Step_Template__c st : stepTemplates) {
            srSteps.add(new HexaBPM__SR_Steps__c(
                HexaBPM__SR_Template__c = SR_Template.Id,
                HexaBPM__Step_No__c = 1,
                HexaBPM__Step_Template__c = st.Id,
                HexaBPM__Summary__c = st.Name,
                HexaBPM__Step_RecordType_API_Name__c = 'General'
            ));
        }
        insert srSteps;

        List<HexaBPM__Step__c> steps = new List<HexaBPM__Step__c>();
        for (HexaBPM__SR_Steps__c srs : srSteps) {
            steps.add(new HexaBPM__Step__c(
                HexaBPM__Summary__c = srs.HexaBPM__Summary__c,
                HexaBPM__SR__c = SR.Id,
                HexaBPM__SR_Step__c = srs.Id,
                HexaBPM__Start_Date__c = System.today()
            ));
        }
        insert steps;

        // === Status Records ===
        List<HexaBPM__Status__c> statusList = new List<HexaBPM__Status__c>{
            new HexaBPM__Status__c(Name = Constants.PENDING_STATUS, HexaBPM__Code__c = Constants.PENDING_STATUS),
            new HexaBPM__Status__c(Name = Constants.COMPLETED_STATUS, HexaBPM__Code__c = Constants.COMPLETED_STATUS),
            new HexaBPM__Status__c(Name = Constants.STEP_APPROVED_STATUS, HexaBPM__Code__c = Constants.STEP_APPROVED_STATUS)
        };
        insert statusList;

        Test.stopTest();


    }
    
   /* @isTest
    public static void validateRegistrationAttributesMethod (){

        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        System.runAs(systemAdmin) {
                   Test.startTest();

        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c  From HexaBPM__Service_Request__c Limit 1];

		List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        		
        ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);

        Account acc = new Account(Id = SR.SalesOrder__r.Account__c);
        acc.NationalIdNumber__pc = '';
        acc.Nationality__pc = 'Jordan';
        update acc;

        ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);

        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;

        SalesOrder__c so = new SalesOrder__c(Id = SR.SalesOrder__c);
        so.Account__c = orgAcc.Id;
        update so;

        ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);

        Contact con = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        con.PrimaryContact__c = true;
        con.NationalIdNumber__c = '';
        update con;

        ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);

        con.Email = null;
        con.Nationality__c = 'Jordan';
        update con;

        ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);

        orgAcc.RegistrationNumber__c = '';
        update orgAcc;

        ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(so.Id, orgAcc.Id, 'Friend Of');
        insert jointOwner;

        JointOwner__c jointOwner1 = TestObjectsFactory.getJointOwnerRecord(so.Id, acc.Id, 'Friend Of');
        insert jointOwner1;

        acc.NationalIdNumber__pc = '';
        acc.Nationality__pc = 'United Arab Emirates';
        update acc;

  //      ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);
        acc.Nationality__pc = 'Jordan';
        update acc;

     //   ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);
        ADMRegistrationUtility.validateRegistrationDocuemnts(SR.Id);
                    Test.stopTest();

        }
            
    }
*/
    @isTest
    public static void createApplicationMethod (){
		User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;

        System.runAs(systemAdmin) {
           
       
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c,HexaBPM__External_Status_Name__c  From HexaBPM__Service_Request__c Limit 1];
        Account acc = new Account(Id = SR.SalesOrder__r.Account__c);
            
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Aldar Signed SPA';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        Document__c testDoc = new Document__c(
        DocumentType__c = 'Passport Copy',
        Account__c = acc.Id
        );
        insert testDoc;
            
        ContentVersion cv = new ContentVersion(
            Title = 'Test PDF',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
		insert cv;


		cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = testDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc.Name = 'Aldar Signed SPA';
        insert objSRDoc;
        TestObjectsFactory.createContentDocumentLink(objSRDoc.Id);  

         String responseBody = '{\"applicationName\":\"x-ald-sferp-api\",\"success\":true,\"statusCode\":\"201\",\"correlationId\":\"a9436fa0-d4a7-11ee-8711-06ca4ca4a2d9\",\"results\":{\"success\":false,\"elapsed\":1734,\"result\":{\"description\":\"Propertynotaccessible\",\"statusCode\":\"838404\",\"errorDetails\":\"400BadRequest:[{\\\"success\\\":false,\\\"elapsed\\\":1112,\\\"result\\\":{\\\"description\\\":\\\"Propertynotaccessible\\\",\\\"statusCode\\\":\\\"838404\\\"}}]\"}}}';
       // String responseBody = '{"error":"x-ald-sferp-api","success":false,"applicationId":"","description":"123456","errorMessgae":"123456","failureCode":"VAL033","errorDetails":"1234","result":"1234"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

        //ADMRegistrationUtility.createApplication(SR.Id);



        Unit__c unit = new Unit__c(Id = SR.Unit__c);
        unit.RecordTypeId = Utilities.getRecordTypeId('Unit__c', 'Plot');
        update unit;

        //ADMRegistrationUtility.createApplication(SR.Id);

        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;
        Test.startTest();
        Contact con = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        con.PrimaryContact__c = true;
        update con;

        SalesOrder__c so = new SalesOrder__c(Id = SR.SalesOrder__c);
        so.Account__c = orgAcc.Id;
        update so;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(so.Id, orgAcc.Id, 'Friend Of');
        insert jointOwner;

        JointOwner__c jointOwner1 = TestObjectsFactory.getJointOwnerRecord(so.Id, acc.Id, 'Friend Of');
        insert jointOwner1;

        //ADMRegistrationUtility.createApplication(SR.Id);
        ADMRegistrationUtility.validateRegistrationAttributes(SR.Id);
        ADMRegistrationUtility.uploadDocumentFuture(SR.Id,'123456', new List<String>{'Aldar Signed SPA'});
        ADMRegistrationUtility.submitApplicationFuture(SR.Id);
        ADMRegistrationUtility.sendApprovalStatusFuture(SR.Id, 'true');
        ADMRegistrationUtility.cancelApplicationFuture(SR.Id);
        ADMRegistrationUtility.paymentFuture(SR.Id);
                    Test.stopTest();

        }
    }

    @isTest
    public static void createApplicationMethod2 (){
		User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        System.runAs(systemAdmin) {
                   

        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
        Account acc = new Account(Id = SR.SalesOrder__r.Account__c);
            
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Aldar Signed SPA';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        Document__c testDoc = new Document__c(
            DocumentType__c = 'Passport Copy',
            Account__c = acc.Id
        );
        insert testDoc;
            
        ContentVersion cv = new ContentVersion(
            Title = 'Test PDF',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
		insert cv;


		cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = testDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc.Name = 'Aldar Signed SPA';
        insert objSRDoc;
            
        TestObjectsFactory.createContentDocumentLink(objSRDoc.Id);  
        Test.startTest();
      //  String responseBody = '{"success":true,"applicationId":"123456"}';
        String responseBody = '{\"applicationName\":\"x-ald-sferp-api\",\"success\":true,\"statusCode\":\"201\",\"correlationId\":\"d3a62ed0-d480-11ee-8a5f-02e2e997ec85\",\"results\":{\"success\":true,\"elapsed\":1382,\"result\":null}}';//Monika
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));

        ADMRegistrationUtility.createApplication(SR.Id);
        ADMRegistrationUtility.uploadDocumentFuture(SR.Id,'123456', new List<String>{'Aldar Signed SPA'});
        ADMRegistrationUtility.submitApplicationFuture(SR.Id);
        ADMRegistrationUtility.sendApprovalStatusFuture(SR.Id, 'true');
        ADMRegistrationUtility.cancelApplicationFuture(SR.Id);

        SR.ADMApplicationNumber__c = '123456';
        update SR;

        ADMRegistrationUtility.closeADMApproval('123456', 'Approved');
        ADMRegistrationUtility.closeADMApproval('123456', 'Rejected');
        ADMRegistrationUtility.closeADMApproval('1111', 'Rejected');

        ADMRegistrationUtility.paymentFuture(SR.Id);
        ADMRegistrationUtility.validateRegistrationDocs(SR.Id);
                    Test.stopTest();

        }
    }
	/*
    Monika added for succes Response
    */
        @isTest
        public static void createApplicationMethod3 (){
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            
              String responseBody = '{\"applicationName\":\"x-ald-sferp-api\",\"success\":true,\"statusCode\":\"201\",\"correlationId\":\"05598b70-cbf3-11ee-9a20-02b4fd272967\",\"results\":{\"success\":true,\"elapsed\":2464,\"result\":{\"ACTIVE_APPLICATION\":[{\"failureCode\":\"VAL002\",\"days\":null,\"results\":[\"2024/71367\"],\"details\":{}}],\"CONCURRENT_APPLICATION\":[{\"failureCode\":\"VAL061\",\"days\":null,\"results\":[\"20240000181754\"],\"details\":{}}]}}}';
              Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
      
              ADMRegistrationUtility.createApplication(SR.Id);
              Test.stopTest();
        }
        @isTest
        public static void testScheduleExecute() {
            // Create test data
            Map<String, String> headerConfiguration = new Map<String, String>{'HeaderKey' => 'HeaderValue'};
            String JSONBody = '{"key":"value"}';
            String muleConfig = 'SampleConfig';
            String extraParam = 'ExtraParam';
           // HexaBPM__SR_Status__c srStatus = [Select id from HexaBPM__SR_Status__c limit 1];
       		// insert srStatus;
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
           // SR.HexaBPM__External_SR_Status__c=srStatus.id;
            Test.startTest();
            update SR;
            HexaBPM__Step__c stp = [Select id from HexaBPM__Step__c limit 1];
			stp.HexaBPM__SR__c=SR.id;
            // Create a new instance of ScheduleUploadDocument
            ScheduleADMCreateAppCall scheduleJob = new ScheduleADMCreateAppCall(headerConfiguration, JSONBody, muleConfig, extraParam, SR.Id);
    
            
            scheduleJob.execute(null);
            Test.stopTest();
               
        }
}