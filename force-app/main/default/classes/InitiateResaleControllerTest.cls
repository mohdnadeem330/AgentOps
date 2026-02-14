@isTest
public with sharing class InitiateResaleControllerTest {
    @TestSetup
    static void makeData(){
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
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
        
        List<User> users = new List<User>(); 
        
        User user_CCA = TestObjectsFactory.getUserRecord('Contact Centre Agent', 'CCA1');
        user_CCA.FirstName = 'CCA1';
        users.add(user_CCA);
        
        User user_RM = TestObjectsFactory.getUserRecord('Resale Relationship Manager', 'RM1');
        user_RM.FirstName = 'RM1';
        users.add(user_RM);

        User user_SM = TestObjectsFactory.getUserRecord('Sales Manager', 'SM1');
        user_SM.FirstName = 'SM1';
        users.add(user_SM);

        insert users;
    }
    
    @IsTest
    static void getRecordDetails_test_success(){
        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        
        Map<String, Object> returnMap = new Map<String, Object>();
        Test.startTest();
            returnMap = InitiateResaleController.getRecordDetails(so.Id);
        Test.stopTest();
    }

    @IsTest
    static void getRecordDetails_test_success_as_cca(){
        User contextuser = [SELECT Id FROM User WHERE Name = 'CCA1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        
        Map<String, Object> returnMap = new Map<String, Object>();
        Test.startTest();
            System.runAs(contextuser){
                returnMap = InitiateResaleController.getRecordDetails(so.Id);
            }
        Test.stopTest();
        Assert.areEqual('In Progress', returnMap.get('status'));
    }

    @IsTest
    static void getRecordDetails_test_success_as_rm(){
        User contextuser = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        
        Map<String, Object> returnMap = new Map<String, Object>();
        Test.startTest();
            System.runAs(contextuser){
                returnMap = InitiateResaleController.getRecordDetails(so.Id);
            }
        Test.stopTest();
        Assert.areEqual('In Progress', returnMap.get('status'));
    }

    @IsTest
    static void getRecordDetails_test_success_as_sm(){
        User contextuser = [SELECT Id FROM User WHERE Name = 'SM1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        
        Map<String, Object> returnMap = new Map<String, Object>();
        Test.startTest();
            System.runAs(contextuser){
                returnMap = InitiateResaleController.getRecordDetails(so.Id);
            }
        Test.stopTest();
        Assert.areEqual('New', returnMap.get('status'));
        Assert.areEqual(contextuser.Id, returnMap.get('salesManagerId'));
    }

    @IsTest
    static void getRecordDetails_test_fail1(){
        Map<String, Object> returnMap = new Map<String, Object>();
        Boolean auraEx = false;
        Boolean otherEx = false;
        Test.startTest();
            try {
                returnMap = InitiateResaleController.getRecordDetails('a2A8d000001X6R1EAK');
            } catch (AuraHandledException ex) {
                auraEx = true;
            } catch (Exception ex) {
                otherEx = true;
            }
        Test.stopTest();
        Assert.isTrue(auraEx);
        Assert.isfalse(otherEx);
    }

    @IsTest
    static void getRecordDetails_test_fail2(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
        
        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;

        Map<String, Object> returnMap = new Map<String, Object>();
        Boolean auraEx = false;
        Boolean otherEx = false;
        Test.startTest();
            try {
                returnMap = InitiateResaleController.getRecordDetails(so.Id);
            } catch (AuraHandledException ex) {
                auraEx = true;
            } catch (Exception ex) {
                otherEx = true;
            }
        Test.stopTest();
        Assert.isTrue(auraEx);
        Assert.isfalse(otherEx);
    }
}