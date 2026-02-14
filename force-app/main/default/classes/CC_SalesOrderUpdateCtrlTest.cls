@isTest
public class CC_SalesOrderUpdateCtrlTest {
    //Create setupData
    @testSetup static void setupData() {
        Test.startTest();
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'SPARegistrationForOffPlan']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
       Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Account__c = acc.Id;
        salesOrder.Opportunity__c = opp.Id;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);
        List<HexaBPM__SR_Status__c> HexaBPMSRStatusList = new List<HexaBPM__SR_Status__c>();
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        HexaBPMSRStatusList.add(objSRStatus);
        //insert objSRStatus;
        
        
        HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus(Constants.PENDING_STATUS);
        HexaBPMSRStatusList.add(objSRStatus1);
        
        HexaBPM__SR_Status__c objSRStatus2 = TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS);
        HexaBPMSRStatusList.add(objSRStatus2);
        
        HexaBPM__SR_Status__c objSRStatus3 = TestObjectsFactory.getSRStatus(Constants.STEP_APPROVED_STATUS);
        HexaBPMSRStatusList.add(objSRStatus3);
        
        HexaBPM__SR_Status__c objSRStatus4 = TestObjectsFactory.getSRStatus(Constants.STEP_ACCEPTED_STATUS);
        HexaBPMSRStatusList.add(objSRStatus4);
        
        HexaBPM__SR_Status__c objSRStatus5 = TestObjectsFactory.getSRStatus(Constants.STEP_REJECTED_STATUS);
        HexaBPMSRStatusList.add(objSRStatus5);
        
        insert HexaBPMSRStatusList;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'SPA Registration For Off Plan';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='SPARegistrationForOffPlan';
        insert SR_Template;
        
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('SPARegistrationForOffPlan');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.SPACounterSignedDate__c = System.today();
        insert SR;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Verify Details';
        ST.HexaBPM__Code__c = 'Verify Details';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Verify Details';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Verify Details';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        HexaBPM__Step_Template__c ST1 = new HexaBPM__Step_Template__c();
        ST1.Name = 'Submit Registration';
        ST1.HexaBPM__Code__c = 'Submit Registration';
        ST1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST1;
        
        HexaBPM__SR_Steps__c SRStep1 = new HexaBPM__SR_Steps__c();
        SRStep1.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep1.HexaBPM__Step_No__c = 1;
        SRStep1.HexaBPM__Step_Template__c = ST1.Id;
        SRStep1.HexaBPM__Summary__c = 'Submit Registration';
        SRStep1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep1;
        
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'Submit Registration';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = SRStep1.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1; 
        
        HexaBPM__Step_Template__c ST2 = new HexaBPM__Step_Template__c();
        ST2.Name = 'Salesforce - Approval';
        ST2.HexaBPM__Code__c = 'Salesforce - Approval';
        ST2.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST2;
        
        HexaBPM__SR_Steps__c SRStep2 = new HexaBPM__SR_Steps__c();
        SRStep2.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep2.HexaBPM__Step_No__c = 1;
        SRStep2.HexaBPM__Step_Template__c = ST2.Id;
        SRStep2.HexaBPM__Summary__c = 'Salesforce - Approval';
        SRStep2.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep2;
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Salesforce - Approval';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep2.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        insert step2;
        
        HexaBPM__Step_Template__c ST3 = new HexaBPM__Step_Template__c();
        ST3.Name = 'Payment Step';
        ST3.HexaBPM__Code__c = 'Payment Step';
        ST3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST3;
        
        HexaBPM__SR_Steps__c SRStep3 = new HexaBPM__SR_Steps__c();
        SRStep3.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep3.HexaBPM__Step_No__c = 1;
        SRStep3.HexaBPM__Step_Template__c = ST3.Id;
        SRStep3.HexaBPM__Summary__c = 'Payment Step';
        SRStep3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep3;
        
        HexaBPM__Step__c step3 = new HexaBPM__Step__c();
        step3.HexaBPM__Summary__c = 'Payment Step';
        step3.HexaBPM__SR__c = SR.Id;
        step3.HexaBPM__SR_Step__c = SRStep3.Id;
        step3.HexaBPM__Start_Date__c = System.today();
        insert step3;
        
       
        Test.stopTest();
    }
    @isTest static void SalesOrderUpdateCtrlErrorTest(){
        Test.startTest();
        CC_SalesOrderUpdateCtrl sales = new CC_SalesOrderUpdateCtrl();
        sales.EvaluateCustomCode(null,null);
        Test.stopTest();
    }
    @isTest static void SalesOrderUpdateCtrlTest(){
        Test.startTest();
        CC_SalesOrderUpdateCtrl sales = new CC_SalesOrderUpdateCtrl();
        HexaBPM__Service_Request__c sr = [SELECT Id,RegistrationDate__c,PaymentDate__c FROM HexaBPM__Service_Request__c LIMIT 1];
        sr.RegistrationDate__c = system.today();
        sr.PaymentDate__c = system.today();
        update sr;
        HexaBPM__Step__c stp = [SELECT Id,HexaBPM__SR__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c != null AND HexaBPM__Summary__c = 'Payment Step'];
        sales.EvaluateCustomCode(sr,stp);
        Test.stopTest();
    }
     @isTest static void SalesOrderUpdateCtrlErrorTest2(){
        Test.startTest();
        CC_SalesOrderUpdateCtrl sales = new CC_SalesOrderUpdateCtrl();
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        HexaBPM__Step__c stp = [SELECT Id,HexaBPM__SR__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c != null AND HexaBPM__Summary__c = 'Payment Step'];
        sales.EvaluateCustomCode(sr,stp);
        Test.stopTest();
    }
}