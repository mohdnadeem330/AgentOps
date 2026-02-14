@isTest
private class CC_SPATitleDeedForRTOAndPHPPLogicTest {
  
    @isTest
    static void testCMValidation() { 
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'SPATitleDeedForRTOAndPHPP']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        Id spaRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'SPA & Title Deed for RTO and PHPP');

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'SPA & Title Deed for RTO and PHPP';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='SPATitleDeedForRTOAndPHPP';
        insert SR_Template;
        
        HexaBPM__SR_Template__c SR_Template1 = new HexaBPM__SR_Template__c();
        SR_Template1.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template1.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template1;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;

        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = spaRecordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        //SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.HexaBPM__External_SR_Status__c = objSRStatus.Id;
		SR.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
        SR.HexaBPM__Submitted_DateTime__c = Datetime.now();
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'CM Validation';
        ST.HexaBPM__Code__c = 'CM Validation';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'CM Validation';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'CM Validation';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 

        HexaBPM__Step__c stepError = [Select Id From HexaBPM__Step__c where Id=: step.Id];
        
        CC_SPATitleDeedForRTOAndPHPPLogic cc = new CC_SPATitleDeedForRTOAndPHPPLogic();
        cc.EvaluateCustomCode(null, null);
        cc.EvaluateCustomCode(SR, stepError);
        cc.EvaluateCustomCode(SR, step);
        
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
        HexaBPM__Service_Request__c SR1 = new HexaBPM__Service_Request__c();
        SR1.RecordTypeId = handoverRecordType;
        SR1.HexaBPM__Customer__c = acc.Id;
        SR1.HexaBPM__Contact__c = acc.PersonContactId;
        //SR.OwnerId = UserInfo.getUserId();
        SR1.HexaBPM__SR_Template__c = SR_Template1.Id;
        SR1.Unit__c = unit.Id;
        SR1.SalesOrder__c = salesOrder.Id;
        SR1.HandoverDetail__c = hodetail.Id;
        insert SR1;

        cc.EvaluateCustomCode(SR,step);
    }
}