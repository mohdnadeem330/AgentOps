@isTest
private class CC_ValidateAndRemoveFlagTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);

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
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{TestObjectsFactory.getSRStatus(Constants.SUBMITTED),TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT)};
        
        //SR AND STEP
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = DandTRecordTypeId;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        //SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c limit 1];
        
        
        CC_ValidateAndRemoveFlag cc = new CC_ValidateAndRemoveFlag();
        
        cc.EvaluateCustomCode(SR, stp);
        cc.EvaluateCustomCode(null, null);

        Test.stopTest();
    }
}