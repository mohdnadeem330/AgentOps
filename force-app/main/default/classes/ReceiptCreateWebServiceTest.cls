@isTest(SeeAllData=false)
public  class ReceiptCreateWebServiceTest {
    @isTest static void setupMethod() {
        
        Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
        insert orgAccount;
        
        Contact contactRecord = TestObjectsFactory.contactDataSetup(orgAccount.id);
        //insert contactRecord;
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAccount.Id);
        insert opportunityRecord;
        
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingSection;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = projectRecord.Id;
        unit.Name = 'MAYAN-B1-101095';
        unit.BuildingSectionName__c = buildingSection.id;
        insert unit;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAccount.Id);
        salesOrderRecord.unit__c = unit.Id;
        salesOrderRecord.Contact__c = contactRecord.Id;
        insert salesOrderRecord;
        
        PaymentPlan__c paymentPlan = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlan;
        
        list<PaymentInstallments__c> paymentInstallmentList = TestObjectsFactory.getPaymentInstallment(paymentPlan.Id);
        insert paymentInstallmentList;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.getInstallmentLines(salesOrderRecord.id, paymentPlan.Id, paymentInstallmentList);
        insert  installmentLineList;
        
        
        String JSON = '{"recieptRecord": {"PaymentType__c": "Cheque","Amount__c": "10000","SalesOrder__c":"'+salesOrderRecord.id+'", "Opportunity__c":"'+opportunityRecord.id+'", "Account__c":"'+orgAccount.id+'","Remarks__c": "Remark","BankName__c": "","CustomerBankAccount__c": "","MaturityDate__c" : "2022-08-08","ReferenceNumber__c": "762528","MortgageCheque__c": "","CurrencyIsoCode": "AED","IsCreatedFromLink__c": true,"RecievedFromAccount__c": ""},"orderId": "'+salesOrderRecord.Id+'","recordId": "'+installmentLineList[0].Id+'","fileToInsert":{"Title" : "ajay.png","FileContent":"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAAaADAAQAAAABAAAAAQAAAAD5Ip3+AAAADUlEQVQIHWP4/5+hHgAHfQJ+Y3Sh9QAAAABJRU5ErkJggg=="}}';
        
        TestObjectsFactory.initializeRestContext(null, '/create/receipt');
        ReceiptCreateWebService.doPost();
        TestObjectsFactory.initializeRestContext(JSON, '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        
        ReceiptAcknowledgementController.FileInfo fileInfo = new ReceiptAcknowledgementController.FileInfo();
        ReceiptAcknowledgement__c receiptRecord = new ReceiptAcknowledgement__c();
        
        ReceiptCreateWebService.CreateReceiptModel createReceiptModel = new ReceiptCreateWebService.CreateReceiptModel(receiptRecord,salesOrderRecord.Id, installmentLineList[0].Id,fileInfo);
        
        ReceiptCreateWebService.doPost();
        
        Test.stopTest();
    }
}