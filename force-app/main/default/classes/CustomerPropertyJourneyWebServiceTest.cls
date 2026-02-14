@isTest
public class CustomerPropertyJourneyWebServiceTest {

    @isTest
    public static void testCustomerPropertyJourneyWebService() {

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
        salesOrder.CustomerDLPStartDate__c = date.today();
        salesOrder.DLPDate__c = date.today();
        salesOrder.HandoverServiceChargeStartDate__c = date.today();
        salesOrder.HandoverServiceChargeEndDate__c = date.today();
        salesOrder.HandoverReadyforOccupancyDate__c = date.today();
        salesOrder.AMCStartDate__c = date.today();
        salesOrder.AMCEndDate__c = date.today();
        salesOrder.PMAStartDate__c = date.today();
        salesOrder.PMAEndDate__c = date.today();
        insert salesOrder;

        Document__c document = new Document__c();
        document.SalesOrder__c = salesOrder.Id;
        document.DocumentType__c = CustomerAPIConstants.DOCUMENT_SPA_DELIVERY_LETTER;
        insert document;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        SalesOrderOtherCharges__c salesOrderOtherCharge = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);

        list<Document__c> docList = new list<Document__c>{new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = Constants.DOCUMENT_TYPE_KYC, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_KYC, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_WEALTH, Status__c = Constants.DOCUMENT_STATUS_UPLOADED),
                                                            new Document__c(SalesOrder__c = salesOrder.Id, DocumentType__c = CustomerAPIConstants.DOCUMENT_SIGN_SPA, Status__c = Constants.DOCUMENT_STATUS_UPLOADED)};
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
                                                TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT), 
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
		Test.startTest();
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c = Constants.HO_STATUS_READY,
                                                                        Stage__c = Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder.Id,
                                                                        isRTOHandover__c = false,
                                                                        UtilityTransferStatus__c = Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c = Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        CustomerSnaggingAppointment__c = appRecord.Id,
                                                                        CustomerDesnaggingAppointment__c = appRecord.Id,
                                                                        KeyHandoverAppointment__c = appRecord.Id,
                                                                        KAR__c = UserInfo.getUserId(),
                                                                        HandoverAgent__c = UserInfo.getUserId());
        insert hodetail;

        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.HandoverDetail__c = hodetail.Id;
        insert SR;
        
        HexaBPM__SR_Status__c closedSRStatus = TestObjectsFactory.getSRStatus(CustomerAPIConstants.SR_STATUS_CLOSED);
        insert closedSRStatus;

        SR.HexaBPM__External_SR_Status__c = closedSRStatus.Id;
        update SR;

        List<HexaBPM__SR_Doc__c> srDocList = new List<HexaBPM__SR_Doc__c>();
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_HOME_ORIENTATION_LETTER, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_CUSTOMER_SNAGGING, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_CUSTOMER_DESNAGGING, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_READY_FOR_OCCUPANCY_LETTER, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_TITLE_DEED_COPY, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_DISTRICT_COOLING_TRANSFER, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_SERVICE_CHARGES_PAYMENT_PROOF, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_ADDC_CERTIFICATE, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_NOC_FOR_ADDC, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_HANDOVER_NOC_LETTER, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_PLOT_POSSESSION_CERTIFICATE, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_SIGNED_HANDOVER_NOC_LETTER, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        srDocList.add(new HexaBPM__SR_Doc__c(Name=CustomerAPIConstants.DOCUMENT_SIGNED_PLOT_POSSESSION_CERTIFICATE, HexaBPM__Service_Request__c=SR.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_UPLOADED));
        insert srDocList;

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

        TestObjectsFactory.initializeRestContext(null, '/query/propertyjourney');
        RestContextHandler handler = new RestContextHandler(true);
        
        
        try {
            CustomerPropertyJourneyWebService.doPost(acc.Id, salesOrder.Id, '', '');
            External_Files__c ext = new External_Files__c();
            ext.Document__c=docList[0].Id;
            ext.File_Name__c = 'newdocument';
            ext.Deleted_by_Creator__c = false;
            ext.External_URL__c ='http://example.com/testfile';
            insert ext;
            DocumentQueryModel dq = new DocumentQueryModel();
            DocumentQueryModel dq1 = new DocumentQueryModel(ext);
            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerPropertyJourneyWebServiceError() {

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

        TestObjectsFactory.initializeRestContext(null, '/query/propertyjourney');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerPropertyJourneyWebService.doPost(acc.Id, salesOrder.Id + '123', '', '');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}