@isTest
public class CC_AssignOwnerToStepTest {
    @isTest static void setupData() {
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
        insert salesOrder;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        salesOrder1.Contact__c = con.Id;
        salesOrder1.AmountPayable__c = 10000;
        insert salesOrder1;
        
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder1.Id, acc1.Id,'Third Party');
        insert jointOwner;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Property Transfer', 'PropertyTransfer');
        insert objStepTemplate;
        Test.startTest();
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
        
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_TYPE, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesorder.Id;
        
        insert newSR;
        
         HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'CM Validation';
        step.HexaBPM__SR__c = newSR.Id;
        step.HexaBPM__SR_Step__c = objSRSteps.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step;
        
        HexaBPM__Service_Request__c newSR1 = [SELECT Id,OwnerId FROM HexaBPM__Service_Request__c WHERE  Id=: step.HexaBPM__SR__c LIMIT 1];
        HexaBPM__Step__c newStep = [SELECT Id,HexaBPM__SR__c FROM HexaBPM__Step__c LIMIT 1];
        CC_AssignOwnerToStep cAldar = new CC_AssignOwnerToStep();
        cAldar.EvaluateCustomCode(newSR1,newStep);
        Test.stopTest();
    }
    @isTest static void ownerAssignmentTest(){
        
    }
}