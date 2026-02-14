@isTest
public class IBANValidatorControllerTest {

    @isTest static void testMethodOne() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        /*Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G1234561');
        insert acc1;*/

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
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        /*ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);*/
        
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
       
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        Test.startTest();
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.CANCELLATION_RT, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.CancellationReason__c = 'Mutual Cancellation - Refund';
        newSR.SocialReason__c = 'Not Applicable';
        newSR.AgreementType__c = 'T2 - Cancellation with Refund';
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesorder.Id;
        insert newSR;

        IBANValidatorController.getServiceRequest(newSR.Id);
        IBANValidatorController.updateServiceRequest(newSR.Id, 'AE680230000001000000002');
        Test.StopTest();        
    }    

    @isTest static void testMethodTwo() {
        Test.startTest();
        String ibanResponseBody = '{"Data":{"IBANAccountNumber":"AE680230000001000000002","IBANAccountTitle": "AHM*** MUST*** HAS*** AHL*** "}}';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(ibanResponseBody));
        IBANValidatorController.validateIBANCallout('AE320260001015820559701');

        Test.StopTest();        
    }    
}