@isTest
private class CC_PPCReceiptAdjustmentTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'PaymentPlanChange']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 1000;
        salesOrder.ADMFeeAmount__c = 10;
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Payment Plan Change';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='PaymentPlanChange';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentPlanChange');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Approve the Request';
        ST.HexaBPM__Code__c = 'Approve the Request';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Approve the Request';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Approve the Request';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, Unit__c, Unit__r.Project__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approve the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
		
        CC_PPCReceiptAdjustment cc = new CC_PPCReceiptAdjustment();
        cc.EvaluateCustomCode(SR, stp);

        stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approve the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		cc.EvaluateCustomCode(SR, stp);
		cc.EvaluateCustomCode(null, null);

        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(SR.SalesOrder__r.Opportunity__c);
        insert bookingMemo;

        MemoLines__c memoLine = TestObjectsFactory.getMemoLineRecord(bookingMemo.Id, SR.Unit__c);
        insert memoLine ;

		SR.ProposalPaymentPlan__c = bookingMemo.Id;
        SR.NewNetAmount__c = 1000;
        update SR;
        
        SalesOrderOtherCharges__c salesOrderOtherCharge = TestObjectsFactory.createSalesOrderOtherCharges(SR.SalesOrder__c, SR.HexaBPM__Customer__c);
		
		List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

		cc.EvaluateCustomCode(SR, stp);

        for(InstallmentLines__c il : installmentLineList){
            ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Credit Card');
            insert receiptAcknowledgement;
            
            ReceiptAllocation__c ra = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, SR.SalesOrder__c, SR.HexaBPM__Customer__c, il.Id);
            insert ra;
        }
        
		cc.EvaluateCustomCode(SR, stp);
        
        Project__c pr = new Project__c(Id=SR.Unit__r.Project__c);
        pr.ExcludeFromADM__c = true;
        update pr;
		cc.EvaluateCustomCode(SR, stp);

        Test.stopTest();
    }
}