/*
*Created By     : Hardik Vitthani
*Description    : Test class for UnitSelectionEmailController
*/
@isTest
public class UnitSelectionEmailControllerTest {
    @isTest
    public static void testUnitSelectionEmailController() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'hardikkuamr.vitthani.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 100000;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;

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
       
        Id srRecordtypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.CANCELLATION_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.CANCELLATION_TYPE, srRecordtypeId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;
        
        SRUnitSelected__c srUnitSelected = TestObjectsFactory.getSRUnitSelected(unit.Name, newSR.Id, salesOrder.Id, unit.Id);
        srUnitSelected.RetainedCancelled__c = Constants.RETAINED_UNIT;
        insert srUnitSelected;

        SRUnitSelected__c srUnitSelected2 = TestObjectsFactory.getSRUnitSelected(unit.Name, newSR.Id, salesOrder.Id, unit.Id);
        srUnitSelected2.RetainedCancelled__c = Constants.CANCELLED_UNIT;
        insert srUnitSelected2;

        try {
            Test.startTest();

            UnitSelectionEmailController unitSelectionEmailObj = new UnitSelectionEmailController();
            unitSelectionEmailObj.srId = newSR.Id;
            List<SRUnitSelected__c> srUnitSelectedList = unitSelectionEmailObj.reqList;
            List<UnitSelectionEmailModel> reqCancelledList = unitSelectionEmailObj.reqCancelledList;
            List<UnitSelectionEmailModel> reqRetainedList = unitSelectionEmailObj.reqRetainedList;
            Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}