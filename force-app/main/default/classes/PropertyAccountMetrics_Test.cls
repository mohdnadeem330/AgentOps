@isTest
private class PropertyAccountMetrics_Test {
 
    private static Account createTestAccount(String nameSuffix) {
        Account acc = new Account(
            Name = 'Test VIP Account ' + nameSuffix,
            CustomerType__c = 'VIP',
            CustomerSubType__c = 'VVVIP TIER 3',
            KYC_Validity_Status__c = 'Valid',
            KYC_ValidityDate__c = System.today().addMonths(6),
            CustomerVertical__c = 'Aldar Properties',
            MobileNumber__c = '1223455'
        );
        insert acc;
        return acc;
    }
 
    @isTest
    static void testAllMethodsWithFullCoverage() {
        Account acc = createTestAccount('A');
 
        // Contracts for Leasing Summary
        Contract active = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            //EndDate = System.today().addDays(120),
            ECSS_AnnualRent__c = '50000',
            ECSS_ContractOrganizationType__c = 'Tenancy'
        );
        Contract expiring = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            //EndDate = System.today().addDays(60),
            ECSS_AnnualRent__c = '80000',
            ECSS_ContractOrganizationType__c = 'Tenancy'
        );
        insert new List<Contract>{active, expiring};
 
        Project__c pro = new Project__c(BusinessUnitId__c = '7856', ProjectCode__c = '7856');
        insert pro;
 
        BuildingSection__c building = new BuildingSection__c(
            BuildingSectionCode__c = '1456',
            Project__c = pro.Id
        );
        insert building;
 
        Unit__c unit = new Unit__c(
            Name = '123456',
            BuildingSectionName__c = building.Id,
            Project__c = pro.Id,
            UnitType__c = 'Apartment'
        );
        insert unit;
 
        SalesOrder__c so = new SalesOrder__c(
            Account__c = acc.Id,
            NetAmount__c = 100000,
            Status__c = 'Confirmed',
            Unit__c = unit.Id,
             CustomerDLPStartDate__c = System.today().addDays(-30),
            DLPDate__c = System.today().addDays(30)
        );
        insert so;
 
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            MobilePhone = '9876543210',
            AccountId = acc.Id
        );
        insert con;
 
        // DLP / AMC cases
        Case amcCase = new Case(
            AccountId = acc.Id,
            Vertical__c = 'DLP',
            //SubVertical__c = 'AMC',
            Total_Amount__c = 2000,
            AMC_Start_Date__c = System.now(),
            AMC_Due_Date__c = System.now().addMonths(1),
            Subject = 'AMC Case',
            Status = 'Active',
            CustomerType__c = 'Tenant',
            ContactId = con.Id,
            Email_Not_Triggered__c = false,
            CaseReopenCount__c = 0,
            Origin = 'Phone',
             DLP_Closure_Reason__c ='Attended'
        );
        Case dlpCase = new Case(
            AccountId = acc.Id,
            Vertical__c = 'DLP',
            SubVertical__c = 'DLP',
            Status = 'Closed',
            ContactId = con.Id,
            Subject = 'DLP Case',
            CustomerType__c = 'Tenant',
            Email_Not_Triggered__c = false,
            CaseReopenCount__c = 0,
            Origin = 'Phone',
             DLP_Closure_Reason__c ='Attended'
        );
        insert new List<Case>{amcCase, dlpCase};
 
        // Communication Preference
        insert new Communication_Preference__c(
            Account__c = acc.Id,
            FastTrack_Completion_Date_Time__c = System.now().addDays(-2)
        );
        //
       HexaBPM__SR_Status__c SRstatus = new HexaBPM__SR_Status__c();
        SRstatus.name ='Submitted';
        SRstatus.HexaBPM__Code__c ='Test';
        insert SRstatus;
        
        // Feedback for NPS/CSAT
        insert new QualtricsResponse__c(
            AccountId__c = acc.Id,
            Question1Impact__c='CSAT',
            Answer1__c = '8',
            SurveyName__c = 'Test Survey'
        );
 
          insert new QualtricsResponse__c(
            AccountId__c = acc.Id,
            Question1Impact__c='NPS',
            Answer1__c = '9',
            SurveyName__c = 'Test Survey'
        );
 
        // Service Request (with try-catch)
        try {
            insert new HexaBPM__Service_Request__c(HexaBPM__Customer__c = acc.Id);
        } catch (Exception e) {
            System.debug('Skipping SR insert: ' + e.getMessage());
        }
 
        // Relationship (spouse + child)
        Account spouseAcc = createTestAccount('Spouse');
        Account childAcc = createTestAccount('Child');
        insert new List<AccountRelationship__c>{
            new AccountRelationship__c(
                Account__c = acc.Id,
                RelatedAccount__c = spouseAcc.Id,
                RelationshipSubType__c = 'Spouse',
                RelationshipType__c = 'Joint Owner P-P'
            ),
            new AccountRelationship__c(
                Account__c = acc.Id,
                RelatedAccount__c = childAcc.Id,
                RelationshipSubType__c = 'Child',
                RelationshipType__c = 'Joint Owner P-P'
            )
        };
 
        // Order with Insurance record type
        RecordType insuranceRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' LIMIT 1];
        insert new Order(
            AccountId = acc.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            Type = 'Shory',
            RecordTypeId = insuranceRt.Id
        );
 
        Test.startTest();
 
        // Positive calls
        PropertyAccountMetrics.getCustomer360Summary(acc.Id);
        PropertyAccountMetrics.getLeasingSummary(acc.Id);
        PropertyAccountMetrics.getOwnershipSummary(acc.Id);
        PropertyAccountMetrics.getFinancialInsights(acc.Id);
        PropertyAccountMetrics.getEngagementSummary(acc.Id);
        PropertyAccountMetrics.getMaintenanceAndDLPData(acc.Id);
        PropertyAccountMetrics.getFamilyRelationshipView(acc.Id);
        PropertyAccountMetrics.getOptionsAndUpgrades(acc.Id);
        PropertyAccountMetrics.getBusinessCrossoverLOB(acc.Id);
 
        // Negative/Exception paths
   
         try {
                PropertyAccountMetrics.getFinancialInsights(null);
                PropertyAccountMetrics.getEngagementSummary(null);
                PropertyAccountMetrics.getOptionsAndUpgrades(null);
            } catch (Exception e) {
                System.debug('Expected handled exception: ' + e.getMessage());
            }
 
 
 
        // Empty family relationship (cover else path)
        Account acc2 = createTestAccount('NoRelations');
        PropertyAccountMetrics.getFamilyRelationshipView(acc2.Id);
 
        // Empty LOB scenario (no matching domain)
        PropertyAccountMetrics.getBusinessCrossoverLOB(acc2.Id);
 
        Test.stopTest();
    }
}