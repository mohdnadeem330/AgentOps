/*
*Created By     : Hardik Vitthani
*Description    : Test class for SetNewPassword
*/
@isTest
public class SetNewPasswordTest {
    @isTest
    public static void testSetNewPassword() {
        Test.startTest();

        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        User newUser = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'newuseradmin');
        newUser.UserRoleId = portalRole.Id;
        newUser.Email = 'test@aldar.com.invalid';
        insert newUser;

        System.runAs(newUser) {
            Account acc = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
            insert acc;

            Contact con = new Contact();
            con.LastName = 'Alice';
            con.FirstName = 'Alice';
            con.AccountId = acc.Id;
            con.BrokerType__c = Constants.AGENCY_ADMIN;
            insert con;

            User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
            agencyAdmin.ContactId = con.Id;
            agencyAdmin.Email = 'test.portal@aldar.com.invalid';
            insert agencyAdmin;

            try {
                SetNewPassword.calFutureMethod(new List<Id>{con.Id});
            } catch(System.EmailException ex){
                System.debug('ex>>>' + ex);
            } catch (Exception ex) {
                System.debug('ex>>>' + ex);
            }
        }

        Test.stopTest();
    }
}