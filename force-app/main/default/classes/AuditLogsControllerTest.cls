@isTest
public class AuditLogsControllerTest {
    @isTest
    static void testGetCaseHistoryRecords() {

        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
			Type = 'NOC',
            Development_Name__c='Yas Island'//,
            //Sub_Status__c='Additional Information Required from Customer'
        );
        
		
		
        List<CaseHistory> debugHistory = [SELECT Field, OldValue, NewValue FROM CaseHistory WHERE CaseId = :testCase.Id];
        System.debug('DEBUG HISTORIES: ' + debugHistory);
        Test.startTest();
        insert testCase;
        CaseHistory mockHistory = new CaseHistory(
            CaseId = testCase.Id,
            Field = 'Status'
        );
        insert mockHistory;
        testCase.Status = 'Closed';
        testCase.CaseCategory__c = 'Access Card';
        update testCase;
        List<AuditLogsController.CaseHistoryWrapper> historyList = AuditLogsController.getCaseHistoryRecords(testCase.Id);
        Test.stopTest();
		System.debug('Returned history list: ' + historyList);
        System.assertNotEquals(0, historyList.size(), 'History should not be empty');
    }
    
    @isTest
    static void testWrapperConstructor() {
        AuditLogsController.CaseHistoryWrapper wrapper1 = new AuditLogsController.CaseHistoryWrapper(
            Datetime.now(), 'User', 'Field', 'Old', 'New'
        );
        System.assertEquals('Field: Old changed to New', wrapper1.description);
        
        AuditLogsController.CaseHistoryWrapper wrapper2 = new AuditLogsController.CaseHistoryWrapper(
            Datetime.now(), 'User', 'Field', null, 'New'
        );
        System.assertEquals('Field:  changed to New', wrapper2.description);
        
        AuditLogsController.CaseHistoryWrapper wrapper3 = new AuditLogsController.CaseHistoryWrapper(
            Datetime.now(), 'User', 'Field', 'Old', null
        ); 
        System.assertEquals('Field: Old changed to ', wrapper3.description);
        
        AuditLogsController.CaseHistoryWrapper wrapper4 = new AuditLogsController.CaseHistoryWrapper(
            Datetime.now(), 'User', 'Field', null, null
        );
        System.assertEquals('', wrapper4.description);
    }
}