@isTest
public class BatchToCreateBankVirtualAccountTest {
    @isTest
    public static void makeData(){
        Account account = TestObjectsFactory.getPersonAccountRecord(1111111, 'India','11111','P11111');
        account.MobileNumber__c = '123456789';
        account.SourceofFunds__pc = 'Employment Income';
        account.Company__pc = 'AbuDhabi investment Authority';
        account.Position__pc = 'Manager';
        account.CompanyAddress__pc = 'AbuDhabi investment 211 corniche AD';
        account.AnnualIncome__pc = 130000;
        account.NoofYearswithCompany__pc = 32;
        account.Industry = 'Government';
        account.CustomerBankName__c = 'Abhu Dhabi';
        account.CustomerBankCountry__c = 'United Arab Emirates';
        account.EmploymentStatus__pc  = 'Employed';
        insert account;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        insert opp;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(project.id);
        insert buildingRecord;
        project.BankNameEscrow__c = 'Abu Dhabi Commercial Bank';
        project.AccountNumberEscrow__c = '10503791920050';
        project.IBANNoEscrow__c = 'AE220030010503791920050';
        
        project.BankNameCorporate__c = 'Abu Dhabi Commercial Bank';
        project.AccountNumberCorporate__c = '10503791920050';
        project.IBANNoCorporate__c = 'AE120354031221018122005';
        update project;
        
        List<Unit__c> unList = new List<Unit__c>();
        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        unit.Name = 'MAYAN-B1-101095';
        unit.Status__c = 'New';
        unList.add(unit);
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('Mayan');
        unit1.Project__c = project.Id;
        unit1.Name = 'MAYAN-B1-101096';
        unit1.Status__c = 'New';
      
        unList.add(unit1);
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('Mayan');
        unit2.Project__c = project.Id;
        unit2.Name = 'MAYAN-B1-101097';
        unit2.status__c = 'New';
        unList.add(unit2);
        
        insert unList;
        
        BankVirtualAccounts__c va1 = TestObjectsFactory.getBankVirtualAccounts();
        va1.Project__c = project.id;
        va1.BufferFlag__c = true;
        va1.Virtual_Account_Type__c = 'Escrow';
        va1.Statusflag__c = ALD_Constants.ALDVA_STATUS_CANCELLED;
        va1.EscrowAccountNumber__c = '123123121';
        va1.BankName__c = BatchToCreateBankVirtualAccount.FAB;
        va1.VirtualAccountNumber__c = null;
        insert va1;

        BankVirtualAccounts__c va2 = TestObjectsFactory.getBankVirtualAccounts();
        va2.Project__c = project.id;
        va2.BufferFlag__c = true;
        va2.Virtual_Account_Type__c = 'Escrow';
        va2.EscrowAccountNumber__c = '1231233321';
        va2.Statusflag__c = ALD_Constants.ALDVA_STATUS_CANCELLED;
        va2.BankName__c =  BatchToCreateBankVirtualAccount.ADIB;
        va2.VirtualAccountNumber__c = null;
        insert va2;
        BankVirtualAccounts__c va3 = TestObjectsFactory.getBankVirtualAccounts();
        va3.Project__c = project.id;
        va3.BufferFlag__c = true;
        va3.Virtual_Account_Type__c = 'Escrow';
        va3.EscrowAccountNumber__c = '1231233321';
        va3.Statusflag__c ='Available';
        va3.VirtualAccountNumber__c = null;
        va3.BankName__c ='First Abu Dhabi Bank';
        insert va3;
        List<BankVirtualAccounts__c> str = new List<BankVirtualAccounts__c>();
        str.add(va1);
        str.add(va2);
        str.add(va3);
                
        BatchToCreateBankVirtualAccount  bcn = new BatchToCreateBankVirtualAccount(str,'Escrow',BatchToCreateBankVirtualAccount.ADIB);
        database.executeBatch(bcn,200);
                BatchToCreateBankVirtualAccount  bcn1= new BatchToCreateBankVirtualAccount(str,'Escrow','First Abu Dhabi Bank');
        database.executeBatch(bcn1,200);
    }
}