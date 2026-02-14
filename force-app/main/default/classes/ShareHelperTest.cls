/*
*Created By     : Hardik Vitthani
*Description    : Test class for ShareHelper
*/
@isTest
public class ShareHelperTest {
    @isTest
    public static void testShareLead() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        try {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Test":"Test"}'));
            
            Lead lead = TestObjectsFactory.getLeadRecord(101, 'Person');
            lead.BrokerAgency__c = acc.Id;
            insert lead;
            
            ShareHelper.shareLeadRecord(new List<Lead>{lead}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareOpportunity() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        Account pAcc = TestObjectsFactory.getPersonAccountRecord();
        insert pAcc;
        
        try {
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(pAcc.Id);
            opp.BrokerAgencyAccount__c = acc.Id;
            insert opp;
            
            ShareHelper.shareOpportunityRecord(new List<Opportunity>{opp}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareAccountRelatedToOpportunity() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        Account pAcc = TestObjectsFactory.getPersonAccountRecord();
        insert pAcc;
        
        try {
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(pAcc.Id);
            opp.BrokerAgencyAccount__c = acc.Id;
            insert opp;
            
            ShareHelper.shareAccountRelatedToOpportunity(new List<Opportunity>{opp}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareSalesOrderSalesManager() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.SalesManager__c = UserInfo.getUserId();
        insert salesOrder;
        
        try {
            ShareHelper.shareSalesOrderSalesManager(new List<salesOrder__c>{salesOrder}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareSalesOrderBrokerManager() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        Account pAcc = TestObjectsFactory.getPersonAccountRecord();
        insert pAcc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(pAcc.Id);
        opp.BrokerAgencyAccount__c = acc.Id;
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, pAcc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.SalesManager__c = UserInfo.getUserId();
        insert salesOrder;
        
        try {
            ShareHelper.shareSalesOrderBrokerManager(new List<salesOrder__c>{salesOrder}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareCommissionLineBrokerManager() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        Account pAcc = TestObjectsFactory.getPersonAccountRecord();
        insert pAcc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(pAcc.Id);
        opp.BrokerAgencyAccount__c = acc.Id;
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, pAcc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.SalesManager__c = UserInfo.getUserId();
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        CommissionLineItem__c commissionLine = TestObjectsFactory.createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);
        commissionLine.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
        commissionLine.BrokerAgency__c = acc.Id;
        update commissionLine;
        
        try {
            ShareHelper.shareCommissionLineBrokerManager(new List<CommissionLineItem__c>{commissionLine}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareDocumentSalesOrder() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        Account pAcc = TestObjectsFactory.getPersonAccountRecord();
        insert pAcc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(pAcc.Id);
        opp.BrokerAgencyAccount__c = acc.Id;
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, pAcc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.SalesManager__c = UserInfo.getUserId();
        insert salesOrder;
        
        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id, salesOrder.Id);
        insert document;
        
        try {
            ShareHelper.shareDocument(new List<Document__c>{document}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareDocumentEOI() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        Account pAcc = TestObjectsFactory.getPersonAccountRecord();
        insert pAcc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(pAcc.Id);
        opp.BrokerAgencyAccount__c = acc.Id;
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        OpportunityEOI__c opportunityEOI = TestObjectsFactory.getOpportunityEOIRecord(opp.Id, 'Online');
        opportunityEOI.ProjectName__c = unit.Project__c;
        opportunityEOI.Account__c = acc.Id;
        opportunityEOI.Opportunity__c = opp.Id;
        opportunityEOI.BuildingSectionName__c = unit.BuildingSectionName__c;
        opportunityEOI.UnitModel__c = '1BHK';
        opportunityEOI.PriceRangeFrom__c = 0;
        opportunityEOI.PriceRangeTo__c = 10000;
        opportunityEOI.UnitFeatures__c = 'Saadiyat';
        opportunityEOI.ComplianceStatus__c = 'Cleared';
        insert opportunityEOI;
        
        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id, null);
        document.ExpressionofInterest__c = opportunityEOI.Id;
        insert document;
        
        try {
            ShareHelper.shareDocument(new List<Document__c>{document}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareDocumentWithAccountTeamMember() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id, null);
        document.Account__c = acc.Id;
        insert document;
        
        try {
            ShareHelper.shareDocumentWithAccountTeamMember(new List<Document__c>{document}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareReceiptAcknowledgementSalesOrder() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.SalesManager__c = UserInfo.getUserId();
        insert salesOrder;
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;
        
        try {
            //ShareHelper.shareReceiptAcknowledgement(new List<ReceiptAcknowledgement__c>{receiptAcknowledgement}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareReceiptAcknowledgementEOI() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        OpportunityEOI__c opportunityEOI = TestObjectsFactory.getOpportunityEOIRecord(opp.Id, 'Online');
        opportunityEOI.ProjectName__c = unit.Project__c;
        opportunityEOI.Account__c = acc.Id;
        opportunityEOI.Opportunity__c = opp.Id;
        opportunityEOI.BuildingSectionName__c = unit.BuildingSectionName__c;
        opportunityEOI.UnitModel__c = '1BHK';
        opportunityEOI.PriceRangeFrom__c = 0;
        opportunityEOI.PriceRangeTo__c = 10000;
        opportunityEOI.UnitFeatures__c = 'Saadiyat';
        opportunityEOI.ComplianceStatus__c = 'Cleared';
        insert opportunityEOI;
        
        try {
            ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(null, acc.Id, opp.Id, 'Credit Card');
            receiptAcknowledgement.OpportunityEOI__c = opportunityEOI.Id;
            insert receiptAcknowledgement;
            
            //ShareHelper.shareReceiptAcknowledgement(new List<ReceiptAcknowledgement__c>{receiptAcknowledgement}, Constants.READ_ACCESS);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareServiceRequestBrokerManager() {
        Test.startTest();
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Broker Manager']; 
        UserRole r = [Select Id, name From UserRole Where Name LIKE '%Broker Relations Manager%' limit 1];
        
        User userRecord1 = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        
        User u;
        System.runAs(userRecord1) {
            
            u = new User(Alias = 'standt', Email='sampleemail@aldar.com', 
                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                         LocaleSidKey='en_US', ProfileId = p.Id, 
                         TimeZoneSidKey='Asia/Dubai', UserName='testbrokercreation@aldar.com', UserRoleId=r.Id);
            
            insert u;
        }
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        SR.BrokerManager__c = u.Id;
        insert SR;
        
        ShareHelper.shareServiceRequestBrokerManager(new List<HexaBPM__Service_Request__c>{SR}, Constants.READ_ACCESS);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testShareAccountWithAgents() {
        Test.startTest();
        
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        
        Contact con1 = TestObjectsFactory.contactDataSetup(accountRecord.Id);
        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
        
        Map<Id, Id> agentsChangedAccountIds = new Map<Id, Id>();
        
        agentsChangedAccountIds.put(accountRecord.Id, con.Id);
        ShareHelper.shareAccountRecordWhenBrokerAgentChanged(agentsChangedAccountIds, Constants.READ_ACCESS);
        
        User userRecord1 = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        Profile p = [SELECT Id FROM Profile WHERE Name='Agency Admin'];
        
        User u;
        System.runAs(userRecord1) {
            
            u = new User(Alias = 'standt', Email='sampleemail@aldar.com', 
                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                         LocaleSidKey='en_US', ProfileId = p.Id, 
                         TimeZoneSidKey='Asia/Dubai', UserName='testbrokercreation@aldar.com', ContactId=con.Id);
            
            insert u;
        }
        
        Map<Id, Id> AccountIdWithagencyAdmin = new Map<Id, Id>();
        AccountIdWithagencyAdmin.put(accountRecord.Id, u.Id);
        ShareHelper.shareAccountRecordWithNewAgentCreated(AccountIdWithagencyAdmin, Constants.READ_ACCESS);
        
        Test.stopTest();
    }
    @isTest
    public static void testSASharing() {
        FSL.GlobalAPIS.addStatusTransition('New', 'Closed');
        // FSL.GlobalAPIS.addStatusTransition(fromStatus, toStatus);
        Account testAccount = TestObjectsFactory.getPersonAccountRecord();
        insert testAccount;
        // Account testAccount = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        //testAccount.OwnerId  = UserInfo.getUserId();
        //testAccount.MobileNumber__c = '123456789';
        //insert testAccount;   
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        
        User salesManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaythakurSM1');
        salesManager.IsActive = TRUE;
        insert salesManager;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        project.CommunityName__c = 'Noya';
        insert project;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Project__c = project.id;
        unit2.Status__c = 'New';
        unit2.AssignedToUser__c = salesManager.Id;
        unit2.LatitudeLongitude__Latitude__s=32.987650;
        unit2.LatitudeLongitude__Longitude__s=72.345678;
        insert unit2;               
        
    }
    
     @isTest
    public static void testShareOpportunityRecordEmpty() {
        Test.startTest();
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName='Prospecting', CloseDate=Date.today());
        insert opp;
        ShareHelper.shareOpportunityRecord(new List<Opportunity>{opp}, Constants.READ_ACCESS);
        Test.stopTest();
    }

    @isTest
    public static void testShareAccountRelatedToOpportunityEmpty() {
        Test.startTest();
        Opportunity opp = new Opportunity(Name = 'NoAccOpp', StageName='Prospecting', CloseDate=Date.today());
        insert opp;
        ShareHelper.shareAccountRelatedToOpportunity(new List<Opportunity>{opp}, Constants.READ_ACCESS);
        Test.stopTest();
    }
     @isTest
    public static void testShareSalesOrderBrokerManagerCatchBlock() {
        Test.startTest();
        // Pass empty SO list to force no sharing
        ShareHelper.shareSalesOrderBrokerManager(new List<SalesOrder__c>(), Constants.READ_ACCESS);
        Test.stopTest();
    }

    @isTest
    public static void testShareSalesOrderFABGroup() {
        Test.startTest();
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.CommunityName__c = 'Noya';
        insert project;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        unit2.Project__c = project.id;
        unit2.Status__c = 'New';
        unit2.LatitudeLongitude__Latitude__s=32.987650;
        unit2.LatitudeLongitude__Longitude__s=72.345678;
        insert unit2;
        
        Opportunity opp = new Opportunity( Name='OppTest',StageName='Prospecting',Unit__c =unit2.Id , CloseDate=Date.today(),
                                          RMVerified__c = true);
        insert opp;
        SalesOrder__c so = new SalesOrder__c( Opportunity__c=opp.Id,Unit__c = unit2.Id);
        insert so;
        ShareHelper.shareSalesOrderFABGroup(new List<SalesOrder__c>{so}, Constants.READ_ACCESS);
        Test.stopTest();
    }

    @isTest
    public static void shareServiceRequestTest(){
        Test.startTest();
        HexaBPM__Service_Request__c serviceRequest1 = new HexaBPM__Service_Request__c();
        List<HexaBPM__Service_Request__c> serviceRequests = new List<HexaBPM__Service_Request__c>();
        serviceRequests.add(serviceRequest1);
        ShareHelper.shareServiceRequest(serviceRequests,'Read');
        Test.stopTest();
    }

}