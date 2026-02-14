@isTest
private class HandoverCalloutHelperTest {
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
    public static void testHandoverCalloutSR (){
        HexaBPM__Service_Request__c srRecord = [select id,HandoverDetail__c from HexaBPM__Service_Request__c];
        HandoverDetails__c hod = new HandoverDetails__c(id=srRecord.HandoverDetail__c);
        Test.startTest();
            String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+srRecord.Id+'","status": "Success","errorMsg": "","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            hod.CHODate__c = system.today();
            update hod;
            HandoverCalloutHelper.getDataForCallout (new list<ID>{srRecord.Id});
            
            hod.RFODate__c  = system.today();
            update hod;
            HandoverCalloutHelper.getDataForCallout (new list<ID>{srRecord.Id});
        
            hod.TitleDeedCompletionDate__c  = system.today();
            update hod;
            HandoverCalloutHelper.getDataForCallout (new list<ID>{srRecord.Id});
        
            hod.HandoverCompletionDate__c  = system.today();
            update hod;
            HandoverCalloutHelper.getDataForCallout(new list<ID>{srRecord.Id});
        Test.stopTest();
    }
    @isTest
    public static void testHandoverErrorCalloutSR (){
        HexaBPM__Service_Request__c srRecord = [select id,HandoverDetail__c from HexaBPM__Service_Request__c];
        HandoverDetails__c hod = new HandoverDetails__c(id=srRecord.HandoverDetail__c);
        Test.startTest();
            String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+srRecord.Id+'","status": "Failed","errorMsg": "Failed","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            HandoverCalloutHelper.getDataForCallout (new list<ID>{srRecord.Id});
            
            hod.HandoverCompletionDate__c  = system.today();
            update hod;
            HandoverCalloutHelper.getDataForCallout (new list<ID>{srRecord.Id});
        Test.stopTest();
    }
}