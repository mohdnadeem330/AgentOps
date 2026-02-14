@isTest
private class CC_ALD_ONLY_TO_VALIDATE_SSTest {

//Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'LPCWaiver']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

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
        
        HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS);
        insert objSRStatus1;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'LPC Waiver';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='LPCWaiver';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('LPCWaiver');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Verify the Request';
        ST.HexaBPM__Code__c = 'Verify the Request';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Verify the Request';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Verify the Request';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Approve the Request';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        insert step2;
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c,HexaBPM__Summary__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		CC_ALD_ONLY_TO_VALIDATE_SS cc = new CC_ALD_ONLY_TO_VALIDATE_SS();
        
		cc.EvaluateCustomCode(SR, stp);
        cc.EvaluateCustomCode(null, stp);
    }
}