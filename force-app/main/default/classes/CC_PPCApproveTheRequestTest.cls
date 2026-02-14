@isTest
private class CC_PPCApproveTheRequestTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Test.startTest();
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND (DeveloperName = 'PaymentExtension' OR DeveloperName = 'PaymentPlanChange')]){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Emailtemplate tempRec =  [select id, DeveloperName from emailtemplate where DeveloperName = 'SOUpdatedPPCSRCustomerEmail' limit 1];

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        acc.Email__c = 'ali.athamneh@pwc.com';
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
        update con;
        
        /*Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonEmail = 'ali.athamneh@pwc.com';
        insert acc;*/
                
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Account__c = acc.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 1000;
        salesOrder.CustomerType__c = 'VIP';
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Payment Plan Change';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='PaymentPlanChange';
        insert SR_Template;
        
        HexaBPM__SR_Template__c SR_Template2 = new HexaBPM__SR_Template__c();
        SR_Template2.Name = 'Cheque Replacement';
        SR_Template2.HexaBPM__SR_RecordType_API_Name__c='ChequeReplacement';
        insert SR_Template2;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentPlanChange');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = con.Id;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.NewNetAmount__c = 20000;
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Approval by D-CM';
        ST.HexaBPM__Code__c = 'Approval by D-CM';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Approval by D-CM';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Approval by D-CM';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step;
        Test.stopTest();

    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, Unit__c, HexaBPM__Customer__c, Unit__r.BuildingSectionName__r.TaxPercentage__c, NewNetAmount__c, HexaBPM__Contact__c From HexaBPM__Service_Request__c Limit 1];
        //HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approve the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c,HexaBPM__Summary__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approval by D-CM' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        SR.No_Charge_Fee_Required__c = true;
		CC_PPCApproveTheRequest cc = new CC_PPCApproveTheRequest();
        System.debug('cccc:'+cc.EvaluateCustomCode(SR, stp));
		System.debug('cccc:'+cc.EvaluateCustomCode(null, null));


        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(SR.SalesOrder__r.Opportunity__c);
        insert bookingMemo ;

        MemoLines__c memoLine = TestObjectsFactory.getMemoLineRecord(bookingMemo.Id, SR.Unit__c);
        insert memoLine ;

        List<InstallmentLineChanges__c> ilcList = TestObjectsFactory.getInstallmentLineChanges(bookingMemo.Id, SR.Unit__c, 2);
        insert ilcList;
		List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        
        
        
        ReceiptAcknowledgement__c receiptAcknowledgement1 = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Credit Card');
        insert receiptAcknowledgement1;
        
       
        ReceiptAllocation__c ra1 = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement1.Id, SR.SalesOrder__c, SR.HexaBPM__Customer__c, installmentLineList[0].Id);
        insert ra1;
        System.debug('cccc:'+cc.EvaluateCustomCode(SR, stp));

        delete ra1;
         
        for(InstallmentLines__c il : installmentLineList){
            ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Credit Card');
            insert receiptAcknowledgement;
            
            ReceiptAllocation__c ra = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, SR.SalesOrder__c, SR.HexaBPM__Customer__c, il.Id);
            insert ra;
        }

        SR.ProposalPaymentPlan__c = bookingMemo.Id;
        //update SR;
       
        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.PAYMENT_PLAN_CHANGE_RT, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 4500;
        chargePercentage.IsActive__c = True;
        chargePercentage.VATChanges__c = 5;
        insert chargePercentage;

		//System.debug('cccc:'+cc.EvaluateCustomCode(SR, stp));
        Test.stopTest();
    }
    
    @isTest
    public static void callMethod2 (){
        

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, Unit__c, HexaBPM__Customer__c, Unit__r.BuildingSectionName__r.TaxPercentage__c, NewNetAmount__c, HexaBPM__Contact__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c,HexaBPM__Summary__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approval by D-CM' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		CC_PPCApproveTheRequest cc = new CC_PPCApproveTheRequest();

        BookingMemo__c bookingMemo = TestObjectsFactory.getBookingMemoRecord(SR.SalesOrder__r.Opportunity__c);
        insert bookingMemo ;

        MemoLines__c memoLine = TestObjectsFactory.getMemoLineRecord(bookingMemo.Id, SR.Unit__c);
        insert memoLine ;

        List<InstallmentLineChanges__c> ilcList = TestObjectsFactory.getInstallmentLineChanges(bookingMemo.Id, SR.Unit__c, 2);
        insert ilcList;
		List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        
        Test.startTest();
        ReceiptAcknowledgement__c receiptAcknowledgement1 = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Credit Card');
        insert receiptAcknowledgement1;

        SR.ProposalPaymentPlan__c = bookingMemo.Id;               
       	SR.ChequeReplacementStatus__c = Constants.CHEQUE_REPLACEMENT_APPLICABLE;
        SR.No_Charge_Fee_Required__c = true;
		update SR;
        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.PAYMENT_PLAN_CHANGE_RT, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 4500;
        chargePercentage.IsActive__c = True;
        chargePercentage.VATChanges__c = 5;
        insert chargePercentage;
		System.debug('cccc:'+cc.EvaluateCustomCode(SR, stp));


        Test.stopTest();
    }
    @isTest
    public static void callChargeFeeMethodWithChargeFeeRequired (){
        Test.startTest();

        HexaBPM__SR_Template__c SR_Template = [SELECT Id FROM HexaBPM__SR_Template__c WHERE Name = 'Payment Plan Change' LIMIT 1];

        HexaBPM__Service_Request__c SR_Setup = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        
        HexaBPM__Step_Template__c charge_ST = new HexaBPM__Step_Template__c();
        charge_ST.Name = 'Charge Fees';
        charge_ST.HexaBPM__Code__c = 'Charge Fees';
        charge_ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert charge_ST;

        HexaBPM__SR_Steps__c SRChargeFeeStep = new HexaBPM__SR_Steps__c();
        SRChargeFeeStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRChargeFeeStep.HexaBPM__Step_No__c = 1;
        SRChargeFeeStep.HexaBPM__Step_Template__c = charge_ST.Id;
        SRChargeFeeStep.HexaBPM__Summary__c = 'Charge Fees';
        SRChargeFeeStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRChargeFeeStep;
        
        
        HexaBPM__Step__c chargeFeestep = new HexaBPM__Step__c();
        chargeFeestep.HexaBPM__Summary__c = 'Charge Fees';
        chargeFeestep.HexaBPM__SR__c = SR_Setup.Id;
        chargeFeestep.HexaBPM__SR_Step__c = SRChargeFeeStep.Id;
        chargeFeestep.HexaBPM__Start_Date__c = System.today();
        insert chargeFeestep;
        
        HexaBPM__Step__c chargeFeeNotPaidstep = new HexaBPM__Step__c();
        chargeFeeNotPaidstep.HexaBPM__Summary__c = 'Customer Not Paid';
        chargeFeeNotPaidstep.HexaBPM__SR__c = SR_Setup.Id;
        chargeFeeNotPaidstep.HexaBPM__SR_Step__c = SRChargeFeeStep.Id;
        chargeFeeNotPaidstep.HexaBPM__Start_Date__c = System.today();
        insert chargeFeeNotPaidstep; 

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Charge Fees' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Customer Not Paid';
        status.HexaBPM__Code__c = 'Customer Not Paid';
        insert status;

        stp.HexaBPM__Status__c = status.Id;
        update stp;

        HexaBPM__Step__c afterstp = [Select Id,HexaBPM__Summary__c, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE Id =:stp.Id limit 1];

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        CC_PPCApproveTheRequest cc = new CC_PPCApproveTheRequest();
        
        SR.InstallmentLine__c = installmentLineList[0].Id;
        SR.PaymentExtensionDate__c = Date.today() + 90;
        update SR;

        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.PAYMENT_PLAN_CHANGE_RT, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 4500;
        chargePercentage.IsActive__c = True;
        chargePercentage.VATChanges__c = 5;
        insert chargePercentage;
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Credit Card');
        receiptAcknowledgement.ServiceRequest__c = SR.Id;
        receiptAcknowledgement.ReferenceNumber__c = '';
        receiptAcknowledgement.PaymentType__c = Constants.CHEQUE;
        receiptAcknowledgement.MaturityDate__c = null;
        receiptAcknowledgement.BankName__c = null;
        receiptAcknowledgement.Receipt_Type__c = 'Charge Fee';
        insert receiptAcknowledgement;

        cc.EvaluateCustomCode(SR, afterstp);
        
        //cc.EvaluateCustomCode(null, null);

        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.Name = 'Approved';
        srStatus.HexaBPM__Code__c = 'Approved';
        insert srStatus;
        
        cc.EvaluateCustomCode(SR, stp);

        Test.stopTest();
    }
}