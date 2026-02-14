@isTest
public class DM_PmcPortalCtrlTest {
    @isTest(SeeAllData=true)
    static void test() {
        DM_PmcPortalCtrl.getDMApproverUsers();
        DM_PmcPortalCtrl.getPMCPortalUsers();
        
        //  DM_PmcPortalCtrl.getUserInfo();
        
        Product2 testProduct = new Product2(Name = 'Road Closure Diversion', IsActive = true,Family = 'NOC');
        insert testProduct;
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Type = 'NOC',
            ProductId = testProduct.id,
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            status='Pending with Customer',
            Sub_Status__c='Additional Information Required from Customer'
        );
        insert testCase;
        Id caseDocumentRecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
        Document__c document = new Document__c();
        document.DocumentType__c = 'Others';
        document.Case__c = testCase.Id; 
        document.RecordTypeId = caseDocumentRecordTypeId;
        document.Other_Document_Name__c = 'aldarDocName';
        insert document; 
        
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Content Version',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test content version data'),
            FirstPublishLocationId = document.Id
        );
        insert testContentVersion;
        
        List<String> caseIdList = new List<String> { testCase.Id };
            DM_PmcPortalCtrl.getCaseMilestones(testCase.Id);
        
        DM_PmcPortalCtrl.getPaymentRequests(caseIdList);
        DM_PmcPortalCtrl.updateAldarDocument(testCase.Id,'aldarDocName','Others');
        DM_PmcPortalCtrl.updateCase(testCase, 'Test comment');
        
    }
    @isTest(SeeAllData=true)
    static void test2() {
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        system.debug('testAccount'+testAccount);
        
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;
        system.debug('testContact'+testContact);
        
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'DM PMC Manager Partner' LIMIT 1];
        system.debug('userProfile'+userProfile);
        
        // Get the default user profile settings for required fields
        User testProfile = [SELECT Id, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        system.debug('testProfile'+testProfile);
        // Create a PMC user
        User pmcUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Username = 'test@smaartt.com',
            Alias = 'tuser',
            ProfileId = userProfile.Id,
            ContactId = testContact.Id,
            TimeZoneSidKey = testProfile.TimeZoneSidKey,
            LocaleSidKey = testProfile.LocaleSidKey,
            EmailEncodingKey = testProfile.EmailEncodingKey,
            LanguageLocaleKey = testProfile.LanguageLocaleKey
        );
        insert pmcUser;
        Profile testProfiles = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User approverUser = new User(
            Alias = 'approv1',
            Email = 'approver1@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Approver',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfiles.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'approver100651@test.com',
            IsActive = true
        );
        insert approverUser;
        Product2 testProduct = new Product2(Name = 'Road Closure Diversion', IsActive = true,Family = 'NOC');
        insert testProduct;
        Case testCase = new Case(
            Subject = 'Test Case',
            Type = 'NOC',
            status = 'Work In Progress',
            ProductId = testProduct.id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Development_Name__c='Yas Island',
            Sub_Status__c = 'Documents Accepted by PMC',
            Assigned_To__c = approverUser.id
        );
        insert testCase;
        
        Test.startTest();
        try{
            DM_PmcPortalCtrl.updateCase(testCase, 'Test comment');
            DM_PmcPortalCtrl.recallApproval(testCase.Id);
            
        } catch (Exception e) {
            System.debug('CaseUpdated =='+ e.getMessage());
        }
        
        Test.stopTest();
    }
}