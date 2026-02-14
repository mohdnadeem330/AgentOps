@isTest
public class VerifyLeadControllerTest {

    @isTest
    public static void testVerifyLead(){
        Test.startTest();
        String responseBody = '{"success":true}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        Lead leadRec = TestObjectsFactory.getLeadRecord(001,'Person');
        insert leadRec;
        VerifyLeadController.getAccounts(leadRec.Id);
        VerifyLeadController.submitForApprovals(leadRec.Id, 'POA Holder', '');
        VerifyLeadController.updateExistingAccountOnLead(leadRec.Id, null );
        Test.stopTest();
        
    }
    @isTest
    public static void testVerifyLead2(){
        Test.startTest();
        String responseBody = '{"success":true}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        User custMgmtUserRecord = TestObjectsFactory.getUserRecord(Constants.SALES_MANAGER, 'testUser');
        custMgmtUserRecord.ManagerId = UserInfo.getUserId();
        insert custMgmtUserRecord;
        System.runAs(custMgmtUserRecord){
            Lead leadRec = TestObjectsFactory.getLeadRecord(001,'Person');
            leadRec.LeadSource = 'Direct Call';
            leadRec.EnquiryCategory__c = 'Aldar Employees';
            leadRec.EnquiryTrigger__c = 'Aldar Academies';
            leadRec.CountryOfResidence__c = 'United Arab Emirates';
            insert leadRec;
            VerifyLeadController.submitForApprovals(leadRec.Id, 'POA Holder', '');
        }
        
        Test.stopTest();
        
    }
}