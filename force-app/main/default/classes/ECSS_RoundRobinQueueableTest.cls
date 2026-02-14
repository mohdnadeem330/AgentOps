@isTest
public class ECSS_RoundRobinQueueableTest {
    
    @testSetup
    static void setupTestData() {
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            Asset testAsset = new Asset(
                Name = 'Test Asset',
                ExternalIdentifier = 'AssetExtId123'
            );
            insert testAsset;
            
            Round_Robin_User__c user1 = new Round_Robin_User__c(
                Assigned_User__c = UserInfo.getUserId(),
                Available__c = true,
                Counter__c = 0
            );
            insert user1;
            
            Round_Robin_User__c user2 = new Round_Robin_User__c(
                Assigned_User__c = UserInfo.getUserId(),
                Available__c = true,
                Counter__c = 1
            );
            insert user2;
            
            Assignment_Engine__c engine = new Assignment_Engine__c(
                No_Criteria__c = true
            );
            insert engine;
            
            Round_Robin_Engine_Assignment__c assignment1 = new Round_Robin_Engine_Assignment__c(
                Round_Robin_User__c = user1.Id,
                Assignment_Engine__c = engine.Id
            );
            insert assignment1;
            
            Round_Robin_Engine_Assignment__c assignment2 = new Round_Robin_Engine_Assignment__c(
                Round_Robin_User__c = user2.Id,
                Assignment_Engine__c = engine.Id
            );
            insert assignment2;
            
            Case testCase = TestObjectsFactory.getProvisCase(newAccount);
            testCase.AssetId = testAsset.Id;
            insert testCase;
            
        }
    }
    
    @isTest
    static void testExecute() {
        List<Case> cases = [SELECT Id, AssetId, OwnerId FROM Case LIMIT 1];
        Case testCase = cases[0];
        List<Assignment_Engine__c> engines = [SELECT Id, No_Criteria__c,Criteria__c FROM Assignment_Engine__c LIMIT 1];
        List<String> caseIds = new List<String>{testCase.Id};
            List<String> compIds = new List<String>();
        List<String> combinedCompIds = new List<String>();
        Boolean checkManager = false;
        
        Test.startTest();
        System.enqueueJob(new ECSS_RoundRobinQueueable('Case', caseIds, engines, compIds, combinedCompIds, checkManager));
        
        Test.stopTest();
        
        // Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id LIMIT 1];
        // System.assertNotEquals(null, updatedCase.OwnerId, 'The case should be assigned to a user.');
    }
    @isTest
    static void testExecute2() {
        
        Assignment_Engine__c engine = new Assignment_Engine__c(
            No_Criteria__c = true,
            object_name__c = 'Lead'
        );    
        Test.startTest();
        insert engine;
        Lead testLead = TestObjectsFactory.getLeadRecord(1,'ECSS');
        insert testLead;
        
        
        List<Assignment_Engine__c> engines = [SELECT Id, No_Criteria__c,Criteria__c FROM Assignment_Engine__c LIMIT 1];
        List<String> leadIds = new List<String>{testLead.Id};
            List<String> compIds = new List<String>();
        List<String> combinedCompIds = new List<String>();
        Boolean checkManager = false;
        
        System.enqueueJob(new ECSS_RoundRobinQueueable('Lead', leadIds, engines, compIds, combinedCompIds, checkManager));
        
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testUpdate() {
        
        Assignment_Engine__c engine = new Assignment_Engine__c(
            No_Criteria__c = true,
            object_name__c = 'Lead'
        );    
        Test.startTest();
        insert engine;
        Lead testLead = TestObjectsFactory.getLeadRecord(1,'ECSS');
        testLead.MobileCountryCode__c = '20';
        testLead.MobilePhone = '01062156646'; // Set phone before insert
        
        insert testLead;
        
        
        List<Assignment_Engine__c> engines = [SELECT Id, No_Criteria__c,Criteria__c FROM Assignment_Engine__c LIMIT 1];
        List<String> leadIds = new List<String>{testLead.Id};
            List<String> compIds = new List<String>();
        List<String> combinedCompIds = new List<String>();
        Boolean checkManager = false;
        
        Test.stopTest();
        
        
    }
    @isTest
    static void testUpdateNoRR() {
        User testUser = [select id,ECSS_SalesAgent__c from user where email='testuser@example.com'];
        testUser.ECSS_SalesAgent__c = true;
        update testUser;
        System.runAs(testUser) {
            Assignment_Engine__c engine = new Assignment_Engine__c(
                No_Criteria__c = true,
                object_name__c = 'Lead'
            );    
            Test.startTest();
            insert engine;
            Lead testLead = TestObjectsFactory.getLeadRecord(1,'ECSS');
            
            insert testLead;
            
            
            List<Assignment_Engine__c> engines = [SELECT Id, No_Criteria__c,Criteria__c FROM Assignment_Engine__c LIMIT 1];
            List<String> leadIds = new List<String>{testLead.Id};
                List<String> compIds = new List<String>();
            List<String> combinedCompIds = new List<String>();
            Boolean checkManager = false;
            
            Test.stopTest();
            
        }
    }
}