@IsTest
public class Soho_CreateListingTest {

    @TestSetup
    static void makeData(){
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        buildingSection.CompletionCertificateDate__c = Date.today().addMonths(8); 
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today().addDays(7);
        insert unit;
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.MaritalStatus__pc = 'Single';
        insert newAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        User admin = TestObjectsFactory.getUserRecord('System Administrator', 'admin');
        admin.FirstName = 'Admin';
        insert admin;

        List<User> users = new List<User>(); 
        
        User user_CCA = TestObjectsFactory.getUserRecord('Contact Centre Agent', 'CCA1');
        user_CCA.FirstName = 'CCA1';
        users.add(user_CCA);
        
        User user_SM = TestObjectsFactory.getUserRecord('Sales Manager', 'SM1');
        user_SM.FirstName = 'SM1';
        users.add(user_SM);

        User user_RM = TestObjectsFactory.getUserRecord('Resale Relationship Manager', 'RM1');
        user_RM.FirstName = 'RM1';
        user_RM.ManagerId = admin.Id;
        users.add(user_RM);

        insert users;
    }

    @isTest
    public static void testCreateListingMethod(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c, Unit__r.BuildingSectionName__r.CompletionCertificateDate__c FROM SalesOrder__c LIMIT 1][0];
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        TriggerHandler.processedIds = new Set<Id>();
        Test.startTest();
            insert resaleCase;
            String reqBody = JSON.serialize(resaleCase).replace('Id', 'Description');
            TestObjectsFactory.initializeRestContext(reqBody, '/createListing');       
            Soho_CreateListing.createListing();
        Test.stopTest();
    }
    @isTest
    public static void testCreateListingMethodSecond(){
        Test.startTest();
        String reqBody = '{ "Subject":"Test Subject", "Description":"Test Description", "Status":"New"}';
        TestObjectsFactory.initializeRestContext('', '/createListing');       
        Soho_CreateListing.createListing();
        Test.stopTest();
    }
    @isTest
    public static void testCreateListingMethodDMLException(){
        Test.startTest();
        String reqBody = '{ "Subject":"Test Subject", "Description":"Test Description", "Status":"New"}';
        TestObjectsFactory.initializeRestContext(null, '/createListing');       
        Soho_CreateListing.createListing();
        Test.stopTest();
    }
    @isTest
    public static void testCreateListingMethodException(){
        Test.startTest();
        TestObjectsFactory.initializeRestContext(null, '/createListing');       
        Soho_CreateListing.createListing();
        Test.stopTest();
    }
}