@isTest
private class CC_RTORenewalTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Id recordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RTORENEWALTYPE);

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
        SR_Template.Name = Constants.RTORENEWALTYPE;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.RTORENEWALTYPE;
        insert SR_Template;
        
        
        // STEP AND STEP TEMPLATE
        list<HexaBPM__Step_Template__c> stepTemplateToInsert = new list<HexaBPM__Step_Template__c>();
        list<String> templatesCode = new list<String>{Constants.STEPNAME_VERIFY_DETAILS,
                                                Constants.STEPNAME_UPLOAD_SIGNED_CONTRACT,
                                                Constants.STEPNAME_TAWTHEEQ_REGISTRATION};
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
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.HO_TRANSSTATUS_INPROGRESS),
                                                TestObjectsFactory.getSRStatus(Constants.CLOSED),
                                                TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
                                                TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT)};
        
        //SR AND STEP
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        //SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
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

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp1 = [Select Id, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c where Step_Template_Code__c= :Constants.STEPNAME_VERIFY_DETAILS limit 1];
        HexaBPM__Step__c stp2 = [Select Id, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c where Step_Template_Code__c= :Constants.STEPNAME_UPLOAD_SIGNED_CONTRACT limit 1];
        HexaBPM__Step__c stp3 = [Select Id, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c where Step_Template_Code__c= :Constants.STEPNAME_TAWTHEEQ_REGISTRATION limit 1];
        
        
        CC_RTORenewal cc = new CC_RTORenewal();
        
        cc.EvaluateCustomCode(SR, stp1);
        cc.EvaluateCustomCode(SR, stp2);
        cc.EvaluateCustomCode(SR, stp3);
        cc.EvaluateCustomCode(new HexaBPM__Service_Request__c(), new HexaBPM__Step__c(HexaBPM__SR__c=SR.Id));
        cc.EvaluateCustomCode(null, null);

        Test.stopTest();
    }
    
}