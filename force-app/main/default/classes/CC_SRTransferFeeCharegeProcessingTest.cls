@isTest(SeeAllData=false)
public class CC_SRTransferFeeCharegeProcessingTest {
    
    @isTest static void setupData() {
        
        List<Account> accList = new List<Account>();
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        accList.add(acc);
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G1234561');
        accList.add(acc1);
        
        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        accList.add(bankAccount);
        
        insert accList;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        List<Unit__c> unitList = new List<Unit__c>();
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today().addDays(7);
        unit.ResaleListed__c = true;
        unit.Listing_Price__c = 5000;
        unitList.add(unit);
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Name = 'MAYAN-B1-1004';
        unit1.Status__c = 'Sold';
        unit1.CompletionDate__c = System.today().addDays(7);
        unit1.ResaleListed__c = true;
        unit1.Listing_Price__c = 5000;
        unitList.add(unit1);
        insert unitList;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.Amount = 1000;
        insert opp;
        
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrderList.add(salesOrder);
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        salesOrder1.Contact__c = con.Id;
        salesOrder1.AmountPayable__c = 10000;
        salesOrderList.add(salesOrder1);
        insert salesOrderList;
        
        HexaBPM__SR_Status__c closed = new HexaBPM__SR_Status__c();
        closed.Name = 'closed';
        closed.HexaBPM__Code__c = 'closed';
        insert closed;
        
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSRSPA.SalesOrder__c = salesOrder.Id;
        newSRSPA.SPACounterSignedDate__c=Date.today();
        insert newSRSPA;
        
        Case ca = TestObjectsFactory.getStandardCase(acc1.Id, con.Id, 'Compliance');    
        ca.Unit__c = unit1.Id;
        ca.SalesOrder__c = salesOrder1.Id;
        ca.Opportunity__c = opp.Id;
        ca.Subject = 'Test Subject';
        ca.Description = 'Test Description';
        ca.Status = 'New';
        ca.Origin = 'Online';
        ca.CaseCategory__c = 'Property Transfer';
        ca.Initial_Condition__c = 'Re Sale';
        insert ca;
        
        opp.SalesOrder__c = salesOrder1.Id;
        opp.SaleType__c = 'Resale';
        update opp;
        
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder1.Id, acc1.Id,'Friend Of');
        insert jointOwner;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        Test.startTest();
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Property Transfer', 'PropertyTransfer');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        List<HexaBPM__SR_Status__c> srStatusList = new List<HexaBPM__SR_Status__c>();
        
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        srStatusList.add(draft);
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        srStatusList.add(submitted);
        
        insert srStatusList;
        
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
       
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_TYPE, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesorder.Id;
        newSR.Case__c = ca.Id;
        newSR.CreatedFromResaleOpportunity__c = true;
        newSR.ResaleOpportunity__c = opp.Id;
        newSR.TransferSellingPrice__c = 120000;
        insert newSR;
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        insert newStep;
        
        List<ChargeRule__c> chargeRuleList = new List<ChargeRule__c>();
        ChargeRule__c chargePercentage1 = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Listing Fees');       
        chargePercentage1.ChargeAmount__c = 1500;
        chargePercentage1.ChargePercentage__c = null;
        chargeRuleList.add(chargePercentage1);
        
        ChargeRule__c chargePercentage2 = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Service Charge - Seller');       
        chargePercentage2.ChargeAmount__c = null;
        chargePercentage2.ChargePercentage__c = 2;
        chargeRuleList.add(chargePercentage2);
        
        ChargeRule__c chargePercentage3 = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Service Charge - Buyer');       
        chargePercentage3.ChargeAmount__c = null;
        chargePercentage3.ChargePercentage__c = 2;
        chargeRuleList.add(chargePercentage3);
        insert chargeRuleList;
        
        CC_SRTransferFeeCharegeProcessing sRTransferFeeCharegeProcessing =  new CC_SRTransferFeeCharegeProcessing();
        
        newSR.Unit__c = unit1.Id;
        newSR.salesOrder__c = salesOrder1.Id;
        update newSR;
        
        sRTransferFeeCharegeProcessing.EvaluateCustomCode(newSR,newStep);
        Test.StopTest();
        
    }
    
}