/*
*Created By     : Hardik Vitthani
*Description    : Test class for CC_SRCancelSalesOrderController
*/
@isTest
public class CC_SRCancelSalesOrderControllerTest {
    @isTest
    public static void testSRCancelSalesOrderController() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        acc.PersonEmail='test@aldar.com';
        insert acc;

        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'hardikkuamr.vitthani.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        //insert bankAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        InstallmentLines__c line = installmentLines[0];
        line.InvoiceNumber__c = '12123';
        update line;

        //ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
       // insert receiptAcknowledgement;

        //ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        //insert receiptAllocation;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.CANCELLATION_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Cancellation', 'Cancellation');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        insert draft;
        
         //HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        //insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
        
         HexaBPM__Status__c status1 = new HexaBPM__Status__c();
            status1.Name ='Pending';
            status1.HexaBPM__Code__c ='Pending';
        	status1.OwnerId = UserInfo.getUserId();
        	//status1.QueueId__c =UserInfo.getUserId();
            //status1.HexaBPM__DEV_Id__c ='567890';
            //insert status1;
       
        Id srRecordtypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.CANCELLATION_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.CANCELLATION_TYPE, srRecordtypeId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.EquityAmount__c = 100000;
        newSR.ReallocationAmount__c = 10000;
        newSR.Refund_Amount__c = 2000;
       // newSR.HexaBPM__Customer__c =acc.Id;
        newSR.ChargeCollected__c =10000;
        newSR.ForfeitAmount__c = 10000;
        newSR.Provision_Fund__c =10000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BankAccountNumber__c = '123456789';
		newSR.BranchName__c='Branch';
		newSR.BankName__c ='Bank Name';
		newSR.IBANNumber__c='IBAN123456734567892';
		newSR.SwiftCode__c='NOC Test';
        newSR.CancellationReason__c ='Mutual Cancellation - Refund';
        newSR.SocialReason__c ='Death & Incurable Disease';
        newSR.AgreementType__c ='T1 - Cancellation without Refund';
        insert newSR;
        
        

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);
        //newStep.Name ='pending';
        newStep.QueueId__c = UserInfo.getUserId();
        //insert newStep;
        
        //HexaBPM__Step__c newStep1 = TestObjectsFactory.getServiceRequestStep(newSR1.id, objSRSteps.Id, objStepTemplate.id);   
        //insert newStep1;

        try {
            Test.startTest();
            CC_SRCancelSalesOrderController cancelSalesOrder = new CC_SRCancelSalesOrderController();
            cancelSalesOrder.EvaluateCustomCode(newSR, newStep);
            //cancelSalesOrder.EvaluateCustomCode(newSR1, newStep1);
            Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testSRCancelSalesOrderController1() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'hardikkuamr.vitthani.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        //insert bankAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        InstallmentLines__c line = installmentLines[0];
        line.InvoiceNumber__c = '12123';
        update line;

        //ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        //insert receiptAcknowledgement;

        //ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        //insert receiptAllocation;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.CANCELLATION_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Cancellation', 'Cancellation');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
        
         HexaBPM__Status__c status1 = new HexaBPM__Status__c();
            status1.Name ='Pending';
            status1.HexaBPM__Code__c ='Pending';
           // status1.HexaBPM__DEV_Id__c ='567890';
            //insert status1;
       
        Id srRecordtypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.CANCELLATION_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.CANCELLATION_TYPE, srRecordtypeId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.EquityAmount__c = 100000;
        newSR.ReallocationAmount__c = 10000;
        newSR.Refund_Amount__c = 2000;
        newSR.ChargeCollected__c =10000;
        newSR.ForfeitAmount__c = 10000;
        //newSR.RefundAmount__c =1000;
        newSR.Provision_Fund__c =10000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BankAccountNumber__c = '123456789';
		newSR.BranchName__c='Branch';
		newSR.BankName__c ='Bank Name';
		newSR.IBANNumber__c='IBAN123456734567892';
		newSR.SwiftCode__c='NOC Test';
        newSR.CancellationReason__c ='Mutual Cancellation - Refund';
        newSR.SocialReason__c ='Death & Incurable Disease';
        newSR.AgreementType__c ='T1 - Cancellation without Refund';
        newSR.SubType__c = 'Sales Cancellation';
        insert newSR;
        
        

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        insert newStep;
        
        //HexaBPM__Step__c newStep1 = TestObjectsFactory.getServiceRequestStep(newSR1.id, objSRSteps.Id, objStepTemplate.id);   
        //insert newStep1;

        try {
            Test.startTest();
            CC_SRCancelSalesOrderController cancelSalesOrder = new CC_SRCancelSalesOrderController();
            cancelSalesOrder.EvaluateCustomCode(newSR, newStep);
            //cancelSalesOrder.EvaluateCustomCode(newSR1, newStep1);
            Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}