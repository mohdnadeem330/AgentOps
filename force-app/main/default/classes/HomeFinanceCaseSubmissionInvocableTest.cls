@isTest
public class HomeFinanceCaseSubmissionInvocableTest {
    
    @testSetup
    static void setupTestData() {
        Id homeFinanceRecordTypeId = Utilities.getRecordTypeId('Case', 'Home Finance');
        // Creating test case records
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 1; i++) {
            cases.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New',
                CaseCategory__c = 'Home Finance',
                CaseComments__c = 'Home Finance Case',
                Home_Finance_Facilitator__c = 'Huspy',
                Origin = 'Phone',
                SubVertical__c = 'Home Finance',
                Vertical__c = 'Sales',
                RecordTypeId = homeFinanceRecordTypeId 
            )
            );
        }
        insert cases;

        List<Contact> listContact = new List<Contact>();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;

        Contact conta1 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        conta1.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta1.AgentStatus__c = 'Active';
        conta1.PrimaryOwner__c = true;
        
        listContact.add(conta1);
        update listContact;
    }

    @isTest
    static void testUploadHomeFinancelTaxInvoiceLetter() {
        // Fetch the test cases
        Map<Id,Case> cases = new Map<Id,Case>([SELECT Id FROM Case LIMIT 1]);
        List<Id> caseIds = new List<Id>();
        for(Id key : cases.keySet()){
            caseIds.add(key);
        }

        // Call the method
        Test.startTest();
        HomeFinanceCaseSubmissionInvocable.uploadHomeFinancelTaxInvoiceLetter(caseIds);
        Test.stopTest();
    }
}