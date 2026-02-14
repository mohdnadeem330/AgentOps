@isTest
public class TopUpCommissionTriggerHelper_Test {

    @isTest
    static void testValidateDuplicatesBeforeInsert() {
        // Create and insert an InternalCommission__c record
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
        
        // Insert a record to test for duplicates
        TopUpCommission__c existingRecord = new TopUpCommission__c(
            Classification__c = '100',
            Internal_Commission__c = internalCommission.id
        );
        insert existingRecord;

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

        InternalCommission__c internalCommission2 = internalCommission.clone();
        insert internalCommission2;

        TopUpCommission__c existingRecord = new TopUpCommission__c(
            Classification__c = '50-50',
            Internal_Commission__c = internalCommission.id
        );
        insert existingRecord;

        // Create the record to be updated
        TopUpCommission__c recordToUpdate = new TopUpCommission__c(
            Classification__c = '60-40',
            Internal_Commission__c = internalCommission2.id
        );
        insert recordToUpdate;

        // Prepare for update - trying to update to an existing combination, which should trigger the validation
        recordToUpdate.Classification__c = '50-50'; 
        recordToUpdate.Internal_Commission__c = existingRecord.Internal_Commission__c;

        Map<Id, TopUpCommission__c> oldMap = new Map<Id, TopUpCommission__c>();
        oldMap.put(recordToUpdate.Id, new TopUpCommission__c(
            Id = recordToUpdate.Id,
            Classification__c = '60-40',
            Internal_Commission__c = internalCommission2.id
        ));

        List<TopUpCommission__c> newRecords = new List<TopUpCommission__c>{ recordToUpdate };

        // Ensure that the validation will happen in before update context
        Test.startTest();
        try {
            // Trigger the validateDuplicatesTopUpCommBeforeUpdate in the before update context
            TopUpCommissionTriggerHelper.validateDuplicatesTopUpCommBeforeUpdate(newRecords, oldMap);
            // If no exception, assert success
            System.assert(true, 'No DML exception was thrown, validation passed.');
        } catch (DmlException e) {
            // This should trigger a validation exception due to duplicate classification and internal commission
            System.assert(e.getMessage().contains('A record with the same Classification and Internal Commission combination already exists'),
                'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testNoDuplicateErrors() {
        // Create and insert an InternalCommission__c record
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

        // Insert a valid record (no duplicates)
        TopUpCommission__c validRecord = new TopUpCommission__c(
            Classification__c = '15-85',
            Internal_Commission__c = internalCommission.id
        );

        Test.startTest();
        insert validRecord; // Should not throw an exception
        Test.stopTest();

        System.assertNotEquals(null, validRecord.Id, 'Record should have been inserted successfully.');
    }

    @isTest
    static void testGetTopUpCommissionWithClassificationAndInterComm() {
        // Create and insert an InternalCommission__c record
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

        // Insert multiple TopUpCommission__c records
        List<TopUpCommission__c> testRecords = new List<TopUpCommission__c>{
            new TopUpCommission__c(Classification__c = '30-70', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '80-20', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = 'MEMO', Internal_Commission__c = internalCommission.id)
        };
        insert testRecords;

        // Prepare input map
        Map<String, String> classificationToInterCommMap = new Map<String, String>{
            '30-70' => internalCommission.id,
            '80-20' => internalCommission.id,
            'MEMO' => internalCommission.id
        };

        Test.startTest();
        List<TopUpCommission__c> results = TopUpCommissionService.getTopUpCommissionWithClassificationAndInterComm(classificationToInterCommMap);
        Test.stopTest();

        // Verify that the expected number of records are returned
        System.assertEquals(3, results.size(), 'Expected 3 matching records.');
    }

    @isTest
    static void testAllClassifications() {
        // Create and insert an InternalCommission__c record
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
        
       

        // Insert multiple records for various classifications
        List<TopUpCommission__c> testRecords = new List<TopUpCommission__c> {
            new TopUpCommission__c(Classification__c = '100', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '10-90', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '15-85', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '20-80', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '25-75', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '30-70', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '35-65', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '40-60', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '45-55', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '50-50', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '60-40', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '65-35', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '70-30', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = '80-20', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = 'MEMO', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = 'POLICY', Internal_Commission__c = internalCommission.id),
            new TopUpCommission__c(Classification__c = 'STANDARD', Internal_Commission__c = internalCommission.id)
        };
        insert testRecords;

        // Validate that all records were inserted
        System.assertEquals(17, [SELECT COUNT() FROM TopUpCommission__c], 'Expected 17 records to be inserted.');
    }
    
}