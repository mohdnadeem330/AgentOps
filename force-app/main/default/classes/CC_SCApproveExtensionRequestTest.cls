@isTest
private class CC_SCApproveExtensionRequestTest {
  
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
        
    }

    @isTest
    public static void callChargeFeeMethodWithChargeFeeRequired (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE Step_Template_Code__c = 'Charge Fees' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Customer Not Paid';
        status.HexaBPM__Code__c = 'Customer Not Paid';
        insert status;

        stp.HexaBPM__Status__c = status.Id;
        update stp;

        HexaBPM__Step__c afterstp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE Id =:stp.Id limit 1];

        system.debug('###stp###'+JSON.serializePretty(afterstp));

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        CC_SCApproveExtensionRequest cc = new CC_SCApproveExtensionRequest();
        
        SR.InstallmentLine__c = installmentLineList[0].Id;
        SR.PaymentExtensionDate__c = Date.today() + 90;
        update SR;

        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.PAYMENT_EXTENSION_TYPE, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = null;
        chargePercentage.ChargePercentage__c = 0.016;
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