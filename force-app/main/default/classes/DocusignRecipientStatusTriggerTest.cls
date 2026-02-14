@isTest
public class DocusignRecipientStatusTriggerTest {

    @testSetup
    private static void setupData() {
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;
        
        Account relatedAccount = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert relatedAccount;
        
        Account relatedAccount1 = TestObjectsFactory.getOrganisationAccountRecord('companyName1', 'registrationNo1');
        insert relatedAccount1;
        
        Contact con = TestObjectsFactory.contactDataSetup(account.Id);
        
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
        unit.AffectionPlan__c = 'www.google.com';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        insert salesOrder;

        
        List<dfsle__RecipientStatus__c> newList = new List<dfsle__RecipientStatus__c>();
        Map<Id,dfsle__RecipientStatus__c> oldMapList = new Map<Id,dfsle__RecipientStatus__c>();   
        Document__c spaDoc = TestObjectsFactory.getSalesOrderDocument(opp.Id,salesOrder.Id);
        spaDoc.DocumentType__c = 'Sales Offer';
        insert spaDoc;
        
        dfsle__EnvelopeStatus__c es = new dfsle__EnvelopeStatus__c();
        es.dfsle__DocuSignId__c = '1234TEST-83ef-47b6-bc4e-123411111111';
        es.dfsle__EmailSubject__c= 'SARAN TEST SUB';
        es.dfsle__Sent__c = System.now();
        es.dfsle__Expires__c = System.now().addDays(1);
        es.dfsle__Reason__c = 'test';
        es.dfsle__SenderEmail__c = 'saran@aldar.com';
        es.dfsle__SenderName__c = 'Saran';
        es.dfsle__Status__c = 'Sent';
        es.dfsle__SourceId__c = spaDoc.Id;
        insert es;
        
        System.debug('es Id -> '+es.Id);
        dfsle__RecipientStatus__c rs = new dfsle__RecipientStatus__c();
        rs.dfsle__Status__c = 'Sent';
        rs.dfsle__Email__c = 'saran@aldar.com';
        rs.dfsle__RoutingOrder__c = 1;
        rs.dfsle__EnvelopeStatus__c = es.Id;
        rs.dfsle__SourceId__c = spaDoc.Id;
        //rs.EnvelopeId__c = '08993507-f57b-4e3c-9bfe-09e5b1144c35';
        newList.add(rs);
        
        dfsle__RecipientStatus__c rs2 = new dfsle__RecipientStatus__c();
        rs2.dfsle__Status__c = 'Sent';
        rs2.dfsle__Email__c = 'saran2@aldar.com';
        rs2.dfsle__RoutingOrder__c = 21;
        rs2.dfsle__EnvelopeStatus__c = es.Id;
        rs2.dfsle__SourceId__c = spaDoc.Id;
        newList.add(rs2);
        
        insert newList;
		//DocusignRecipientTriggerHelper.updateSalesOrder((List<dfsle__RecipientStatus__c>) trigger.new, (Map<Id,dfsle__RecipientStatus__c>) trigger.oldMap );
    }
    
    @isTest
    private static void testDocuSignReceipientStatus() {
        List<dfsle__RecipientStatus__c> newList = new List<dfsle__RecipientStatus__c>();

        List<dfsle__RecipientStatus__c> rsList = [SELECT Id, dfsle__RoutingOrder__c FROM dfsle__RecipientStatus__c WHERE (dfsle__Email__c = 'saran@aldar.com' OR dfsle__Email__c = 'saran2@aldar.com') LIMIT 10];
        for(dfsle__RecipientStatus__c rs : rsList) {
            if(rs.dfsle__RoutingOrder__c == 1){
                rs.dfsle__Status__c = 'Completed';
                newList.add(rs);
                
            }
            System.debug('rs dfsle__RoutingOrder__c 1 --> '+rs.dfsle__RoutingOrder__c);
            //            rs.dfsle__Status__c = 'Completed';
            ///         	rs.dfsle__RoutingOrder__c = 20;   
            System.debug('rs dfsle__RoutingOrder__c 2 --> '+rs.dfsle__RoutingOrder__c);
            System.debug('rs id --> '+rs.Id);
        }
        Test.startTest();
        update newList;
        Test.stopTest();
    }
    
    @isTest
    private static void testDocuSignReceipientStatusException() {
        List<dfsle__RecipientStatus__c> newList = new List<dfsle__RecipientStatus__c>();

        List<dfsle__RecipientStatus__c> rsList = [SELECT Id, dfsle__RoutingOrder__c FROM dfsle__RecipientStatus__c WHERE (dfsle__Email__c = 'saran@aldar.com' OR dfsle__Email__c = 'saran2@aldar.com') LIMIT 10];
        for(dfsle__RecipientStatus__c rs : rsList) {
            System.debug('rs dfsle__RoutingOrder__c 1 --> '+rs.dfsle__RoutingOrder__c);
            rs.dfsle__Status__c = 'Completed';
         	rs.dfsle__RoutingOrder__c = 21;   
            System.debug('rs dfsle__RoutingOrder__c 2 --> '+rs.dfsle__RoutingOrder__c);
            System.debug('rs id --> '+rs.Id);
            newList.add(rs);
        }
        Test.startTest();
        DocusignRecipientTriggerHelper.GET_EXCEPTION = true;
        update newList;
        Test.stopTest();
    }
}