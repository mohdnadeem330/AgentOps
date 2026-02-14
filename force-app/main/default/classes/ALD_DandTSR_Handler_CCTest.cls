@isTest
public class ALD_DandTSR_Handler_CCTest {
    @testSetup static void setupData() {

        User us = [SELECT Id FROM User WHERE IsActive=true and UserName!=:Userinfo.getUserName() and ProfileId=:UserInfo.getProfileId() Limit 1];
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.CustomerBankName__c = 'Bank Name';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.DEFAULT_AND_TERMINATION;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.DEFAULT_AND_TERMINATION;
        insert SR_Template;
        
        Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);

        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = DandTRecordTypeId;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.SRType__c = 'Default And Termination';
        insert SR;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Manage Receipt';
        ST.HexaBPM__Code__c = 'Manage Receipt';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
        objStatus.Name = 'Approved';
        objStatus.HexaBPM__Type__c = 'End';
        objStatus.HexaBPM__Code__c = 'Approved';
        insert objStatus;
        
        HexaBPM__Status__c objStatus2 = new HexaBPM__Status__c();
        objStatus2.Name = 'Pending';
        objStatus2.HexaBPM__Type__c = 'End';
        objStatus2.HexaBPM__Code__c = 'Pending';
        insert objStatus2;
        
        list<HexaBPM__Status__c> stepStatus = new list<HexaBPM__Status__c>{
            new HexaBPM__Status__c(Name=Constants.STEP_STATUS_CUSTOMER_SETTELED, HexaBPM__Code__c=Constants.STEP_STATUS_CUSTOMER_SETTELED , HexaBPM__Type__c = 'End'),
            new HexaBPM__Status__c(Name=ALD_Constants.REFERRED_TO_DandT_BY_LEGAL, HexaBPM__Code__c=ALD_Constants.REFERRED_TO_DandT_BY_LEGAL , HexaBPM__Type__c = 'End'),
            new HexaBPM__Status__c(Name=ALD_Constants.SENT_TO_EXTERNAL_COUNSEL, HexaBPM__Code__c=ALD_Constants.SENT_TO_EXTERNAL_COUNSEL , HexaBPM__Type__c = 'End'),
            new HexaBPM__Status__c(Name=ALD_Constants.SUBMITTED_TO_COURT, HexaBPM__Code__c=ALD_Constants.SUBMITTED_TO_COURT , HexaBPM__Type__c = 'End')};
                insert stepStatus;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Manage Receipt';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Manage Receipt';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        step.OwnerId = us.Id;
        step.HexaBPM__Status__c = objStatus2.Id;
        insert step; 
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Verify the Request';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        step2.HexaBPM__Status__c = objStatus.Id;
        insert step2; 
        
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_TRANSFER_LEGAL),
            TestObjectsFactory.getSRStatus(Constants.SR_STATUS_CLOSED),
            TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
            TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT) , 
            TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_CUSTOMER_SETTELED),
            TestObjectsFactory.getSRStatus(ALD_Constants.PULLED_BACK_BY_DandT),
            TestObjectsFactory.getSRStatus(ALD_Constants.SENT_TO_EXTERNAL_COUNSEL),
            TestObjectsFactory.getSRStatus(ALD_Constants.REFERRED_TO_DandT_BY_LEGAL)};
        
    }
    
    @isTest static void testInstallmentRecords() {
        test.startTest();

        HexaBPM__Service_Request__c srRecord = ServiceRequestService.getServiceRequestWithWhereClause(null)[0];
        //srRecord.LegalFees__c = 1000;
        //update srRecord;
        //Create other charge section
        ALD_DandTSR_Handler_CC.Special_Exceptional_Case = true;
        ALD_DandTSR_Handler_CC.handleDandTSR(new Set<Id>{srRecord.HexaBPM__Customer__c},new Map<Id,HexaBPM__Service_Request__c>(new List<HexaBPM__Service_Request__c>{srRecord}));
        //External councel section
        HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SUBMITTED LIMIT 1];

        srRecord.HexaBPM__External_SR_Status__c = objSRStatus.Id;
        srRecord.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
        srRecord.LegalStatus__c = ALD_Constants.SENT_TO_EXTERNAL_COUNSEL;
        update srRecord;
        ALD_DandTSR_Handler_CC.pushPullTheSr(ALD_Constants.pushTransferToLegalTitle,new List<Id>{srRecord.Id},'test');

        
        ALD_DandTSR_Handler_CC.Special_Exceptional_Case = false;
        ALD_DandTSR_Handler_CC.handleDandTSR(new Set<Id>{srRecord.HexaBPM__Customer__c},new Map<Id,HexaBPM__Service_Request__c>(new List<HexaBPM__Service_Request__c>{srRecord}));
        ALD_DandTSR_Handler_CC.shouldPushOrPullApx(srRecord.Id);
        ALD_DandTSR_Handler_CC.pubStepStatusSoql(new List<String>{'Pending'});
        
        
        CC_ALD_DandTSR_Handler ccHandler = new CC_ALD_DandTSR_Handler();
        HexaBPM__Step__c stp = [SELECT Id,HexaBPM__Summary__c,HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' Limit 1];
        ccHandler.EvaluateCustomCode(srRecord, stp);
        
        ccHandler.EvaluateCustomCode(null, null);
        
        test.stopTest();
    }
    
    @isTest 
    static void testSRStepsRecords() {
        User us = [SELECT Id FROM User WHERE IsActive=true and UserName!=:Userinfo.getUserName() and ProfileId=:UserInfo.getProfileId() Limit 1];

        HexaBPM__Service_Request__c srRecord = ServiceRequestService.getServiceRequestWithWhereClause(null)[0];
        ALD_DandTSR_Handler_CC.Special_Exceptional_Case = true;
        ALD_DandTSR_Handler_CC.handleDandTSR(new Set<Id>{srRecord.HexaBPM__Customer__c},new Map<Id,HexaBPM__Service_Request__c>(new List<HexaBPM__Service_Request__c>{srRecord}));
        
        ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srRecord.Id});
        ServiceRequestService.getOpenServiceRequestByType(new Set<String>{Constants.DEFAULT_AND_TERMINATION});
        ServiceRequestService.getOpenServiceRequestListByType(new Set<String>{Constants.DEFAULT_AND_TERMINATION});
    }
}