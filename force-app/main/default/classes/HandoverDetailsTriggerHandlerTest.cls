@isTest
private class HandoverDetailsTriggerHandlerTest {
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
        
        //Installment
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> paymentInstallmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert paymentInstallmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrder.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
            
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0].InvoicedAmount__c=installmentLines[0].InstallmentAmount__c;
            insert installmentLines;

        }
        
        
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
                                                    
                                                    
                                                    
                                                    
                                                    
        //Service Appointment
                                                    User testUser = TestObjectsFactory.getUserRecord('System Administrator', 'testuser');
        insert testUser;
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        opHours.TimeZone = 'Asia/Dubai';
        insert opHours;
        
        TimeSlot timeSlot = new TimeSlot();
        timeSlot.OperatingHoursId = opHours.Id;
        timeSlot.DayOfWeek = 'Monday';
        timeSlot.MaxAppointments = 5;
        timeSlot.StartTime = Time.newInstance(9, 0, 0, 0);
        timeSlot.EndTime = Time.newInstance(18, 0, 0, 0);
        insert timeSlot;
        
        ServiceTerritory serviceTerritoryRec = new ServiceTerritory(Name = 'Test Service Territory', OperatingHoursId = opHours.Id, IsActive = true);
        insert serviceTerritoryRec;
        
        ServiceResource serviceResource = new ServiceResource(Name = 'Test Service Resource', ResourceType = 'T', RelatedRecordId = testUser.Id, IsActive = true);
        insert serviceResource;
        
        ServiceTerritoryMember serviceTerritoryMemberrec = new ServiceTerritoryMember();
        serviceTerritoryMemberrec.ServiceTerritoryId = serviceTerritoryRec.Id;
        serviceTerritoryMemberrec.ServiceResourceId = serviceResource.Id;
        serviceTerritoryMemberrec.OperatingHoursId = opHours.Id;
        serviceTerritoryMemberrec.TerritoryType = 'P';
        serviceTerritoryMemberrec.EffectiveStartDate = Datetime.valueOf('2024-09-02 05:00:00');
        insert serviceTerritoryMemberrec;
        
        WorkType wt = new WorkType(Name = 'Home Orientation - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        
        WorkType wt2 = new WorkType(Name = 'Desnagging - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        
        WorkType wt3 = new WorkType(Name = 'Key Handover - Scheduled', EstimatedDuration = 60, DurationType = 'Minutes', OperatingHoursId = opHours.Id);
        insert new List<WorkType>{ wt, wt2, wt3 };
            
        Id handoverRT = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Handover').getRecordTypeId();
        ServiceAppointment rec = new ServiceAppointment();
        rec.serviceTerritoryId = serviceTerritoryRec.Id;
        rec.parentRecordId = acc.Id;
        rec.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        rec.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        rec.additionalInformation = 'Test Additional Info';
        rec.appointmentType = 'Handover';
        rec.comments = 'Test Comments for Home Orientation';
        rec.WorkTypeId = wt.Id;
        rec.RecordTypeId = handoverRT;  
        
        ServiceAppointment rec2 = new ServiceAppointment();
        rec2.serviceTerritoryId = serviceTerritoryRec.Id;
        rec2.parentRecordId = acc.Id;
        rec2.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        rec2.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        rec2.additionalInformation = 'Test Additional Info';
        rec2.appointmentType = 'Handover';
        rec2.comments = 'Test Comments for Desnagging';
        rec2.WorkTypeId = wt2.Id;
        rec2.RecordTypeId = handoverRT;
        
        ServiceAppointment rec3 = new ServiceAppointment();
        rec3.serviceTerritoryId = serviceTerritoryRec.Id;
        rec3.parentRecordId = acc.Id;
        rec3.schedStartTime = Datetime.valueOf('2025-05-05 09:00:00');
        rec3.schedEndTime = Datetime.valueOf('2025-05-05 10:00:00');
        rec3.additionalInformation = 'Test Additional Info';
        rec3.appointmentType = 'Handover';
        rec3.comments = 'Test Comments for Key Handover';
        rec3.WorkTypeId = wt3.Id;
        rec3.RecordTypeId = handoverRT;
        insert new List<ServiceAppointment>{ rec, rec2, rec3 };
                                                    
        
        //Handover 
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c=Constants.HO_STATUS_READY,
                                                                        Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder.Id,
                                                                        isRTOHandover__c =  false,
                                                                        UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY ,
                                                                        HandoverAgent__c = UserInfo.getUserId() ,
                                                             			kar__c = UserInfo.getUserId(),
                                                                        LastInstallment__c=installmentLines[0].id  );                                        
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
    public static void callMethod (){
        Test.startTest();
        
        ServiceAppointment ser1 = [Select Id From ServiceAppointment Where  comments = 'Test Comments for Home Orientation' Limit 1];
        ServiceAppointment ser2 = [Select Id From ServiceAppointment Where  comments = 'Test Comments for Desnagging' Limit 1];
        ServiceAppointment ser3 = [Select Id From ServiceAppointment Where  comments = 'Test Comments for Key Handover' Limit 1];
        
        Appointment__c  appRecord = new Appointment__c();
        appRecord.RecordTypeId = Utilities.getRecordTypeId('Appointment__c', 'Handover');
        appRecord.UnitCode__c = '25083MAYAN-B1-1001';
        appRecord.Date__c = system.today();
        appRecord.Slot__c = '08:00 - 09:00';
        appRecord.AppointmentType__c = Constants.HO_HOME_ORIENTATION ;
        appRecord.AppointmentId__c = '123';
        appRecord.Broker__c =UserInfo.getUserId();
        appRecord.StartTime__c =Time.newInstance(18, 30, 2, 20);
        appRecord.EndTIme__c = Time.newInstance(19, 30, 2, 20);
        insert appRecord;
        HandoverDetails__c hoDetail = [select id from HandoverDetails__c limit 1];
        hoDetail.CustomerSnaggingAppointment__c=appRecord.Id;
        hoDetail.QADesnaggingDate__c=system.today();
        hoDetail.CustomerSnaggingDate__c = System.today().addDays(2);
        update hoDetail;
        
        hoDetail.CustomerDesnaggingDate__c = system.today();
        hoDetail.Home_Orientation_Appointment__c = ser1.Id;
        hoDetail.Desnagging_Appointment__c = ser2.Id;
        hoDetail.Key_Handover_Appointment__c = ser3.Id;
        
        update hoDetail;
        Test.stopTest();
    }
    @isTest
    public static void testDesnagging (){
        Test.startTest();
        try{
            HandoverDetails__c hoDetail = [select id from HandoverDetails__c limit 1];
            hoDetail.CustomerDesnaggingDate__c = system.today();
           // hoDetail.CustomerSnaggingDate__c = System.today().addDays(2);
            update hoDetail; 
        }catch(exception e){}
        
        Test.stopTest();
    }
    
    @isTest
    public static void testPhasing (){
        Test.startTest();
        try{
            HandoverDetails__c hoDetail = [select id from HandoverDetails__c limit 1];
            //hoDetail.CustomerSnaggingDate__c = system.today();
            hoDetail.QASnaggingDate__c = system.today();
            hoDetail.HandoverPhaseDate__c = system.today().addDays(3);
            hoDetail.HandoverCompletionLetterDate__c = system.today();
            hoDetail.HandoverPhasingLetterDate__c = system.today();
            hoDetail.CHODate__c = system.today();
            hoDetail.HandoverAgent__c = UserInfo.getUserId();
            hoDetail.kar__c = UserInfo.getUserId();
            hoDetail.RFODate__c = system.today();
            update hoDetail;
        }catch(exception e){}
        Test.stopTest();
        HexaBPM__Service_Request__c sr =[select id from HexaBPM__Service_Request__c limit 1];
        set<String> taskSubjectList =new  set<String>();
        taskSubjectList.add(Constants.TASK_HO_CALL_48);
        taskSubjectList.add(Constants.TASK_HO_CALL_7);
        taskSubjectList.add(Constants.TASK_HO_CALL_14);
                    
        HandoverDetailsTriggerHandler.closeOpenTasks(new set<ID>{sr.id},taskSubjectList,true);
        
    }
    @isTest
    public static void testappointment (){
        Test.startTest();
        try{
           Unit__c unitrec =[select id,Name from Unit__c limit 1];
            Appointment__c  appRecord = new Appointment__c();
            appRecord.UnitCode__c = unitrec.Name;
            appRecord.Date__c = system.today();
            appRecord.Slot__c = '08:00 - 09:00';
            appRecord.AppointmentType__c = Constants.HO_DESNAGGING;
            appRecord.AppointmentId__c = '123';
            insert appRecord;
            
            
        }catch(exception e){}
        Test.stopTest();
        
    }
    @isTest
    public static void testappointment2 (){
        Test.startTest();
        try{
           Unit__c unitrec =[select id,Name from Unit__c limit 1];
            Appointment__c  appRecord = new Appointment__c();
            appRecord.UnitCode__c = unitrec.Name;
            appRecord.Date__c = system.today();
            appRecord.Slot__c = '08:00 - 09:00';
            appRecord.AppointmentType__c = Constants.HO_HOME_ORIENTATION;
            appRecord.AppointmentId__c = '123';
            insert appRecord;
            
            
        }catch(exception e){}
        Test.stopTest();
        
    }
    @isTest
    public static void testappointment3 (){
        Test.startTest();
        try{
           Unit__c unitrec =[select id,Name from Unit__c limit 1];
            Appointment__c  appRecord = new Appointment__c();
            appRecord.UnitCode__c = unitrec.Name;
            appRecord.Date__c = system.today();
            appRecord.Slot__c = '08:00 - 09:00';
            appRecord.AppointmentType__c = Constants.HO_KEYHANDOVER;
            appRecord.AppointmentId__c = '123';
            insert appRecord;
            
            
        }catch(exception e){}
        Test.stopTest();
        
    }

    
    
}