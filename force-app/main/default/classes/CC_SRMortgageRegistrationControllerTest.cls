@isTest(SeeAllData=false)
public class CC_SRMortgageRegistrationControllerTest {
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
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
       
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.HexaBPM__Customer__c = acc.Id;
        insert newSR;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        insert newStep;

        CC_SRMortgageRegistrationController mortageRegistration = new CC_SRMortgageRegistrationController();

        newSR.MortgageBank__c = bankAccount.Id;
        newSR.MortgageAmount__c = 100000;
        newSR.StartDate__c = Date.Today().addDays(-100);
        newSR.MortgageApplicationNumber__c = '12345';
        newSR.HexaBPM__External_SR_Status__c =  approvedByFinance.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  approvedByFinance.Id;
        update newSR;

        mortageRegistration.EvaluateCustomCode(newSR,newStep);

        Test.startTest();
        Test.StopTest();

    }
}