@isTest
public class DM_CommunityAuthCtrlTest {
    @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        conRecord.MobilePhone='971123456789';
        conRecord.BrokerLoginOTPNumber__c='123456';
        update conRecord;
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
    }
    @isTest static void dologintest(){
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,userName from User where contactId = :conRecord.Id limit 1];
        system.setPassword(userRecord.Id, 'Test@123');
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetSMSNotificationSuccess');
        mock.setStatusCode(200);
         Test.setMock(HttpCalloutMock.class, mock);
        try{          
           DM_CommunityAuthCtrl.sendSMSMFAlogin(userRecord.userName);          
        }catch(Exception e){
            
        }
    }
    @isTest static void dologintest2(){
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,userName from User where contactId = :conRecord.Id limit 1];        
        try{          
          DM_CommunityAuthCtrl.verifyOTP(userRecord.userName, 'Test@123','/', '123456');         
        }catch(Exception e){
            
        }
        try{       
          DM_CommunityAuthCtrl.maskPhoneNumber('12234355');
        }catch(Exception e){
            
        }
    }
    @isTest static void CommunityAuth() {
        Contact conRecord = [select id from Contact limit 1];
        User userRecord = [select id,userName from User where contactId = :conRecord.Id limit 1];
        try{
           DM_CommunityAuthCtrl.doLogin(userRecord.userName, 'Test@123', '/');           
        }catch(Exception e){
            
        }
      
    }
}