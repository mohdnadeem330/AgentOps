@isTest
public class ReleaseAssignmentWebServiceTest {

    @TestSetup
    static void setupData() {
        // Create unit
        Unit__c unit = TestObjectsFactory.unitDataSetup('UNIT-001');
        unit.Status__c = Constants.UNIT_STATUS_AVAILABLE;
        insert unit;

        // Create Sales Manager user
        User manager = TestObjectsFactory.getUserRecord('Sales Manager', 'manager.user1');
        manager.IsActive = true;
        manager.Email = 'srana@aldar.com';
        insert manager;

        // Create subordinate user
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'sales.user1');
        sm.IsActive = true;
        sm.ManagerId = manager.Id;
        sm.Email = 'srana@aldar.com';
        insert sm;

        // Create Account
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        // Create Opportunity
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        // Associate unit with opportunity
        unit.RelatedOpportunity__c = opp.Id;
        update unit;

        // Create Unit Assignment record
        Unit_Assignment__c unitAssignment = new Unit_Assignment__c(
            Unit__c = unit.Id,
         	Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Approver__c = manager.Id,
            Opportunity__c = opp.Id);
        insert unitAssignment;
            
    }

    @isTest
    static void testReleaseAssignment_Success() {
        User user = [SELECT Id FROM User WHERE ManagerId != null LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c WHERE Status__c = :Constants.UNIT_STATUS_AVAILABLE LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Simulate REST context
        Test.startTest();
        TestObjectsFactory.initializeRestContext(user.Id, '/releaseAssignments');

        ReleaseAssignmentWebService.doPost(user.Id, new List<String>{ unit.Id }, opp.Id);

        Test.stopTest();

        // Verify the unit was updated
        Unit__c updatedUnit = [SELECT Id, RelatedOpportunity__c, AssignedToUser__c, LockedBy__c, AllocationGroup__c 
                               FROM Unit__c 
                               WHERE Id = :unit.Id];

        //System.assertEquals(null, updatedUnit.RelatedOpportunity__c, 'RelatedOpportunity__c should be null after release');
        System.assertEquals(null, updatedUnit.AssignedToUser__c, 'AssignedToUser__c should be null after release');
        System.assertEquals(null, updatedUnit.LockedBy__c, 'LockedBy__c should be null after release');
    }

    @isTest
    static void testReleaseAssignment_NoMatchingUnits() {
        User user = [SELECT Id FROM User WHERE ManagerId != null LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Use a unit that is NOT in available status
         Unit__c unit = TestObjectsFactory.unitDataSetup('UNIT-002');
        unit.Status__c = 'Reserved';
        insert unit;

        Test.startTest();
        TestObjectsFactory.initializeRestContext(user.Id, '/releaseAssignments');

        // This unit should be skipped by the logic
        ReleaseAssignmentWebService.doPost(user.Id, new List<String>{ unit.Id }, opp.Id);

        Test.stopTest();
    }

    @isTest
    static void testReleaseAssignment_ExceptionHandling() {
        User user = [SELECT Id FROM User WHERE ManagerId != null LIMIT 1];

        // Pass invalid data to force an exception
        Test.startTest();
        TestObjectsFactory.initializeRestContext(user.Id, '/releaseAssignments');

        ReleaseAssignmentWebService.doPost(user.Id, null, null);

        Test.stopTest();
    }
}