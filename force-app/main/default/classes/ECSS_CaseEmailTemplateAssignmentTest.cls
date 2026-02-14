@isTest
public class ECSS_CaseEmailTemplateAssignmentTest {
    
    @testSetup
    static void setupTestData() {
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            String caseObjectName = 'Case';
            
            
            // Create Account
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            
            // Create Contact
            Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
            insert testContact;
            
            List<Case> caseList = new List<Case>();
            // Create Cases with varying attributes to match the test conditions
            Case case1 = TestObjectsFactory.getProvisCase(testAccount);
            case1.Status = 'New';
            case1.CaseCategory__c = 'Unit Swap';
            case1.Subject = 'Test Case 1';
            case1.ContactId = testContact.Id;
            caseList.add(case1);
            
            Case case2 = case1.clone(true);
            case2.Status = 'In Progress';
            case2.CaseCategory__c = 'Unit Swap';
            case2.Subject = 'Test Case 2';
            case2.ContactId = testContact.Id;
            caseList.add(case2);
            
            Case case3 = case1.clone(true);
            case3.Status = 'In Progress';
            case3.SubVertical__c = 'Provis';
            case3.Subject = 'Test Case 3';
            case3.ContactId = testContact.Id;
            caseList.add(case3);
            
            
            Case case4 = case1.clone(true);
            case4.Status = 'In Progress';
            case4.Subject = 'Test Case 3';
            case4.ECSS_Object_Category__c = 'Khidmah Home';
            case4.CaseCategory__c = 'IFM/ Khidmah Home';
            case4.ContactId = testContact.Id;
            caseList.add(case4);
            
            Id maintenanceRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Maintenance').getRecordTypeId();
            Case case5 = case1.clone(true);
            case5.Status = 'In Progress';
            case5.Subject = 'Test Case 3';
            case5.ECSS_CompanyOptions__c = 'Khidmah';
            case5.SubVertical__c = 'IFM / Khidmah Home';
            case5.ECSS_Object_Category__c = 'Bathroom';
            case5.ContactId = testContact.Id;
            case5.RecordTypeId = maintenanceRecordTypeId;
            caseList.add(case5);
            
            Contract con = new Contract(
                AccountId = testAccount.Id,
                ContractTerm = 12, // in months
                StartDate = Date.today(),
                Status = 'Draft'   // or another valid picklist value from your org
            );
            insert con;
            
            Case case6 = case1.clone(true);
            case6.Status = 'In Progress';
            case6.Subject = 'Test Case 3';
            case6.ECSS_CompanyOptions__c = 'Khidmah';
            case6.SubVertical__c = 'IFM / Khidmah Home';
            case6.ECSS_Object_Category__c= 'Bathroom';
            case6.ECSS_SAPSalesOrganization__c = '1300';
            case6.ECSS_Contract__c =con.Id;
            case6.ContactId = testContact.Id;
            case6.RecordTypeId = maintenanceRecordTypeId;
            caseList.add(case6);
            insert caseList;
			Case cs = [SELECT Id,ECSS_Contract__c,ECSS_SAPSalesOrganization__c from case where ECSS_Contract__c != null limit 1];
			cs.ECSS_SAPSalesOrganization__c = '1300';
			update cs;            
        }
    }
    
    @isTest
    static void testGetEmailTemplate() {
        // Mock Metadata Query Results
        List<ECSS_Case_Email_Template__mdt> mockMetadata = new List<ECSS_Case_Email_Template__mdt>{
            new ECSS_Case_Email_Template__mdt(
                Category__c = 'Unit Swap',
                Sub_Vertical__c = null,
                Email_Template_Name__c = 'UnitSwapEmailTemplate',
                Status__c = 'New',
                Type__c = 'Standard'
            ),
                new ECSS_Case_Email_Template__mdt(
                    Category__c = 'Unit Swap',
                    Sub_Vertical__c = null,
                    Email_Template_Name__c = 'UnitSwapInProgressTemplate',
                    Status__c = 'In Progress',
                    Type__c = 'Standard'
                ),
                new ECSS_Case_Email_Template__mdt(
                    Category__c = null,
                    Sub_Vertical__c = 'Khidmah',
                    Email_Template_Name__c = 'DefaultsCollectionTemplate',
                    Status__c = 'In Progress',
                    Type__c = 'Standard'
                ),
                new ECSS_Case_Email_Template__mdt(
                    Category__c = 'IFM/ Khidmah Home',
                    Object_Category__c = 'Khidmah Home',
                    Email_Template_Name__c = 'DefaultsCollectionTemplate',
                    Status__c = 'In Progress',
                    Type__c = 'Standard'  
                ),
                
                new ECSS_Case_Email_Template__mdt(
                    IFM_Template_Name__c = 'IFMMaintenanceTemplate',
                    Email_Template_Name__c = 'KhidmahMaintenanceTemplate',
                    Active_Template__c = true,
                    Type__c = 'Standard'
                )
                };
                    
                    List<Case> cases = [
                        SELECT Id, RecordTypeId, ECSS_CompanyOptions__c, SubVertical__c, ECSS_Object_Category__c,CaseCategory__c, Status,ECSS_Contract__c,ECSS_SAPSalesOrganization__c,Recordtype_Name__c
                        FROM Case
                    ];
        
        Test.startTest();
        List<ECSS_CaseEmailTemplateAssignment.CaseEmailWrapper> emailTemplates =
            ECSS_CaseEmailTemplateAssignment.getEmailTemplate(cases);
        Test.stopTest();
        
        
    }
}