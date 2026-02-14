@isTest
public class ALDOC_OtherChargesHelperTest {
    @testSetup 
    static void setupMethod() {
        
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
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        update installmentLines[0];
        /*
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        receiptAllocation.DateOfApplication__c = null;
        receiptAllocation.Unapply__c = false;
        insert receiptAllocation;*/
        User us = TestObjectsFactory.getUserRecord('System Administrator', 'alliswell16May');
        us.Username = 'alliswell16May@aldar.com';
        insert us;
        //User us = [SELECT Id,Username from User Where Profile.Name = 'System Administrator' and username='alliswell16May@aldar.com' and IsActive = true limit 1];
        System.debug('us name ## -<'+us.Username);
        System.runAs(us) {
            SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
            otherCharges.SubType__c = Constants.OTHER_CHARGES_Charge_TYPE_ADM_Fee_REFUND;
            update otherCharges;    
        }
        
    }
    
    @isTest static void testUpdate() {
        //ALDOC_OtherChargesHelper.IsTesting_FOR_ADMIN = TRUE;
        SalesOrderOtherCharges__c otherCharges = [select id, createdby.name,Account__c, SalesOrder__c from SalesOrderOtherCharges__c limit 1];
        System.debug('otherCharges created by -> '+otherCharges.createdby.name);
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = otherCharges.SalesOrder__c;
        salesOrderOtherCharges.Account__c = otherCharges.Account__c;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO;
        Id chargeId = ALDOC_OtherChargesHelper.insertSalesOrderOtherCharge(salesOrderOtherCharges);
        List<Id> recordIds = new List<Id>();
        recordIds.add(chargeId);
        
        otherCharges.Amount__c = 9000;
        otherCharges.SyncStatus__c = 'In Progress';
        update salesOrderOtherCharges;
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "50c29210-d82d-11ed-9436-0211179397d0", "results": { "othChgRes": [ { "sfRequestId": "50c29210-d82d-11ed-9436-0211179397d0", "srSFId": "STANDALONE", "sfId": "a292500000228qxAAA", "erpId": "9058910", "recAcct": "02.10.A439020.123142.02.00.000.000", "expAcct": "02.10.A439020.421101.02.00.000.000", "taxAcct": "02.10.A439020.233169.02.00.000.000", "status": "Success", "errorMsg": "", "invoiceNo": "70083100" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        ALDOC_OtherChargesHelper.executeUponApproval(recordIds);
        ALDOC_OtherChargesHelper.fetchOCFields(chargeId,'SalesOrderOtherCharges__c','New_OC_For_Finance');
        ALDOC_OtherChargesHelper.fetchOCFields(null,'SalesOrderOtherCharges__c','Bank_info');
        ALDOC_OtherChargesHelper.fetchSalesOrder(otherCharges.SalesOrder__c);
        ALDOC_OtherChargesHelper.checkIsFinanceHeadGroup();
    }
    @isTest static void testUpdateTwo() {
        //ALDOC_OtherChargesHelper.IsTesting_FOR_ADMIN = TRUE;
        SalesOrderOtherCharges__c otherCharges = [select id, Account__c, createdby.name,SalesOrder__c from SalesOrderOtherCharges__c limit 1];
        System.debug('otherCharges created by -> '+otherCharges.createdby.name);
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = otherCharges.SalesOrder__c;
        salesOrderOtherCharges.Account__c = otherCharges.Account__c;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO;
        Id chargeId = ALDOC_OtherChargesHelper.insertSalesOrderOtherCharge(salesOrderOtherCharges);
        List<Id> recordIds = new List<Id>();
        recordIds.add(chargeId);
        ALDOC_OtherChargesHelper.IsTesting_FOR_ADMIN = TRUE;
        ALDOC_OtherChargesHelper.executeUponApproval(recordIds);
        
    }
    
    @isTest static void testUpdateFailureCase() {
        //ALDOC_OtherChargesHelper.IsTesting_FOR_ADMIN = TRUE;
        SalesOrderOtherCharges__c otherCharges = [select id, createdby.name,Account__c, SalesOrder__c from SalesOrderOtherCharges__c limit 1];
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = otherCharges.SalesOrder__c;
        salesOrderOtherCharges.Account__c = otherCharges.Account__c;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO;
        Id chargeId = ALDOC_OtherChargesHelper.insertSalesOrderOtherCharge(salesOrderOtherCharges);
        List<Id> recordIds = new List<Id>();
        recordIds.add(chargeId);
        //User us = [SELECT Id,Username from User Where Profile.Name = 'System Administrator' and username='alliswell16May@aldar.com' and IsActive = true limit 1];
        //System.debug('us name ## -<'+us.Username);
        //System.runAs(us) {
            SalesOrderOtherCharges__c salesOrderOtherCharges1 = [SELECT Id,Amount__c,SyncStatus__c, createdById from SalesOrderOtherCharges__c where id=:otherCharges.Id];
            //System.debug('### createdById -> '+salesOrderOtherCharges1.createdById);
            //System.debug('### us Id -> '+us.Id); 
            salesOrderOtherCharges1.Amount__c = 9000;
            salesOrderOtherCharges1.SyncStatus__c = 'In Progress';
            update salesOrderOtherCharges1;
        //}
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "204", "correlationId": "50c29210-d82d-11ed-9436-0211179397d0", "results": { "othChgRes": [ { "sfRequestId": "50c29210-d82d-11ed-9436-0211179397d0", "srSFId": "STANDALONE", "sfId": "a292500000228qxAAA", "erpId": "9058910", "recAcct": "02.10.A439020.123142.02.00.000.000", "expAcct": "02.10.A439020.421101.02.00.000.000", "taxAcct": "02.10.A439020.233169.02.00.000.000", "status": "E", "errorMsg": "", "invoiceNo": "70083100" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        ALDOC_OtherChargesHelper.executeUponApproval(recordIds);
        ALDOC_OtherChargesHelper.fetchOCFields(chargeId,'SalesOrderOtherCharges__c','New_OC_For_Finance');
        ALDOC_OtherChargesHelper.fetchOCFields(null,'SalesOrderOtherCharges__c','Bank_info');
        ALDOC_OtherChargesHelper.fetchSalesOrder(otherCharges.SalesOrder__c);
    }
}