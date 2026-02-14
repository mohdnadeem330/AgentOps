@isTest
private class CC_ChequeReplacementVerifyTheRequestTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'PaymentExtension']){
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
        
        ReceiptAcknowledgement__c newReceiptAcknowledgement = new ReceiptAcknowledgement__c();
        newReceiptAcknowledgement.PaymentType__c = Constants.CHEQUE;
        newReceiptAcknowledgement.Amount__c = 100000;
        newReceiptAcknowledgement.SalesOrder__c = salesOrder.Id;
        newReceiptAcknowledgement.Opportunity__c = opp.Id;
        newReceiptAcknowledgement.Account__c = acc.Id;
        newReceiptAcknowledgement.Remarks__c = 'Test Remark';
        newReceiptAcknowledgement.CustomerBankAccount__c = '1234567890';
        newReceiptAcknowledgement.ReferenceNumber__c = '1234567890';
        newReceiptAcknowledgement.MortgageCheque__c = true;
        newReceiptAcknowledgement.MaturityDate__c = Date.today();
        insert newReceiptAcknowledgement;
        
       // receiptAcknowledgement.ReferenceNumber__c = '';
       // receiptAcknowledgement.PaymentType__c = ;
       // receiptAcknowledgement.MaturityDate__c = null;
       // receiptAcknowledgement.BankName__c = null;
       // receiptAcknowledgement.Receipt_Type__c = 'Charge Fee';
       // insert receiptAcknowledgement;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Payment Extension';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='PaymentExtension';
        insert SR_Template;
        
        HexaBPM__SR_Template__c SR_Template1 = new HexaBPM__SR_Template__c();
        SR_Template1.Name = 'Cheque Replacement';
        SR_Template1.HexaBPM__SR_RecordType_API_Name__c='Cheque Replacement';
        insert SR_Template1;
        
       /* HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentExtension');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.No_Charge_Fee_Required__c =false;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.ReceiptAcknowledgement__c = newReceiptAcknowledgement.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;*/
         HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentExtension');
        SR.SRType__c ='Cheque Replacement';
        SR.HexaBPM__Customer__c = acc.Id;
        SR.No_Charge_Fee_Required__c =false;
        SR.HexaBPM__Contact__c = acc.PersonContactId; 
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.ReceiptAcknowledgement__c = newReceiptAcknowledgement.Id; 
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

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,No_Charge_Fee_Required__c,HexaBPM__Customer__c,Credit_Note_Sub_Type__c,HexaBPM__Contact__c,SRType__c,SalesOrder__r.Opportunity__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        
        
        
        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.CHEQUE_REPLACEMENT_SR_TYPE, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 1000;
        chargePercentage.IsActive__c = True;
        chargePercentage.VATChanges__c = 5;
        insert chargePercentage;

		CC_ChequeReplacementVerifyTheRequest cc = new CC_ChequeReplacementVerifyTheRequest();
		cc.EvaluateCustomCode(SR, stp);
        
		stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
		cc.EvaluateCustomCode(SR, stp);
        CC_ChequeReplacementVerifyTheRequest.prepareReceiptAck(SR);
		cc.EvaluateCustomCode(null, null);


        Test.stopTest();
    }
}