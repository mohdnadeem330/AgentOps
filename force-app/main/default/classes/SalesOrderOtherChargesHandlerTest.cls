@isTest
public class SalesOrderOtherChargesHandlerTest {

    @testSetup 
    static void setupMethod() {
        
        List<HexaBPM__SR_Status__c> srStatusList = new List<HexaBPM__SR_Status__c>();
         HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus( Constants.SUBMITTED);
        srStatusList.add(objSRStatus);
        HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus(Constants.PENDING_STATUS);
        srStatusList.add(objSRStatus1);
        
        HexaBPM__SR_Status__c objSRStatus2 = TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS);
        srStatusList.add(objSRStatus2);
        
        HexaBPM__SR_Status__c objSRStatus3 = TestObjectsFactory.getSRStatus(Constants.STEP_APPROVED_STATUS);
        srStatusList.add(objSRStatus3);
        
        HexaBPM__SR_Status__c objSRStatus4 = TestObjectsFactory.getSRStatus(Constants.STEP_ACCEPTED_STATUS);
        srStatusList.add(objSRStatus4);
        
        HexaBPM__SR_Status__c objSRStatus5 = TestObjectsFactory.getSRStatus(Constants.STEP_REJECTED_STATUS);
        srStatusList.add(objSRStatus5);
        
        insert srStatusList;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
    
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
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
        salesOrder.MortgageApplicable__c = 'No';
        salesOrder.ADMFeeAmount__c = 20000;
        insert salesOrder;
        
         HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
       // SR.RecordTypeId = recordTypeSR.get('TitleDeedRegistration');
        SR.HexaBPM__Customer__c = acc.Id;
      //  SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
      //  SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.MortgageApplicable__c = 'No';
        SR.ApplicationId__c = 123456;
        SR.Proceed_with_Offline__c = false;
        insert SR;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        update installmentLines[0];
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        receiptAllocation.DateOfApplication__c = null;
        receiptAllocation.Unapply__c = false;
        insert receiptAllocation;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.SubType__c = Constants.OTHER_CHARGES_Charge_TYPE_ADM_Fee_REFUND;
        update otherCharges;
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = salesOrder.Id;
        salesOrderOtherCharges.Account__c = acc.Id;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.InvoicedAmount__c = 9990;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE;
        insert salesOrderOtherCharges;
    }
    
    @isTest static void testUpdate() {
                Test.startTest();
        SalesOrderOtherCharges__c otherCharges = [select id, Account__c, SalesOrder__c from SalesOrderOtherCharges__c limit 1];
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = otherCharges.SalesOrder__c;
        salesOrderOtherCharges.Account__c = otherCharges.Account__c;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO;
        insert salesOrderOtherCharges;
        
        TriggerHandler.processedIds = new Set<Id>();

        salesOrderOtherCharges.Amount__c = 9000;
        update salesOrderOtherCharges;
        
        TriggerHandler.processedIds = new Set<Id>();

        salesOrderOtherCharges.InvoicedAmount__c = 8000;
        update salesOrderOtherCharges;
        Test.stopTest();
    }
    

    @isTest static void testUpdateOne() {
        Test.startTest();
        SalesOrderOtherCharges__c otherCharges = [select id, Account__c, SalesOrder__c from SalesOrderOtherCharges__c limit 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = otherCharges.SalesOrder__c;
        salesOrderOtherCharges.Account__c = otherCharges.Account__c;
        salesOrderOtherCharges.ChargedFromResaleOpp__c = true;
        salesOrderOtherCharges.InvoicedAmount__c = 8000;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.Opportunity__c = opp.Id;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO;        
        insert salesOrderOtherCharges;
        
        TriggerHandler.processedIds = new Set<Id>();    
        salesOrderOtherCharges.InvoicedAmount__c = 10000;
        System.debug('salesOrderOtherCharges :' + salesOrderOtherCharges);
        salesOrderOtherCharges.TypeOfCharge__c = 'Title Deed Registration Fee';
        salesOrderOtherCharges.Amount__c = 925;
        salesOrderOtherCharges.AmountReceived__c = 925;
        salesOrderOtherCharges.ServiceRequest__c = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1].Id;
        update salesOrderOtherCharges;
        Test.stopTest();
    }
}