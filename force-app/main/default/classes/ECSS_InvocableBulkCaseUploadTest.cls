@isTest
public class ECSS_InvocableBulkCaseUploadTest {
    @testSetup
    static void setupTestData() {
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            Case case1 = TestObjectsFactory.getProvisCase(newAccount);
            // case1.ECSS_SAP_Account_Id_Bulk_Upload__c = 'SAP_ACC_001';
            // case1.ECSS_UnitSAPExternalId__c = 'ASSET_001';
            // case1.ECSS_Company_External_Id__c = 'COMP_001';
            
            // Case case2 = TestObjectsFactory.getProvisCase(acc2);
            // case2.ECSS_SAP_Account_Id_Bulk_Upload__c = 'SAP_ACC_002';
            // case2.ECSS_UnitSAPExternalId__c = 'ASSET_002';
            // case2.ECSS_Company_External_Id__c = 'COMP_002';

        insert case1;
        }
    }

    @isTest
    static void testCreateCases() {
        List<Case> cases = [
            SELECT Id, ECSS_SAP_Account_Id_Bulk_Upload__c, ECSS_UnitSAPExternalId__c, ECSS_Company_External_Id__c
            FROM Case
        ];

        ECSS_InvocableBulkCaseUpload.CasesWrapper casesWrapper = new ECSS_InvocableBulkCaseUpload.CasesWrapper();
        casesWrapper.casesList = cases;
        // casesWrapper.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard Case').getRecordTypeId();

        List<ECSS_InvocableBulkCaseUpload.CasesWrapper> wrapperList = new List<ECSS_InvocableBulkCaseUpload.CasesWrapper>{casesWrapper};

        Test.startTest();
        List<ECSS_InvocableBulkCaseUpload.returnCaseWrapper> result = ECSS_InvocableBulkCaseUpload.createCases(wrapperList);
        Test.stopTest();

       
    }
}