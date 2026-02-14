@isTest
public class CustomerPropertyJourneysWebServiceTest {

    @isTest
    public static void testCustomerPropertyJourneysWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
         Unit__c unit1 = TestObjectsFactory.unitDataSetup('25083');
        unit1.RecordTypeId = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get(Constants.UNIT_RECORD_TYPE_PLOT).getRecordTypeId();
        unit1.Status__c = 'Sold';
        insert unit1;
		
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        salesOrder1.Status__c = 'Sold';
        insert salesOrder1;

        

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        salesOrder.AMCStartDate__c = System.today();
        salesOrder.AMCEndDate__c = System.today();
        salesOrder.PMAStartDate__c = System.today();
        salesOrder.PMAEndDate__c = System.today();
        salesOrder.CustomerDLPStartDate__c = System.today();
        salesOrder.DLPDate__c = System.today();
        salesOrder.AMCEndDate__c = System.today();
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        SalesOrderOtherCharges__c salesOrderOtherCharge = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
		List<InstallmentLines__c> installmentLineList1 = TestObjectsFactory.createInstallmentLines(salesOrder1.Id, 5);
        SalesOrderOtherCharges__c salesOrderOtherCharge1 = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder1.Id, acc.Id);

        
        list<Document__c> docList = new list<Document__c>{new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_KYC, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_WEALTH, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = CustomerAPIConstants.DOCUMENT_SIGN_SPA, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
            												new Document__c(SalesOrder__c = salesOrder1.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder1.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_KYC, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder1.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_WEALTH, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder1.Id, DocumentType__c = CustomerAPIConstants.DOCUMENT_SIGN_SPA, Status__c = Constants.DOCUMENT_STATUS_UPLOADED)};
        insert docList;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template;

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

        list<HexaBPM__Status__c> stepStatus = new list<HexaBPM__Status__c>{new HexaBPM__Status__c(Name=Constants.STEP_STATUS_PENDING, HexaBPM__Code__c=Constants.STEP_STATUS_PENDING , HexaBPM__Type__c = 'Start'),
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

        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_APPOINTMENT_BOOKED),
                                                TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_SENT),
                                                TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
                                                TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT) , 
                                                TestObjectsFactory.getSRStatus(Constants.SR_STATUS_PENDING_FINANCE_VERIFICATION)};

        Appointment__c appRecord = new Appointment__c();
        appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
        appRecord.Date__c = date.today();
        appRecord.Slot__c = '08:00 - 09:00';
        appRecord.AppointmentType__c = Constants.HO_KEYHANDOVER;
        appRecord.AppointmentId__c = '123';
        appRecord.Broker__c = UserInfo.getUserId();
        appRecord.StartTime__c = Time.newInstance(18, 30, 2, 20);
        appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
        insert appRecord;

        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                             			HandoverCompletionDate__c =system.today().addDays(5),
                                                                        Status__c = Constants.HO_STATUS_READY,
                                                                        Stage__c = Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder.Id,
                                                                        isRTOHandover__c = false,
                                                                        UtilityTransferStatus__c = Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c = Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        CustomerSnaggingAppointment__c = appRecord.Id,
                                                                        CustomerDesnaggingAppointment__c = appRecord.Id,
                                                                        KeyHandoverAppointment__c = appRecord.Id);
        HandoverDetails__c hodetail1 = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit1.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c = Constants.HO_STATUS_READY,
                                                                        Stage__c = Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder1.Id,
                                                                        isRTOHandover__c = false,
                                                                        UtilityTransferStatus__c = Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c = Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        CustomerSnaggingAppointment__c = appRecord.Id,
                                                                        CustomerDesnaggingAppointment__c = appRecord.Id,
                                                                        KeyHandoverAppointment__c = appRecord.Id);
        insert hodetail;
Test.startTest();
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.HandoverDetail__c = hodetail.Id;
        insert SR;
        
        HexaBPM__Service_Request__c SR1 = new HexaBPM__Service_Request__c();
        SR1.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        SR1.HexaBPM__Customer__c = acc.Id;
        SR1.HexaBPM__Contact__c = acc.PersonContactId;
        SR1.HexaBPM__SR_Template__c = SR_Template.Id;
        SR1.Unit__c = unit1.Id;
        SR1.SalesOrder__c = salesOrder1.Id;
        SR1.HandoverDetail__c = hodetail1.Id;
        insert SR1;
        
        HexaBPM__SR_Status__c closedSRStatus = TestObjectsFactory.getSRStatus(CustomerAPIConstants.SR_STATUS_CLOSED);
        insert closedSRStatus;

        SR.HexaBPM__External_SR_Status__c = closedSRStatus.Id;
        update SR;
        
        list<HexaBPM__Step__c> srSteps = new list<HexaBPM__Step__c>();
        for(HexaBPM__SR_Steps__c tempRec : templateSteps){
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = tempRec.HexaBPM__Summary__c;
            step.HexaBPM__SR__c = SR.Id;
            step.HexaBPM__SR_Step__c = tempRec.Id;
            step.HexaBPM__Start_Date__c = System.today();
            srSteps.add(step);
        }
        for(HexaBPM__SR_Steps__c tempRec1 : templateSteps){
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = tempRec1.HexaBPM__Summary__c;
            step.HexaBPM__SR__c = SR1.Id;
            step.HexaBPM__SR_Step__c = tempRec1.Id;
            step.HexaBPM__Start_Date__c = System.today();
            srSteps.add(step);
        }
        insert srSteps;

        TestObjectsFactory.initializeRestContext(null, '/query/propertyjourneys');
        RestContextHandler handler = new RestContextHandler(true);
        
        
        try {
            CustomerPropertyJourneysWebService.doPost(acc.Id, new List<String>{salesOrder.Id,salesOrder1.Id}, '', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerPropertyJourneysWebServiceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        TestObjectsFactory.initializeRestContext(null, '/query/propertyjourneys');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerPropertyJourneysWebService.doPost(acc.Id, new List<String>{salesOrder.Id + '123'}, '', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}