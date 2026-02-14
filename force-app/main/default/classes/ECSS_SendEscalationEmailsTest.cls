@isTest
public class ECSS_SendEscalationEmailsTest {

   @testSetup
    static void setupTestData() {
       
        Folder emailFolder = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1];

        //System.runAs(testUser) {
            EmailTemplate emailTemplateTest = new EmailTemplate(
                Name = 'Test Email Template',
                DeveloperName = 'Test_Email_Template',
                TemplateType = 'custom',
                Subject = 'Test Email Subject',
                HtmlValue = '<p>This is a test email template.</p>',
                IsActive = true,
                FolderId = emailFolder.Id
            );
            insert emailTemplateTest;
        
    }
     @isTest
    static void testSendAssignmentandEscalationEmail1() {
        
         insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = false,
            Is_After_Update__c = false,
            Is_After_Delete__c = false,
            Is_Before_Insert__c = false,
            Is_Before_Update__c = false,
            Is_Before_Delete__c = false
        );
       // User testUser = [select id from user where email='testuser@example.com' LIMIT 1];
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id,
            Email = 'test.contact@example.com'
        );
        insert testContact;
        
        Case testCase = new Case();
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
        testCase.CaseCategory__c = 'Home Finance';
        testCase.CaseComments__c = 'Home Finance Parent Case';
        //caseRecord.Home_Finance_Facilitator__c = 'Huspy';
        testCase.Status = 'New';
        testCase.SubVertical__c = 'Home Finance';
        // caseRecord.Sum_of_Total_Commission_for_Aldar__c = 10000;
        testCase.ContactId = testContact.Id;
        testcase.ECSS_CompanyOptions__c = 'AlDar Properties';
        insert testCase;


       // }
        EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Test_Email_Template' LIMIT 1];

        ECSS_CaseSendAction caseSendAction = new ECSS_CaseSendAction();
        List<String> s1 = new List<String>();
        s1.add(testContact.Email);
        caseSendAction.EmailList = s1;
        caseSendAction.EmailTemplateId = emailTemplate.Id;
        caseSendAction.caseObj = testCase;

        List<ECSS_CaseSendAction> caseSendActions = new List<ECSS_CaseSendAction>{ caseSendAction };

        Test.startTest();
        ECSS_SendEscalationEmails.sendAssignmentandEscalationEmail(caseSendActions);
        Test.stopTest();
    }

    @isTest
    static void testSendAssignmentandEscalationEmail() {
        
         insert new Trigger_Enabler__c(
            Name = 'Asset',
            Is_After_Insert__c = false,
            Is_After_Update__c = false,
            Is_After_Delete__c = false,
            Is_Before_Insert__c = false,
            Is_Before_Update__c = false,
            Is_Before_Delete__c = false
        );
       // User testUser = [select id from user where email='testuser@example.com' LIMIT 1];
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id,
            Email = 'test.contact@example.com'
        );
        insert testContact;
        
        Case testCase = new Case();
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
        testCase.CaseCategory__c = 'Home Finance';
        testCase.CaseComments__c = 'Home Finance Parent Case';
        //caseRecord.Home_Finance_Facilitator__c = 'Huspy';
        testCase.Status = 'New';
        testCase.SubVertical__c = 'Home Finance';
        // caseRecord.Sum_of_Total_Commission_for_Aldar__c = 10000;
        testCase.ContactId = testContact.Id;
        testcase.ECSS_CompanyOptions__c = 'AlDar Properties';
        insert testCase;


       // }
        EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Test_Email_Template' LIMIT 1];

        ECSS_CaseSendAction caseSendAction = new ECSS_CaseSendAction();
        caseSendAction.Email = testContact.Email;
        caseSendAction.EmailTemplateId = emailTemplate.Id;
        caseSendAction.caseObj = testCase;

        List<ECSS_CaseSendAction> caseSendActions = new List<ECSS_CaseSendAction>{ caseSendAction };

        Test.startTest();
        ECSS_SendEscalationEmails.sendAssignmentandEscalationEmail(caseSendActions);
        Test.stopTest();
    }
}