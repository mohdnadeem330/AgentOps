@isTest(SeeAllData=false)
public class CC_SRMortgageDischargeControllerTest {
    @isTest static void setupMethod() {

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'hardikkuamr.vitthani.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        con.mobilephone = '971505396522';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.Contact__c = con.Id;
        insert salesOrder;

        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Discharge', 'InternalMortgageDischarge');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c requestApproved = TestObjectsFactory.getSRStatus('Request Approved');       
        insert requestApproved;

        HexaBPM__SR_Status__c documentsArchived = TestObjectsFactory.getSRStatus('Documents Archived'); 
        insert documentsArchived;

        Id mortgageDischargeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);     
        insert newStep;

        CC_SRMortgageDischargeController mortageDischarge = new CC_SRMortgageDischargeController();

        newSR.HexaBPM__External_SR_Status__c =  requestApproved.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  requestApproved.Id;
        newSR.MortgageBank__c = bankAccount.Id;
        newSR.HexaBPM__Contact__c = con.Id;
        update newSR;

        mortageDischarge.EvaluateCustomCode(newSR,newStep);

        Test.startTest();
        
        salesOrder.MortgageApplicable__c = 'Yes';
        update salesOrder;

        newSR.HexaBPM__External_SR_Status__c =  documentsArchived.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  documentsArchived.Id;
        update newSR;

        mortageDischarge.EvaluateCustomCode(newSR,newStep);

        Test.StopTest();

    }
}