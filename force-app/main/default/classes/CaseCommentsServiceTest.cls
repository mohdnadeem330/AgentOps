/*
*Created By     : Hardik Vitthani
*Description    : Test class for CaseCommentsService
*/
@isTest
public class CaseCommentsServiceTest {
    @isTest
    public static void testGetCaseCommentsHistory() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;

        Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
        insert cs;

        CaseComment caseComment = TestObjectsFactory.getCaseComment(cs.Id, 'Test');
        insert caseComment;

        try {
            CaseCommentsService.getCaseCommentsHistory(cs.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testCreatenewComments() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        con.Email = 'test@aldar.com.invalid';
        insert con;

        Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
        insert cs;

        try {
            CaseCommentsService.createnewComments(cs.Id, 'Test');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testGetAttachmentURL() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;

        Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
        insert cs;

        TestObjectsFactory.createContentDocumentLink(cs.Id);
        ContentVersion cv = [SELECT Id FROM contentversion LIMIT 1];

        try {
            CaseCommentsService.getAttachmentURL(cs.Id, cv.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
}