@isTest
public class FinanceCaseInvoiceVfControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a Parent Case
        Id homeFinanceRecordTypeId = Utilities.getRecordTypeId('Case', 'Home Finance');

        Case parentCase = new Case(
            Subject = 'Test Case ',
            Status = 'New',
            CaseCategory__c = 'Home Finance',
            CaseComments__c = 'Home Finance Case',
            Home_Finance_Facilitator__c = 'Huspy',
            Origin = 'Phone',
            SubVertical__c = 'Home Finance',
            Vertical__c = 'Sales',
            RecordTypeId = homeFinanceRecordTypeId 
        );
        insert parentCase;
        // Creating test case records

        // Create Child Cases related to Parent Case
        List<Case> childCases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            childCases.add(new Case(
                Subject = 'Child Case ' + i,
                Status = 'New',
                ParentId = parentCase.Id,
                CaseCategory__c = 'Home Finance',
                Disbursement_Date__c = System.today(),
                Disbursement_Amount__c = 1000 * (i + 1),
                Home_Finance_Facilitator__c = 'Huspy',
                Applicable_Payout_Rate__c = 0.05,
                // TotalCommissionforAldar__c = 100 * (i + 1),
                Bank_Name__c = 'Test Bank',
                RecordTypeId = homeFinanceRecordTypeId 
            ));
        }
        insert childCases;
    }

    @isTest
    static void testFinanceCaseInvoiceVfController() {
        // Fetch the Parent Case created in @testSetup
        Case parentCase = [SELECT Id FROM Case WHERE ParentId != null LIMIT 1];

        // Simulate the VF page context with a caseId parameter
        Test.startTest();
        // Instantiate the controller
        FinanceCaseInvoiceVfController controller = new FinanceCaseInvoiceVfController();
        Test.stopTest();
        
    }
}