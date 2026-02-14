@isTest
private class CC_ApproveExtensionRequestTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'PaymentExtension']){
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
        salesOrder.CustomerType__c = 'VIP';
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Payment Extension';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='PaymentExtension';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentExtension');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Approval by Development Finance';
        ST.HexaBPM__Code__c = 'Approval by Development Finance';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;

        //Charge Fee Step Setup
        HexaBPM__Step_Template__c charge_ST = new HexaBPM__Step_Template__c();
        charge_ST.Name = 'Charge Fees';
        charge_ST.HexaBPM__Code__c = 'Charge Fees';
        charge_ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert charge_ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Approval by Development Finance';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;

        HexaBPM__SR_Steps__c SRChargeFeeStep = new HexaBPM__SR_Steps__c();
        SRChargeFeeStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRChargeFeeStep.HexaBPM__Step_No__c = 1;
        SRChargeFeeStep.HexaBPM__Step_Template__c = charge_ST.Id;
        SRChargeFeeStep.HexaBPM__Summary__c = 'Charge Fees';
        SRChargeFeeStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRChargeFeeStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Approval by Development Finance';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        HexaBPM__Step__c chargeFeestep = new HexaBPM__Step__c();
        chargeFeestep.HexaBPM__Summary__c = 'Charge Fees';
        chargeFeestep.HexaBPM__SR__c = SR.Id;
        chargeFeestep.HexaBPM__SR_Step__c = SRChargeFeeStep.Id;
        chargeFeestep.HexaBPM__Start_Date__c = System.today();
        insert chargeFeestep;       
        
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approval by Development Finance' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        CC_ApproveExtensionRequest cc = new CC_ApproveExtensionRequest();
        
        SR.InstallmentLine__c = installmentLineList[0].Id;
        SR.PaymentExtensionDate__c = Date.today() + 90;
        update SR;
        cc.EvaluateCustomCode(SR, stp);
        
        cc.EvaluateCustomCode(null, null);

        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.Name = 'Approved';
        srStatus.HexaBPM__Code__c = 'Approved';
        insert srStatus;
        
        cc.EvaluateCustomCode(SR, stp);

        Test.stopTest();
    }

    @isTest
    public static void callChargeFeeMethodWithChargeFeeRequired (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Charge Fees' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        CC_ApproveExtensionRequest cc = new CC_ApproveExtensionRequest();
        
        SR.InstallmentLine__c = installmentLineList[0].Id;
        SR.PaymentExtensionDate__c = Date.today() + 90;
        update SR;

        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.PAYMENT_EXTENSION_TYPE, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = null;
        chargePercentage.ChargePercentage__c = 0.016;
        chargePercentage.IsActive__c = True;
        chargePercentage.VATChanges__c = 5;
        insert chargePercentage;

        cc.EvaluateCustomCode(SR, stp);
        
        cc.EvaluateCustomCode(null, null);

        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.Name = 'Approved';
        srStatus.HexaBPM__Code__c = 'Approved';
        insert srStatus;
        
        cc.EvaluateCustomCode(SR, stp);

        Test.stopTest();
    }

    @isTest
    public static void callChargeFeeMethodWithChargeFeeNotRequired (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Charge Fees' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        CC_ApproveExtensionRequest cc = new CC_ApproveExtensionRequest();

        HexaBPM__SR_Status__c submittedSrStatus = new HexaBPM__SR_Status__c();
        submittedSrStatus.HexaBPM__Code__c =  'Submitted';
        submittedSrStatus.Name =  'Submitted';
        insert submittedSrStatus ;
        
        SR.InstallmentLine__c = installmentLineList[0].Id;
        SR.PaymentExtensionDate__c = Date.today() + 90;
        SR.No_Charge_Fee_Required__c = True;
        SR.HexaBPM__External_SR_Status__c = submittedSrStatus.Id;
        update SR;

        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.PAYMENT_EXTENSION_TYPE, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = null;
        chargePercentage.ChargePercentage__c = 0.016;
        chargePercentage.IsActive__c = True;
        chargePercentage.VATChanges__c = 5;
        insert chargePercentage;

        cc.EvaluateCustomCode(SR, stp);
        
        cc.EvaluateCustomCode(null, null);

        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.Name = 'Approved';
        srStatus.HexaBPM__Code__c = 'Approved';
        insert srStatus;
        
        cc.EvaluateCustomCode(SR, stp);

        Test.stopTest();
    }
}