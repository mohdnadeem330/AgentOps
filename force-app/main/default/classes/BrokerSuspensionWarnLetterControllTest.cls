@isTest
public with sharing class BrokerSuspensionWarnLetterControllTest {
    @testSetup
    static void setup() {
        // Create test data that can be reused in all test methods
        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;
        
        Account orgAcc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc1;
    
        orgAcc1.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc1.ParentId = orgAcc.Id;
        update orgAcc1;

        Contact singleCon       = new Contact();
        singleCon.Firstname     = 'newContact';
        singleCon.LastName       = 'Lastname';
        singleCon.AccountId     = orgAcc1.id;
        singleCon.Email       = 'aldartestUser@yopmail.com';
        singleCon.BrokerType__c    = 'Agent';
        singleCon.RecordTypeId     = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
        Insert singleCon;

        Id pfId = [SELECT Id, Name FROM profile WHERE name=: Constants.AGENCY_USER_PROFILE_LOGIN LIMIT 1].Id;
        
        User newCommunitiesUser         = new User();
        newCommunitiesUser.ContactId      = singleCon.Id;
        newCommunitiesUser.FirstName      = singleCon.FirstName;
        newCommunitiesUser.LastName        = singleCon.LastName;
        newCommunitiesUser.Email        = singleCon.Email;
        newCommunitiesUser.Username        = singleCon.FirstName+'_'+'ACCOUNT_NUMBER'+'_'+singleCon.LastName+Constants.USERNAME_DOMAIN;
        newCommunitiesUser.profileid      = pfId;
        newCommunitiesUser.languagelocalekey  = 'en_US';
        newCommunitiesUser.localesidkey      = 'en_US';
        newCommunitiesUser.emailencodingkey    = 'UTF-8';
        newCommunitiesUser.IsActive        = true;
        newCommunitiesUser.timezonesidkey    = 'Asia/Dubai';
        newCommunitiesUser.alias        = String.valueof(singleCon.FirstName.substring(0,1) + singleCon.LastName.substring(0,1) + Math.random() ).substring(0,5);
        newCommunitiesUser.communityNickname  = singleCon.LastName + '_'+Integer.valueof((Math.random() * 10000));
        insert newCommunitiesUser;

        // Create Suspension Warning record
        Suspensions_Warning__c suspensionWarning = new Suspensions_Warning__c(
            SuspensionStartDate__c = System.Today().addDays(-10),
            SuspensionEndDate__c = System.today().addDays(10),
            LeadRegistrationAndManagement__c = true,
            LeadRegistrationSubCategory__c = 'Broker Register as Customer W/O Consent',
            Commission__c = true,
            CommissionSubCategory__c = 'Failure to Sign the Broker Form',
            LegalMatters__c = true,
            LegalMattersSubCategory__c = 'Broker attempting to disguise illegal funds',
            Disputes__c = true,
            DisputesSubCategory__c = 'Soliciting customers to interfere on a final decision given by Aldar on dispute cases.',
            BusinessEthics__c = true,
            BusinessEthicsSubCategory__c = 'Brokers using inappropriate, coarse, offensive language',
            MarketingAndCommunications__c = true,
            MarketingAndCommunicationsSubCategory__c = 'Failure to follow Aldar’s corporate brand guidelines.',
            BrokerRegistration__c = true,
            BrokerRegistrationSubCategory__c = 'If broker refuses to register on GoAML register',
            OpenHousesKioskSalesPropertyViewing__c = true,
            PropertyViewingsSubCategory__c = 'Brokers not behaving appropriately and not following rules',
            // Resale__c = true,
            // ResaleSubCategory__c = 'Brokers advertisement about any of Aldar’s project in the secondary market',
            FailureToProtectConfidentialInfo__c = true,
            ConfidentialityInfoFailureSubCategory__c = 'Mishandling or disclosing confidential information about clients or transactions.',
            PublishingArticlesWoConsent__c = true,
            PublishingWoConsentSubCategory__c = 'Unapproved official PR communication on any platform',
            Others__c = true,
            OtherReasonforSuspension__c = 'Other Reason',
            SuspensionWarning__c = 'Suspension'
        );
        insert suspensionWarning;

        // Set Page Parameters
        Test.setCurrentPageReference(new PageReference('brokerSuspensionWarnLetter'));
        ApexPages.currentPage().getParameters().put('id', orgAcc1.Id);
        ApexPages.currentPage().getParameters().put('suspWarnId', suspensionWarning.Id);
        
        BrokerSuspensionWarnLetterVFController.accountId = orgAcc1.Id;
        BrokerSuspensionWarnLetterVFController.suspenWarnId = suspensionWarning.Id;
        BrokerSuspensionWarnLetterVFController controller = new BrokerSuspensionWarnLetterVFController();

    }

    @isTest
    static void testController() {
        // Instantiate the controller
        //BrokerSuspensionWarnLetterVFController controller = new BrokerSuspensionWarnLetterVFController();

        // // Verify brokerUserDetails
        // System.assertNotEquals(controller.brokerUserDetails, null, 'Broker User Details should not be null');
        // System.assertEquals(controller.brokerUserDetails.AccountId, [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id, 'Broker User should belong to the correct Account');

        // // Verify suspensionRecord
        // System.assertNotEquals(controller.suspensionRecord, null, 'Suspension Record should not be null');
        // System.assertEquals(controller.suspensionRecord.LeadRegistrationAndManagement__c, true, 'Lead Registration And Management should be true');

        // // Verify mapSuspensionCateSubCategory
        // System.assertEquals(controller.mapSuspensionCateSubCategory.get('Lead Registration And Management').size(), 2, 'Lead Registration And Management Sub Categories size should be 2');
        // System.assertEquals(controller.mapSuspensionCateSubCategory.get('Commission').size(), 2, 'Commission Sub Categories size should be 2');
        // System.assertEquals(controller.mapSuspensionCateSubCategory.get('Other Reasons').size(), 1, 'Other Reasons Sub Categories size should be 1');

        // // Verify mapSuspensionCateSubCategorySizeEach
        // System.assertEquals(controller.mapSuspensionCateSubCategorySizeEach.get('Lead Registration And Management'), 2, 'Lead Registration And Management Sub Categories size each should be 2');
        // System.assertEquals(controller.mapSuspensionCateSubCategorySizeEach.get('Commission'), 2, 'Commission Sub Categories size each should be 2');
        // System.assertEquals(controller.mapSuspensionCateSubCategorySizeEach.get('Other Reasons'), 1, 'Other Reasons Sub Categories size each should be 1');

        // // Verify mapSuspensionCateSubCategorySize
        // System.assertEquals(controller.mapSuspensionCateSubCategorySize, 3, 'Map Suspension Cate Sub Category Size should be 3');

        // // Verify suspension start and end dates
        // System.assertNotEquals(controller.suspensionStartDate, null, 'Suspension Start Date should not be null');
        // System.assertNotEquals(controller.suspensionEndDate, null, 'Suspension End Date should not be null');
    }

}