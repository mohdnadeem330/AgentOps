@isTest
public class MergeAccountTest {
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        orgAcc.UAEVATRegisterNumber__c = 'abcdqwerabcdqwe';
        insert orgAcc;
        Account orgAcc2 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc2;
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        SR.HexaBPM__Customer__c=orgAcc.id;
        insert SR;
        
        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name ='Awaiting Approval';
        status1.HexaBPM__Code__c ='AWAITING_APPROVAL2';
        insert status1;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Step 1';
        ST.HexaBPM__Code__c = 'Require More Information';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'Require More Information';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Test';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        insert SRStep;
        
        Group testGroup2 = new Group(Name='Test User', Type='Queue');
        insert testGroup2;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Digital Signature by CCO';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        step.HexaBPM__Status__c = status1.id;
        step.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
        step.HexaBPM__Step_Notes__c = 'test area';
        step.HexaBPM__Step_No__c =30.0;
        step.ownerid = UserInfo.getUserId();
        // insert step; 
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        //Add GTC under project
        Document__c docRecord= new Document__c(Project__c=projectRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_SIGNED_KYC);
        insert docRecord;
    }
    
    @isTest static void findDuplicateAccountsByEmirateIdPassportTest3() {
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PassportNumber__pc = 'X170930923';
        acc.Nationality__pc = 'India';
        acc.PersonMobilePhone = '+918980676862';
        acc.PersonBirthdate = System.today()-30;
        acc.ERPID__c = 'X170930923';
        insert acc;
        
        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        orgAcc.ERPID__c = 'X170930924';
        insert orgAcc;
        
        Contact con = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Document__c docRecord = [SELECT Id FROM Document__c LIMIT 1];
        docRecord.DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_KYC;
        docRecord.Account__c = acc.Id;
        docRecord.Status__c = 'Uploaded';
        update docRecord;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('This is the file content')
        );
        insert cv;

        // Step 3: Query for the related ContentDocumentId
        ContentVersion insertedCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // Step 4: Create the ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCv.ContentDocumentId,
            LinkedEntityId = docRecord.Id,
            ShareType = 'V', // Viewer access (V), Collaborator (C), or Inferred (I)
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        
        
        Test.startTest();    
        MergeAccount.getDuplicateRecords(acc.Id,'Passport');
        Test.stopTest();
    }
    
    @isTest static void findDuplicateAccountsByEmirateIdPassportTest35() {
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PassportNumber__pc = 'X170930923';
        acc.Nationality__pc = 'India';
        acc.PersonMobilePhone = '+918980676862';
        acc.PersonBirthdate = System.today()-30;
        acc.ERPID__c = 'X170930923';
        insert acc;
        
        Account orgAcc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        orgAcc.PassportNumber__pc = 'X170930921';
        orgAcc.Nationality__pc = 'India';
        orgAcc.PersonMobilePhone = '+918980676861';
        orgAcc.PersonBirthdate = System.today()-20;
        orgAcc.ERPID__c = 'X170930921';
        insert orgAcc;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        Test.startTest();
        MergeAccount.createMasterAccountRecord(acc.Id, orgAcc.Id);
        MergeAccount.resetAccountRecord(orgAcc.Id, 'Error');
        Test.stopTest();
    }
    
    @isTest static void unitTest11() {
        Account orgAcc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        orgAcc.ERPID__c = 'X170930922';
        insert orgAcc;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PassportNumber__pc = 'X170930923';
        acc.Nationality__pc = 'India';
        acc.PersonMobilePhone = '+918980676862';
        acc.PersonBirthdate = System.today()-30;
        acc.ERPID__c = 'X170930923';
        acc.MasterAccount__c = orgAcc.Id;
        insert acc;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        Test.startTest();
        MergeAccount.processMergeRequest(new Set<Id>{acc.Id});
        Test.stopTest();
    }
    
    @isTest static void unitTest12() {
        Account orgAcc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        orgAcc.ERPID__c = 'X170930922';
        insert orgAcc;
        
        List<Id> mergeAccountIdsList = new List<Id>{orgAcc.Id};
        Test.startTest();
        StartBatchProcess__e event = new StartBatchProcess__e(BatchType__c = 'MergeCustomersBatchNew', RecordIds__c = String.join(mergeAccountIdsList, ','));
		EventBus.publish(event);
        Test.stopTest();
    }
    
    @isTest static void unitTest14() {
        Account orgAcc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        orgAcc.ERPID__c = 'X170930922';
        insert orgAcc;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PassportNumber__pc = 'X170930923';
        acc.Nationality__pc = 'India';
        acc.PersonMobilePhone = '+918980676862';
        acc.PersonBirthdate = System.today()-30;
        acc.ERPID__c = 'X170930923';
        acc.MasterAccount__c = orgAcc.Id;
        acc.Merging_Status__c = 'ERP Validation Failure';
        insert acc;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        Test.startTest();
        try{
            MergeAccount.createMasterAccountRecord(orgAcc.Id, acc.Id);
        } catch(exception ex) {}
        
        Test.stopTest();
    }
    
    @isTest static void unitTest13() {
        Account orgAcc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        //orgAcc.ERPID__c = 'X170930922';
        insert orgAcc;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PassportNumber__pc = 'X170930923';
        acc.Nationality__pc = 'India';
        acc.PersonMobilePhone = '+918980676862';
        acc.PersonBirthdate = System.today()-30;
        //acc.ERPID__c = 'X170930923';
        acc.MasterAccount__c = orgAcc.Id;
        acc.Merging_Status__c = 'Salesforce Merge Failed';
        insert acc;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        Test.startTest();
        try{
            MergeAccount.createMasterAccountRecord(orgAcc.Id, acc.Id);
        } catch(exception ex) {}
        Test.stopTest();
    }
    
    // Mock class for HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(201);
            res.setBody('{' +
                        '"results": [' +
                        '{ "fromSFID": "001FW000008CyDeYAK", "status": "Failure", "errorMsg": "Invalid Data" }' +
                        ']' +
                        '}');
            return res;
        }
    }
}