/**********************************************************************************************************************
* Name               : CommunityAuthController                                                        
* Description        : Class to perform login and forgot password action for community users
* Usage              : CustomLogin LWC 
* Created By         : PWC Digital Middle East
* Last Modified By	 : tdontha@aldar.com(Tharun)
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           zaid.damer@pwc.com     	06/06/2022      Initial Draft    
* 2.0			tdontha@aldar.com		12/02/2024		Email based OTP logins for portal users (BPE-108)	
******************************************************************************************************************/
//The class is supposed to be executed in without sharing as methods will be accessed by the guest User
public without sharing class CommunityAuthController {
    public CommunityAuthController() {
        
    }
    /**
* doLogin
*
* This method used to login user and return the navigation URL
*
* @param  username
* @param  password
* @param  startUrl
* @return string authenticated URL
*/
    @AuraEnabled
    public static string doLogin(String username, String password,String startUrl){
        try {
            PortalSessionControl__c sessionSetting = PortalSessionControl__c.getInstance();
            
            //Check the login session and restriction.  
            if(sessionSetting != null && sessionSetting.IsActive__c){
                sessionControl(username, sessionSetting.NoOfSessionsAllowed__c);
            }               
            
            //startUrl = System.currentPageReference().getParameters().get('startURL');
            System.Debug('---startUrl---'+startUrl);
            //startUrl = Site.getPathPrefix() + '/SiteLogin?startURL=' + EncodingUtil.urlEncode(startURL, 'UTF-8');
            
            if (checkFrozenUser(username)) { throw new CalloutException('This user is frozen'); }
            //ApexPages.PageReference pageRef = Site.login(username,password,startUrl);
            //ApexPages.PageReference pageRef = Site.login(username,password,'aldarproperties--pruat.sandbox.my.site.com');
            
            String isEmailOTP = Label.EnableEmailMFAPartnerUsers.trim().toUpperCase();
            if(isEmailOTP == 'TRUE'){
                ApexPages.PageReference pageRef = Site.login(username,password,starturl);
                if(pageRef != null){ return sendEmailMFAlogin(username);}
            }else{
                ApexPages.PageReference pageRef = Site.login(username,password,starturl);
                if(pageRef != null) return pageRef.getUrl();
            }
            throw new CalloutException();
        } catch (Exception e) {
            System.debug('Exxxxxx---'+e.getStackTraceString());
            if (e.getMessage() == 'This user is frozen') { throw new AuraHandledException(e.getMessage());
            } else { throw new AuraHandledException('Wrong username or password');}
        }
    }
    
    /**
* forgotPassowrd
*
* This method used to initialize forgot password flow
*
* @param  username
* @return string Success Message
*/
    @AuraEnabled
    public static String forgotPassowrd(String userid) {
        String procesMsg = '';
        User user = [SELECT Id FROM User WHERE Username = :userid]; //Added username in query for test class
        if (user != null) {
            procesMsg = 'LoginResetSuccess';
            if (Site.isValidUsername(userid)) {Site.forgotPassword(userid, 'ForgotPasswordEmail');
            } else { procesMsg = 'LoginResetWarning';
            }
        }
        return procesMsg;
    }
    /**
* checkFrozenUser
*
* This method used return if the user is frozen or not
*
* @param  username
* @return Boolean represents if the user is frozen
*/
    public static Boolean checkFrozenUser(String username) {
        UserLogin user = [SELECT IsFrozen,UserId FROM UserLogin WHERE UserId IN (SELECT Id FROM User WHERE username = :username)];
        return user.IsFrozen;
    }
    
    public static void sessionControl(String username, Decimal numOfSessions) {
        
        List<AuthSession> authSesList = new List<AuthSession>();
        authSesList = [SELECT Id, CreatedDate, IsCurrent, LoginType, LogoutUrl,UserType, UsersId 
                       FROM AuthSession WHERE Users.username =: username AND 
                       LoginType = 'Chatter Communities External User' AND 
                       SessionType = 'ChatterNetworks' ORDER BY CreatedDate ASC];
        
        if(!authSesList.isEmpty() && authSesList.size() >= numOfSessions) {
            SessionControlEvent__e sessionEvent = new SessionControlEvent__e(SessionId__c = authSesList[0].Id);
            EventBus.publish(sessionEvent);
        }
    }
    
    @AuraEnabled
    public static String sendEmailMFAlogin(String username)
    {
        try{
            User loggedInUser = [SELECT Id, Name, ContactId, AccountId, Email 
                                 FROM User WHERE Username =: username AND ContactId != null];
            String otpGeneratedValue = String.valueOf(Utilities.getRandomNumber(6));
            String returnValue = 'LoginFailed';
            
            if (loggedInUser != null) {
                Contact portalUserContact 						= new Contact();
                portalUserContact.Id 							= loggedInUser.ContactId;
                portalUserContact.BrokerLoginOTPNumber__c		= otpGeneratedValue;
                portalUserContact.BrokerLoginOTPDateTime__c		= Datetime.now();
                update portalUserContact;
                //If update is successful send email and return OTP sent and masked email address
                //if(sendBrokerOTPEmail(loggedInUser.Email, otpGeneratedValue))
                
                //Added by Tharun for sending email through FLOW 
                Map<String, Object> flowParams 					= new Map<String, Object>();
                flowParams.put('emailAddress',loggedInUser.Email);
                flowParams.put('otpToBeSent', otpGeneratedValue);
                Flow.Interview.BPSendOTPEmail sendOTPFlow = new Flow.Interview.BPSendOTPEmail(flowParams);
                sendOTPFlow.start();
                System.Debug('sendOTPFlow----'+sendOTPFlow);
                returnValue =  'OTPSent-'+ maskEmail(loggedInUser.Email);
            }
            return returnValue;
        }
        catch (Exception e){throw new AuraHandledException(e.getMessage());} 
    }
    
    
    @AuraEnabled
    public static Map<String, String> verifyOTP(String username,String password, String startUrl, String otpEntered) 
    {
        Map<String, String> returnMap 		= new Map<String,String>();
        Timer__mdt otpTimer 				= Utilities.getTimer(ALD_Constants.BROKER_LOGIN_OTP_TIMER);
        String timerUnit 					= otpTimer.Time__c;
        Integer timerDetails 				= Integer.valueOf(otpTimer.Timer__c);
        
        try{
            User userAfterLogin = [SELECT 
                                   Id,
                                   Name,
                                   ContactId,
                                   AccountId, 
                                   Email,
                                   Contact.BrokerLoginOTPNumber__c,
                                   Contact.BrokerLoginOTPDateTime__c
                                   FROM User WHERE Username =: username AND ContactId != null LIMIT 1];
            
            if (userAfterLogin != null) {
                DateTime otpSentDateTimeWithTimeLimit = userAfterLogin.Contact.BrokerLoginOTPDateTime__c.addMinutes(timerDetails);
                if(Datetime.now() < otpSentDateTimeWithTimeLimit){
                    //OTP entered within time
                    String otpGenerated = userAfterLogin.Contact.BrokerLoginOTPNumber__c;
                    if(otpEntered.equals(otpGenerated)){
                        ApexPages.PageReference pageRef = Site.login(username,password,starturl);
                        if(pageRef != null) {returnMap.put('Success', pageRef.getUrl());}
                    }else{returnMap.put('Failed', 'Incorrect OTP, Please try again.');}
                }else{
                    //OTP entered beyond the time limit
                    returnMap.put('Failed', 'OTP is expired, Click Resend OTP button');
                }
            }
            return returnMap;
        }
        catch (Exception e){throw new AuraHandledException(e.getMessage());}                                   
    }
    
    public static String maskEmail(String emailAddress) {
        if (emailAddress != null && emailAddress.length() > 3) {
            // Split the email address into local and domain parts
            List<String> parts = emailAddress.split('@');
            if (parts.size() == 2) {
                String localPart = parts[0];
                String maskedLocalPart = localPart.length() <= 3 ? localPart : localPart.substring(0, 3) + '*'.repeat(localPart.length() - 3);
                // Reconstruct the masked email address
                return maskedLocalPart + '@' + parts[1];
            }else{
                String maskedEmail = emailAddress.substring(0, 3) + '*'.repeat(emailAddress.length() - 3);
                return maskedEmail;
            }
        } else {
            return emailAddress;
        }
    }
    
    
    public static Boolean sendBrokerOTPEmail(String emailAddress, String otpToBeSent)
    {
        List<Messaging.SingleEmailMessage>	lstEmail 		= new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage sendingEmailMessage	= new Messaging.SingleEmailMessage();
        String emailTemplateName 							= 'BrokerLoginOTPEmail';
        EmailTemplate template 								= [SELECT Id
                                                               FROM EmailTemplate 
                                                               WHERE DeveloperName =: emailTemplateName];
        Id orgWideEmailAddressId 							= [SELECT Id, Address 
                                                               FROM OrgWideEmailAddress 
                                                               WHERE DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_BROKER LIMIT 1].Id;
        Messaging.SingleEmailMessage sEmail 				= Messaging.renderStoredEmailTemplate(template.Id, null, null);
        String htmlBody 									= sEmail.getHtmlBody();
        String subject 										= sEmail.getSubject();
        htmlBody 											= htmlBody.replace('{otpnumber}', String.valueOf(otpToBeSent));
        
        sendingEmailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId);
        //sendingEmailMessage.setCcAddresses(new List<String> {'tdontha@aldar.com'});
        sendingEmailMessage.setSubject(subject);
        sendingEmailMessage.setHtmlBody(htmlBody);
        sendingEmailMessage.setToAddresses(new String[] {emailAddress});
        lstEmail.add(sendingEmailMessage);
        
        if (lstEmail.size() > 0 && lstEmail != null )
        {
            // true	 - By default, this is true, which means that if a record fails, the remainder of DML operations will not be processed	
            // false - If a record fails, the remainder of DML operations can still succeed
            List<Messaging.SendEmailResult> resultsEmails = Messaging.sendEmail(lstEmail, false);
            for(Messaging.SendEmailResult ser: resultsEmails){
                if (!ser.isSuccess()){
                    for(Messaging.SendEmailError objErr: ser.getErrors()){
                        String errorStackTrace = objErr.getTargetObjectId() +' - '+ objErr.getMessage();
                        System.debug('errorStackTrace---'+errorStackTrace);
                        LoggerService.save(BatchToSendEmailsToBrokerAgencies.createApexInfoLog('CommunityAuthController','sendBrokerOTPEmail',errorStackTrace));
                        return false;
                    }
                }else{
                    System.debug('Emails Sent Successfully---'+ser.isSuccess());
                    return true;
                }
            }
        }
        return false;
    }
    
    @AuraEnabled(Cacheable = true)  
    public static Timer__mdt getBrokerOTPTimer()
    {
        return [SELECT Id, DeveloperName, Time__c, Timer__c FROM Timer__mdt WHERE
                DeveloperName = 'BrokerLogin' LIMIT 1];
    }
    
}