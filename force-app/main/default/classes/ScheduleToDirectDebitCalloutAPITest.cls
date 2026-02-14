@isTest
public class ScheduleToDirectDebitCalloutAPITest {
    public static string ADIBBankName   		           = 'Abu Dhabi Islamic Bank';
    
    @testSetup
    static void makeData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.SourceofFunds__pc = 'Employment Income';
        acc.Company__pc = 'AbuDhabi investment Authority';
        acc.Position__pc = 'Manager';
        acc.CompanyAddress__pc = 'AbuDhabi investment 211 corniche AD';
        acc.AnnualIncome__pc = 130000;
        acc.NoofYearswithCompany__pc = 32;
        acc.Industry = 'Government';
        acc.CustomerBankName__c = 'Abhu Dhabi';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        acc.NationalIdNumber__pc = '784198363604806';
        acc.EmploymentStatus__pc  = 'Employed';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.id);
        ddr.PayerAccount__c = acc.id;
        ddr.AmountType__c  = 'Variable';
        ddr.DebitRequestInstanceAllowed__c = '5';
        ddr.CustomerAccountName__c = acc.Name;
        ddr.PayingBankRoutingCode__c = '050';
        ddr.CustomerIdType__c = 'UAE Emirates Identity Card';
        ddr.CustomerIDNumber__c = '784123123123123';
        
        insert ddr;        
    }

    @isTest
    public static void testMethod1() {
        DirectDebitRequest__c ddr = [Select Id FROM DirectDebitRequest__c LIMIT 1];
        
        DDTransaction__c ddt11 = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        ddt11.DDAFileName__c = 'test.pdf';
        ddt11.Requesttype__c = 'New Registration';
        ddt11.APIEnabled__c = true;
        insert ddt11;
        ddt11.BankAPIsyncstatus__c = 'Ready for Registration Mandate API';
        update ddt11;
       
        Test.startTest();
        ScheduleToDirectDebitCalloutAPI sch = new ScheduleToDirectDebitCalloutAPI();
        sch.execute(null);
        Test.stopTest();
    }

    @isTest
    public static void testMethod2() {
        DirectDebitRequest__c ddr = [Select Id FROM DirectDebitRequest__c LIMIT 1];
        
        DDTransaction__c ddt12 = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        ddt12.Requesttype__c = BatchToDirectDebitCalloutAPIHelper.COLLECTION;        
        ddt12.APIEnabled__c = true;
		insert ddt12;
        ddt12.BankAPIsyncstatus__c = 'Ready for file upload API';
        update ddt12;
        Test.startTest();
        ScheduleToDirectDebitCalloutAPI sch = new ScheduleToDirectDebitCalloutAPI();
        sch.execute(null);
        Test.stopTest();
    }

    @isTest
    public static void testMethod3() {
        DirectDebitRequest__c ddr = [Select Id FROM DirectDebitRequest__c LIMIT 1];
        
        DDTransaction__c ddt13 = TestObjectsFactory.createDDTransactions(ddr.id, ADIBBankName);
        ddt13.Requesttype__c = BatchToDirectDebitCalloutAPIHelper.CANCELLATION;
        ddt13.APIEnabled__c = true;
        insert ddt13;
        ddt13.BankAPIsyncstatus__c = 'Registration sent to bank';
        update ddt13;
        Test.startTest();
        ScheduleToDirectDebitCalloutAPI sch = new ScheduleToDirectDebitCalloutAPI();
        sch.execute(null);
        Test.stopTest();
    }    
}