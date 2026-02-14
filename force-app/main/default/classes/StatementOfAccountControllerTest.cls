@isTest(SeeAllData=false)
public class StatementOfAccountControllerTest {
    
    @isTest static void setupMethod() {

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc1;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
         HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
        objStatus.Name = Constants.STEP_STATUS_CUSTOMER_SETTELED;
        objStatus.HexaBPM__Type__c = 'End';
        objStatus.HexaBPM__Code__c = Constants.STEP_STATUS_CUSTOMER_SETTELED;
        insert objStatus;
        
         HexaBPM__Status__c objStatus1 = new HexaBPM__Status__c();
        objStatus1.Name = Constants.STEP_STATUS_TRANSFER_LEGAL;
        objStatus1.HexaBPM__Type__c = 'End';
        objStatus1.HexaBPM__Code__c = Constants.STEP_STATUS_TRANSFER_LEGAL;
        insert objStatus1;
        
          HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;

        HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus(Constants.PENDING_STATUS);
        insert objSRStatus1;

        HexaBPM__SR_Status__c objSRStatus2 = TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS);
        insert objSRStatus2;
        
         HexaBPM__SR_Status__c objSRStatus3 = TestObjectsFactory.getSRStatus(Constants.SR_STATUS_CLOSED);
        insert objSRStatus3;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        installmentLines[0].InvoiceNumber__c = '638221';
        installmentLines[0].InstallmentDate__c = Date.Today().addDays(-10);
        update installmentLines[0];
        
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(acc1.Id,20,'Friend Of');
        jointOwner.SalesOrder__c = salesOrder.Id;
        insert jointOwner;
		  Test.StartTest();
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
        
        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receipt.Status__c = Constants.RECEIPT_STATUS_CLEARED;
        receipt.ClearedDate__c = Date.Today();
        receiptList.add(receipt);
        
        ReceiptAcknowledgement__c receipt2 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receipt2.ReceiptNumber__c = '123123';
        receiptList.add(receipt2);
        
        ReceiptAcknowledgement__c receipt3 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receipt3.PaymentType__c = 'Credit Note';
        receipt3.PaymentSubType__c = 'Rebate';
        receipt2.ReceiptNumber__c = '123124';
        receiptList.add(receipt3);
        
        ReceiptAcknowledgement__c receipt4 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receipt4.ReceiptNumber__c = '123123';
        receipt4.Status__c = Constants.RECEIPT_STATUS_CLEARED;
        receiptList.add(receipt4);
             
        insert receiptList;

        List<ReceiptAllocation__c> allocationList = new List<ReceiptAllocation__c>();

        allocationList.add(TestObjectsFactory.getReceiptAllocationRecord(receipt.Id, salesOrder.Id, acc.Id, installmentLines[0].Id));
        allocationList.add(TestObjectsFactory.getReceiptAllocationRecord(receipt2.Id, salesOrder.Id, acc.Id, otherCharges.Id));  
        
      
        insert allocationList;
        
        
        
        PageReference pageRef = Page.StatementOfAccountDocument;
        Test.setCurrentPage(pageRef);  
        ApexPages.currentPage().getParameters().put('id',salesOrder.Id);

        StatementOfAccountController.getSalesOrderDetails();   
        StatementOfAccountController.getListSalesOrderDetail(new List<Id>{salesOrder.Id}); 
        
        
        
        SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit.Id;
        salesOrder2.Contact__c = con.Id;
        salesOrder2.MortgageApplicationNumber__c = '1234';
        salesOrder2.BookingDate__c = Date.newinstance(2020,01,20) ;
        insert salesOrder2;

        Test.StopTest();
    }
 
}