/**
* QualtricsTest
*
* Test class for Qualtrics
*/
@isTest
private class QualtricsTest{
    //Creating test data
    @testSetup static void setupData() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
        // Create Lead From Account Record
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.ExistingAccount__c = acc.Id;
        leadRec.IsCreateFromExistingAccount__c = true;

        insert leadRec;
        
        //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template;
        
        
        // STEP AND STEP TEMPLATE
        list<HexaBPM__Step_Template__c> stepTemplateToInsert = new list<HexaBPM__Step_Template__c>();
        list<String> templatesCode = new list<String>{Constants.STEP_NAME_KAR_ASSIGNMENT,
                                                Constants.STEP_NAME_FINANCE_VERIFICATION,
                                                Constants.STEP_NAME_DESNAGGING_APPOINTMENT,
                                                Constants.STEP_NAME_UTILITY_TRANSFER,
                                                Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT,
                                                Constants.STEP_NAME_SNAGGING_APPOINTMENT,
                                                Constants.STEP_NAME_HANDOVER_PHASING,
                                                Constants.STEP_NAME_TITLE_DEED};
        for(String tempS : templatesCode){
            HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
            ST.Name = tempS;
            ST.HexaBPM__Code__c = tempS;
            ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
            stepTemplateToInsert.add(ST);
        }
        insert stepTemplateToInsert;
        
        //Step Status 
        list<HexaBPM__Status__c> stepStatus = new list<HexaBPM__Status__c>{ new HexaBPM__Status__c(Name=Constants.STEP_STATUS_PENDING, HexaBPM__Code__c=Constants.STEP_STATUS_PENDING , HexaBPM__Type__c = 'Start'),
                                                                        new HexaBPM__Status__c(Name=Constants.STEP_STATUS_COMPLETED, HexaBPM__Code__c=Constants.STEP_STATUS_COMPLETED , HexaBPM__Type__c = 'End')};
        insert stepStatus;
        list<HexaBPM__SR_Steps__c> templateSteps = new list<HexaBPM__SR_Steps__c>();
        for(HexaBPM__Step_Template__c tempRec : stepTemplateToInsert){
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = templateSteps.size()+1;
            SRStep.HexaBPM__Step_Template__c = tempRec.Id;
            SRStep.HexaBPM__Summary__c = tempRec.Name;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            SRStep.HexaBPM__Start_Status__c = stepStatus[0].Id;
            
            templateSteps.add(SRStep);
        }   
        insert templateSteps;
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_APPOINTMENT_BOOKED),
                                                TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_SENT),
                                                TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
                                                TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT) , 
                                                TestObjectsFactory.getSRStatus(Constants.SR_STATUS_PENDING_FINANCE_VERIFICATION)};
        
        
        //Handover 
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unitrecord.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c=Constants.HO_STATUS_READY,
                                                                        Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrderRecord.Id,
                                                                        isRTOHandover__c =  false,
                                                                        UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY    );                                        
        insert hodetail;                                            
        //SR AND STEP
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = handoverRecordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        //SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unitrecord.Id;
        SR.SalesOrder__c = salesOrderRecord.Id;
        SR.HandoverDetail__c = hodetail.Id;
        insert SR;
        
        list<HexaBPM__Step__c> srSteps = new list<HexaBPM__Step__c>();
        for(HexaBPM__SR_Steps__c tempRec : templateSteps){
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = tempRec.HexaBPM__Summary__c;
            step.HexaBPM__SR__c = SR.Id;
            step.HexaBPM__SR_Step__c = tempRec.Id;
            step.HexaBPM__Start_Date__c = System.today();
            srSteps.add(step);
        }
        insert srSteps;
    }
    //Test Qualtrics for SO
    @isTest static void testSalesOrder() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        SalesOrder__c salesOrderRecord =[select id from SalesOrder__c limit 1];
        Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
            System.enqueueJob(new Qualtrics.QualtricsIntegration(new set<ID>{salesOrderRecord.Id}));
        Test.StopTest();
        salesOrderRecord =[select id,QualtricsIntegrationStatus__c from SalesOrder__c limit 1];
        System.assertEquals(salesOrderRecord.QualtricsIntegrationStatus__c, Constants.QUALTRICS_SENT);
    }
    //Test Qualtrics for opportunity
    @isTest static void testOpportunity() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Opportunity opptyRecord =[select id from Opportunity limit 1];
        Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
            System.enqueueJob(new Qualtrics.QualtricsIntegration(new set<ID>{opptyRecord.Id}));
        Test.StopTest();
        opptyRecord =[select id,QualtricsIntegrationStatus__c from Opportunity limit 1];
        System.assertEquals(opptyRecord.QualtricsIntegrationStatus__c, Constants.QUALTRICS_SENT);
    }
    //Test Qualtrics for Lead
    @isTest static void testLead() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Lead leadRecord =[select id from Lead limit 1];
        Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
            System.enqueueJob(new Qualtrics.QualtricsIntegration(new set<ID>{leadRecord.Id}));
        Test.StopTest();
        leadRecord =[select id,QualtricsIntegrationStatus__c from Lead limit 1];
        System.assertEquals(leadRecord.QualtricsIntegrationStatus__c, Constants.QUALTRICS_SENT);
    }
    
    //Test Qualtrics for SR
    @isTest static void testSR() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        HexaBPM__Service_Request__c tempRec = [select id from HexaBPM__Service_Request__c limit 1];
        Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
            System.enqueueJob(new Qualtrics.QualtricsIntegration(new set<ID>{tempRec.Id}));
        Test.StopTest();
        tempRec =[select id,QualtricsIntegrationStatus__c from HexaBPM__Service_Request__c limit 1];
        System.assertEquals(tempRec.QualtricsIntegrationStatus__c, Constants.QUALTRICS_SENT);
    }
    
    //Test Qualtrics for Case
    @isTest static void testCase() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account; 

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unit;

        Case cs = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');
        cs.Unit__c = unit.Id;
        insert cs;
        
        Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
            System.enqueueJob(new Qualtrics.QualtricsIntegration(new set<ID>{cs.Id}));
        Test.StopTest();
        cs =[select id,QualtricsIntegrationStatus__c from Case limit 1];
        System.assertEquals(cs.QualtricsIntegrationStatus__c, Constants.QUALTRICS_SENT);
    }
       //Test Qualtrics for Case DLP
    @isTest static void testCaseDLP() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account; 

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unit;

        Case cs = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');
        cs.Unit__c = unit.Id;
        cs.Vertical__c = Constants.DLP_SUB_VERTICAL;
        insert cs;
        
        Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new QualtricsMockResponse());
            System.enqueueJob(new Qualtrics.QualtricsIntegration(new set<ID>{cs.Id}));
        Test.StopTest();
        cs =[select id,QualtricsIntegrationStatus__c from Case limit 1];
        System.assertEquals(cs.QualtricsIntegrationStatus__c, Constants.QUALTRICS_SENT);
    }
}