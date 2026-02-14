/***
Class       : DM_CommunityAuthCtrl
Author      : Smaartt
Last Modified By:
Description : This class is used to do custom login and SMS Otp verification on community
TestClass   : DM_CommunityAuthCtrlTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              30/07/2024           Initial Version 
****************************************************************************************************************/
public without sharing class DM_CommunityAuthCtrl {
    @AuraEnabled
    public static string doLogin(String username, String password,String startUrl){
        try {
            String isSMSOTP =Label.DM_EnableSMSMFA.trim().toUpperCase();
            if(isSMSOTP == 'false'){
                ApexPages.PageReference pageRef = Site.login(username,password,starturl);
                if(pageRef != null){
                    return sendSMSMFAlogin(username);
                }
            }else{
                ApexPages.PageReference pageRef = Site.login(username,password,starturl);
                if(pageRef != null) 
                    return pageRef.getUrl();
            }
            throw new CalloutException();
        }catch(Exception e){
            throw new CustomException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String sendSMSMFAlogin(String username){
        //return 'OTP sent *****6023';
       try{
            List<User> userInfo = [SELECT Id, Name, ContactId,Contact.MobilePhone, AccountId, Email 
                                   FROM User WHERE Username =: username AND ContactId != null AND Contact.MobilePhone!= null];
            String otp = String.valueOf(Utilities.getRandomNumber(6));  
            string phoneNo = '';
            if(userInfo.size()>0 != null){
                phoneNo=userInfo[0].Contact.MobilePhone;
                if(phoneNo.startsWith('971')){
                    Contact con = new Contact();
                    con.Id = userInfo[0].ContactId;
                    con.BrokerLoginOTPNumber__c=otp;
                    con.BrokerLoginOTPDateTime__c= Datetime.now();
                    update con;               
                    SmsNotificationAPI.SmsRequest sms = new SmsNotificationAPI.SmsRequest();
                    sms.destination = phoneNo;
                    sms.record = con;
                    sms.smsBody=otp+' '+Label.DmSMSOtpText;
                    SmsNotificationAPI.sendSmsNotification(new list<SmsNotificationAPI.SmsRequest>{sms});
                    return 'OTP sent -'+maskPhoneNumber(phoneNo);
                }else{
                    throw new CustomException('User not registered with valid mobile number.');
                }
                
            }else{
                throw new CustomException('User not registered with valid mobile number.');
            }          
        }catch (Exception e){
            throw new CustomException('User not registered with valid mobile number.');
        } 
    }
    @AuraEnabled
    public static String verifyOTP(String username, String password,String startUrl,string otp){
        try{
            List<User> userInfo = [SELECT Id,Contact.BrokerLoginOTPNumber__c FROM User WHERE Username =: username AND ContactId != null];
            system.debug('userInfo'+userInfo);
            if(userInfo.size()>0){
                string otpSent = userInfo[0].Contact.BrokerLoginOTPNumber__c;
                if(otp.equals(otpSent)){
                    ApexPages.PageReference pageRef = Site.login(username,password,startUrl);
                    if(pageRef != null) 
                        return pageRef.getUrl();
                }else{
                    return 'WrongOTP';
                }
            }
            throw new CustomException();
        }catch (Exception e){
            throw new CustomException(e.getMessage());
        }
        
    }  
    
    public static String maskPhoneNumber(String phoneNumber) {
        return '****' + phoneNumber.substring(phoneNumber.length() - 4);
    }
}