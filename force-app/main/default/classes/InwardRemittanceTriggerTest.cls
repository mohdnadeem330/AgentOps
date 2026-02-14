@isTest
public class InwardRemittanceTriggerTest {
    
    @isTest
    public static void testPreventReceiptAcknowledgementUpdate() {
        Account acc = TestObjectsFactory.getAccountRecord('Organization Account', false, 'JO20220211');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        
        project.BankNameEscrow__c = 'Abu Dhabi Commercial Bank';
        project.AccountNumberEscrow__c = '10503791920050';
        project.IBANNoEscrow__c = 'AE220030010503791920050';
        project.BankNameCorporate__c = 'Abu Dhabi Commercial Bank';
        project.AccountNumberCorporate__c = '10503791920050';
        project.IBANNoCorporate__c = 'AE120354031221018122005';
        update project;
    
        BankVirtualAccounts__c va1 = TestObjectsFactory.getBankVirtualAccounts();
        va1.Project__c = project.id;
        va1.BufferFlag__c = true;
        va1.Virtual_Account_Type__c = 'Escrow';
        va1.Statusflag__c = 'Available';
        va1.EscrowAccountNumber__c = '123123121';
        va1.BankName__c = 'Abu Dhabi Commercial Bank';
        va1.VirtualAccountNumber__c = null;
        va1.VirtualIBANAccountNumber__c = 'IBAN100';
        va1.SendModificationRequest__c = true;
        insert va1;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        ReceiptAcknowledgement__c receipt1 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receipt1;
        
        ReceiptAcknowledgement__c receipt2 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receipt2;
        
        Inward_Remittance__c remittance = new Inward_Remittance__c(
            Request_ID__c = 'REQ100',
            Request_DateTime__c = System.now(),
            Service_Name__c = 'Test Service',
            Service_Code__c = 'S100',
            Customer_Code__c = 'C100',
            Language__c = 'EN',
            Virtual_Account_Number__c = 'VAN100',
            Virtual_Account_IBAN__c = 'IBAN100',
            Real_Account_Number__c = 'RAN100',
            Transfer_Type__c = 'Type100',
            Transaction_Type__c = 'TXN100',
            Amount__c = 500.0,
            Currency__c = 'USD',
            Payment_Details_Long__c = 'Test Payment',
            Transaction_Reference__c = 'TRX100',
            Customer_Reference__c = 'CR100',
            Payment_Status__c = 'Pending',
            Payment_Status_Description__c = 'Processing',
            Sales_Order__c = salesOrder.Id,
            Status__c = 'Unprocessed',
            Receipt_Acknowledgement__c = receipt1.Id
        );
        insert remittance;
        Inward_Remittance__c oldRemittance = [SELECT Id, Receipt_Acknowledgement__c FROM Inward_Remittance__c WHERE Id = :remittance.Id];

        Test.startTest();
        remittance.Receipt_Acknowledgement__c = receipt2.Id;

        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldRemittance.Id => oldRemittance };
        List<SObject> newList = new List<SObject>{ remittance };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ remittance.Id => remittance };
        List<SObject> oldList = new List<SObject>{ oldRemittance };

        InwardRemittanceTriggerHandler handler = new InwardRemittanceTriggerHandler();
        handler.beforeUpdateMethod(newList, newMap, oldList, oldMap);
        try {
            update remittance;
        } catch (DmlException e) {
            System.debug('Expected Exception: ' + e.getMessage());
            System.assert(e.getMessage().contains('Receipt Acknowledgement already created'), 'Expected error message not found');
        }
        Test.stopTest();
    }

    @isTest
    public static void testTriggerHandler() {
        Account acc = TestObjectsFactory.getAccountRecord('Organization Account', false, 'JO20220211');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Project__c = project.Id;
        insert unit;
        
        BankVirtualAccounts__c va = TestObjectsFactory.getBankVirtualAccounts();
        va.Project__c = project.Id;
        va.Virtual_Account_Type__c = 'Escrow';
        va.VirtualIBANAccountNumber__c = 'IBAN54321';
        va.BankName__c = 'Abu Dhabi Commercial Bank';
        insert va;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        Test.startTest();
        
        Inward_Remittance__c remittance = new Inward_Remittance__c(
            Virtual_Account_Number__c = 'VAN456',
            Virtual_Account_IBAN__c = 'IBAN54321',
            Real_Account_Number__c = 'RAN456',
            Bank__c = 'First Abu Dhabi Bank',
            Transfer_Type__c = 'Type2',
            Amount__c = 2000,
            Payment_Details_Long__c = 'Test Payment Details 2',
            Status__c = 'Unprocessed'
        );
        
        InwardRemittanceTriggerHandler handler = new InwardRemittanceTriggerHandler();
        handler.beforeInsertMethod(new List<SObject>{remittance}, new Map<Id, SObject>());
        
        insert remittance;
        
        Test.stopTest();
        
        remittance = [SELECT Id, Virtual_Account__c, Sales_Order__c, Unit__c FROM Inward_Remittance__c WHERE Id = :remittance.Id];
        System.assertEquals(va.Id, remittance.Virtual_Account__c, 'Virtual account should be linked by handler');
    }
    
    @isTest
    public static void testVirtualAccountWithNoSalesOrder() {
        Account acc = TestObjectsFactory.getAccountRecord('Organization Account', false, 'JO20220211');
        insert acc;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        
        BankVirtualAccounts__c va = TestObjectsFactory.getBankVirtualAccounts();
        va.Project__c = project.id;
        va.Virtual_Account_Type__c = 'Escrow';
        va.VirtualIBANAccountNumber__c = 'IBAN98765';
        va.BankName__c = 'Abu Dhabi Commercial Bank';
        insert va;
        
        Test.startTest();
        
        Inward_Remittance__c remittance = new Inward_Remittance__c(
            Virtual_Account__c = va.Id,
            Virtual_Account_Number__c = 'VAN000',
            Virtual_Account_IBAN__c = 'IBAN98765',
            Real_Account_Number__c = 'RAN000',
            Bank__c = 'First Abu Dhabi Bank',
            Transfer_Type__c = 'Type4',
            Amount__c = 4000,
            Payment_Details_Long__c = 'Test Payment Details 4',
            Status__c = 'Unprocessed'
        );
        
        insert remittance;
        
        Test.stopTest();
        
        remittance = [SELECT Id, Virtual_Account__c, Sales_Order__c, Unit__c FROM Inward_Remittance__c WHERE Id = :remittance.Id];
        System.assertEquals(va.Id, remittance.Virtual_Account__c, 'Virtual account should be linked');
        System.assertEquals(null, remittance.Sales_Order__c, 'Sales order should not be linked');
        System.assertEquals(null, remittance.Unit__c, 'Unit should not be linked');
    }
    
}