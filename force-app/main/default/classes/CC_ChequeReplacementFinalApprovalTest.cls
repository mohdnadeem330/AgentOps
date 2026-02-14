@isTest
private class CC_ChequeReplacementFinalApprovalTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND (DeveloperName = 'PaymentExtension' OR DeveloperName = 'PaymentPlanChange')]){
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
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Cheque Replacement';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='Cheque Replacement';
        insert SR_Template;
        
        HexaBPM__SR_Template__c SR_Template1 = new HexaBPM__SR_Template__c();
        SR_Template1.Name = 'Payment Plan Change';
        SR_Template1.HexaBPM__SR_RecordType_API_Name__c='PaymentPlanChange';
        insert SR_Template1;
        
        HexaBPM__SR_Template__c SR_Template2 = new HexaBPM__SR_Template__c();
        SR_Template2.Name = 'Payment Extension';
        SR_Template2.HexaBPM__SR_RecordType_API_Name__c='PaymentExtension';
        insert SR_Template2;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentExtension');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;
        
        salesOrder.NetAmount__c = 1000;
        update salesOrder;
            
        HexaBPM__Service_Request__c SRPPC = new HexaBPM__Service_Request__c();
        SRPPC.RecordTypeId = recordTypeSR.get('PaymentPlanChange');
        SRPPC.HexaBPM__Customer__c = acc.Id;
        SRPPC.HexaBPM__Contact__c = acc.PersonContactId;
        SRPPC.OwnerId = UserInfo.getUserId();
        SRPPC.HexaBPM__SR_Template__c = SR_Template.Id;
        SRPPC.Unit__c = unit.Id;
        SRPPC.SalesOrder__c = salesOrder.Id;
        insert SRPPC;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Prepare the Cheques';
        ST.HexaBPM__Code__c = 'Prepare the Cheques';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Prepare the Cheques';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Prepare the Cheques';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Prepare the Cheques' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		CC_ChequeReplacementFinalApproval cc = new CC_ChequeReplacementFinalApproval();
        
		cc.EvaluateCustomCode(SR, stp);
        stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Prepare the Cheques' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
		
        cc.EvaluateCustomCode(SR, stp);
		cc.EvaluateCustomCode(null, null);

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Credit Card');
        receiptAcknowledgement.ServiceRequest__c = SR.Id;
        insert receiptAcknowledgement;
        
        SR.ReceiptAcknowledgement__c = receiptAcknowledgement.Id;
        update SR;
        cc.EvaluateCustomCode(SR, stp);
        
        HexaBPM__Service_Request__c SRPPC = [Select Id, Recordtype.Name From HexaBPM__Service_Request__c Where Recordtype.Name = 'Payment Plan Change' Limit 1];
        SR.HexaBPM__Parent_SR__c = SRPPC.Id;
        update SR;
        cc.EvaluateCustomCode(SR, stp);
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        SR.InstallmentLine__c = installmentLineList[0].Id;
        
        ReceiptAllocation__c ra = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, SR.SalesOrder__c, SR.HexaBPM__Customer__c, installmentLineList[0].Id);
        insert ra;
        update SR;
        cc.EvaluateCustomCode(SR, stp);

        Test.stopTest();
    }
}