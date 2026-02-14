@isTest(SeeAllData=false)
public class UserServiceTest {
    @isTest static void setupMethod() {

        
        User userRecord = TestObjectsFactory.getUserRecord('System Administrator', 'userName');

        insert userRecord;

        Profile Profile = [SELECT id FROM profile WHERE name = 'Agency Admin'];

        //List<Id> contactId = new List<Id>();
        Set<Id> userIds = new Set<Id>();
        //contactId.add(contactRecord.Id);
        userIds.add(userRecord.Id);

        Test.startTest();

        UserService.getUsersQuery('SELECT id from user');
        UserService.prepareUserId(userRecord.Username);
       //UserService.getUserDetails(contactId);
        UserService.getUsersById(userIds);
        UserService.getUserEmail(userRecord.id);
        UserService.getCurrentUserId(userRecord.id);
        UserService.getUserDetailByEmail(userRecord.Email);
        UserService.getUsersByRoleName('Admin');
        
        userRecord.Title = 'Administrator';
        userRecord.isActive = false;
        //userRecord.ProfileId = Profile.id;
        update userRecord;
        //UserService.getCurrentUserId('user');
        Test.stopTest();


    }
}