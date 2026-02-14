@isTest
private class PaymentGatewayEventManagerTrgHandlerTest {
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'InvestorCertificate']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        acc.Email__c = 'ali.athamneh@pwc.com';
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
        update con;
        
              
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

    }
    @isTest
    public static void testInsertScenario (){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c,SalesOrder__r.Opportunity__c From HexaBPM__Service_Request__c Limit 1];
        
        HexaBPM__SR_Template__c SR_Template = [SELECT Id FROM HexaBPM__SR_Template__c WHERE Name = 'Investor Certificate' LIMIT 1];
   
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

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(SR.SalesOrder__c, SR.HexaBPM__Customer__c, SR.SalesOrder__r.Opportunity__c, 'Credit Card');
        receiptAcknowledgement.ServiceRequest__c = SR.Id;
        receiptAcknowledgement.ReferenceNumber__c = '';
        receiptAcknowledgement.PaymentType__c = Constants.CHEQUE;
        receiptAcknowledgement.MaturityDate__c = null;
        receiptAcknowledgement.BankName__c = null;
        receiptAcknowledgement.Receipt_Type__c = 'Charge Fee';
        insert receiptAcknowledgement;

        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Completed';
        status.HexaBPM__Code__c = 'Completed';
        insert status;

        HexaBPM__Status__c pendingstatus = new HexaBPM__Status__c();
        pendingstatus.Name = 'Pending';
        pendingstatus.HexaBPM__Code__c = 'Pending';
        insert pendingstatus;

        HexaBPM__Step__c chargeFeestep = new HexaBPM__Step__c();
        chargeFeestep.HexaBPM__Summary__c = 'Charge Fees';
        chargeFeestep.HexaBPM__SR__c = SR.Id;
        chargeFeestep.HexaBPM__SR_Step__c = SRChargeFeeStep.Id;
        chargeFeestep.HexaBPM__Start_Date__c = System.today();
        insert chargeFeestep;

        chargeFeestep.HexaBPM__Status__c = pendingstatus.Id;
        update chargeFeestep;

        PaymentGatewayEventManager__e pgEvent = new PaymentGatewayEventManager__e();
        pgEvent.Receipt_Acknowledgement_Id__c = receiptAcknowledgement.Id;
        pgEvent.Receipt_Type__c = 'Charge Fee';
        EventBus.publish(new List<PaymentGatewayEventManager__e>{pgEvent});

        Test.stopTest();
    }
}