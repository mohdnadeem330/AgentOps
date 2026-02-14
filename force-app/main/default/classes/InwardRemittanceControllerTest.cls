@isTest
public with sharing class InwardRemittanceControllerTest {
    
    @isTest
    public static void testGetInwardRemittances() {
        // Insert sample remittance records
        List<Inward_Remittance__c> remittances = new List<Inward_Remittance__c>();
        for (Integer i = 0; i < 25; i++) {
            remittances.add(new Inward_Remittance__c(
                Virtual_Account_Number__c = 'VAN' + i,
                Real_Account_Number__c = 'RAN' + i,
                Bank__c = 'First Abu Dhabi Bank',
                Transfer_Type__c = 'Type' + i,
                Amount__c = 100 + i,
                Payment_Details_Long__c = 'Payment details ' + i,
                Request_DateTime__c = System.today().addDays(-i),
                Status__c = 'Unprocessed'
            ));
        }
        insert remittances;

        Test.startTest();
        
        // Parameters for the method call
        String virtualAccountNumber = 'VAN1';
        String virtualAccountIBAN = null; // Adjust as needed
        String realAccountNumber = 'RAN1';
        String bank = 'First Abu Dhabi Bank';
        String transferType = 'Type1';
        Decimal amount = 101.0;
        String paymentDetails = 'Payment details 1';
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        String project = null; // Adjust as needed
        String unit = null; // Adjust as needed
        String salesOrder = null; // Adjust as needed
        String status = 'Unprocessed';
        String receiptStatus = 'processed';
        Integer pageSize = 10;
        Integer pageNumber = 1;

        // Call the method
        InwardRemittanceController.PaginationWrapper result = InwardRemittanceController.getInwardRemittances(
            virtualAccountNumber, 
            virtualAccountIBAN, 
            realAccountNumber, 
            bank, 
            transferType, 
            amount, 
            paymentDetails, 
            startDate, 
            endDate, 
            project, 
            unit, 
            salesOrder, 
            status,
            receiptStatus,
            pageSize, 
            pageNumber
        );

        Test.stopTest();

        // Assertions to verify the results
        System.assertNotEquals(result.records.size(), 0, 'There should be records returned');
        System.assertEquals(result.totalRecords > 0, true, 'Total records should be greater than zero');
        System.assertEquals(result.totalPages >= 1, true, 'Total pages should be at least 1');

        Boolean foundMatchingRecord = false;
        for (InwardRemittanceController.RemittanceWrapper record : result.records) {
            if (record.virtualAccountNumber == virtualAccountNumber && record.amount == amount) {
                foundMatchingRecord = true;
                break;
            }
        }
        System.assertEquals(foundMatchingRecord, true, 'There should be a record matching the specified filters');
    }    

    @isTest
    public static void testUpdateRemittanceStatus() {

        Account acc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
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
        //va1.Unit__c = unit.id;
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

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;

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
            Status__c = 'Unprocessed'
        );
        insert remittance;

        Test.startTest();
        
        InwardRemittanceController.updateRemittanceStatus(remittance.Id, 'Processed');
        InwardRemittanceController.getExistingReceipts(remittance.Id);
        InwardRemittanceController.linkReceiptToRemittance(remittance.Id, receiptAcknowledgement.Id);
        Test.stopTest();

        remittance = [SELECT Id, Status__c FROM Inward_Remittance__c WHERE Id = :remittance.Id];
    }
}