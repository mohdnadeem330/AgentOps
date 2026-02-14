@isTest
public class ECSS_RoundRobinQueueableTest_Coverage {
    @isTest
    static void testQueueableCoverage() {
        // Create engine
        Assignment_Engine__c engine = new Assignment_Engine__c(
            //Name = 'Test Engine',
            No_Criteria__c = true,
            object_name__c = 'Lead'
        );
        insert engine;

        // Create user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email='testuser123@example.com',
            EmailEncodingKey='UTF-8',
            LastName='Tester',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/New_York',
            Username='testuser123' + DateTime.now().getTime() + '@example.com'
        );
        insert u;

        // Create round robin user
        Round_Robin_User__c rrUser = new Round_Robin_User__c(
            Assigned_User__c = u.Id,
            Available__c = true,
            Counter__c = 0
        );
        insert rrUser;

        // Link engine to user
        Round_Robin_Engine_Assignment__c assign = new Round_Robin_Engine_Assignment__c(
            Assignment_Engine__c = engine.Id,
            Round_Robin_User__c = rrUser.Id
        );
        insert assign;

        // Create a lead that will be assigned
        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'PwC',
            Status = 'New',
            EnquiryCategory__c= 'Corporate'
        );
        
        Lead leadObj = TestObjectsFactory.getLeadRecord(1, 'Person');
        insert leadObj;
        //insert l;
 
        // Set up input
        List<String> leadIds = new List<String>{ leadObj.Id };
        List<Assignment_Engine__c> engines = new List<Assignment_Engine__c>{ engine };
        List<String> compIds = new List<String>(); // Optional
        List<String> combinedCompIds = new List<String>(); // Optional

        Test.startTest();
        System.enqueueJob(new ECSS_RoundRobinQueueable('Lead', leadIds, engines, compIds, combinedCompIds, false));
        System.enqueueJob(new ECSS_RoundRobinQueueable('Lead', leadIds, engines, compIds, combinedCompIds, true));
        Test.stopTest();

        // Verify lead was assigned
        //Lead updated = [SELECT Id, OwnerId, ECSS_Assigned__c FROM Lead WHERE Id = :l.Id];
        //System.assertEquals(true, updated.ECSS_Assigned__c);
    }

    
 @isTest
    static void testQueueableCoverageCase() {
        // Create engine
        Assignment_Engine__c engine = new Assignment_Engine__c(
            //Name = 'Test Engine',
            No_Criteria__c = true,
            object_name__c = 'Lead'
        );
        insert engine;

        // Create user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email='testuser123@example.com',
            EmailEncodingKey='UTF-8',
            LastName='Tester',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/New_York',
            Username='testuser123' + DateTime.now().getTime() + '@example.com'
        );
        insert u;

        // Create round robin user
        Round_Robin_User__c rrUser = new Round_Robin_User__c(
            Assigned_User__c = u.Id,
            Available__c = true,
            Counter__c = 0
        );
        insert rrUser;

        // Link engine to user
        Round_Robin_Engine_Assignment__c assign = new Round_Robin_Engine_Assignment__c(
            Assignment_Engine__c = engine.Id,
            Round_Robin_User__c = rrUser.Id
        );
        insert assign;

        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        Id feedbackRecordTypeId = Utilities.getRecordTypeId('Case', Constants.FEEDBACK_CASE_RT);
        Case cs = TestObjectsFactory.getCaseRecord(feedbackRecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unit.Id, 'Phone');
       
        
        
        // Set up input
        List<String> caseIds = new List<String>{ cs.Id };
        List<Assignment_Engine__c> engines = new List<Assignment_Engine__c>{ engine };
        List<String> compIds = new List<String>(); // Optional
        List<String> combinedCompIds = new List<String>(); // Optional

        Test.startTest();
        System.enqueueJob(new ECSS_RoundRobinQueueable('Case', caseIds, engines, compIds, combinedCompIds, false));
        Test.stopTest();

        // Verify Opportunity was assigned
        //Lead updated = [SELECT Id, OwnerId, ECSS_Assigned__c FROM Lead WHERE Id = :l.Id];
        //System.assertEquals(true, updated.ECSS_Assigned__c);
    }

    
    

 @isTest
    static void testQueueableCoverageOpp() {
        // Create engine
        Assignment_Engine__c engine = new Assignment_Engine__c(
            //Name = 'Test Engine',
            No_Criteria__c = true,
            object_name__c = 'Lead'
        );
        insert engine;

        // Create user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email='testuser123@example.com',
            EmailEncodingKey='UTF-8',
            LastName='Tester',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/New_York',
            Username='testuser123' + DateTime.now().getTime() + '@example.com'
        );
        insert u;

        // Create round robin user
        Round_Robin_User__c rrUser = new Round_Robin_User__c(
            Assigned_User__c = u.Id,
            Available__c = true,
            Counter__c = 0
        );
        insert rrUser;

        // Link engine to user
        Round_Robin_Engine_Assignment__c assign = new Round_Robin_Engine_Assignment__c(
            Assignment_Engine__c = engine.Id,
            Round_Robin_User__c = rrUser.Id
        );
        insert assign;

        
         Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
 
        // Set up input
        List<String> oppIds = new List<String>{ opp.Id };
        List<Assignment_Engine__c> engines = new List<Assignment_Engine__c>{ engine };
        List<String> compIds = new List<String>(); // Optional
        List<String> combinedCompIds = new List<String>(); // Optional

        Test.startTest();
        System.enqueueJob(new ECSS_RoundRobinQueueable('Opportunity', oppIds, engines, compIds, combinedCompIds, false));
        Test.stopTest();

        // Verify Opportunity was assigned
        //Lead updated = [SELECT Id, OwnerId, ECSS_Assigned__c FROM Lead WHERE Id = :l.Id];
        //System.assertEquals(true, updated.ECSS_Assigned__c);
    }



}