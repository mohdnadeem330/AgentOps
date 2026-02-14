@isTest(SeeAllData=false)
public class BatchToAllSRCalloutTest {
    
    @testSetup static void setupData() {

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
       
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
        salesorder.RebateForfeitureLetterSent__c = TRUE;
        insert salesOrder;        
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE;
        update otherCharges;

    }

    @isTest static void mortgageDischarge() {

        Unit__c unit = [select id from Unit__c limit 1];
        SalesOrder__c salesOrder = [select id from SalesOrder__c limit 1];
        
        salesOrder.MortgageApplicable__c = 'Yes';
        update salesOrder;

        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, 'InternalMortgageDischarge');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       
        Id mortgageDischargeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.SyncStatus__c = Constants.STATUS_FAILED;
        insert newSR;

        try {
            //System.schedule('BatchToAllSRCallout-Test', '0 0 * * * ?', new BatchToAllSRCallout() );
            database.executeBatch(new BatchToAllSRCallout());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}