@isTest
private class CC_VerifyExtensionRequestTest {
  
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
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

		CC_VerifyExtensionRequest cc = new CC_VerifyExtensionRequest();
		cc.EvaluateCustomCode(SR, stp);
        
        SR.InstallmentLine__c = installmentLineList[0].Id;
        update SR;
        cc.EvaluateCustomCode(SR, stp);
        
        SR.PaymentExtensionDate__c = Date.today() + 30;
        SR.SummaryReport__c = 'Text';
        update SR;
        cc.EvaluateCustomCode(SR, stp);
        cc.EvaluateCustomCode(null, null);

        Test.stopTest();
    }
    
    @isTest
    public static void callMethod2 (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Generate CCA';
        status.HexaBPM__Code__c = 'Generate CCA';
        insert status;
        
        stp.HexaBPM__Status__c = status.Id;
        update stp;
        
		CC_VerifyExtensionRequest cc = new CC_VerifyExtensionRequest();
        stp = [Select Id, HexaBPM__SR__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		cc.EvaluateCustomCode(SR, stp);
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        installmentLineList[0].InvoicedAmount__c = 1000;
        update installmentLineList[0];
        
        SR.InstallmentLine__c = installmentLineList[0].Id;
        SR.PaymentExtensionDate__c = Date.today() + 5;
        SR.ForfeitAmount__c = 100;
        SR.Refund_Amount__c = 200;
        update SR;
        
        SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Where Id =: SR.Id];
        
        stp = [Select Id, HexaBPM__SR__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        cc.EvaluateCustomCode(SR, stp);
        

        Test.stopTest();
    }
}