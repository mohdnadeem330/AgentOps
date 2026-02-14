/**
* AppointmentTriggerHandlerTest
*
* Test class for AppointmentTriggerHandler
*/

@isTest
private class AppointmentTriggerHandlerTest {
   //Create setupData
    @testSetup static void setupData() {
        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
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
        
        list<HexaBPM__SR_Steps__c> templateSteps = new list<HexaBPM__SR_Steps__c>();
        for(HexaBPM__Step_Template__c tempRec : stepTemplateToInsert){
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = templateSteps.size()+1;
            SRStep.HexaBPM__Step_Template__c = tempRec.Id;
            SRStep.HexaBPM__Summary__c = tempRec.Name;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            templateSteps.add(SRStep);
        }   
        insert templateSteps;
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_APPOINTMENT_BOOKED),
                                                TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_SENT),
                                                TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
                                                TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT)};
        
        //Handover 
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c=Constants.HO_STATUS_READY,
                                                                        Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder.Id,
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
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
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
    
    @isTest
    public static void testAppointmentsDeSnag (){
        Test.startTest();
            Unit__c unitrec =[select id,Name from Unit__c limit 1];
            Appointment__c  appRecord = new Appointment__c();
            appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
            appRecord.UnitCode__c = unitrec.Name;
            appRecord.Date__c = system.today();
            appRecord.Slot__c = '08:00 - 09:00';
            appRecord.AppointmentType__c = Constants.HO_DESNAGGING;
            appRecord.AppointmentId__c = '123';
            appRecord.Broker__c =UserInfo.getUserId();
            appRecord.StartTime__c =Time.newInstance(18, 30, 2, 20);
            appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
            insert appRecord;
        Test.stopTest();
    }
    @isTest
    public static void testAppointmentsHO (){
       
            Unit__c unitrec =[select id,Name from Unit__c limit 1];
            Appointment__c  appRecord = new Appointment__c();
            appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
            appRecord.UnitCode__c = unitrec.Name;
            appRecord.Date__c = system.today();
            appRecord.Slot__c = '08:00 - 09:00';
            appRecord.AppointmentType__c = Constants.HO_HOME_ORIENTATION ;
            appRecord.AppointmentId__c = '123';
            appRecord.Broker__c =UserInfo.getUserId();
            appRecord.StartTime__c =Time.newInstance(18, 30, 2, 20);
            appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
            insert appRecord;
        
        	test.startTest();
                appRecord.EndTIme__c = Time.newInstance(18, 30, 2, 20);
                update appRecord;
        	test.stoptest();
      
    }
    @isTest
    public static void testAppointmentsKey (){
        Test.startTest();
            Unit__c unitrec =[select id,Name from Unit__c limit 1];
            Appointment__c  appRecord = new Appointment__c();
            appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
            appRecord.UnitCode__c = unitrec.Name;
            appRecord.Date__c = system.today();
            appRecord.Slot__c = '08:00 - 09:00';
            appRecord.AppointmentType__c = Constants.HO_KEYHANDOVER ;
            appRecord.AppointmentId__c = '123';
            appRecord.Broker__c =UserInfo.getUserId();
            appRecord.StartTime__c =Time.newInstance(18, 30, 2, 20);
            appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
            insert appRecord;
        
	TriggerHandler.processedIds = new Set<Id>();

        HexaBPM__Service_Request__c sr = [Select ID from HexaBPM__Service_Request__c Limit 1];
        appRecord.ServiceRequest__c = sr.Id;
        update appRecord;
        Test.stopTest();
    }
    @isTest
    public static void testAppointmentsCase (){
        Test.startTest();
            Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
            insert account; 
    
            Contact con = TestObjectsFactory.contactDataSetup(account.Id);
        
            Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
            unit.Status__c = 'Sold';
            insert unit;
    
            Case cs = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');
            cs.Unit__c = unit.Id;
            insert cs;
            cs =[select id,CaseNumber from Case limit 1];
            
            Appointment__c  appRecord = new Appointment__c();
            appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Pre Sales');
            appRecord.Date__c = system.today();
            appRecord.Slot__c = '08:00 - 09:00';
            appRecord.AppointmentType__c = Constants.ASSESSMENT ;
            appRecord.AppointmentId__c = '123';
            appRecord.CaseNumber__c = cs.CaseNumber ;
            appRecord.Broker__c =UserInfo.getUserId();
            appRecord.StartTime__c =Time.newInstance(18, 30, 2, 20);
            appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
            insert appRecord;
        
                        TriggerHandler.processedIds = new Set<Id>();

        	appRecord.Slot__c = '09:00 - 10:00';
            update appRecord;
            AppointmentTriggerHandler.deleteEventRecords(new List<String>{'Test'});
        
        Test.stopTest();
    }
    
    public static void testAppointmentsCaseUpdate (){
        Test.startTest();
            Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
            insert account; 
    
            Contact con = TestObjectsFactory.contactDataSetup(account.Id);
        
            Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
            unit.Status__c = 'Sold';
            insert unit;
    
            Case cs = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');
            cs.Unit__c = unit.Id;
            insert cs;
            cs =[select id,CaseNumber from Case limit 1];
            
            Appointment__c  appRecord = new Appointment__c();
            appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', Constants.ASSESSMENT);
            appRecord.Date__c = system.today();
            appRecord.Slot__c = '08:00 - 09:00';
            appRecord.AppointmentType__c = Constants.ASSESSMENT ;
            appRecord.AppointmentId__c = '123';
            appRecord.CaseNumber__c = cs.CaseNumber ;
            appRecord.StartTime__c =Time.newInstance(18, 30, 2, 20);
            appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
            insert appRecord;
        
                TriggerHandler.processedIds = new Set<Id>();

        	appRecord.Broker__c =UserInfo.getUserId();
            update appRecord;
                TriggerHandler.processedIds = new Set<Id>();

        	appRecord.Slot__c = '09:00 - 10:00';
        	appRecord.AsiteSyncStatus__c = Constants.STATUS_IN_PROGRESS;
            update appRecord;

                TriggerHandler.processedIds = new Set<Id>();

        	appRecord.Status__c = 'Cancelled';
        	update appRecord;
        
            AppointmentTriggerHandler.deleteEventRecords(new List<String>{'Test'});
        Test.stopTest();
    }

}