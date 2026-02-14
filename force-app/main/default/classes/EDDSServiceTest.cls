@isTest
public class EDDSServiceTest {

    @isTest
    public static void getEligibilityAndAccountTest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        Project__c project = [Select Id,DirectDebitApplied__c FROM Project__c LIMIT 1];
        project.DirectDebitApplied__c=true;
        project.DirectDebitOIC__c = '21212121';
        project.EDirectDebitApplied__c=true;
        project.EDirectDebitOIC__c = '21212121';
        update project;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
            
        List<InstallmentLines__c> installmentLinesList = TestObjectsFactory.createInstallmentLines(salesOrder1.Id, 5);
        
        Test.startTest();

        EDDSService.getEligibilityAndAccount(salesOrder1.Id, acc.Id,'NewSale');

        test.stopTest();
    }  

    @isTest
    public static void getDirectDebitsTest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        Project__c project = [Select Id,DirectDebitApplied__c FROM Project__c LIMIT 1];
        project.DirectDebitApplied__c=true;
        project.DirectDebitOIC__c = '21212121';
        project.EDirectDebitApplied__c=true;
        project.EDirectDebitOIC__c = '21212121';
        update project;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
            
        List<InstallmentLines__c> installmentLinesList = TestObjectsFactory.createInstallmentLines(salesOrder1.Id, 5);
             
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        ddr.PayerAccount__c=acc.Id;
        insert ddr;
        
        Test.startTest();

        EDDSService.getDirectDebits(salesOrder1.Id, acc.Id,'NewSale');

        test.stopTest();
    }  

    @isTest
    public static void getDDParamsTest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.Company__pc = 'ALdar';
        acc2.Position__pc = 'CEO';
        acc2.AnnualIncome__pc = 123456;
        acc2.Industry = 'Agriculture';
        acc2.BankName__c = 'ADCB';
        acc2.NoofYearswithCompany__pc = 20;
        acc2.BankCountry__c = 'United Arab Emirates';
        acc2.CompanyAddress__pc = 'Test address';
        acc2.isValidationBypass__c  = true;
        acc2.EmploymentStatus__pc = 'Unemployed';
        insert acc2;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
            
        List<InstallmentLines__c> installmentLinesList = TestObjectsFactory.createInstallmentLines(salesOrder1.Id, 5);
             
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        ddr.PayerAccount__c=acc.Id;
        insert ddr;
        
        Test.startTest();

        //DirectDebitService.getSalesOrderDetailsForDDS(salesOrder1.id);
        EDDSService.getDDParams(salesOrder1.Id, new List<String>{acc.Id,acc2.Id},'NewSale');

        test.stopTest();
    }
    
    @isTest
    public static void isValueInPicklistTest() {
        Test.startTest();
        EDDSService.isValueInPicklist('Account','Industry','Technology');
        EDDSService.isValueInPicklist('Account','Non_Existing_Random_Field','Non Existing Random Value');
        EDDSService.isValueInPicklist('Account','Industry','');
        EDDSService.isValueInPicklist('Non_Existing_Random_Object','Industry','Non Existing Random Value');
        EDDSService.isValueInPicklist('Account','createddate','Non Existing Random Value');
        test.stopTest();
    }  
    
    @isTest
    public static void isValidSalesforceIdTest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.Company__pc = 'ALdar';
        acc2.Position__pc = 'CEO';
        acc2.AnnualIncome__pc = 123456;
        acc2.Industry = 'Agriculture';
        acc2.BankName__c = 'ADCB';
        acc2.NoofYearswithCompany__pc = 20;
        acc2.BankCountry__c = 'United Arab Emirates';
        acc2.CompanyAddress__pc = 'Test address';
        acc2.isValidationBypass__c  = true;
        acc2.EmploymentStatus__pc = 'Unemployed';
        insert acc2;
        
        Test.startTest();
        EDDSService.isValidSalesforceId(null,'Account');
        EDDSService.isValidSalesforceId(acc.Id,'Account');
        EDDSService.isValidSalesforceId(acc2.Id,'Contact');
        EDDSService.isValidSalesforceId('INVALIDID','Contact');
        EDDSService.isValidSalesforceIds(null,'Account');
        EDDSService.isValidSalesforceIds(new List<String>{acc.Id,acc2.Id},'Account');
        EDDSService.isValidSalesforceIds(new List<String>{acc.Id,acc2.Id},'Contact');
        EDDSService.isValidSalesforceIds(new List<String>{'INVALIDID'},'Contact');
        test.stopTest();
    }  
    
    @isTest
    public static void isValidJourneyTypeTest() {
        EDDSService.isValidJourneyType('NewSale');
    }
    
    @isTest
    public static void isValidTransactionTypeTest() {
        EDDSService.isValidTransactionType('NewRegistration');
    }

    @isTest
    public static void getDirectDebitByIdSetTest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.Company__pc = 'ALdar';
        acc2.Position__pc = 'CEO';
        acc2.AnnualIncome__pc = 123456;
        acc2.Industry = 'Agriculture';
        acc2.BankName__c = 'ADCB';
        acc2.NoofYearswithCompany__pc = 20;
        acc2.BankCountry__c = 'United Arab Emirates';
        acc2.CompanyAddress__pc = 'Test address';
        acc2.isValidationBypass__c  = true;
        acc2.EmploymentStatus__pc = 'Unemployed';
        insert acc2;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
            
        List<InstallmentLines__c> installmentLinesList = TestObjectsFactory.createInstallmentLines(salesOrder1.Id, 5);
             
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        ddr.PayerAccount__c=acc.Id;
        insert ddr;
        
        Test.startTest();
        EDDSService.getDirectDebitByIdSet(new Set<Id>{ddr.Id});

        test.stopTest();
    }
        
}