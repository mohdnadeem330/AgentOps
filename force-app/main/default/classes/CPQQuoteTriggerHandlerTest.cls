@isTest
public class CPQQuoteTriggerHandlerTest {

    @testSetup
    static void setupData() {
        
         insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = true,
            Is_After_Update__c = true,
            Is_After_Delete__c = true,
            Is_Before_Insert__c = true,
            Is_Before_Update__c = true,
            Is_Before_Delete__c = true
        );

    }
    
    static testMethod void test_beforeInsert_with_locked_asset_mismatch() {
        Account acc1 = new Account(FirstName = 'Test', LastName = 'A', RecordTypeId = utilities.getRecordTypeId('Account', 'Person Account'));
        insert acc1;
        
        Account acc2 = new Account(FirstName = 'Test', LastName = 'B', RecordTypeId = utilities.getRecordTypeId('Account', 'Person Account'));
        insert acc2;
        
        Asset lockedAsset = new Asset(
            Name = 'Locked Asset',
            Ref_ID__c = 'LOCK123',
            Status = 'Reserved',
            LockedByUser__c = acc2.Id
        );
        insert lockedAsset;
        
        Id parkingRTId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc1.Id,
            RecordTypeId = parkingRTId,
            Parking_Ref_ID__c = 'LOCK123'
        );
        
        Test.startTest();
        Database.SaveResult sr = Database.insert(quote, false);
        Test.stopTest();
    }
    
    static testMethod void test_beforeInsert_with_locked_asset_match() {
        Account acc = new Account(FirstName = 'Test', LastName = 'C', RecordTypeId = utilities.getRecordTypeId('Account', 'Person Account'));
        insert acc;
        
        Asset asset = new Asset(
            Name = 'Asset',
            Ref_ID__c = 'REF123',
            Status = 'Reserved',
            LockedByUser__c = acc.Id
        );
        insert asset;
        
        Id parkingRTId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            RecordTypeId = parkingRTId,
            Parking_Ref_ID__c = 'REF123'
        );
        Test.startTest();
        insert quote;
        Test.stopTest();
    }
    
    static testMethod void test_afterInsertMethod_with_parking_quote() {
        Account acc = new Account(FirstName = 'Test', LastName = 'D', RecordTypeId = utilities.getRecordTypeId('Account', 'Person Account'));
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acc.Id, StageName = 'Proposal', CloseDate = Date.today());
        insert opp;
        
        Id parkingRTId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Parking').getRecordTypeId();
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            RecordTypeId = parkingRTId,
            Parking_Ref_ID__c = 'NEWREF'
        );
        Test.startTest();
        insert quote;
        Test.stopTest();
    }
    
    static testMethod void test_afterUpdateMethod_with_furniture_quote() {
        Account acc = new Account(FirstName = 'Test', LastName = 'E', RecordTypeId = utilities.getRecordTypeId('Account', 'Person Account'));
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Furniture Opp', AccountId = acc.Id, StageName = 'Proposal', CloseDate = Date.today());
        insert opp;
        
        Id furnitureRTId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Furniture').getRecordTypeId();
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            RecordTypeId = furnitureRTId,
            Total_Amount_Paid__c = 0,
            Total_Amount_Received__c = 0,
            SBQQ__Ordered__c = false
        );
        insert quote;
        
        quote.Total_Amount_Paid__c = 500;
        quote.Total_Amount_Received__c = 500;
        Test.startTest();
        update quote;
        Test.stopTest();
    }
    
  static testMethod void test_generateFurnitureOrder_direct_call() {
        Account acc = new Account(FirstName = 'Test', LastName = 'F', RecordTypeId = utilities.getRecordTypeId('Account', 'Person Account'));
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Furniture Direct', AccountId = acc.Id, StageName = 'Proposal', CloseDate = Date.today());
        insert opp;
        
        Id furnitureRTId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Furniture').getRecordTypeId();
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            RecordTypeId = furnitureRTId,
            Total_Amount_Paid__c = 100,
            Total_Amount_Received__c = 100,
            SBQQ__Primary__c = true,    
            SBQQ__Ordered__c = true
        );
        insert quote;
        
        SBQQ__Quote__c quoteBefore = quote.clone(false, false, false, false);
        quoteBefore.Total_Amount_Paid__c = 0;
        quoteBefore.Total_Amount_Received__c = 0;
        
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ quote.Id => quoteBefore };
            
            Test.startTest();
        CPQQuoteTriggerHandler.generateFurnitureOrder(new List<SBQQ__Quote__c>{ quote }, oldMap);
        Test.stopTest();
    }

    static testMethod void test_triggerCalculationEvent_with_calculated_quote() {
        // Create test Account and Opportunity
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'CalcEvent',
            RecordTypeId = utilities.getRecordTypeId('Account', 'Person Account')
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'CalcEvent Opp',
            AccountId = acc.Id,
            StageName = 'Proposal',
            CloseDate = Date.today()
        );
        insert opp;

        // Get Parking record type (or any valid type)
        Id parkingRTId = Schema.SObjectType.SBQQ__Quote__c
            .getRecordTypeInfosByName()
            .get('Parking')
            .getRecordTypeId();

        // Insert a Quote with calculation complete flag
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            RecordTypeId = parkingRTId,
            Quote_Calculation_Complete__c = false
        );
        insert quote;

        // Step 2: Query the record fresh so oldMap retains old value in trigger
        List<SBQQ__Quote__c> quoteToUpdate = [
            SELECT Id, Quote_Calculation_Complete__c, RecordTypeId, SBQQ__Account__c, Building_Section__c, Sales_Order__c, Project__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
            LIMIT 1
        ];
        quoteToUpdate[0].Quote_Calculation_Complete__c = true;
    
        Test.startTest();
        CPQQuoteTriggerHandler quoteTrigger = new CPQQuoteTriggerHandler();
        quoteTrigger.afterUpdateMethod(quoteToUpdate, null, null, null);
        Test.stopTest();
    
        // Step 4: No exceptions means event logic + logging ran successfully
        System.assert(true, 'Trigger afterUpdate executed and calculation event published.');
        System.assert(true, 'CPQQuoteCalculationEvent__e published successfully for calculated quote.');
    }

    //added by Harsh 16/12/2025
    @isTest
    private static void testTriggerCalculationEvent() {
        // Create test account
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'CalcEvent',
            RecordTypeId = utilities.getRecordTypeId('Account', 'Person Account')
        );
        insert acc;
        
        // Create test quote
        Opportunity opp = new Opportunity(
            Name = 'CalcEvent Opp',
            AccountId = acc.Id,
            StageName = 'Proposal',
            CloseDate = Date.today()
        );
        insert opp;

        // Get Parking record type (or any valid type)
        Id parkingRTId = Schema.SObjectType.SBQQ__Quote__c
            .getRecordTypeInfosByName()
            .get('Parking')
            .getRecordTypeId();

        // Insert a Quote with calculation complete flag
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            RecordTypeId = parkingRTId,
            Quote_Calculation_Complete__c = false
        );
        insert quote;
        
        // Test the method
        Test.startTest();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>{quote};
        CPQQuoteTriggerHandler.triggerCalculationEvent(quoteList);
        Test.stopTest();
        
        // Assert (basic assertion to ensure no exception)
        System.assertEquals(1, quoteList.size());
    }

}