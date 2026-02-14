@istest
public class VirtualAccountServiceTest {
	@isTest static void setupData() {
    	Account account = TestObjectsFactory.getPersonAccountRecord(1111111, 'India','11111','P11111');
        account.Company__pc = 'ALdar';
        account.Position__pc = 'CEO';
        account.AnnualIncome__pc = 123456;
        account.Industry = 'Agriculture';
        account.BankName__c = 'ADCB';
        account.NoofYearswithCompany__pc = 20;
        account.BankCountry__c = 'United Arab Emirates';
        account.CompanyAddress__pc = 'Test address';
        account.isValidationBypass__c  = true;
        account.EmploymentStatus__pc = 'Unemployed';
        insert account;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        insert opp;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        unit.Name = 'MAYAN-B1-101095';
        insert unit;
        
        BankVirtualAccounts__c va1 = TestObjectsFactory.getBankVirtualAccounts();
        va1.Project__c = project.id;
        va1.Unit__c = unit.id;
        va1.Virtual_Account_Type__c = 'Escrow';
        insert va1;
        unit.VirtualAccountNumber__c = va1.id;
        update unit;
        BankVirtualAccounts__c va2 = TestObjectsFactory.getBankVirtualAccounts();
        va2.Project__c = project.id;
        va2.BufferFlag__c = true;
        va2.Virtual_Account_Type__c = 'Escrow';
        insert va2;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        insert salesOrder;
        
        test.startTest();
        salesOrder.Status__c = 'Cancelled';
        update salesOrder;
        set<id> soid = new set<id>();
        soid.add(salesOrder.id);
        VirtualAccountService.updateUnitVA(new Map<id,String>{salesOrder.id=>'Cancelled'});
        //System.assert(va1.StatusFlag__c == 'Cancelled');
        //System.assert(va2.BufferFlag__c==false);
        test.stopTest();
        
    }
}