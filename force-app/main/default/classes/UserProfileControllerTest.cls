@isTest(SeeAllData=false)
public class UserProfileControllerTest {
    @isTest static void setupMethod() {
        
        Account account = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
        insert account;
        
        Contact contactRecord = TestObjectsFactory.contactDataSetup(account.id);
        contactRecord.PrimaryOwner__c = true;
        contactRecord.BrokerType__c = 'Partner/Owner';
        contactRecord.AgentStatus__c = 'Active';
        contactRecord.MobileCountryCode__c = '971';
        contactRecord.MobilePhone__c = '9696859685';
        contactRecord.Email = 'test@gmail.com';
        update contactRecord;
        
        Contact contactRecord1 = TestObjectsFactory.contactDataSetup(account.id);
        contactRecord1.PrimaryAgencyAdmin__c = true;
        contactRecord1.BrokerType__c = 'Agency Admin';
        contactRecord1.AgentStatus__c = 'Active';
        contactRecord1.MobileCountryCode__c = '971';
        contactRecord1.MobilePhone__c = '9696859685';
        contactRecord1.Email = 'test@gmail.com';
        contactRecord1.BrokerLoginOTPDateTime__c = System.now().addDays(2);
        contactRecord1.BrokerLoginOTPNumber__c = '12345';
        update contactRecord1;
        
        User user = TestObjectsFactory.getUserRecord('System Administrator', 'pwctest');
        //user.ContactId = contactRecord1.Id;
        insert user; 
        
        HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c();
        insert serviceRequest;
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'PDF';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        
        HexaBPM__SR_Doc__c document = new HexaBPM__SR_Doc__c();
        document.HexaBPM__Customer__c = account.Id;
        document.HexaBPM__Document_Type__c = 'Test Code 1';
        document.HexaBPM__SR_Template_Doc__c = docTemp.id;
        document.HexaBPM__Service_Request__c = serviceRequest.Id;
        document.Name = 'Bank Copy';
        insert document;
        
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.Name = Constants.SUBMITTED;
        srStatus.HexaBPM__Code__c = 'Submitted';
        srStatus.Name = 'Submitted';
        insert srStatus;
        
        Date newDate = Date.today();
        Date newEndDate = Date.today() + 30;
        String profileImage = '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCADqATkDASIAAhEBAxEB/8QAFwABAQEBAAAAAAAAAAAAAAAAAAECA//EACQQAQEBAAIBBAMBAQEBAAAAAAABESExQQISUXFhgZGxocHw/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAH/xAAWEQEBAQAAAAAAAAAAAAAAAAAAEQH/2gAMAwEAAhEDEQA/AMriLyCKgg1gQwCgs4FTMOdutepjQak+FzMSVqgxZdRdPPIIvH5WzzGdBriphtTeAXg2ZjKA1pqKDUGZca3foBek8gFv8Ie3fKdA1qb8s7hoL6eLVt51FsAnql3Ut1M7AWbflLMDkEMX/F6/YjK/pADFQAUNA6alYagKk72m/j9p4Bq2fDDSYKLNXPNLoHE/NT6RYC31cJxZ3yWVM+aBYi/S2ZgiAsnYJx5D21vPmqrm3PTfpQQwyAC8JZvSKDni41ZrMuUVVl+Uz9w9v/1QWrZsZ5nFPHYH+JZyureQSF5M+fJ0CAfwRAVRBQA1DAWVUayoJUWoDpsxntPsueBV4+VxhdyAtv8AjOLGpIDMLbeGvbF4iozJfr/WukAVABAXAQXEAAASzVAZdO2WNordm+emFl7XcQSNZiFtv0C9w90nhJf4mA1u+GcJFwIyAqL/AOovwgGNfSRqdIrNa29M0gKCAojU9PAMjWXpckEJFNFEAAXEUBABYz6rZ0ureQc9vyt9XxDF2QAXtABcQAs0AZywkvluJbyipifas52DcyxjlZweAO0xri/hc+wZOEKIu6nSyeToVZyWXwvCg53gW81QQ7aTNAn5dGZJPs1UXURQAUEMCXQLZE93PRZ5hPTgNMrbIzKCm52LZwCs+2M8w2g3sjPuZAXb4IsMAUACzVUGM4/K+md6vEXUUyM5PDR0IxYe6ramih0VNBrS4xoqN8Q1BFQk3yqyAsioioAAKgDSJL4/jQIn5igLrPqtOuf6oOaxbMoAltUAhhIoJiiggrPu+AaOIxtAX3JbaAIaLwi4t9X4T3fg2AFtqcrUUarP20zUDAmqoE0WRBZPNVUVEAAAAVAC8kvih2DSKxOdBqs7Z0l0gI0mKAC4AuHE7ZtBriM+744QAAAAABAFsveIttBICyaikvy1+r/Cen5rWQHIBQa4rIDRqSl5qDWqziqgAAAATA7BpGdqXb2C2+J/UgAtRQBSQtkBWb6vhLbQAAAAAEBRAAAAAUbm+GZNdPxAP+ql2Tjwx7/wIgZ8iKvBk+CJoCXii9gaqZ/qqihAAAEVABGkBFUwBftNkZ3QW34QAAABFAQAVAAAAAARVkl8gs/43sk1jL45LvHArepk+E9XTG35oLqsmIKmLAEygKg0y1AFQBUXwgAAAoBC34S3UAAABAVAAAAAABAUQAVABdRQa1PcYyit2z58M8C4ouM2NXpOEGeWtNZUatiAIoAKIoCoAoG4C9MW6dgIoAIAAAAAAACKWAgL0CAAAALiANCKioNLgM1CrLihmTafkt1EF3SZ5ZVUW4mnIKvAi5fhEURVDWVQBRAAAAAAAAQFRVyAyulgAqCKlF8IqLsEgC9mGoC+IusqCrv5ZEUVOk1RuJfwSLOOkGFi4XPCoYYrNiKauosBGi9ICstM1UAAAAAAFQ0VcTBAXUGgIqGoKhKAzRRUQUAwxoSrGRpkQA/qiosOL9oJptMRRVZa0VUqSiChE6BqMgCwqKqIogAIAqKCKgKoogg0lBFuIKgAAAKNRlf2gqsftsEtZWoAAqAACKoMqAAeSoqp39kL2AqLOlE8rEBFQARYALhigrNC9gGmooLp4TweEQFFBFAECgIoAu0ifIAqAAA//9k=';
        
        
        Test.startTest();
        UserProfileController.getUserProfileDetails();
        UserProfileController.getSRDocId(account.Id, 'PDF');
        UserProfileController.updateMobilePhone(contactRecord.Id,'7030181809');
        UserProfileController.resetPassowrd('PWC@12345','PWC@12345','PWC@54321');
        UserProfileController.updateProposedExpiryDate(account.Id,newDate,'111199999', newEndDate);
        UserProfileController.uploadUserPicture(profileImage);
        UserProfileController.getPicklistValuesGeneric('Account', 'Industry');
        UserProfileController.getPrimaryOwnerOrAdminDetails(account.Id);
        UserProfileController.getOtpDetails(account.Id);
        UserProfileController.uploadFile(profileImage, 'Test','Bank Copy',account.Id);
        
        UserProfileController.sendEmailOTP(contactRecord1.Id, 'test11@gmail.com');
        String otpValue = [SELECT Id,BrokerLoginOTPNumber__c FROM Contact WHERE Id =:contactRecord1.Id ].BrokerLoginOTPNumber__c;
        UserProfileController.verifyEmailOTP(contactRecord1.Id,otpValue,'test@gmail.com', '971', '552282345');
        UserProfileController.verifyEmailOTP(contactRecord1.Id,otpValue,'', '971', '552282345');
        //String base64 = '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';
        //BrokerAgentsController.uploadFile(base64,'Test','Emirates ID Copy',con.Id);
        //UserProfileController.sentOTP(account.Id, 'sms');
        //UserProfileController.sentOTP(account.Id, 'email');
        Test.stopTest();
        
    }
    
    @isTest static void testSentOTPSuccess() {
        Map<String,String> bankDetails = new Map<String,String>();
        bankDetails.put('bankName', 'NBD');
        bankDetails.put('bankBranch', 'ABU DHABI');
        bankDetails.put('accountNumber', '110011');
        bankDetails.put('IBANNumber', 'AE32938232932389238');
        bankDetails.put('swiftCode', 'NBD111111');
        bankDetails.put('country', 'United Arab Emirates');
        bankDetails.put('currency', 'AED');
        
        // Create test data: Account and Contact records
        Account account = TestObjectsFactory.getAgencyAccountRecord('PWC1', '123456799');
        insert account;
        
        Contact contactRecord = TestObjectsFactory.contactDataSetup(account.id);
        contactRecord.AccountId = account.id;
        contactRecord.PrimaryOwner__c = true;
        contactRecord.AgentStatus__c = 'Active';
        contactRecord.MobileCountryCode__c = '971';
        contactRecord.MobilePhone__c = '9696859685';
        contactRecord.Email = 'test111@gmail.com';
        update contactRecord;
        
        Contact contactRecord1 = TestObjectsFactory.contactDataSetup(account.id);
        contactRecord1.AccountId = account.id;
        contactRecord1.PrimaryAgencyAdmin__c = true;
        contactRecord1.AgentStatus__c = 'Active';
        contactRecord1.MobileCountryCode__c = '971';
        contactRecord1.MobilePhone__c = '9696859685';
        contactRecord1.Email = 'test112271@gmail.com';
        contactRecord1.BrokerType__c = 'Partner/Owner';
        contactRecord1.PrimaryOwner__c = true;
        update contactRecord1;
        
        User portalUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'pwctest');
        portalUser.ContactId = contactRecord1.Id;
        portalUser.Email = 'test@gmail.com';
        insert portalUser;
        System.Debug('portalUser------'+portalUser);
        System.Debug('tharun------'+portalUser.AccountId);
        System.Debug('Contact------'+portalUser.ContactId);
        
        User userRecord = [SELECT Id,AccountId FROM User WHERE Id = :portalUser.Id];
        String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        // Set up the test context
       
        System.runAs(userRecord) {
            Test.startTest();
            if(String.isNotBlank(userRecord.AccountId)){
                UserProfileController.bankDetailsCRSubmit(userRecord, bankDetails);
                
            }
            UserProfileController.sentOTP(account.Id, 'sms');
            UserProfileController.sentOTP(account.Id, 'email');
            Test.stopTest();
        }
    }
    @isTest static void testVATDetails() {
        Account account = TestObjectsFactory.getAgencyAccountRecord('PWC1', '123456799');
        insert account;
        
        Contact contactRecord1 = TestObjectsFactory.contactDataSetup(account.id);
        contactRecord1.AccountId = account.id;
        contactRecord1.PrimaryAgencyAdmin__c = true;
        contactRecord1.AgentStatus__c = 'Active';
        contactRecord1.MobileCountryCode__c = '971';
        contactRecord1.MobilePhone__c = '9696859685';
        contactRecord1.Email = 'test112271@gmail.com';
        contactRecord1.BrokerType__c = 'Partner/Owner';
        contactRecord1.PrimaryOwner__c = true;
        update contactRecord1;
        
        
        User portalUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'pwctest');
        portalUser.ContactId = contactRecord1.Id;
        portalUser.Email = 'test@gmail.com';
        insert portalUser;
        User userRecord = [SELECT Id,AccountId FROM User WHERE Id = :portalUser.Id];
         Date newDate = Date.today();
        Date newEndDate = Date.today() + 30;
        System.runAs(userRecord) {
            Test.startTest();
            if(String.isNotBlank(userRecord.AccountId)){
                UserProfileController.updateVATDetails(account.Id,'VAT Registration Certificate',newDate,newEndDate,'11119999');                
            }
            Test.stopTest();
        }
        UserProfileController.hasPendingInvoiceBundle(account.Id);
    }
}