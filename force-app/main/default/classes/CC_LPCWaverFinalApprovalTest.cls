@isTest
private class CC_LPCWaverFinalApprovalTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'LPCWaiver']){
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
        SR_Template.Name = 'LPC Waiver';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='LPCWaiver';
        insert SR_Template;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('LPCWaiver');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;
        SR.TotalLPCAmount__c = 21000;

        SR.WaivedAmount__c = 10000;
        SR.ChargeCollected__c = 10000;

        SR.TotalLPCDue__c = 20000;
        update SR;
        List<ReceiptAcknowledgement__c> rList = new List<ReceiptAcknowledgement__c>();
        ReceiptAcknowledgement__c receiptAcknowledgement1 = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Cheque');
        receiptAcknowledgement1.ServiceRequest__c = SR.Id;
        rList.add(receiptAcknowledgement1);
        ReceiptAcknowledgement__c receiptAcknowledgement2 = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Cheque');
        receiptAcknowledgement2.ServiceRequest__c = SR.Id;
        rList.add(receiptAcknowledgement2);
        insert rList;
        for(ReceiptAcknowledgement__c receiptAcknowledgement:rList) {
            receiptAcknowledgement.Amount__c = 5000;
            receiptAcknowledgement.Status__c = Constants.RECEIPT_STATUS_CLEARED;
            receiptAcknowledgement.BankName__c = 'Abu Dhabi Commercial Bank';
            receiptAcknowledgement.ReceiptNumber__c = receiptAcknowledgement.Id;
        }
        update rList;
        
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

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		CC_LPCWaverFinalApproval cc = new CC_LPCWaverFinalApproval();
        
		cc.EvaluateCustomCode(SR, stp);
		cc.EvaluateCustomCode(null, null);
        
        SR.TotalLPCAmount__c = null;
        update SR;
		cc.EvaluateCustomCode(SR, stp);
        
        SR.TotalLPCAmount__c = 200;
        SR.WaivedAmount__c = 100;
        SR.TotalLPCDue__c = 50;
        update SR;
        
		cc.EvaluateCustomCode(SR, stp);

		SR.IsChargeReceiptCreated__c = true;
        SR.WaivedPercentage__c = 100;
		update SR;
		
        cc.EvaluateCustomCode(SR, stp);

        SR.WaivedPercentage__c = 10;
        SR.LPCFreezeStatus__c = 'Synced';
        update SR;
        
        cc.EvaluateCustomCode(SR, stp);
        
        List<ReceiptAcknowledgement__c> rList = new List<ReceiptAcknowledgement__c>();
        
        
		cc.EvaluateCustomCode(SR, stp);
        for(ReceiptAcknowledgement__c receiptAcknowledgement:[SELECT Id,Amount__c,BankName__c,Status__c,ReceiptNumber__c
                                                              FROM ReceiptAcknowledgement__c WHERE ServiceRequest__c=:SR.Id LIMIT 1]) 
        {
            receiptAcknowledgement.Amount__c = 5000;
            receiptAcknowledgement.Status__c = Constants.RECEIPT_STATUS_CLEARED;
            receiptAcknowledgement.BankName__c = 'Abu Dhabi Commercial Bank';
            receiptAcknowledgement.ReceiptNumber__c = receiptAcknowledgement.Id;
            rList.add(receiptAcknowledgement);
        }
        update rList;
        
        cc.EvaluateCustomCode(SR, stp);

        SR.TotalLPCAmount__c = 20000;
        SR.WaivedAmount__c = 10000;
        SR.TotalLPCDue__c = 10000;
        update SR;
        cc.EvaluateCustomCode(SR, stp);
        for(ReceiptAcknowledgement__c receiptAcknowledgement:[SELECT Id,Amount__c,BankName__c,Status__c,ReceiptNumber__c
                                                              FROM ReceiptAcknowledgement__c WHERE ServiceRequest__c=:SR.Id and Status__c!=:Constants.RECEIPT_STATUS_CLEARED LIMIT 2]) 
        {
            receiptAcknowledgement.Amount__c = 5000;
            receiptAcknowledgement.Status__c = Constants.RECEIPT_STATUS_CLEARED;
            receiptAcknowledgement.BankName__c = 'Abu Dhabi Commercial Bank';
            receiptAcknowledgement.ReceiptNumber__c = receiptAcknowledgement.Id;
            rList.add(receiptAcknowledgement);

        }
        update rList;
        Test.stopTest();
    }
    
    @isTest
    public static void callMethod1 (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		CC_LPCWaverFinalApproval cc = new CC_LPCWaverFinalApproval();
        
        List<ReceiptAcknowledgement__c> rList = new List<ReceiptAcknowledgement__c>();
        
        ReceiptAcknowledgement__c receiptAcknowledgement1 = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Cheque');
        //receiptAcknowledgement1.ServiceRequest__c = SR.Id;
        rList.add(receiptAcknowledgement1);
        
        ReceiptAcknowledgement__c receiptAcknowledgement2 = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Cheque');
        //receiptAcknowledgement2.ServiceRequest__c = SR.Id;
        rList.add(receiptAcknowledgement2);
        //insert rList;
        
        for(ReceiptAcknowledgement__c receiptAcknowledgement:rList) {
            receiptAcknowledgement.Amount__c = 5000;
            receiptAcknowledgement.Status__c = Constants.RECEIPT_STATUS_CLEARED;
            receiptAcknowledgement.BankName__c = 'Abu Dhabi Commercial Bank';
            receiptAcknowledgement.ReceiptNumber__c = receiptAcknowledgement.Id;
        }
        //update rList;
        
        SR.TotalLPCAmount__c = 20000;
        SR.WaivedAmount__c = 10000;
        SR.TotalLPCDue__c = 10000;
        update SR;
        
		cc.EvaluateCustomCode(SR, stp);
        
    }
}