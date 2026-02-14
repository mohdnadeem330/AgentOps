@isTest
public class ECSS_ReferenceSheetChecksTest {

    @testSetup
    static void dataSetup()
    {
              Id accRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ECSS_Company').getRecordTypeId();
        Account acc = new Account(
            Name = 'Test Company',
            ECSS_Company_External_Id__c = 'COMP123',
            ECSS_Availability__c = 'Available for Lease',
            RecordTypeId = accRecTypeId
        );
        insert acc;
        
        Project__c proj = new Project__c(
            Name = 'Project',
            ECSS_SAPExternalId__c = 'PROJ001',
            BusinessUnitId__c = 'PROJ123',
            ProjectCode__c = 'PROJ123'
        );
        insert proj;
        
        Account landlord = new Account(
            Name = 'Landlord',
            SapAccountID__c = 'LAND123'
        );
        insert landlord;
        
        BuildingSection__c bs = new BuildingSection__c(
            Name = 'BS1',
            ECSS_Building_External_Id__c = 'BS_EXT_ID',
            BuildingSectionCode__c = 'BSCODE',
            Project__c = proj.Id
        );
        insert bs;
        
        Zone__c zone = new Zone__c(
            Name = 'Zone 1',
            Zone_External_Id__c = 'ZONE1',
            Project__c = proj.Id
        );
        insert zone;
        
        Product2 p = new Product2(Name = 'UnitType1', IsActive = true);
        insert p;
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        String UnitRTName = System.Label.ECSS_Unit;
        Id unitRecordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get(UnitRTName).getRecordTypeId();
        
        Asset asset = new Asset(
            Name = 'Test Asset DXB',
            ECSS_Unit_Area__c = 'DXB',
            ECSS_Company_Code_External_Id__c = acc.ECSS_Company_External_Id__c,
            ECSS_Project_External_Id__c = proj.ECSS_SAPExternalId__c,
            ECSS_LandlordSAPExternalId__c = landlord.SapAccountID__c,
            ECSS_Building_Section_External_Id__c = bs.ECSS_Building_External_Id__c,
            ECSS_Zone_External_Id__c = zone.Zone_External_Id__c,
            //ECSS_Owner_Email__c = insertUser.Username,
            //OwnerId = insertUser.Id,
            ExternalIdentifier = 'EXT123',
            RecordTypeId = unitRecordTypeId
        );
        insert asset;
        
        Account mainOccupantAccount = new Account();
        mainOccupantAccount.Name = 'Main Occupant';
		insert mainOccupantAccount;

		Opportunity mainOccupantOpportunity = new Opportunity();
		mainOccupantOpportunity.Name = 'Test Opportunity';
        mainOccupantOpportunity.AccountId = mainOccupantAccount.Id;
        insert mainOccupantOpportunity;
        
        Quote mainOccupantQuote = new Quote();
        mainOccupantQuote.Name = 'TestQuote';
        mainOccupantQuote.OpportunityId = mainOccupantOpportunity.Id;
        insert mainOccupantQuote;
        
    }
    @isTest
    public static void testNoExistingAccounts()
    {
        Account mainOccupantAccount = [SELECT Id FROM Account WHERE Name = 'Main Occupant' LIMIT 1];
        Opportunity mainOccupantOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        Quote mainOccupantQuote = [SELECT Id FROM Quote LIMIT 1];
        
        ECSS_OccupantDetails occ1 = new ECSS_OccupantDetails();
        occ1.firstName = 'Test';
        occ1.lastName = 'Co Occupant 1';
        occ1.dateOfBirth = Date.Today();
        occ1.email = 'test@test.com';
        occ1.mobileCountryCode = '';
        occ1.mobileNumber = '0123456789';
        occ1.nationalId = '1234567';
        occ1.passportNumber = '1234567';
        occ1.relationship = 'Father';
        occ1.assetId = asset.Id;
        occ1.quoteId = mainOccupantQuote.Id;
        occ1.relatedAccountId = mainOccupantAccount.Id;
        occ1.opportunityId = mainOccupantOpportunity.Id;
        
        List<ECSS_OccupantDetails> occupantDetails = new List<ECSS_OccupantDetails>();
        occupantDetails.add(occ1);
        
        List<String> lastNames = new List<String>();
        lastNames.add(occ1.lastName);
        
        List<String> nationalId = new List<String>();
        nationalId.add(occ1.nationalId);
        
        List<String> passport = new List<String>();
        passport.add(occ1.passportNumber);
        
        List<String> lastNameAndPassport = new List<String>();
        lastNameAndPassport.add(occ1.lastName+ ' '+occ1.passportNumber);
        
        List<String> lastNameAndNationalId = new List<String>();
        lastNameAndNationalId.add(occ1.lastName+ ' '+ occ1.nationalId);
        
        ECSS_ReferenceSheetChecks.FlowInputs flowInputs = new ECSS_ReferenceSheetChecks.FlowInputs();
        flowInputs.occupantDetails = occupantDetails;
        flowInputs.lastNames = lastNames;
        flowInputs.nationalIds = nationalId;
        flowInputs.passportNumbers = passport;
        flowInputs.lastNameAndPassport = lastNameAndPassport;
        flowInputs.lastNameAndNationalId = lastNameAndNationalId;
        flowInputs.relatedAccount = mainOccupantAccount.Id;
        
        List<ECSS_ReferenceSheetChecks.FlowInputs> flowInputsList = new List<ECSS_ReferenceSheetChecks.FlowInputs>();
        flowInputsList.add(flowInputs);
        
        ECSS_ReferenceSheetChecks.checkForDuplicateAccounts(flowInputsList);
    }
    @isTest
    public static void testWithExistingAccount()
    {
        Account mainOccupantAccount = [SELECT Id FROM Account WHERE Name = 'Main Occupant' LIMIT 1];
        Opportunity mainOccupantOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        Quote mainOccupantQuote = [SELECT Id FROM Quote LIMIT 1];
        
        ECSS_OccupantDetails occ1 = new ECSS_OccupantDetails();
        occ1.firstName = 'Test';
        occ1.lastName = 'Co Occupant 1';
        occ1.dateOfBirth = Date.Today();
        occ1.email = 'test@test.com';
        occ1.mobileCountryCode = '';
        occ1.mobileNumber = '0123456789';
        occ1.nationalId = '1234567';
        occ1.passportNumber = '1234567';
        occ1.relationship = 'Father';
        occ1.assetId = asset.Id;
        occ1.quoteId = mainOccupantQuote.Id;
        occ1.relatedAccountId = mainOccupantAccount.Id;
        occ1.opportunityId = mainOccupantOpportunity.Id;
        
        Id personAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account coOccupantAccount1 = new Account();
        coOccupantAccount1.FirstName = 'Test';
        coOccupantAccount1.LastName = 'Co Occupant 1';
        coOccupantAccount1.NationalIdNumber__pc = '1234567';
        coOccupantAccount1.PassportNumber__pc = '1234567';
        coOccupantAccount1.RecordTypeId = personAccRecType;
		insert coOccupantAccount1;
        
        AccountRelationship__c accountRel1 = new AccountRelationship__c();
        accountRel1.Account__c = coOccupantAccount1.Id;
        accountRel1.RelatedAccount__c = mainOccupantAccount.Id;
        accountRel1.RelationshipType__c = 'Third Party';
        accountRel1.RelationshipSubType__c  = occ1.relationship;
        insert accountRel1;
        
        List<ECSS_OccupantDetails> occupantDetails = new List<ECSS_OccupantDetails>();
        occupantDetails.add(occ1);
        
        List<String> lastNames = new List<String>();
        lastNames.add(occ1.lastName);
        
        List<String> nationalId = new List<String>();
        nationalId.add(occ1.nationalId);
        
        List<String> passport = new List<String>();
        passport.add(occ1.passportNumber);
        
        List<String> lastNameAndPassport = new List<String>();
        lastNameAndPassport.add(occ1.lastName+ ' '+occ1.passportNumber);
        
        List<String> lastNameAndNationalId = new List<String>();
        lastNameAndNationalId.add(occ1.lastName+ ' '+ occ1.nationalId);
        
        ECSS_ReferenceSheetChecks.FlowInputs flowInputs = new ECSS_ReferenceSheetChecks.FlowInputs();
        flowInputs.occupantDetails = occupantDetails;
        flowInputs.lastNames = lastNames;
        flowInputs.nationalIds = nationalId;
        flowInputs.passportNumbers = passport;
        flowInputs.lastNameAndPassport = lastNameAndPassport;
        flowInputs.lastNameAndNationalId = lastNameAndNationalId;
        flowInputs.relatedAccount = mainOccupantAccount.Id;
        
        List<ECSS_ReferenceSheetChecks.FlowInputs> flowInputsList = new List<ECSS_ReferenceSheetChecks.FlowInputs>();
        flowInputsList.add(flowInputs);
        
        ECSS_ReferenceSheetChecks.checkForDuplicateAccounts(flowInputsList);
    }
    
    @isTest
    public static void testWithExistingAccountNoRel()
    {
        Account mainOccupantAccount = [SELECT Id FROM Account WHERE Name = 'Main Occupant' LIMIT 1];
        Opportunity mainOccupantOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        Quote mainOccupantQuote = [SELECT Id FROM Quote LIMIT 1];
        
        ECSS_OccupantDetails occ1 = new ECSS_OccupantDetails();
        occ1.firstName = 'Test';
        occ1.lastName = 'Co Occupant 2';
        occ1.dateOfBirth = Date.Today();
        occ1.email = 'test@test.com';
        occ1.mobileCountryCode = '';
        occ1.mobileNumber = '0123456789';
        occ1.nationalId = '12345678';
        occ1.passportNumber = '1234567';
        occ1.relationship = 'Father';
        occ1.assetId = asset.Id;
        occ1.quoteId = mainOccupantQuote.Id;
        occ1.relatedAccountId = mainOccupantAccount.Id;
        occ1.opportunityId = mainOccupantOpportunity.Id;
        
        
        Id personAccRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account coOccupantAccount1 = new Account();
        coOccupantAccount1.FirstName = 'Test';
        coOccupantAccount1.LastName = 'Co Occupant 2';
        coOccupantAccount1.NationalIdNumber__pc = '12345678';
        //coOccupantAccount1.PassportNumber__pc = '1234567';
        coOccupantAccount1.RecordTypeId = personAccRecType;
		insert coOccupantAccount1;
        
        List<ECSS_OccupantDetails> occupantDetails = new List<ECSS_OccupantDetails>();
        occupantDetails.add(occ1);
        
        List<String> lastNames = new List<String>();
        lastNames.add(occ1.lastName);
        
        List<String> nationalId = new List<String>();
        nationalId.add(occ1.nationalId);
        
        List<String> passport = new List<String>();
        passport.add(occ1.passportNumber);
        
        List<String> lastNameAndPassport = new List<String>();
        lastNameAndPassport.add(occ1.lastName+ ' '+occ1.passportNumber);
        
        List<String> lastNameAndNationalId = new List<String>();
        lastNameAndNationalId.add(occ1.lastName+ ' '+ occ1.nationalId);
        
        ECSS_ReferenceSheetChecks.FlowInputs flowInputs = new ECSS_ReferenceSheetChecks.FlowInputs();
        flowInputs.occupantDetails = occupantDetails;
        flowInputs.lastNames = lastNames;
        flowInputs.nationalIds = nationalId;
        flowInputs.passportNumbers = passport;
        flowInputs.lastNameAndPassport = lastNameAndPassport;
        flowInputs.lastNameAndNationalId = lastNameAndNationalId;
        flowInputs.relatedAccount = mainOccupantAccount.Id;
        
        List<ECSS_ReferenceSheetChecks.FlowInputs> flowInputsList = new List<ECSS_ReferenceSheetChecks.FlowInputs>();
        flowInputsList.add(flowInputs);
        
        ECSS_ReferenceSheetChecks.checkForDuplicateAccounts(flowInputsList);
    }
}