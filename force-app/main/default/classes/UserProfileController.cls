public without sharing class UserProfileController {

    @AuraEnabled(cacheable=false)
    public static USER getUserProfileDetails(){
        // Updated By Moh Sarfaraj for BPE-130
        return [select Contact.Id, Contact.Email, Contact.MailingCity, Contact.MailingCountry, Contact.MobilePhone, 
                Contact.FirstName,Contact.LastName, Contact.MailingPostalCode, Account.Name, Account.Id, 
                Account.AccountNumber__c, Account.AgencyRegion__c, Account.RegistrationExpiryDate__c, 
                Account.RegistrationNumber__c, Account.PlaceOfRegistration__c, Account.BranchAddress__c, 
                Account.BankName__c, Account.Email__c, Account.BrokerAgent__r.FirstName, Account.SwiftCode__c, 
                Account.CurrencyIsoCode, Account.IBANNumber__c, Account.BankCountry__c, Account.BillingCity, 
                Account.Phone, Account.BillingCountry, Account.MobileNumber__c,  Account.BillingPostalCode,  Account.BillingState,
                Account.ApprovalStatus__c, Account.ProposedBankDetailStatus__c, Profile.Name,FullPhotoUrl,
                Account.BankAccountNumber__c, Account.Description, Email, Account.BeneficiaryName__c,Account.UAEVATRegisterNumber__c,
                Contact.MobileCountryCode__c,Contact.Name,
                Contact.PrimaryAgencyAdmin__c, Contact.ProposedEmail__c, Contact.MobilePhone__c,
                Contact.ProposedMobileCountryCode__c, Contact.ProposedMobilePhone__c, Contact.AgentStatus__c, Contact.BrokerType__c,
                Contact.AgentID__c ,AccountId, Account.VATRegistrationStartDate__c, Account.VATRegistrationEndDate__c
                from USER WHERE Id=:UserInfo.getUserId() limit 1];
    }
    
    @AuraEnabled(cacheable=false)
    public static map<string,string> uploadUserPicture(string baseData){
        map<string,string> returnResponse = new map<string,string>();
        returnResponse.put('success','false');
        try{
            blob picData = EncodingUtil.base64Decode(baseData);
            ConnectApi.BinaryInput fileUpload = new ConnectApi.BinaryInput(picData,'image/jpg', 'ProfileImage');
            ConnectApi.Photo photoProfile = ConnectApi.UserProfiles.setPhoto(ConnectApi.Communities.getCommunities().communities[0].id, UserInfo.getUserId(), fileUpload);
            returnResponse.put('success','true');
            returnResponse.put('data',photoProfile.mediumPhotoUrl);
            returnResponse.put('msg','Image updated successfully, please allow sometime to get it reflected at all places');
        }catch(exception e){
            returnResponse.put('msg',e.getMessage());
        }
        
        return returnResponse;
    }

    @AuraEnabled(cacheable=true)
    public static HexaBPM__SR_Doc__c getSRDocId(String accountId, String documentType){
        return [select id from HexaBPM__SR_Doc__c where HexaBPM__Customer__c =: accountId AND DocumentMasterCode__c =:documentType limit 1];
    }

    @AuraEnabled(cacheable=false)
    public static void updateMobilePhone(Id contactId, String mobileNumber){
        Contact contactRec = new Contact(Id=contactId);
        contactRec.MobilePhone = mobileNumber;
        contactRec.MobilePhone__c = mobileNumber;
        contactRec.MobileNumberEnc__c = mobileNumber;
        update contactRec;
    }

    @AuraEnabled
    public static void resetPassowrd(String newPassword, String verifyNewPassword, String oldPassword) {
        Site.changePassword(newPassword, verifyNewPassword, oldPassword);
    }

    @AuraEnabled(cacheable=false)
    public static void updateProposedExpiryDate(Id accountId, Date proposedExpiryDate, String proposedUAEVATRegistrationNumberValue,Date ProposedStartdate){
        system.debug('accountId:::'+accountId);
        system.debug('proposedExpiryDate:::'+proposedExpiryDate);
        system.debug('proposedUAEVATRegistrationNumberValue:::'+proposedUAEVATRegistrationNumberValue);
        Account accountRec =[SELECT Id,OwnerId,ProposedUAEVATRegisterNumber__c,ProposedVATStartDate__c,ProposedVATExpiryDate__c FROM Account 
                             WHERE Id =:accountId LIMIT 1];
        
        if(proposedExpiryDate != null || ProposedStartdate!=null){
            accountRec.ProposedVATExpiryDate__c = proposedExpiryDate; 
            accountRec.ProposedVATStartDate__c=ProposedStartdate;
        }
        if(proposedUAEVATRegistrationNumberValue != null){
            accountRec.ProposedUAEVATRegisterNumber__c = proposedUAEVATRegistrationNumberValue; 
        }
        //accountRec.BrokerUserSubmitter__c = UserInfo.getUserId(); 
        system.debug('accountRec:::'+accountRec);
        update accountRec;

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Documents uploaded for review.');
        req1.setObjectId(accountId);
        //---- Submit as logged in user
        req1.setSubmitterId(accountRec.OwnerId);
        //---- Submit the record to specific process
        if(proposedUAEVATRegistrationNumberValue != null){
            req1.setProcessDefinitionNameOrId('BrokerUAEVATApproval');
        }else if(proposedExpiryDate != null){
            req1.setProcessDefinitionNameOrId('BrokerDocuments');
        }
        req1.setSkipEntryCriteria(true);
        //---- Submit the approval request for the opportunity    
        Approval.ProcessResult result = Approval.process(req1);
        //vals to return
    }

    @AuraEnabled(cacheable=false)
    public static void updateVATDetails(Id accountId, String vatValue, Date proposedVATStartDate, Date proposedVATExpiryDate, String proposedUAEVATRegistrationNumberValue){
    
        Account accountRec =[SELECT Id,OwnerId,ProposedVATRegistrationtype__c,ProposedVATStartDate__c,ProposedVATExpiryDate__c FROM Account 
                             WHERE Id =:accountId LIMIT 1];
        
        if(vatValue != null){
            accountRec.ProposedVATRegistrationtype__c = vatValue;
        }
        if(proposedVATStartDate != null){
            accountRec.ProposedVATStartDate__c = proposedVATStartDate; 
        }
        if(proposedVATExpiryDate != null){
            accountRec.ProposedVATExpiryDate__c = proposedVATExpiryDate; 
        }
        if(proposedUAEVATRegistrationNumberValue != null){
            accountRec.ProposedUAEVATRegisterNumber__c = proposedUAEVATRegistrationNumberValue; 
        }
       
        update accountRec;

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Documents uploaded for review.');
        req1.setObjectId(accountId);
        req1.setSubmitterId(accountRec.OwnerId);
       
        if(proposedUAEVATRegistrationNumberValue != null){
            req1.setProcessDefinitionNameOrId('BrokerUAEVATApproval');
        }
        req1.setSkipEntryCriteria(true);
          
        Approval.ProcessResult result = Approval.process(req1);
    }

    /**
    * getPicklistValuesGeneric
    * This method used to
    * @param String
    * @param String
    * @return List<Map<String,String>>
    * @description Added By Moh Sarfaraj for BPE-130
    */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getPicklistValuesGeneric(String sObjectName, String fieldName){
        Schema.DescribeSObjectResult objDescribeSobject = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Map<String,String>> picklistToReturn = new List<Map<String,String>>();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            Map<String,String> tempMap = new Map<String,String>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }

    /**
    * getPrimaryOwnerOrAdminDetails
    * This method used to
    * @param String
    * @return List<Map<String,String>>
    * @description Added By Moh Sarfaraj for BPE-130
    */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getPrimaryOwnerOrAdminDetails(String accountId){
        try{
            if(String.isNotBlank(accountId)){
                String otpReceiver = System.Label.BPM_BankOTPOwnership.deleteWhiteSpace().toUpperCase(); // PrimaryAdmin / PrimaryOwner
                List<Contact> listContact = new List<Contact>();

                if(otpReceiver.equalsIgnoreCase('PRIMARYADMIN')){
                    listContact = new List<Contact>();
                    listContact = [SELECT Id,FirstName,LastName,Name,Email,MobilePhone__c,MobileCountryCode__c 
                                   FROM Contact WHERE AgentStatus__c = 'Active' AND MobilePhone__c != null AND 
                                   Email != null AND AccountId = :accountId AND BrokerType__c = 'Agency Admin' 
                                   AND PrimaryAgencyAdmin__c = true ORDER By LastModifiedDate DESC LIMIT 1];

                }else if(otpReceiver.equalsIgnoreCase('PRIMARYOWNER')){
                    listContact = new List<Contact>();
                    listContact = [SELECT Id,FirstName,LastName,Email,Name,MobilePhone__c,MobileCountryCode__c 
                                   FROM Contact WHERE AgentStatus__c = 'Active' AND MobilePhone__c != null AND 
                                   Email != null AND AccountId = :accountId AND BrokerType__c = 'Partner/Owner' 
                                   AND PrimaryOwner__c = true ORDER By LastModifiedDate DESC LIMIT 1];
                }

                return (!listContact.isEmpty() && String.isNotBlank([SELECT Id FROM User WHERE ContactId = :listContact[0].Id AND IsActive = true]?.Id)) ? listContact : new List<Contact>();
            }
            return new List<Contact>();
        }catch (Exception e){throw new AuraHandledException(e.getMessage());}
    }

    /**
    * sentOTP
    * This method used to
    * @param String
    * @param String
    * @return String
    * @description Added By Moh Sarfaraj for BPE-130
    */
    @AuraEnabled(cacheable=false)
    public static String sentOTP(String accountId, String type){
        //try{
            String otpReceiver = System.Label.BPM_BankOTPOwnership.deleteWhiteSpace().toUpperCase(); // PrimaryAdmin / PrimaryOwner

            if(String.isNotBlank(otpReceiver) && String.isNotBlank(accountId) && String.isNotBlank(type)){
                List<Contact> listContact;
                if(otpReceiver.equalsIgnoreCase('PRIMARYADMIN')){
                    listContact = new List<Contact>();
                    listContact = [SELECT Id,Name,Email,MobileCountryCode__c,MobilePhone__c,BrokerLoginOTPNumber__c,
                                   BrokerLoginOTPDateTime__c,OwnerId FROM Contact WHERE AccountId = :accountId AND 
                                   BrokerType__c = 'Agency Admin' AND PrimaryAgencyAdmin__c = true 
                                   ORDER By LastModifiedDate DESC LIMIT 1];

                }else if(otpReceiver.equalsIgnoreCase('PRIMARYOWNER')){
                    listContact = new List<Contact>();
                    listContact = [SELECT Id,Name,Email,MobileCountryCode__c,MobilePhone__c,BrokerLoginOTPNumber__c,
                                   BrokerLoginOTPDateTime__c,OwnerId FROM Contact WHERE AccountId = :accountId AND 
                                   BrokerType__c = 'Partner/Owner' AND PrimaryOwner__c = true 
                                   ORDER By LastModifiedDate DESC LIMIT 1];
                }

                if(listContact != null && !listContact.isEmpty()){
                    Integer sixDigitOTPNumber = Integer.valueof((Math.random() * 1000000));
                    listContact[0].BrokerLoginOTPNumber__c = String.valueOf(sixDigitOTPNumber);
                    listContact[0].BrokerLoginOTPDateTime__c = Datetime.now();

                    if(type == 'sms'){
                        String countryCode = listContact[0].MobileCountryCode__c;
                
                        if(countryCode.startsWith('+971')  || countryCode.startsWith('971') || countryCode.startsWith('+97') || countryCode.startsWith('97')){
                            SmsNotificationAPI.SmsRequest wrp = new SmsNotificationAPI.SmsRequest();
                            wrp.destination = listContact[0].MobileCountryCode__c + listContact[0].MobilePhone__c;
                            wrp.smsBody = 'Dear ' +listContact[0].Name+','+'\r\n' +'Your One Time Passcode is '+sixDigitOTPNumber+'.'+'\r\n'+'\r\n' +'Aldar Properties' ;
                            wrp.record = listContact[0];
                            // Call Domestic SMS API
                            SmsNotificationAPI.sendSmsNotification(new List<SmsNotificationAPI.SmsRequest>{wrp});
                        }else{
                            // Implement INTL SMS API
                        }   
                    }else if(type == 'email'){
                        // Added By Moh Sarfaraj for BPE-278
                        CommunityAuthController.sendBrokerOTPEmail(listContact[0]?.Email, String.valueOf(sixDigitOTPNumber));
                    }
                    update listContact;
                    return 'success';
                }
                return 'There is no '+System.Label.BPM_BankOTPOwnership+ ' for this Agency';
            }
        //}
        //catch (Exception e){throw new AuraHandledException(e.getMessage());}
        return '';
    }

    /**
    * getOtpDetails
    * This method used to
    * @param String
    * @return List<Contact>
    * @description Added By Moh Sarfaraj for BPE-130
    */
    @AuraEnabled(cacheable=false)
    public static List<Contact> getOtpDetails(String accountId){
        String otpReceiver = System.Label.BPM_BankOTPOwnership.deleteWhiteSpace().toUpperCase(); // PrimaryAdmin / PrimaryOwner
        Timer__mdt otpTimer = Utilities.getTimer(Constants.OTP);

        String timerUnit = otpTimer.Time__c;
        Integer timerDetails = Integer.valueOf(otpTimer.Timer__c);

        if (timerUnit == Constants.HOURS) {
            timerDetails = timerDetails * 60;
        }

        List<Contact> listContact;
        if(String.isNotBlank(otpReceiver) && String.isNotBlank(accountId)){
            if(otpReceiver.equalsIgnoreCase('PRIMARYADMIN')){
                listContact = new List<Contact>();
                listContact = [SELECT Id,Name,BrokerLoginOTPNumber__c FROM Contact WHERE 
                               BrokerLoginOTPDateTime__c >: System.now().addMinutes(-timerDetails) AND
                               AccountId = :accountId AND BrokerType__c = 'Agency Admin' AND 
                               PrimaryAgencyAdmin__c = true ORDER By LastModifiedDate DESC LIMIT 1];

            }else if(otpReceiver.equalsIgnoreCase('PRIMARYOWNER')){
                listContact = new List<Contact>();
                listContact = [SELECT Id,Name,BrokerLoginOTPNumber__c FROM Contact WHERE 
                               BrokerLoginOTPDateTime__c >: System.now().addMinutes(-timerDetails) AND 
                               AccountId = :accountId AND BrokerType__c = 'Partner/Owner' AND 
                               PrimaryOwner__c = true ORDER By LastModifiedDate DESC LIMIT 1];
            }
        }

        if(listContact != null && !listContact.isEmpty()){
            return listContact;
        }
        return new List<Contact>();
    }

    /**
    * bankDetailsCRSubmit
    * This method used to
    * @param User
    * @param Map<String,String>
    * @return String
    * @description Added By Moh Sarfaraj for BPE-130
    */
    @AuraEnabled(cacheable=false)
    public static String bankDetailsCRSubmit(User userRecord, Map<String,String> bankDetails){ 
       // try{
            Account proposedBankUpdate = new Account();
            proposedBankUpdate.Id = userRecord.AccountId;
            proposedBankUpdate.ProposedBankName__c = bankDetails.get('bankName');
            proposedBankUpdate.ProposedBranchAddress__c = bankDetails.get('bankBranch');
            proposedBankUpdate.ProposedBankAccountNumber__c = bankDetails.get('accountNumber');
            proposedBankUpdate.ProposedIBANNumber__c = bankDetails.get('IBANNumber');
            proposedBankUpdate.ProposedSwiftCode__c = bankDetails.get('swiftCode');
            proposedBankUpdate.ProposedBankCountry__c = bankDetails.get('country');
            // proposedBankUpdate.ProposedBankName__c = bankDetails.get('currency');
            proposedBankUpdate.ProposedBeneficiaryName__c = bankDetails.get('beneficiaryName');
            proposedBankUpdate.ProposedBankDetailStatus__c = 'Pending';
            proposedBankUpdate.Description = 'Please Review the Bank Copy Document Before Approve/Reject';
            update proposedBankUpdate;

            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setObjectId(proposedBankUpdate.Id);
            // Run The Approval Process for Ireana
            Approval.ProcessResult result = Approval.process(approvalRequest);
            return 'success';
        //}catch (Exception e){throw new AuraHandledException(e.getMessage()); //}
            //return ex.getMessage();
        //}
    }

    /**
    * uploadFile
    * This method used to
    * @param String
    * @param String
    * @param String
    * @param String
    * @return String
    * @description Added By Moh Sarfaraj for BPE-130
    */
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String type, String recordId) {
        try{
            List<HexaBPM__SR_Doc__c> listHBDocs = [SELECT Id FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Customer__c = :recordId AND 
                                               HexaBPM__Document_Name__c = :type];

            if(String.isNotBlank(base64) && String.isNotBlank(filename) && listHBDocs != null && !listHBDocs.isEmpty()){
                ContentVersion cv = createContentVersion(base64, filename);
                ContentDocumentLink cd1 = createContentLink(cv.Id, listHBDocs[0].Id);

                Account accountUpdateLink = new Account();
                accountUpdateLink.Id = recordId;
                accountUpdateLink.DocumentLink__c = URL.getOrgDomainURL().toExternalForm() + '/lightning/r/ContentDocument/'+cd1.ContentDocumentId+'/view';
                update accountUpdateLink;
                return 'Success';
            }
            return '';
        }catch (Exception e){throw new AuraHandledException(e.getMessage());} 
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
        Network network =  [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        cv.NetworkId = network.Id;
        try {
            insert cv;
            return cv;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        try {
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
    
    /********************************* METHODS ADDED BY THARUN *********************************/
    @AuraEnabled
    public static String sendEmailOTP(String conId, String conEmailAddress)
    {
        try{
            String otpGeneratedValue = String.valueOf(Utilities.getRandomNumber(6));
            String returnValue = 'Error';
            
            if (conId != null) {
                Contact portalUserContact                       = new Contact();
                portalUserContact.Id                            = (Id)conId;
                portalUserContact.BrokerLoginOTPNumber__c       = otpGeneratedValue;
                portalUserContact.BrokerLoginOTPDateTime__c     = Datetime.now();
                update portalUserContact;
                //If update is successful send email and return OTP sent and masked email address
                if(CommunityAuthController.sendBrokerOTPEmail(conEmailAddress, otpGeneratedValue))
                returnValue =  'OTPSent-'+ conEmailAddress;
            }
            return returnValue;
        }
        catch (Exception e){throw new AuraHandledException(e.getMessage());} 
    }
    
        
    @AuraEnabled
    public static Map<String, String> verifyEmailOTP(String conId, String otpEntered, 
                                                     String emailEntered,
                                                     String countryCodeEntered,
                                                     String mobNumberEntered)
    {
        Map<String, String> returnMap       = new Map<String,String>();
        Timer__mdt otpTimer                 = Utilities.getTimer(ALD_Constants.BROKER_LOGIN_OTP_TIMER);
        String timerUnit                    = otpTimer.Time__c;
        Integer timerDetails                = Integer.valueOf(otpTimer.Timer__c);
        String approvalComments             = '';
        
        try{
            Contact contactDetails = [SELECT Id, Name, ProposedEmail__c,
                                      BrokerLoginOTPNumber__c, BrokerLoginOTPDateTime__c
                                      FROM Contact WHERE Id = :conId LIMIT 1];
            if (contactDetails != null) {
                DateTime otpSentDateTimeWithTimeLimit = contactDetails.BrokerLoginOTPDateTime__c.addMinutes(timerDetails);
                if(Datetime.now() < otpSentDateTimeWithTimeLimit){
                    //OTP entered within time
                    String otpGenerated = contactDetails.BrokerLoginOTPNumber__c;
                    if(String.isNotBlank(otpEntered) && otpEntered.equals(otpGenerated) && !Test.isRunningTest()){
                        if(String.isNotBlank(emailEntered)){
                            contactDetails.ProposedEmail__c                 = emailEntered;
                            approvalComments                                = 'Broker Email update request for approval';
                        }else if( String.isNotBlank(countryCodeEntered) && String.isNotBlank(mobNumberEntered) ){
                            contactDetails.ProposedMobileCountryCode__c     = countryCodeEntered;
                            contactDetails.ProposedMobilePhone__c           = mobNumberEntered;
                            approvalComments                                = 'Broker Mobile update request for approval';
                        }
                        
                        // SOQL_UPDATE
                        Update contactDetails;
                        
                        Approval.ProcessSubmitRequest contactEmailApproval = new Approval.ProcessSubmitRequest();
                        contactEmailApproval.setComments(approvalComments);
                        contactEmailApproval.setObjectId(contactDetails.Id);
                        Approval.ProcessResult result = Approval.process(contactEmailApproval);
                        
                        returnMap.put('Success', 'Request sent to approval with Broker Admin Team');
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
    
    /********************************* METHODS ADDED BY THARUN *********************************/
    
    /**
    * uploadFile
    * This method used to show Intimate update Bank Details
    * @param String
    * @return String
    * @description Added By Moh Sarfaraj for BPM-566
    */
    @AuraEnabled(cacheable=true)
    public static Boolean hasPendingInvoiceBundle(String accountId){
        try{
            Boolean hasPendingInvoice = false;
            if(String.isNotBlank(accountId)){
                final Set<String> setStatuses = new Set<String>{'Pending Invoice Verification','Pending Finance Verification',
                    'Sent to Finance', 'Invoice Approval In Progress', 'Payment Approval In Progress', 'Payment Under Bank Clearance'};
                    
                List<InvoiceBundle__c> listInvoices = [SELECT Id,Status__c FROM InvoiceBundle__c WHERE 
                                                       BrokerAgency__c = :accountId AND Status__c IN :setStatuses];

                if(listInvoices != null && !listInvoices.isEmpty()){
                    hasPendingInvoice = true;
                }
            }
            return hasPendingInvoice;
        }catch (Exception e){throw new AuraHandledException(e.getMessage());} 
    }
}