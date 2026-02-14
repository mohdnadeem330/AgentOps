@isTest
public class ECSS_UploadCaseInvocableTest {

    @testSetup
    static void setupTestData() {
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            Case caseObj = TestObjectsFactory.getProvisCase(newAccount);
            caseObj.Description= 'Description 1';
            caseObj.Subject='Subject 1';
            insert caseObj;
        }
    }

    @isTest
    static void testCreateCases() {
        List<Case_Field_Dependency_Revised__mdt> mockDependencies = new List<Case_Field_Dependency_Revised__mdt>{
            new Case_Field_Dependency_Revised__mdt(
                Category__c = 'Category1',
                Sub_Category__c = 'SubCategory1',
                ECSS_Is_ECSS__c = true,
                ECSS_Is_Eltizam__c = true,
                Sub_Vertical__c = 'SubVertical1'
            ),
            new Case_Field_Dependency_Revised__mdt(
                Category__c = 'Category2',
                Sub_Category__c = 'SubCategory2',
                ECSS_Is_ECSS__c = true,
                ECSS_Is_Eltizam__c = false,
                Sub_Vertical__c = 'SubVertical2'
            )
        };

        Test.startTest();

        List<Case> cases = [SELECT Id, Subject, Description FROM Case];

        ECSS_UploadCaseInvocable.CasesWrapper wrapper = new ECSS_UploadCaseInvocable.CasesWrapper();
        wrapper.casesList = cases;

        List<ECSS_UploadCaseInvocable.CasesWrapper> inputList = new List<ECSS_UploadCaseInvocable.CasesWrapper>{wrapper};

        List<ECSS_UploadCaseInvocable.returnWrapper> result = ECSS_UploadCaseInvocable.createCases(inputList);

        Test.stopTest();

        
    }
}