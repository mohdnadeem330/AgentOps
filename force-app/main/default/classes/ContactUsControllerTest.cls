@isTest
private class ContactUsControllerTest {
    
    @isTest(SeeAllData=true)  
    static  void callMethods() {

        String query = 'SELECT Title, FirstName, LastName, RoleName__c, Email, MobilePhone, FullPhotoUrl, ProfileName__c FROM User WHERE RoleName__c = \'Head of Broker Management\' OR ProfileName__c IN ( \'Sales Admin\', \'Sales Manager\' )';
        ContactUsController.getUsersQuery(query);
		ContactUsController.getBMandSMTeam();
        ContactUsController.getloggedInUserDetails();
        ContactUsController.getRegionPicklist();
        ContactUsController.getSodicTeamMembers();

    }
}