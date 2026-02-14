@isTest
private class CC_PPCInitiateChequeReplacementTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND (DeveloperName = 'PaymentPlanChange' OR DeveloperName = 'PaymentExtension')]){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Submitted';
        srStatus.Name = 'Submitted';
        insert srStatus;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 1000;
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Payment Plan Change';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='PaymentPlanChange';
        insert SR_Template;
        
        HexaBPM__SR_Template__c SR_Template1 = new HexaBPM__SR_Template__c();
        SR_Template1.Name = 'Cheque Replacement';
        SR_Template1.HexaBPM__SR_RecordType_API_Name__c='Cheque Replacement';
        insert SR_Template1;
        
        HexaBPM__SR_Template__c SR_Template2 = new HexaBPM__SR_Template__c();
        SR_Template2.Name = 'Payment Extension';
        SR_Template2.HexaBPM__SR_RecordType_API_Name__c='PaymentExtension';
        insert SR_Template2;
        
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
        ST.Name = 'Initiate Cheque Replacement';
        ST.HexaBPM__Code__c = 'Initiate Cheque Replacement';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Initiate Cheque Replacement';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Initiate Cheque Replacement';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Cheques Received';
        status.HexaBPM__Code__c = 'Cheques Received';
        insert status;
        
        step.HexaBPM__Status__c = status.Id;
        update step;
        
        HexaBPM__SR_Status__c srStatus1 = new HexaBPM__SR_Status__c();
        srStatus1.HexaBPM__Code__c = 'Draft';
        srStatus1.Name = 'Draft';
        insert srStatus1;
        
        HexaBPM__Service_Request__c SR2 = new HexaBPM__Service_Request__c();
        SR2.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PAYMENT_EXTENSION_RT);
        SR2.HexaBPM__Parent_SR__c = SR.Id;
        SR2.HexaBPM__External_SR_Status__c = srStatus1.Id;
		SR2.HexaBPM__Internal_SR_Status__c = srStatus1.Id;
        SR2.HexaBPM__Submitted_DateTime__c = Datetime.now();
        SR2.HexaBPM__SR_Template__c = SR_Template.Id;
        insert SR2;
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, Unit__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Initiate Cheque Replacement' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
           
		CC_PPCInitiateChequeReplacement cc = new CC_PPCInitiateChequeReplacement();
		System.debug('11'+cc.EvaluateCustomCode(SR, stp));
		System.debug('22'+cc.EvaluateCustomCode(null, null));

        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(SR.SalesOrder__r.Opportunity__c);
        insert bookingMemo ;

        MemoLines__c memoLine = TestObjectsFactory.getMemoLineRecord(bookingMemo.Id, SR.Unit__c);
        insert memoLine ;

		SR.ProposalPaymentPlan__c = bookingMemo.Id;
        SR.ChequeReplacementStatus__c = null;
        update SR;
        
        System.debug('333'+stp);
        System.debug('33'+cc.EvaluateCustomCode(SR, stp));
        
        HexaBPM__SR_Status__c srStatus2 = new HexaBPM__SR_Status__c();
        srStatus2.HexaBPM__Code__c = 'Closed';
        srStatus2.Name = 'Closed';
        insert srStatus2;
        
		HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Cheque Replacement';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='Cheque Replacement';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR2 = [Select Id From HexaBPM__Service_Request__c Where Id != : SR.Id];
        
        HexaBPM__Service_Request__c SR3 = new HexaBPM__Service_Request__c();
        SR3.HexaBPM__Parent_SR__c = SR.Id;
        SR3.HexaBPM__External_SR_Status__c = srStatus2.Id;
		SR3.HexaBPM__Internal_SR_Status__c = srStatus2.Id;
        SR3.HexaBPM__Submitted_DateTime__c = Datetime.now();
        SR3.HexaBPM__SR_Template__c = SR_Template.Id;
        insert SR3;
        
        SR3.HexaBPM__External_SR_Status__c = srStatus2.Id;
		SR3.HexaBPM__Internal_SR_Status__c = srStatus2.Id;
        update SR3;
        
        /*HexaBPM__Service_Request__c SR4 = new HexaBPM__Service_Request__c();
        SR4.HexaBPM__Parent_SR__c = SR.Id;
        SR4.HexaBPM__External_SR_Status__c = srStatus2.Id;
		SR4.HexaBPM__Internal_SR_Status__c = srStatus2.Id;
        SR4.HexaBPM__Submitted_DateTime__c = Datetime.now();
        SR4.HexaBPM__SR_Template__c = SR_Template.Id;
        insert SR4;
        
        SR4.HexaBPM__External_SR_Status__c = srStatus2.Id;
		SR4.HexaBPM__Internal_SR_Status__c = srStatus2.Id;
        update SR4;*/
        
		System.debug('44'+cc.EvaluateCustomCode(SR, stp));

        SR.ChequeReplacementStatus__c = Constants.CHEQUE_REPLACEMENT_APPLICABLE;
        update SR;
        System.debug('55'+cc.EvaluateCustomCode(SR, stp));
        

        Test.stopTest();
    }
}