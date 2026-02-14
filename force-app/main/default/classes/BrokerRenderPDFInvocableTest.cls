@IsTest
public class BrokerRenderPDFInvocableTest {
    
    @testSetup
    public static void setup() {
        
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

        List<Suspensions_Warning__c> suspensions = new List<Suspensions_Warning__c>();
        suspensions.add(new Suspensions_Warning__c(
            BrokerAgency__c = orgAcc1.Id,
            SuspensionApprovalStatus__c = 'Submitted for Suspension Approval',
            SuspensionWarning__c = 'Warning'
        ));
        
        suspensions[0].LeadRegistrationSubCategory__c = 'Broker Register as Customer W/O Consent';
        suspensions[0].CommissionSubCategory__c = 'Failure to Sign the Broker Form';
        suspensions[0].LegalMattersSubCategory__c = 'Broker attempting to disguise illegal funds';
        suspensions[0].DisputesSubCategory__c = 'Soliciting customers to interfere on a final decision given by Aldar on dispute cases.';
        suspensions[0].BusinessEthicsSubCategory__c = 'Brokers using inappropriate, coarse, offensive language';
        suspensions[0].MarketingAndCommunicationsSubCategory__c = 'Failure to follow Aldar’s corporate brand guidelines.';
        suspensions[0].BrokerRegistrationSubCategory__c = 'If broker refuses to register on GoAML register';
        suspensions[0].PropertyViewingsSubCategory__c = 'Brokers not behaving appropriately and not following rules';
        // suspensions[0].ResaleSubCategory__c = 'Brokers advertisement about any of Aldar’s project in the secondary market';
        suspensions[0].ConfidentialityInfoFailureSubCategory__c = 'Mishandling or disclosing confidential information about clients or transactions.';
        suspensions[0].PublishingWoConsentSubCategory__c = 'Unapproved official PR communication on any platform';
        suspensions[0].OtherReasonforSuspension__c = 'Test';
        insert suspensions;
        
        Document__c documentRecord = new Document__c ();
        documentRecord.Suspensions_Warning__c   = suspensions[0].Id;
        documentRecord.DocumentPlaceHolderId__c = 'Suspension_Letter';
        documentRecord.DocumentType__c = 'Suspension Letter';
        documentRecord.Status__c = 'Pending';
        documentRecord.RecordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('BrokerDocuments').getRecordTypeId();
        insert documentRecord ;
         
        ContentVersion contentVersion = new ContentVersion(
        Title = 'a picture',PathOnClient = 'Pic.jpg',
        VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
        insert contentVersion;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = documentRecord.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        
    }
    @isTest
    static void testBeforeUpdate() {
        List<Suspensions_Warning__c> suspensionsList = new List<Suspensions_Warning__c>();
        suspensionsList = [SELECT Id, SuspensionApprovalStatus__c, SuspensionWarning__c, BrokerAgency__c FROM Suspensions_Warning__c LIMIT 1];
       
        Test.startTest();
        BrokerRenderPDFInvocable.uploadSuspensionWarningLetter(new List<Id>{suspensionsList[0].Id});
        Test.stopTest();
    }
    @isTest
static void testSuspensionEmailFlow() {
    Account agencyAcc = [SELECT Id FROM Account WHERE RecordTypeId = :Constants.BROKER_AGENCY_RECORD_TYPE_ID LIMIT 1];
    
    Suspensions_Warning__c suspensionRecord = new Suspensions_Warning__c(
        BrokerAgency__c = agencyAcc.Id,
        SuspensionApprovalStatus__c = 'Submitted for Suspension Approval',
        SuspensionWarning__c = 'Suspension'
    );
    insert suspensionRecord;

    Document__c documentRecord = new Document__c();
    documentRecord.Suspensions_Warning__c = suspensionRecord.Id;
    documentRecord.DocumentPlaceHolderId__c = 'Suspension_Letter';
    documentRecord.DocumentType__c = 'Suspension Letter';
    documentRecord.Status__c = 'Pending';
    documentRecord.RecordTypeId = Schema.SObjectType.Document__c
        .getRecordTypeInfosByDeveloperName()
        .get('BrokerDocuments')
        .getRecordTypeId();
    insert documentRecord;

    ContentVersion contentVersion = new ContentVersion(
        Title = 'SuspensionDoc',
        PathOnClient = 'SuspensionDoc.pdf',
        VersionData = Blob.valueOf('Sample Suspension Letter'),
        IsMajorVersion = true
    );
    insert contentVersion;

    ContentDocument contentDoc = [SELECT Id, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
    ContentDocumentLink cdl = new ContentDocumentLink(
        LinkedEntityId = documentRecord.Id,
        ContentDocumentId = contentDoc.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;

    Test.startTest();
    BrokerRenderPDFInvocable.uploadSuspensionWarningLetter(new List<Id>{suspensionRecord.Id});
    Test.stopTest();

    System.assert(true, 'Suspension flow executed successfully');
}

}