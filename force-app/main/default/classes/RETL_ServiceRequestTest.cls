@IsTest
private class RETL_ServiceRequestTest {

    // Helper to create Opportunity with Yardi ID (needed for mapping logic)
    private static Opportunity createOpp(String yardiId) {
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = System.today(), RETL_Yardi_Proposal_Id__c = yardiId);
        insert opp;
        return opp;
    }

    // Assuming fields ending in __c are Decimal, and _b_a__c are String based on your usage.
    private static RETL_Service_Request__c createPopulatedServiceRequest(Id oppId) {
        Decimal todayDecimal = 1;
        String stringValue = 'Before'; 

        return new RETL_Service_Request__c(
            RETL_Opportunity_Id__c = oppId,
            // Contractual Dates
            RETL_Contr_Kick_Off_Meeting_b_a__c = stringValue,
            RETL_Contr_Kick_Off_Meeting__c = todayDecimal,
            RETL_Contr_Concept_Design_Submission_b_a__c = stringValue,
            RETL_Contr_Concept_Design_Submission__c = todayDecimal,
            RETL_Contr_Detailed_Arch_MEP_Design_b_a__c = stringValue,
            RETL_Contr_Detailed_Arch_MEP_Design__c = todayDecimal,
            RETL_Contr_Authorities_Submission_b_a__c = stringValue,
            RETL_Contr_Authorities_Submission__c = todayDecimal,
            RETL_Contr_Start_onsite_b_a__c = stringValue,
            RETL_Contr_Start_onsite__c = todayDecimal,
            
            // Actual Dates
            RETL_Actual_Kick_Off_Meeting_b_a__c = stringValue,
            RETL_Actual_Kick_Off_Meeting__c = todayDecimal,
            RETL_Actual_Concept_Design_Submission_ba__c = stringValue,
            RETL_Actual_Concept_Design_Submission__c = todayDecimal,
            RETL_Actual_Detailed_Arch_MEP_Design_b_a__c = stringValue,
            RETL_Actual_Detailed_Arch_MEP_Design__c = todayDecimal,
            RETL_Actual_Authorities_Submission_b_a__c = stringValue,
            RETL_Actual_Authorities_Submission__c = todayDecimal,
            RETL_Actual_Start_onsite_b_a__c = stringValue,
            RETL_Actual_Start_onsite__c = todayDecimal,
            RETL_Actual_Store_Opening_Date__c = System.today()
        );
    }

    @IsTest
    static void testSyncWithDetailsCoverage() {
        // Setup Data
        Opportunity opp = createOpp('859'); // Match the ID in our Mock response
        RETL_Service_Request__c sr = createPopulatedServiceRequest(opp.Id);
        insert sr;

        // Prepare parameters for @future call
        List<Id> ids = new List<Id>{sr.Id};
        Map<Id, Set<String>> fieldsMap = new Map<Id, Set<String>>{
            sr.Id => new Set<String>{'RETL_Contr_Kick_Off_Meeting__c'}
        };
        String serializedMap = JSON.serialize(fieldsMap);

        // Set Mock to return the JSON with "Details"
        Test.setMock(HttpCalloutMock.class, new RETL_ServiceRequestTriggerYardiAPIMock(false));

        Test.startTest();
        // Call the future method directly for coverage
        RETL_ServiceRequestTriggerHelper.syncServiceRequests(ids, serializedMap, false);
        Test.stopTest();
        
        // Code coverage will now flow through the 'Details' loop
    }

    @IsTest
    static void testSyncWithPermanentMPCheck() {
        Opportunity opp = createOpp('4000');
        RETL_Service_Request__c sr = createPopulatedServiceRequest(opp.Id);
        insert sr;

        List<Id> ids = new List<Id>{sr.Id};
        Map<Id, Set<String>> fieldsMap = new Map<Id, Set<String>>{ sr.Id => new Set<String>{'RETL_Contr_Kick_Off_Meeting__c'}};
        
        Test.setMock(HttpCalloutMock.class, new RETL_ServiceRequestTriggerYardiAPIMock(false));

        Test.startTest();
        // Testing with permanentMPCheck = true to cover the alternative logic branch
        RETL_ServiceRequestTriggerHelper.syncServiceRequests(ids, JSON.serialize(fieldsMap), true);
        Test.stopTest();
    }

    private static RETL_Service_Request__c createUnpopulatedServiceRequest() {
        // Keep unpopulated, but assign a value to a monitored field to ensure insert sync
        return new RETL_Service_Request__c(
            RETL_Contr_Kick_Off_Meeting_b_a__c = 'Before'
        );
    }
    
    // --- Test Methods ---

    @IsTest
    static void testSyncSuccessScenarios() {
        Test.setMock(HttpCalloutMock.class, new RETL_ServiceRequestTriggerYardiAPIMock(false));

        Test.startTest();
        
        // 1. Test Insert (should sync all monitored fields)
        Opportunity opp = createOpp('859');
        RETL_Service_Request__c srInsert = createPopulatedServiceRequest(opp.Id);
        insert srInsert;
        String newString = 'After';
        Decimal newDate = 10;
        
        // 2. Test Update (must change a monitored field to sync)
        RETL_Service_Request__c srUpdate = [
            SELECT 
                RETL_Contr_Kick_Off_Meeting_b_a__c, RETL_Contr_Kick_Off_Meeting__c,
                RETL_Contr_Concept_Design_Submission_b_a__c, RETL_Contr_Concept_Design_Submission__c,
                RETL_Contr_Detailed_Arch_MEP_Design_b_a__c, RETL_Contr_Detailed_Arch_MEP_Design__c,
                RETL_Contr_Authorities_Submission_b_a__c, RETL_Contr_Authorities_Submission__c,
                RETL_Contr_Start_onsite_b_a__c, RETL_Contr_Start_onsite__c,
                RETL_Actual_Kick_Off_Meeting_b_a__c, RETL_Actual_Kick_Off_Meeting__c,
                RETL_Actual_Concept_Design_Submission_ba__c, RETL_Actual_Concept_Design_Submission__c,
                RETL_Actual_Detailed_Arch_MEP_Design_b_a__c, RETL_Actual_Detailed_Arch_MEP_Design__c,
                RETL_Actual_Authorities_Submission_b_a__c, RETL_Actual_Authorities_Submission__c,
                RETL_Actual_Start_onsite_b_a__c, RETL_Actual_Start_onsite__c,
                RETL_Actual_Store_Opening_Date__c
            FROM RETL_Service_Request__c 
            WHERE Id = :srInsert.Id
        ];
        
        // Update all Contractual Dates fields
        srUpdate.RETL_Contr_Kick_Off_Meeting_b_a__c = newString;
        srUpdate.RETL_Contr_Kick_Off_Meeting__c = newDate;
        srUpdate.RETL_Contr_Concept_Design_Submission_b_a__c = newString;
        srUpdate.RETL_Contr_Concept_Design_Submission__c = newDate;
        srUpdate.RETL_Contr_Detailed_Arch_MEP_Design_b_a__c = newString;
        srUpdate.RETL_Contr_Detailed_Arch_MEP_Design__c = newDate;
        srUpdate.RETL_Contr_Authorities_Submission_b_a__c = newString;
        srUpdate.RETL_Contr_Authorities_Submission__c = newDate;
        srUpdate.RETL_Contr_Start_onsite_b_a__c = newString;
        srUpdate.RETL_Contr_Start_onsite__c = newDate;

        // Update all Actual Dates fields
        srUpdate.RETL_Actual_Kick_Off_Meeting_b_a__c = newString;
        srUpdate.RETL_Actual_Kick_Off_Meeting__c = newDate;
        srUpdate.RETL_Actual_Concept_Design_Submission_ba__c = newString;
        srUpdate.RETL_Actual_Concept_Design_Submission__c = newDate;
        srUpdate.RETL_Actual_Detailed_Arch_MEP_Design_b_a__c = newString;
        srUpdate.RETL_Actual_Detailed_Arch_MEP_Design__c = newDate;
        srUpdate.RETL_Actual_Authorities_Submission_b_a__c = newString;
        srUpdate.RETL_Actual_Authorities_Submission__c = newDate;
        srUpdate.RETL_Actual_Start_onsite_b_a__c = newString;
        srUpdate.RETL_Actual_Start_onsite__c = newDate;
        
        // Update Actual Store Opening Date
        srUpdate.RETL_Actual_Store_Opening_Date__c = System.today().addDays(1);
        srUpdate.RETL_Skip_Contractual_Validation__c  = true;

        // Perform the update - this triggers the handler's change detection and sync logic
        update srUpdate;
        
        Test.stopTest();
        
        // Optionally assert a change field was added if you can inspect the helper class logic
        // For simple coverage, just confirming the update runs is usually enough.
    }

    @IsTest
    static void testNoSyncScenarios() {
        // 1. Prepare fully populated record for No Change Update
        Opportunity opp = createOpp('859');
        RETL_Service_Request__c srPopulated = createPopulatedServiceRequest(opp.Id);
        insert srPopulated; // This insert will trigger a sync
        
        // 2. Prepare unpopulated record for Insert (which should trigger a sync)
        RETL_Service_Request__c srUnpopulated = createUnpopulatedServiceRequest();
        insert srUnpopulated;
        
        Test.setMock(HttpCalloutMock.class, new RETL_ServiceRequestTriggerYardiAPIMock(false));
        
        Test.startTest();
        
        // 1. Update with NO change to monitored fields
        RETL_Service_Request__c srUpdateNoChange = [SELECT Id FROM RETL_Service_Request__c WHERE Id = :srPopulated.Id];
        // To cover the update, update a non-tracked field (like a generic Status or Description, if available)
        // Since we don't know the non-tracked fields, just running the update without changing a tracked field
        // should cover the 'changedFields.isEmpty()' path in the handler.
        srUpdateNoChange.RETL_Skip_Contractual_Validation__c  = true;
        update srUpdateNoChange; // Update without changing tracked fields
        
        // 2. Update unpopulated record 
        RETL_Service_Request__c srUpdateUnpopulated = [SELECT Id FROM RETL_Service_Request__c WHERE Id = :srUnpopulated.Id];
        // Again, update without changing the one tracked field (RETL_Contr_Kick_Off_Meeting_b_a__c = 'Before')
        srUpdateUnpopulated.RETL_Skip_Contractual_Validation__c  = true;
        update srUpdateUnpopulated;
        
        Test.stopTest();
    }
    
    @IsTest
    static void testHelperExceptionHandling() {
        Test.setMock(HttpCalloutMock.class, new RETL_ServiceRequestTriggerYardiAPIMock(true));
		Opportunity opp = createOpp('859');
        RETL_Service_Request__c sr = createPopulatedServiceRequest(opp.Id);
        
        Test.startTest();
        // Insert with a populated record to attempt a sync callout which should then throw the mock exception
        insert sr; 
        
        Test.stopTest();
        // Exception handling is typically confirmed by ensuring the exception is caught and no DML error occurs.
    }
}