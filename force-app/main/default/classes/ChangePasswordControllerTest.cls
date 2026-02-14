@IsTest 
private class ChangePasswordControllerTest {

   	@IsTest(SeeAllData=true) 
    public static void testChangePasswordController() {

        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = 'salesforce1';
        controller.newPassword = 'Salesforce1@'; 
        controller.verifyNewPassword = 'Salesforce1@';
                
        System.assertEquals(controller.changePassword(),null, 'controller.changePassword() == null');                           
    }    
}