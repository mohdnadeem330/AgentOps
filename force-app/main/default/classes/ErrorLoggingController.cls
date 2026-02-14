public class ErrorLoggingController {
    
    public static void logErrors(String className, String methodName, String errorMessage, String stackTrace, String severity){
        Logger__c logObj = new Logger__c();
        logObj.Traced_User__c = UserInfo.getUserId();
        logObj.ClassName__c = className;
        logObj.MethodName__c = methodName;
        logObj.ExceptionMessage__c = errorMessage;
        logObj.StackTrace__c = stackTrace;
        logObj.Severity__c = severity;
        
        insert logObj;
        
        if(logObj.Severity__c == 'High') sendEmailNotification(logObj);
    }
    
    private static void sendEmailNotification(Logger__c logObj){
        List<String> emailAddress = new List<String>();
        
        List<ApexEmailNotification> exceptionEmail = [SELECT Id, UserId, User.Email, Email FROM ApexEmailNotification where UserId != null];
        
        if(!exceptionEmail.isEmpty() || Test.isRunningTest()){
            
            if(Test.isRunningTest()) emailAddress.add(UserInfo.getUserEmail());
            
            for(ApexEmailNotification notifObj : exceptionEmail){
                if(notifObj.User.Email != null) emailAddress.add(notifObj.User.Email);
            }
            
            List<Messaging.SingleEmailMessage> newlogsEmailList = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setHtmlBody(prepareFinalEmailBody(logObj));
            mail.setSubject('Need Attention with Error Log: '+logObj.Name);
            mail.setToAddresses(emailAddress);
            
            newlogsEmailList.add(mail);
            
            if(!newlogsEmailList.isEmpty()) Messaging.sendEmail(newlogsEmailList);
        }
    }
    
    private Static String prepareFinalEmailBody(Logger__c logObj){
        String logNotificationTemplateId = [SELECT Id, DeveloperName, Name FROM EmailTemplate where DeveloperName='ErrorLoggingNotification' LIMIT 1].Id;
        String recordUrl = System.URL.getOrgDomainUrl().toExternalForm()+'/'+logObj.Id;
        system.debug(Messaging.renderStoredEmailTemplate(logNotificationTemplateId, null, logObj.Id).getHtmlBody());
        String emailBody = Messaging.renderStoredEmailTemplate(logNotificationTemplateId, null, logObj.Id).getHtmlBody().replace('!=ERROR=!', logObj.ExceptionMessage__c);
        emailBody = emailBody.replace('!=CLASS=!', logObj.ClassName__c);
        emailBody = emailBody.replace('!=RECORDLINK=!', '<a href="' +recordUrl+'">'+recordUrl+'</a>');
        
        return emailBody;
    }
}