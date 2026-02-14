@isTest
public class StaffIncentiveCommissionCalculationTest {

    @isTest
    static void setupData() {
         Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;

        Account relatedAccount = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert relatedAccount;
        
        Account relatedAccount1 = TestObjectsFactory.getOrganisationAccountRecord('companyName1', 'registrationNo1');
        insert relatedAccount1;

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        opp.EmployeeId__c = '123456789';
        opp.EmployeeEmail__c = 'test@aldar.com';
        insert opp;

        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;

        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;

        Document__c gtc = TestObjectsFactory.getProjectDocument(project.Id);
        insert gtc;

        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        unit.Name = 'MAYAN-B1-101095';
        unit.AffectionPlan__c = 'www.google.com';
        insert unit;
        
        Document__c doc = TestObjectsFactory.getProjectDocument(project.Id);
        doc.Unit__c = unit.Id;
        doc.DocumentType__c = 'Affection Plan';
        insert doc;

        TestObjectsFactory.createContentDocumentLink(doc.Id);
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        salesOrder.NetAmount__c = 100;
        salesOrder.Status__c = 'Sold';
        salesOrder.SalesApprovedDate__c = system.today();
        insert salesOrder;
        
        CommissionLineItem__c commissionLineItem = new CommissionLineItem__c();
        commissionLineItem.CommissionType__c = 'Staff Incentive';
        commissionLineItem.SalesOrder__c = salesOrder.Id;
        commissionLineItem.EmployeeEmail__c = opp.EmployeeEmail__c;
        commissionLineItem.EmployeeId__c = opp.EmployeeId__c;
        commissionLineItem.CommissionPercentage__c = 0;
        commissionLineItem.CommissionAmount__c = 2500;
        commissionLineItem.TotalPayableCommission__c = 2500;
        commissionLineItem.Unit__c = salesOrder.Unit__c;
        commissionLineItem.Project__c = project.Id;
        insert commissionLineItem;

    }
    
    @isTest static void StaffIncentiveCommissionsTest() {
        setupData() ;
        Integer intMonth = Date.Today().Month();
        Integer intYear = Date.Today().Year();
        integer numberOfDays = date.daysInMonth(intYear, intMonth);
        date soldStartDate = date.newInstance(intYear, intMonth, 1);
        date soldEndDate = date.newInstance(intYear, intMonth, numberOfDays);
        
        List<CommissionLineItem__c> commissionLineItems = [SELECT id, CommissionType__c, SalesOrder__r.SalesApprovedDate__c, SalesOrder__c, EmployeeEmail__c, EmployeeId__c, CommissionPercentage__c, CommissionAmount__c, TotalPayableCommission__c, Unit__c, Project__c FROM CommissionLineItem__c WHERE CommissionType__c= 'Staff Incentive' AND SalesOrder__r.Status__c ='Sold' AND  ((SalesOrder__r.SoldDate__c >=: soldStartDate AND SalesOrder__r.SoldDate__c <=: soldEndDate) OR (SalesOrder__r.SalesApprovedDate__c >=: soldStartDate AND SalesOrder__r.SalesApprovedDate__c <=: soldEndDate) )] ;
        system.debug('commissionLineItems::'+commissionLineItems);
        StaffIncentiveCommissionCalculationBatch batch = new StaffIncentiveCommissionCalculationBatch(String.valueOf(intMonth), String.valueOf(intYear));
        database.executeBatch(batch);
    }
    
}