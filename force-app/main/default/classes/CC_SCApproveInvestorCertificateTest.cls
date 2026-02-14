@isTest
private class CC_SCApproveInvestorCertificateTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'InvestorCertificate']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        //Emailtemplate tempRec =  [select id, DeveloperName from emailtemplate where DeveloperName = 'SOUpdatedPPCSRCustomerEmail' limit 1];

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
        SR_Template.Name = 'Investor Certificate';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='InvestorCertificate';
        insert SR_Template;
        
        /*HexaBPM__SR_Template__c SR_Template2 = new HexaBPM__SR_Template__c();
        SR_Template2.Name = 'Cheque Replacement';
        SR_Template2.HexaBPM__SR_RecordType_API_Name__c='ChequeReplacement';
        insert SR_Template2;*/
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('InvestorCertificate');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = con.Id;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.NewNetAmount__c = 20000;
        insert SR;

        /*HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
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
        insert step; */

    }
    
    @isTest
    public static void callChargeFeeMethodWithChargeFeeRequired (){
        Test.startTest();

        HexaBPM__SR_Template__c SR_Template = [SELECT Id FROM HexaBPM__SR_Template__c WHERE Name = 'Investor Certificate' LIMIT 1];

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
        
        HexaBPM__Step__c appIC = new HexaBPM__Step__c();
        appIC.HexaBPM__Summary__c = 'Approve the Investor Certificate';
        appIC.HexaBPM__SR__c = SR_Setup.Id;
        appIC.HexaBPM__SR_Step__c = SRChargeFeeStep.Id;
        appIC.HexaBPM__Start_Date__c = System.today();
        insert appIC;
        
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
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approve the Investor Certificate' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Approved';
        status.HexaBPM__Code__c = 'Approved';
        insert status;

        stp.HexaBPM__Status__c = status.Id;
        update stp;

        HexaBPM__Step__c afterstp = [Select Id,HexaBPM__Summary__c, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Step_Status__c From HexaBPM__Step__c WHERE Id =:stp.Id limit 1];

        system.debug('###stp###'+JSON.serializePretty(afterstp));

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);

        CC_SCApproveInvestorCertificate cc = new CC_SCApproveInvestorCertificate();
        
        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord(Constants.INVESTOR_CERTIFICATE_RT, Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        chargePercentage.ChargeAmount__c = 1000;
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