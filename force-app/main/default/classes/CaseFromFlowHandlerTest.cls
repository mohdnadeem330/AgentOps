@isTest
public class CaseFromFlowHandlerTest {
	@testSetup static void setupData() {
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PassportNumber__pc = 'X170930923';
        acc.Nationality__pc = 'India';
        acc.PersonMobilePhone = '+918980676862';
        acc.PersonBirthdate = System.today()-30;
        acc.ERPID__c = 'X170930923';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
    }
    
    @isTest static void unitTest1() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Prepare the InputWrapper for the InvocableMethod
        CaseFromFlowHandler.InputWrapper input = new CaseFromFlowHandler.InputWrapper();
        input.submitterAccountId = acc.Id;
        input.callFromFlowName = 'UpdateAccountContactDetails';
        input.email = 'merge.case@test.com';
		User u = [SELECT Id FROM User WHERE Profile.name = 'Sales Manager' AND isActive = true LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<CaseFromFlowHandler.OutputWrapper> resultList = CaseFromFlowHandler.createCaseFromFlow(new List<CaseFromFlowHandler.InputWrapper>{ input });
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testCheckDuplicateRecordByEmail_NoDuplicate() {
        // Create a Case with related Account
        Account acc = [SELECT Id, PersonEmail FROM Account LIMIT 1];
        Case c = new Case(
            AccountId = acc.Id,
            Email__c = acc.PersonEmail,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Requests' LIMIT 1].Id,
            CaseCategory__c = 'Contact Center',
            SubCategory__c = 'Contact Details Update',
            Subject = 'Test Case'
        );
        insert c;

        Test.startTest();
        Boolean result = CaseFromFlowHandler.checkDuplicateRecordByEmail(c.Id);
        Test.stopTest();
    }
}