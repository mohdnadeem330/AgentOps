@isTest
private class CC_VerifyLPCWaverRequestTest {
  
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
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS);
        insert objSRStatus1;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'LPC Waiver';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='LPCWaiver';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('LPCWaiver');
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
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Approve the Request';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        insert step2;

        //Charge Fee Step Setup
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
        chargeFeestep.HexaBPM__SR__c = SR.Id;
        chargeFeestep.HexaBPM__SR_Step__c = SRChargeFeeStep.Id;
        chargeFeestep.HexaBPM__Start_Date__c = System.today();
        insert chargeFeestep;
        
        HexaBPM__Step__c chargeFeeNotPaidstep = new HexaBPM__Step__c();
        chargeFeeNotPaidstep.HexaBPM__Summary__c = 'Customer Not Paid';
        chargeFeeNotPaidstep.HexaBPM__SR__c = SR.Id;
        chargeFeeNotPaidstep.HexaBPM__SR_Step__c = SRChargeFeeStep.Id;
        chargeFeeNotPaidstep.HexaBPM__Start_Date__c = System.today();
        insert chargeFeeNotPaidstep; 

        //Approval by AVP-Default Step Setup
        HexaBPM__Step_Template__c avpDefault_ST = new HexaBPM__Step_Template__c();
        avpDefault_ST.Name = 'Approval by AVP-Default';
        avpDefault_ST.HexaBPM__Code__c = 'Approval by AVP-Default';
        avpDefault_ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert avpDefault_ST;

        HexaBPM__SR_Steps__c SRavpDefaultStep = new HexaBPM__SR_Steps__c();
        SRavpDefaultStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRavpDefaultStep.HexaBPM__Step_No__c = 1;
        SRavpDefaultStep.HexaBPM__Step_Template__c = avpDefault_ST.Id;
        SRavpDefaultStep.HexaBPM__Summary__c = 'Approval by AVP-Default';
        SRavpDefaultStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRavpDefaultStep;
        
        
        HexaBPM__Step__c avpDefaultstep = new HexaBPM__Step__c();
        avpDefaultstep.HexaBPM__Summary__c = 'Approval by AVP-Default';
        avpDefaultstep.HexaBPM__SR__c = SR.Id;
        avpDefaultstep.HexaBPM__SR_Step__c = SRavpDefaultStep.Id;
        avpDefaultstep.HexaBPM__Start_Date__c = System.today();
        insert avpDefaultstep;
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c,HexaBPM__Summary__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		CC_VerifyLPCWaverRequest cc = new CC_VerifyLPCWaverRequest();
        
		cc.EvaluateCustomCode(SR, stp);
		cc.EvaluateCustomCode(null, null);

        SR.TotalLPCAmount__c = 200;
        SR.WaivedAmount__c = 100;
        SR.TotalLPCDue__c = 50;
        update SR;
        
		cc.EvaluateCustomCode(SR, stp);

        SR.TotalLPCAmount__c = null;
        update SR;
		cc.EvaluateCustomCode(SR, stp);
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
		SR.TotalLPCAmount__c = 1000;
        SR.WaivedAmount__c = 100;
		SR.WaivedPercentage__c = 10;
		SR.WaivedBy__c = 'Amount';
		SR.TotalLPCDue__c = 1000;
        SR.LPCFreezeStatus__c = 'Synced';
        update SR;

        HexaBPM__Step__c stp2 = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approve the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
		cc.EvaluateCustomCode(SR, stp2);

        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus('Rejected');
        insert objSRStatus;
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Rejected';
        status.HexaBPM__Code__c = 'Rejected';
        insert status;
        
        stp2.HexaBPM__Status__c = status.Id;
        update stp2;
        
        HexaBPM__Step__c stp3 = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c, HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approve the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        cc.EvaluateCustomCode(SR, stp3);
        
        Test.stopTest();
    }
    @isTest
    public static void callChargeFeeMethodWithChargeFeeRequired (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c,LPCFreezeStatus__c,TotalLPCAmount__c,WaivedAmount__c,TotalLPCDue__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Charge Fees' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Customer Not Paid';
        status.HexaBPM__Code__c = 'Customer Not Paid';
        insert status;

        stp.HexaBPM__Status__c = status.Id;
        update stp;

        HexaBPM__Step__c afterstp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c,HexaBPM__Summary__c From HexaBPM__Step__c WHERE Id =:stp.Id limit 1];

        

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        

        SR.LPCFreezeStatus__c = 'Synced';
        SR.TotalLPCAmount__c = 1000;
        SR.WaivedAmount__c = 100;
		SR.WaivedPercentage__c = 10;
		SR.WaivedBy__c = 'Amount';
		SR.TotalLPCDue__c = 1000;
        update SR;

        HexaBPM__Service_Request__c afterUpdateSR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c,LPCFreezeStatus__c,TotalLPCAmount__c,WaivedAmount__c,TotalLPCDue__c,No_Charge_Fee_Required__c From HexaBPM__Service_Request__c WHERE Id =:SR.Id Limit 1];
                

        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.LPC_WAIVER_TYPE, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 500;
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

        system.debug('###stp###'+JSON.serializePretty(afterstp));
        system.debug('###afterUpdateSR###'+JSON.serializePretty(afterUpdateSR));

        CC_VerifyLPCWaverRequest cc = new CC_VerifyLPCWaverRequest();
        cc.EvaluateCustomCode(afterUpdateSR, afterstp);
        
        //cc.EvaluateCustomCode(null, null);

        /*HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.Name = 'Approved';
        srStatus.HexaBPM__Code__c = 'Approved';
        insert srStatus;
        
        cc.EvaluateCustomCode(SR, stp);*/

        Test.stopTest();
    }
    @isTest
    public static void callMethodWithChargeFeeStepWithNoPayment (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c,LPCFreezeStatus__c,TotalLPCAmount__c,WaivedAmount__c,TotalLPCDue__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Charge Fees' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Customer Not Paid';
        status.HexaBPM__Code__c = 'Customer Not Paid';
        insert status;

        stp.HexaBPM__Status__c = status.Id;
        update stp;

        HexaBPM__Step__c afterstp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c,HexaBPM__Summary__c From HexaBPM__Step__c WHERE Id =:stp.Id limit 1];        

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);       

        SR.LPCFreezeStatus__c = 'Synced';
        SR.TotalLPCAmount__c = 1000;
        SR.WaivedAmount__c = 100;
		SR.WaivedPercentage__c = 10;
		SR.WaivedBy__c = 'Amount';
		SR.TotalLPCDue__c = 1000;
        update SR;

        HexaBPM__Service_Request__c afterUpdateSR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c,LPCFreezeStatus__c,TotalLPCAmount__c,WaivedAmount__c,TotalLPCDue__c,No_Charge_Fee_Required__c From HexaBPM__Service_Request__c WHERE Id =:SR.Id Limit 1];
                

        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.LPC_WAIVER_TYPE, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 500;
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

        system.debug('###stp###'+JSON.serializePretty(afterstp));
        system.debug('###afterUpdateSR###'+JSON.serializePretty(afterUpdateSR));

        CC_VerifyLPCWaverRequest cc = new CC_VerifyLPCWaverRequest();
        cc.EvaluateCustomCode(afterUpdateSR, afterstp);

        Test.stopTest();
    }

    @isTest
    public static void callMethodWithChargeFeeStepWithPayment (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c,LPCFreezeStatus__c,TotalLPCAmount__c,WaivedAmount__c,TotalLPCDue__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Charge Fees' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Completed';
        status.HexaBPM__Code__c = 'Completed';
        insert status;

        stp.HexaBPM__Status__c = status.Id;
        update stp;

        HexaBPM__Step__c afterstp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c,HexaBPM__Summary__c From HexaBPM__Step__c WHERE Id =:stp.Id limit 1];        

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);       

        SR.LPCFreezeStatus__c = 'Synced';
        SR.TotalLPCAmount__c = 1000;
        SR.WaivedAmount__c = 100;
		SR.WaivedPercentage__c = 10;
		SR.WaivedBy__c = 'Amount';
		SR.TotalLPCDue__c = 1000;
        update SR;

        HexaBPM__Service_Request__c afterUpdateSR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c,LPCFreezeStatus__c,TotalLPCAmount__c,WaivedAmount__c,TotalLPCDue__c,No_Charge_Fee_Required__c From HexaBPM__Service_Request__c WHERE Id =:SR.Id Limit 1];
                

        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.LPC_WAIVER_TYPE, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 500;
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

        system.debug('###stp###'+JSON.serializePretty(afterstp));
        system.debug('###afterUpdateSR###'+JSON.serializePretty(afterUpdateSR));

        CC_VerifyLPCWaverRequest cc = new CC_VerifyLPCWaverRequest();
        cc.EvaluateCustomCode(afterUpdateSR, afterstp);

        Test.stopTest();
    }

    @isTest
    public static void callMethodWithNonChargeFeeStep (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c,LPCFreezeStatus__c,TotalLPCAmount__c,WaivedAmount__c,TotalLPCDue__c,PaymentExtensionPeriod__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c,HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approval by AVP-Default' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);       

        SR.LPCFreezeStatus__c = 'Synced';
        SR.TotalLPCAmount__c = 1000;
        SR.WaivedAmount__c = 100;
		SR.WaivedPercentage__c = 10;
		SR.WaivedBy__c = 'Amount';
		SR.TotalLPCDue__c = 1000;
        SR.PaymentExtensionPeriod__c = 1000;
        update SR;

        HexaBPM__Service_Request__c afterUpdateSR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c,LPCFreezeStatus__c,TotalLPCAmount__c,WaivedAmount__c,TotalLPCDue__c,No_Charge_Fee_Required__c,PaymentExtensionPeriod__c From HexaBPM__Service_Request__c WHERE Id =:SR.Id Limit 1];
                

        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.LPC_WAIVER_TYPE, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 500;
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

        system.debug('###stp###'+JSON.serializePretty(stp));
        system.debug('###afterUpdateSR###'+JSON.serializePretty(afterUpdateSR));

        CC_VerifyLPCWaverRequest cc = new CC_VerifyLPCWaverRequest();
        cc.EvaluateCustomCode(afterUpdateSR, stp);

        Test.stopTest();
    }
}