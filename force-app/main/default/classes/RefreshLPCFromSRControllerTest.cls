@isTest
private class RefreshLPCFromSRControllerTest {
  
    //Create setupData
    @testSetup static void setupData() {
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
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.NewNetAmount__c = 20000;
        insert SR;
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receiptAcknowledgement.ServiceRequest__c = SR.Id;
        insert receiptAcknowledgement;

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
    public static void callMethod(){
        
		HexaBPM__Service_Request__c SR = [Select Id From HexaBPM__Service_Request__c Limit 1];

        Test.startTest();

        SalesOrder__c salesOrder = [Select Id From SalesOrder__c Limit 1];
        RefreshLPCFromSRController.getOutstandingLPCforSalesOrder(SR.Id);
        
        SR.WaivedBy__c = 'Amount';
        update SR;
        RefreshLPCFromSRController.getOutstandingLPCforSalesOrder(SR.Id);

        SR.WaivedBy__c = 'Percentage';
        SR.IsChargeReceiptCreated__c = true;
        update SR;
        
        RefreshLPCFromSRController.getOutstandingLPCforSalesOrder(SR.Id);
        
        Test.stopTest();
    }

}