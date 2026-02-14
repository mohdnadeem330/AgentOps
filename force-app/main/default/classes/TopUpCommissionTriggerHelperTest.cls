@isTest
public class TopUpCommissionTriggerHelperTest{
    // Test setup for reusable data
    @testSetup
    static void setupTestData() {
        // Insert an InternalCommission__c record
        InternalCommission__c internalCommission = new InternalCommission__c(
            DirectCommission__c = 2.5,
            IndirectCommission__c = 1.5,
            LandDirectCommission__c = 2.0,
            LandIndirectCommission__c = 1.0,
            StaffReferral__c = 2.5,
            VIPDirectCommission__c = 1.5,
            VIPIndirectCommission__c = 0.5,
            UserRole__c = 'Sales Manager',
            InventoryLaunchCategory__c = 'Launch',
            StartDate__c = Date.today(),
            EndDate__c = Date.today().addDays(30),
            SalesValueFrom__c = 0,
            SaleValueTo__c = 1000000000
        );
        insert internalCommission;

        // Insert a TopUpCommission__c record
        TopUpCommission__c existingRecord = new TopUpCommission__c(
            Classification__c = '100',
            Internal_Commission__c = internalCommission.Id
        );
        insert existingRecord;

        // Insert additional records for broader coverage
        List<TopUpCommission__c> testRecords = new List<TopUpCommission__c>{
            new TopUpCommission__c(Classification__c = '30-70', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '80-20', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = 'MEMO', Internal_Commission__c = internalCommission.id)
        };
        insert testRecords;
    }

    @isTest
    static void testValidateDuplicatesBeforeInsert() {
        // Get test data
        InternalCommission__c internalCommission = [SELECT Id FROM InternalCommission__c LIMIT 1];
        
        // Attempt to insert a duplicate record
        TopUpCommission__c duplicateRecord = new TopUpCommission__c(
            Classification__c = '100',
            Internal_Commission__c = internalCommission.id
        );

        Test.startTest();
        try {
            insert duplicateRecord;
            System.assert(false, 'Expected DMLException due to duplicate record.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A record with the same Classification and Internal Commission combination already exists'),
                'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateDuplicatesBeforeUpdate() {
        // Fetch records
        InternalCommission__c internalCommission = [SELECT Id FROM InternalCommission__c LIMIT 1];
        TopUpCommission__c existingRecord = [SELECT Id, Classification__c FROM TopUpCommission__c LIMIT 1];

        // Insert a new record to update
        TopUpCommission__c recordToUpdate = new TopUpCommission__c(
            Classification__c = '60-40',
            Internal_Commission__c = internalCommission.id
        );
        insert recordToUpdate;

        // Update the record to create a duplicate scenario
        recordToUpdate.Classification__c = existingRecord.Classification__c;

        Test.startTest();
        try {
            update recordToUpdate;
            System.assert(false, 'Expected DMLException due to duplicate record.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A record with the same Classification and Internal Commission combination already exists'),
                'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testNoDuplicateErrors() {
        // Fetch data
        InternalCommission__c internalCommission = [SELECT Id FROM InternalCommission__c LIMIT 1];

        // Insert a valid record
        TopUpCommission__c validRecord = new TopUpCommission__c(
            Classification__c = '15-85',
            Internal_Commission__c = internalCommission.id
        );

        Test.startTest();
        insert validRecord; // Should not throw any exception
        Test.stopTest();

        System.assertNotEquals(null, validRecord.Id, 'Record should have been inserted successfully.');
    }

    @isTest
    static void testGetTopUpCommissionWithClassificationAndInterComm() {
        // Prepare input map
        Map<String, String> classificationToInterCommMap = new Map<String, String>{
            '30-70' => [SELECT Id FROM InternalCommission__c LIMIT 1].Id,
            '80-20' => [SELECT Id FROM InternalCommission__c LIMIT 1].Id,
            'MEMO' => [SELECT Id FROM InternalCommission__c LIMIT 1].Id
        };

        Test.startTest();
        List<TopUpCommission__c> results = TopUpCommissionService.getTopUpCommissionWithClassificationAndInterComm(classificationToInterCommMap);
        Test.stopTest();

        // Verify that the expected number of records are returned
        System.assertEquals(3, results.size(), 'Expected 3 matching records.');
    }

    @isTest
    static void testAllClassifications() {
        // Query inserted data
        List<TopUpCommission__c> records = [SELECT Classification__c FROM TopUpCommission__c];

        System.assert(records.size() > 0, 'Records should exist for classifications.');
     //   System.assert(records.contains(new TopUpCommission__c(Classification__c = '100')),            'Expected record with Classification__c = "100" to exist.');
    }
}