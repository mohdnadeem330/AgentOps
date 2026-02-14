@isTest(SeeAllData=false)
public class CC_SRUnitSwapEquityTransferTest {
    @isTest
    public static void unitTestMethod() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G1234561');
        insert acc1;

        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Name = 'MAYAN-B1-1004';
        unit1.Status__c = 'Sold';
        insert unit1;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.Status__c = Constants.SO_STATUS_SOLD;
        insert salesOrder;

        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        salesOrder1.Contact__c = con.Id;
        salesOrder1.AmountPayable__c = 10000;
        insert salesOrder1;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        // InstallmentLines__c updateInstallment = new InstallmentLines__c();
        // updateInstallment.Id = installmentLines[0].Id;

        // update updateInstallment;

        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder1.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Status__c = Constants.RECEIPT_STATUS_CLEARED;
        insert receiptAcknowledgementRec;

        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);


        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.UNIT_SWAP_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Unit Swap', 'UnitSwap');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
        
        Id unitSwapId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.UNIT_SWAP_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.UNIT_SWAP_SR_TYPE, unitSwapId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.SwappedOrder__c = salesOrder1.Id;
        newSR.UnitFromSameProject__c = Constants.YES;
        insert newSR;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        insert newStep;

        //Child SR
        HexaBPM__SR_Template__c cancellationSRTemplate = TestObjectsFactory.getSRTemplate(Constants.CANCELLATION_RT);
        insert cancellationSRTemplate;

        HexaBPM__Step_Template__c cancellationStepTemplate = TestObjectsFactory.getStepTemplate('Cancellation', 'Cancellation');
        insert cancellationStepTemplate;

        HexaBPM__SR_Steps__c cancellationSRSteps = TestObjectsFactory.getSRStep(cancellationSRTemplate.Id, cancellationStepTemplate.Id);
        insert cancellationSRSteps;
       
        Id cancellationSRRecordtypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.CANCELLATION_RT);

        HexaBPM__Service_Request__c cancellationSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.CANCELLATION_TYPE, cancellationSRRecordtypeId, cancellationSRTemplate.Id);
        cancellationSR.ChargeCollected__c = 2000;
        cancellationSR.EquityAmount__c = 100000;
        cancellationSR.ReallocationAmount__c = 160000;
        cancellationSR.ForfeitAmount__c = 10000;
        cancellationSR.TotalCollectedAmount__c = 200000;
        cancellationSR.SalesOrder__c = salesOrder.Id;
        cancellationSR.HexaBPM__Parent_SR__c = newSR.Id;
        cancellationSR.SubType__c = Constants.UNIT_SWAP_SUB_TYPE;
        insert cancellationSR;

        HexaBPM__Step__c cancellationStep = TestObjectsFactory.getServiceRequestStep(cancellationSR.id, cancellationSRSteps.Id, cancellationStepTemplate.id);   
        insert cancellationStep;
        //Child SR

        try {
            Test.startTest();

            CC_SRCancelSalesOrderController cancelSalesOrder = new CC_SRCancelSalesOrderController();
            cancelSalesOrder.EvaluateCustomCode(cancellationSR, cancellationStep);

            CC_SRUnitSwapEquityTransfer obj = new CC_SRUnitSwapEquityTransfer();
            obj.EvaluateCustomCode(newSR, newStep);

            Test.StopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}