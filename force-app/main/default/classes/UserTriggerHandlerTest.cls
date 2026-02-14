@isTest(SeeAllData=false)
public class UserTriggerHandlerTest {
    @isTest static void setupMethod() {
        UserRole userrole1 = [Select Id, DeveloperName From UserRole Where DeveloperName = 'CEO' Limit 1];
        User userRecord1 = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        userRecord1.UserRoleId = userrole1.id;
        insert userRecord1;
        
        Profile Profile = [SELECT id FROM profile WHERE name = 'Agency Admin'];
        
        System.runAs(userRecord1) {
            
            Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
            insert accountRecord;
            
           // Contact conRecord = TestObjectsFactory.contactDataSetup(accountRecord.id);
            Contact conRecord = new Contact();
            conRecord.Lastname='Alice';
            conRecord.AccountId = accountRecord.Id;
            conRecord.Email = 'ajay@pwc.com';
            insert conRecord;
            
            UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Broker_Relations_Manager_DXB' Limit 1];
            
            User userRecord = TestObjectsFactory.getUserRecord('Agency User', 'userName');
            userRecord.ContactId = conRecord.Id;
            //userRecord.UserRoleId = userrole.Id;
            userRecord.PortalRole = 'Manager';
            
            Test.startTest();
            insert userRecord;       
            
			TriggerHandler.processedIds = new Set<Id>();

            userRecord.ProfileId = Profile.id;
            userRecord.isActive = false;
            update userRecord;
            
            Test.stopTest();   
        }
    }
}