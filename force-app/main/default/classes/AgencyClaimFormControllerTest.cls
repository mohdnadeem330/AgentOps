/**
* AgencyClaimFormControllerTest
*
* Test class for AgencyClaimFormController
*/
@isTest
private class AgencyClaimFormControllerTest{
    //test PDF generation
    
    @isTest static void testNoRecords() {
        //ApexPages.currentPage().getParameters().put('Id','testId');
        //
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        project.CommunityName__c = 'Noya';
        insert project;
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Project__c = project.id;
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.BookingDate__c = Date.newInstance(2022, 1, 1);
        salesOrder.NetAmount__c = 10000;
        insert salesOrder;

        //List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        //id, name, CommissionAmount__c, SalesOrder__r.ProjectName__c, SalesOrder__r.Unit__r.CommunityName__c, SalesOrder__r.UnitNumber__c, SalesOrder__r.name, SalesOrder__r.NetAmount__c,SalesOrder__r.BookingDate__c,BrokerAgency__r.name, InvoiceDate__c, InvoiceNumber__c
        //TestObjectsFactory.createOpportunityOfferLines(salesOrder.Id, 5);
        CommissionLineItem__c commissionLineItem = new CommissionLineItem__c();
        commissionLineItem.SalesOrder__c = salesOrder.id;
        commissionLineItem.CommissionType__c = 'External';
        commissionLineItem.CommissionPercentage__c = 10;
        commissionLineItem.CommissionAmount__c = 1000;
        commissionLineItem.SalesManager__c = UserInfo.getUserId();
        commissionLineItem.BrokerAgency__c = acc.id;
        commissionLineItem.InvoiceDate__c = Date.newInstance(2022, 1, 1);
        commissionLineItem.InvoiceNumber__c = 'INV123';
        commissionLineItem.Status__c = 'Pending Invoice Verification';
        //commissionLineItem.InstallmentLine__c = installmentLineId;
        
        insert commissionLineItem;
        System.debug(commissionLineItem);
        //update cl1;
        //CommissionLineItem__c cl = new CommissionLineItem__c(CommissionAmount__c = 100, CommissionPercentage__c = 5, CommissionType__c = 'External', Status__c='Pending Invoice Verification');
        //insert cl;
        test.startTest();
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		app.setObjectId(commissionLineItem.id);
		Approval.ProcessResult result = Approval.process(app);
        
        
        //Test.StartTest();
        PageReference pageRef = Page.AgencyClaimForm; // Add your VF page Name here
  		pageRef.getParameters().put('id', String.valueOf(commissionLineItem.Id));
  		Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(commissionLineItem);
        AgencyClaimFormController controllerObject = new AgencyClaimFormController(sc);

        test.stopTest();
        //System.assertEquals(null, controllerObject.comm);
    }
}