/**
* @File Name : DMPortalAuthController.cls
* @Description : Handles username retrieval and email notifications for the DM Portal
* @Author :
* @Last Modified By : neelesh 
* @Last Modified On : July 17, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 7, 2025 |   | Initial Version
* 1.1 | July 17, 2025 | Refactored to use dynamic EmailTemplate queries
**/

public with sharing class DMPortalAuthController {
    
    private static final Set<String> ALLOWED_PROFILES = new Set<String>{
        'DM PMC Manager Partner',
        'DM PMC Team Partner Login',
        'DM Requestor Partner Login'
    };
    
    private static Map<String, Integer> rateLimitMap = new Map<String, Integer>();
    private static final Integer MAX_ATTEMPTS_PER_HOUR = 5;

    @AuraEnabled
    public static UsernameResponse retrieveUsername(String email) {
        UsernameResponse response = new UsernameResponse();
        
        try {
            if (String.isBlank(email) || !isValidEmail(email)) {
                response.success = false;
                response.message = 'Please enter a valid email address';
                return response;
            }

            if (!checkRateLimit(email)) {
                response.success = false;
                response.message = 'Too many attempts. Please try again later';
                return response;
            }

            List<User> users = [
                SELECT Id, Username, Email, IsActive, Profile.Name, ContactId
                FROM User
                WHERE Email = :email
                LIMIT 1
            ];

            if (users.isEmpty()) {
                response.success = false;
                response.message = 'No account found with this email address';
                Id templateId = getTemplateIdByDeveloperName('Username_Not_Found_Template');
                sendEmailSafely(email, null, templateId);
                logAttempt(email, false);
                return response;
            }

            User foundUser = users[0];

            if (!foundUser.IsActive) {
                response.success = false;
                response.message = 'Account is not active. Please contact support';
                logAttempt(email, false);
                return response;
            }

            if (!ALLOWED_PROFILES.contains(foundUser.Profile.Name)) {
                response.success = false;
                response.message = 'Account is not authorized for this portal';
                logAttempt(email, false);
                return response;
            }

            response.success = true;
            response.username = foundUser.Username;
            response.message = 'Username retrieved successfully';
            logAttempt(email, true);
            Id templateId = getTemplateIdByDeveloperName('Username_Found_Template');
            sendEmailSafely(email, foundUser, templateId);

        } catch (Exception e) {
            response.success = false;
            response.message = 'An error occurred. Please contact support';
            System.debug('Error in retrieveUsername: ' + e.getMessage());
            logError(email, e);
        }

        return response;
    }

    private static void sendEmailSafely(String email, User foundUser, Id templateId) {
        try {
            Boolean isGuestUser = UserInfo.getUserType() == 'Guest';
            if (isGuestUser) {
                sendEmailForGuestUser(email, foundUser, templateId);
            } else {
                sendEmailForAuthenticatedUser(email, foundUser, templateId);
            }
        } catch (Exception e) {
            System.debug('Error in sendEmailSafely for ' + email + ': ' + e.getMessage());
            sendPlainTextEmailFallback(email, foundUser);
        }
    }
   @TestVisible
    private static void sendEmailForGuestUser(String email, User foundUser, Id templateId) {
        try {
            if (foundUser != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { email });
                mail.setTemplateId(templateId);
                mail.setTargetObjectId(foundUser.Id);
                mail.setSaveAsActivity(false);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                System.debug('Guest user email sent successfully with User target: ' + email);
                return;
            }
        } catch (Exception e) {
            System.debug('Method 1 failed for guest user: ' + e.getMessage());
        }

        throw new EmailException('Template email failed for guest user');
    }

    private static void sendEmailForAuthenticatedUser(String email, User foundUser, Id templateId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { email });
        mail.setTemplateId(templateId);
        
        if (foundUser != null) {
            if (foundUser.ContactId != null) {
                mail.setTargetObjectId(foundUser.ContactId);
                mail.setSaveAsActivity(true);
            } else {
                mail.setTargetObjectId(foundUser.Id);
                mail.setSaveAsActivity(false);
            }
        } else {
            mail.setTargetObjectId(UserInfo.getUserId());
        }

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        System.debug('Authenticated user email sent successfully: ' + email);
    }

    private static void sendPlainTextEmailFallback(String email, User foundUser) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { email });
            mail.setSaveAsActivity(false);

            if (foundUser != null) {
                mail.setSubject('Your DM Portal Username');
                mail.setPlainTextBody('Hello,\n\nYour DM Portal username is: ' + foundUser.Username + 
                    '\n\nYou can use this username to access the portal.\n\nBest regards,\nDM Portal Team');
            } else {
                mail.setSubject('DM Portal - Account Not Found');
                mail.setPlainTextBody('Hello,\n\nWe could not find an account associated with this email address (' + email + ').\n\n' +
                    'Please contact support if you believe this is an error.\n\nBest regards,\nDM Portal Team');
            }

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Plain text fallback email sent successfully: ' + email);

        } catch (Exception e) {
            System.debug('Even plain text fallback failed for ' + email + ': ' + e.getMessage());
        }
    }

    private static Id getTemplateIdByDeveloperName(String developerName) {
        try {
            EmailTemplate tmpl = [
                SELECT Id
                FROM EmailTemplate
                WHERE DeveloperName = :developerName
                LIMIT 1
            ];
            return tmpl.Id;
        } catch (Exception e) {
            System.debug('Failed to find template: ' + developerName + ' → ' + e.getMessage());
            return null;
        }
    }

    private static Boolean isValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        return Pattern.compile(emailRegex).matcher(email).matches();
    }

    private static Boolean checkRateLimit(String email) {
        try {
            String key = email.toLowerCase() + '__' + String.valueOf(System.now().hour());
            Integer attempts = rateLimitMap.get(key);
            if (attempts == null) attempts = 0;
            if (attempts >= MAX_ATTEMPTS_PER_HOUR) return false;
            rateLimitMap.put(key, attempts + 1);
            return true;
        } catch (Exception e) {
            System.debug('Error in rate limiting: ' + e.getMessage());
            return true;
        }
    }

    private static void logAttempt(String email, Boolean success) {
        System.debug('Username retrieval attempt -- Email: ' + email +
                     ', Success: ' + success + ', Time: ' + System.now());
    }

    private static void logError(String email, Exception e) {
        System.debug('Error in username retrieval -- Email: ' + email +
                     ', Error: ' + e.getMessage());
    }

    public class EmailException extends Exception {}

    public class UsernameResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String username { get; set; }

        public UsernameResponse() {
            this.success = false;
            this.message = '';
            this.username = '';
        }
    }
}