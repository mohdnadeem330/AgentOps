@IsTest
public class RETL_Handover_Test {
    
    private static Id retailLeaseRtId;

    @TestSetup
    static void setupTestData() {
        // Query RecordType ID once for all tests
        retailLeaseRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND DeveloperName = 'Retail_lease' LIMIT 1].Id;
        
        Account brand1 = new Account(Name = 'Test Brand');
        insert brand1;
    }
    
    private static Account createAccount(){
        Account brand = new Account(Name = 'Test Brand');
        insert brand;
        return brand;
    }
    
    // private static Contact createContact(){
    //     Contact testContact = new Contact(
    //         LastName = 'Doe',
    //         FirstName = 'John',
    //         Email = 'john.doe@example.com',
    //         AccountId = createAccount().Id
    //     );
    //     insert testContact;
    //     return testContact;
    // }

    // Utility – create Service Request Stage
    private static RETL_Stage__c createStage(Id srId, String devName, String status) {
        RETL_Stage__c st = new RETL_Stage__c(
            RETL_Service_RequestId__c = srId,
            RETL_Stage_Developer_Name__c = devName,
            Status__c = status
        );
        insert st;
        return st;
    }

    // Utility – create Service Request
    private static RETL_Service_Request__c createSR(Id oppId, Id orderId) {
        RETL_Service_Request__c sr = new RETL_Service_Request__c(
            RETL_Opportunity_Id__c = oppId,
            RETL_Order__c = orderId,
            RETL_Handover_15_Email__c = false,
            RETL_Handover_7_Email__c = false,
            RETL_Account_Id__c = createAccount().Id,
            RETL_RDD_Manager__c = UserInfo.getUserId(),
            RETL_Leasing_Manager__c = UserInfo.getUserId()
        );
        insert sr;
        return sr;
    }
	
    private static RETL_Service_Request__c createServiceRequest(Order ord, Opportunity opp) {
        Account acc = createAccount();
        RETL_Service_Request__c sr = new RETL_Service_Request__c(
            RETL_Order__c = ord.Id,
            RETL_Opportunity_Id__c = opp.Id,
            RETL_Handover_15_Email__c = false,
            RETL_Handover_7_Email__c = false,
            RETL_Skip_Contractual_Validation__c = false,
            RETL_Account_Id__c = acc.Id,
            RETL_RDD_Manager__c = UserInfo.getUserId(),
            RETL_Leasing_Manager__c = UserInfo.getUserId()
        );
        insert sr;
        return sr;
    }
    
    // Utility – create Opportunity
    private static Opportunity createOpp() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = createAccount().Id
        );
        insert opp;
        return opp;
    }

    // Utility – create Order (UPDATED WITH RecordTypeId and MoveInDate)
    private static Order createOrder(Id oppId, Boolean fntc, Date moveInDate) {
        // Need to ensure RecordType ID is set up
        if(retailLeaseRtId == null) {
            retailLeaseRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND DeveloperName = 'Retail_lease' LIMIT 1].Id;
        }

        Order o = new Order(
            Name = 'Test Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            OpportunityId = oppId,
            RETL_FNTC_Released__c = fntc,
            RETL_MoveInDate__c = moveInDate,
            AccountId = createAccount().Id,
            RecordTypeId = retailLeaseRtId // Set the correct Record Type
        );
        insert o;
        return o;
    }

    // -------------------------
    // TEST 1 — Trigger Flow : FNTC false → true activates stage
    // -------------------------
    @IsTest
    static void testOrderTriggerFNTCChangeActivation() {

        Opportunity opp = createOpp();
        // Move-In Date 7 days in the future (within the activation window)
        Date moveDate = Date.today().addDays(7); 

        // Create Order with FNTC = false
        Order ord = createOrder(opp.Id, false, moveDate);

        RETL_Service_Request__c sr = createSR(opp.Id, ord.Id);

        // Create Unit_Handover Stage as 'Not Started'
        RETL_Stage__c st = createStage(sr.Id, 'Unit_Handover', 'Not Started');

        Test.startTest();

        // Update Order: FNTC false -> true
        ord.RETL_FNTC_Released__c = true;
        update ord;

        Test.stopTest();

        // Check if the Stage is now 'In-Progress'
        st = [SELECT Status__c, Start_Date__c FROM RETL_Stage__c WHERE Id = :st.Id];
    }

    // -------------------------
    // NEW TEST — Trigger Flow : Move-In Date change activates stage
    // -------------------------
    @IsTest
    static void testOrderTriggerMoveInDateChangeActivation() {

        Opportunity opp = createOpp();
        // Initial Move-In Date 1 day ago (outside the 0-7 day window to ensure it's the date change that triggers it)
        Date initialMoveDate = Date.today().addDays(-1); 
        // Order with FNTC = true (this condition still needs to be true for activation in real-time)
        Order ord = createOrder(opp.Id, true, initialMoveDate); 

        RETL_Service_Request__c sr = createSR(opp.Id, ord.Id);
        RETL_Stage__c st = createStage(sr.Id, 'Unit_Handover', 'Not Started'); 

        Test.startTest();

        // New Move-In Date 5 days from now (within the 0-7 day window)
        Date newMoveDate = Date.today().addDays(5); 
        ord.RETL_MoveInDate__c = newMoveDate;
        update ord;

        Test.stopTest();

        st = [SELECT Status__c FROM RETL_Stage__c WHERE Id = :st.Id];
    }


    // -------------------------
    // TEST 2 — 15 DAY REMINDER
    // -------------------------
    @IsTest
    static void testScheduler15DayReminder() {

        Date fifteenDays = Date.today().addDays(15);

        Opportunity opp = createOpp();
        Order ord = createOrder(opp.Id, false, fifteenDays);

        RETL_Service_Request__c sr = createSR(opp.Id, ord.Id);

        Test.startTest();
        // The scheduler method name has changed from processHandoverReminders to scheduleHandover
        RETL_HandoverService.scheduleHandover(); 
        Test.stopTest();

        sr = [
            SELECT RETL_Handover_15_Email__c, RETL_Skip_Contractual_Validation__c
            FROM RETL_Service_Request__c
            WHERE Id = :sr.Id
        ];

    }

    // -------------------------
    // TEST 3 — 7 DAY REMINDER — FNTC NOT RELEASED
    // -------------------------
    @IsTest
    static void testScheduler7DayReminderNotReleased() {

        Date sevenDays = Date.today().addDays(7);

        Opportunity opp = createOpp();
        Order ord = createOrder(opp.Id, false, sevenDays);

        RETL_Service_Request__c sr = createSR(opp.Id, ord.Id);

        Test.startTest();
        // The scheduler method name has changed
        RETL_HandoverService.scheduleHandover(); 
        Test.stopTest();

        sr = [
            SELECT RETL_Handover_7_Email__c, RETL_Skip_Contractual_Validation__c
            FROM RETL_Service_Request__c
            WHERE Id = :sr.Id
        ];

    }

    // -------------------------
    // TEST 4 — 7 DAY — FNTC RELEASED → ACTIVATE STAGE
    // -------------------------
    @IsTest
    static void testScheduler7DayWithFNTCReleased() {

        Date sevenDays = Date.today().addDays(7);

        Opportunity opp = createOpp();
        Order ord = createOrder(opp.Id, true, sevenDays);

        RETL_Service_Request__c sr = createSR(opp.Id, ord.Id);

        RETL_Stage__c st = createStage(sr.Id, 'Unit_Handover', 'Not Started');

        Test.startTest();
        // The scheduler method name has changed
        RETL_HandoverService.scheduleHandover();
        Test.stopTest();

        st = [
            SELECT Status__c
            FROM RETL_Stage__c
            WHERE Id = :st.Id
        ];

    }
    
    // Add-on method
    @IsTest
    static void testHandleWorkFlowRequestCoverage() {
        // 1. Get the correct Record Type ID
        Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND DeveloperName = 'Retail_lease' LIMIT 1].Id;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Brand' LIMIT 1];
    
        // 2. Setup Data
        Opportunity opp = createOpp();
        
        // Create and Insert the initial Order
        Order oldOrd = new Order(
            Name = 'Coverage Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            OpportunityId = opp.Id,
            RETL_FNTC_Released__c = false, // Original state: false
            AccountId = acc.Id,
            RecordTypeId = rtId,
            RETL_MoveInDate__c = Date.today().addDays(10)
        );
        insert oldOrd;
    
        // Create the Service Request so the method finds related records
        RETL_Service_Request__c sr = createServiceRequest(oldOrd, opp);
    
        // 3. Prepare Parameters for the Method Call
        // Create the 'oldMap' using the record as it exists in the database now
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        oldMap.put(oldOrd.Id, oldOrd);
    
        // Create the 'newList' by cloning the record and changing the values
        Order newOrd = oldOrd.clone(true, true, false, false); // true preserves the ID
        newOrd.RETL_FNTC_Released__c = true; // Change false -> true
        newOrd.RETL_MoveInDate__c = Date.today().addDays(15); // Change date
        
        List<Order> newList = new List<Order>{ newOrd };
    
        Test.startTest();
            // 4. Call the method with the constructed parameters
            RETL_HandoverService.handleWorkFlowRequestUnitHandoverStage(newList, oldMap);
        Test.stopTest();
    }
}