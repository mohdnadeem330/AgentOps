@isTest
private class CC_RTOExtensionSRLogicTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'RTOPaymentExtension']){
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

        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'RTO Extension';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='RTOPaymentExtension';
        insert SR_Template;

        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('RTOPaymentExtension');
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
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Approval by Development Finance';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Approval by Development Finance';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 

        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'Verify the Request';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = SRStep.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1;        
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c, HexaBPM__Summary__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approval by Development Finance' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        ReceiptAcknowledgement__c rec = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Online');
        insert rec;

        CC_RTOExtensionSRLogic cc = new CC_RTOExtensionSRLogic();
        
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
    public static void callMethod2 (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, ForfeitAmount__c, Refund_Amount__c, PaymentExtensionDate__c, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Status__c, ReceiptAcknowledgement__r.OutstandingAmount__c, ReceiptAcknowledgement__r.MaturityDate__c, SalesOrder__c, PaymentExtensionPeriod__c, SummaryReport__c, ExemptValidations__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c, HexaBPM__Summary__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        ReceiptAcknowledgement__c rec = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Online');
        insert rec;

        CC_RTOExtensionSRLogic cc = new CC_RTOExtensionSRLogic();
        
        SR.InstallmentLine__c = installmentLineList[0].Id;
        SR.PaymentExtensionDate__c = Date.today() + 90;
        update SR;
        cc.EvaluateCustomCode(SR, stp);
        
        SR.ReceiptAcknowledgement__c = rec.Id;
        update SR;
        cc.EvaluateCustomCode(SR, stp);

        rec.MaturityDate__c = Date.today();
        update rec;
        
        cc.EvaluateCustomCode(null, null);

        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.Name = 'Generate CCA';
        srStatus.HexaBPM__Code__c = 'Generate CCA';
        insert srStatus;
        
        cc.EvaluateCustomCode(SR, stp);

        Test.stopTest();
    }
}