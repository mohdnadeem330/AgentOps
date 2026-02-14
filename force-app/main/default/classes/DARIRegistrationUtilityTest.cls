/**
* @description       : This class used for cover DARIRegistrationUtility apex class
* @coverage          : DARIRegistrationUtility.cls | @CC100%
* @author            : rmohmmed@aldar.com
* @group             : Aldar
* @last modified on  : 02-01-2024
* @last modified by  : rmohmmed@aldar.com
* Modifications Log
* Ver   Date         Author                        Modification
* 1.0   02-01-2024   rmohmmed@aldar.com            Initial Version | Story Number | @CC100%
**/
@isTest
private class DARIRegistrationUtilityTest {
    //Create setupData
    @testSetup static void setupData() {
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.PENDING_STATUS;
        status.HexaBPM__Code__c = Constants.PENDING_STATUS;
        insert status;
        
        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name = Constants.COMPLETED_STATUS;
        status1.HexaBPM__Code__c = Constants.COMPLETED_STATUS;
        insert status1;
        
        HexaBPM__Status__c status2 = new HexaBPM__Status__c();
        status2.Name = Constants.STEP_APPROVED_STATUS;
        status2.HexaBPM__Code__c = Constants.STEP_APPROVED_STATUS;
        insert status2;
        
        Map<String, Id> recordTypeSR = new Map<String, Id>();
        for(Recordtype rtype : [SELECT Id, DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'TitleDeedRegistration']){
            recordTypeSR.put(rtype.DeveloperName, rtype.Id);
        }
        
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
        salesOrder.NetAmount__c = 100000;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);
        List<HexaBPM__SR_Status__c> srStatusList = new List<HexaBPM__SR_Status__c>();
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        srStatusList.add(objSRStatus);
        
        HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus(Constants.PENDING_STATUS);
        srStatusList.add(objSRStatus1);
        
        HexaBPM__SR_Status__c objSRStatus2 = TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS);
        srStatusList.add(objSRStatus2);
        
        HexaBPM__SR_Status__c objSRStatus3 = TestObjectsFactory.getSRStatus(Constants.STEP_APPROVED_STATUS);
        srStatusList.add(objSRStatus3);
        
        HexaBPM__SR_Status__c objSRStatus4 = TestObjectsFactory.getSRStatus(Constants.STEP_ACCEPTED_STATUS);
        srStatusList.add(objSRStatus4);
        
        HexaBPM__SR_Status__c objSRStatus5 = TestObjectsFactory.getSRStatus(Constants.STEP_REJECTED_STATUS);
        srStatusList.add(objSRStatus5);
        
        insert srStatusList;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Title Deed Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c = 'TitleDeedRegistration';
        insert SR_Template;
        
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('TitleDeedRegistration');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.MortgageApplicable__c = 'No';
        SR.ApplicationId__c = 123456;
        insert SR;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'CM Validation';
        ST.HexaBPM__Code__c = 'CM Validation';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST1 = new HexaBPM__Step_Template__c();
        ST1.Name = 'SOA Verification';
        ST1.HexaBPM__Code__c = 'SOA Verification';
        ST1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST2 = new HexaBPM__Step_Template__c();
        ST2.Name = 'Initiate Registration';
        ST2.HexaBPM__Code__c = 'Initiate Registration';
        ST2.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST3 = new HexaBPM__Step_Template__c();
        ST3.Name = 'Mortgage Registration';
        ST3.HexaBPM__Code__c = 'Mortgage Registration';
        ST3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST4 = new HexaBPM__Step_Template__c();
        ST4.Name = 'Registration In Progress';
        ST4.HexaBPM__Code__c = 'Registration In Progress';
        ST4.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST5 = new HexaBPM__Step_Template__c();
        ST5.Name = 'Salesforce - Approval';
        ST5.HexaBPM__Code__c = 'Salesforce - Approval';
        ST5.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST6 = new HexaBPM__Step_Template__c();
        ST6.Name = 'Registration Completion';
        ST6.HexaBPM__Code__c = 'Registration Completion';
        ST6.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST7 = new HexaBPM__Step_Template__c();
        ST7.Name = 'ADM Team Approval';
        ST7.HexaBPM__Code__c = 'ADM Team Approval';
        ST7.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST9 = new HexaBPM__Step_Template__c();
        ST9.Name = 'Payment Step';
        ST9.HexaBPM__Code__c = 'Payment Step';
        ST9.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__Step_Template__c ST8 = new HexaBPM__Step_Template__c();
        ST8.Name = 'Capture Fee Details';
        ST8.HexaBPM__Code__c = 'Capture Fee Details';
        ST8.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        insert new List<HexaBPM__Step_Template__c>{ST, ST1, ST2, ST3, ST4, ST5, ST6, ST7, ST8, ST9};
            
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'CM Validation';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep1 = new HexaBPM__SR_Steps__c();
        SRStep1.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep1.HexaBPM__Step_No__c = 1;
        SRStep1.HexaBPM__Step_Template__c = ST1.Id;
        SRStep1.HexaBPM__Summary__c = 'SOA Verification';
        SRStep1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep2 = new HexaBPM__SR_Steps__c();
        SRStep2.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep2.HexaBPM__Step_No__c = 1;
        SRStep2.HexaBPM__Step_Template__c = ST2.Id;
        SRStep2.HexaBPM__Summary__c = 'Initiate Registration';
        SRStep2.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep3 = new HexaBPM__SR_Steps__c();
        SRStep3.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep3.HexaBPM__Step_No__c = 1;
        SRStep3.HexaBPM__Step_Template__c = ST3.Id;
        SRStep3.HexaBPM__Summary__c = 'Mortgage Registration';
        SRStep3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep4 = new HexaBPM__SR_Steps__c();
        SRStep4.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep4.HexaBPM__Step_No__c = 1;
        SRStep4.HexaBPM__Step_Template__c = ST4.Id;
        SRStep4.HexaBPM__Summary__c = 'Registration In Progress';
        SRStep4.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep5 = new HexaBPM__SR_Steps__c();
        SRStep5.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep5.HexaBPM__Step_No__c = 1;
        SRStep5.HexaBPM__Step_Template__c = ST5.Id;
        SRStep5.HexaBPM__Summary__c = 'Salesforce - Approval';
        SRStep5.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep6 = new HexaBPM__SR_Steps__c();
        SRStep6.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep6.HexaBPM__Step_No__c = 1;
        SRStep6.HexaBPM__Step_Template__c = ST6.Id;
        SRStep6.HexaBPM__Summary__c = 'Registration Completion';
        SRStep6.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep7 = new HexaBPM__SR_Steps__c();
        SRStep7.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep7.HexaBPM__Step_No__c = 1;
        SRStep7.HexaBPM__Step_Template__c = ST7.Id;
        SRStep7.HexaBPM__Summary__c = 'ADM Team Approval';
        SRStep7.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep8 = new HexaBPM__SR_Steps__c();
        SRStep8.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep8.HexaBPM__Step_No__c = 1;
        SRStep8.HexaBPM__Step_Template__c = ST8.Id;
        SRStep8.HexaBPM__Summary__c = 'Capture Fee Details';
        SRStep8.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        HexaBPM__SR_Steps__c SRStep9 = new HexaBPM__SR_Steps__c();
        SRStep9.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep9.HexaBPM__Step_No__c = 1;
        SRStep9.HexaBPM__Step_Template__c = ST9.Id;
        SRStep9.HexaBPM__Summary__c = 'Payment Step';
        SRStep9.HexaBPM__Step_RecordType_API_Name__c = 'General';
        
        insert new List<HexaBPM__SR_Steps__c>{SRStep, SRStep1, SRStep2, SRStep3, SRStep4, SRStep5, SRStep6, SRStep7, SRStep8, SRStep9};
            
            HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'CM Validation';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'SOA Verification';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = SRStep1.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Initiate Registration';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep2.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step3 = new HexaBPM__Step__c();
        step3.HexaBPM__Summary__c = 'Mortgage Registration';
        step3.HexaBPM__SR__c = SR.Id;
        step3.HexaBPM__SR_Step__c = SRStep3.Id;
        step3.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step4 = new HexaBPM__Step__c();
        step4.HexaBPM__Summary__c = 'Registration In Progress';
        step4.HexaBPM__SR__c = SR.Id;
        step4.HexaBPM__SR_Step__c = SRStep4.Id;
        step4.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step5 = new HexaBPM__Step__c();
        step5.HexaBPM__Summary__c = 'Salesforce - Approval';
        step5.HexaBPM__SR__c = SR.Id;
        step5.HexaBPM__SR_Step__c = SRStep5.Id;
        step5.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step6 = new HexaBPM__Step__c();
        step6.HexaBPM__Summary__c = 'Registration Completion';
        step6.HexaBPM__SR__c = SR.Id;
        step6.HexaBPM__SR_Step__c = SRStep6.Id;
        step6.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step7 = new HexaBPM__Step__c();
        step7.HexaBPM__Summary__c = 'ADM Team Approval';
        step7.HexaBPM__SR__c = SR.Id;
        step7.HexaBPM__SR_Step__c = SRStep7.Id;
        step7.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step8 = new HexaBPM__Step__c();
        step8.HexaBPM__Summary__c = 'Capture Fee Details';
        step8.HexaBPM__SR__c = SR.Id;
        step8.HexaBPM__SR_Step__c = SRStep8.Id;
        step8.HexaBPM__Start_Date__c = System.today();
        
        HexaBPM__Step__c step9 = new HexaBPM__Step__c();
        step9.HexaBPM__Summary__c = 'Payment Step';
        step9.HexaBPM__SR__c = SR.Id;
        step9.HexaBPM__SR_Step__c = SRStep9.Id;
        step9.HexaBPM__Start_Date__c = System.today();
        
        insert new List<HexaBPM__Step__c>{step, step1, step2, step3, step4, step5, step6, step7, step8, step9};
            
            
            
            HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Mortgage Agreement';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc.Name = 'Mortgage Agreement';
        insert objSRDoc;
        
        TestObjectsFactory.createContentDocumentLink(objSRDoc.Id);
    }
    
    @isTest
    public static void createApplicationMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "2eb811b0-c745-11ee-b6ad-02e197650587", "results": { "success": true, "elapsed": 14060, "result": { "id": 48031, "applicationNumber": "20240000048031", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "premiseId": null, "premiseAddress": null, "isPremiseIdRequired": false, "payLiability": null } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.createApplication(SR.Id);
            /*ADMRegistrationUtility.createApplication(SR.Id);
ADMRegistrationUtility.uploadDocumentFuture(SR.Id,'123456', new List<String>{'Aldar Signed SPA'});
ADMRegistrationUtility.submitApplicationFuture(SR.Id);
ADMRegistrationUtility.sendApprovalStatusFuture(SR.Id, 'true');
ADMRegistrationUtility.cancelApplicationFuture(SR.Id);
ADMRegistrationUtility.paymentFuture(SR.Id);*/
            Test.stopTest();
        }
    }
    
    @isTest
    public static void fetchApplicationMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.fetchApplication(SR.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void postPropertyDetailsMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.postPropertyDetails(SR.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void postRegistrationFeeDetailsMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.postRegistrationFeeDetails(SR.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void postUploadDocumentMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.postUploadDocument(SR.Id, 123456 , new List<String>{'Mortgage Agreement'});
            Test.stopTest();
        }
    }
    
    @isTest
    public static void submitApplicationMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.submitApplication(SR.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void postDeveloperApprovalMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.postDeveloperApproval(SR.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void cancellationAppMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.cancellationApp(SR.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void dmtRegFeePaymentsMethodTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "5efc1b10-c6b3-11ee-8667-0660f3e525b1", "results": { "success": true, "elapsed": 26, "result": { "transactionFeeAmount": null, "transactionFeePaidBy": null, "transactionFeePaymentType": null, "transactionFeePaymentSubType": null, "adminFeeAmount": null, "adminFeeVatPercentage": null, "adminFeeVatAmount": null, "adminFeePaymentType": null, "adminFeePaymentSubType": null, "adminFeeTotalAmount": null, "transactionTotalAmount": null, "mortgageTransactionFeeAmount": null, "mortgageTransactionFeeMaxAmount": null, "mortgageTransactionFeePaidBy": null, "mortgageTransactionFeePercent": null, "mortgageTransactionFeePaymentType": null, "mortgageTransactionFeePaymentSubType": null, "mortgageAdminFeeAmount": null, "mortgageAdminFeeVatPercentage": null, "mortgageAdminFeeVatAmount": null, "mortgageAdminFeePaymentType": null, "mortgageAdminFeePaymentSubType": null, "mortgageAdminFeeTotalAmount": null, "mortgageTransactionTotalAmount": null, "liabilityAmount": null, "liabilityAmountPaidBy": null, "liabilityFeePaymentType": null, "liabilityFeePaymentSubType": null, "isVilla": null, "showTawteeqSection": null, "propertyRegFeeAmount": null, "propertyRegFeePaidBy": null, "propertyRegFeePaymentType": null, "propertyRegFeePaymentSubType": null, "unitRegFeeAmount": null, "unitRegFeePaidBy": null, "unitRegFeePaymentType": null, "unitRegFeePaymentSubType": null, "propertyRegTotalAmount": null, "totalAmount": null, "paymentList": null, "paidBys": [] } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.dmtRegFeePayments(SR.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void getPaymentBreakdownTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.getPaymentBreakdown(SR.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void otherTest (){
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            Test.startTest();
            HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c  From HexaBPM__Service_Request__c Limit 1];
            String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "8d16b620-c3ef-11ee-a3bc-0251a40159f9", "results": { "success": true, "elapsed": 1557, "result": { "applicationId": 45709, "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "applicationDetails": { "applicationId": 45709, "applicationNumber": "20240000045709", "applicationType": "OFFPLAN_TO_COMPLETE_LAND", "workflowID": 1322, "plotID": 71486 } } } }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DARIRegistrationUtility.closeADMApproval(123456, 'Approved');
            DARIRegistrationUtility.updatePaymentStatus(123456, 'Approved');
            Test.stopTest();
        }
    }
    
    public static testMethod void DARIRegistrationStatusServiceUpdateStatus(){
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c, Unit__c, ApplicationNumber__c  From HexaBPM__Service_Request__c Limit 1];
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/DARI/statusService/statusUpdate'; 
        req.httpMethod = 'Post';
        RestContext.request = req;
        RestContext.response = res; 
        Test.startTest();
        //  DARIRegistrationStatusService.updateStatus(123456, 'Approved', 'Approval');
        // DARIRegistrationStatusService.updateStatus(123456, 'Approved', 'Payment');
        Test.stopTest();  
    }
    
    @isTest
    public static void postMortgageDetailsMethodTest() {
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        insert systemAdmin;
        
        System.runAs(systemAdmin) {
            // Pick one SR record
            HexaBPM__Service_Request__c SR = [
                SELECT Id, ApplicationId__c, Unit__c, SalesOrder__c
                FROM HexaBPM__Service_Request__c
                LIMIT 1
            ];
            
            // Ensure Mortgage Registration step exists
            HexaBPM__Step__c mortgageStep = new HexaBPM__Step__c(
                HexaBPM__Summary__c = 'Mortgage Registration',
                HexaBPM__SR__c = SR.Id,
                HexaBPM__Start_Date__c = Date.today()
            );
            insert mortgageStep;
            
            Test.startTest();
            
            // --- SUCCESS branch ---
            String successResponse = '{'+
                '"applicationName": "x-ald-sferp-api",'+
                '"success": true,'+
                '"statusCode": "201",'+
                '"results": {'+
                '"success": true,'+
                '"result": { "id": 48031 }'+
                '}'+
                '}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(successResponse));
            DARIRegistrationUtility.postMortgageDetailsFuture(SR.Id);
            
            // --- FAILURE branch ---
            String failureResponse = '{'+
                '"applicationName": "x-ald-sferp-api",'+
                '"success": true,'+
                '"statusCode": "400",'+
                '"results": {'+
                '"success": false,'+
                '"result": { "error": "Invalid Data" }'+
                '}'+
                '}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(failureResponse));
            DARIRegistrationUtility.postMortgageDetailsFuture(SR.Id);
            
            Test.stopTest();
            
            // Assert SUCCESS updated step
            HexaBPM__Step__c stepCheck = [
                SELECT Id, HexaBPM__Status__c
                FROM HexaBPM__Step__c
                WHERE Id = :mortgageStep.Id
            ];
        }
    }  
}