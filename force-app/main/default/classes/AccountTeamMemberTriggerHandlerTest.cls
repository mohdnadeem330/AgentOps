@isTest
public class AccountTeamMemberTriggerHandlerTest {
    
    @isTest static void testAccountTeamShareDocument() {
        List<User> us = [SELECT Id FROM User WHERE Profile.name LIKE '%Manager%' AND isActive=true AND Id !=: userinfo.getUserId() limit 1];
     
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
            
            Document__c docRecord= new Document__c(Account__c=acc.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
            insert docRecord;
            
        AccountTeamMember accountMember = new AccountTeamMember();
        accountMember.AccountId = acc.Id;
        accountMember.UserId = us[0].id;
        accountMember.CaseAccessLevel = Constants.NONE_ACCESS;
        accountMember.OpportunityAccessLevel = Constants.NONE_ACCESS;
        accountMember.AccountAccessLevel = 'Read';
        accountMember.TeamMemberRole = Constants.TEAM_ROLE_SALES_MANAGER;
        insert accountMember;
        test.startTest();
        AccountTeamMember atm2 = [Select Id, AccountAccessLevel from AccountTeamMember where Id=: accountMember.id];
        atm2.AccountAccessLevel = 'Edit';
        update atm2;
        
        delete atm2;
        AccountTeamMemberTriggerHandler.documentSharewithTeamMember(null);
        Test.stopTest();
        
    }
}