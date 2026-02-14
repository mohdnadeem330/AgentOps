@isTest
public class CC_Update_sObjectTest {
    static testMethod void testUpdatesObject() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.ERPID__c = '87292';
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
        salesOrder.Status__c = 'Sold';
        salesOrder.SyncStatus__c = 'Synced';
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('PropertyTransfer');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_RT, 'PropertyTransfer');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_RT, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.HexaBPM__Contact__c = con.Id;
        newSR.BuyerName__c = acc.Id;
        insert newSR;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        // newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;

        Test.startTest();
        try {
            CC_Update_sObject obj = new CC_Update_sObject();

            // Service Request
            HexaBPM__Action__c action = new HexaBPM__Action__c();
            action.HexaBPM__Action_Type__c = 'HexaBPM__Service_Request__c';
            action.HexaBPM__Field_Name__c = 'SRType__c';
            action.HexaBPM__Field_Type__c = 'STRING';
            action.HexaBPM__Value_or_Field__c = 'Value';
            action.HexaBPM__Field_Value__c = 'Property Transfer';
            insert action;
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'IsAppointmentDateStepCompleted__c';
            action.HexaBPM__Field_Type__c = 'BOOLEAN';
            action.HexaBPM__Field_Value__c = 'true';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'ADMDeregistrationDate__c';
            action.HexaBPM__Field_Type__c = 'DATE';
            action.HexaBPM__Field_Value__c = '10/10/2010';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'ChargeCollected__c';
            action.HexaBPM__Field_Type__c = 'DOUBLE';
            action.HexaBPM__Field_Value__c = '3000';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'ChargeCollected__c';
            action.HexaBPM__Field_Type__c = 'DOUBLE';
            action.HexaBPM__Field_Value__c = 'HexaBPM__Step_No__c';
            action.HexaBPM__Value_or_Field__c = 'Step Field';
            obj.UpdatesObject(action, newStep);
            // Service Request

            // Step
            action.HexaBPM__Action_Type__c = 'HexaBPM__Step__c';
            action.HexaBPM__Value_or_Field__c = 'Value';
            action.HexaBPM__Field_Name__c = 'HexaBPM__Summary__c';
            action.HexaBPM__Field_Type__c = 'STRING';
            action.HexaBPM__Field_Value__c = 'Test';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'ExecuteCustomCode__c';
            action.HexaBPM__Field_Type__c = 'BOOLEAN';
            action.HexaBPM__Field_Value__c = 'true';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'HexaBPM__Start_Date__c';
            action.HexaBPM__Field_Type__c = 'DATE';
            action.HexaBPM__Field_Value__c = '10/03/2023';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'HexaBPM__Step_No__c';
            action.HexaBPM__Field_Type__c = 'DOUBLE';
            action.HexaBPM__Field_Value__c = '10';
            obj.UpdatesObject(action, newStep);
            // Step

            // Account
            action.HexaBPM__Action_Type__c = 'Account';
            action.HexaBPM__Value_or_Field__c = 'Value';
            action.HexaBPM__Field_Name__c = 'SyncStatus__c';
            action.HexaBPM__Field_Type__c = 'STRING';
            action.HexaBPM__Field_Value__c = 'Synced';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'TransferThresholdLimitExcluded__c';
            action.HexaBPM__Field_Type__c = 'BOOLEAN';
            action.HexaBPM__Field_Value__c = 'true';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'LastSalesOrderClosureDate__c';
            action.HexaBPM__Field_Type__c = 'DATE';
            action.HexaBPM__Field_Value__c = '10/10/2022';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'RetryCount__c';
            action.HexaBPM__Field_Type__c = 'DOUBLE';
            action.HexaBPM__Field_Value__c = '1';
            obj.UpdatesObject(action, newStep);
            // Account

            // Contact
            action.HexaBPM__Action_Type__c = 'Contact';
            action.HexaBPM__Value_or_Field__c = 'Value';
            action.HexaBPM__Field_Name__c = 'Gender__c';
            action.HexaBPM__Field_Type__c = 'STRING';
            action.HexaBPM__Field_Value__c = 'Male';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'PrimaryContact__c';
            action.HexaBPM__Field_Type__c = 'BOOLEAN';
            action.HexaBPM__Field_Value__c = 'true';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'Birthdate';
            action.HexaBPM__Field_Type__c = 'DATE';
            action.HexaBPM__Field_Value__c = '10/10/2000';
            obj.UpdatesObject(action, newStep);

            action.HexaBPM__Field_Name__c = 'NoofYearswithCompany__c';
            action.HexaBPM__Field_Type__c = 'DOUBLE';
            action.HexaBPM__Field_Value__c = '1';
            obj.UpdatesObject(action, newStep);
            // Contact
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}