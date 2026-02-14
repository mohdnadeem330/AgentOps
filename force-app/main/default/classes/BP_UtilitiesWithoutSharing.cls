public without sharing class BP_UtilitiesWithoutSharing {
    
    public static String brokerLeadValidation(Lead newLead){
        Datetime datetimeMinus1Hour = datetime.now().addHours(-1);

        List<Lead> leads = new List<Lead>([SELECT Offer1__c
                                        FROM Lead WHERE 
                                        CreatedDate >: datetimeMinus1Hour AND 
                                        FirstName=: newLead.FirstName AND 
                                        LastName=: newLead.LastName AND 
                                        Email=: newLead.Email AND 
                                        MobileNumber1__c=: newLead.MobileNumber1__c AND 
                                        Project__c =: newLead.Project__c]);

        if(leads != null && !leads.isEmpty()){
            for(Lead lead : leads){
                if(lead.Offer1__c != null && lead.Offer1__c == newLead.Offer1__c){
                    return 'Duplicate';
                }
            }
            return 'Duplicate';
        }
        return 'Unique';
    }

    // send OTP for Broker Portal 2.0
    public static String sendOTP(String contactId, String type, String value) {
        try {
            List<Contact> listBroker = [
                SELECT Id, Name, Email, MobileCountryCode__c, MobilePhone__c, 
                       PrimaryOwner__c, OwnerId 
                FROM Contact 
                WHERE Id = :contactId 
                LIMIT 1
            ];

            if (listBroker != null && !listBroker.isEmpty()) {
                Integer otpNumber = Integer.valueOf(Math.random() * 1000000);
                String otpString = String.valueOf(otpNumber);
                
                // Pad OTP with leading zeros if necessary
                while (otpString.length() < 6) {
                    otpString = '0' + otpString;
                }

                Contact broker = listBroker[0];
                broker.BrokerLoginOTPNumber__c = otpString;
                broker.BrokerLoginOTPDateTime__c = DateTime.now();
                broker.BrokerResendOTP__c = false;

                if (type.equalsIgnoreCase('SMS')) {
                    if (String.isNotBlank(value) &&
                        (value.startsWith('+971') || value.startsWith('971') || value.startsWith('+97') || value.startsWith('97'))) {
                        
                        SmsNotificationAPI.SmsRequest sms = new SmsNotificationAPI.SmsRequest();
                        sms.destination = value;
                        sms.smsBody = 'Dear User,\r\nYour One Time Passcode is ' + otpString + '.\r\n\r\nAldar Properties';
                        sms.record = broker;

                        if (!Test.isRunningTest()) {
                            SmsNotificationAPI.sendSmsNotification(new List<SmsNotificationAPI.SmsRequest>{ sms });
                        }

                        update broker;
                        return 'success';
                    } else {
                        return 'Invalid phone number format';
                    }
                } else if (type.equalsIgnoreCase('EMAIL')) {
                    CommunityAuthController.sendBrokerOTPEmail(value, otpString);
                    update broker;
                    return 'success';
                } else {
                    return 'Invalid OTP type';
                }
            }
            return 'Contact not found';
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e, 'Broker2.0 API', 'BP_SendOTP', 'sendOTP - contactId: ' + contactId));
            return 'Error occurred while sending OTP: ' + e.getMessage();
        }
    }
    
    //get User Record 
    public static User getUser(Id userId){
    
    	return [SELECT Id, Name, Username, contact.Account.AgencyStatus__c, contact.UAENationalityVerified__c,
                       contact.Account.RegistrationExpiryDate__c, contact.Name, contact.Account.RegistrationNumber__c,
                       Manager.Name, ProfileName__c, UserRole.Name, Profile.Name, UserRole.Id, AccountId, ContactId,
                       FirstName, LastName, Contact.AccountId, Contact.PrimaryOwner__c, Contact.PrimaryContact__c,
                       Contact.BrokerType__c, Contact.AgentID__c, Contact.Account.BillingCountry,
                       Contact.Account.BillingState, Contact.Account.AppointmentSystemID__c,
                       Contact.Account.Email__c, Contact.Account.Name, Team__c, Email, UserRoleId, ProfileId,
                       FullPhotoUrl, SmallPhotoUrl, Title, MobilePhone, Contact.MobileCountryCode__c,
                       Contact.MailingCountryCode, Contact.Nationality__c, Contact.ResidentStatus__c,
                       Contact.PassportNumber__c, Contact.PassportExpiryDate__c, Contact.NationalIdNumber__c,
                       Contact.MobilePhone,Contact.Account.Owner.Name, Contact.Account.Owner.Email
                FROM User WHERE Id = :userId];
	}
}