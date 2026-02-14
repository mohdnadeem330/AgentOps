/**
* CommunityAuthControllerTest
*
* Test class for CommunityAuthController
*/
@isTest
private class CommunityAuthControllerTest{
    //Creating Setp data
     @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
         
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
    }
    //Trying to perform login and forgot password operations
    @isTest static void testForgorPass() {
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,userName from User where contactId = :conRecord.Id limit 1];
        CommunityAuthController obj = new CommunityAuthController();
    	boolean frozenUser = CommunityAuthController.checkFrozenUser(userRecord.userName);
        System.assertEquals(frozenUser,false);
        try{
            CommunityAuthController.doLogin(userRecord.userName,'Test','/');
        }catch(Exception e){
            
        }
        try{
            String response = CommunityAuthController.forgotPassowrd(userRecord.userName);
        }catch(Exception e){
            
        }
    }
    //Trying to perform login and forgot password operations
    @isTest static void testLogin() {
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,userName from User where contactId = :conRecord.Id limit 1];
        system.setPassword(userRecord.Id, 'Test@123');
        CommunityAuthController obj = new CommunityAuthController();
    	boolean frozenUser = CommunityAuthController.checkFrozenUser(userRecord.userName);
        System.assertEquals(frozenUser,false);
        try{
            CommunityAuthController.doLogin(userRecord.userName,'Test@123','/');
        }catch(Exception e){
            
        }
        
    }
    
    @isTest static void testSessionLogin() {
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,userName from User where contactId = :conRecord.Id limit 1];
        PortalSessionControl__c ses = new PortalSessionControl__c();
        ses.IsActive__c = true;
        ses.NoOfSessionsAllowed__c = 5;
        insert ses;
        
        try{
            CommunityAuthController.doLogin(userRecord.userName,'Test@123','/');
        }catch(Exception e){
            
        }
    }
    
    @isTest static void testOTPLogin() {
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,userName from User where contactId = :conRecord.Id limit 1];
        system.setPassword(userRecord.Id, 'Test@123');
        CommunityAuthController obj = new CommunityAuthController();
    	boolean frozenUser = CommunityAuthController.checkFrozenUser(userRecord.userName);
        System.assertEquals(frozenUser,false);
        try{
            CommunityAuthController.sendEmailMFAlogin(userRecord.userName);
            CommunityAuthController.verifyOTP(userRecord.userName,'Test@123','/','123456');
            CommunityAuthController.sendBrokerOTPEmail('test@gmail.com','123456');
        }catch(Exception e){}
    }
    
    
}