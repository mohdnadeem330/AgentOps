@isTest
private class CC_ALD_DandTSR_HandlerTest {
    public static String LegalCourtOrderName ='Legal-Court Order';
    public static Id LegalCourtOrderRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', LegalCourtOrderName);

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
        
        HexaBPM__SR_Template__c SR_Template2 = new HexaBPM__SR_Template__c();
        SR_Template2.Name = LegalCourtOrderName;
        SR_Template2.HexaBPM__SR_RecordType_API_Name__c=LegalCourtOrderName;
        insert SR_Template2;
        
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
        
        HexaBPM__SR_Steps__c SRStep2 = new HexaBPM__SR_Steps__c();
        SRStep2.HexaBPM__SR_Template__c = SR_Template2.id;
        SRStep2.HexaBPM__Step_No__c = 1;
        SRStep2.HexaBPM__Step_Template__c = ST.Id;
        SRStep2.HexaBPM__Summary__c = 'Flag Customer';
        SRStep2.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep2;
        
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
        
        HexaBPM__Service_Request__c SR2 = new HexaBPM__Service_Request__c();
        SR2.RecordTypeId = LegalCourtOrderRecordTypeId;
        SR2.HexaBPM__Customer__c = acc.Id;
        //SR.OwnerId = UserInfo.getUserId();
        SR2.HexaBPM__SR_Template__c = SR_Template.Id;
        insert SR2;
        
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'Flag Customer';
        step1.HexaBPM__SR__c = SR2.Id;
        step1.HexaBPM__SR_Step__c = SRStep2.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1; 
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__r.Account__c, SalesOrder__c From HexaBPM__Service_Request__c where RecordTypeId=:LegalCourtOrderRecordTypeId Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR_Step__c, HexaBPM__Summary__c, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c where HexaBPM__SR__r.RecordTypeId=:LegalCourtOrderRecordTypeId limit 1];
        
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'Un-Flag Customer';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = stp.HexaBPM__SR_Step__c;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1;
        
        account acc = [select id from account limit 1];
        Set<Id> accset = new Set<Id>();
        accset.add(acc.Id);
       
        
        CC_ALD_DandTSR_Handler cc = new CC_ALD_DandTSR_Handler();
        
        cc.EvaluateCustomCode(SR, stp);
        cc.EvaluateCustomCode(null, null);
        cc.EvaluateCustomCode(SR, step1);
        CC_ALD_DandTSR_Handler.blockCustomerForDnT(accset);
        Test.stopTest();
    }
    
}