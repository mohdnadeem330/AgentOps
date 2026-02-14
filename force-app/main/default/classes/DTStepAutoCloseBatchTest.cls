/**
* DTStepAutoCloseBatchTest
*
* Test class for DTStepAutoCloseBatch
*/
@isTest
private class DTStepAutoCloseBatchTest{
    @testSetup static void setupData() {
            //offer
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
            
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
            insert projectRecord;
            BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
            insert buildingRecord;
            Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
            unitrecord.Status__c= COnstants.UNIT_STATUS_SOLD;
            insert unitrecord;
    
             
            SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder.Unit__c = unitrecord.Id;
        	salesOrder.HoldReasonCode__c = 'test123';
            insert salesOrder;
            
            //SR TEMPLATE
            HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
            SR_Template.Name = Constants.DEFAULT_AND_TERMINATION;
            SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.DEFAULT_AND_TERMINATION;
            insert SR_Template;
        
            // STEP AND STEP TEMPLATE
            HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
            ST.Name = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
            ST.HexaBPM__Code__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
            ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
            insert ST;
            
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = 1;
            SRStep.HexaBPM__Step_Template__c = ST.Id;
            SRStep.HexaBPM__Summary__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            insert SRStep;
            
            // STEP AND STEP TEMPLATE (STEP_STATUS_TRANSFER_LEGAL)
            ST = new HexaBPM__Step_Template__c();
            ST.Name = Constants.STEP_STATUS_TRANSFER_LEGAL;
            ST.HexaBPM__Code__c = Constants.STEP_STATUS_TRANSFER_LEGAL;
            ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
            insert ST;
            
            SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = 1;
            SRStep.HexaBPM__Step_Template__c = ST.Id;
            SRStep.HexaBPM__Summary__c = Constants.STEP_STATUS_TRANSFER_LEGAL;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            insert SRStep;
            
            //SR Status 
            insert new list<HexaBPM__SR_Status__c>{TestObjectsFactory.getSRStatus(Constants.SUBMITTED),TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT), TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_TRANSFER_LEGAL)};
            
             //SR AND STEP
            Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);
            HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
            SR.RecordTypeId = DandTRecordTypeId;
            SR.HexaBPM__Customer__c = acc.Id;
            SR.HexaBPM__Contact__c = acc.PersonContactId;
            //SR.OwnerId = UserInfo.getUserId();
            SR.HexaBPM__SR_Template__c = SR_Template.Id;
            SR.Unit__c = unitrecord.Id;
            SR.SalesOrder__c = salesOrder.Id;
            SR.StepClosureDate__c = System.TOday();
            insert SR;
            
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
            step.HexaBPM__SR__c = SR.Id;
            step.HexaBPM__SR_Step__c = SRStep.Id;
            step.HexaBPM__Start_Date__c = System.today();
            insert step; 
    }
    //Test Installment records,
    @isTest static void testInstallmentEmailNotification() {
        
        Test.StartTest();
        System.schedule('DTStepAutoCloseBatch-Test', '0 0 * * * ?', new DTStepAutoCloseBatch() );
        Test.StopTest();
    }
    
}