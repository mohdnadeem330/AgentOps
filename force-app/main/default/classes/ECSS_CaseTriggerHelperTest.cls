@isTest
public class ECSS_CaseTriggerHelperTest {
    
    @testSetup
    static void setupTestData() {
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com' Limit 1];
        System.runAs(testUser) {
            // Create an Account
            Account testAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', '111111111111111', 'P1');
            testAccount.NationalIdNumber__pc = '111111111111111';
            insert testAccount;
            Trigger_Enabler__c triggerEnabler = new Trigger_Enabler__c();
            triggerEnabler.Name = 'Asset';
            triggerEnabler.Is_After_Update__c =false;
            triggerEnabler.Is_After_Insert__c =false;
            triggerEnabler.Is_After_Delete__c = false;
            triggerEnabler.Is_Before_Delete__c = false;
            triggerEnabler.Is_Before_Insert__c = false;
            triggerEnabler.Is_Before_Update__c = false;
            insert triggerEnabler;
            // Create an Asset linked to the Account
            Asset testAsset = new Asset(
                Name = 'Test Asset'
            );
            insert testAsset;
            
            // Create a Contract linked to the Asset
            Contract testContract = new Contract(
                AccountId = testAccount.Id
            );
            insert testContract;
            Sales_organization__c so = new Sales_organization__c();
            so.ECSS_DefaultNotificationTypes__c = 'a,b,c,d';
            insert so;
            // Create a Case linked to the Account and Asset
            Case testCase = TestObjectsFactory.getProvisCaseNoAccount();
            //testCase.AssetId = testAsset.Id;
            testCase.ECSS_Contract__c = testContract.Id;
            insert testCase;
        }
    }
    
    @isTest
    static void testUpdateSAPValues() {
        Test.startTest();
        // Query the test Case created in the test setup
        List<Case> cases = [SELECT Id, Asset.ExternalIdentifier, RecordType.DeveloperName FROM Case LIMIT 1];
        ECSS_CaseTriggerHelper.UpdateSAPValues(cases);
        Test.stopTest();
    }
    
    @isTest
    static void testCreateRelatedAcc() {
         Test.startTest();
        // Query the test Account created in the test setup
        Account testAccount = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        
        // Create a new Case to test account creation
        Case testCase = TestObjectsFactory.getProvisCaseNoAccount();
        testCase.ECSS_CreateAccount__c = true;
        testCase.ECSS_AccountFirstName__c = 'John';
        testCase.ECSS_AccountLastName__c = 'Doe';
        testCase.ECSS_AccountMiddleName__c = 'Middle';
        testCase.ECSS_AccountCreationGender__c = 'Male';
        testCase.ECSS_RequestedEmail__c = 'john.doe@example.com';
        testCase.ECSS_RequestedEmiratesId__c = 'EmiratesId123';
        testCase.ECSS_RequestedPassportNo__c = 'PassportNo123';
        testCase.ECSS_RequestedMobileNumber__c = '1234567890';
        testCase.ECSS_ZipCode__c = '12345';
       
        
        insert testCase;
        
        // Query the newly inserted Case
        List<Case> cases = [
            SELECT Id, AccountId, ContactId, Priority, ECSS_CreateAccount__c, ECSS_RequestedEmail__c,Recordtype_Name__c
            FROM Case
            WHERE Id = :testCase.Id
        ];
        
        ECSS_CaseTriggerHelper.createRelatedAcc(cases);
        Test.stopTest();
        
        
    }
    @isTest
    static void testCreateCaseNoAcc() {
        Test.startTest();
        // Query the test Account created in the test setup
        Case testCase=TestObjectsFactory.getProvisCaseNoAccount();
        testCase.recordtypeId=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Maintenance').getRecordTypeId();
        testCase.ECSS_CreateAccount__c=true;
        testCase.ECSS_AccountCreationType__c='PersonAccount';
        testCase.Priority = label.ECSS_EmergencyPriority;
        testCase.ECSS_AccountFirstName__c='test';
        testCase.ECSS_AccountLastName__c='test';
        testCase.ECSS_CompanyOptions__c='Provis';
        testCase.SubVertical__c='RTO/PROMO';
        testCase.CaseCategory__c = 'HVAC';
        testCase.ECSS_Object_Category__c='Bathroom';
        
        
        insert testCase;
        
        // Query the newly inserted Case
        List<Case> cases = [
            SELECT Id, AccountId, ContactId, Priority, ECSS_CreateAccount__c, ECSS_RequestedEmail__c,Recordtype_Name__c
            FROM Case
            WHERE Id = :testCase.Id
        ];
        
        ECSS_CaseTriggerHelper.createRelatedAcc(cases);
        Test.stopTest();
        
        
    }
    @isTest
    static void testCreateCaseNoAccOrg() {
        Asset testAsset = [SELECT ID FROM Asset limit 1];
        Test.startTest();
        // Query the test Account created in the test setup
        Case testCase=TestObjectsFactory.getProvisCaseNoAccount();
        testCase.recordtypeId=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Maintenance').getRecordTypeId();
        testCase.ECSS_CreateAccount__c=true;
        testCase.ECSS_AccountCreationType__c='OrganizationAccount';
        testCase.Priority = label.ECSS_EmergencyPriority;
        testCase.ECSS_RequestedAccountName__c = 'test';
        testCase.ECSS_CompanyOptions__c='Provis';
        testCase.SubVertical__c='RTO/PROMO';
        testCase.CaseCategory__c = 'HVAC';
        testCase.ECSS_Object_Category__c='Bathroom';
        testCase.ECSS_AccountUnit__c = testAsset.Id;
        insert testCase;
        
        // Query the newly inserted Case
        List<Case> cases = [
            SELECT Id, AccountId, ContactId, Priority, ECSS_CreateAccount__c, ECSS_RequestedEmail__c,Recordtype_Name__c
            FROM Case
            WHERE Id = :testCase.Id
        ];
        
        ECSS_CaseTriggerHelper.createRelatedAcc(cases);
        Test.stopTest();
        
        
    }
}