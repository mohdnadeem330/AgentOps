@isTest
private class CustomerUnitContractStatusSchedulerTest {
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
        
        
        contract cont = TestObjectsFactory.getKhidmahContracts(testAccount.Id);
        cont.EndDate = System.today()+1;
        cont.ECSS_ContractOrganizationType__c = 'IFM';
        insert cont;
        
        Unit_Contract__c unitCont = TestObjectsFactory.getKhidmahContractDetail(testCase.AssetId,cont.Id);
        insert unitCont;
        
        Account comp = TestObjectsFactory.getECSSCompany();
        insert comp;
        
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
        
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert ecssUnit;            
        TestObjectsFactory.getCustomerUnit(testAccount.Id, ecssUnit.Id);
        Customer_Unit__c asUnit = [SELECT Id,Unit__c,Active__c FROM Customer_Unit__c limit 1];
        unitCont.ECSS_CustomerUnit__c = asUnit.id;
        asUnit.Active__c =  false;
        update unitCont;
        update asUnit;
        FM_Companies__c fm = TestObjectsFactory.getFMCompany(testCase.AssetId, comp.Id);
        insert fm;
        // Instantiate the schedulable class
        CustomerUnitContractStatusScheduler schedBatch = new CustomerUnitContractStatusScheduler();
        
        // Define the schedule string (e.g., every day at midnight)
        String sch = '0 0 0 * * ?';
        
        Test.startTest();
        // Schedule the class
        asUnit.Active__c =  true;
        update asUnit;
        
        cont.EndDate = System.today()-2;
        update cont;
        String jobId = System.schedule('Test Scheduled Batch', sch, schedBatch);
        List<Id> recordIds = new List<id>();
        recordIds.add(asUnit.id);
        contractDetailsUpdateCU.checkRecords(recordIds);
        Test.stopTest();
    }
}