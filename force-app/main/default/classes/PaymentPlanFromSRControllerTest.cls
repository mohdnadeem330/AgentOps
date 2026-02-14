@isTest
private class PaymentPlanFromSRControllerTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'PaymentPlanChange']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
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
                
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Completed';
        status.HexaBPM__Code__c = 'Completed';
        insert status;
        
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Request Verified';
        srStatus.Name = 'Request Verified';
        insert srStatus;
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, Name, ProposalPaymentPlan__c, SalesOrder__c, SalesOrder__r.NetAmount__c, SalesOrder__r.Offer__c, SalesOrder__r.PaymentPlan__c, SalesOrder__r.Opportunity__c, Unit__c, Unit__r.Project__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approve the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];

        PaymentPlanFromSRController.getServiceRequestDetails(SR.Id);
        PaymentPlanFromSRController.getInstallmentLines(SR.SalesOrder__c);
        PaymentPlan__c pp = TestObjectsFactory.getPaymentPlan();
        insert pp;
        
        List<Map<String,String>> installmentList = new List<Map<String,String>>();
        
        Map<String,String> il1 = new Map<String,String>();
        il1.put('Number', '1');
		il1.put('Percentage', '50');
		il1.put('Amount', '500');
		il1.put('readonly', 'true');
		il1.put('Date', '2023-02-02');
		installmentList.add(il1);
        
        Map<String,String> il2 = new Map<String,String>();
        il2.put('Number', '2');
		il2.put('Percentage', '50');
		il2.put('Amount', '500');
		il2.put('readonly', 'false');
		il2.put('Date', '2023-02-02');
        installmentList.add(il2);
		
        PaymentPlanFromSRController.createBookingMemo(SR, 'specialNote', '10', '10', installmentList, 'Aggressive Payment Plan', '1000', pp.Id);
        SR = [Select Id, Name, ProposalPaymentPlan__c, SalesOrder__c, Unit__r.BuildingSectionName__c, SalesOrder__r.NetAmount__c, SalesOrder__r.Offer__c, SalesOrder__r.PaymentPlan__c, SalesOrder__r.Opportunity__c, Unit__c, Unit__r.Project__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        MemoLines__c memoline = PaymentPlanFromSRController.getBookingMemoDetails(SR.ProposalPaymentPlan__c);
        PaymentPlanFromSRController.getInstallmentLineChangesDetails(SR.ProposalPaymentPlan__c);
        HexaBPM__Step__c step = PaymentPlanFromSRController.getServiceRequestStep(SR.Id);
        PaymentPlanFromSRController.completeServiceRequestStep(step, SR);
        PaymentPlanFromSRController.getListOfPaymentPlans(SR.Unit__r);

        PaymentPlanFromSRController.updateInstallmentChangesRecords(memoline, installmentList, SR, '1000', pp.Id);

        Test.stopTest();
    }
}