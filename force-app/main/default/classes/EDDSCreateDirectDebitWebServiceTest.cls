@isTest
public class EDDSCreateDirectDebitWebServiceTest {

     @isTest
    public static void doPost1Test() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25083');
        insert unit1;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        insert ddr1;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/createEDirectDebit');
        RestContextHandler handler = new RestContextHandler(false);
        RestContext.request.requestBody = Blob.valueOf('{"directDebitId": "'+ddr1.id+'","relatedRecordId": "'+salesOrder1.id+'","payerAccountId": "'+acc.Id+'","amountType": "Variable","paymentFrequency": "Monthly","maxAmount": 5260000.0,"minAmount": 0,"ddaReferenceNumber": "1758875554568OU#00064336",'
	    +'"expiresOn": "","commencesOn": "2025-09-25","customerMobileNumber": "+971545127085","customerEmail": "test@pwc.com", "custNid": "784199012345678","customerIdNumber": "784199012345678","customerIdType": "UAE Emirates Identity Card","customerType": "Individual", "customerFullName": "Jane Doe",'
    	+'"customerBankAccountNumber": "AE123456789123456789123","customerBankAccountTitle": "Jane Doe Thomson","customerBankAccountType": "Current","customerAccountBankName": "Abu Dhabi Commercial Bank","userPreferPaymentMethod": "Bank Account","ddaId":"914","ddarId":"795","journeyType": "NewSale"}');
        EDDSCreateDirectDebitWebService.doPost();
    }
    

     @isTest
    public static void doPost2Test() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25083');
        insert unit1;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        insert ddr1;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/createEDirectDebit');
        RestContextHandler handler = new RestContextHandler(false);
        RestContext.request.requestBody = Blob.valueOf('{"directDebitId": "","relatedRecordId": "'+salesOrder1.id+'","payerAccountId": "'+acc.Id+'","amountType": "Variable","paymentFrequency": "Monthly","maxAmount": 5260000.0,"minAmount": 0,"ddaReferenceNumber": "1758875554568OU#00064336",'
	    +'"expiresOn": "","commencesOn": "2025-09-25","customerMobileNumber": "+971545127085","customerEmail": "test@pwc.com", "custNid": "784199012345678","customerIdNumber": "784199012345678","customerIdType": "UAE Emirates Identity Card","customerType": "Individual", "customerFullName": "Jane Doe",'
    	+'"customerBankAccountNumber": "AE123456789123456789123","customerBankAccountTitle": "Jane Doe Thomson","customerBankAccountType": "Current","customerAccountBankName": "Abu Dhabi Commercial Bank","userPreferPaymentMethod": "Bank Account","ddaId":"914","ddarId":"795","journeyType": "NewSale"}');
        EDDSCreateDirectDebitWebService.doPost();
    }
    

     @isTest
    public static void doPost3Test() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25083');
        insert unit1;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        insert ddr1;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/createEDirectDebit');
        RestContextHandler handler = new RestContextHandler(false);
        RestContext.request.requestBody = Blob.valueOf('{"directDebitId": "'+ddr1.id+'","relatedRecordId": "'+salesOrder1.id+'","payerAccountId": "'+acc.Id+'","amountType": "Variable","paymentFrequency": "Monthly","maxAmount": 5260000.0,"minAmount": 0,"ddaReferenceNumber": "1758875554568OU#00064336",'
	    +'"expiresOn": "","commencesOn": "2025-09-25","customerMobileNumber": "+971545127085","customerEmail": "test@pwc.com", "custNid": "784199012345678","customerIdNumber": "784199012345678","customerIdType": "UAE Emirates Identity Card","customerType": "Individual", "customerFullName": "Jane Doe",'
    	+'"customerBankAccountNumber": "AE123456789123456789123","customerBankAccountTitle": "Jane Doe Thomson","customerBankAccountType": "Current","customerAccountBankName": "Abu Dhabi Commercial Bank","userPreferPaymentMethod": "Bank Account","ddaId":"914","ddarId":"795","journeyType": "NewLeasing"}');
        EDDSCreateDirectDebitWebService.doPost();
    }
    

     @isTest
    public static void doPost4Test() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25083');
        insert unit1;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        insert ddr1;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/createEDirectDebit');
        RestContextHandler handler = new RestContextHandler(false);
        RestContext.request.requestBody = Blob.valueOf('{"directDebitId": "'+ddr1.id+'","relatedRecordId": "'+salesOrder1.id+'","payerAccountId": "'+acc.Id+'","amountType": "Variable","paymentFrequency": "Monthly","maxAmount": 5260000.0,"minAmount": 0,"ddaReferenceNumber": "1758875554568OU#00064336",'
	    +'"expiresOn": "","commencesOn": "2025-09-25","customerMobileNumber": "+971545127085","customerEmail": "test@pwc.com", "custNid": "784199012345678","customerIdNumber": "784199012345678","customerIdType": "UAE Emirates Identity Card","customerType": "Individual", "customerFullName": "Jane Doe",'
    	+'"customerBankAccountNumber": "AE123456789123456789123","customerBankAccountTitle": "Jane Doe Thomson","customerBankAccountType": "Current","customerAccountBankName": "Abu Dhabi Commercial Bank","userPreferPaymentMethod": "Bank Account","ddaId":"914","ddarId":"795","journeyType": "Retail"}');
        EDDSCreateDirectDebitWebService.doPost();
    }
    

     @isTest
    public static void doPost5Test() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25083');
        insert unit1;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        insert ddr1;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/createEDirectDebit');
        RestContextHandler handler = new RestContextHandler(false);
        RestContext.request.requestBody = Blob.valueOf('{"directDebitId": "'+ddr1.id+'","relatedRecordId": "'+salesOrder1.id+'","payerAccountId": "'+acc.Id+'","amountType": "Variable","paymentFrequency": "Monthly","maxAmount": 5260000.0,"minAmount": 0,"ddaReferenceNumber": "1758875554568OU#00064336",'
	    +'"expiresOn": "","commencesOn": "2025-09-25","customerMobileNumber": "+971545127085","customerEmail": "test@pwc.com", "custNid": "784199012345678","customerIdNumber": "784199012345678","customerIdType": "UAE Emirates Identity Card","customerType": "Individual", "customerFullName": "Jane Doe",'
    	+'"customerBankAccountNumber": "AE123456789123456789123","customerBankAccountTitle": "Jane Doe Thomson","customerBankAccountType": "Current","customerAccountBankName": "Abu Dhabi Commercial Bank","userPreferPaymentMethod": "Bank Account","ddaId":"914","ddarId":"795","journeyType": ""}');
        EDDSCreateDirectDebitWebService.doPost();
    }
    

     @isTest
    public static void doPost6Test() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;
        
        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(acc2.Id);
        insert opp2;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25083');
        insert unit1;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        insert ddr1;
        
        TestObjectsFactory.initializeRestContext(null, '/edds/createEDirectDebit');
        RestContextHandler handler = new RestContextHandler(false);
        RestContext.request.requestBody = Blob.valueOf('{"directDebitId": "","relatedRecordId": "","payerAccountId": "","amountType": "Variable","paymentFrequency": "Monthly","maxAmount": 5260000.0,"minAmount": 0,"ddaReferenceNumber": "1758875554568OU#00064336",'
	    +'"expiresOn": "","commencesOn": "2025-09-25","customerMobileNumber": "+971545127085","customerEmail": "test@pwc.com", "custNid": "784199012345678","customerIdNumber": "784199012345678","customerIdType": "UAE Emirates Identity Card","customerType": "Individual", "customerFullName": "Jane Doe",'
    	+'"customerBankAccountNumber": "AE123456789123456789123","customerBankAccountTitle": "Jane Doe Thomson","customerBankAccountType": "Current","customerAccountBankName": "Abu Dhabi Commercial Bank","userPreferPaymentMethod": "Bank Account","ddaId":"914","ddarId":"795","journeyType": "NewSale"}');
        EDDSCreateDirectDebitWebService.doPost();
    }    
}