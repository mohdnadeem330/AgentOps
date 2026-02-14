@isTest
public class ResaleOpportunityValidationTest {
    @TestSetup
    static void makeData(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
        
        Account seller = TestObjectsFactory.getPersonAccountRecord();
        seller.MaritalStatus__pc = 'Single';
        insert seller;
        
        Account buyer = TestObjectsFactory.getPersonAccountRecord();
        buyer.MaritalStatus__pc = 'Single';
        insert buyer;
        
        Lead objLead1 = TestObjectsFactory.getLeadRecord(1,'Person');
        objLead1.agencyName__c = 'Address Point Properties L.L.C';
        objLead1.agentName__c = 'Brooke Reynolds';
        objLead1.offer1__c = '2020 Free for 3 offer';
        insert objLead1;
        
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today().addDays(7);
        unit.ResaleListed__c = true;
        unit.Listing_Price__c = 5000;
        insert unit;
        
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(seller.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;    
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.id, seller.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = seller.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(buyer.Id);
        opp2.Name = 'TestResale';
        opp2.OwnerManger__c = UserInfo.getUserId();
        opp2.SalesOrder__c = salesOrder.id;
        opp2.Lead_Type__c = 'Resale';
        opp2.Unit__c = unit.id;
        opp2.Seller__c = seller.Id;
        insert opp2;
    }

    @IsTest
    static void methodName(){
        Opportunity opp = [SELECT Id, AccountId, Seller__c, SecurityDepositReceived__c, SecurityDepositReceivedBuyer__c FROM Opportunity WHERE Lead_Type__c = 'Resale' LIMIT 1];
        
        ResaleOpportunityValidationHelper.Request req = new ResaleOpportunityValidationHelper.Request();
        req.oppRec = opp;

        Test.startTest();
        List<ResaleOpportunityValidationHelper.Result> results = ResaleOpportunityValidationHelper.validateOpportunity(new List<ResaleOpportunityValidationHelper.Request>{req});
        Test.stopTest();
    }
}