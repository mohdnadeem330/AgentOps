@isTest(SeeAllData=false)
public class LPCServiceTest_STAGING {
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
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        insert salesOrder;

        Unit__c unitdetails = [SELECT Id,BuildingSectionName__c FROM Unit__c WHERE Id =: unit.Id];

        BuildingSection__c newBuilding = new BuildingSection__c();
        newBuilding.Id = unitdetails.BuildingSectionName__c;
        newBuilding.LatePaymentCharges__c = 2;
        update newBuilding;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);
        
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 90;
        installmentLines[0].InvoiceNumber__c = '638221';
        installmentLines[0].InstallmentDate__c = Date.Today().addDays(-10);
        installmentLines[0].ExtensionDate__c = Date.Today().addDays(-5);
        
        installmentLines[1].AmountReceived__c = 100;
        installmentLines[1].InvoicedAmount__c = 90;
        installmentLines[1].InvoiceNumber__c = '638221';
        installmentLines[1].InstallmentDate__c = Date.Today().addDays(-10);
        installmentLines[1].LPCFreezeDate__c = Date.Today().addDays(-5);
        installmentLines[1].LPCFreezeUntilDate__c = Date.Today().addDays(20);
        
        installmentLines[2].InvoiceNumber__c = '638221';
        installmentLines[2].InstallmentDate__c = Date.Today().addDays(-5);
        
        update installmentLines ;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);

        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receipt.Status__c = Constants.RECEIPT_STATUS_CLEARED;
        receipt.ClearedDate__c = Date.Today();
        insert receipt;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(acc1.Id,20,'Friend Of');
        jointOwner.SalesOrder__c = salesOrder.Id;
        insert jointOwner;

        ReceiptAllocation__c recAllocation = TestObjectsFactory.getReceiptAllocationRecord(receipt.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        insert recAllocation;

        ReceiptAllocation__c recAllocation1 = TestObjectsFactory.getReceiptAllocationRecord(receipt.Id, salesOrder.Id, acc.Id, otherCharges.Id);
        insert recAllocation1;

        List<ReceiptAllocation__c> allocationList = new List<ReceiptAllocation__c>();
        allocationList.add(recAllocation);
        allocationList.add(recAllocation1);

        ReceiptAllocation__c recAllocation2 = [SELECT Id, ReceiptAcknowledgement__r.ClearedDate__c, AmountApplied__c FROM ReceiptAllocation__c WHERE Id =: recAllocation1.Id];
        InstallmentLines__c installmentRec = [SELECT Id, AmountReceived__c, InvoicedAmount__c, InvoiceNumber__c, InstallmentDate__c, LPCPercentage__c, OutstandingAmount__c, InstallmentAmount__c FROM InstallmentLines__c WHERE Id =: installmentLines[0].Id ];

        List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
        
        SalesOrderOtherCharges__c otherCharges1 = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges1.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT ;
        otherChargeList.add(otherCharges1);
        
        SalesOrderOtherCharges__c otherCharges2 = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges2.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT ;
        otherCharges2.InvoicedAmount__c = 150 ;
        otherChargeList.add(otherCharges2);
        
        update otherChargeList ;
        
        Test.StartTest();
        
        PageReference pageRef = Page.StatementOfAccountDocument;
        Test.setCurrentPage(pageRef);  
		ApexPages.currentPage().getParameters().put('id',salesOrder.Id);

        StatementOfAccountController_STAGING.getSalesOrderDetails();   
        StatementOfAccountController_STAGING.getListSalesOrderDetail(new List<Id>{salesOrder.Id});   
        LPCService_STAGING.getOutstandingLPCforSalesOrder(salesOrder.Id);   

        Map<Id,List<ReceiptAllocation__c>> installmentAllocationMap = new Map<Id,List<ReceiptAllocation__c>>();
        installmentAllocationMap.put(installmentLines[0].Id, allocationList) ;
        LPCService_STAGING.getLPCForSalesOrder(salesOrder, installmentLines, installmentAllocationMap);
        
        

        Test.StopTest();

    }
}