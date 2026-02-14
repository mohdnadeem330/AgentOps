@isTest(SeeAllData=false)
public class CC_SRCreateMortgageRegistrationTest {
    @isTest static void setupMethod() {

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25085');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004';
        unit.ShortNumber__c = '1004';
        insert unit;
        
        /*Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Status__c = 'Sold';
        insert unit1;*/

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        insert salesOrder;
        
        /*SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        salesOrder1.Contact__c = con.Id;
        insert salesOrder1;*/
        
        ChargeRule__c fullyPaid = TestObjectsFactory.getChargeRuleRecord('Internal Mortgage Registration', 'Fully Paid');     
        insert fullyPaid;
        
        ChargeRule__c notFullyPaid = TestObjectsFactory.getChargeRuleRecord('Internal Mortgage Registration', 'Not Fully Paid');     
        insert notFullyPaid;


        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_TYPE, Constants.PROPERTY_TRANSFER_DEV_RT);
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Closed');       
        insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
       
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        insert newStep;

        CC_SRCreateMortgageRegistration mortageRegistration = new CC_SRCreateMortgageRegistration();

        Test.startTest();

        mortageRegistration.EvaluateCustomCode(newSR,newStep);
        
        Test.StopTest();

    }
}