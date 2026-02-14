@isTest
public with sharing class ResaleListingExpiryBatchTest {
    @TestSetup
    static void makeData(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);

        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.MaritalStatus__pc = 'Single';
        insert newAccount;

        List<Unit__c> units = new List<Unit__c>();
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < 10; i++){
            Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
            unit.Status__c = 'Sold';
            unit.CompletionDate__c = System.today().addDays(7);
            units.add(unit);

            Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
            opp.OwnerManger__c = UserInfo.getUserId();
            opps.add(opp);
        }

        insert units;
        insert opps;

        List<SalesOrder__c> sos = new List<SalesOrder__c>();
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < 10; i++){
            SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opps[i].Id, newAccount.Id);
            so.Unit__c = units[i].Id;
            so.IsBookingCompleted__c = true;
            so.NetAmount__c = 100000;
            so.Account__c = newAccount.Id;
            so.Status__c = 'Sold';
            sos.add(so);

            Case rc = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', units[i].Id, '800-Aldar');
            cases.add(rc);
        }
        insert sos;
        insert cases;

        for(Case cs: cases){
            cs.CustomerContacted__c = true;
            cs.Status = 'Property Listed';
            cs.VerifiedByAdmin__c = true;
            cs.Expiry_Date__c = System.today().addDays(-1);
        }
        update cases;
    }

    @IsTest
    static void testBatchable(){
        Test.startTest();
            Id batchprocessid = Database.executeBatch(new ResaleListingExpiryBatch(), 50);            
        Test.stopTest();
    }

    @IsTest
    static void testSchedulable(){
        String cron = '0 0 0 15 3 ?';

        Test.startTest();
            String jobId = System.schedule('Test my class', cron, new ResaleListingExpiryBatch());            
        Test.stopTest();
    }
}