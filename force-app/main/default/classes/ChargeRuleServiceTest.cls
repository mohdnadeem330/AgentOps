@isTest(SeeAllData=false)
public class ChargeRuleServiceTest {
    @isTest static void setupMethod(){

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
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
        
        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord('Internal Mortgage Registration', 'Fully Paid');       
        chargePercentage.ChargeAmount__c = null;
        chargePercentage.ChargePercentage__c = 5;
        insert chargePercentage;

        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Discharge', 'InternalMortgageDischarge');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;

        HexaBPM__SR_Status__c requestApproved = TestObjectsFactory.getSRStatus('Request Approved');       
        insert requestApproved;       

        Id mortgageDischargeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        newSR.ChargeType__c = 'Fully Paid';
        insert newSR;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);     
        insert newStep;

        ChargeRule__c chargeAmount = TestObjectsFactory.getChargeRuleRecord('Internal Mortgage Registration', 'Fully Paid');       
        insert chargeAmount;

        

        ChargeRule__c cr = TestObjectsFactory.getChargeRuleRecord('Internal Mortgage Registration', 'Fully Paid');       
        insert cr;

        List<HexaBPM__Service_Request__c> srList = new List<HexaBPM__Service_Request__c>();
        srList.add(newSR);

        ChargeRuleService crs = new ChargeRuleService();

        Test.startTest();

        List<ChargeRuleModel> chargeRuleList = ChargeRuleService.getChargeRuleByType(srList);

        Test.StopTest();

    }
}